#!/usr/bin/env python3
"""check_manuscript_numbers.py -- stray-number validator for the paper.

Scans the manuscript for numeric literals typed in prose/tables that are NOT
sourced from numbers_auto.tex macros, and reports them with context so a
human can classify each as (a) a calibration input (legitimate to type),
(b) an approved literal (listed in approved_literals.txt), or (c) a RESULT
that should be macro-fed from the exporter.

The point is not zero literals -- calibration inputs are typed by design --
but zero UNREVIEWED literals: every number in the manuscript should be either
a macro or on the approved list, so a stale hand-typed result can never hide.

USAGE   python3 check_manuscript_numbers.py [--tex FILE] [--approved FILE]
EXIT    0 if no unapproved literals, 1 otherwise (CI-friendly).
"""

import argparse
import re
import sys
from pathlib import Path

SKIP_ENVS = {"tikzpicture", "thebibliography", "filecontents"}

# Lines that are pure machinery, never prose claims.
SKIP_LINE_RE = re.compile(
    r"^\s*%"                                   # comments
    r"|\\(usepackage|documentclass|geometry|setlength|providecommand|"
    r"newcommand|renewcommand|definecolor|hypersetup|input|include|"
    r"bibliography|graphicspath|label|ref|eqref|pageref|cite|citep|citet|"
    r"citealp|includegraphics|vspace|hspace|addtolength|counterwithin)"
)

# Numbers that never need review anywhere.
ALWAYS_OK_RE = re.compile(
    r"^(0|1|2)$"                # bare small integers (enumeration, exponents)
    r"|^(19|20)\d{2}$"          # years
)

NUM_RE = re.compile(r"(?<![\w.])[-+]?\d+\.?\d*(?![\w])")


def strip_protected(line: str) -> str:
    """Remove spans whose numbers are structural, not claims."""
    # optional args and lengths: [1.5ex], {3cm}, tabcolsep etc.
    line = re.sub(r"\[[^\]]*\]", " ", line)
    line = re.sub(r"\\(hspace|vspace|rule|parbox|makebox|raisebox)\*?\{[^}]*\}", " ", line)
    # column specs {lccc}, p{2.5cm}, tabular* widths
    line = re.sub(r"\\begin\{tabular\*?\}\{[^}]*\}", " ", line)
    line = re.sub(r"p\{[^}]*\}", " ", line)
    # citation years inside \citet{...} keys already dropped by SKIP_LINE or key text
    line = re.sub(r"\\cite[tp]?(alp)?\*?(\[[^\]]*\])?\{[^}]*\}", " ", line)
    line = re.sub(r"\\(label|ref|eqref|autoref|pageref)\{[^}]*\}", " ", line)
    # macro names never carry digits that matter
    line = re.sub(r"\\[A-Za-z@]+", " ", line)
    return line


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tex", default="green_deficits_price_level.tex")
    ap.add_argument("--approved", default="approved_literals.txt")
    args = ap.parse_args()

    tex = Path(args.tex)
    if not tex.exists():
        print(f"ERROR: {tex} not found", file=sys.stderr)
        return 2

    approved: set[str] = set()
    ap_path = Path(args.approved)
    if ap_path.exists():
        for raw in ap_path.read_text().splitlines():
            entry = raw.split("#", 1)[0].strip()
            if entry:
                approved.add(entry)

    findings = []
    env_stack: list[str] = []
    in_preamble = True
    for lineno, raw in enumerate(tex.read_text().splitlines(), start=1):
        if "\\begin{document}" in raw:
            in_preamble = False
            continue
        if in_preamble:
            continue
        for m in re.finditer(r"\\begin\{(\w+\*?)\}", raw):
            env_stack.append(m.group(1))
        for m in re.finditer(r"\\end\{(\w+\*?)\}", raw):
            if env_stack and env_stack[-1] == m.group(1):
                env_stack.pop()
        if any(e in SKIP_ENVS for e in env_stack):
            continue
        if SKIP_LINE_RE.match(raw):
            continue
        line = strip_protected(raw)
        for m in NUM_RE.finditer(line):
            tok = m.group(0).lstrip("+")
            if ALWAYS_OK_RE.match(tok.lstrip("-")):
                continue
            if tok in approved or tok.lstrip("-") in approved:
                continue
            findings.append((lineno, tok, raw.strip()[:110]))

    if not findings:
        print("OK: no unapproved numeric literals outside the approved list.")
        return 0

    print(f"{len(findings)} unapproved numeric literal(s):\n")
    for lineno, tok, ctx in findings:
        print(f"  L{lineno:5d}  {tok:>12}  | {ctx}")
    print(
        "\nEach literal must be (a) replaced by a numbers_auto.tex macro if it is a"
        "\ncomputed result, or (b) added to approved_literals.txt with a comment if"
        "\nit is a calibration input, a scale factor, or a transcribed-and-checked"
        "\nvalue from a pushed run table."
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
