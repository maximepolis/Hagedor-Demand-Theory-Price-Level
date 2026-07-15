# HANK / heterogeneous-agent solution methods — provenance and what we use

This project's dynamic exercises (the RANK and linearized-HANK Phillips-curve
transitions, and the nonlinear DTPL announcement transition) draw on standard
heterogeneous-agent computational methods. This note records what was drawn
from an external reference toolkit (a Dynare masterclass "Extensions" session)
and how it was adapted, so provenance is transparent and nothing is copied
without attribution.

## What the reference toolkit contains

A set of reference implementations of:
- **Sequence-space Jacobian (SSJ)** solve/estimate machinery in the style of
  Auclert, Bardóczy, Rognlie, and Straub (2021) — `ha_ge_jacobian.m` (GE
  Jacobian via the fake-news recursion), `ha_td_solve.m` (nonlinear MIT-shock
  transition as a chord-Newton on the aggregate path), `ha_backward_step.m`,
  `ha_backward_precompute.m`, `ha_aggregate.m`, `ra_sequence_jacobian.m`.
- **Reiter (2009)** state-space linearization — the `reiter_*.m` family
  (residual, analytic/finite-difference Jacobians, QZ solve, simulation,
  dimension reduction).
- **Dynare `.mod`** one- and two-asset HANK models with bundled steady-state
  `.mat` seeds, and RA references (Smets–Wouters, Herbst–Schorfheide,
  Krusell–Smith).

These routines are tightly coupled to Dynare's heterogeneity structures
(`M_`, `oo_.heterogeneity`, `dr.G`) and to the ABRS (2021) replication package.
They are **reference material**, not drop-in project code.

## What we adapted, and how

Our nonlinear DTPL transition (`solve_hank_dtpl_transition.m`) has a scalar
aggregate unknown per date — the log price level — so the full fake-news
machinery is unnecessary. We took the **method and the correctness-gate idea**,
not the code, and wrote project-native routines:

| New project file | Draws on | What it does |
|---|---|---|
| `src_project/transition_residual_dtpl.m` | the residual pattern of `ha_td_solve` | factors the per-path market-clearing residual into a pure function (an independent second implementation of the Anderson solver's residual) |
| `src_project/ssj_transition_jacobian.m` | the sequence-space Jacobian of Auclert et al. (2021) | builds the GE Jacobian `J[t,s]=∂resid_t/∂ln P_s` **directly** by finite differences (affordable here: scalar unknown per date) rather than via fake-news |
| `src_project/solve_transition_ssj.m` | `ha_td_solve`'s chord-Newton and its "first iterate = linear IRF" gate | Newton solve of the transition in sequence space; returns a **sequence-space determinacy diagnostic** (σ_min, cond, det-sign of `J`) |
| `verify_transition_ssj.m` (driver) | the toolkit's built-in correctness gate | runs Anderson vs SSJ-Newton on the headline announcement transition, cross-checks agreement, reports the determinacy diagnostic |

Nothing from the toolkit is copied verbatim into the replication package; the
Dynare-coupled files are not redistributed. The method is cited in the paper
(Auclert et al. 2021; Reiter 2009) at the transition solver description.

## Why this improves the project

1. **Independent cross-validation of the headline dynamic claim.** The
   announcement result (77% of the green disinflation and the bondholder
   windfall in year one) is now solved two ways, on two independent residual
   codes; agreement is a real correctness gate, not a re-run of the same solver.
2. **A dynamic determinacy test.** The GE Jacobian's conditioning is the
   sequence-space counterpart of the steady-state `ε_S < −1` diagnostic — it
   detects the flat-demand multiplicity region *along the transition*, not only
   across steady states.
3. **A faster, principled solver.** Newton on the exact GE Jacobian converges
   quadratically where the Anderson fixed point converges linearly, at the cost
   of `T−1` extra residual solves to build `J` (documented; the user can freeze
   `J` at the first iterate for the chord-Newton variant).

## Status / validation

The SSJ routines are implemented but, like every quantitative object in the
package, are a *result* only once run and verified. `verify_transition_ssj`
must report solver agreement (`max |ΔP̂|/P̂ < 1e-2`) before any SSJ-derived
number is quoted. This environment did not run MATLAB, so no SSJ number is
asserted in the paper; the method note is stated as a cross-check the driver
performs.

## Not adopted (and why)

- The **two-asset HANK** `.mod`/`.mat` and the endogenous-convenience-yield
  extension it would enable (referee M5) remain a genuine model extension, not a
  method port: it needs Dynare, a re-calibration, and validation. It stays on
  the conclusion's open-items list rather than being asserted here.
- The **Reiter state-space** path (QZ on a linearized state space) is an
  alternative to the sequence-space route; we use the sequence-space Jacobian
  because our unknown is a short scalar path and the SSJ gives the cleanest
  cross-check and determinacy read.
