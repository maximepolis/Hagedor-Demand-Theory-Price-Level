#!/usr/bin/env bash
# make_prerefactor_baseline.sh -- OPTIONAL. Check out the FROZEN pre-refactor
# commit in a separate git worktree.
#
# ============================ YOU PROBABLY DO NOT NEED THIS ============================
# The frozen baseline now SHIPS WITH THE PROJECT in <root>/baseline_bf0a4e8,
# verified by SHA-256 manifest rather than by git, so the capture works on a
# plain extracted ZIP:
#
#     (MATLAB, in research_green_deficits)   clear; main_baseline_capture
#
# This script exists only for someone working from a git CLONE who would rather
# materialise the commit themselves. It is not required, and nothing in the
# MATLAB pipeline calls it. See baseline_bf0a4e8/README.md.
# ======================================================================================
#
# The original rationale, which still applies to the worktree route:
#
# WHY A WORKTREE AND NOT A COPY. The point of the baseline is that it is the
# code at bf0a4e8, not a reconstruction of it. A worktree is produced by git
# from the commit object, so it cannot drift, cannot be edited by accident from
# the main tree, and its provenance is checkable with `git -C <dir> rev-parse
# HEAD`. Recreating the old local functions inside the current source tree --
# the obvious shortcut -- would defeat the whole exercise: the question is
# whether MOVING them changed behaviour, and a reconstruction is not the thing
# that was moved.
#
# WHY NOT `git stash` / `git checkout bf0a4e8`. Both mutate the working tree,
# so a run interrupted halfway leaves the project in an unknown state, and
# neither lets the baseline and the current code be on disk at the same time --
# which they must be, because MATLAB has to run both in one session sequence.
#
# The ONLY file added to the worktree is the capture driver, which is copied in
# rather than committed. It reads the pre-refactor code; it does not modify it.
# `verify` below re-checks that nothing else differs from the commit.
#
# USAGE
#   ./make_prerefactor_baseline.sh create    # make the worktree
#   ./make_prerefactor_baseline.sh verify    # prove it is clean and at bf0a4e8
#   ./make_prerefactor_baseline.sh remove    # tear it down
#
# The worktree is placed OUTSIDE the repository so that genpath() in the
# current tree can never reach it and silently shadow a current function with
# its pre-refactor namesake -- which would be the same class of bug as the
# solve_household_egm collision.

set -euo pipefail

BASELINE_COMMIT="bf0a4e8a4444f9d5b2c9d865a39b7de2136f67ec"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WT_DIR="$(dirname "$REPO_ROOT")/dtpl-baseline-bf0a4e8"
PROJ="research_green_deficits"

usage() { sed -n '2,40p' "$0"; exit 1; }

case "${1:-}" in
  create)
    if [ -d "$WT_DIR" ]; then
      echo "worktree already exists: $WT_DIR"
      echo "run '$0 verify' to check it, or '$0 remove' first."
      exit 0
    fi
    git -C "$REPO_ROOT" worktree add --detach "$WT_DIR" "$BASELINE_COMMIT"
    cp "$REPO_ROOT/$PROJ/main_baseline_capture.m" "$WT_DIR/$PROJ/"
    echo
    echo "baseline worktree : $WT_DIR"
    echo "commit            : $(git -C "$WT_DIR" rev-parse HEAD)"
    echo
    echo "The ONLY file added is main_baseline_capture.m. Nothing else was touched."
    echo
    echo "Next, in MATLAB:"
    echo "  cd('$WT_DIR/$PROJ')"
    echo "  clear; restoredefaultpath; BASELINE_OUT = '$REPO_ROOT/$PROJ/output/baseline';"
    echo "  main_baseline_capture"
    ;;

  verify)
    [ -d "$WT_DIR" ] || { echo "no worktree at $WT_DIR; run '$0 create'"; exit 1; }
    head="$(git -C "$WT_DIR" rev-parse HEAD)"
    echo "worktree : $WT_DIR"
    echo "HEAD     : $head"
    if [ "$head" != "$BASELINE_COMMIT" ]; then
      echo "!! HEAD is NOT the frozen baseline commit $BASELINE_COMMIT"
      exit 1
    fi
    # Untracked capture driver is expected; ANY tracked modification is not.
    modified="$(git -C "$WT_DIR" status --porcelain | grep -v '^?? ' || true)"
    if [ -n "$modified" ]; then
      echo "!! tracked files differ from the commit:"
      echo "$modified"
      exit 1
    fi
    untracked="$(git -C "$WT_DIR" status --porcelain | grep '^?? ' || true)"
    echo "tracked files : IDENTICAL to $BASELINE_COMMIT"
    echo "untracked     : ${untracked:-(none)}"
    echo
    echo "OK: the baseline is the commit, unmodified."
    ;;

  remove)
    git -C "$REPO_ROOT" worktree remove --force "$WT_DIR" 2>/dev/null || rm -rf "$WT_DIR"
    git -C "$REPO_ROOT" worktree prune
    echo "removed $WT_DIR"
    ;;

  *) usage ;;
esac
