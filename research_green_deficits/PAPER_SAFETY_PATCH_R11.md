# Paper safety patch (R11) — prepared, not applied

Minimal changes so that no uncertified two-asset claim stands as unqualified
in the compiled PDF. **This is a safety patch, not the paper reconstruction.**
The abstract, introduction and Section 6 are not restructured.

**Status: located and drafted. Manuscript NOT edited.** Figure *code* changes
are applied (they are unblocked); every `.tex` change below is held for your
word, with exact line numbers and replacement text so it can be applied
mechanically.

Line numbers are for `paper/green_deficits_price_level.tex` at commit
`a3578ee` unless stated. `\appendix` is at **line 3325**, so every site below
is body text except where noted. Every line number in this file was checked
against the source by opening it, not inferred from a grep count.

---

## A. Two-asset status

### A1 — Abstract (lines 270–290)

Two sentences carry uncertified two-asset headlines.

**A1a, lines 278–283.** Currently:

> In the preferred calibration, with concentrated bond ownership and
> infrequent portfolio adjustment, the lump-sum instrument raises the real
> value of nominal debt while the levy erodes it; that level sign is not a
> primitive, and it reverses under uniform ownership with frictionless
> rebalancing.

Replace with:

> Whether that ordering also puts the two instruments on opposite sides of
> zero depends on portfolio structure, and we do not treat the level sign as
> established: it turns on ownership concentration and adjustment frictions
> whose numerical certification is in progress.

*Rationale:* removes the restored two-asset level sign, keeps the honest
statement that the level is structure-dependent.

**A1b, lines 285–287.** Currently:

> ...rather than by households' direct saving response at the initial
> distribution, and the preferred two-asset calibration preserves the
> financing ordering.

Replace with:

> ...rather than by households' direct saving response at the initial
> distribution.

*Rationale:* the clause asserts the two-asset ordering as an abstract-level
finding. It returns only when Track A passes Gate 11.

### A2 — Section 6 conditionality statement (insert after line 2374)

Section 6 opens at line 2363. Insert immediately after the first paragraph
(which ends line 2374, "...does and does not establish."):

> \paragraph{Numerical status.} The quantitative results in this section are
> conditional on joint-grid certification of the two-asset solver, which is
> in progress and reported separately. Section~\ref{subsec:gridsens} already
> shows that magnitudes vary by a factor of five across the discretizations
> we have solved and that halving the grid materially changes the responses;
> until the certification protocol is complete, the level results here should
> be read as provisional and the ordering as the claim under test.

### A3 — "the economy the paper's quantitative claims rest on" (lines 2370–2371)

Replace `This section develops the economy the paper's quantitative claims
rest on` with:

> This section develops the ownership-and-illiquidity two-asset
> specification, under numerical validation

### A4 — "robust across every portfolio environment" (lines 2376–2377)

Replace `one claim that is robust across every portfolio environment we solve`
with:

> one claim obtained across every portfolio environment we solve, subject to
> numerical certification of the two-asset specification

### A5 — "preferred quantitative calibration" → the specification name

| line | current | replacement |
|---|---|---|
| 2363 | `\section{The preferred quantitative calibration}` | `\section{The ownership-and-illiquidity two-asset specification}` |
| 1711 | `preferred calibration, and checking` | `ownership-and-illiquidity specification, and checking` |
| 2378 | `a property of the preferred calibration` | `a property of the ownership-and-illiquidity specification` |
| 2387 | `preferred calibration.` | `ownership-and-illiquidity specification.` |
| 2402 | `the paper's \emph{preferred quantitative calibration}` | `the paper's \emph{ownership-and-illiquidity two-asset specification (under numerical validation)}` |

The `\label{subsec:twoassetnl}` on line 2363 is **unchanged** — renaming it
would dangle every `\ref` to it.

### A6 — portfolio-robustness claims (one body, one appendix)

**Line 3243–3244 (BODY).** `Across the portfolio specifications we report ---`
→ prefix the list with the scope qualifier:

> Across the portfolio specifications we report --- the certified one-asset
> economy, together with two-asset companions whose numerical certification
> is in progress ---

**Line 5676 (APPENDIX, `\appendix` is at 3325).** `is robust across the portfolio specifications reported` →

> is obtained across the portfolio specifications reported, subject to
> numerical certification of the two-asset specification

### A7 — "the data reject"

**Not found.** Grep for `data reject` returns nothing in the current source.
Either it was already removed or it is rendered from a macro. **Flagged as
unverified**; no edit proposed until the exact string is located in the
compiled PDF and traced back.

### A8 — announcement fractions 89% and 78%

