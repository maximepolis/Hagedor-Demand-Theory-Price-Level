# Replication package — Hagedorn (2026), "A Demand Theory of the Price Level" (IER)

MATLAB replication of the **mechanism, comparative statics, and schematic
figures** of Marcus Hagedorn, *A Demand Theory of the Price Level*,
International Economic Review, 2026.

The paper is primarily **theoretical**. This package therefore implements a
transparent *benchmark* incomplete-markets economy that reproduces the paper's
logic, and it clearly separates **what is exactly implemented from the paper**
from **what is a numerical illustration chosen by the replicator** (see
`REPLICATION_NOTES.md`).

## The core result

In a Huggett-style heterogeneous-agent incomplete-markets endowment economy with
uninsurable idiosyncratic income risk and nominal government bonds, the
steady-state price level is pinned down by **asset-market clearing**:

```
S(1+r^ss) = B / P*            =>   P* = B / S(1+r^ss)
1 + r^ss  = (1+i^ss)/(1+pi^ss)      (Fisher; monetary + fiscal policy)
1 + pi^ss = B_{t+1}/B_t              (nominal debt growth = inflation)
```

- **Monetary policy** sets the nominal rate `i^ss`.
- **Fiscal policy** sets nominal debt growth, hence steady-state inflation `pi^ss`.
- Together they pin the **real rate** `r^ss`, at which the heterogeneous-agent
  block delivers a **finite** aggregate real asset demand `S(1+r^ss)`.
- Given nominal liabilities `B`, the **price level** adjusts so real bond supply
  `B/P` equals asset demand. This yields a **unique finite** `P*`.

In **complete markets / representative agent** the real rate is pinned by
preferences (`1+r = 1/beta`) independent of `B/P`, asset-market clearing is
redundant (Ricardian equivalence), and the price level is **indeterminate**.

## Research project built on this package

`research_green_deficits/` contains a standalone research project — *"Can Green
Deficits Finance Themselves? Climate Investment, Asset Demand, and
Self-Fulfilling Price Levels in Incomplete-Markets Economies"* — that combines
this paper's DTPL mechanism with Angeletos-Lian-Wolf (self-financing deficits),
Acharya-Challe-Dogra (optimal monetary policy in HANK) and Acharya-Benhabib
(self-fulfilling fluctuations in HANK), plus a climate block. See
`research_green_deficits/README.md`; run `research_green_deficits/main_project_run_all.m`.

## Folder structure

```
main_run_all.m                     orchestrator (clear, seed, paths, run, save, summary)
main_baseline_DTPL.m               baseline steady state + checks
main_figures.m                     Figures 1-2
main_policy_rules.m                nominal & real tax rules + Figure 3
main_extensions_money_capital_G.m  capital, money, nominal-G + Figure 4
main_counterexamples.m             complete-markets, hand-to-mouth, FTPL contrast
main_empirical_figure5_optional.m  Figure 5 (only if data provided)
src/                               all model + numerical + plotting modules
output/figures/                    Figure{1..5}.{fig,png,pdf}
output/tables/                     summary tables
output/logs/                       run_log.txt (diary)
data/                              optional OECD CSV for Figure 5
REPLICATION_NOTES.md               detailed notes
```

## How to run

Open MATLAB in this folder and run:

```matlab
>> main_run_all
```

This clears the workspace, sets the seed, adds `src/` to the path, runs all
sections, writes figures/tables/logs to `output/`, saves `output/results.mat`,
and prints a concise replication summary. For a quick smoke test set
`FAST = true;` in the workspace before running (uses `na = 100`).

Each `main_*.m` section can also be run standalone (it creates `params` if
needed).

## Requirements

- **MATLAB R2018b+**. No toolboxes are required. `exportgraphics` (R2020a+) is
  used for figures if present, otherwise `print`/`saveas` is used as a fallback.
- **Dynare is not used**: the central object is a *global* heterogeneous-agent
  steady-state asset-demand function, not a perturbation solution.

## Data (Figure 5 only)

Figure 5 is optional. Place a CSV at `data/oecd_inflation_govexp.csv`. Two
layouts are supported (see `src/load_oecd_data.m`):

- **Pre-aggregated**: `country, infl, govexp_growth` (percent, already averaged).
- **Raw panel**: `country, year, cpi, real_gdp` plus either `gov_exp_nominal`
  or the paper's components `final_consumption, gross_capital_formation,
  acquisitions_less_disposals, consumption_fixed_capital`.

If no usable data file is present, the script prints a message and **skips**
Figure 5. No OECD data are fabricated.

## Core function signatures

```matlab
params = setup_params();
[eGrid, Pi, stationary_e] = make_income_process(params);
[V, polA_idx, polA, polC, hhdiag] = solve_household_vfi(r, tau, params);
[dist, distdiag] = stationary_distribution(polA_idx, Pi, params);
[S, out] = aggregate_asset_demand(r, params);
[ss, out] = solve_steady_state_DTPL(params, i_ss, pi_ss, B);
[ss, out] = solve_nominal_tax_rule(params, omega1, omega2, i_ss, B);
[roots, out] = solve_real_tax_rule(params, tau_star, gamma, i_ss, B);
out = solve_complete_markets_counterexample(params);
out = solve_hand_to_mouth_counterexample(params);
out = solve_capital_extension(params);
out = solve_money_extension(params);
out = solve_nominal_G_extension(params);
checks(ss, out, params);
```
