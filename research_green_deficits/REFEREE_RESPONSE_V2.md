# Response to the referee report + "Beyond the referee" memo

Two documents arrived: a full referee report (v2) and a forward-looking
research memo. This file records, item by item, what is **implemented in the
manuscript now**, what **needs a MATLAB run** (scaffolded, pending your
machine), and what is a **future-research** item (weeks of model work, or a
separate paper).

Legend: [DONE] in the .tex/.bib now · [RUN] code scaffolded, needs your run ·
[FUTURE] research item, not this revision · [FLAG] judgment call for you.

---

## Referee report — potentially fatal concerns

- **C1 (unsigned portfolio correction).** [DONE] Removed every "upper
  bound"/ω-scaling directional claim (abstract, §5.6 bound paragraph, §6.3).
  The §5.6 passage now lays out the three polar cases (stable shares → no
  scaling; pinned outside return → *amplified* by ~1/ω, i.e. one-asset
  *understates*; elastic convenience yield → sign governed by ℓ′, uncalibrated),
  cites Krishnamurthy–Vissing-Jørgensen for ℓ′, and rests the paper's
  quantitative content on signs/shares/orderings. [FUTURE→M1] the structural
  fix is the bonds-in-utility two-asset economy (memo M1); that is the
  decisive multi-week build that turns every magnitude into a computed object.
- **C2 (KNV demarcation).** [DONE] The one-sentence KNV mention is now a full
  mechanism-level demarcation paragraph in §2: shared primitive
  (∂S/∂τ by incidence), different regime (passive-fiscal DTPL vs their
  FTPL-rooted determination), different object (sign of revaluation for a
  given appropriation vs deficit capacity), and what survives translation.
  The M2 tilt decomposition (below) is the computed bridge the referee asked
  for. Also added the missing lit: Mian–Straub–Sufi, Bassetto–Cui,
  Brunnermeier–Merkel–Sannikov, Kocherlakota; merged the duplicate Auclert key.
- **C3 (matched experiment not instrument-matched).** [DONE, text] The
  conclusion no longer claims the sign contrast is "attributable to the
  price-determination block itself"; it states the tax-incidence convention
  is a second difference, that Prop 8 makes incidence sign-determining, and
  that the clean test is the 2×2 of {price determination}×{lump-sum,
  proportional}. [RUN] the 2×2 itself (run the matched pair under both
  incidence conventions) is listed below.
- **C4 (mixed provenance / stale prose).** [DONE] Converted the §5.9 regime
  prose numbers to macros (−0.055→\RDefRev etc.); fixed the §5.6 "0.56"→\nuMedShort;
  the §5.5 decomposition is EGM (−5.45%); the stale tab:regimesreal caption
  was already removed. [FLAG] the transition (§6.3) is deliberately pinned to
  the grid-choice solver for numerical stability, so its boundary P0=0.9051
  differs from the EGM steady-state P0=0.9033 by the disclosed ≤0.4% solver
  gap — the numerical appendix documents this. The one number I could not
  source (worked-example W: −8.981 in the optimal-accommodation appendix vs
  −8.954 in the benchmark table) is flagged below for you to reconcile.
- **C5 (incidence floor).** [DONE] The floor s̲=0.05 is now stated in the
  model section at eq:incidence, with the aggregation caveat (E[y]>1−D where
  it binds; the identities are exact off the floor and first-order on it).
  The conclusion's collapse sentence now carries the lump-sum conditionality.
  [RUN] recompute the ψ=2 frontier rows under the floor and confirm the
  collapse survives (listed below).

## Referee report — major comments

- **5.1** [DONE] intro "optimal nominal growth rate is a genuine instrument"
  → "the real rate … is a genuine instrument" (was false by Prop 2).
- **5.2** [DONE] the σ=1 claim is corrected: the target is attainable in
  principle (asset demand diverges as β→1/(1+r)), but the required β is
  implausibly close to the boundary — an identification point, not a
  feasibility restriction.
- **5.3** [DONE, text] §5.7 aggregate-risk now declares itself the indexed
  mandate, states the state-by-state tax rule, and notes the nominal-budget
  case (K_g becomes a slow aggregate state) is bracketed rather than carried
  — which also gives Prop 6 an on-equilibrium insurance reading. [RUN] the
  polar fixed-K_g bracket runs are optional discipline.
- **5.4** [DONE] §3.2 now commits to public adaptation capital (version 1) as
  the benchmark reading, with mitigation (version 2) as the coordinated-program
  robustness variant.
- **5.5** [DONE] ν-taxonomy enforced: intro reworded to "raises the
  revaluation share … lowers the net household burden"; Prop 4(ii)'s
  condition relabeled a net-burden condition with the interest-transfer
  caveat.
- **5.7** [DONE] the false "nonatomic distribution" justification in the
  suffstat proof is deleted (the chain is finite; ā=0 puts 17.7% at one
  point); the status label is downgraded to "proved under a maintained
  regularity hypothesis, numerically verified" at the statement, the proof,
  and the §4 status paragraph (now "three proved from primitives").
