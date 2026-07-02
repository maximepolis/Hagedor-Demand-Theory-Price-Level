# Replication notes — Hagedorn (2026), "A Demand Theory of the Price Level"

This document details the modeling and numerical choices behind the replication.
It follows the required section outline.

---

## 1. Paper mechanism

The paper develops a **Demand Theory of the Price Level (DTPL)**. In a
Bewley–Huggett incomplete-markets economy with uninsurable idiosyncratic income
risk, households have a **precautionary demand for safe (nominal) government
bonds**. For each feasible real interest rate `r`, the household block delivers a
**finite aggregate real asset demand** `S(1+r)`.

- **Monetary policy** sets the nominal interest rate `i^ss`.
- **Fiscal policy** sets the growth rate of nominal debt (or nominal demand),
  which determines steady-state inflation `pi^ss = B_{t+1}/B_t - 1`.
- The **Fisher relation** `1+r^ss = (1+i^ss)/(1+pi^ss)` then pins the real rate.
- Given nominal government liabilities `B`, **asset-market clearing** requires
  the real bond supply `B/P` to equal household asset demand `S(1+r^ss)`. The
  **price level** is the variable that clears this market:

  ```
  S(1+r^ss) = B / P*     =>     P* = B / S(1+r^ss).
  ```

This is a genuinely **demand-side** determination of the price level: the price
level adjusts so real asset supply equals private asset demand. It is **not** the
Fiscal Theory of the Price Level (FTPL): fiscal policy here is **passive**
(Ricardian) and merely satisfies the government budget constraint through tax
adjustment; the price level is selected by asset-market clearing, not by a
present-value fiscal condition under active fiscal policy.

In **complete markets / representative agent** the real rate is pinned by the
household Euler equation at `1+r = 1/beta`, independent of the real quantity of
bonds. Asset-market clearing becomes redundant (Ricardian equivalence), and the
price level is **indeterminate** absent an active (FTPL-type) fiscal rule.

**Important theoretical point (as stressed by the paper):** the determinacy
result does **not** require the asset-demand curve to be globally upward sloping.
For nominal debt-growth rules, uniqueness of `P*` follows because monetary and
fiscal policy pin down the real interest rate, and asset demand is a *function*
evaluated at that single real rate. Monotonicity of `S(1+r)` is visually useful
but is **not essential** for the baseline determinacy result. (The code reports
the local slope `dS/dr` as a diagnostic only.)

---

## 2. What is exactly replicated (from the paper)

- The **household problem** (CRRA preferences, budget
  `c + a' = (1+r)a + e - tau`, borrowing limit `a' >= -abar`, finite-state
  Markov endowment normalized to unit mean).
- The **stationary equilibrium** and aggregate asset demand
  `S = ∫ a dΩ`.
- The **baseline DTPL determination** `P* = B / S(1+r^ss)` with
  `1+r^ss = (1+i^ss)/(1+pi^ss)` and inflation equal to nominal debt growth.
- The **existence conditions** (`S>0`, finite, `beta(1+r^ss)<1`).
- The **complete-markets indeterminacy** result (`1+r=1/beta`, redundant
  asset-market clearing, Ricardian equivalence).
- The **nominal tax rule** `T = ω1 i B + ω2 B` ⇒
  `1+pi^ss = (1-ω1) i^ss + (1-ω2)` and its special cases in `ω1`.
- The **real tax rule** `tau = tau* + γ(r b − tau*)` ⇒
  `1+pi^ss = 1+i^ss − (P/B) tau*`, with the price level solving
  `S((1+i^ss)/(1+pi(P))) = B/P` and the possibility of non-uniqueness.
- The **capital extension** structure: `F_K + 1 − δ = 1+r^ss` pins `K^*`;
  asset-market clearing `K^* + B/P^* = S(1+r^ss)` still pins `P^*`.
- The **money extension** logic: with the CB setting `i`, money `M` is
  endogenous; money-market clearing alone does not pin `P`, asset-market clearing
  does.
- The **nominal-government-expenditure** logic: nominal `G` determines `P`
  through an aggregate-demand channel via `S(1+r, G/P)`.
