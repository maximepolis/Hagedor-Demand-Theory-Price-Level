# Model-status report

*Audit of every model block against the full research-program specification.
Labels: **IMPLEMENTED** (code runs, output verified), **PARTIALLY IMPLEMENTED**
(a restricted version runs), **PROPOSED** (designed, not coded),
**PLACEHOLDER** (interface exists, content pending data/inputs),
**NOT YET IMPLEMENTED**. This report is generated from code inspection and the
two verified runs (baseline `main_project_run_all`, na=500, 68 s; extended run
that crashed at X2 and is fixed as of this commit), not from the paper draft.*

## 1. Households

| Component | Status | Where / what remains |
|---|---|---|
| Incomplete markets, idiosyncratic income risk (7-state Rouwenhorst AR(1)) | **IMPLEMENTED** | root `src/`, wrapped by `S_green.m` |
| Liquid nominal government bonds, borrowing constraint | **IMPLEMENTED** | benchmark `abar=0` |
| Heterogeneous climate-damage exposure (incidence gradient `chi(e)`) | **IMPLEMENTED** | `S_green.m`, `psi_inc` |
| Endogenous climate income risk (`sig_eps(D)`) | **IMPLEMENTED** | reduced form, `phi_D` |
| Wealth distribution realism (match Gini / top shares / MPC moments) | **PROPOSED** | Ginis computed; not yet targeted in calibration |
| Illiquid capital/equity (two-asset) | **NOT YET IMPLEMENTED** | needed for KMV-style MPC realism |
| Heterogeneous energy-expenditure shares | **PROPOSED** | requires an energy good in preferences |
| Portfolio exposure to nominal debt (maturity, indexation mix) | **PROPOSED** | single one-period nominal bond currently |

## 2. Firms

| Component | Status | Notes |
|---|---|---|
| Production sector at all | **NOT YET IMPLEMENTED** in the HA block | endowment economy by design (transparency); root package has Hagedorn's capital extension as a template |
| Sticky prices (NK) | **PARTIALLY IMPLEMENTED** | `dynare/green_rank_nk.mod`: Rotemberg RANK skeleton for transitions only |
| Clean/dirty sectors, energy input, brown-capital stranding | **NOT YET IMPLEMENTED** | design in ROADMAP.md |
| Climate damages to productivity | **PARTIALLY IMPLEMENTED** | damages hit endowments (HA block) / TFP (Dynare skeleton) |

## 3. Government

| Component | Status | Notes |
|---|---|---|
| Nominal debt, nominal growth rule, passive lump-sum taxes | **IMPLEMENTED** | the DTPL backbone |
| Nominal green budget vs real-indexed green mandate | **IMPLEMENTED** | both regimes in `solve_green_steady_state.m` |
| Carbon taxes | **NOT YET IMPLEMENTED** | required for regime comparison (ROADMAP step Q9) |
| Distortionary labor/capital taxes | **NOT YET IMPLEMENTED** | referee risk #3; lump-sum is the transparent benchmark, labeled as such |
| Targeted transfers | **NOT YET IMPLEMENTED** | |
| Debt maturity structure | **NOT YET IMPLEMENTED** | referee risk #9; single-period debt currently |
| Debt-stabilizing fiscal rules | **PARTIALLY IMPLEMENTED** | root package has nominal/real tax rules; not yet joined to the climate block |

## 4. Climate

| Component | Status | Notes |
|---|---|---|
| Emissions, carbon stock, damages (bounded) | **IMPLEMENTED** | `climate_block2.m` (version 2), fixed point proved monotone |
| Reduced-form abatement damages | **IMPLEMENTED** | `climate_block.m` (version 1) |
| Temperature as separate state | **PROPOSED** | currently carbon stock maps directly to damages; a linear T(X) layer is trivial to add and changes nothing qualitatively |
| Mitigation capital (public) | **IMPLEMENTED** | `Kg = g_g/delta_g` |
| Adaptation capital (distinct from mitigation) | **NOT YET IMPLEMENTED** | would enter `chi(e)` or `Dmax` |
| Idiosyncratic climate risk | **IMPLEMENTED** | `phi_D` channel + incidence-induced dispersion |
| Low/medium/high damage calibrations | **PROPOSED** | plan in appendix/CALIBRATION_APPENDIX.md (DICE conservative / Burke-Hsiang-Miguel medium / Bilal-Känzig high); current numbers ILLUSTRATIVE |
| Climate-risk shock process (aggregate) | **NOT YET IMPLEMENTED** | no aggregate risk anywhere yet |
| Biodiversity/natural capital | **NOT YET IMPLEMENTED** | optional extension |

