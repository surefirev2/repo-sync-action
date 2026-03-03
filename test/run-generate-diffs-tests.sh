#!/usr/bin/env bash
# Run generate-diffs script tests with a minimal git repo and per-repo file lists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GEN_DIFFS_SCRIPT="$REPO_ROOT/src/template-sync-generate-diffs.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: generate diff for single repo ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"

echo "v1" > foo.txt
git add foo.txt
git commit -q -m "add foo v1"

echo "v2" > foo.txt
git add foo.txt
git commit -q -m "update foo v2"

printf 'foo.txt\n' > files_to_sync_repo-a.txt

REPOS="repo-a" bash "$GEN_DIFFS_SCRIPT"

[[ -f sync_diff_repo-a.txt ]] || { echo "sync_diff_repo-a.txt not created"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: missing file list skipped ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
echo "v1" > foo.txt
git add foo.txt
git commit -q -m "add foo v1"

REPOS="repo-a" bash "$GEN_DIFFS_SCRIPT"

[[ ! -f sync_diff_repo-a.txt ]] || { echo "sync_diff_repo-a.txt should not be created when list is missing"; exit 1; }
echo "Test 2 passed."

echo "All generate-diffs tests passed."
