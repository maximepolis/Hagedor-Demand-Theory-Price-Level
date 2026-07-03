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
| Production sector | **PARTIALLY IMPLEMENTED** | Stage-1 aggregate layer `production_block_green.m` (Y=(1-D)A(Kg)N, tax-base split, Bom-Ligthart-checkable elasticity) exists but is NOT joined to the HA household block, which remains an endowment economy by design (transparency); clean/dirty CES + Pigouvian margin (U8) NOT YET IMPLEMENTED |
| Sticky prices (NK) | **PARTIALLY IMPLEMENTED** | `dynare/green_rank_nk.mod` (RANK, run VERIFIED: all four regimes converged) + `dynare/green_hank.mod` (tier-1 HANK, run completed, numeric summary pending) -- transition tiers only, NOT the DTPL mechanism |
| Clean/dirty sectors, energy input, brown-capital stranding | **NOT YET IMPLEMENTED** | design in ROADMAP.md |
| Climate damages to productivity | **PARTIALLY IMPLEMENTED** | damages hit endowments (HA block) / TFP (Dynare skeleton) |

## 3. Government

| Component | Status | Notes |
|---|---|---|
| Nominal debt, nominal growth rule, passive lump-sum taxes | **IMPLEMENTED** | the DTPL backbone |
| Nominal green budget vs real-indexed green mandate | **IMPLEMENTED** | both regimes in `solve_green_steady_state.m` |
| Proportional levy with carbon-tax-STYLE incidence (R2-PROP-LEVY) | **IMPLEMENTED** | `solve_regime_equilibrium.m` + `S_green.m` vartheta; a true Pigouvian carbon tax (production/emissions margin) remains **NOT YET IMPLEMENTED** (needs U8) |
| Distortionary labor/capital taxes | **NOT YET IMPLEMENTED** | referee risk #3; lump-sum is the transparent benchmark, labeled as such |
| Lump-sum rebate of levy revenue (R3-PROP-LEVY-REBATE) | **IMPLEMENTED** | negative tau_ls in the regime solver; TARGETED (state-contingent) transfers remain **NOT YET IMPLEMENTED** |
| Debt maturity / indexation / holder composition | **IMPLEMENTED (arithmetic + bounds tier)** | `debt_maturity_revaluation.m` (U5): level-jump equivalence, indexation leakage, foreign holders, geometric-coupon duration, q_g sweep; a full long-bond PRICING equilibrium (Hurtado-Nuno-Thomas style) remains **NOT YET IMPLEMENTED** |
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
| Steady-state vs transition vs aggregate-risk separation | **IMPLEMENTED (labels)** | ALL quantitative results to date are STEADY STATE ONLY; transitions: Dynare RANK block (U6, IMPLEMENTED, run pending) + native-Dynare HANK tier-1 (`dynare/green_hank.mod`, U7, IMPLEMENTED, run pending — linearized IRFs, NOT the nonlinear DTPL P* transition); nonlinear HANK P* transition NOT YET IMPLEMENTED (plan only); aggregate risk NOT YET IMPLEMENTED |
| Exact re-solve at roots, interpolation-residual reporting | **IMPLEMENTED** | |

## 7. Welfare and incidence

| Component | Status | Notes |
|---|---|---|
| Utilitarian steady-state welfare | **IMPLEMENTED** | value function under invariant distribution |
| Consumption-equivalent units | **IMPLEMENTED** | `welfare_by_group.m` (with the sigma>1 validity guard; a sign bug in the transform was found and fixed before any reported numbers) |
| Welfare by wealth/income/bondholding quintile, constrained status, high-MPC proxy, exposure terciles | **IMPLEMENTED** | `welfare_by_group.m` (wealth; run verified) + `welfare_groups_extended.m` (income/bond/constrained/MPC/exposure; run pending via `main_project_channels`) |
| Bondholder levy | **IMPLEMENTED** | one-time L in the decomposition (found NEGATIVE: windfall) |
| Energy-exposure / sector-exposure groups | **NOT YET IMPLEMENTED** | requires energy good / sectors |

## 8. Self-financing decomposition channels (the paper's Eq. nu)

| Channel | Status |
|---|---|
| Nominal debt revaluation | **IMPLEMENTED** (sign found negative at benchmark: green disinflation) |
| Avoided-damage dividend | **IMPLEMENTED** |
| Endogenous safe-asset-demand channel | **IMPLEMENTED and separately reported** | `decompose_safe_asset_channel.m`: exact GE counterfactuals split ln P1 - ln P0 into tax / damage level+incidence / risk / interaction + financing swap (run pending via `main_project_channels`) |
| Output/tax-base expansion | **PARTIALLY IMPLEMENTED** | Stage-1 production layer `production_block_green.m` (Y=(1-D)A(Kg)N) splits nu_taxbase from nu_damage at the AGGREGATE level; STYLIZED (no labor margin, not yet joined to the HA block) |
| Liquidity / convenience yield | **PROPOSED** (requires a convenience-yield wedge or two-asset structure) |
| Debt-maturity / term-structure valuation | **IMPLEMENTED (arithmetic + accommodation-duration bounds, U5)**; full pricing equilibrium NOT YET IMPLEMENTED |
| Distributional transfer/incidence effects | **IMPLEMENTED** (levy incidence + Ginis + group-level welfare by wealth quintile [run verified] and extended groups [run pending]) |

