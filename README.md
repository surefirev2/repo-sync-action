# repo-sync-action

Reusable GitHub Action that syncs files from a **template** repository to many downstream repositories via pull requests. Add the action to your template repo; sync logic lives in this repo.

## Usage

In your **template** repository (the repo that holds the canonical files), add a workflow that runs this action:

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

| Input         | Required | Default                     | Description |
|---------------|----------|-----------------------------|-------------|
| `config_path` | No       | `.github/template-sync.yml` | Path to template-sync config YAML (relative to the workspace). |
| `org`         | No       | `github.repository_owner`   | GitHub org used to resolve repo list and globs. |
| `token`       | No*      | `""`                        | GitHub token (e.g. from `create-github-app-token`). Required for non–dry-run; use empty for dry-run. |
| `dry_run`     | No       | `false`                     | If true, only log what would be synced; no clone, push, or PR. |
| `draft_pr`    | No       | `false`                     | If true, create or update PRs as draft. |

## Outputs

| Output       | Description |
|--------------|-------------|
| `repos_list` | Space-separated list of target repo names. |
| `count`      | Number of files that would be (or were) synced. |

## Config

In your template repo, add `.github/template-sync.yml` with `repositories` (downstream repo names or globs) and `include_paths` or `exclude_paths`. Schema and behavior are documented in [docs/template-sync-config-schema.md](docs/template-sync-config-schema.md).

## Permissions

The caller workflow must grant `contents: write` and `pull_requests: write`. Use a GitHub App (or token) with those permissions on each dependent repo.

## Docs

- [Config schema](docs/template-sync-config-schema.md) — `.github/template-sync.yml` format and allowlist/blacklist behavior.
- [Sync options](docs/template-sync-options.md) — triggers, dry-run, draft PRs, permissions.

## Development

This repo contains the action code only. Add the workflow and config in your template repo.

- **CI:** Lint (ShellCheck) and tests. [.github/workflows/ci.yaml](.github/workflows/ci.yaml)
- **Release:** Push a version tag (e.g. `v1.0.0`) to create a GitHub Release.
- **Pre-commit:** [.pre-commit-config.yaml](.pre-commit-config.yaml); run `pre-commit install`.

### Testing

- `make test` — bash test runners and pytest harness.
- `make test-bash` — bash scripts only.
- `make test-python` — pytest only.
