# HANK transition plan (roadmap U7)

*Status: **PLAN ONLY — NOT YET IMPLEMENTED.** This document specifies the
full heterogeneous-agent transition computation so that the Dynare RANK
block is never mistaken for it (project standard: do not present RANK/NK
paths as HANK results). Method: sequence-space Jacobians (Auclert–Bardóczy–
Rognlie–Straub 2021) around the steady states already computed by the
MATLAB package.*

## 1. Objects

**Household state vector** (per period): `(a, e)` on the existing grids
(`na = 500` assets × `ne = 7` income states); policies from
`solve_household_vfi` (or EGM for speed inside the Jacobian builder);
distribution `Omega_t` propagated by the exact transition matrix already
implemented in `compute_stationary_distribution`.

**Aggregate state vector**: green capital `Kg_t`, carbon stock `X_t`
(climate version 2), nominal debt `B_t` (policy-given path), price level
`P_t`, damage `D_t = D(X_t)`.

**Unknown sequence vector** (length `T ≈ 300`): the price-level path
`{P_t}` — everything else is either policy-given (`i_t`, `mu_t`, `Gg_t`),
recursively determined by climate laws of motion, or a household response.

**Residual equations** (one per period): asset-market clearing
`S_t(1+r_t; {tau_s}, {D_s}) − B_t/P_t = 0`, where `S_t` is the aggregate
asset function evaluated along the perfect-foresight sequences and
`tau_t = r_t B_t/P_t + Gg_t/P_t` (budget-balance each period; regime
variants as in `solve_regime_equilibrium`).

**Jacobians to build**: `dS_t/dtau_s`, `dS_t/dD_s`, `dS_t/dr_s` — the
fake-news algorithm on the household block (one backward pass per
perturbation date, one forward distribution pass); the climate block
Jacobian `dD_t/dP_s` (through `g = Gg/P` and the `Kg`, `X` laws of motion)
is lower-triangular and cheap.

**Terminal conditions**: the economy converges to a stationary green
equilibrium already computed by `solve_green_steady_state` (unique in the
calibrated benchmark). Initial conditions: the no-program steady state's
`Omega_0`, `Kg_0 = 0`, `X_0 = X(no program)`.

## 2. Experiments (in order of paper value)

1. **Program announcement (MIT-style, perfect foresight)**: at `t = 0` the
   nominal green budget `Gg_t` turns on permanently. Deliverables: paths of
   `P_t` (does disinflation arrive on impact or build?), `tau_t`, `D_t`,
   `Kg_t`, the *transition-inclusive* self-financing share
   `nu^PV = PV(revaluation + damage dividend)/PV(program cost)` — the
   dynamic analog of the steady-state `nu`, which the steady-state
   comparison under- or over-states depending on the `Kg` build-up speed
   and `q_g` delays.
2. **Financing-regime transitions**: R1 vs R3 along the path (does the
   rebate regime's price-level increase front-load?).
3. **Accommodation timing**: temporary vs permanent `mu` accommodation
   (the temporary green-accommodation rule of the research-program spec).
4. **Belief-switch experiment** (only if a calibration with multiplicity is
   found): jump between basins.

## 3. Validation checks

- `T → ∞` limit of every path matches the corresponding steady state from
  the MATLAB package (tolerance `1e-4` on `P`, `D`, `tau`).
- Jacobian symmetry/shift checks (fake-news lemma diagnostics).
- A RANK version of the same sequence problem must reproduce the Dynare
  block's paths (cross-validation of the two codebases).
- The `t = 0` impact response of `S` to a pure `tau` perturbation must match
  the finite-difference derivative of the steady-state `S(tau, D)`
  interpolant nodes.

## 4. Effort estimate and risks

Fake-news Jacobians on a 3,500-state household block with ~4 input
sequences and T = 300: days of implementation, minutes of runtime per
experiment. Main risk: the `S_t` object here depends on the *price level*
through taxes and damages simultaneously — the composite Jacobian must be
assembled carefully (chain rule through `g = Gg/P`), which is exactly why
this plan exists before the code does.
