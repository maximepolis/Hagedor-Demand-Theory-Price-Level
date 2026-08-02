#!/usr/bin/env python3
"""Structural checks on the manuscript that do not require a TeX run.

WHY THIS EXISTS. A length pass moves and deletes blocks, and the failure mode
is silent: a \\ref that no longer resolves compiles to "??" rather than an
error, a \\label deleted with its block leaves every citation of it dangling,
and a block "moved to the appendix" can land in the wrong section without the
document complaining at all. That last one has already happened once in this
project -- a demotion matched a body subsection before the intended appendix
one, the body never shrank, and a clean compile was taken as proof it had.

So the checks here are the ones a compile does NOT give you:
  * every \\ref/\\eqref/\\autoref/\\cref target exists
  * no duplicate \\label
  * every \\cite key is in the .bib
  * no label defined but never referenced (dead weight, not an error)
  * section-by-section line budget, so a length pass can be audited by
    section rather than by a single total that hides where the cuts landed
  * environment balance (\\begin/\\end), which a compile does catch but only
    after a long run

Usage:  python3 check_tex.py [main.tex] [refs.bib]
Exit code is nonzero if any HARD check fails, so it can gate a commit.
"""
import re
import sys
import os
from collections import Counter, OrderedDict

HARD = []          # failures that must block
SOFT = []          # things worth knowing


def strip_comments(text):
    """Remove TeX comments but keep escaped percent signs."""
    out = []
    for line in text.split("\n"):
        buf, i, n = [], 0, len(line)
        while i < n:
            c = line[i]
            if c == "\\" and i + 1 < n:
                buf.append(line[i:i + 2]); i += 2; continue
            if c == "%":
                break
            buf.append(c); i += 1
        out.append("".join(buf))
    return "\n".join(out)


def load(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return fh.read()


def check_labels(body):
    labels = re.findall(r"\\label\{([^}]*)\}", body)
    dup = [k for k, v in Counter(labels).items() if v > 1]
    if dup:
        HARD.append("duplicate \\label: " + ", ".join(sorted(dup)))

    refs = set()
    for pat in (r"\\ref\{([^}]*)\}", r"\\eqref\{([^}]*)\}",
                r"\\autoref\{([^}]*)\}", r"\\cref\{([^}]*)\}",
                r"\\Cref\{([^}]*)\}", r"\\pageref\{([^}]*)\}"):
        for m in re.findall(pat, body):
            for k in m.split(","):
                k = k.strip()
                if k:
                    refs.add(k)
    lab = set(labels)
    dangling = sorted(refs - lab)
    if dangling:
        HARD.append("\\ref to a label that does not exist: " + ", ".join(dangling))
    unused = sorted(lab - refs)
    if unused:
        SOFT.append("%d labels defined but never referenced" % len(unused))
    return lab, refs


def check_cites(body, bibpath):
    if not bibpath or not os.path.exists(bibpath):
        SOFT.append("no .bib given; citation keys not checked")
        return
    bib = load(bibpath)
    keys = set(re.findall(r"@\w+\s*\{\s*([^,\s]+)", bib))
    used = set()
    for m in re.findall(r"\\cite[a-zA-Z]*\s*(?:\[[^\]]*\])*\s*\{([^}]*)\}", body):
        for k in m.split(","):
            k = k.strip()
            if k:
                used.add(k)
    missing = sorted(used - keys)
    if missing:
        HARD.append("\\cite key not in the .bib: " + ", ".join(missing))


def check_envs(body):
    begins = re.findall(r"\\begin\{([^}]*)\}", body)
    ends = re.findall(r"\\end\{([^}]*)\}", body)
    cb, ce = Counter(begins), Counter(ends)
    for env in sorted(set(cb) | set(ce)):
        if cb[env] != ce[env]:
            HARD.append("environment %s: %d \\begin vs %d \\end"
                        % (env, cb[env], ce[env]))


def section_budget(text):
    """Lines per top-level section, split at \\appendix."""
    lines = text.split("\n")
    marks = []
    for i, ln in enumerate(lines):
        m = re.match(r"\s*\\(section|appendix|begin\{document\}|end\{document\})\b", ln)
        if m:
            title = ""
            t = re.search(r"\\section\{(.*?)\}", ln)
            if t:
                title = t.group(1)
            marks.append((i, m.group(1), title))
    rows, in_app = OrderedDict(), False
    for j, (i, kind, title) in enumerate(marks):
        nxt = marks[j + 1][0] if j + 1 < len(marks) else len(lines)
        if kind == "appendix":
            in_app = True
            continue
        if kind.startswith("begin") or kind.startswith("end"):
            continue
        key = ("APP  " if in_app else "BODY ") + (title or "(untitled)")
        rows[key] = rows.get(key, 0) + (nxt - i)
    return rows


def main():
    tex = sys.argv[1] if len(sys.argv) > 1 else "green_deficits_price_level.tex"
    bib = sys.argv[2] if len(sys.argv) > 2 else "refs.bib"
    raw = load(tex)
    body = strip_comments(raw)

    check_labels(body)
    check_cites(body, bib)
    check_envs(body)

    rows = section_budget(body)
    bodyln = sum(v for k, v in rows.items() if k.startswith("BODY"))
    appln = sum(v for k, v in rows.items() if k.startswith("APP"))

    print("=" * 66)
    print("SECTION BUDGET (source lines; a proxy for pages, not a substitute)")
    print("=" * 66)
    for k, v in rows.items():
        share = 100.0 * v / max(bodyln if k.startswith("BODY") else appln, 1)
        print("  %-52s %5d  %4.1f%%" % (k[:52], v, share))
    print("  %-52s %5d" % ("BODY TOTAL", bodyln))
    print("  %-52s %5d" % ("APPENDIX TOTAL", appln))
    print()

    if SOFT:
        print("NOTES")
        for s in SOFT:
            print("  - " + s)
        print()
    if HARD:
        print("FAILURES")
        for s in HARD:
            print("  ! " + s)
        print()
        print("RESULT: FAIL")
        return 1
    print("RESULT: PASS (structure is consistent; a TeX run is still required")
    print("        for spacing, floats and the true page count)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
