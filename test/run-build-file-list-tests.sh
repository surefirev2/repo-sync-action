#!/usr/bin/env bash
# Run build-file-list script tests with a minimal git repo and fixture include/exclude files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_SCRIPT="$REPO_ROOT/.github/scripts/template-sync-build-file-list.sh"
GA_SCRIPT="$REPO_ROOT/.github/scripts/template-sync-ga-build-file-list.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: allowlist with directory glob ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
mkdir -p .github/workflows .github/scripts
touch .github/workflows/sync.yaml .github/scripts/foo.sh .github/scripts/bar.sh README.md
git add -A && git commit -q -m "init"

printf '.github/workflows/*\n.github/scripts/*\n' > include_paths.txt
touch exclusions.txt

GITHUB_OUTPUT=$(mktemp)
REPOS="" bash "$GA_SCRIPT" || true
# GA script with empty REPOS uses include_paths.txt and writes to files_to_sync.txt in cwd
# Actually GA script with empty REPOS runs build-file-list with --include-file and --output-dir .
# So we need to run build-file-list directly to control output location
bash "$BUILD_SCRIPT" --include-file include_paths.txt --include-dir . --output-dir . --output files_to_sync.txt

count=$(wc -l < files_to_sync.txt)
# Expect 3 files: sync.yaml, foo.sh, bar.sh (README not in include)
if [[ "$count" -lt 2 ]]; then
  echo "Expected at least 2 files in files_to_sync.txt, got $count" >&2
  cat files_to_sync.txt >&2
  exit 1
fi
grep -q '.github/workflows/sync.yaml' files_to_sync.txt || { echo "sync.yaml missing"; exit 1; }
grep -q '.github/scripts/foo.sh' files_to_sync.txt || { echo "foo.sh missing"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: blacklist mode ==="
work_dir=$(mktemp -d)
cd "$work_dir"
git init -q
mkdir -p .github
touch README.md .github/foo.yaml
git add -A && git commit -q -m "init"

printf 'README.md\n' > exclusions.txt
# Empty include file for blacklist mode
touch include_paths_empty.txt
bash "$BUILD_SCRIPT" --exclusions-file exclusions.txt --include-dir . --output-dir . --output files_to_sync.txt

# Should have .github/foo.yaml but not README.md
grep -q 'README.md' files_to_sync.txt && { echo "README.md should be excluded"; exit 1; }
grep -q '.github/foo.yaml' files_to_sync.txt || { echo ".github/foo.yaml should be included"; exit 1; }
echo "Test 2 passed."

echo "All build-file-list tests passed."
