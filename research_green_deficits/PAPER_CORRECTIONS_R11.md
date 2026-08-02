# Paper-side corrections, round 11

Fourteen items from the compiled-PDF review, integrated as a work plan.
**Prose is frozen** by the round-10 instruction; this file records what must
change, what I verified, and what is already done in code. Nothing in the
manuscript body has been edited for this round.

---

## 0. A correction I owe, before anything else

In round 10 I told you: *"I scanned all 26 figures for that string — none
carries it. Figure regeneration is not on the critical path."*

**That was wrong, and the method could not have found what it claimed to look
for.** MATLAB writes figure text with CID font encoding
(`Adobe-Identity-UCS`), so a raw decode of the PDF streams recovers font
metadata and license boilerplate, not rendered labels. What my scan actually
read was strings like `CIDInit`, `BaKoMa`, `Copyright`, `FITNESS`. The single
"service" hit I reported from PFig18 was almost certainly a substring of that
boilerplate, not an axis label.

So I ran a check that could not fail, and reported the pass. That is the same
error class as the terminal-`dlnP` identity and the vacuous hysteresis test
earlier in this project, and I should have recognised it — a uniform ~100
extractable "words" across 26 different figures was visible evidence that the
extractor was reading something other than the plots.

**The authoritative check is the plotting source**, and it confirms your
reading. Verified below.

---

## 1. Verification of the figure claims

| Claim | Verdict | Evidence |
|---|---|---|
| Fig 4 panel title "self-financing" | **CONFIRMED** | `main_project_regimes.m`: `title('(a) self-financing')` |
| Fig 4 axis "self-financing share ν" | **CONFIRMED** | same file: `ylabel('self-financing share \nu')` |
| Fig 4 regime label "R1 deficit" | **NOT in current code** | tick labels are `{'lump-sum','levy','levy+rebate','mixed'}`. The internal regime *name* is `R1-LUMPSUM` and `R4-MIXED-DEFICIT-LEVY`, but neither is drawn. Either the compiled PDF predates the tick-label change, or the R4 name was read from a legend that no longer exists. **The stale-PDF reading is the more likely one and is itself the point: the checked-in figures are older than the code.** |
| Fig 5 "nominal budget, deficit" / "indexed mandate, deficit" | **CONFIRMED as stale PDF** | `src_project/plot_transition_fig.m` already emits `{'nominal appropriation, service rule', 'indexed mandate, service rule'}`. The *code* is correct; the checked-in PDF is not. |

**Figure identification** (body order): Fig 1 = mechanism (TikZ), Fig 2 =
`PFig15`, Fig 3 = `PFig8`, **Fig 4 = `PFig9_financing_regimes`**, **Fig 5 =
`PFig18_dtpl_transition`**.

---

## 2. Done in this round (code only, no prose)

The terminology rule is applied at the **source** of every figure label, so a
regeneration produces correct figures rather than requiring a second pass:

| File | Was | Now |
|---|---|---|
| `main_project_regimes.m` | `ylabel('self-financing share \nu')`; `title('(a) self-financing')`; legend `{revaluation, damage dividend, total ν}` | `ylabel('net household-burden offset \nu')`; `title('(a) net household-burden offset')`; legend `{fiscal self-financing ν_reval, resource benefit-cost ν_dam, net offset ν}` |
| `main_project_calibrated.m` | figure name + `ylabel` "self-financing" | "net household-burden offset" |
| `main_project_maturity.m` | `ylabel` "self-financing share ν" | "net household-burden offset ν" |
| `main_project_robustness.m` | colorbar + `ylabel` "self-financing share ν" | "net household-burden offset ν" |
| `main_project_aggrisk_stageB.m` | `ylabel('self-financing share')` | "net household-burden offset ν" |
| `src_project/plot_green_figures.m` | `ylabel('self-financing share ν')` | "net household-burden offset ν" |

Each file carries a comment stating why: labelling ν a "self-financing share"
asserts the *fiscal* reading of a *household* object, which is exactly the
misstatement the body text was rewritten to avoid.

`plot_transition_fig.m` needed **no** change — it is already correct, and Fig 5
needs only regeneration.

