# Frozen pre-refactor baseline — commit `bf0a4e8`

**Do not edit anything in this directory.** It is a byte-exact snapshot of
commit `bf0a4e8a4444f9d5b2c9d865a39b7de2136f67ec`, extracted from the git
commit object, and it is the reference leg of the D10/D11 parity tests.

## Why it is here

The D10 refactor moved ten functions out of
`main_twoasset_ownership_kv.m`'s local-function block into `src_project/`,
and changed `solve_hank_dtpl_transition.m` (420 lines then, 473 now). The
parity question is whether that changed behaviour. Answering it requires
running the code **as it was** — and neither the current script nor
`kv_calibrate_on_grid` can serve, because both now call the moved files.

Originally this was done with a `git worktree`. That does not work here: the
project is distributed as a GitHub ZIP and extracted, so there is no `.git`
directory, `git rev-parse HEAD` returns `fatal: not a git repository`, and
the capture refused to run. The requirement was wrong, not the setup.

## What replaces git

`MANIFEST_bf0a4e8.sha256` lists the SHA-256 and byte length of all 152 `.m`
files. `kv_verify_baseline.m` re-hashes the directory and refuses to capture
unless every file matches.

That is **stronger** than the `HEAD == bf0a4e8` check it replaces. A commit
hash says where a checkout started; it says nothing about whether a file was
edited afterwards. A content manifest verifies the bytes about to execute.

Files that differ **only in line endings** (a ZIP extracted on Windows, or a
file resaved by an editor) are re-hashed after normalising CRLF to LF and
reported as content-intact rather than as corruption — MATLAB does not care
how a source file ends its lines, and conflating the two cases would send you
looking for a broken download that does not exist. A genuinely modified file
still fails: both controls are exercised, and the normalisation does not
excuse an edit.

`.gitattributes` marks this tree `-text` so git never rewrites its line
endings on checkout or ZIP export.

## This is not a reimplementation

The instruction *"do not recreate the old implementation inside the current
source tree"* stands, and this does not breach it. Nothing here is rewritten
or reconstructed. The files are byte-identical copies of the commit; they live
**outside** both source trees; and no driver puts them on the MATLAB path.
The main drivers add `genpath(<root>/src)` and `genpath(<proj>/src_project)`,
neither of which reaches here.

`main_baseline_capture.m` adds these directories **only** after
`restoredefaultpath`, asserts that `main_twoasset_ownership_kv` resolves
inside this tree *and* that it declares eleven functions (the post-refactor
file declares one), and restores the caller's path and working directory on
exit. `run_project_path_setup.m` errors if this directory is ever found on the
main path.

## Usage

From the main `research_green_deficits` folder, in MATLAB:

```matlab
clear; main_baseline_capture              % benchmark grid
clear; FAST = true; main_baseline_capture % must match the parity run's FAST
```

Writes `output/baseline/baseline_d10_<tag>.mat`,
`baseline_d11_<tag>.mat` and `baseline_capture.txt` into the **main** tree.
Nothing is written here.

## Contents

| | |
|---|---|
| `research_green_deficits/**/*.m` | 117 files, incl. the pre-refactor `main_twoasset_ownership_kv.m` (787 lines, 11 local functions) |
| `src/**/*.m` | 29 files |
| `MANIFEST_bf0a4e8.sha256` | 152 rows: sha256, bytes, path |
