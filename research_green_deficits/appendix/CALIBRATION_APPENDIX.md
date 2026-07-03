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