---

## 3. The fourteen items, prioritised

### Immediate priority (your four)

| # | Item | Status | Blocking |
|---|---|---|---|
| P1 | Regenerate Figs 4 and 5 with correct terminology | **code fixed; regeneration needs MATLAB** | your machine |
| P2 | Remove or qualify every uncertified two-asset headline | **specified below, not executed** | prose freeze |
| P3 | Reconcile the tax-elasticity decomposition and the borrowing-limit sweep | **specified below, not executed** | prose freeze |
| P4 | Correct the conclusion on neutrality and observable financing | **specified below, not executed** | prose freeze |

### Item 1 — quarantine the uncertified two-asset claims

Locations, with the replacement principle. `CLAIM_STATUS_R10.md` rows 10, 12,
13, 14 already carry these as **WP**; this is the textual consequence.

- **Abstract**: drop "In the preferred calibration…" and "the preferred
  two-asset calibration preserves the financing ordering". Retain the
  one-asset mechanism; state that richer portfolio structures make the level
  sign conditional. The *ordering* returns to the abstract only when its
  signal-to-grid-error ratio passes Gate 11.
- **p.27** "the data reject" the uniform-ownership configuration → the data
  are *inconsistent with* it; "reject" is a test the paper does not run.
- **p.35** "the economy the paper's quantitative claims rest on" → "the
  ownership-and-illiquidity specification, under numerical validation".
- **pp.37–40** restored sign, transition path, incidence → each prefixed as
  provisional pending certification.
- **p.49** "Across the portfolio specifications we report…" → scope to the
  certified one-asset economy plus explicitly uncertified companions.
- Replace **"preferred calibration"** globally with **"the
  ownership-and-illiquidity specification (under numerical validation)"**.

Your point about §6 is right and sharpens this: the section already reports
that magnitudes vary by a factor of five and that halving the grid materially
changes responses. Given that a pure grid change moves the tree price by more
than the financing signal, "the sign contrast is what survives the curvature
and grid variations we have solved" cannot stand as written.

### Item 3 — the ν terminology, remaining text sites

Code is done. Remaining: appendix prose and any body use of "full-financing
threshold" for ν = 1 → **zero-net-household-burden frontier**. Frozen.

### Item 4 — fixed-nominal vs fixed-real in the introduction

Adopt the estimand box already drafted in `R10_EXECUTION_PLAN.md` §1.
Reserve "same real program" strictly for Prop 5 and `tab:regimesreal`;
introduce Experiment N as "at a fixed nominal appropriation".

### Item 5 — the borrowing-limit contradiction

The later account (recalibrated β, elasticity rises +2.67 → +5.12) is the
careful one. The earlier passage must be rewritten so the loose-limit points
are described as *losing the targeted positive-debt equilibrium*, not as a
genuine economic sign reversal.

### Item 6 — one reconciliation display

Two rows, one normalization (per unit of revenue), each labelled derivative or
finite difference:

```
marginal perturbation   direct  -0.07   distributional  ...     total  ...
finite program-size     direct  +0.34   distributional +3.44    total +3.78
```

Then make Prop 7, §5.1, the conclusion and every generated macro use those
labels. The +3.71 / +3.44 / +3.78 alternation must resolve to one bridge.

### Item 7 — identification language

"properties the calibration takes from the data rather than chooses to sign
the result" → the aggregate permanent-tax elasticity, and especially its
dominant distributional component, is a model-implied object. This is
`CLAIM_STATUS_R10.md` row 7 in prose.

### Item 8 — the neutrality statement

"Nominal debt issuance is neutral" → a *joint proportional rescaling* of
nominal debt and the nominal appropriation is neutral, holding `G_g/B` fixed;
real debt remains demand-determined; changing `B` alone at a fixed
appropriation changes the real program scale.

### Item 9 — the financing-schedule prediction

"conditional on the financing schedule, which is observable" → "conditional on
the announced tax path **and** the associated terminal-debt or consolidation
rule". And "provided the financing is scheduled to arrive quickly" → "under
the contemporaneous service-rule benchmark". Consistent with the round-10
threshold edits and with register row 21.

