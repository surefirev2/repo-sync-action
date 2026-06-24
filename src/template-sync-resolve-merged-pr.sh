#!/usr/bin/env bash
# Resolve parent PR number after merge to main (for reusing draft downstream branches).
# Uses same-repo API + commit-message fallbacks. Emits GitHub Actions output when
# GITHUB_OUTPUT is set; otherwise prints "number=<n>" to stdout.
set -euo pipefail

repository="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY required}"
sha="${GITHUB_SHA:?GITHUB_SHA required}"

_valid_pr() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

_emit_output() {
  local pr="$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "number=${pr}" >>"$GITHUB_OUTPUT"
  else
    echo "number=${pr}"
  fi
}

pr=""
if command -v gh >/dev/null 2>&1 && [[ -n "${GH_TOKEN:-}" ]]; then
  pr=$(gh api "repos/${repository}/commits/${sha}/pulls" --jq '.[0].number' 2>/dev/null || true)
fi

if ! _valid_pr "$pr"; then
  pr=$(git log -1 --pretty=%B "$sha" 2>/dev/null | sed -n 's/^Merge pull request #\([0-9]*\) from .*/\1/p' || true)
fi

if ! _valid_pr "$pr"; then
  pr=$(git log -1 --pretty=%B "$sha" 2>/dev/null | sed -n 's/.*(#\([0-9]*\)).*/\1/p' | head -1)
fi

if _valid_pr "$pr"; then
  _emit_output "$pr"
  echo "Merged PR number: $pr (will reuse draft PR branch)" >&2
else
  _emit_output ""
  echo "Not a merge of a PR; sync will use branch without PR suffix" >&2
fi
