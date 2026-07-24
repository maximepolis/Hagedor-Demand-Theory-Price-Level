# Two-asset DTPL model: build plan and scoping

The referee's decisive request is a nonlinear portfolio model in which the
nominal government liability and illiquid real wealth clear in *separate*
markets, so that the reported price-level magnitudes become computed objects
rather than one-asset benchmarks. This file scopes that build honestly,
including the aggregation question the earlier "EGM unchanged" description
glossed over.

## 1. Why the one-asset model is inadequate for magnitudes (not for the theorem)

The incidence theorem and the financing-incidence proposition are statements
about the demand schedule for the nominal liability, $S_b(1+r;\cdot)$. They
survive in a richer portfolio environment after replacing total saving with
nominal-bond demand. What does **not** survive is the *magnitude* of
$d\ln P$: with one asset, a unit shift in desired saving revalues the entire
nominal debt one-for-one, so the price-level response is scaled by the whole
wealth-to-debt ratio. With a separate illiquid asset, part of any saving
shift is absorbed by the real asset (its price/quantity adjusting), and only
the portion landing on nominal claims moves $P$. The one-asset number is
therefore an upper bound whose tightness depends on an uncalibrated
substitution margin — exactly the object a two-asset model computes.

## 2. The aggregation question (the part the earlier note got wrong)

A single "total-wealth" state is sufficient **only** under restrictive
conditions: frictionless static portfolio choice each period, known separable
returns, a liquidity service depending only on the contemporaneous choice, no
illiquid adjustment friction, and homogeneous participation. That version
cannot reproduce wealthy hand-to-mouth households or heterogeneous bond
ownership — precisely the heterogeneity the incidence mechanism runs through.
So we do **not** assume one-dimensional aggregation. The plan is:

- **Step 0 (aggregation test).** Solve the frictionless static-portfolio
  version first and check whether the portfolio share is degenerate/interior
  and whether a one-dimensional total-wealth recursion reproduces the
  two-state solution on a coarse grid. If it does, keep it as the transparent
  benchmark. If not (the likely outcome once $v(b)$ is non-trivial), move to
  the two-state model below. Either way, the aggregation claim is a *result*,
  not an assumption.

## 3. Minimal sufficient model

Household state $s_i = (e_i, b_i, k_i)$: idiosyncratic income $e_i$, liquid
nominal bonds $b_i$, illiquid real claims $k_i$ (a Lucas tree / real capital).

- **Preferences.** Standard CRRA over consumption plus a liquidity term
  $v(b_i)$ (Krishnamurthy–Vissing-Jørgensen convenience yield); $v'>0$,
  $v''<0$ pins an interior nominal share and an elastic convenience yield.
- **Assets.** Liquid bonds pay the nominal rate deflated by realized
  inflation; the illiquid asset pays a real dividend and trades at price $q$.
  Two variants for the illiquid margin:
  - (a) **Continuously adjustable $k$** (frictionless two-asset): both
    choices interior each period; heavier state but no adjustment logic.
  - (b) **Infrequent adjustment** (Kaplan–Violante style): $b$ adjustable
    every period, $k$ adjustable with probability $\lambda$ or a fixed cost;
    this is what generates wealthy hand-to-mouth agents and realistic bond
    ownership. Recommended if Step 0 rejects one-dimensional aggregation and
    the wealth-concentration/HtM moments matter.
- **Market clearing (two conditions).** $\int b_i\,\dd\Omega = B/P$ (nominal
  debt) pins $P$; $\int k_i\,\dd\Omega = K$ (real asset supply) pins $q$. The
  reform moves both; the price-level response is now the *nominal-market*
  piece only.

## 4. Solution method (honest version)

- Variant (a): endogenous-grid or root-finding over two continuous choices;
  the household problem is 3-dimensional in the state. EGM extends but is
  **not** "unchanged" — it must handle the portfolio first-order condition
  jointly with the consumption Euler equation.
- Variant (b): the two-asset EGM/adjustment machinery of the HANK literature
  (Auclert et al. sequence-space, or Bayer–Luetticke). Nonlinear steady state
  by iterating $(P,q)$ on the two clearing conditions; transition by the same
  sequence-space Newton method already used here, now on a two-price path.

## 5. What the build validates (deliverables)

1. **The $d\ln P$-vs-$\zeta$ figure** the DTPL literature lacks: the price-level
   response as a function of the convenience-yield elasticity $\zeta$, spanning
   the one-asset upper bound (rigid share) and the elastic-share interior.
2. **Which signs, orderings, and magnitudes survive** — reported as computed
   outcomes, not assumed. In particular whether the lump-sum-vs-levy sign
   contrast and the front-loading survive an elastic nominal share.
3. A recalibration to **liquid public liabilities** (not total wealth) as the
   clearing object, which is the correct target once the two assets separate.

## 6. Cost and sequencing

- Step 0 (aggregation test) + variant (a) steady state: ~1 week.
- Variant (b) with infrequent adjustment + nonlinear transition: ~3–4 weeks.
- Total to a portfolio-validated magnitude: **3–5 weeks** of build + your runs.

Recommended order: Step 0 first (it may cheaply justify the benchmark), then
variant (a) for the $d\ln P$-vs-$\zeta$ figure, then variant (b) only if the
HtM/participation moments are needed for the magnitude. No result is described
as portfolio-validated until the two markets clear separately.

## 7. Interim position (in the paper now)

Until this is built, the paper claims the mechanism exactly and the magnitudes
as one-asset benchmarks (Position B). The build converts the benchmark
magnitudes into predictions and retires the abstract's weakest caveat; it does
not change the incidence theorem or the financing-incidence proposition.

## 8. Stage 2 (post-first-results): the HANK upgrade path

The first computed results (Step 0 + variant (b)) and the internal round-4
report (REFEREE_REPORT_INTERNAL_R4.md) define the upgrade order:

1. **Two-asset welfare incidence by decile** (R1, ~1 week). CE-transfer
   incidence by wealth group in the two-asset steady states, baseline vs
   lump-sum vs levy, using the solvers' value functions (EGM: p.compute_V;
   KV: native V). This is the object that answers "who pays" in the
   disciplined model; until it exists the distributional answer is
   one-asset only.
2. **Convenience-yield elasticity calibration** (R3, days;
   calibrate_convenience_kvj.m scaffolded). The model's d(spread)/d ln B is
   the Krishnamurthy--Vissing-Jorgensen regression object; calibrating the
   liquidity curvature to the empirical estimate closes the
   separable-vs-complementary fork with data and anchors the whole
   elasticity chain.
3. **Ownership-calibrated liquid claims** (R2, the next real build, ~2-3
   weeks). Intermediation wedge (part of debt held inside the illiquid
   account via a fund), direct liquid holdings calibrated to the SCF
   distribution, superstar income state ported from the one-asset model
   (add_superstar_state). Fixes the revaluation base in level and
   distribution and produces wealthy hand-to-mouth households.
4. **Accuracy pack** (R4, days). Euler errors on the simulated
   distribution + one grid-doubling row per two-asset driver; KV incidence
   block at a smaller perturbation; transition damping-robustness row.
5. **Two-price sequence-space Newton** for the transition (upgrade from
   the damped map), reusing the one-asset SSJ machinery on the stacked
   (P, q) path.
6. **Elastic labor in the levy welfare comparison** (R5): either the
   production-block wedge extended to the instrument ranking, or narrowed
   welfare language.