### Item 10 — the two-asset welfare claim

The two-asset transition holds damages fixed, so it is the incidence of the
**financing side**. Table 4 answers who bears the tax and nominal-revaluation
component under that portfolio structure, not the title question.

### Item 11 — front-loading, in the paper

Four statistics, four statuses, per register rows 16a–16d: one-asset 77%
(validated within the one-asset model); frictionless two-asset 89%
(conditional on that solver); ownership-and-illiquidity 78% (provisional);
107% (cross-instrument overshooting, **not** a front-loading fraction). The
"three objects share one signature" paragraph survives only if the
denominators are named in it.

### Item 12 — broken cross-reference — **DONE**

The source read, across two lines:

```
... turns the papers central object literal: ... Appendix~
ef{app:aggrisk} develops this and shows ...
```

A backslash was consumed as a string escape (`"\ref"` in a non-raw Python
string is CR + `ef`), leaving a newline where the macro's backslash had been.
The braces survived, so `app:aggrisk` was never a `\ref` at all: **the label
graph is perfectly consistent, no reference dangles, and the compile is
clean.** That is why `check_tex.py` passed the document, and it is why my
first attempt at a rule still missed it — I searched for `ef` followed
directly by a label key, but the damage here kept the brace and put a line
break in the middle, so the defect was not a single searchable string.

Fixed in the manuscript (one line, two characters of prose):

```tex
Making the climate itself stochastic turns the paper's central object
literal: the bond is nominally safe but really risky. Appendix~\ref{app:aggrisk}
develops this and shows ...
```

These are the **only** manuscript characters touched this round. They are
repairs of broken output — a reference that renders as `efapp:aggrisk` and a
possessive missing its apostrophe — not prose decisions, so they do not
breach the freeze on §1–§14 rewriting.

Checker, now in `paper/check_tex.py`:

- `check_mangled_macros` — a table of macro tails left behind when a
  backslash is eaten by a C/Python escape (`ef{`, `egin{`, `ext{`, `rac{`,
  `ewcommand`, `otag`, `oindent`, `ightarrow`, `ppendix`, `arepsilon`), each
  vetoed by a preceding letter so that every legitimate `\ref`, `\begin`,
  `\text`, `\frac` and the English words *reference, beginning, text,
  fraction, appendix* stay clean. Matching runs on the body with newlines
  intact, which is what makes the split-line case visible.
- `--selftest` — ten positive and seven negative controls **inside the
  file**. A checker that reports PASS is worthless until you have watched it
  report FAIL, and this project has been burnt three times by checks that
  could not fail. Both halves pass; the negative half is the one that
  matters, since an over-eager rule gets switched off and then catches
  nothing.
- Line numbers on the mangled-macro and apostrophe reports.
- Default bib fixed from `refs.bib` (which does not exist here, so every run
  had been silently skipping the citation check) to `references.bib`.
  Citation keys now check clean.

All four `.tex` files in `paper/` were rescanned: clean.

### Item 13 — do not call the transition certified

Distinguish four things the manuscript currently runs together: operator
parity; path-solver convergence; stationary-grid certification; economic-signal
precision. Only the first two are documented. "All four pass" must not imply
publication certification. For Table 4, a welfare-error bound materially below
0.10pp is required before "the transition adds almost nothing".

### Item 14 — figure layout

Enlarge axes and legend fonts; use more text width; move Figs 2–4 nearer their
discussion; avoid isolated half-page graphics; enlarge Fig 5. Estimated
49 → 45–46pp with no economics deleted.

---

## 4. Sequencing

1. **Now, unblocked — done:** figure label code at source; the `check_tex.py`
   mangled-macro rule with its self-test; the item-12 repair in the source.
2. **When your runs finish:** regenerate all figures; that closes P1.
3. **On your word:** the prose corrections P2–P4 and items 4–13, as one pass.
4. **After certification:** the two-asset claims either return with their
   status upgraded, or the quarantine language becomes permanent.

Items 1, 7, 9, 10, 11 and 13 are all consequences of the claim register
already agreed. They do not need new analysis — only a text pass, when the
freeze lifts.
