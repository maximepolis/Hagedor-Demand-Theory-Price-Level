# Calibration appendix (plan + current status)

*Every parameter, its current value, its status, and the data source or
target moment that will discipline it. Rule 9 of the project standards:
illustrative values are never presented as calibrated results. Status:
**CALIBRATED** (mapped to a target), **INHERITED** (from the replication
benchmark, standard values), **ILLUSTRATIVE** (authors' choice, to be
replaced), **DERIVED** (implied by other parameters).*

## Household block

| Param | Value | Status | Discipline plan |
|---|---|---|---|
| beta | 0.96 | INHERITED | re-target to clear the asset market at an empirical safe real rate given debt/GDP (Aiyagari–McGrattan-style) |
| sigma | 2 | INHERITED | standard range 1–3; robustness at 1 and 3 |
| rho, sig_eps0 | 0.90, 0.20 | INHERITED | re-estimate to earnings-panel moments; target wealth Gini and top-10% share (currently outputs, not targets) |
| abar | 0 | INHERITED | robustness with positive borrowing limit |
| na, ne | 500, 7 | numerical | convergence checks vs 1000, 11 |

## Government / monetary

| Param | Value | Status | Discipline plan |
|---|---|---|---|
| Bnom | 1.0 | normalization | scale reported as B/(P·Y): benchmark implies b/Y ≈ 5.3 at mu=0.02 — HIGH relative to data; recalibrate beta/B jointly to debt/GDP ≈ 1.0–1.2 (OECD) |
| i_ss | 0.04 | ILLUSTRATIVE | average nominal policy/10y rate for the sample |
| mu | 0.02 | ILLUSTRATIVE | inflation-target anchor (2%) |
| mu_ext | 0.03 | derived from run | evaluation stance near measured mu* |
| maturity | 1 period | MISSING | geometric-coupon duration to average OECD debt duration (~5–7y) — roadmap U5 |

## Green program

| Param | Value | Status | Discipline plan |
|---|---|---|---|
| Gg_nom | 0.012 (g_g ≈ 5–6% of mean endowment) | ILLUSTRATIVE | IEA Net Zero / IMF / NGFS public green-investment paths: ~1–2.5% of GDP public share; benchmark is deliberately LARGE — rescale and report both |
| delta_g | 0.10 | ILLUSTRATIVE | infrastructure depreciation 4–8%; robustness |

## Climate block (version 1 / version 2)

| Param | Value | Status | Discipline plan |
|---|---|---|---|
| D0 / D(0) | 0.10 / 0.0991 | ILLUSTRATIVE | LOW: DICE/Nordhaus damage at relevant warming (~1–3% GDP): D0=0.02; MEDIUM: Dell–Jones–Olken / Burke–Hsiang–Miguel: D0=0.05–0.10; HIGH: Bilal–Känzig: D0=0.20+. Report all three columns |
| theta_g | 1.2 (sweep 0–2.5) | ILLUSTRATIVE | map from abatement-cost curves (IEA/IAM marginal abatement costs) to damage reduction per unit of public green capital; nu(theta_g) already reported as a function, so re-reading the figure under the calibrated theta_g is immediate |
| Dmax, eps0, delta_x, gamma_x, alpha_A | 0.25, 1, 0.05, 0.028, 0.9 | ILLUSTRATIVE | delta_x from carbon-cycle half-life; gamma_x jointly with Dmax to hit the LOW/MED/HIGH D(0) targets; alpha_A = max abatable share from sectoral emissions data |
| phi_D | 0.5 | ILLUSTRATIVE | disperse: climate-driven income-risk estimates are scarce; report phi_D ∈ {0, 0.5, 1} |
| psi (incidence) | 0 baseline; sweep {0,1,2} | ILLUSTRATIVE | Känzig (2023): consumption response of bottom-quartile vs top-quartile to carbon shocks → implied exposure ratio → psi. Fried–Novan–Peterman as cross-check |

## Empirics

| Object | Status | Source |
|---|---|---|
| E1 anchor panel | IN REPO | 34 OECD countries (root `data/`) |
| E2 green-budget panel | ABSENT (schema specified) | IMF GFS/COFOG 05 + budget-law indexation classification |
| E3 event study | DESIGN ONLY | EU ETS/Green Deal, IRA announcement windows; Känzig-style shocks |