- The **DTPL ≠ FTPL** distinction.

---

## 3. What is numerically illustrated (replicator's choices)

- The paper does **not** provide a full empirical calibration; the numbers in
  `setup_params.m` are a **benchmark chosen by the replicator** to make the
  mechanism visible, not calibrated moments from the paper.
- The **income process** (AR(1) with `rho=0.90`, `sig_eps=0.20`, 7 states via
  Rouwenhorst) is a standard illustrative choice.
- The **money-demand system** is a *simplified separable* steady-state schedule
  derived from the bond/money first-order conditions and evaluated at aggregate
  consumption, rather than a full two-asset distributional solve. This preserves
  the paper's logic (endogenous `M`, asset market pins `P`) at low cost.
- The **capital extension** uses a consolidated tax that finances the real
  interest on government bonds only, `tau = r(S − K^*)`; production is
  Cobb-Douglas `Y = K^alpha` with `alpha=0.36`, `delta=0.08` (illustrative).
- The **FTPL price** uses a constant-surplus present value `B/P = s/r`; the
  surplus `s` defaults to the DTPL steady-state tax for a like-for-like contrast.
- The **schematic figures** reproduce the paper's *qualitative* geometry; exact
  curve shapes depend on the benchmark calibration.
- For the real tax rule, the shipped calibration produces a **unique** root in
  each panel of Figure 3 given the monotone sign structure of the benchmark; the
  solver is nevertheless **multi-root capable** (it scans for all sign changes
  and refines each with `fzero`) so genuine multiplicity is detected whenever a
  calibration produces it. This is flagged, not hidden.

---

## 4. Calibration choices

| Parameter | Value | Meaning |
|-----------|-------|---------|
| frequency | annual | stated benchmark frequency |
| `beta` | 0.96 | discount factor (asymptote `1/beta−1 ≈ 0.0417`) |
| `sigma` | 2.0 | CRRA coefficient |
| `abar` | 0.0 | borrowing limit (`a' >= 0`) |
| `na`, `amax`, `acurv` | 500, 60, 2.5 | asset grid (dense near constraint) |
| `ne`, `rho`, `sig_eps` | 7, 0.90, 0.20 | income process (mean-normalized) |
| `Bnom` | 1.0 | nominal debt |
| `i_ss` | 0.04 | nominal rate |
| `pi_ss` | 0.02 | inflation = nominal debt growth |
| ⇒ `r_ss` | ≈0.0196 | real rate (safely below `1/beta−1`) |

Extensions add `alpha=0.36, delta=0.08` (capital), `chi=0.05, eta=2` (money),
`Gnom=0.20, Breal=1.0` (nominal G). All are illustrative.

---

## 5. Algorithmic details

- **Household solver (canonical): value function iteration** on a fixed asset
  grid (`solve_household_vfi`). Feasible consumption is computed for *every*
  candidate `a'`; infeasible choices get `-Inf` utility, so correctness does not
  rely on monotonicity. Convergence: sup-norm `< tol_vfi = 1e-8` with an
  iteration guard; **Howard (modified policy) iteration** accelerates it.
- **Household solver (optional): EGM** (`solve_household_egm`) as a speed
  alternative; continuous policy is snapped to grid nodes for the index-based
  distribution. VFI remains canonical.
- **Stationary distribution** (`stationary_distribution`): the exact invariant
  distribution of the joint `(a,e)` Markov chain by power iteration on a sparse
  transition matrix (`tol_dist = 1e-12`). **No Monte-Carlo simulation.**
- **Asset demand** (`aggregate_asset_demand`): outer fixed point over
  `(tau, S)` with `tau = r S` and damping `lambda_S = 0.5`, `tol_S = 1e-8`.
  Accepts scalar or vector `r`. Refuses `beta(1+r) >= betaR_max` and flags
  divergence rather than crashing.
- **Price-level root finding** (real tax rule, nominal G): scan a positive
  `P`-grid for sign changes, then refine each bracket with `fzero`
  (`tol_root = 1e-8`). All roots are returned. A precomputed `S(r)` (or
  `S(tau)`) interpolant avoids re-solving the household problem at every trial
  `P`.
