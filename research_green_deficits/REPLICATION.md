# Replication package — *Can Green Deficits Finance Themselves?*

This document is the data-editor-facing guide: software requirements, the
one-command reproduction, per-stage runtimes, and the exact mapping from
every figure and table in the paper to the script that produces it.
The project overview is in `README.md`; the formal model-to-code map is in
`MODEL_AND_THEORY.md`.

## 1. Software requirements

| Component | Requirement | Used for |
|---|---|---|
| MATLAB | R2020a or later recommended (`exportgraphics`; older releases fall back to `print`) | everything in `main_project_*.m` |
| Toolboxes | none (base MATLAB only) | — |
| Dynare | a development build with the heterogeneity framework (`heterogeneity_dimension` / `heterogeneity_solve`) on the MATLAB path | `dynare/run_green_hank`, `dynare/run_green_hank2` only |
| Dynare (stable) | any Dynare 5/6+ | `dynare/run_green_transitions` (RANK) only |
| LaTeX | `pdflatex` + `bibtex` (TeX Live or Overleaf; `placeins` optional — the preamble degrades gracefully) | `paper/green_deficits_price_level.tex` |

No internet access is required for any result in the paper. (The optional
E3 event-study layer, **not used in the paper**, downloads FRED data and
needs an API key; see §6.)

## 2. One-command reproduction

```matlab
cd research_green_deficits
run_green_deficits_master          % full pass, na = 500
% or: FAST = true; run_green_deficits_master   % small grids, ~minutes
```

The master runs every MATLAB stage in dependency order, then the Dynare
stages if Dynare is on the path, records per-stage success/skip reasons,
and writes `output/tables/master_status.txt`. Every stage is independently
re-runnable; failures do not stop the master. Randomness is seeded
(`rng(20260102)`); results are deterministic up to solver tolerances.

After the master, compile the paper:

```bash
cd paper
pdflatex green_deficits_price_level && bibtex green_deficits_price_level
pdflatex green_deficits_price_level && pdflatex green_deficits_price_level
```

`paper/numbers_auto.tex` (machine-written by `export_paper_numbers`, stage
13 of the master) feeds the headline numbers, Table 3, and Table 6, so the
compiled text cannot disagree with the saved results.

## 3. Figure and table map

| Paper object | Producing script | Notes / runtime class |
|---|---|---|
| Figure 1 (mechanism) | TikZ, in the `.tex` | — |
| Figures PFig1–PFig4 (benchmark, sunspots, optimal μ) | `main_project_run_all` | ~30–45 min at `na=500`; `FAST=true` ≈ 5 min |
| PFig5–PFig6 (extended sector) | `main_project_extended` | tens of minutes |
| PFig7, PFig8; Tables 3, 5 | `main_project_calibrated` | tens of minutes |
| PFig9; Table 6 | `main_project_regimes` | tens of minutes |
| PFig10, PFig11 (maturity, q_g) | `main_project_maturity` | minutes |
| PFig15, PFig16 (safe-asset channel, welfare groups) | `main_project_channels` | tens of minutes |
| PFig20 (robustness frontier) | `main_project_robustness` | the longest steady-state stage (≈65 equilibrium solves + sensitivity) |
| PFig19 (aggregate risk, Stage A) | `main_project_aggrisk` | tens of minutes |
| PFig21 (Stage B fiscal/welfare) | `main_project_aggrisk_stageB` | tens of minutes |
| PFig18; transition summary | `main_project_transition` | the heaviest stage: three converged fixed points (nominal, indexed, rebate), hours at `na=500` |
| transition-welfare table | `main_project_transition_welfare` | minutes (one backward pass per design on the saved paths; no fixed-point re-solve) |
| production/tax-base table | `main_project_production` | < 1 s (reads `calibrated_results.mat`) |
| `paper/numbers_auto.tex` | `export_paper_numbers` | < 1 s (reads saved `.mat`s) |
| PFig13 (RANK transitions) | `dynare/run_green_transitions` | minutes; checkpoint-resumed |
| PFig14 (HANK IRFs) | `dynare/run_green_hank` | tens of minutes first run; checkpoint-resumed |
| PFig17; Table 7 (two-asset HANK) | `dynare/run_green_hank2` | **manual, own MATLAB session** (the dev-build heterogeneity solver intermittently hard-crashes the process; the driver is checkpointed and crash-resilient — see its header). Banked results pass its accuracy protocol. |
| style-only figure refresh | `replot_paper_figures` | seconds (re-exports PFig1–4 and PFig18 from saved `.mat`s) |

All figures are exported through `src/save_all_figs.m`, which applies the
common house style (`src/style_figure.m`, `src/finish_panel_legend.m`), so
regenerating any figure reproduces the paper's formatting exactly.

## 4. Outputs and provenance

Everything lands under `output/`: `figures/` (`.pdf`/`.png`/`.fig`),
`tables/*.txt` (one human-readable summary per stage), `*.mat` (full result
structs), `logs/` (per-stage diaries). Each summary file states its own
scope and caveats; numbers in the paper are quotable only from stages whose
summaries mark them converged/`REPORTABLE` — non-converged runs say so
explicitly and are never silently smoothed.

## 5. Checkpoint / resume behavior

The Dynare stages checkpoint after every solved regime
(`output/hank*_green_irfs.mat`, content-hash keyed to the economic content
of the `.mod` files) and resume automatically; `FORCE_RERUN = true`
re-solves. The nonlinear transition saves `output/transition_results.mat`;
`main_project_transition_welfare` and `replot_paper_figures` consume it
without re-solving.

## 6. Optional empirical layer (not used in the paper)

`src_project/download_fred_e3.m` + `main_project_e3.m` implement a daily
event-study/local-projection exercise around green-fiscal announcements.
The paper does not use its output (the identified windows are confounded —
see `output/tables/e3_summary.txt` for the honest negative result). It
requires a free FRED API key, supplied via the `FRED_API_KEY` environment
variable or the git-ignored file `data/.fred_key` — **never commit the
key**.
