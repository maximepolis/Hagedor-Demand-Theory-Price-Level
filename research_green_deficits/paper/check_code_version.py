#!/usr/bin/env python3
"""Check that the revision string carried in the source agrees with
CODE_VERSION.txt.

WHY THIS EXISTS. The pipeline revision is printed at the top of every driver
so that a pasted console log identifies the code that produced it. That only
works if the printed revision IS the code's revision. Three consecutive
extractions on the collaborator's machine delivered drivers from R11.26,
R11.28 and R11.30 while every banner read "pipeline R11.19": the unpacker was
refreshing the .m files and leaving CODE_VERSION.txt alone, so the banner
named a revision that had not run in days.

kv_code_version.m now carries the revision as a constant, EXPECTED, and shouts
when it disagrees with the text file -- a fact rather than a date heuristic,
because the .m files are the ones the extraction updates. The cost is that the
revision lives in two places. This check is what makes that cost safe: it
fails if a bump lands in one place and not the other, which is exactly the
mistake the two-copy design would otherwise introduce.

Exit 0 when they agree, 1 when they do not.
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
PROJ = HERE.parent
VERSION_FILE = PROJ / "CODE_VERSION.txt"
SOURCE_FILE = PROJ / "src_project" / "kv_code_version.m"


def version_from_txt(path):
    """First non-blank, non-comment line -- the same rule kv_code_version uses."""
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        t = line.strip()
        if t and not t.startswith("#"):
            return t
    return None


def version_from_source(path):
    """The EXPECTED assignment, ignoring the comment block that explains it.

    Anchored to the start of a line so the several mentions of EXPECTED inside
    that comment -- which begin with '%' -- cannot match.
    """
    pat = re.compile(r"^\s*EXPECTED\s*=\s*'([^']+)'\s*;", re.MULTILINE)
    hits = pat.findall(path.read_text(encoding="utf-8", errors="replace"))
    if len(hits) != 1:
        return None if not hits else hits[0]
    return hits[0]


def main():
    for f in (VERSION_FILE, SOURCE_FILE):
        if not f.exists():
            print(f"MISSING: {f}")
            return 1

    txt = version_from_txt(VERSION_FILE)
    src = version_from_source(SOURCE_FILE)

    if txt is None:
        print(f"FAIL: no revision line found in {VERSION_FILE.name}")
        return 1
    if src is None:
        print(f"FAIL: no unique EXPECTED = '...' assignment in {SOURCE_FILE.name}")
        return 1

    if txt != src:
        print(f"FAIL: {VERSION_FILE.name} says {txt}, "
              f"{SOURCE_FILE.name} says {src}.")
        print("Bump both, or the banner will misreport the running revision.")
        return 1

    print(f"OK: revision {txt} agrees in CODE_VERSION.txt and kv_code_version.m")
    return 0


if __name__ == "__main__":
    sys.exit(main())