## 5. Monetary policy

| Component | Status | Notes |
|---|---|---|
| Nominal-rate peg (i fixed) | **IMPLEMENTED** | the baseline stance |
| Choice over nominal growth mu (accommodation) | **IMPLEMENTED** | `optimal_policy_green.m`, W(mu), interior mu*=0.045 |
| Taylor rule / inflation targeting / temporary green-accommodation rule | **PARTIALLY IMPLEMENTED** | in the Dynare RANK skeleton only; steady-state DTPL block has no role for a Taylor coefficient by construction (the peg + growth rule pins r) |
| Optimal Ramsey policy | **PROPOSED** | current exercise is a grid over mu, utilitarian steady-state W |

## 6. Equilibrium and solution

| Component | Status | Notes |
|---|---|---|
| Stationary equilibrium, all roots of Phi(P), elasticity diagnostic | **IMPLEMENTED** | `solve_green_steady_state.m` |
| Steady-state vs transition vs aggregate-risk separation | **IMPLEMENTED (labels)** | ALL quantitative results to date are STEADY STATE ONLY; transitions: Dynare RANK skeleton (PARTIAL); HANK sequence-space transitions NOT YET IMPLEMENTED; aggregate risk NOT YET IMPLEMENTED |
| Exact re-solve at roots, interpolation-residual reporting | **IMPLEMENTED** | |

## 7. Welfare and incidence

| Component | Status | Notes |
|---|---|---|
| Utilitarian steady-state welfare | **IMPLEMENTED** | value function under invariant distribution |
| Consumption-equivalent units | **PROPOSED** | trivial transformation `((W1/W0))^(1/(1-sigma))-1` under CRRA with care for the -1/(1-sigma) constant; to add |
| Welfare by wealth/income quintile | **PROPOSED** | distribution and V are stored; a `welfare_by_group.m` is a small addition |
| Bondholder levy | **IMPLEMENTED** | one-time L in the decomposition (found NEGATIVE: windfall) |
| Energy-exposure / sector-exposure groups | **NOT YET IMPLEMENTED** | requires energy good / sectors |

## 8. Self-financing decomposition channels (the paper's Eq. nu)

| Channel | Status |
|---|---|
| Nominal debt revaluation | **IMPLEMENTED** (sign found negative at benchmark: green disinflation) |
| Avoided-damage dividend | **IMPLEMENTED** |
| Endogenous safe-asset-demand channel | **IMPLEMENTED** (it is what flips the revaluation sign; separately reportable from the S(tau,D) nodes) |
| Output/tax-base expansion | **PARTIALLY IMPLEMENTED** (in an endowment economy the "output" channel IS the damage dividend; separate identification needs production) |
| Liquidity / convenience yield | **PROPOSED** (requires a convenience-yield wedge or two-asset structure) |
| Debt-maturity / term-structure valuation | **NOT YET IMPLEMENTED** |
| Distributional transfer/incidence effects | **PARTIALLY IMPLEMENTED** (levy incidence + Ginis; group-level welfare PROPOSED) |

## 9. Empirics

| Component | Status |
|---|---|
| E1 nominal-anchor regression (OLS + HC1, Wald beta=1) | **IMPLEMENTED** (`empirical_anchor.m`; runs on the repo's 34-country OECD file) |
| E2 green-budget denomination panel | **PLACEHOLDER** (schema + loader implemented; data absent by design — never fabricated) |
| E3 revaluation-sign event study | **PROPOSED** (design in the paper, Sec. 6) |
| Sovereign-yield / climate-vulnerability validation | **NOT YET IMPLEMENTED** |

## Verified run record

- Baseline `main_project_run_all` (na=500): completed in 68.4 s; unique green
  steady state P*=0.1897, D=0.0468; nu=0.600 (reval −0.241 + damage 0.841);
  mu*=0.045 interior; no multiplicity for theta_g ≤ 2.5 at psi=0.
- Extended `main_project_extended` (na=500): first run crashed at X2
  (min-of-empty assignment) after revealing (i) infeasible high-(tau,D)
  interpolant corners under psi>0 and (ii) systematic equilibrium
  NON-EXISTENCE at mu=0.02 with incidence (fiscal-space collapse). All three
  addressed in this commit; rerun pending.
