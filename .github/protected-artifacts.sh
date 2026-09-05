#!/usr/bin/env bash
# Protected artifacts — files this repository declares immutable once written.
#
# The rule already exists in prose: snapshots/LEDGER-HEADER.md says its files
# "are never edited, reformatted, or 'fixed'", and documentation/plan-workspace.md
# calls changes/ "immutable change records". Nothing enforced either. This does,
# at the one boundary every route to the tree has to cross: the git diff.
#
# A PreToolUse hook was considered and rejected — it sees Edit/Write and nothing
# else, and the edits it would have needed to catch this week went through Bash.
# A hash verifier for the snapshot ledgers was rejected too: the diff already
# covers them, and a second mechanism is a second thing to drift.
#
# What it protects (git pathspec globs, nothing else):
PROTECTED=(
  ':(glob)docs/plans/*/snapshots/**'
  ':(glob)docs/plans/*/changes/CR-*.md'
)
# evidence/** is deliberately NOT here. plan-workspace.md:26 says evidence is
# "committed with audit.md"; :29 says changes are "immutable change records".
# Different contracts on adjacent lines. Only one of them is a never-edit rule.
#
# Additions pass. Modifications, deletions, renames and type changes fail.
# History is corrected by adding a new record, never by rewriting the old one,
# so there is no bypass flag and none should be added.
#
# Usage:
#   .github/protected-artifacts.sh local              staged index vs HEAD
#   .github/protected-artifacts.sh local --worktree   working tree vs HEAD
#   .github/protected-artifacts.sh ci                 range from GitHub event vars
#
# Lives in .github/ deliberately, beside release.sh: scripts/ is subject to the
# wiring sweep, and a check invoked by CI and pre-commit is neither a hook nor a
# command.

set -uo pipefail
cd "$(dirname "$0")/.."

die() { echo "ERROR: $1" >&2; exit 2; }

resolves() { git cat-file -e "$1^{commit}" 2>/dev/null; }

# --- pick the range ----------------------------------------------------------

MODE="${1:-}"
DIFF_ARGS=()
DESC=""

case "$MODE" in
  local)
    if [ "${2:-}" = "--worktree" ]; then
      DIFF_ARGS=(HEAD); DESC="working tree vs HEAD"
    else
      DIFF_ARGS=(--cached HEAD); DESC="staged index vs HEAD"
    fi
    ;;

  ci)
    EVENT="${GITHUB_EVENT_NAME:-}"
    case "$EVENT" in
      pull_request)
        BASE="${PR_BASE_SHA:-}"; HEAD_SHA="${PR_HEAD_SHA:-}"
        [ -n "$BASE" ] && [ -n "$HEAD_SHA" ] || die "pull_request: PR_BASE_SHA and PR_HEAD_SHA must be set"
        resolves "$BASE"     || die "pull_request: base $BASE is not fetched — set fetch-depth: 0 on the checkout"
        resolves "$HEAD_SHA" || die "pull_request: head $HEAD_SHA is not fetched"
        # Three dots: diff from the merge-base, so commits that landed on the
        # base branch after the PR forked do not read as the PR's changes.
        DIFF_ARGS=("$BASE...$HEAD_SHA"); DESC="pull_request: merge-base($BASE, $HEAD_SHA) -> $HEAD_SHA"
        ;;
      push)
        BASE="${PUSH_BEFORE_SHA:-}"; HEAD_SHA="${GITHUB_SHA:-}"
        [ -n "$BASE" ] && [ -n "$HEAD_SHA" ] || die "push: PUSH_BEFORE_SHA and GITHUB_SHA must be set"
        # All zeros is branch creation, not a force-push — GitHub reports
        # `forced` separately. Either way there is no range to check.
        case "$BASE" in 0000000000000000000000000000000000000000)
          die "push: before-SHA is zero (branch creation) — no range to check, refusing to pass vacuously" ;;
        esac
        # A force-push leaves `before` pointing at a commit that may no longer be
        # reachable. Narrowing the range would let the rewrite through; fail.
        resolves "$BASE"     || die "push: before-SHA $BASE is unresolvable (force-push or shallow clone) — refusing to narrow the range"
        resolves "$HEAD_SHA" || die "push: $HEAD_SHA is not fetched"
        DIFF_ARGS=("$BASE..$HEAD_SHA"); DESC="push: $BASE -> $HEAD_SHA"
        ;;
      workflow_dispatch)
        REF="${GITHUB_REF_NAME:-}"
        HEAD_SHA=$(git rev-parse HEAD)
        if [ "$REF" = "main" ]; then
          # merge-base(HEAD, origin/main) == HEAD on main, so that range would be
          # empty and pass vacuously. The smallest honest contract a no-input
          # dispatch can offer is the latest commit. On a merge commit HEAD^ is
          # the first parent, which makes the range cover everything the merge
          # brought in — that is the intent; do not "fix" it to HEAD^2.
          resolves "HEAD^" || die "workflow_dispatch on main: HEAD has no parent (root commit) — no range to check"
          DIFF_ARGS=("HEAD^..HEAD"); DESC="workflow_dispatch on main: HEAD^ -> HEAD ($HEAD_SHA)"
        else
          resolves origin/main || die "workflow_dispatch on $REF: origin/main is not fetched — set fetch-depth: 0"
          MB=$(git merge-base origin/main HEAD) || die "workflow_dispatch on $REF: no merge-base with origin/main"
          DIFF_ARGS=("$MB..HEAD"); DESC="workflow_dispatch on $REF: merge-base with origin/main ($MB) -> HEAD ($HEAD_SHA)"
        fi
        ;;
      *)
        die "ci: unsupported GITHUB_EVENT_NAME '${EVENT}' — this check knows pull_request, push and workflow_dispatch"
        ;;
    esac
    ;;

  *)
    echo "usage: protected-artifacts.sh local [--worktree] | ci" >&2; exit 2 ;;
esac

# --- run it ------------------------------------------------------------------

echo "protected artifacts: $DESC"

# -M so a rename reads as R with its source path, not D + A. The pathspec then
# keeps any change whose source or destination is protected.
VIOLATIONS=$(git diff --name-status -M --diff-filter=MDRT "${DIFF_ARGS[@]}" -- "${PROTECTED[@]}")

if [ -n "$VIOLATIONS" ]; then
  echo "ERROR: protected artifacts were modified, deleted, renamed or retyped:" >&2
  echo "$VIOLATIONS" | sed 's/^/    /' >&2
  echo "" >&2
  echo "These records are immutable once written. Correct history by ADDING a new" >&2
  echo "change record or snapshot; never by editing the old one. There is no bypass." >&2
  exit 1
fi

ADDED=$(git diff --name-status --diff-filter=A "${DIFF_ARGS[@]}" -- "${PROTECTED[@]}" | wc -l | tr -d ' ')
echo "  ok:  0 protected artifacts modified, deleted, renamed or retyped ($ADDED added)"
