# Run sheet for the next MATLAB session

Everything below is already committed; run in this order from
`research_green_deficits/`. Send back the listed `.txt` tables (and any red
error text verbatim — the two-asset and audit drivers were authored without
a MATLAB environment, so first-run errors are expected and fast to fix).

## 1. Two-asset Step 0 — smoke test first (minutes)

```matlab
FAST = true; main_twoasset_step0
```

What it does: baseline (P, q) equilibrium with chi_b calibrated to the
liquid debt target; lump-sum vs levy as full two-market equilibria; the
d ln P vs zeta sweep; the liquid-margin incidence split; an EGM-vs-VFI
solver self-test. The EGM solver is the default and is warm-started through
every equilibrium loop, so the FAST run should be minutes, not hours.

Checks to eyeball in `output/tables/twoasset_step0.txt`:
- `self-test` line: dS_b between EGM and VFI should be small (~1e-3 or
  better at the coarse grid). If it is large, send the table — the solvers
  disagree and I need to see by how much.
- `spread` should be positive (equity return above bond return = the
  convenience yield).
- The `sign contrast survives: 1` line under (2) is the headline.

Then the full run (longer; still tractable with EGM):

```matlab
clear; main_twoasset_step0
```

## 2. Variant (b): infrequent k-adjustment (AFTER Step 0 passes)

Only run this once Step 0's self-test line looks sane — variant (b) reuses
the same convenience-utility block and the Step 0 EGM as its consistency
anchor.

```matlab
clear; FAST = true; main_twoasset_kv
```

The driver was speed-rebuilt after the first overnight attempt stalled:
the household solver is now a vectorized discrete-choice VFI (no nested
golden searches), the distribution is a sparse-matrix power iteration,
the tax fixed point uses full updates, chi is calibrated by secant, and
the value function warm-starts across every equilibrium. **Progress lines
now print continuously with elapsed seconds** — if you see no new line
for ~10 minutes, kill it and send the last lines printed. Expected: FAST
~10–20 min, full run ~1–3 h (not overnight):

```matlab
clear; main_twoasset_kv
```

Checks to eyeball in `output/tables/twoasset_kv.txt`:
- `HtM` line: the wealthy-hand-to-mouth share should be materially positive
  (US target ~20%; if it is ~0, lambda or the cutoffs need recalibration —
  send the table and I adjust).
- `lambda->1 check`: the KV liquid aggregate should approach the
  frictionless EGM value (gap ~1e-2 or better at FAST grids). This is the
  main correctness gate for the whole variant.
- `policy-flow by group` under (3): whether wealthy hand-to-mouth
  households carry a nonzero direct response — the referee-facing answer
  on the covariance channel with realistic bond ownership.
- `sign contrast survives: 1` under (2).

## 2b. Non-separable liquidity + two-asset transition (new scaffolds)

Both reuse the Step 0 economy; run after Step 0 has produced
`output/twoasset_step0.mat`.

**Non-separable liquidity** — the specification test of whether the one-asset
lump-sum *disinflation* survives when consumption and liquidity are
complements (CES bundle, elasticity xi). The xi sweep runs under parfor —
open a pool first:
```matlab
parpool;
clear; FAST = true; main_twoasset_nonsep
```
Eyeball `output/tables/twoasset_nonsep.txt`: the `ls sign` column. If any
`xi < 1` shows `NEG(!)` for `dlnP(ls)`, the disinflation is a feature of
complementary liquidity and that becomes the benchmark specification.

**Two-asset nonlinear transition** — the joint {P_t, q_t} announcement path
(the computational showpiece). Note: the transition is inherently sequential
(backward/forward passes in time), so it does not use the pool; its speed
comes from vectorization and from skipping the value-evaluation pass, and
the earlier "ok"-field crash is fixed:
```matlab
clear; FAST = true; main_twoasset_transition
```
Watch the `outer NN: max dlnP / max dlnq` convergence lines. Eyeball
`output/tables/twoasset_transition.txt`: the `front-loading share` vs the
one-asset Section 6.3 value, and the `max tree-market residual`. Both drivers
are first-run scaffolds — send the console output verbatim if either fails to
converge and I will tune the damping / grids.

## 2c. Convenience-yield calibration (closes the specification fork with data)

