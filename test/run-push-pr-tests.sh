#!/usr/bin/env bash
# Run push-pr script tests focusing on dry-run behavior (no network).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PUSH_PR_SCRIPT="$REPO_ROOT/src/template-sync-push-pr.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: exits cleanly when no repos ==="
work_dir=$(mktemp -d)
cd "$work_dir"

ORG="testorg" \
  REPOS_LIST="" \
  DRY_RUN="1" \
  FILES_LIST="files_to_sync.txt" \
  bash "$PUSH_PR_SCRIPT" > output.txt 2>&1 || { echo "Script should not fail when no repos"; exit 1; }

grep -q 'No dependent repos to sync.' output.txt || { echo "Expected message for no repos"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: dry-run prints planned sync without network ==="
work_dir=$(mktemp -d)
cd "$work_dir"

printf 'foo.txt\nbar/baz.txt\n' > files_to_sync.txt

ORG="testorg" \
  REPOS_LIST="repo-a" \
  DRY_RUN="1" \
  FILES_LIST="files_to_sync.txt" \
  bash "$PUSH_PR_SCRIPT" > output.txt 2>&1

grep -F -q -- '--- [dry-run] Would sync to testorg/repo-a ---' output.txt || { echo "Expected dry-run header"; exit 1; }
grep -F -q -- 'foo.txt' output.txt || { echo "Expected foo.txt in dry-run output"; exit 1; }
grep -F -q -- 'bar/baz.txt' output.txt || { echo "Expected bar/baz.txt in dry-run output"; exit 1; }
echo "Test 2 passed."

echo "All push-pr tests passed."