## Calibrated-pass results (U3 EXECUTED — verified run, na=500, 147 s)

- **beta\* = 0.9296** (bisection converged: S = 1.1033 vs target 1.10) —
  status of beta upgraded to **CALIBRATED** (target: debt/GDP = 1.10).
- **Gg_cal = 0.01818** (2.0% of mean income at P0_med = 0.9091) — program
  scale **CALIBRATED** to net-zero public-investment paths.
- Damage columns (all unique equilibria):

| Column | D0 | nu | reval | damage | full financing at theta_g | W0 → W1 |
|---|---|---|---|---|---|---|
| LOW (DICE) | 0.02 | 0.149 | −0.060 | 0.210 | never (0.32 at 2.5) | −3.22 → −3.72 |
| MEDIUM (DJO–BHM) | 0.06 | 0.563 | −0.064 | 0.628 | ≈ 2.35 | −4.09 → −4.42 |
| HIGH (Bilal–Känzig) | 0.20 | **2.007** | −0.068 | 2.076 | ≈ 0.57 | −7.82 → **−7.23** |

- Green disinflation robust at calibrated scale: reval ≈ −0.06 and a
  bondholder windfall of 7–9% of annual mean income in every column; the
  HIGH column raises steady-state welfare outright.

## Calibrated-pass machinery (U3) — implemented, awaiting run

`main_project_calibrated.m` executes the three re-targets:

- **C1** `calibrate_beta.m`: bisection on beta so no-program real debt hits
  **debt/GDP = 1.10** (OECD general government) at the policy real rate,
  evaluated at the medium damage column. Replaces illustrative beta = 0.96.
- **C2** program scale: nominal green budget set so real green spending is
  **2.0% of mean income** at the calibrated no-program price level
  (public share of net-zero investment paths, IEA/IMF/NGFS).
- **C3** damage columns: **LOW D0 = 0.02** (DICE/Nordhaus), **MEDIUM
  D0 = 0.06** (Dell–Jones–Olken / Burke–Hsiang–Miguel), **HIGH D0 = 0.20**
  (Bilal–Känzig). Per-column nu decomposition, PFig7, and
  `output/tables/calibrated_summary.txt`.

Remaining ILLUSTRATIVE after this pass: theta_g and delta_g (await the
abatement-cost mapping), phi_D and psi (await climate-risk and incidence
estimates), i_ss and mu (anchored to a 4%/2% convention rather than
estimated). These are reported as sweeps, not point claims.

## Known calibration tensions (to resolve, not hide)

1. **Debt scale**: b/Y ≈ 5 at the benchmark (B=1 against mean income 1 with
   P*≈0.19–0.22). The model's S is calibrated by beta and risk, so hitting
   debt/GDP ≈ 1 requires joint (beta, B, risk) re-targeting; the qualitative
   mechanism does not depend on the scale, but magnitudes of nu do.
2. **Program scale**: real green spending ≈ 5–6% of income is 2–5x the
   public share of net-zero investment paths; the headline nu must be
   re-reported at ~1.5–2% scale.
3. **r vs asymptote**: with beta=0.96, the computable real-rate window is
   narrow; recalibrating beta upward (e.g. 0.98 annual) widens it and is the
   natural companion of fixing tension 1.

## Full parameter register (editorial-roadmap Step 6)

*One row per parameter: value → source/target → status → sensitivity range
→ where in code → which outputs depend on it. Statuses as in the header;
"swept" = reported over a range, never as a point estimate.*

