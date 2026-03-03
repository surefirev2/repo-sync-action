#!/usr/bin/env bash
# Run PR comment script tests with a stubbed gh CLI to avoid network calls.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PR_COMMENT_SCRIPT="$REPO_ROOT/src/template-sync-pr-comment.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: creates new comment with union file list ==="
work_dir=$(mktemp -d)
cd "$work_dir"

mkdir -p bin
GH_LOG="$work_dir/gh.log"

cat > bin/gh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "gh $*" >> "${GH_LOG:-/dev/null}"
subcmd="${1:-}"
case "$subcmd" in
  api)
    # For list-comments, return empty array; for PATCH, just consume input.
    path="${2:-}"
    if [[ "$path" == repos/*/issues/*/comments ]]; then
      # Simulate no existing comments (so COMMENT_ID is empty)
      :
    else
      cat >/dev/null || true
    fi
    ;;
  pr)
    # pr comment ... --body-file BODY
    if [[ "${2:-}" == "comment" ]]; then
      exit 0
    fi
    ;;
esac
exit 0
EOF
chmod +x bin/gh

export PATH="$work_dir/bin:$PATH"
export GH_LOG

printf 'foo.txt\nbar/baz.txt\n' > files_to_sync.txt

REPOS="repo-a repo-b" \
  COUNT="2" \
  FILES_LIST="files_to_sync.txt" \
  GITHUB_REPOSITORY="surefirev2/template-template" \
  GH_TOKEN="dummy" \
  bash "$PR_COMMENT_SCRIPT" 123 --repo "surefirev2/template-template"

grep -q 'gh api repos/surefirev2/template-template/issues/123/comments' "$GH_LOG" || { echo "Expected gh api list-comments call"; exit 1; }
grep -q 'gh pr comment 123 --repo surefirev2/template-template' "$GH_LOG" || { echo "Expected gh pr comment call"; exit 1; }
echo "Test 1 passed."

echo "All PR comment tests passed."