- **Euler residuals**: `1 − beta(1+r) E[u'(c')]/u'(c)` reported as `log10`
  absolute errors over unconstrained states; constrained states are separated.
- **Reproducibility**: `main_run_all` sets `rng(20260101,'twister')`. The
  stationary distribution is deterministic (no simulation), so results are
  reproducible up to floating point.

---

## 6. Known limitations

- The **money extension** uses an aggregate (representative-consumption)
  money-demand schedule, not a full two-asset heterogeneous-agent solve.
- The **capital extension** consolidates the fiscal-financing side; it is a
  demonstration that determinacy survives, not a calibrated production economy.
- Figures reproduce the paper's **qualitative** geometry; the paper's exact
  figures depend on its (theoretical) parameterization.
- The **FTPL** block is intentionally minimal (constant-surplus present value),
  included only for contrast — it is **not** the paper's theory.
- With `abar = 0` and precautionary savings, aggregate assets are strictly
  positive, so a literal **zero-net-supply** bond experiment is discussed but not
  forced to a knife-edge root.
- No empirical calibration is claimed; Figure 5 runs only if a data file exists.

---

## 7. How to run

```matlab
>> main_run_all           % full run (na = 500)
```

For a quick check:

```matlab
>> FAST = true; main_run_all      % na = 100
```

Standalone sections (each builds `params` if absent):

```matlab
>> main_baseline_DTPL
>> main_figures
>> main_policy_rules
>> main_extensions_money_capital_G
>> main_counterexamples
>> main_empirical_figure5_optional
```

---

## 8. Output files

- `output/figures/Figure1_asset_market.{fig,png,pdf}` — asset market.
- `output/figures/Figure2_determinacy.{fig,png,pdf}` — determinacy vs
  indeterminacy.
- `output/figures/Figure3_real_tax_rule.{fig,png,pdf}` — real tax rule.
- `output/figures/Figure4_nominal_G.{fig,png,pdf}` — nominal government
  expenditure.
- `output/figures/Figure5_inflation_vs_G.{fig,png,pdf}` — empirical (if data).
- `output/tables/baseline_summary.txt` — baseline steady-state values.
- `output/logs/run_log.txt` — full console log (diary).
- `output/results.mat` — the `RES` results struct and `params`.

---

## 9. Interpretation of each figure

- **Figure 1 — Asset market.** (a) The upward-sloping heterogeneous-agent asset
  demand `S(1+r)` and the real bond supply `B/P^*`; their intersection is the
  steady state. (b) For different hypothetical price levels `P1,P2,P3`, the real
  supplies `B/P_j` cut the demand curve at different real rates — showing that a
  policy block (Fisher relation) is needed to select `r^ss` and hence `P^*`.
- **Figure 2 — Determinacy vs indeterminacy.** (a) Incomplete markets: once
  policy fixes `r^ss`, there is a single `S` and a unique `P* = B/S(1+r^ss)`.
  (b) Complete markets: the asset-demand "curve" is vertical at `1+r = 1/beta`,
  so any `B/P` is admissible — the price level is indeterminate.
- **Figure 3 — Real tax rule.** The market-clearing residual `F(P) = S(r(P)) −
  B/P` versus `P`, where inflation (hence `r`) depends on `P`. Zero crossings are
  equilibrium price levels: one panel with a unique equilibrium, one where
  multiplicity can arise (the solver returns all roots found).
- **Figure 4 — Nominal government expenditure.** Market-clearing residuals for
  (a) real bonds `S(1+r, G/P) = B^{real}` and (b) nominal bonds plus nominal
  spending `S(1+r, G/P) = B/P`. Nominal `G` can determine `P` through the
  aggregate-demand channel even when bonds are real.
- **Figure 5 — Empirical (optional).** Cross-country scatter of average CPI
  inflation against average growth of nominal government expenditure / real GDP,
  with the 45-degree line, an OLS fit, and the cross-country correlation. Runs
  only if a usable data file is supplied.