## 9. Empirics

| Component | Status |
|---|---|
| E1 nominal-anchor regression (OLS + HC1, Wald beta=1) | **IMPLEMENTED** (`empirical_anchor.m`; runs on the repo's 34-country OECD file) |
| E2 green-budget denomination panel | **PLACEHOLDER** (schema + loader implemented; data absent by design — never fabricated) |
| E4 World Bank panel (anchor at scale + climate-fiscal descriptives) | **DATA DOWNLOADED** (7,684 country-year rows via the user's MATLAB webread; CO2 fallback code used); `empirical_panel.m` estimates PENDING the user's run |
| E3 revaluation-sign event study | **PROPOSED** (design in the paper, Sec. 6) |
| Sovereign-yield / climate-vulnerability validation | **NOT YET IMPLEMENTED** |

## Verified run record

- Baseline `main_project_run_all` (na=500): 68.4 s / 73.2 s (master rerun);
  unique green steady state P*=0.1897, D=0.0468; nu=0.600 (reval −0.241 +
  damage 0.841); mu*=0.045 interior; no multiplicity for theta_g ≤ 2.5 at
  psi=0; NO equilibrium at mu=0.015 (existence failure, boundary-sign
  verified).
- Extended `main_project_extended` (na=500, via master): completed in
  48.3 s after fixes. X1 (carbon stock, psi=1, mu_ext=0.03): unique
  P*=0.2826, D=0.0709, tau=0.0768. X2 frontier over (psi,Gg) at mu_ext:
  min eps_S ∈ [−0.49, −0.33] — SUNSPOT REGION EMPTY at this calibration;
  at (psi=2, Gg=0.024) NO equilibrium under either regime (fiscal-space
  collapse; Phi>0 at all feasible P). X3: nu=0.659 with reval −0.005
  (ACCOMMODATION NEUTRALITY: near-zero revaluation at the accommodative
  stance); full self-financing threshold theta_g≈1.9. X4/E1: beta=1.004
  (HC1 se 0.257), Wald test of beta=1: p=0.988, n=34.
- Paper placeholders filled from these runs (illustrative-draft pass, U1
  complete). Per standard #10, multiplicity is demoted in the text to a
  sufficient-condition theorem: the calibrated benchmark does NOT generate
  it, and the paper says so.
- Corrected C4 rerun (na=500, 132.1 s) after the CE-transform sign fix:
  incidence now consistent with C3 welfare levels. Under deficit financing
  the program is REGRESSIVE at the steady-state margin: LOW quintiles
  [-3.97..-2.10]%, MEDIUM [-2.96..-1.29]%; HIGH all-quintile GAINS
  [+1.86..+2.41]% with the poorest gaining least. Written into the paper
  (Table "incidence").
- Financing regimes `main_project_regimes` (na=500, 31.3 s): baseline
  P0=0.8246; R1 deficit nu=0.568 (reval -0.060), R2 carbon levy nu=0.668
  (reval +0.033), R3 levy+rebate nu=0.759 (reval +0.119), R4 mixed
  nu=0.620. SIGN of the revaluation channel flips with the financing mix
  (Proposition "financing design"); the rebate design near-Pareto-dominates
  deficit financing (bottom50 +1.23% vs -2.42%, top10 -0.13% vs -1.15%).
  Written into the paper (Table "regimes", Result 5, Proposition 6).
- Calibrated pass `main_project_calibrated` (na=500): completed in 147 s.
  beta* = 0.9296 (bisection to debt/GDP = 1.10, converged); program 2% of
  income (Gg_cal = 0.01818). Self-financing by damage column: LOW (DICE
  0.02) nu = 0.149; MEDIUM (DJO-BHM 0.06) nu = 0.563; HIGH (Bilal-Kaenzig
  0.20) nu = 2.007 (fully self-financing). Revaluation ~ -0.06 in every
  column (green disinflation robust at calibrated scale); HIGH column
  raises steady-state welfare outright (-7.82 -> -7.23). Written into the
  paper as Table "calibrated" with the conditional headline. Section C4
  (welfare incidence by wealth quintile, welfare_by_group.m + PFig8) added
  after this run -- numbers pending the C4 rerun.

- U6 RANK transitions (user machine, Dynare 8-unstable): ALL FOUR regimes
  CONVERGED after the ramp-in redesign. WEAK/TAYLOR/AGGRESSIVE: impact
  inflation -0.04%/-0.52%/-0.24% annualized, peak < +1.6% annualized;
  kg(40q)=0.349 and d: 0.0972->0.0925 IDENTICAL across active regimes
  (monetary-regime independence of the real green path); GREENACCOM
  (large experiment, ~7.2pp annualized initial cut) +22.6% annualized
  impact inflation, same kg, slightly higher damages (0.0933). Recorded
  in appendix/TRANSITION_VALIDATION.md; in the paper as Section
  "Transition diagnostics" + PFig13.
- U7 tier-1 HANK (green_hank.mod): run completed on the user machine,
  PFig14 produced (four regimes); numeric summary
  (hank_irfs_summary.txt / hank_tier1_validation.txt) PENDING
  transcription -- the paper's tier-1 subsection reports figure + scope
  only, no numbers.
