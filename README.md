# Replication of Hagedorn (2026), "A Demand Theory of the Price Level" (IER)

This package reproduces the **mechanism** of Marcus Hagedorn, "A Demand Theory of
the Price Level," International Economic Review, 2026 (DOI 10.1111/iere.70064),
posthumously submitted by I. Manovskii, handled by D. Krueger.

## Core idea reproduced
In Bewley–Imrohoroglu–Huggett–Aiyagari incomplete-markets models the steady-state
price level is pinned down by **asset-market clearing**:
    S(1+r) = B/P          (Eq. 13/14)
with the real rate pinned by policy through the Fisher relation
    1+r_ss = (1+i_ss)/(1+pi_ss)   (Eq. 17)
and long-run inflation pinned by nominal fiscal policy
    pi_ss = (B'-B)/B = (T'-T)/T   (Eq. 18)
hence
    P* = B / S((1+i_ss)/(1+pi_ss))   (Eq. 22).
In complete markets (1+r_ss)=1/beta is independent of B/P, so P is indeterminate
(Eq. 24, Fig. 2b).

## How to run
Open MATLAB in this folder and run:
    >> main_run_all
It creates output/, figures/ and writes validation_report.txt.

## Requirements
- MATLAB R2018b+ (uses discretize, griddedInterpolant, sparse, fzero).
  exportgraphics (R2020a+) used if present; otherwise print()/saveas() fallback.
- No toolboxes strictly required. Statistics/Optimization toolboxes are NOT needed.
- Dynare is NOT required (the paper is solved with global heterogeneous-agent
  methods; Dynare's perturbation is inappropriate for this object).

## Data (Figure 5 only)
Place a CSV at  data/oecd_inflation_govexp.csv  with columns:
    country, infl, govexp_growth
("infl" = average annual CPI inflation, percent; "govexp_growth" = average annual
growth of nominal government expenditure / real GDP, percent), per the paper's
note (NIPA Table 3.1 lines 21,39,41,42 analogue; OECD CPI all items; 34 OECD
countries). If the file is absent the code generates a CLEARLY LABELLED
illustrative placeholder and prints a warning -- it is NOT the paper's data.

## Outputs
- figures/Figure1..Figure5 (.png/.pdf/.fig)
- output/results.mat
- validation_report.txt (numerical checks + replication status matrix)

## Calibration disclaimer
The paper is theoretical and reports no household calibration. All structural
numbers in parameters_baseline.m are ILLUSTRATIVE benchmark values, explicitly
labelled. The policy example matches the paper's endnote 14. Figures 1-4 are
qualitative in the paper; we reproduce them quantitatively from the computed S(1+r).

## Known limitations
See validation_report.txt and the "Replication status matrix". Money-demand and
some present-value-identity demonstrations are implemented at the steady-state-
equation level with documented approximations (separable MIU).

## Data (Figure 5) — downloaded live from the internet
Figure 5 data are fetched automatically from the **World Bank WDI REST API**
(`load_oecd_data.m`) for the 34 OECD countries in the paper's endnote 33:
- Inflation, consumer prices (annual %): `FP.CPI.TOTL.ZG`
- General government final consumption expenditure, current LCU: `NE.CON.GOVT.CN`
- GDP, constant LCU (real): `NY.GDP.MKTP.KN`

The code computes, per country: average CPI inflation, and the average annual
growth of (nominal government expenditure / real GDP). Results are cached to
`data/oecd_inflation_govexp.csv` and reused offline on later runs.

Requirements: an internet connection on first run; `webread` (base MATLAB).
To force offline use, set `par.use_web_data = false` in `parameters_baseline.m`.

PROXY CAVEAT: the World Bank government measure (final consumption) is **not**
the paper's exact NIPA Table 3.1 construction (final consumption GP3P + gross
capital formation GP5_K2P − consumption of fixed capital GK1R). It is a
reproducible web proxy, clearly labelled in the figure title, the source
footnote, and `validation_report.txt`. The computed correlation may therefore
differ from the paper's 0.93. To match the paper exactly, drop a CSV with
columns `country, infl, govexp_growth` at `data/oecd_inflation_govexp.csv` and
set `par.use_web_data = false`.