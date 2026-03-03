# Template sync: push-based flow that opens PRs

## Implementation

Template sync is implemented as a **push-based flow that opens PRs**. Sync logic lives in the **repo-sync-action** ([surefirev2/repo-sync-action](https://github.com/surefirev2/repo-sync-action)). Your template repo calls the action from a workflow and provides a config file.

- **Trigger:** Push to `main` (sync runs) or `pull_request` to `main` (preview only: target repos and file list are shown in the job summary; no sync).
- **Workflow:** In your template repo, add a workflow that checks out the repo, creates a token, and runs `uses: surefirev2/repo-sync-action@v1`. The action reads `.github/template-sync.yml` in that repo for:
  - **Repos:** `repositories` lists exact repo names and/or glob patterns; patterns are resolved via `gh repo list`.
  - **Files:** If `include_paths` is non-empty, only those paths are synced (allowlist). Otherwise `exclude_paths` is used as a blacklist.
- **Behavior:** For each dependent repo, the action clones the repo, copies the included files from the template into branch `chore/template-sync`, pushes the branch, and creates a pull request (or updates the existing PR if one is already open for that branch). There is **no direct push to the default branch** of dependents.
- **Result:** Each dependent gets a PR; required status checks run on the PR. Merge is manual or can be automated. No automerge workflow is provided.

## Config

Full schema and behavior are documented in [template-sync-config-schema.md](template-sync-config-schema.md). Summary:

- **.github/template-sync.yml** (in your template repo):
  - `repositories`: (required) list of downstream repo names and/or glob patterns. Patterns are resolved against the org; exact names are used as-is.
  - `include_paths`: (optional) allowlist of paths to sync to all repos. If non-empty, only these paths are synced (allowlist mode). Paths may end with `/*` for directory trees.
  - `repo_include_paths`: (optional) per-repo overrides; map a repo name to its path list (merged with global include_paths where applicable).
  - `exclude_paths`: (optional) blacklist; used only when `include_paths` is empty. When both are present, the scripts use `include_paths` as the source of truth and do not combine allowlist and blacklist.

## Testing

- **Dry run:** In your template repo, go to **Actions → Template Sync → Run workflow**. Check **Dry run (no clone/push/PR)** and run. The job will resolve config, build the file list, and run the sync in dry-run mode (logs show which repos and files would be synced; no clone, push, or PR).
- **Draft PR:** Run workflow with **Create PRs as draft** checked (and **Dry run** unchecked) to open template-sync PRs as drafts in each dependent.
- **Local dry-run:** From your template repo root, after resolving config and building the file list (e.g. by running the same steps as the workflow), run: `DRY_RUN=1 ORG=your-org REPOS_LIST="repo1 repo2" FILES_LIST=files_to_sync.txt bash path/to/repo-sync-action/src/template-sync-push-pr.sh --dry-run`. No token required for dry-run.

## Permissions

The GitHub App token used by the workflow must have on each dependent repo at least:

- `contents: write` (create branch, push commits).
- `pull_requests: write` (create and update PRs).
