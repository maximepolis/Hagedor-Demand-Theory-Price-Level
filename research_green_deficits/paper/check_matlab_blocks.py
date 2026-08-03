#!/usr/bin/env python3
"""Block-balance check for MATLAB sources, with MATLAB's real lexical rules.

WHY A REAL LEXER. The obvious check -- count the `function`/`if`/`for` keywords
and count the `end`s -- is wrong on this codebase in four separate ways, and
each one produces a FALSE ALARM on correct code:

  1. `end` as an INDEX.  x(end), p.kGrid(end), acGrid(end-1) are subscripts,
     not block terminators. This project uses them everywhere.
  2. ONE-LINE blocks.  `if nargin < 2, force = false; end` opens and closes on
     the same line, so a line-anchored regex sees the `if` and misses the `end`.
  3. The APOSTROPHE is overloaded.  A' is a transpose; 'A' is a string. A lexer
     that treats every quote as a string delimiter swallows half the file.
  4. `end` inside a comment or a string is not an `end`.

A parser that gets any of these wrong reports a defect in the FILE when the
defect is in the PARSER. That distinction is the whole point here: it decides
whether you edit a working data pipeline or fix your tooling.

The rule for `end`-as-index used here is MATLAB's own: `end` is a subscript
when the bracket depth (parentheses, braces, or square brackets) is greater
than zero. Otherwise it terminates a block.

Usage:  python3 check_matlab_blocks.py FILE_OR_DIR [FILE_OR_DIR ...]
        python3 check_matlab_blocks.py --selftest
Exit code is nonzero if any file is unbalanced.
"""
import os
import re
import sys

OPENERS = {"function", "if", "for", "parfor", "while", "switch", "try",
           "classdef", "properties", "methods", "events", "enumeration",
           "arguments", "spmd"}
# `else`, `elseif`, `case`, `otherwise`, `catch` continue a block; they neither
# open nor close one.
NEUTRAL = {"else", "elseif", "case", "otherwise", "catch"}

TOKEN = re.compile(r"[A-Za-z_]\w*")


def strip_line(line, in_block_comment):
    """Return (code, in_block_comment) with comments and strings blanked.

    Strings are replaced by spaces rather than removed so that column offsets
    -- and therefore bracket depth -- stay meaningful.
    """
    s = line.strip()
    if in_block_comment:
        if re.match(r"^%\}\s*$", s) or re.match(r"^#\}\s*$", s):
            return "", False
        return "", True
    if re.match(r"^%\{\s*$", s) or re.match(r"^#\{\s*$", s):
        return "", True

    out = []
    i, n = 0, len(line)
    # WHITESPACE IS SIGNIFICANT BEFORE A QUOTE. MATLAB reads `'` as a transpose
    # only when it IMMEDIATELY follows a value -- no space between. Inside
    # brackets a space is a column separator, so in
    #     rec.key = [iso3 '|' R.date];
    # the quote after "iso3 " opens a STRING. Tracking the last non-space
    # character instead (which an earlier version of this file did) reads it as
    # a transpose, swallows the rest of the line as code, and then loses the
    # `end` tokens that follow -- reporting five unclosed blocks in a file that
    # is perfectly well formed. That is the exact failure this checker exists
    # to distinguish from a real defect, so it is worth being precise about.
    while i < n:
        c = line[i]
        if c in "%#" and not (c == "#" and i + 1 < n and line[i + 1] == "!"):
            break                                   # comment to end of line
        if c == "." and line[i:i + 3] == "...":
            break                                   # continuation
        if c == '"':
            j = i + 1
            while j < n:
                if line[j] == '"':
                    if j + 1 < n and line[j + 1] == '"':
                        j += 2
                        continue
                    break
                j += 1
            out.append(" " * (min(j, n - 1) - i + 1))
            i = j + 1
            continue
        if c == "'":
            # TRANSPOSE if the previous significant character can end a value;
            # otherwise a string delimiter. This is MATLAB's own disambiguation.
            pc = line[i - 1] if i > 0 else ""
            if pc and (pc.isalnum() or pc in ")]}._'"):
                out.append("'")                     # transpose, not a string
                i += 1
                continue
            j = i + 1
            while j < n:
                if line[j] == "'":
                    if j + 1 < n and line[j + 1] == "'":
                        j += 2
                        continue
                    break
                j += 1
            out.append(" " * (min(j, n - 1) - i + 1))
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out), False


