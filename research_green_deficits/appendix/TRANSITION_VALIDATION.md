# Transition validation (U6 RANK/NK + U7 tier-1 HANK)

*Records the verified transition runs, the validation criteria each path
must pass before it may be reported, and the honest scope of each tier.
Companion machine-written files (regenerated on every run):
`output/tables/rank_transition_validation.txt` and
`output/tables/hank_tier1_validation.txt`.*

## Scope labels (project standard)

| tier | label | what it is NOT |
|---|---|---|
| U6 `green_rank_nk.mod` | RANK/NK TRANSITION DIAGNOSTIC | not the DTPL price-level mechanism; inflation from NKPC + policy rule |
| U7 tier 1 `green_hank.mod` | TIER-1 LINEARIZED HANK IRF | not nonlinear DTPL price-level determination; a bridge, not the final answer |
| U7 tier 2 (planned) | NONLINEAR HANK-DTPL TRANSITION | NOT YET IMPLEMENTED (HANK_TRANSITION_PLAN.md) |

## Validation criteria (enforced by the drivers, unconverged paths discarded)

1. `oo_.deterministic_simulation.status` must be true (U6) / the
   heterogeneity solver must return IRFs (U7) — a failed Newton iterate is
   never reported (this discipline caught the first run's garbage paths).
2. Mechanical identity: `kg_t = (1-delta_g) kg_{t-1} + gg_t` to 1e-6 on all
   interior columns (the appended terminal-steady-state column is excluded;
   it sits a truncation gap ~ kg_gap*0.975^300 ≈ 3.4e-4 off the law, which
   is a property of horizon truncation, not of the solution).
3. Steady states computed exactly by `green_rank_nk_steadystate.m` /
   `heterogeneity_compute_steady_state` (no hand-tuned initval); the Dynare
   log prints market-clearing residuals (tol 1e-4 for the HANK tier).

## Verified U6 run (user machine, Dynare 8-unstable-2026-05-19)

All four regimes CONVERGED (solver residuals ~1e-14 after the chained
calls; every path passed the kg-law check).

| regime | pi impact (ann.) | pi peak (qtr) | debt peak | kg(40q) | d(40q) |
|---|---|---|---|---|---|
| WEAK       | −0.04% | +0.0039 | 1.004 | 0.349 | 0.0925 |
| TAYLOR     | −0.52% | +0.0007 | 1.004 | 0.349 | 0.0925 |
| AGGRESSIVE | −0.24% | +0.0003 | 1.004 | 0.349 | 0.0925 |
| GREENACCOM | +22.55% | +0.0564 | 1.004 | 0.349 | 0.0933 |

(Initial steady state: d = 0.0972, kg = 0; terminal: d = 0.0601, kg = 0.6.)

**Interpretation.**
- Tax-financed ramped program ⇒ essentially price-stable under any active
  rule (impact between −0.5% and 0.0% annualized; peak < +1.6% annualized).
- Real green transition is regime-independent: kg(40q) and d(40q)
  identical to three decimals across the active rules.
- GREENACCOM is a deliberately LARGE experiment (psi_g = 0.03 × kg-gap 0.6
  ≈ 1.8pp quarterly ≈ 7.2pp annualized initial cut). It yields a +22.6%
  annualized impact-inflation spike, the same kg(40q), and slightly HIGHER
  damages (output boom ⇒ more emissions): accommodation buys inflation,
  not green capital.
- FISCAL NOTE: the U6 tax rule finances gg contemporaneously by design;
  the deficit-financing experiments live in the steady-state MATLAB block
  and the HANK tier.

## Verified U7 tier-1 HANK run (user machine)

All four regimes SOLVED (IRF horizon 200; calibrated beta = 0.979640,
B = 3.96 targeting debt/annual-GDP = 1.10 at the damaged steady state).
IRFs to a one-std e_g shock (0.009 ≈ 1% of output, rho_g = 0.995,
deficit-financed on impact, phi_b = 0.10):

| regime | pi impact (ann.) | Y impact | b(40q) | kg(40q) | d(40q) |
|---|---|---|---|---|---|
| WEAK       | +2.18% | +0.0042 | +0.1023 | +0.2048 | −0.0039 |
| TAYLOR     | +0.31% | +0.0044 | +0.1023 | +0.2048 | −0.0039 |
| AGGRESSIVE | +0.07% | +0.0045 | +0.1022 | +0.2048 | −0.0039 |
| GREENACCOM | +0.53% | +0.0044 | +0.1023 | +0.2048 | −0.0039 |

**Interpretation.**
- DEFICIT financing flips the impact-inflation sign relative to the
  tax-financed U6 diagnostics (+ across all rules here vs − there); the
  size of the inflation impact is almost entirely a monetary-rule choice
  (+2.18% → +0.07% across rules).
- The real green path is again rule-independent (kg, d identical to three
  decimals across regimes) — the U6 finding survives heterogeneity and
  Fisher redistribution.
- Debt rises 0.102 (~2.6% of the stock) by 40 quarters vs a flat debt
  path in tax-financed U6.

Caveats (also printed in the validation file): income process is the
Dynare-example 3-state Rouwenhorst (rho_e = 0.966, sig_e = 0.5), NOT the
quantitative model's 7-state process — magnitudes indicative; alignment
is future work.

**New regime pending:** TAYLORBAL (PHIB = 0.75, near-balanced-budget
financing of the same program under the Taylor rule) has been added to
`run_green_hank.m`; the TAYLOR-vs-TAYLORBAL gap isolates the
deficit-financing component within the HANK tier itself. RUN PENDING.