```matlab
parpool; clear; FAST = true; calibrate_convenience_kvj
```
Computes the model's d(spread)/d ln(debt) — the Krishnamurthy--Vissing-
Jorgensen regression object — across the curvature zeta, and reports the
zeta* matching the empirical headline (−0.75 pp per log point). If a zeta*
exists, rerun Step 0 at that zeta: its lump-sum sign is the paper's
DISCIPLINED answer. If the separable model cannot reach the KVJ range, the
CES variant takes over. Eyeball `output/tables/convenience_kvj.txt`.

## 2d. R1 + R2: welfare-by-decile and ownership recalibration (new)

**R1 — who pays, in the two-asset world** (runs in minutes; needs
`twoasset_step0.mat`, uses `twoasset_kv.mat` too if present):
```matlab
clear; main_twoasset_welfare
```
Output `output/tables/twoasset_welfare.txt`: CE incidence by baseline-wealth
decile for lump-sum and levy, in BOTH two-asset economies. This is the table
that answers the paper's title in the disciplined model — compare the decile
profile against the one-asset Section 5 tables.

**R2 — ownership-calibrated economy** (intermediation wedge iota_H, direct
liquid target 0.30 of income, superstar income state, endogenous fund
dividend):
```matlab
parpool; clear; FAST = true; main_twoasset_ownership
```
Eyeball `output/tables/twoasset_ownership.txt`: does WHtM turn positive, do
the top wealth shares approach the data, and what happens to dlnP per
instrument when only the directly-held slice of debt clears the bond market.

## 3. Incidence audit — smoke test, then full (full run is hours)

The audit is now PARALLELIZED (Blocks A, D, E, F, G run under parfor).
Open a pool first to get the speedup — otherwise it runs serially:

```matlab
parpool;                        % once per session; uses all local cores
clear; FAST = true; audit_tax_incidence
```

then the full run (with a pool this should be a few hours, not overnight):

```matlab
clear; audit_tax_incidence
```

Blocks: A step-size/identity validation; B exact policy-flow +
distribution-stock decomposition; C the dynamic path (tests the
short-run/long-run sign reversal dS_0 < 0 < dS_inf — the key hypothesis);
D dense borrowing-limit map under fixed AND recalibrated beta (the
+18.2 -> -4.96 swing resolves here); E levy sweep; F sufficient-statistic
validation; G grid audit. Block D's recalibrated-beta row is the expensive
part.

## 4. Refresh the paper macros

```matlab
clear; export_paper_numbers
```

This now also picks up the two-asset results (guarded — it exports them
only if `output/twoasset_step0.mat` exists and the baseline converged).

## 5. Push

Push **only** `output/` and `paper/numbers_auto.tex`. Please do not upload
your local copy of `paper/green_deficits_price_level.tex` — it is behind
the branch and re-uploading it reverts the revision (this has happened
twice before).

## Status (updated after the latest results)

- Step 0: full-grid rerun DONE and integrated (matched the FAST pass to the
  third decimal; the full zeta sweep is now in the paper).
- Variant (b): DONE and integrated.
- Audit: DONE and integrated — it drove a correctness fix (the
  borrowing-limit sign flip is a debt-target-collapse artifact; the honest
  recalibrated sweep is monotone positive), the exact policy-flow vs
  distribution split (machine-precision reconstruction), and the
  sufficient-statistic validation (formula matches solved d ln P to 10%).
- NEW to run: the two scaffolds in section 2b (non-separable liquidity,
  two-asset transition). These are the only pending runs.

## What to send back

1. `output/tables/twoasset_step0.txt`
2. `output/tables/twoasset_kv.txt`
3. `output/tables/audit_tax_incidence.txt`
4. `output/tables/twoasset_nonsep.txt`, `output/tables/twoasset_transition.txt`
5. `output/tables/twoasset_welfare.txt`, `output/tables/twoasset_ownership.txt`, `output/tables/convenience_kvj.txt`
6. Any MATLAB error text, verbatim, if a driver dies.

## What happens with the results

- Two-asset: the appendix subsection "A nonlinear two-asset benchmark"
  fills in (omega, spread, dlnP per instrument, the zeta endpoints, the
  liquid-margin split) via the new macros; the one-asset absorption ratio
  tells us how conditional the one-asset magnitudes are.
- Audit Block C: if the sign reversal is confirmed, the short-run vs
  long-run incidence distinction becomes a headline result and I write it
  into the transition section with the run's numbers.
- Audit Block D: decides what the borrowing-limit sweep is allowed to claim
  (economics vs confound), and fixes the elasticity-map table language.