| Parameter | Value | Source / target | Status | Sensitivity range | Code location | Dependent outputs |
|---|---|---|---|---|---|---|
| beta* | 0.9296 | debt/annual-GDP = 1.10 (OECD central) | **CALIBRATED** (bisection, verified run) | re-target 0.9–1.3 debt/GDP | `calibrate_beta.m` | all calibrated tables, PFig7–9, 15–16 |
| Gg_cal | 0.01818 | program = 2% of income (IEA/NGFS-scale flow) | **CALIBRATED** (scale mapping) | 1–4% of income | `main_project_calibrated.m` | nu columns, regimes, channels |
| D0 LOW/MED/HIGH | 0.02 / 0.06 / 0.20 | DICE (Nordhaus 2017) / DJO+BHM / Bilal–Känzig | **EXTERNALLY DISCIPLINED** (three columns, never averaged) | column design | `main_project_calibrated.m` | Table "calibrated", incidence table |
| theta_g | 1.2 | NOT yet mapped | **ILLUSTRATIVE — swept** | full-self-financing threshold at ≈1.9 reported | `climate_block.m` | nu, frontier | 
| q_g | 1.0 | implementation efficiency; Climate-PIMA evidence pending | **ILLUSTRATIVE — swept** (1 / 0.8 / 0.6: nu = 0.563/0.449/0.329) | 0.5–1 | `climate_block*.m` | maturity table, PFig11 |
| phi_D | (setup value) | climate-induced idiosyncratic risk; no direct estimate located | **ILLUSTRATIVE — swept** | 0 (off) to 2× | `S_green.m` risk rebuild | risk channel of PFig15 |
| psi_inc | 0 (benchmark) / >0 (extended) | Känzig incidence gradient (to map) | **ILLUSTRATIVE — swept** | 0–2 | `S_green.m` chi(e) | sunspot frontier, exposure terciles |
| i_ss | 0.04 | policy-regime parameter (nominal anchor) | **ILLUSTRATIVE / policy-regime** | 0.02–0.06 | `setup_params_green.m` | r_cal, all steady states |
| mu | 0.02 | inflation-target anchor | **ILLUSTRATIVE / policy-regime** | W(mu) grid 0.015–0.06 | `setup_params_green.m` | P*, accommodation exercise |
| sigma | 2 | standard | **INHERITED** | 1–3 | `setup_params_green.m` | welfare transforms |
| rho, sig_eps0 | 0.90, 0.20 | earnings-panel standards | **INHERITED** (wealth moments are outputs, not targets — stated) | re-estimate | `make_income_process` | S, Ginis |
| alpha_I, alpha_F | swept | indexation share, foreign-holder share (Hilscher et al.) | **swept** | 0–1 | `debt_maturity_revaluation.m` | maturity table |
| delta_m / duration | 1y/5y/10y | OECD average debt duration | **swept** | 1–10y | `debt_maturity_revaluation.m` | duration rows |
| aY, thA | 0.20, 0.8 | Bom–Ligthart output elasticity (eta_Y printed as check) | **ILLUSTRATIVE — checkable** | eta_Y 0.08–0.12 | `production_block_green.m` | Stage-1 tax-base split |
| taxbase_rate | 0.30 | average effective tax take | **ILLUSTRATIVE** | 0.2–0.4 | `production_block_green.m` | nu_taxbase |
| na, ne, Pspan | 500, 7, [0.5,1.3] | numerics | numerical | na=1000 check | `setup_params_green.m` | all |
| Dynare RANK block | see .mod | quarterly NK standards (kappa_r=100, eps_p=6, phi_b=0.10) | **ILLUSTRATIVE** (diagnostics tier) | regime sweep IS the sensitivity | `green_rank_nk.mod` | PFig13, validation table |
| Dynare HANK block | see .mod | example-calibration income process (3-state); B=3.96 targets debt/GDP 1.10 | **ILLUSTRATIVE** (tier-1; alignment with 7-state process is future work — stated in the validation file) | — | `green_hank.mod` | PFig14, validation table |

### Critical remaining calibration tasks (unchanged priorities)

1. theta_g ← abatement-cost / public-investment-effectiveness evidence
   (IEA marginal abatement curves); until then swept with the ≈1.9
   threshold always reported alongside.
2. q_g ← Climate-PIMA / public-investment-management efficiency evidence.
3. phi_D ← climate-induced idiosyncratic income-risk estimates, or remain
   transparently swept (it now has its own isolated channel in PFig15).
4. psi_inc ← Känzig-style carbon/energy incidence gradients.
5. mu, i_ss ← sample-anchored nominal targets, or presented as
   policy-regime parameters (current treatment).
