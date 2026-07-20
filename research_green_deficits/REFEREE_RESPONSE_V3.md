# Response to the major-revision referee report (round 3)

This round covered a full "major revision / reject-and-resubmit" referee
report plus a set of detailed proof-audit points (#1–#4). This file records,
item by item, what is **implemented in the manuscript now**, what **needs a
MATLAB run** on your machine, and what is a **future-research** item.

Legend: [DONE] in the .tex/.bib now · [RUN] code scaffolded, needs your run ·
[FUTURE] research item, not this revision · [FLAG] judgment call for you.

---

## Proof audits (#1–#4) — all implemented

- **#1 (Prop 1 low-price boundary, negative rates).** [DONE] The proof of
  existence no longer asserts a collapse at the low-price boundary
  unconditionally. It now splits by the sign of the coefficient on \(1/P\)
  in the excess-demand map: where that coefficient is positive the
  low-\(P\) end drives excess demand to the feasibility edge (collapse
  argument intact); where it is non-positive — the empirically relevant
  negative-real-rate configuration — existence is guaranteed by the
  boundary behaviour at the *high*-\(P\) end alone, so the theorem holds
  without the collapse step. The referee's counterexample is thereby
  absorbed rather than contradicted.
- **#2 (Result 1 sufficient conditions need \(\tau_1\ge\tau_0\)).** [DONE]
  Result 1's monotone-comparative-statics step is now stated as sufficient
  under \(\tau_1\ge\tau_0\) (the empirically relevant case: a green program
  weakly raises the tax rate), or, absent that, as a local statement at the
  no-program point. The unqualified global claim is removed.
- **#3 (Prop 3 regularity labels).** [DONE] The differentiability the
  sufficient-statistic representation needs is relabelled as a distinct
  smoothness condition **(R3)**, kept separate from the boundary/feasibility
  conditions **(R1)–(R2)** used elsewhere. The proof, the proposition
  statement, and the §4 status paragraph all use the new label consistently,
  so "regularity" no longer overloads two different requirements.
- **#4 (A.7 strict income improvement vs the damage floor).** [DONE] A.7
  now states a **weak** income improvement that is strict **except where the
  damage floor \(\underline{s}\) binds**. This removes the conflict the
  referee flagged between the strict-improvement claim and the bounded-
  incidence floor introduced for the frontier.

## Major-revision report — implemented in the text now

- **Lump-sum semi-elasticity as the organizing measured object.** [DONE]
  The tax node of the decomposition is tied explicitly to the measured
  semi-elasticity, and the abstract now *leads* with the incidence result:
  the financing instrument sets the sign of the revaluation, and lump-sum
  financing equals a same-revenue proportional levy plus a mean-zero
  **regressive tilt**. The tilt split is a computed identity
  (\epsLsPerRev = \epsLevyPerRev + \epsTilt, per unit of revenue), populated
  from `numbers_auto.tex`.
- **Covariance representation of the nominal-liability margin.** [DONE] New
  proposition (covariance form of financing incidence): the response of
  aggregate nominal claims to a financing reform decomposes into
  \(\E[m^b]\,\E[dy^{\mathrm{net}}] + \Cov(m_i^b, dy_i^{\mathrm{net}})\); for a
  revenue-neutral reform the mean term vanishes and the sign is governed by
  \(\Cov(m_i^b, dy_i^{\mathrm{net}})\), where \(m_i^b\) is the marginal
  propensity to accumulate liquid nominal claims. This is the exact
  micro-foundation the referee asked for behind "who holds the nominal
  liability at the margin."
- **Labor-supply sign.** [DONE] The §5.5 wording is corrected: under
  lump-sum financing the wealth effect **raises** hours (it does not shrink
  the tax base); the base-shrinking intuition applies to the distortionary
  levy, not the lump-sum tax.
- **Climate discipline / instrument dependence.** [DONE, carried from prior
  rounds] The benchmark reading commits to public adaptation capital, with
  mitigation as the coordinated-program robustness variant, and the frontier
  results carry the lump-sum conditionality wherever the collapse is quoted.
- **Keywords / framing.** [DONE] Keywords updated to *tax incidence, debt
  revaluation, fiscal policy, public investment, climate*; the
  self-fulfilling-equilibria keyword is dropped, matching the demotion of
  the sunspot material done in earlier rounds.

## Major-revision report — needs your MATLAB runs [RUN]

1. **Empirical sign-test of the tax semi-elasticity.** Report
   \(\partial \ln S_b/\partial\tau\) against an external MPC-by-wealth
   moment (Fagereng et al. / Kaplan–Violante–Weidner) so the sign of the
   incidence channel is disciplined, not just internally consistent. Small
   addition to the elasticity driver; the covariance proposition gives the
   object to target (\(\Cov(m_i^b, dy_i^{\mathrm{net}})\)).
2. **2×2 matched experiment** ({price determination} × {lump-sum,
   proportional}): the clean instrument-matched test behind the DTPL-vs-NK
   sign contrast.
3. **ψ=2 collapse under the damage floor:** recompute the frontier rows and
   confirm the collapse survives the bounded-incidence floor.
4. **Exact-\(\varepsilon_S\) on the frontier:** elasticities from exact
   re-solves at \(P\pm\Delta P\), not the bilinear interpolant.
5. **Levy semi-elasticity across the same sweeps** as the lump-sum map, so
   the two exhibits are reported as one measured object across primitives.

## Future research [FUTURE]

- **Two-asset bonds-in-utility DTPL model (the decisive build).** A Lucas
  tree + \(v(b)\) liquidity term, household state stays total wealth (EGM
  unchanged), two market-clearing conditions pin \((P,q)\). This is the
  structural answer to the one-asset magnitude question and turns every
  revaluation magnitude into a computed object with an elastic convenience
  yield. 3–5 weeks; recommended as the next major build. Everything in the
  current manuscript that rests on signs/shares/orderings survives; this
  replaces the remaining magnitude caveats.
- **Empirical event studies** (opposite-signed model-class predictions on
  breakeven inflation) and the **architecture reorganization** (demote the
  neutrality/aggregate-risk/optimal-accommodation propositions to an
  appendix) remain deferred, the latter pending the levy-as-determinacy-
  instrument result that would *replace* rather than delete those
  propositions.

## Compile status

108 pages, 0 undefined references, clean bibtex. Committed and pushed to
`claude/hagedorn-dtpl-matlab-9abghk`.