To be classified **provisional** per register rows 16a–16d, and not used to
establish a portfolio-robust timing ordering. *Locations still to be
confirmed* — the figures appear to be macro-driven and did not resolve to
literal `89`/`78` in the body. **Blocked pending macro trace**; listed here so
it is not silently dropped.

---

## B. Figures — done in code, not by editing PDFs

| file | change | status |
|---|---|---|
| `main_project_regimes.m` | ticks → `Lump-sum`, `Proportional levy`, `Levy plus rebate`, `Mixed`; legend → `Revaluation`, `Damage dividend`, `Total offset`; axis/title → `Net household-burden offset ν` | **applied** |
| `src_project/plot_transition_fig.m` | legend → `Nominal appropriation — service rule`, `Indexed mandate — service rule`, `Levy plus rebate — service rule` | **applied** |
| `main_project_calibrated.m`, `main_project_maturity.m`, `main_project_robustness.m`, `main_project_aggrisk_stageB.m`, `src_project/plot_green_figures.m` | ν relabelled to net household-burden offset | applied in round 10 |

"self-financing share" and "R1 deficit" no longer appear in any figure label.
Note that `R1-LUMPSUM` is the *internal regime name*; "R1 deficit" would have
misdescribed the bar, since R1 is the lump-sum baseline and carries no
deficit. **Figures still need regeneration on your machine**; the checked-in
PDFs are older than the code.

---

## C. The ratcheted 1.4-year number

`\DefHalfStarRatchet` = `1.4` (defined `paper/numbers_manual.tex:146`).

**C1 — remove from the introduction (line 457).** Currently:

> ...and the sign reversal we locate across phase-in speeds --- at a tax
> half-life of about $\DefHalfStarRatchet$ years --- is a property of that
> joint experiment, not of tax timing alone.

Replace with:

> ...and the sign reversal we locate across phase-in speeds is a property of
> that joint experiment, not of tax timing alone.

**C2 — retain in Section 7 (line 3005–3008), relabelled.** Currently:

> ...locates the critical speed of the \emph{ratcheted} experiment at
> $\rho_d^{*}\in[\ldots]$: a tax-financing half-life of
> $\DefHalfStarRatchet$ years...

Replace the lead-in with:

> ...locates the \emph{reversal frontier of the joint delayed-tax /
> permanent-debt-ratchet experiment} at $\rho_d^{*}\in[\ldots]$: a
> tax-financing half-life of $\DefHalfStarRatchet$ years...

**C3 — conclusion, line 3297.** `schedule, which is observable. The matched`
→

> schedule. The current calculation is conditional on both the announced tax
> path and the associated terminal-debt or consolidation rule. The matched

---

## D. Other factual corrections

| # | site | change |
|---|---|---|
| D1 | line 2073–2074 | **already applied** (`a3578ee`): `Appendix~\ref{app:aggrisk}`, `the paper's central object` |
| D2 | 33 occurrences of `self-financing` | reserve "fiscal self-financing" for ν_reval; ν itself is the net household-burden offset. Per-site pass required. |
| D3 | line 5145 (appendix) | `lowers the full-financing threshold` → `lowers the zero-net-household-burden frontier` |
| D4 | decomposition −0.07 / +0.34 / +3.44 / +3.78 | one reconciliation display, two rows (marginal perturbation; finite program-size), one normalization (per unit of revenue), each row labelled derivative or finite difference. **Sites still to be traced** — the numbers are macro-driven. |
| D5 | borrowing-limit passage | rewrite the earlier account so loose-limit points are described as *losing the targeted positive-debt equilibrium*, not as an economic sign reversal. The later recalibrated-β account (+2.67 → +5.12) is the correct one. |
| D6 | Table 4 caption | qualify as **financing-side** incidence: damages are held fixed along the two-asset transition, so it prices the financing announcement, not the title question. |
| D7 | line 2765 | `Second, and against our prior, \emph{the transition adds almost nothing}.` → remove or qualify. Retain only if a welfare-error bound below the reported transition-vs-steady-state differences is in hand; none is. Proposed: `Second, and against our prior, the transition contributes little to the incidence ranking, within a numerical tolerance we have not yet bounded.` |

---

## E. What is deliberately NOT in this patch

- No restructuring of the abstract, introduction or Section 6.
- No change to any `\label`.
- No new numbers, and no removal of a caveat.
- A7, A8 and D4 are **flagged as unlocated**, not quietly dropped. Each needs
  the macro traced or the compiled-PDF string confirmed before an edit is
  proposed; inventing a near-match would be worse than leaving it open.
