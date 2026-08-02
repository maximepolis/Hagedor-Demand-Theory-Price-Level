# Round-10 execution plan

Companion to `CLAIM_STATUS_R10.md` and `NUMERICAL_ACCEPTANCE_TWO_ASSET_R10.md`.
No prose has been edited and no economic experiment has been run for this
document.

---

## 1. Experiment-definition box (proposed body text)

To be placed at the head of the quantitative section, before any regime table.

> **Notation.** `B` is the outstanding stock of nominal government debt and
> `b = B/P` its real value. `G_g` is the nominal green appropriation and
> `g_g = G_g/P` the real program it buys. The financing instrument is the pair
> `(τ_ls, ϑ)` satisfying the government identity at every date.
>
> **Experiment N — nominal-budget incidence.** Hold `B` and `G_g` fixed. Vary
> the financing instrument. `P`, `b` and `g_g` all adjust. This is incidence
> under the same *legislated nominal appropriation*, and it is the
> institutionally relevant object because public budgets are legislated in
> nominal terms. It does **not** compare the same physical program: an
> instrument that raises `P` buys less adaptation capital.
>
> **Experiment R — pure financing incidence.** Hold `B` and `g_g` fixed. Vary
> the financing instrument. `G_g = P g_g` adjusts. This compares the same
> *physical public-investment program* across instruments, so the damage
> dividend is identical by construction and the cross-regime differences are
> tax incidence plus the price response it induces. It does **not** hold the
> nominal fiscal position constant: the appropriation is regime-dependent.
>
> The two experiments answer different questions and the paper reports both,
> side by side. The title question — who bears the cost of a given real
> program — is answered by Experiment R. Experiment N is what a legislature
> actually enacts.

**Status.** Experiment N is the current headline (`tab:regimes`). Experiment R
is already computed and reported in `subsec:regimesreal` / `tab:regimesreal`,
with values live in `paper/numbers_auto.tex` (`\RDefRealP` = 0.858,
`\RLevRealP` = 0.929, `\RRebRealP` = 1.008, `\RMixRealP` = 0.893; revaluation
shares `\RDefRealRev` = −0.057, `\RLevRealRev` = +0.030). The work is
promotion and paired presentation, not computation.

---

## 2. The 1.4-year threshold: every location

Search terms used: `1.4`, `half-life`, `halflife`, `phase-in`, `threshold`,
`DefHalfStar`, `DefRhoStar`, `DefRho`. Excludes unrelated uses of "threshold"
(determinacy, resource `ν≥1`, hand-to-mouth cutoff, float placement).

| # | File | Line | Current text | Required action |
|---|---|---|---|---|
| 1 | `paper/green_deficits_price_level.tex` | 453–456 | "Solving across phase-in speeds locates a sharp threshold: when delayed taxation permanently raises the terminal nominal stock, the announced disinflation survives only if the financing arrives on a tax half-life under about `\DefHalfStar` years, and reverses sign beyond it." | **Qualify.** The conditional clause is present and correct, but "sharp threshold" overstates a boundary that has not been separated from the debt ratchet. Replace with a statement that the sign of the announcement response depends jointly on financing speed *and* on whether the terminal stock is permanently raised, and that the paper does not yet separate them. |
| 2 | `paper/green_deficits_price_level.tex` | 456–459 | "The paper's central prediction is therefore conditional on an observable --- the announced financing schedule --- rather than unconditional." | **Remove.** Register row 21: overclaim. The observable would have to be the schedule *and* the terminal-debt rule. |
| 3 | `paper/green_deficits_price_level.tex` | 1375–1376 | "(disinflation survives only below an explicit threshold on the speed of tax phase-in)" | **Remove or qualify.** This is the *unqualified* form and it sits in the theory section, where it reads as a property of the model rather than of one financing rule. |
| 4 | `paper/green_deficits_price_level.tex` | 2976–2990 | "The practical content is a threshold, and because `c>1` throughout it binds …" through the `\DefRhoStarLo`–`\DefRhoStarHi` statement | **Relabel.** Keep the computation; state it as the threshold *of the debt-ratchet rule*, not of tax timing. |
| 5 | `paper/green_deficits_price_level.tex` | 2990–3006 | "Two things are bundled in that threshold … Separating the two requires a matched-terminal-debt path … which we do not compute here." | **Keep, and promote.** This is already the correct caveat and it is well written. It should appear *before* the number, not after it, and its substance should propagate to locations 1–4. |
| 6 | `paper/numbers_manual.tex` | 143 | `\newcommand{\DefHalfStar}{1.4}` | **Rename** to `\DefHalfStarRatchet`, so no location can quote it as a pure tax-timing object. Update the four call sites. |
| 7 | `paper/numbers_manual.tex` | 140–142 | `\DefRhoStarLo` 0.600, `\DefRhoStarHi` 0.613, `\DefRhoStar` 0.61 | **Rename** with the same suffix, same reason. |

