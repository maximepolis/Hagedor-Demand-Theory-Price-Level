#!/usr/bin/env python3
"""Flag stored results that are older than the code that writes them.

WHY THIS EXISTS. This project has now been bitten three separate times by a
result on disk that no longer corresponds to the code that produced it:

  * a FAST parity run overwrote the benchmark two-asset economy, because the
    parity driver's leg 2 saves to the same output file the paper reads;
  * the checked-in convenience-yield table was produced by a superseded
    version of its own driver and reports column headers the current code no
    longer prints;
  * the two-asset .mat carried no record of the grid it was solved on, so a
    coarse-grid economy could be read as the benchmark.

Each was found by hand, after the fact, and each could have silently reached
a table in the paper. Staleness is not a numerical error and no numerical
gate catches it, so it needs its own check.

WHAT IT DOES. For every artifact in output/ and output/tables/ it finds the
driver that WRITES it and compares the two files' last-commit dates. A driver
that merely reads an artifact does not count -- an earlier version of this
audit took the max over every file mentioning the name and flagged nearly
everything, because calibrated_results.mat is read by thirty drivers.

    .mat  writer = a file containing save(... 'name.mat' ...) in one statement
    .txt  writer = a file containing both fopen( and the literal 'name.txt'

LIMITS, STATED BECAUSE A CHECKER THAT OVERSELLS ITSELF IS WORSE THAN NONE.

  1. Git dates are DAY granularity. A driver edited and re-run on the same
     day looks fresh either way. That is exactly how the stale convenience
     .mat slipped through: its save-list gained a variable on the same day
     the .mat was committed. Same-day pairs are reported separately as
     UNVERIFIABLE rather than silently passed.
  2. Commit date is not run date. An artifact committed after its driver may
     still have been produced by an older copy of it. This check bounds the
     problem from one side only: STALE means definitely-suspect, fresh means
     not-caught-here.
  3. Artifacts with no writer in the project (Dynare output, variant runs
     whose tag is built at runtime) are listed, not judged.

EXIT: 0 if nothing is stale, 1 otherwise, so it can gate a release.

USAGE   python3 paper/check_output_staleness.py [--root .] [--quiet]
"""

import argparse
import glob
import os
import re
import subprocess
import sys


def last_commit(path):
    """Last commit date for a path, or None when git cannot answer."""
    try:
        out = subprocess.check_output(
            ["git", "log", "-1", "--format=%ad", "--date=short", "--", path],
            text=True, stderr=subprocess.DEVNULL,
        ).strip()
        return out or None
    except Exception:
        return None


def find_writers(root):
    """Map artifact basename -> set of driver paths that WRITE it."""
    writers = {}
    drivers = sorted(glob.glob(os.path.join(root, "*.m")) +
                     glob.glob(os.path.join(root, "src_project", "*.m")))
    for d in drivers:
        with open(d, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        # .mat: the filename must appear inside a save(...) statement, so a
        # load() of the same name does not make the loader a writer.
        for stmt in re.finditer(r"save\s*\(([^;]{0,400}?)\)\s*;", src, re.S):
            for name in re.findall(r"'([A-Za-z0-9_]+\.mat)'", stmt.group(1)):
                writers.setdefault(name, set()).add(d)
        # .txt: tables are usually opened through a variable
        # (sf = fullfile(tabdir, 'x.txt'); fid = fopen(sf, 'w')), so a bare
        # "contains fopen( and the literal" test is too loose -- it made the
        # parity driver a writer of the benchmark table merely because that
        # driver names the file in order to BACK IT UP. So: the literal must
        # either sit inside the fopen( call, or be assigned to a variable
        # that is later passed to fopen.
        if "fopen(" in src:
            for name in set(re.findall(r"'([A-Za-z0-9_]+\.txt)'", src)):
                lit = re.escape(name)
                direct = re.search(r"fopen\s*\([^;]{0,200}?'" + lit + r"'", src)
                indirect = False
                for asg in re.finditer(
                        r"(\w+)\s*=\s*[^;=]{0,200}?'" + lit + r"'", src):
                    var = re.escape(asg.group(1))
                    if re.search(r"fopen\s*\(\s*" + var + r"\b", src):
                        indirect = True
                        break
                if direct or indirect:
                    writers.setdefault(name, set()).add(d)
    return writers


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", default=os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))))
    ap.add_argument("--quiet", action="store_true",
                    help="print only the stale and unverifiable rows")
    args = ap.parse_args()
    root = args.root

    writers = find_writers(root)
    artifacts = (sorted(glob.glob(os.path.join(root, "output", "tables", "*.txt"))) +
                 sorted(glob.glob(os.path.join(root, "output", "*.mat"))))
    if not artifacts:
        print("no artifacts found under output/ -- nothing to check")
        return 0

    stale, sameday, unmapped, fresh, nodate = [], [], [], [], []
    for art in artifacts:
        base = os.path.basename(art)
        a_date = last_commit(art)
        ws = writers.get(base, set())
        if not ws:
            unmapped.append(base)
            continue
        w_dates = [(last_commit(w), w) for w in ws]
        w_dates = [(d, w) for d, w in w_dates if d]
        if not a_date or not w_dates:
            nodate.append(base)
            continue
        w_date, w_file = max(w_dates)
        row = (base, a_date, w_date, os.path.basename(w_file))
        if w_date > a_date:
            stale.append(row)
        elif w_date == a_date:
            sameday.append(row)
        else:
            fresh.append(row)

    def show(rows, tag):
        for base, a, w, wf in rows:
            print(f"  {tag} {base:<42} artifact {a}  writer {w}  <- {wf}")

    print(f"OUTPUT STALENESS AUDIT -- {len(artifacts)} artifacts under output/")
    print()
    if stale:
        print(f"STALE: {len(stale)} artifact(s) older than their writer.")
        print("Each was produced by a superseded version of its driver.")
        print()
        print("READ THE DIFF BEFORE PANICKING. This check cannot tell a changed")
        print("figure label from a changed equation, and in this project most")
        print("recent driver edits have been relabelling. A STALE verdict means")
        print("'regenerate, and find out which', not 'the numbers are wrong'.")
        print("  git log -p --since=<artifact date> -- <driver>")
        show(sorted(stale, key=lambda r: r[2], reverse=True), "STALE")
        print()
    else:
        print("STALE: none.")
        print()
    if sameday:
        print(f"UNVERIFIABLE: {len(sameday)} artifact(s) share a commit DATE with")
        print("their writer. Git dates are day-granular, so these cannot be")
        print("cleared or condemned here; regenerate if the result is load-bearing.")
        if not args.quiet:
            show(sorted(sameday), "  ??  ")
        print()
    if not args.quiet:
        if fresh:
            print(f"FRESH: {len(fresh)} artifact(s) newer than their writer.")
            print()
        if unmapped:
            print(f"NO WRITER FOUND: {len(unmapped)} artifact(s). External tools or")
            print("runtime-built filenames; not judged.")
            for b in sorted(unmapped):
                print(f"       {b}")
            print()
        if nodate:
            print(f"NO GIT DATE: {len(nodate)} artifact(s) -- untracked or new.")
            print()

    if stale:
        print("RESULT: FAIL -- regenerate the stale artifacts.")
        return 1
    print("RESULT: PASS (no artifact is older than its writer; read the")
    print("        UNVERIFIABLE list before treating this as a clean bill)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
