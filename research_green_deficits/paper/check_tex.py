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

  * macros whose backslash was eaten by a string escape, which leave the
    label graph intact and so are invisible to every check above

Usage:  python3 check_tex.py [main.tex] [references.bib]
        python3 check_tex.py --selftest      (controls for the mangled rule)
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


def lineno(body, pos):
    return body.count("\n", 0, pos) + 1


def context(body, pos, back=45, fwd=55):
    return " ".join(body[max(0, pos - back):pos + fwd].split())


# Macro tails left behind when a backslash is consumed as a C/Python string
# escape. "\ref" written inside a non-raw Python string is CR + "ef", "\begin"
# is BS + "egin", "\text" is TAB + "ext". The escape character then renders as
# nothing (or as a line break), so the visible output is "Appendix efapp:aggrisk"
# and the LABEL GRAPH IS UNTOUCHED -- there is no \ref to dangle, so a
# reference checker cannot see it and neither can the compiler.
#
# Each entry is (fragment, what it was). The fragments are chosen so that a
# preceding-letter veto is enough to rule out ordinary English and ordinary TeX:
# "ef{" is preceded by "r" in every legitimate \ref/\eqref/\autoref/\pageref.
MANGLED = [
    (r"ef\{",            r"\ref{  (\r eaten)"),
    (r"ef(?:app|subsec|sec|tab|fig|eq|prop|lem|thm|alg|rem):",
     r"\ref    (\r eaten AND the braces lost)"),
    (r"egin\{",          r"\begin{ (\b eaten)"),
    (r"ext(?:bf|it|sc|tt)?\{", r"\text...{ (\t eaten)"),
    (r"rac\{",           r"\frac{  (\f eaten)"),
    (r"ewcommand(?![A-Za-z])",     r"\newcommand (\n eaten)"),
    (r"ewline(?![A-Za-z])",        r"\newline (\n eaten)"),
    (r"otag(?![A-Za-z])",          r"\notag  (\n eaten)"),
    (r"oindent(?![A-Za-z])",       r"\noindent (\n eaten)"),
    (r"ightarrow(?![A-Za-z])",     r"\rightarrow (\r eaten)"),
    (r"ppendix(?![A-Za-z])",       r"\appendix (\a eaten)"),
    (r"arepsilon(?![A-Za-z])",     r"\varepsilon (\v eaten)"),
]


def check_mangled_macros(body):
    """Catch macros whose backslash was eaten by a string escape.

    This is the rule that was MISSING when the manuscript shipped a visible
    "Appendix efapp:aggrisk" on p.29. The earlier malformed-ref rule looked for
    "ef" followed directly by a label key, but the actual damage was
    "Appendix~\\n" + "ef{app:aggrisk}" -- the brace survived and a newline sat
    where the backslash had been, so nothing in the document was searchable as
    one string. Matching is therefore done on a body with newlines intact and
    with the fragment anchored only by "not preceded by a letter", which the
    newline satisfies.
    """
    for frag, was in MANGLED:
        for m in re.finditer(r"(?<![A-Za-z\\])" + frag, body):
            HARD.append("line %d: mangled macro, should be %s: ...%s..."
                        % (lineno(body, m.start()), was,
                           context(body, m.start())))


def check_malformed_refs(body):
    """Catch reference-shaped text that never became a \\ref.

    check_tex passed a document containing the visible string
    "Appendix efapp:aggrisk" because that is not a dangling \\ref -- it is
    literal text where a macro was mangled, so the label graph is perfectly
    consistent and the compile is clean. A checker that only walks that graph
    cannot see it.

    The method: blank out every WELL-FORMED reference and label first, then
    look for label-shaped fragments in what remains. Searching the raw body
    instead flags every legitimate \\ref{subsec:...} and is worse than
    useless -- a check that cries wolf gets switched off.
    """
    masked = re.sub(r"\\(?:label|ref|eqref|autoref|cref|Cref|pageref)\{[^}]*\}",
                    " ", body)
    KEYS = "app|subsec|sec|tab|fig|eq|prop|lem|thm|def|alg|rem"
    pats = [
        (r"\b(?:ef|efs)(?:%s):" % KEYS,
         "mangled \\ref (the backslash-r was eaten)"),
        (r"(?<![A-Za-z{\\])(?:%s):[A-Za-z][A-Za-z0-9_]*" % KEYS,
         "bare label key in running text"),
    ]
    for pat, why in pats:
        for m in re.finditer(pat, masked):
            ctx = masked[max(0, m.start()-45):m.start()+45]
            ctx = " ".join(ctx.split())
            HARD.append("%s: ...%s..." % (why, ctx))