**Checked and clean.** The abstract does not mention the threshold. The
conclusion does not mention it. `\DefRho` = 0.90 with `\DefHalfLife` = 6.6 yr
is the *baseline deficit run*, not the threshold, and the two are internally
consistent (ln 0.5 / ln 0.90 = 6.58; ln 0.5 / ln 0.61 = 1.40). No arithmetic
error found.

---

## 3. The 2×2 tax-timing × terminal-debt experiment

The financing rule is `τ_t = r̄ b_t + (1 − ρ_d^t) g`, so `ρ_d = 0` is
contemporaneous and `ρ_d > 0` phases the tax in. Terminal dilution is
`κ_∞ = B̂_∞ / B̂_0`.

| Case | Tax timing | Terminal debt | Rule | Purpose |
|---|---|---|---|---|
| **C1** | contemporaneous | unchanged (`κ_∞ = 1`) | `ρ_d = 0` | Reference. This is the balanced path already computed. |
| **C2** | delayed | unchanged (`κ_∞ = 1`) | `ρ_d = ρ̄` for `t ≤ T_c`, then a consolidation surcharge `s_t` on the tax over `[T_c, T_c + H]` chosen so that `κ_∞ = 1` | **The pure tax-timing experiment.** This is the case that does not exist yet. |
| **C3** | contemporaneous | permanently higher (`κ_∞ = κ̄ > 1`) | `ρ_d = 0` plus a one-off unfunded issuance at `t = 1` sized to deliver `κ̄` | **The pure debt-ratchet experiment.** Isolates dilution with no timing change. |
| **C4** | delayed | permanently higher | `ρ_d = ρ̄`, no consolidation | The current experiment, correctly labelled. |

**Controls held fixed across all four:** the real program path `g_{g,t}`;
implementation efficiency `q_g`; discounted resource cost; initial `B`;
damages; the horizon `T`; the terminal real economy.

**The consolidation path must be chosen before results are inspected.**
Proposed and to be fixed now: a geometric surcharge beginning at `T_c = 10`
years with half-life 10 years, scaled so `κ_∞ = 1` to within 1e-8, i.e.
`H` chosen by the solver and `s_t ∝ ς^{t−T_c}` with `ς = 2^{−1/10}`. Report
its present value as a share of the program's present value, and report `κ̄`
for C3/C4 as an output rather than a target where the rule generates it.

**Reported decomposition, per case:** deferred-tax relief; temporary nominal
issuance; permanent nominal dilution; distributional precautionary response;
climate-capital response; interaction. The identity must reconstruct the
impact response to the same tolerance as the existing exact decomposition.

**Attribution the 2×2 delivers:** pure timing = C2 − C1; pure ratchet =
C3 − C1; interaction = C4 − C2 − C3 + C1. No threshold may be quoted until
these three are separately reported.

---

## 4. File-by-file implementation plan

Nothing below is executed yet. Ordering follows Phases A–F.

### Already written this round (Phase A)

| File | Status |
|---|---|
| `REFEREE_REPORT_INTERNAL_R9.md` | preserved; erratum prepended withdrawing §3(c) |
| `CLAIM_STATUS_R10.md` | new |
| `NUMERICAL_ACCEPTANCE_TWO_ASSET_R10.md` | new |
| `R10_EXECUTION_PLAN.md` | this file |

