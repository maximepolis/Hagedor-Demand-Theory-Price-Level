# Internal referee report (round 4): the paper with its two-asset results

Simulated demanding top-5 referee, written against the CURRENT repo state:
the integrated audit, the computed Step 0 / variant (b) results, and the
pending non-separable + transition runs. Each point states the defect, why
it matters for the research question ("who pays?"), and the fix.

## Summary judgment

The paper has become empirically disciplined about its own mechanism to an
unusual degree: the borrowing-limit artifact was caught and fixed, the
direct-vs-distributional decomposition is exact, the sufficient statistic is
validated against solved equilibria, and the two-asset extension honestly
overturned one of its own headline signs. That candor is a strength. But
the paper now sits in an unstable halfway house: **the research question is
distributional, and the distributional answer is still computed only in the
one-asset model**, while the two-asset economies that discipline the
aggregates deliver no incidence by group. Three of the concerns below
(R1-R3) must be resolved before the answer to "who pays" is credible.

## Major concerns

**R1 (fatal as it stands). "Who pays" is not yet answered in the two-asset
world.** The welfare incidence by decile — the object that answers the
title question — exists only for the one-asset economy (Section 5's decile
tables). The two-asset economies report d ln P and liquid-margin
elasticities, i.e. *price* answers, not *welfare* answers. Since the
two-asset structure changes the sign of the lump-sum price response, there
is no basis for assuming the one-asset decile incidence survives. *Fix:*
compute consumption-equivalent incidence by wealth group in the two-asset
steady states (the solvers already produce V — the frictionless EGM has an
opt-in value pass, the KV solver returns V natively) for baseline vs
lump-sum vs levy, and make that table the paper's answer to its own title.

**R2 (major). The nominal-claim ownership calibration is counterfactual in
the dimension the question lives on.** Households in the model directly
absorb the entire public-debt stock: mean liquid balances above annual
income for every household. In the data, direct household holdings of
government debt are small; most is held through intermediaries, funds,
pensions, and abroad, and the *distribution* of directly-held liquid wealth
is extremely skewed (median liquid assets of a few weeks of income). Since
"who pays" through revaluation is exactly "who holds the nominal claim,"
this is not a cosmetic mismatch: it inflates the revaluation base, spreads
it uniformly, and mechanically eliminates hand-to-mouth households (the
WHtM = 0 result already conceded). *Fix:* an intermediation wedge — a
fraction of debt is held inside the illiquid account (the tree becomes a
mutual fund holding capital and bonds), households' direct liquid target is
calibrated to the SCF liquid-assets distribution, and the superstar income
state (already implemented for the one-asset model) is ported to the
two-asset income process so the wealth distribution is right. This is the
single most consequential model improvement available.

**R3 (major). The specification fork must be closed by measurement, not
flagged.** The paper now concedes the lump-sum sign depends on the
liquidity aggregator (separable vs complementary). A referee will not
accept a fork as an ending: the two specifications have different
*observable* implications, and the natural discipline exists — the
convenience-yield literature (Krishnamurthy–Vissing-Jørgensen) estimates
the elasticity of the Treasury spread with respect to the supply of public
debt (roughly −0.05 to −0.13 log points per log point of debt/GDP). The
model has exactly this experiment: vary B, re-solve (P, q), read the
spread. Calibrate the curvature (zeta in the separable model, xi in the CES
model) to that elasticity and report the disciplined specification's sign
as the paper's answer. This simultaneously supplies the empirical anchor
the tax semi-elasticity chain has lacked.

**R4 (major). Numerical accuracy is documented for the one-asset model but
not for the two-asset results now doing the paper's heavy lifting.** No
Euler-error statistics for any two-asset solver; no grid-doubling table for
the two-asset equilibria; the variant-(b) liquid-margin additivity residual
(0.29, ~25% of the tilt) is flagged but unresolved (candidate-grid snap at
the 1% perturbation scale); the transition uses a hand-tuned damped map
(relax = 0.3) with no convergence guarantee and no damping-robustness
check. *Fix:* an accuracy block in each two-asset driver (Euler errors on
the simulated distribution, one grid-doubling row), a smaller-perturbation
rerun of the KV incidence block, and — as the production upgrade — a
two-price sequence-space Newton for the transition with the damped map as
fallback.

**R5 (major, scope). The instrument-ordering result ignores the efficiency
margin.** In the endowment economy the levy is non-distortionary by
construction, so the lump-sum-vs-levy comparison isolates incidence — good
for the price mechanism, but the *welfare* ranking of instruments cannot
ignore deadweight loss when the levy is a carbon-tax stand-in. The
production/tax-base appendix bound partially addresses this; the body
should state explicitly that the instrument ordering is a price-level
result, and the welfare comparison is conditional on lump-sum availability.
Either add the elastic-labor welfare wedge to the appendix bound or narrow
the welfare-ranking language.

**R6 (exposition). The paper's body and its best evidence have swapped
places.** The two-asset results — now the paper's most decisive
quantitative discipline — live in a supplementary appendix, while the body
quantitative sections still run on one-asset numbers with conditionality
footnotes. At 114 pages the architecture problem flagged in earlier rounds
has not improved: the sunspot diagnostics, aggregate-risk section, and
worked example are still in the body (prune stages 2+ pending). *Fix:*
promote the two-asset benchmark to a body section ("Disciplining the
magnitudes"), demote the remaining flagged sections, and retarget the body
at ~55-60 pages.

## Minor

- The exogenous policy-set bond rate r_b in the two-asset model is the DTPL
  convention, but the text should defend it explicitly where the two-asset
  economy is introduced (the equity return is then pinned by the
  convenience margin; the spread is an equilibrium object, the level is
  policy).
- lambda = 1/3 annual is asserted, not sourced; cite the KV adjustment
  evidence and show the lambda sensitivity row (computed) in the paper.
- The wealth-income ratio implied by the two-asset calibration
  (q·K + S_b ≈ 3.4) is below the U.S. ~5-6; note it, and R2's recalibration
  largely fixes it.
- The transition driver's damage path is flat (D fixed); fine for the
  financing experiment, but say so where the transition is reported.

## What would make this a clear accept

1. Two-asset welfare incidence by decile (R1) — the question answered in
   the disciplined model.
2. Ownership-calibrated liquid claims + intermediation wedge + superstar
   state (R2) — the revaluation base right in level and distribution.
3. Convenience-yield elasticity calibration closing the specification fork
   (R3) — the sign disciplined by data.
4. The accuracy pack (R4) and the two-asset transition converged with a
   Newton or verified damped map.
5. Architecture: two-asset in the body, body at ~55-60 pages (R6).

Items 1, 3, and 4 are one-to-two-week code exercises on existing machinery.
Item 2 is the next real build (order weeks). Item 5 is editorial.
