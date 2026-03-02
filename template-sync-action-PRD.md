# Template Sync Action — Product Requirements Document

## Mission

Provide a reusable, secure, and well-tested GitHub Action that syncs files from a template repository to many downstream repositories via pull requests.

## Objective

Extract the template-sync functionality from `template-template` into a standalone, versioned, reusable action so that:

- Multiple template repositories (or the same one) can depend on it without copying scripts.
- Sync logic has a single source of truth, with semantic versioning and clear ownership.
- Consumers configure sync via a well-defined config file and call the action from a thin workflow.

## Goals

1. **Single source of truth** — All sync logic (resolve config, build file list, clone/copy/push/PR) lives in the new action repository; template repos only reference the action and hold config.
2. **Semantic versioning and immutable releases** — Action is released with tags (e.g. `v1.0.0`); consumers can pin to a fixed version; release process supports changelogs (e.g. from conventional commits).
3. **Backward-compatible config schema** — Existing [`.github/template-sync.yml`](.github/template-sync.yml) files work without modification; allowlist/blacklist and `repo_include_paths` behave as documented today.
4. **Documented inputs, outputs, and permissions** — Action exposes clear inputs (e.g. config path, org, token, dry-run, draft-pr) and outputs (e.g. repos-list, files-count); required GitHub App permissions are documented.
5. **Tested and linted codebase** — New repo includes CI for shell lint (e.g. shellcheck), tests (e.g. resolve-config and build-file-list with fixture configs), and optional integration/dry-run validation.

## Anti-goals

1. **No direct push to downstream default branches** — Sync always opens or updates a pull request; merging remains a separate, explicit step (manual or automated elsewhere).
2. **No breaking change to existing config schema** — The supported schema for [`.github/template-sync.yml`](.github/template-sync.yml) (repositories, include_paths, exclude_paths, repo_include_paths) will not be changed in a breaking way without a documented migration path.
3. **No new required permissions** — The action will not require permissions beyond what the GitHub App already uses today: `contents: write` and `pull_requests: write` on downstream repos.

---

## User stories and acceptance criteria

### US-1: Use action from template repo

**As a** maintainer of a template repository,
**I want** to use the sync action via `uses: org/template-sync-action@v1`
**so that** I do not maintain sync scripts in my repo.

| ID | Acceptance criteria |
|----|----------------------|
| AC-1.1 | The action repository provides an `action.yml` with required inputs (e.g. config path, org, token) and optional inputs (e.g. dry-run, draft-pr). |
| AC-1.2 | A workflow in the template repo can run the full sync by calling the action (checkout + app token + single “use action” step). |
| AC-1.3 | Sync behavior matches current behavior: same target repos, same file set per repo, PRs created or updated in downstream repos. |

### US-2: Dry-run from Actions UI

**As a** maintainer of a template repository,
**I want** to run a dry-run from the Actions UI
**so that** I can see what would be synced without opening PRs.

| ID | Acceptance criteria |
|----|----------------------|
| AC-2.1 | `workflow_dispatch` (or equivalent) supports an input (e.g. `dry_run: true`) that enables dry-run mode. |
| AC-2.2 | When dry-run is enabled, the job logs show the same kind of output as today: list of target repos and list of files that would be synced per repo. |
| AC-2.3 | No clone, push, or PR is performed when dry-run is enabled. |

### US-3: Draft PRs when testing from a branch

**As a** maintainer of a template repository,
**I want** to open draft PRs when testing from a branch
**so that** I can review sync results before marking PRs ready.

| ID | Acceptance criteria |
|----|----------------------|
| AC-3.1 | The action accepts an option (e.g. `draft_pr: true`) to create or update PRs as draft in downstream repos. |
| AC-3.2 | When this option is set, all sync-created/updated PRs in downstream repos are in draft state. |

### US-4: Config schema unchanged for consumers

**As a** consumer of the action (template repo with an existing config),
**I want** the config schema to stay the same
**so that** I do not have to change my existing [`.github/template-sync.yml`](.github/template-sync.yml).

| ID | Acceptance criteria |
|----|----------------------|
| AC-4.1 | Existing [`.github/template-sync.yml`](.github/template-sync.yml) files that follow the current schema work without modification. |
| AC-4.2 | Allowlist mode (non-empty `include_paths`), blacklist mode (empty `include_paths`, non-empty `exclude_paths`), and `repo_include_paths` overrides behave as documented in [docs/template-sync-config-schema.md](docs/template-sync-config-schema.md). |

### US-5: CI runs on every PR (action repo)

**As a** developer of the template-sync action,
**I want** CI to run on every PR in the action repository
**so that** regressions are caught before merge.

| ID | Acceptance criteria |
|----|----------------------|
| AC-5.1 | CI runs shellcheck (and optionally shfmt) on all shell scripts in the action repo. |
| AC-5.2 | At least one test exercises resolve-config and/or build-file-list using fixture configs (e.g. sample `template-sync.yml` and expected `repos_list` / file lists); tests do not require real `gh` or git clone, or use DRY_RUN/mocks. |
| AC-5.3 | Optionally, an integration job runs the composite action in a minimal workflow with a test config and `dry_run: true` to verify action wiring. |

---

## CI to develop (new action repository)

The following CI should be implemented in the new template-sync action repository.

### Lint

| Job / step | Description |
|------------|-------------|
| **Shellcheck** | Run [ShellCheck](https://www.shellcheck.net/) on all shell scripts under `scripts/**/*.sh`. Fail on errors; consider config to allow optional warnings. |
| **shfmt (optional)** | Run [shfmt](https://github.com/mvdan/shfmt) to check (or fix) formatting of shell scripts. |
| **Trigger** | On pull request and push to default branch. |

### Unit / behavior tests

| Job / step | Description |
|------------|-------------|
| **Resolve-config tests** | Tests that run the resolve-config script with fixture configs in `test/fixtures/` (e.g. a sample `template-sync.yml` with literal repos and globs). Assert expected `repos_list` and generated `include_paths.txt` / `exclusions.txt`. Use a mock or stub for `gh repo list` so tests do not require GitHub API access. |
| **Build-file-list tests** | Tests that run the build-file-list script with fixture include/exclusion files and a minimal repo layout. Assert expected `files_to_sync*.txt` contents. No real git clone required. |
| **Trigger** | On pull request and push to default branch. |

### Integration (optional)

| Job / step | Description |
|------------|-------------|
| **Action wiring** | A job that checks out the action repo, runs the composite action in a minimal workflow (e.g. with a test config and `dry_run: true`). Verifies that the action runs end-to-end without performing real sync (no clone/push/PR). May run in the same repo using a local action reference. |
| **Trigger** | On pull request and push to default branch, or on release tags. |

### Release

| Job / step | Description |
|------------|-------------|
| **Release workflow** | On push of a version tag (e.g. `v*`), create a GitHub Release. Optionally generate a changelog from conventional commits. Do not use `--no-verify` for any git operations (per project rules). |
| **Tag strategy** | Prefer semantic versioning (e.g. `v1.0.0`). Document use of immutable releases and/or floating tags (e.g. `v1` for latest minor) in the action’s README. |

### Dependency and maintenance

| Job / step | Description |
|------------|-------------|
| **Dependabot / Renovate** | If the action or its workflows use third-party actions, enable Dependabot or Renovate for the new repo to keep action versions updated. |
| **pre-commit (optional)** | If the repo uses pre-commit, add hooks for shellcheck and optionally shfmt so developers get feedback locally. |
