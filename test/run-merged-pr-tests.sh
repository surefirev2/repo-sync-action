#!/usr/bin/env bash
# Tests for template-sync-resolve-merged-pr.sh (no network).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOLVE_SCRIPT="$REPO_ROOT/src/template-sync-resolve-merged-pr.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

init_git_repo() {
  work_dir=$(mktemp -d)
  cd "$work_dir"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
}

# GitHub Actions runners export GITHUB_OUTPUT; unset for stdout assertions.
run_resolve_stdout() {
  local sha="$1"
  shift
  env -u GITHUB_OUTPUT \
    GITHUB_REPOSITORY="org/template" \
    GITHUB_SHA="$sha" \
    "$@" \
    bash "$RESOLVE_SCRIPT"
}

echo "=== Test 1: squash-merge commit message (#123) ==="
init_git_repo
echo "initial" > README.md
git add README.md
git commit -q -m "initial"
git commit -q --allow-empty -m "feat: add thing (#123)"
sha=$(git rev-parse HEAD)

out=$(run_resolve_stdout "$sha")
[[ "$out" == "number=123" ]] || { echo "Expected number=123, got: $out"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: merge commit message ==="
init_git_repo
echo "initial" > README.md
git add README.md
git commit -q -m "initial"
git commit -q --allow-empty -m "Merge pull request #42 from org/feature"
sha=$(git rev-parse HEAD)

out=$(run_resolve_stdout "$sha")
[[ "$out" == "number=42" ]] || { echo "Expected number=42, got: $out"; exit 1; }
echo "Test 2 passed."

echo "=== Test 3: API error JSON does not become PR number ==="
init_git_repo
echo "initial" > README.md
git add README.md
git commit -q -m "initial"
git commit -q --allow-empty -m "feat: no pr reference"
sha=$(git rev-parse HEAD)

gh_mock_dir=$(mktemp -d)
cat >"$gh_mock_dir/gh" <<'EOF'
#!/usr/bin/env bash
echo '{"message":"Not Found","status":"404"}'
EOF
chmod +x "$gh_mock_dir/gh"

out=$(
  env -u GITHUB_OUTPUT \
    PATH="$gh_mock_dir:$PATH" \
    GITHUB_REPOSITORY="org/template" \
    GITHUB_SHA="$sha" \
    GH_TOKEN="fake" \
    bash "$RESOLVE_SCRIPT"
)
[[ "$out" == "number=" ]] || { echo "Expected empty number, got: $out"; exit 1; }
rm -rf "$gh_mock_dir"
echo "Test 3 passed."

echo "=== Test 4: writes GitHub Actions output when GITHUB_OUTPUT is set ==="
init_git_repo
echo "initial" > README.md
git add README.md
git commit -q -m "initial"
git commit -q --allow-empty -m "feat: ship (#99)"
sha=$(git rev-parse HEAD)
output_file=$(mktemp)
GITHUB_OUTPUT="$output_file" GITHUB_REPOSITORY="org/template" GITHUB_SHA="$sha" bash "$RESOLVE_SCRIPT" >/dev/null
grep -q '^number=99$' "$output_file" || {
  echo "Expected number=99 in GITHUB_OUTPUT, got: $(cat "$output_file")"
  exit 1
}
rm -f "$output_file"
echo "Test 4 passed."

echo "All merged-pr tests passed."
