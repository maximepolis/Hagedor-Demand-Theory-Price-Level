# HANK transition plan (roadmap U7)

*Status update: **TIER 1 RUN-VERIFIED (one-asset, five regimes) — TIER 2 v1 IMPLEMENTED, RUN PENDING.***

- **Tier 1 (run VERIFIED):** `dynare/green_hank.mod` +
  `dynare/run_green_hank.m` — a native-Dynare heterogeneity-framework HANK
  (one liquid asset, borrowing constraint, Rouwenhorst income) with the
  climate block and a nominal-rate/ex-post-Fisher pair, delivering
  **linearized sequence-space IRFs** to a quasi-permanent deficit-financed
  green-investment shock under four monetary regimes. Surprise inflation
  revalues household asset positions there — the redistribution channel,
  linearized. Built on the framework verified to run by
  `heterogeneity/hank_one_asset_steady_state.log`.
- **Tier 2 (v1 IMPLEMENTED, run pending):** the *nonlinear* DTPL
  price-level transition — P\* pinned by asset-market clearing, the
  unknown sequence being the price-level path itself — is now implemented
  in `src_project/solve_hank_dtpl_transition.m` (+`hh_bellman_step.m`,
  driver `main_project_transition.m`, PFig18): backward Bellman induction
  from the green terminal steady state under time-varying (r_t, tau_t,
  D_t) including the risk channel, exact forward distribution iteration
  from the pre-announcement steady state, damped multiplicative fixed
  point on the stationarized price path with adaptive damping + trust
  region, market-clearing residuals reported at every date. v1 uses the
  fixed-point update rather than fake-news Jacobians (below) — the
  Jacobian route remains the planned upgrade if v1 convergence is slow.
  Two default experiments: nominal appropriation vs indexed mandate
  (the dynamic anchor-insulation comparison). A non-converged path is
  returned as such and is not a result.

*The remainder specifies tier 2. Method: sequence-space Jacobians
(Auclert–Bardóczy–Rognlie–Straub 2021) around the steady states already
computed by the MATLAB package.*

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
