#!/usr/bin/env bash
# Run GA wrapper tests for template-sync-build-file-list.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GA_SCRIPT="$REPO_ROOT/.github/scripts/template-sync-ga-build-file-list.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: single-list mode with include_paths.txt ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
mkdir -p .github/workflows
touch .github/workflows/sync.yaml README.md
git add -A && git commit -q -m "init"

printf '.github/workflows/*\n' > include_paths.txt
touch exclusions.txt

output_file=$(mktemp)
GITHUB_OUTPUT="$output_file" REPOS="" bash "$GA_SCRIPT"

[[ -f files_to_sync.txt ]] || { echo "files_to_sync.txt not created"; exit 1; }
grep -q '.github/workflows/sync.yaml' files_to_sync.txt || { echo "sync.yaml missing from files_to_sync.txt"; exit 1; }
grep -q '^count=' "$output_file" || { echo "count output missing from GITHUB_OUTPUT"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: per-repo mode with include_paths.txt ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
git config user.email "test@example.com"
git config user.name "Test User"
mkdir -p .github/workflows .github/scripts
touch .github/workflows/sync.yaml .github/scripts/foo.sh .github/scripts/bar.sh
git add -A && git commit -q -m "init"

printf '.github/workflows/*\n.github/scripts/*\n' > include_paths.txt
touch exclusions.txt

output_file=$(mktemp)
GITHUB_OUTPUT="$output_file" REPOS="repo-a repo-b" bash "$GA_SCRIPT"

for repo in repo-a repo-b; do
  [[ -f "files_to_sync_${repo}.txt" ]] || { echo "files_to_sync_${repo}.txt not created"; exit 1; }
done

[[ -f files_to_sync.txt ]] || { echo "union files_to_sync.txt not created"; exit 1; }
grep -q '.github/workflows/sync.yaml' files_to_sync.txt || { echo "sync.yaml missing from union files_to_sync.txt"; exit 1; }
grep -q '.github/scripts/foo.sh' files_to_sync.txt || { echo "foo.sh missing from union files_to_sync.txt"; exit 1; }
grep -q '^count=' "$output_file" || { echo "count output missing in per-repo mode"; exit 1; }
echo "Test 2 passed."

echo "All GA build-file-list wrapper tests passed."