def check_apostrophes(body):
    """Possessives that lost their apostrophe, e.g. 'the papers central object'."""
    for m in re.finditer(r"\b(paper|model|economy|referee|author|reader|"
                         r"household|government)s\s+(own|central|main|key|"
                         r"principal|first|second)\b", body):
        SOFT.append("line %d: possible missing apostrophe: ...%s..."
                    % (lineno(body, m.start()), context(body, m.start(), 30, 60)))


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


# ----------------------------------------------------------------------
# SELF-TEST.  A checker that reports PASS is worthless until you have seen
# it report FAIL on something. This project has already been burnt twice by
# checks that could not fail -- a terminal-dlnP identity and a hysteresis
# probe whose two branches were the same computation -- and the figure scan
# that read font metadata instead of axis labels was a third. So the
# controls for the mangled-macro rule live in the file, not in a shell
# history: `python3 check_tex.py --selftest`.
#
# POS must all FIRE; NEG must all stay CLEAN. NEG is the half that matters:
# an over-eager rule gets switched off and then catches nothing at all.
_POS = [
    ("split-line \\ref (the p.29 defect)", "Appendix~\nef{app:aggrisk} develops"),
    ("brace-less \\ref",                   "see Appendix efapp:aggrisk for"),
    ("same-line \\ref",                    "see Appendix~ef{app:aggrisk} for"),
    ("\\begin",                            "here\negin{table} x"),
    ("\\text",                             "$x$ \next{ where }"),
    ("\\frac",                             "$\nrac{a}{b}$"),
    ("\\newcommand",                       "\newcommand{\\Foo}{1}"),
    ("\\appendix",                         "\nppendix\n"),
    ("\\varepsilon before an underscore",  "$\narepsilon_t$"),
    ("\\notag",                            "x \notag\\\\"),
]
_NEG = [
    ("legitimate refs",  "Appendix~\\ref{app:x} \\eqref{eq:y} \\autoref{tab:z} \\pageref{fig:w}"),
    ("legitimate begin", "\\begin{table}\\end{table}"),
    ("legitimate text",  "\\text{a}\\textbf{b}\\textit{c}"),
    ("legitimate frac",  "\\frac{a}{b}"),
    ("appendix words",   "\\appendix Appendix~A the appendix reads appendixes"),
    ("other macros",     "\\newcommand{\\A}{1}\\notag\\noindent\\rightarrow\\varepsilon_t"),
    ("plain English",    "The reference is next to the beginning of the "
                         "text; fraction, appendix, notation."),
]


def selftest():
    bad = 0
    for name, s in _POS:
        del HARD[:]
        check_mangled_macros(s)
        hit = bool(HARD)
        print("  %-8s %s" % ("FIRES" if hit else "MISSED", name))
        bad += not hit
    for name, s in _NEG:
        del HARD[:]
        check_mangled_macros(s)
        clean = not HARD
        print("  %-8s %s%s" % ("clean" if clean else "FALSE+", name,
                               "" if clean else "  -> " + HARD[0]))
        bad += not clean
    del HARD[:]
    print("\nSELFTEST: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
    return 0 if bad == 0 else 1


def main():
    if "--selftest" in sys.argv:
        return selftest()
    tex = sys.argv[1] if len(sys.argv) > 1 else "green_deficits_price_level.tex"
    # The default was "refs.bib", which does not exist here, so every run
    # silently skipped the citation check and said so in a NOTE nobody read.
    bib = sys.argv[2] if len(sys.argv) > 2 else "references.bib"
    raw = load(tex)
    body = strip_comments(raw)

    check_labels(body)
    check_cites(body, bib)
    check_envs(body)
    check_mangled_macros(body)
    check_malformed_refs(body)
    check_apostrophes(body)

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
