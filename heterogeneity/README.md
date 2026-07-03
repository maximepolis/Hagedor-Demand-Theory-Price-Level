# heterogeneity — Dynare HANK framework examples

**Status: files RECEIVED and inspected** (hank_one_asset, hank_two_assets,
krusell_smith_1998, each with a `_steady_state` variant, plus generated
`+`-folders, .mat steady states, logs, and the Dynare manual).

## What the inspection established

- The examples use Dynare's **native heterogeneity framework**:
  `heterogeneity_dimension`, `var(heterogeneity=...)`, complementarity
  constraints (`⟂ a >= 0`), aggregation operators `SUM(...)`, steady-state
  computation from an `initial_guess` struct built in a `verbatim` block
  (with a built-in `rouwenhorst`), free-parameter calibration against
  named clearing conditions, and linearized solution via **sequence-space
  Jacobians** (`heterogeneity_solve(truncation_horizon=...)`).
- `hank_one_asset_steady_state.log` shows the framework **runs successfully
  on the user's machine** (calibration converged, beta = 0.9817,
  vphi = 0.7878, total 20 s) — the framework is viable for this project.

## How it is now used (roadmap U7, tier 1)

`research_green_deficits/dynare/green_hank.mod` ports the project to this
framework: the one-asset household block (verbatim from the working
example) + the climate block (kg, x, d) + a nominal policy rate with an
ex-post Fisher equation, so surprise inflation revalues household asset
positions — the paper's redistribution channel, linearized. The driver
`run_green_hank.m` runs four monetary regimes and produces PFig14.

**Honest scope:** that port delivers *linearized IRFs* to a
quasi-permanent green-investment shock. The *nonlinear DTPL price-level
transition* (P\* pinned by asset demand) is tier 2 and remains specified —
not implemented — in `appendix/HANK_TRANSITION_PLAN.md`.