def scan(path):
    """Return (net_depth, events, errors) for one file."""
    with open(path, encoding="utf-8", errors="replace") as fh:
        raw = fh.read().split("\n")

    depth = 0
    bracket = 0
    errors = []
    events = []
    in_bc = False
    for ln, line in enumerate(raw, 1):
        code, in_bc = strip_line(line, in_bc)
        if not code.strip():
            continue
        # Walk character by character so bracket depth is known at each token.
        i, n = 0, len(code)
        while i < n:
            c = code[i]
            if c in "([{":
                bracket += 1
                i += 1
                continue
            if c in ")]}":
                bracket -= 1
                i += 1
                continue
            m = TOKEN.match(code, i)
            if not m:
                i += 1
                continue
            w = m.group(0)
            i = m.end()
            # A keyword is only a keyword if it is not a field name (s.end)
            # and not a struct field access target.
            if m.start() > 0 and code[m.start() - 1] == ".":
                continue
            if w in OPENERS:
                depth += 1
                events.append((ln, "open", w, depth))
            elif w == "end":
                if bracket > 0:
                    continue                        # x(end): a subscript
                depth -= 1
                events.append((ln, "close", w, depth))
                if depth < 0:
                    errors.append("line %d: `end` with no open block" % ln)
                    depth = 0
            elif w in NEUTRAL:
                pass
        if bracket < 0:
            bracket = 0
    return depth, events, errors


