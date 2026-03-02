# template-template

Template repository that syncs selected files to dependent repos via GitHub Actions. On push to `main` (or when opening a PR), the workflow clones each configured downstream repo, copies only the allowlisted paths, and opens or updates a PR with the changes.

## How it works

- **Config:** [`.github/template-sync.yml`](.github/template-sync.yml) defines `repositories` and `include_paths` (and optional `repo_include_paths` per repo). Paths can be exact (e.g. `.github/workflows/sync.yaml`) or globs (e.g. `.github/scripts/*`), which expand to all tracked files under that directory in this repo only—child repos keep any extra files they have.
- **Workflow:** [`.github/workflows/sync.yaml`](.github/workflows/sync.yaml) runs on push/PR to `main` and on `workflow_dispatch`. It resolves dependents from the config, builds a per-repo file list, then for each repo: clone, copy listed files, commit, push branch, create or update PR.
- **Scripts:** [`.github/scripts/`](.github/scripts/) contain the sync logic (resolve config, build file list, push and open PRs). These are synced to repos that have them in `repo_include_paths`.

## Setup

- **GitHub App:** The sync workflow needs a GitHub App token (`vars.APP_ID`, `secrets.PRIVATE_KEY`) with `contents: write` and `pull-requests: write` so it can push branches and open/update PRs in dependent repos.
- **Dependents:** Add repo names (or globs resolved via `gh repo list`) under `repositories` in `.github/template-sync.yml`. Use `include_paths` for the default file set and `repo_include_paths` for per-repo overrides.

## Docs

- [Config schema](docs/template-sync-config-schema.md) — `.github/template-sync.yml` format and allowlist/blacklist behavior.
- [Sync options](docs/template-sync-options.md) — workflow inputs and behavior.

## Development

- **Pre-commit:** [`.pre-commit-config.yaml`](.pre-commit-config.yaml) runs YAML/JSON checks and basic hygiene. Install hooks with `pre-commit install`.
- **Ownership:** Files under `.github/workflows/sync.yaml` and `.github/scripts/` are owned by this template; changes there are overwritten on the next sync in repos that include them.
