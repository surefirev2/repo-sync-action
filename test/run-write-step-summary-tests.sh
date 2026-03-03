#!/usr/bin/env bash
# Run write-step-summary script tests with synthetic inputs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SUMMARY_SCRIPT="$REPO_ROOT/src/template-sync-write-step-summary.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: summary with file list ==="
work_dir=$(mktemp -d)
cd "$work_dir"

printf 'foo.txt\nbar/baz.txt\n' > files_to_sync.txt

GITHUB_STEP_SUMMARY="$work_dir/summary.md" \
  REPOS="repo-a repo-b" \
  COUNT="2" \
  FILES_LIST="files_to_sync.txt" \
  bash "$SUMMARY_SCRIPT"

[[ -f summary.md ]] || { echo "summary.md not created"; exit 1; }
grep -q '## Template sync preview' summary.md || { echo "Missing heading in summary"; exit 1; }
grep -q 'Target repositories' summary.md || { echo "Target repositories section missing"; exit 1; }
grep -q 'repo-a' summary.md || { echo "repo-a not rendered"; exit 1; }
grep -q 'repo-b' summary.md || { echo "repo-b not rendered"; exit 1; }
grep -q 'Files to sync' summary.md || { echo "Count line missing"; exit 1; }
grep -q '2' summary.md || { echo "Count value not rendered correctly"; exit 1; }
grep -q 'foo.txt' summary.md || { echo "File list not included"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: summary without file list file ==="
work_dir=$(mktemp -d)
cd "$work_dir"

GITHUB_STEP_SUMMARY="$work_dir/summary.md" \
  REPOS="none" \
  COUNT="0" \
  FILES_LIST="files_to_sync.txt" \
  bash "$SUMMARY_SCRIPT"

[[ -f summary.md ]] || { echo "summary.md not created for missing list case"; exit 1; }
grep -q 'Target repositories' summary.md || { echo "Target repositories heading missing for none case"; exit 1; }
grep -q 'none' summary.md || { echo "Repos placeholder not rendered correctly"; exit 1; }
grep -q 'Files to sync' summary.md || { echo "Count line missing for zero case"; exit 1; }
grep -q '0' summary.md || { echo "Zero count not rendered correctly"; exit 1; }
! grep -q '```' summary.md || { echo "File list block should not be present when list is missing"; exit 1; }
echo "Test 2 passed."

echo "All write-step-summary tests passed."
