# Dynare block — transition dynamics

**Status: IMPLEMENTED at the RANK tier (U6) and at the HANK tier-1
(U7, native heterogeneity framework); both runs pending on the user's
machine.**

## Files

| file | tier | what it produces |
|---|---|---|
| `green_rank_nk.mod` + `run_green_transitions.m` | U6 RANK | nonlinear perfect-foresight **transition paths** for the permanent program, four regimes, PFig13 |
| `green_hank.mod` + `run_green_hank.m` | U7 tier 1 HANK | **linearized sequence-space IRFs** to a quasi-permanent green-investment shock, four regimes, PFig14 (requires the Dynare heterogeneity framework — the version that ran `heterogeneity/hank_one_asset_steady_state.mod`) |
| `green_rank_nk_steadystate.m` | U6 | exact steady states for any program size |

The HANK tier-1 model carries the paper's *redistribution* channel in
linearized form (nominal policy rate + ex-post Fisher equation, so surprise
inflation revalues household asset positions across the wealth
distribution) but **not** the DTPL price-*level* mechanism; the nonlinear
P\* transition is tier 2 (appendix/HANK_TRANSITION_PLAN.md, NOT YET
IMPLEMENTED).

`green_rank_nk.mod` is a representative-agent New Keynesian skeleton
(Rotemberg pricing, inertial Taylor rule, real debt with a debt-stabilizing
tax rule, green public capital, carbon stock, TFP damages). Running

```
dynare green_rank_nk
```

produces perfect-foresight **transition paths** for a permanent
deficit-financed green-investment program (output, inflation, debt, green
capital, carbon stock, damages, taxes) — the tier-1 answer to referee risk
R1 ("only steady state").

**Honest scope limits:**

- This block does **not** contain the paper's price-level mechanism. The
  DTPL requires incomplete markets; in RANK, inflation dynamics come from
  the Taylor rule + Phillips curve, and the price *level* is not pinned by
  asset demand. Use it only for transition shapes of the real/nominal block.
- The HANK transition (sequence-space Jacobians around the steady states
  computed by the MATLAB package; belief-switch experiment between the
  green-boom and brown-stagnation equilibria where they exist) is
  **NOT YET IMPLEMENTED** — roadmap step U7.
- The calibration is quarterly and illustrative; the steady-state block may
  need `initval` tuning depending on your Dynare version. Treat failures of
  `steady` as calibration issues in this skeleton, not as statements about
  the paper's model.

**Four-regime comparison (implemented):** `run_green_transitions.m` runs
the .mod under WEAK / TAYLOR / AGGRESSIVE / GREENACCOM (temporary
accommodation tied to the green-capital gap, fading as kg converges),
collects the perfect-foresight paths, and produces PFig13 plus
`transitions_summary.txt`. Steady states are computed exactly for any
program size by `green_rank_nk_steadystate.m` (fixed point over damages,
bisection on labor) -- no hand-tuned initval.

**Convergence notes (from the first two runs):**

- A pure interest-rate peg (`phi_pi = 0`, and even `phi_pi = 1.01`)
  violates or barely satisfies the Taylor principle and leaves the stacked
  perfect-foresight Newton system singular or near-singular; the near-peg
  corner is therefore represented by WEAK (`phi_pi = 1.1`, `rho_i = 0.5`).
- GREENACCOM uses `psi_g = 0.03` (~70bp annualized accommodation at the
  program start); larger values imply implausibly deep cuts and destroy
  convergence.
- The program **ramps in linearly over 12 quarters** (implementation
  delays, Leeper–Walker–Yang) instead of jumping — more realistic and far
  easier numerically.
- The solver call is **chained** (default, then `stack_solve_algo=6`, then
  higher `maxit`), each attempt warm-starting from the previous iterate.
- The driver enforces a **hard convergence check**
  (`oo_.deterministic_simulation.status`) plus a mechanical validation of
  the kg accumulation law; unconverged paths are discarded, never reported.
- Each regime runs as its own copy `grnk_<name>.mod` to avoid stale
  preprocessor artifacts when one .mod is re-run with different `-D`
  defines (a known failure mode on Windows).
