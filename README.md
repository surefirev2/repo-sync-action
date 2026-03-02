# Template Sync Action

Reusable GitHub Action that syncs files from a template repository to many downstream repositories via pull requests. Template repos use this action with a config file; sync logic lives here as a single source of truth.

## Usage

Add a workflow in your template repository that checks out the repo, creates a token (e.g. via a GitHub App), and runs the action:

```yaml
name: Template Sync

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:
    inputs:
      dry_run:
        description: "Dry run (no clone/push/PR)"
        type: boolean
        default: false
      draft_pr:
        description: "Create PRs as draft"
        type: boolean
        default: false

permissions:
  contents: write
  pull-requests: write

jobs:
  template-sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: ${{ github.event_name == 'pull_request' && 2 || 1 }}

      - name: Create GitHub App token
        if: github.event_name == 'push' || github.event_name == 'workflow_dispatch' || github.event_name == 'pull_request'
        id: app-token
        uses: actions/create-github-app-token@v2
        with:
          app-id: ${{ vars.APP_ID }}
          private-key: ${{ secrets.PRIVATE_KEY }}
          owner: ${{ github.repository_owner }}

      - name: Run template sync
        uses: surefirev2/repo-sync-action@v1
        with:
          config_path: .github/template-sync.yml
          org: ${{ github.repository_owner }}
          token: ${{ steps.app-token.outputs.token }}
          dry_run: ${{ github.event_name == 'workflow_dispatch' && inputs.dry_run || false }}
          draft_pr: ${{ github.event_name == 'workflow_dispatch' && inputs.draft_pr || false }}
```

Pin to a full tag (e.g. `@v1.0.0`) for immutable releases.

## Inputs

| Input         | Required | Default                       | Description |
|---------------|----------|-------------------------------|-------------|
| `config_path` | No       | `.github/template-sync.yml`   | Path to template-sync config YAML (relative to workspace). |
| `org`         | No       | `github.repository_owner`     | GitHub org used to resolve repo list (and globs). |
| `token`       | No*      | `""`                          | GitHub token (e.g. from `create-github-app-token`). Required for non–dry-run; use empty for dry-run. |
| `dry_run`     | No       | `false`                       | If true, only log what would be synced; no clone, push, or PR. |
| `draft_pr`    | No       | `false`                       | If true, create or update PRs as draft. |

## Outputs

| Output       | Description |
|--------------|-------------|
| `repos_list` | Space-separated list of target repo names. |
| `count`      | Number of files that would be (or were) synced. |

## Permissions

The caller workflow must grant:

- `contents: write` — create branches and push commits in downstream repos.
- `pull_requests: write` — create and update PRs in downstream repos.

Use a GitHub App (or token) that has these permissions on each dependent repo.

## Config

Sync targets and file sets are defined in `.github/template-sync.yml` in your template repo. Schema and behavior (allowlist, blacklist, `repo_include_paths`) are documented in [docs/template-sync-config-schema.md](docs/template-sync-config-schema.md).

## Docs

- [Config schema](docs/template-sync-config-schema.md) — `.github/template-sync.yml` format and allowlist/blacklist behavior.
- [Sync options](docs/template-sync-options.md) — workflow triggers, dry-run, draft PRs, and permissions.

## Development

- **CI:** Lint (ShellCheck), unit tests (resolve-config and build-file-list with fixtures), and optional integration (dry-run). See [.github/workflows/ci.yaml](.github/workflows/ci.yaml).
- **Release:** Push a version tag (e.g. `v1.0.0`) to create a GitHub Release.
- **Pre-commit:** [.pre-commit-config.yaml](.pre-commit-config.yaml) for local checks; run `pre-commit install`.

### Testing

- **All tests:** `make test` (runs bash test runners and the pytest harness).
- **Bash-only tests:** `make test-bash` (runs the `test/run-*-tests.sh` scripts directly).
- **Python harness tests:** `make test-python` (installs `requirements.txt` and runs `pytest`).
