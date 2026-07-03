# Empirical validation plan (E1–E5)

*Editorial-roadmap Step 11. Governing principle: the empirical layer
validates MECHANISM SIGNS and CALIBRATIONS; it does not claim causal
identification of green-deficit self-financing, and the paper says so.*

## E1 — Nominal-anchor panel [IMPLEMENTED, run verified]

34-country OECD panel: average CPI inflation on average growth of nominal
government expenditure relative to real GDP. Verified run: slope 1.004
(HC1 s.e. 0.257), Wald test of slope = 1: p = 0.988. HONEST SCOPE
(stated in the paper): validates the broad nominal-anchor correlation
(Lemma "anchor"); it does NOT validate green-deficit self-financing.
Code: `empirical_anchor.m`. Scale-up on the World Bank panel:
`empirical_panel.m` (data downloaded, 7,684 rows; estimates PENDING the
user's run — the last empirical placeholder in the paper).

## E2 — Green-budget denomination panel [PLACEHOLDER: schema only]

The most project-specific empirical object: do REAL-INDEXED green mandates
behave differently from NOMINAL cash appropriations? Maps directly to the
anchor-insulation determinacy result (the paper's rule proposal).

- Registry schema (one row per program): `data/green_budget_panel.csv` —
  header-only; fields country, year, program_name, announced_amount,
  currency, duration_years, nominal_cash_budget, real_indexed_budget,
  gdp_share_commitment, carbon_revenue_financed, debt_financed,
  general_tax_financed, transfer_rebate, legal_mandate,
  discretionary_budget, source_document, source_url, notes.
- Population rule: primary budget documents only; one source URL per row;
  NO fabricated rows (loader skips E2 while empty).
- Candidate seed programs (to be sourced, not assumed): EU Green Deal /
  RRF green tranches, US IRA appropriations, Germany KTF, France 2030,
  UK CCC carbon budgets, national green-bond frameworks.

## E3 — Green fiscal announcement event study [PROPOSED]

Events: EU Green Deal announcements, US IRA passage milestones, major
national climate-investment packages, large sovereign green-bond programs,
major carbon-pricing reforms (incl. Känzig-style carbon-policy surprises).
Outcomes: nominal yields, real yields, breakeven inflation, sovereign
spreads, green-bond spreads (greenium), green/brown equity returns,
exchange rates.
Purpose: discipline whether green fiscal programs are priced as
inflationary, disinflationary, or mainly real-rate/spread events — the
model's revaluation-sign prediction (green disinflation under deficit
finance) is directly testable in breakevens around announcements.
Identification: high-frequency windows around announcement timestamps;
Känzig (2023) surprise series for carbon-pricing events.

## E4 — Sovereign climate-risk validation [DATA DOWNLOADED, estimates pending]

Question: does credible green investment reduce spreads (lower physical
risk) or raise them (higher debt + transition risk)? Discipline from BIS
WP 1275 (Anyfantaki et al. 2025). Current implementation: World Bank
panel (yields proxies, debt/GDP, CO2 intensity, climate-exposure
measures) via `download_data.m` + `empirical_panel.m` (anchor-at-scale +
climate-fiscal descriptives; OLS with HC1). Run pending on the user
machine.

## E5 — Household incidence validation [PROPOSED]

Use energy-price and carbon-pricing shocks to discipline: bottom-half
exposure (psi_inc), rebate effectiveness (the R3 design), energy-
expenditure heterogeneity (needs the U8 energy good), and high-MPC
responses (validates the MPC-proxy groups of
`welfare_groups_extended.m`). Sources: Känzig (2023) carbon-policy
surprises; Fried–Novan–Peterman incidence; energy-shock HANK studies
[verify before citing].

## Status ladder

| layer | status | artifact |
|---|---|---|
| E1 | IMPLEMENTED (verified) | paper Sec. "Empirical evidence"; `empirical_anchor.m` |
| E4 | DATA DOWNLOADED; estimates PENDING user run | `empirical_panel.m`, `data/wb_panel.csv` |
| E2 | PLACEHOLDER (schema only, no data) | `data/green_budget_panel.csv` |
| E3 | PROPOSED (design in paper Sec. "Empirical evidence") | — |
| E5 | PROPOSED | — |