# ----------------------------------------------------------------------
# ADJACENT STRING LITERALS.
#
# MATLAB does NOT concatenate juxtaposed string literals: 'a' 'b' is a syntax
# error, not 'ab'. C and Python both do concatenate, so the habit is easy to
# carry in, and a multi-line message written as
#
#     error('first part ' ...
#           'second part', x)
#
# fails only when that line is finally executed -- which, in a long solver
# run, can be twenty minutes in. It has now happened three times in this
# project. Inside [ ] or { } the adjacency IS valid (concatenation and cell
# construction), so the rule fires only at bracket depth zero.
def check_adjacent_strings(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        raw = fh.read().split("\n")

    # Join continuations into logical lines, remembering the first line number.
    logical, buf, start, in_bc = [], "", None, False
    for ln, line in enumerate(raw, 1):
        code, in_bc = strip_line_keep_strings(line, in_bc)
        if start is None:
            start = ln
        stripped = code.rstrip()
        if stripped.endswith("..."):
            buf += stripped[:-3] + " "
            continue
        buf += stripped
        logical.append((start, buf))
        buf, start = "", None
    if buf:
        logical.append((start or len(raw), buf))

    errs = []
    for ln, text in logical:
        depth = 0
        i, n = 0, len(text)
        prev_string_end = None
        while i < n:
            c = text[i]
            if c in "[{":
                depth += 1; i += 1; prev_string_end = None; continue
            if c in "]}":
                depth -= 1; i += 1; prev_string_end = None; continue
            if c == "'":
                pc = text[i - 1] if i > 0 else ""
                if pc and (pc.isalnum() or pc in ")]}._"):
                    i += 1; continue                      # transpose
                j = i + 1
                while j < n:
                    if text[j] == "'":
                        if j + 1 < n and text[j + 1] == "'":
                            j += 2; continue
                        break
                    j += 1
                if depth == 0 and prev_string_end is not None:
                    between = text[prev_string_end:i]
                    if between.strip() == "":
                        errs.append(
                            "line %d: adjacent string literals at depth 0 -- "
                            "MATLAB does not concatenate them; wrap in [ ]" % ln)
                prev_string_end = j + 1
                i = j + 1
                continue
            if not c.isspace():
                prev_string_end = None
            i += 1
    return errs


def strip_line_keep_strings(line, in_block_comment):
    """Like strip_line, but KEEPS string literals (blanking them would erase
    exactly what this check is looking for). Comments and continuations are
    still handled."""
    s = line.strip()
    if in_block_comment:
        if re.match(r"^%\}\s*$", s) or re.match(r"^#\}\s*$", s):
            return "", False
        return "", True
    if re.match(r"^%\{\s*$", s) or re.match(r"^#\{\s*$", s):
        return "", True
    out, i, n = [], 0, len(line)
    while i < n:
        c = line[i]
        if c in "%#":
            break
        if c == "'":
            pc = line[i - 1] if i > 0 else ""
            if pc and (pc.isalnum() or pc in ")]}._"):
                out.append(c); i += 1; continue
            j = i + 1
            while j < n:
                if line[j] == "'":
                    if j + 1 < n and line[j + 1] == "'":
                        j += 2; continue
                    break
                j += 1
            out.append(line[i:min(j + 1, n)])
            i = j + 1
            continue
        out.append(c); i += 1
    return "".join(out), False


def check(path):
    depth, events, errors = scan(path)
    errors = errors + check_adjacent_strings(path)
    if depth > 0:
        opens = [e for e in events if e[1] == "open"]
        tail = ", ".join("%s@%d" % (e[2], e[0]) for e in opens[-3:])
        errors.append("%d block(s) never closed (last opened: %s)" % (depth, tail))
    return errors


SELFTEST = [
    ("end as a subscript", "function y = f(x)\ny = x(end);\nend\n", True),
    ("one-line if", "function f()\nif true, disp(1); end\nend\n", True),
    ("transpose after )", "function y = f(A)\ny = A(1,:)';\nend\n", True),
    ("transpose after var", "function y = f(A)\ny = A';\nend\n", True),
    ("string containing end", "function f()\ndisp('end');\nend\n", True),
    ("string containing if", "function f()\ndisp('if x, end');\nend\n", True),
    ("nested function", "function f()\ng();\nfunction g()\ndisp(1);\nend\nend\n", True),
    ("block comment", "function f()\n%{\nif true\n%}\ndisp(1);\nend\n", True),
    ("comment with end", "function f()\n% if x then end\ndisp(1);\nend\n", True),
    ("double-quoted string", 'function f()\ndisp("if end for");\nend\n', True),
    ("field named end-ish", "function f()\ns.ending = 1;\ndisp(s.ending);\nend\n", True),
    ("continuation", "function f()\nx = 1 + ... if end\n    2;\nend\n", True),
    ("string after space in []",
     "function f()\ns.key = [a '|' b];\ndisp(s.key);\nend\n", True),
    ("string after space, no brackets",
     "function f()\nx = strcat(a, 'z');\nif true, disp(x); end\nend\n", True),
    ("transpose then string",
     "function f()\ny = [A' 'lit'];\ndisp(y);\nend\n", True),
    ("adjacent strings in a call",
     "function f()\nerror('a ' ...\n  'b', 1);\nend\n", False),
    ("adjacent strings, same line",
     "function f()\nerror('a ' 'b');\nend\n", False),
    ("bracketed concatenation is fine",
     "function f()\nerror(['a ' ...\n  'b'], 1);\nend\n", True),
    ("cell of strings is fine",
     "function f()\nx = {'a' 'b'};\ndisp(x);\nend\n", True),
    ("bracket concat same line",
     "function f()\ns = ['a' 'b'];\ndisp(s);\nend\n", True),
    ("transpose then string is fine",
     "function f(A)\ny = [A' 'lit'];\ndisp(y);\nend\n", True),
    ("two args are fine",
     "function f()\nfprintf('%s', 'b');\nend\n", True),
    ("MISSING end", "function f()\nif true\ndisp(1);\nend\n", False),
    ("EXTRA end", "function f()\ndisp(1);\nend\nend\n", False),
    ("unclosed for", "function f()\nfor i=1:3\ndisp(i);\nend\n", False),
]


def selftest():
    import tempfile
    bad = 0
    for name, src, should_pass in SELFTEST:
        with tempfile.NamedTemporaryFile("w", suffix=".m", delete=False) as fh:
            fh.write(src)
            p = fh.name
        errs = check(p)
        os.unlink(p)
        ok = (not errs) if should_pass else bool(errs)
        print("  %-8s %-26s %s" % ("ok" if ok else "WRONG", name,
                                   "" if ok else ("-> " + "; ".join(errs) if errs
                                                  else "-> passed but should have failed")))
        bad += not ok
    print("\nSELFTEST: %s" % ("PASS" if bad == 0 else "FAIL (%d)" % bad))
    return 0 if bad == 0 else 1


def main():
    if "--selftest" in sys.argv:
        return selftest()
    targets = sys.argv[1:] or ["."]
    files = []
    for t in targets:
        if os.path.isdir(t):
            for r, _, fs in os.walk(t):
                files += [os.path.join(r, f) for f in sorted(fs) if f.endswith(".m")]
        elif t.endswith(".m"):
            files.append(t)
    nbad = 0
    for f in sorted(files):
        errs = check(f)
        if errs:
            nbad += 1
            print("FAIL %s" % f)
            for e in errs:
                print("     %s" % e)
    print("\n%d file(s) checked, %d unbalanced" % (len(files), nbad))
    return 1 if nbad else 0


if __name__ == "__main__":
    sys.exit(main())
