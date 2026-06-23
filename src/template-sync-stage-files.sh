#!/usr/bin/env bash
#
# Copy synced files into the current directory (destination repo root) and stage them.
# Usage: (cd dest_repo && bash template-sync-stage-files.sh <source_dir> <files_list_abs>)
# The source_dir is the template repository root (parent of synced paths).
set -euo pipefail
if [[ -n "${DEBUG:-}" ]]; then set -x; fi

SOURCE_DIR="${1:?source_dir required}"
FILES_LIST_ABS="${2:?files_list_abs required}"

[[ -f "$FILES_LIST_ABS" ]] || { echo "Files list not found: $FILES_LIST_ABS" >&2; exit 1; }

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  mkdir -p "$(dirname "$f")"
  cp "$SOURCE_DIR/$f" "$f"
done < "$FILES_LIST_ABS"

# Force-add only synced paths so destination .gitignore (e.g. lib/) cannot skip them.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  git add -f -- "$f"
done < "$FILES_LIST_ABS"

# Mirror executable bit from template; skip paths that did not stage.
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if ! git ls-files --error-unmatch -- "$f" >/dev/null 2>&1; then
    echo "  warning: $f not in index after git add -f; skipping mode sync" >&2
    continue
  fi
  mode=$(git -C "$SOURCE_DIR" ls-files -s -- "$f" 2>/dev/null | awk '{print $1}')
  if [[ "$mode" == 100755 ]]; then
    git update-index --chmod=+x "$f"
  elif [[ "$mode" == 100644 ]]; then
    git update-index --chmod=-x "$f"
  fi
done < "$FILES_LIST_ABS"
