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

then (overnight — the first household solve on the 3D state is the slow
part; everything after warm-starts):

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

## 3. Incidence audit — smoke test, then full (full run is hours)

```matlab
clear; FAST = true; audit_tax_incidence
```

then, ideally overnight:

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

## What to send back

1. `output/tables/twoasset_step0.txt`
2. `output/tables/twoasset_kv.txt`
3. `output/tables/audit_tax_incidence.txt`
4. Any MATLAB error text, verbatim, if a driver dies.

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