### Phase B — estimands

| File | Change |
|---|---|
| `paper/green_deficits_price_level.tex` | insert the §1 box at the head of the quantitative section; retitle `tab:regimes` "Experiment N"; promote `subsec:regimesreal` into the body as "Experiment R" adjacent to it |
| `main_regimes_fixed_real.m` (verify name at run time) | add the terminal-debt control; emit a paired-panel table with Experiment N |

### Phase C — numerical certification

| File | Change |
|---|---|
| `main_twoasset_grid_certification.m` | **new.** Drives the 3×3 joint refinement matrix, the curvature and boundary sweeps, the dispersed-start test, and computes every gate in the acceptance matrix. Writes `output/quarantine/twoasset_certification.mat` and a table. |
| `src_project/kv_gate_report.m` | **new.** One place that evaluates the twenty gates against a solved equilibrium and returns pass/fail plus the normalized metrics, so no driver re-implements a threshold. |
| `main_preferred_signal_noise.m` | already written; becomes gate 11's implementation. Extend to report `Δν_reval` and `Δwelfare` contrasts, not only `ΔP`. |
| `main_twoasset_ownership_kv.m` | `REGRID` already added; needs the recalibration run before certification is meaningful |
| `output/quarantine/` | **new directory**, with a README stating the quarantine rule |

### Phase D — identification

| File | Change |
|---|---|
| `IDENTIFICATION_AND_EXTERNAL_DISCIPLINE_R10.md` | **new.** Component table, moment inventory, extrapolation statement. |
| `LITERATURE_IDENTIFICATION_MAP_R10.md` | **new.** Blocked on network access — see §7 below. |
| `main_identification_diagnostics.m` | **new.** Targeted vs untargeted moments; leave-one-target-out; local sensitivity of the financing contrast to each target. |
| `data/templates/*.csv` | the three existing empty templates are the right home for the external moments; extend the wealth-mobility template to carry response moments, not only levels |

### Phase E — experiments

| File | Change |
|---|---|
| `main_deficit_2x2.m` | **new.** The four cases of §3, one-asset first. |
| `main_signmap_masked.m` | **new.** Sign map over `(λ, ι_H, concentration)` with the validity mask of §5 below. Two-asset, therefore quarantined. |
| `main_frontloading_table.m` | **new.** Computes every front-loading statistic under one definition set (§5). |

### Phase F — paper reconstruction

Deferred. The demotion map in `REFEREE_REPORT_INTERNAL_R9.md` §6 stands, with
the Experiment R promotion added to it.

---

## 5. Two specifications the plan needs, stated now

### Front-loading statistics (one definition set)

For instrument `j ∈ {LS, L}` and price level `P`:

```
F^j_P      = (P^j_0 − P^0) / (P^j_∞ − P^0)          own-path capitalization
F^{L−LS}_P = (P^L_0 − P^{LS}_0) / (P^L_∞ − P^{LS}_∞) cross-instrument capitalization
```

`F > 1` is overshooting and must be labelled as such. The manuscript's 77%
and 89% are `F^j_P` in two different economies; the 107% is `F^{L−LS}_P`.
They are not comparable and must never appear in the same sentence without
their superscripts.

### Sign-map validity mask

At every parameter point store: convergence status; both normalized market
residuals; both boundary masses; the grid-stability metric (gate 11 computed
locally on a 2×2 sub-refinement); the financing contrast; its signal-to-noise
ratio; economic admissibility. Points failing any of these are rendered
**blank or hatched** — never as an economic result.

Plot layers: sign of the contrast; magnitude; certification mask; the
calibrated point; external empirical ranges; distance to the zero contour.

Report separately the **ordering** result `P^levy > P^lump` and the
**straddling-zero** result `P^levy > P^0 > P^lump`. Measure: the admissible
parameter volume supporting each; the calibrated point's distance to the
nearest reversal; which parameter drives the reversal; and whether the
ordering survives where the level sign fails.

---

## 6. Ordered MATLAB commands

Do not run Phase C before the recalibration in step 2 — certifying a
calibration fitted on a different grid certifies nothing.

