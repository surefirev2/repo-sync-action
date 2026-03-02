# Template sync config schema

This document defines the supported schema for `.github/template-sync.yml`. All consumers should use this format so that the template-sync scripts resolve targets and file lists correctly.

## Schema

### `repositories` (required)

List of downstream repo names and/or glob patterns. Exact names are used as-is; patterns (e.g. `terraform-*`) are resolved via `gh repo list` against the org in [template-sync-resolve-config.sh](../.github/scripts/template-sync-resolve-config.sh).

### `include_paths` (optional)

Allowlist of paths to sync. When non-empty, **only** these paths are synced to all repos (unless overridden per repo via `repo_include_paths`). Paths may end with `/*` to mean all tracked files under that directory (e.g. `.github/scripts/*`); see [template-sync-build-file-list.sh](../.github/scripts/template-sync-build-file-list.sh).

### `exclude_paths` (optional)

Blacklist of paths not to sync. **Used only when `include_paths` is empty.** When `include_paths` has any entries, the scripts use allowlist mode only and do not apply `exclude_paths`.

### `repo_include_paths` (optional)

Per-repo overrides. Map a repo name to a list of paths; that repo gets the global `include_paths` plus its own list (merged). Use for repos that should receive extra paths or a different set. See resolve-config and build-file-list for the merge behavior.

## Allowlist vs blacklist

- If **`include_paths` is non-empty**, it is the allowlist: only those paths are synced. `exclude_paths` is ignored.
- If **`include_paths` is empty**, `exclude_paths` is used as a blacklist: all tracked files are synced except those matching the blacklist.

When both keys are present in the file, the scripts treat `include_paths` as the source of truth for mode: they do not combine allowlist and blacklist. So a non-empty `include_paths` always selects allowlist mode.

## Unsupported / legacy keys

The scripts **do not** read `additional:` or `files:` (or other alternate keys). If a consumer used such keys in the past, they must migrate to `repositories`, `include_paths`, `exclude_paths`, and `repo_include_paths` as defined above. No changes to synced scripts are required once the config file uses the supported schema.
