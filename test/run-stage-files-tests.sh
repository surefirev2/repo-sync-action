#!/usr/bin/env bash
# Stage-files: force-add synced paths that match destination .gitignore rules.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGE_SCRIPT="$REPO_ROOT/src/template-sync-stage-files.sh"

work_dir=""
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] && rm -rf "$work_dir"
}
trap cleanup EXIT

echo "=== Test 1: force-adds paths ignored by destination .gitignore (lib/) ==="
work_dir=$(mktemp -d)
cd "$work_dir"

git init -q template
cd template
rel_path=".github/scripts/squawk/tests/fixtures/nested/lib/emr_db/alembic.ini"
mkdir -p "$(dirname "$rel_path")"
echo "fleet defaults" > "$rel_path"
git add -A
git commit -qm "template init"
cd ..

git init -q dest_repo
cd dest_repo
echo 'lib/' > .gitignore
git add .gitignore
git commit -qm "dest init"
cd ..

printf '%s\n' "$rel_path" > files_to_sync.txt
FILES_LIST_ABS="$(pwd)/files_to_sync.txt"

cd dest_repo
bash "$STAGE_SCRIPT" "../template" "$FILES_LIST_ABS"

git diff --staged --quiet && { echo "Expected staged changes for gitignored lib/ path"; exit 1; }
git ls-files --error-unmatch -- "$rel_path" >/dev/null || { echo "Expected $rel_path in index"; exit 1; }
echo "Test 1 passed."

echo "=== Test 2: applies executable bit from template ==="
work_dir=$(mktemp -d)
cd "$work_dir"

git init -q template
cd template
mkdir -p scripts
printf '%s\n' '#!/usr/bin/env bash' 'echo hi' > scripts/run.sh
chmod +x scripts/run.sh
git add scripts/run.sh
git commit -qm "template init"
cd ..

git init -q dest_repo
cd dest_repo
git commit --allow-empty -qm "dest init"
cd ..

printf 'scripts/run.sh\n' > files_to_sync.txt
FILES_LIST_ABS="$(pwd)/files_to_sync.txt"

cd dest_repo
bash "$STAGE_SCRIPT" "../template" "$FILES_LIST_ABS"

mode=$(git ls-files -s -- scripts/run.sh | awk '{print $1}')
[[ "$mode" == 100755 ]] || { echo "Expected executable mode 100755, got $mode"; exit 1; }
echo "Test 2 passed."

echo "All stage-files tests passed."