```matlab
%% Phase C-0  finish the diagnostic already in flight (optional, 15 min)
clear; FAST = true; BFAC = 8; RESCAN = true; main_kv_residual_scan

%% Phase C-1  recalibrate ON the grid that will be certified   (1-2 h)
clear; FAST = true; REGRID = true; main_twoasset_ownership_kv
%   then, once the debug pass looks sane:
clear;             REGRID = true; main_twoasset_ownership_kv     % benchmark

%% Phase C-2  signal-to-noise on the financing contrast          (30-60 min)
clear; FAST = true; main_preferred_signal_noise
clear;             main_preferred_signal_noise

%% Phase C-3  the certification matrix                    (LONG: 8-16 h)
clear; main_twoasset_grid_certification          % 3x3 joint + curvature + bounds

%% Phase B  (independent of C; may run any time)
clear; main_regimes_fixed_real                   % verify Table R reproduces

%% Phase E  one-asset first, unblocked by the two-asset gate
clear; main_deficit_2x2                          % four cases, one-asset
clear; main_frontloading_table                   % one definition set

%% Phase D
clear; main_identification_diagnostics
```

Everything from `main_twoasset_grid_certification` onward writes to
`output/quarantine/` until the gate passes.

---

## 7. Decisions requiring approval

| # | Decision | Why it is yours | My recommendation |
|---|---|---|---|
| D1 | **Literature verification is blocked here.** This container has no usable outbound access for paper retrieval — an earlier attempt in this project was refused by the proxy for arXiv, Brookings and the Cleveland Fed. I can attempt web tools, or you supply PDFs/citations, or you verify. | I will not write a citation I have not read | You verify, or paste the four abstracts and I build the map |
| D2 | Prose edits are frozen by your §11 but your §9 lists "removal of unsupported threshold claims" as proceed-now. | Direct conflict in the brief | Treat §11 as binding: I have produced the location list in §2 above and will not touch the manuscript until you say go |
| D3 | Rename `\DefHalfStar` → `\DefHalfStarRatchet` (and the `\DefRhoStar*` family). This touches `numbers_manual.tex`, which is repo-maintained. | Macro renames propagate | Do it, in the same commit as the location fixes |
| D4 | Consolidation path for case C2: geometric surcharge, `T_c = 10` yr, half-life 10 yr, scaled to `κ_∞ = 1`. | Must be fixed before results are seen | Approve as written, or name another |
| D5 | `κ̄` for case C3: match the `κ_∞` that C4 produces endogenously, or set it independently? | Determines whether C3 − C1 is the right counterfactual for C4 | Match C4's realized `κ_∞`, so the 2×2 is balanced |
| D6 | Certification runs on FAST first or straight to benchmark? FAST is ~1 h, benchmark ~8–16 h. | Compute budget | FAST first to shake out the driver, then benchmark; only benchmark results are certifiable |
| D7 | If gate 11 cannot be met after certification, publish with one-asset quantitative claims plus a documented two-asset numerical limitation? | Scope of the paper | Yes — that is a publishable paper; an uncertified sign is not |
| D8 | Sign-map parameters: `(λ, ι_H, concentration)` as I proposed, or a different triple? | Yours to choose | As proposed; these are the three the straddling-zero result is said to depend on |
| D9 | Should Experiment R or Experiment N be the *first* table the reader sees? | Editorial | R first (it answers the title question), N immediately adjacent |

---

## 8. What was verified for this document, and how

- Commit hash for `REFEREE_REPORT_INTERNAL_R9.md`: read from `git log`.
- Existence and content of the fixed-real experiment: read from the manuscript
  source and `paper/numbers_auto.tex`.
- Threshold locations: `grep` over the manuscript and both numbers files, with
  unrelated uses of "threshold" excluded by inspection.
- `\DefRho` / `\DefHalfLife` / `\DefHalfStar` consistency: arithmetic checked
  by hand (ln 0.5 / ln ρ).
- Numerical statuses in the acceptance matrix: read from this session's
  diagnostic console output, all on the FAST debug grid.

Not done, and not claimed: no TeX compile, no MATLAB run, no literature
retrieval, no new numerical result.
