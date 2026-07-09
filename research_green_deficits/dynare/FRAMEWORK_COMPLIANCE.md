# Framework-compliance audit of the HANK `.mod` files

**Reference:** Dynare Masterclass 2026, *Heterogeneity in Dynare 7 —
Describing the model* / *Extensions* (N. Rion, Dynare Team; slide decks in
`../../heterogeneity/writing_mod_files.pdf`, `.../extensions.pdf`). This
note records a line-by-line check of `green_hank.mod` (tier-1, one-asset)
and `green_hank2.mod` (tier-1b, two-asset) against the framework's parse
rules, done 2026-07-09 after the workshop material was added to the repo.
**Verdict: both files conform to every rule below; no changes required.**

## The parse rules (as stated in the lecture) and our compliance

| # | Rule | `green_hank.mod` | `green_hank2.mod` |
|---|------|------------------|-------------------|
| R1 | Heterogeneous **endogenous** lag ∈ {−1, 0}, lead ∈ {0, +1} | `a(-1)`, `c(+1)` only | `a(-1)`, `b(-1)`, `Va(+1)`, `Vb(+1)` only |
| R2 | Heterogeneous **exogenous** lag = 0 only (no lead/deeper lag) | `e` contemporaneous | `e` contemporaneous |
| R3 | No non-separable lead×lag entanglement of heterogeneous vars (`+`,`−` always OK; `×`,`÷` OK when one factor carries no lead) | no het lead and het lag share a term | adjustment cost couples `a`,`a(-1)` (contemp×lag, no lead); the only leads `Va(+1)`/`Vb(+1)` sit in separate affine terms | 
| R4 | A **nonlinear heterogeneous lead** must resolve to an affine lead via a contemporaneous auxiliary | `c(+1)^(-1/eis)`: preprocessor auto-introduces `AUX_HET_ENDO_LEAD` (slide 22) | done **manually** via the value-derivative auxiliaries `Va`, `Vb` (the envelope conditions define them at `t`; the Eulers use only affine `Va(+1)`, `Vb(+1)`) |
| R5 | `SUM(·)` only inside **aggregate** equations | `SUM(a)`, `SUM(ns)` in the aggregate block | `SUM(a)`, `SUM(b)`, `SUM(u)` in the aggregate block |
| R6 | Blocks square; auxiliaries count on both sides; no extra cross-check equations | het block 4 eq / 4 het vars; agg block square | het block 6 eq / 6 het vars; agg block square (single total-wealth clearing, not a redundant liquid+total pair) |
| R7 | Complementarity `⟂` = Dynare `mcp` convention (`RESID = LHS − RHS`, sign-blind on the interior branch in dynamics) | `⟂ a >= 0` on the Euler | `⟂ b >= 0`, `⟂ a >= 0` on the two Eulers |

## Two points the audit clarified

1. **The affine-lead requirement is why the two Eulers read the way they
   do.** The lead on a heterogeneous variable lives under the conditional
   expectation `E_{i,t}`, and the framework only supports it when the lead
   enters *affinely* (an aggregate factor times a single heterogeneous
   lead). `green_hank2.mod` satisfies this by carrying `Va`/`Vb`
   explicitly: `(beta_ss+beta)*Va(+1)` is aggregate × affine-het-lead.
   `green_hank.mod` instead writes `c(+1)^(-1/eis)` and lets the
   preprocessor build the auxiliary. Both are valid; the two-asset problem
   needs the explicit form because it has two Euler equations sharing the
   marginal-utility object.

2. **Aggregate leads are unrestricted.** The lecture notes that aggregate
   variables "escape the rule" (no expectation operator; non-separable
   couplings allowed, as in standard Dynare), with auto auxiliary chaining
   for non-zero leads on aggregate *exogenous* variables. This is why the
   climate/production/pricing aggregate equations (`r(+1)`, `pi(+1)`,
   `Q(+1)`, `p(+1)`, `div(+1)`, `K(+1)`) parse without restriction. The
   `run-5` edit `Z(+1) -> Z` in `green_hank2.mod` was therefore *not*
   required for compliance (the aggregate exo lead would have been
   auto-chained); it is a harmless simplification that drops one redundant
   auxiliary, exact here because `Z` is a zero-variance placeholder.

## Corroboration from the workshop's own examples

The `RCOND=NaN` that stalled `green_hank2.mod` before the `chi2=2`
smoothing was a *symbolic-derivative* pathology (`sign()`/`abs()^(chi2-1)`
kink at the illiquid-constraint corner), not a parse-rule violation — the
file always parsed. The `chi2=2` polynomial rewrite is the exact,
smooth-everywhere form and is fully compliant (contemporaneous-with-lag
adjustment cost, no lead entanglement).

Separately, the workshop's own **financial-intermediary** example
(`../../heterogeneity/hank_fi_irf_figures/fig_02_financial_intermediary.png`)
displays impulse responses at scales of 10^13–10^18 with an oscillatory
liquid return — i.e. a numerically **degenerate** solve. This is external
corroboration of our tier-1b finding that an *endogenous* liquid/illiquid
spread (convenience yield) is boundary-singular/unstable in this framework,
and that the constant-premium closure is the pragmatic and honest choice.
It argues *against* prioritizing an FI-based endogenous-spread extension as
a near-term win.
