#!/usr/bin/env bash
# Run resolve-config script tests using fixture configs (no GitHub API).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOLVE_SCRIPT="$REPO_ROOT/.github/scripts/template-sync-resolve-config.sh"
FIXTURES="$SCRIPT_DIR/fixtures/resolve-config"
OUTPUT_FILE=""

cleanup() {
  [[ -n "$OUTPUT_FILE" && -f "$OUTPUT_FILE" ]] && rm -f "$OUTPUT_FILE"
}
trap cleanup EXIT

run_resolve() {
  local config="$1"
  local org="${2:-testorg}"
  local out_dir="${3:-.}"
  OUTPUT_FILE=$(mktemp)
  GITHUB_OUTPUT="$OUTPUT_FILE" bash "$RESOLVE_SCRIPT" \
    --config "$config" \
    --org "$org" \
    --out-dir "$out_dir"
  cat "$OUTPUT_FILE"
}

assert_repos_list() {
  local expected="$1"
  local output_file="$2"
  local actual
  actual=$(grep '^repos_list=' "$output_file" | sed 's/^repos_list=//')
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected repos_list: '$expected', got: '$actual'" >&2
    return 1
  fi
}

echo "=== Test 1: literal repos only ==="
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"; cleanup' EXIT
cp "$FIXTURES/literal-repos.yml" "$work_dir/config.yml"
OUTPUT_FILE=$(mktemp)
GITHUB_OUTPUT="$OUTPUT_FILE" bash "$RESOLVE_SCRIPT" \
  --config "$work_dir/config.yml" \
  --org testorg \
  --out-dir "$work_dir"
assert_repos_list "repo-a repo-b" "$OUTPUT_FILE"
[[ -f "$work_dir/include_paths.txt" ]] || { echo "include_paths.txt not created"; exit 1; }
[[ -f "$work_dir/exclusions.txt" ]] || { echo "exclusions.txt not created"; exit 1; }
grep -q '.github/workflows/sync.yaml' "$work_dir/include_paths.txt" || { echo "include_paths content wrong"; exit 1; }
rm -rf "$work_dir"
trap cleanup EXIT
echo "Test 1 passed."

echo "=== Test 2: repo_include_paths override ==="
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"; cleanup' EXIT
cp "$FIXTURES/with-repo-include-paths.yml" "$work_dir/config.yml"
GITHUB_OUTPUT=$(mktemp) bash "$RESOLVE_SCRIPT" \
  --config "$work_dir/config.yml" \
  --org testorg \
  --out-dir "$work_dir"
[[ -f "$work_dir/include_paths_repo-b.txt" ]] || { echo "include_paths_repo-b.txt not created"; exit 1; }
grep -q '.github/scripts/\*' "$work_dir/include_paths_repo-b.txt" || { echo "repo-b include path wrong"; exit 1; }
rm -rf "$work_dir"
trap cleanup EXIT
echo "Test 2 passed."

echo "All resolve-config tests passed."