- **5.10** [DONE] the tax node of the decomposition is now tied to the
  Table-4 semi-elasticity explicitly ("the two exhibits are one measured
  object"). [RUN] reporting the levy semi-elasticity across the same sweeps
  is a small addition to the elasticity driver (not yet added).
- **Lemma audit** [DONE] Lemma 1 states chain irreducibility/uniqueness of
  the invariant distribution; Lemma 2's garbled derivative line is cleaned
  up; Lemma 3 carries the deterministic-model scope qualifier; Prop 7's
  status line now flags that the interior optimum is located at
  worked-example scale.
- **Program-scale wording** [DONE] the Table-3 caption now says the program
  is 2.1% of mean income at the program price (2.0% at the no-program price).

## Referee report — needs your MATLAB runs [RUN]

1. **Single-solver transition** (C4): regenerate the §6.3 transition under
   EGM if you want to close the 0.4% solver gap — but this re-opens the SSJ
   divergence we fixed by pinning to grid-choice, so the honest alternative
   (currently in the paper) is to keep the disclosed gap. Your call.
2. **2×2 matched experiment** (C3): run the matched DTPL-vs-NK pair under
   lump-sum incidence on both sides and proportional on both sides; report
   the 2×2 of announcement-inflation signs.
3. **ψ=2 collapse under the floor** (C5): recompute the frontier rows.
4. **Exact-ε_S on the frontier** (5.8): elasticities from exact re-solves
   at P±ΔP along the frontier rows, not the bilinear interpolant.
5. **Post-damage leverage headline** (5.6): re-bisect β per column on
   post-damage leverage; make the pre-damage design the robustness.
6. **Prop 2 flatness verification** row (flat W along Fisher-preserving moves).

## "Beyond the referee" memo

- **M2 (tilt decomposition).** [DONE, text + RUN code] Added the analytical
  identity (eq:tiltdecomp: lump-sum = same-revenue levy + mean-zero
  regressive tilt) as a new paragraph "Anatomy of the sign", framed as the
  characterization and the KNV bridge. Scaffolded the tilt-only counterfactual
  in the elasticity driver (part (d): levy(perRev)+tilt vs lump-sum(perRev),
  with an additivity residual) and the \epsTilt/\epsLsPerRev/\epsLevyPerRev
  macros. **[RUN]** `decompose_tax_elasticity` to populate the exact split;
  the paper text uses the macros with a pending fallback until then.
- **P1 (abstract restructure).** [DONE] The abstract now leads with the
  incidence result (the financing instrument sets the sign; lump-sum = levy +
  regressive tilt) and demotes the two neutrality theorems to a scoping
  clause, exactly as the memo and referee C2 recommend.
- **M1 (two-asset bonds-in-utility economy).** [FUTURE] The decisive
  extension and the structural answer to C1 — a Lucas tree + v(b) liquidity
  term, household state stays total wealth (EGM unchanged), two market-clearing
  conditions pin (P,q). 3–5 weeks; it retires the abstract's weakest sentence
  and yields the d ln P-vs-ζ figure the DTPL literature lacks. Recommended as
  the next major build.
- **M3 (levy as determinacy instrument), M4 (optimal financing mix), M5
  (λ-credibility transition), M6 (sustainable-r frontier), M7 (MPC
  validation).** [FUTURE] Each is a 1–2 week code exercise on existing
  machinery; M2→M7→M3/M4 is the memo's recommended order. M6 (invert the
  collapse table into a sustainable-real-rate frontier) and M7 (MPC-by-wealth
  validation against Fagereng/Kaplan–Violante–Weidner) are the cheapest.
- **P2 (event studies: BVerfG 2023 ruling, IRA 2022).** [FUTURE, data] The
  first empirical step; opposite-signed model-class predictions on breakeven
  inflation. High value, high risk (the signs may not cooperate).
- **P3 (split into Paper A incidence / Paper B neutrality note / Paper C
  monetary-union).** [FLAG] A strategic decision to make once M1's magnitude
  is known. The current single manuscript is comprehensive; splitting is the
  memo's recommendation for the general-interest push.
- **P4 (θ_g frontier in cost-per-damage-avoided units), P5 (Condorcet
  corollary over the four regimes).** [FUTURE, small] P4 needs a figure
  relabel; P5 needs the full CE-transfer distribution (not just decile
  means) to compute pairwise majorities.

## Flag for you (unsourced number)

The worked-example optimal-accommodation appendix reads W(μ=0.02) = −8.981,
while the benchmark table (tab:benchmark) reports −8.954 for the same
steady state. I cannot recompute the worked example; please reconcile from
its run (or tell me which is authoritative and I will align the other).

## Architecture note (referee §9 / memo P6)

The referee recommends demoting Props 5–7 to a remark and promoting the
matched experiment to its own body subsection. I did **not** do this
structural reorganization — it is a large move and the memo's M3 (levy as
determinacy instrument) would give Props 5–6 a *replacement* rather than a
deletion, so the right sequencing is M3 first, then the demotion. Flagged
for a dedicated pass if you want it.
