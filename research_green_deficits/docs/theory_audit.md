# Theory audit — every formal statement, adversarially reviewed

Scope: all lemmas, propositions, results, and their proofs in
`paper/green_deficits_price_level.tex` (Section 4 + Appendix A), audited
against the questions of the revision plan (Phase 3.4): exact assumptions,
domain, borrowing-constraint kinks, local vs global, numerical conditions,
and explicit counterexample attempts. Findings that required a manuscript
change are marked **[FIXED — this audit]** with the change described;
findings fixed in earlier referee rounds are marked [fixed earlier].

Verdict key: **SOUND** (proof complete under stated hypotheses) ·
**SOUND-C** (sound with stated caveats / numerically verified inputs,
correctly labeled) · **GAP** (would need repair — none remain open).

---

## Lemma `lem:S` (Regularity and scaling of asset demand) — SOUND

- **Assumptions.** β(1+r) < 1 (buffer-stock target finite); feasibility at
  the poorest constrained state; for the *exact* scaling: CRRA, φ_D = ψ = 0,
  and a borrowing limit that is zero or scales with 1−D.
- **Kinks.** None threaten the argument: the scaling proof maps the
  constraint set to itself exactly (this is why ā = 0 is needed — a fixed
  ā > 0 maps to −ā/(1−D)), so no differentiation is performed.
- **Local/global.** Global on the feasibility set.
- **Counterexample attempts.** (1) Fixed ā > 0: homogeneity fails — the
  lemma itself states this and restricts the claim. Blocked by hypothesis.
  (2) ψ > 0 (incidence gradient): endowment process becomes D-dependent —
  the lemma downgrades to a level/risk decomposition there. Blocked.
- **Note.** Existence/continuity via contraction + theorem of the maximum is
  standard; the grid-truncation step is justified by the finite buffer-stock
  target.

## Lemma `lem:climate` (Climate fixed point) — SOUND

- Monotone map T(D) on [0, D_max] with T(0) > 0, T(D_max) < D_max, T′ < 0:
  existence and uniqueness by IVT + monotonicity. Strict decrease in g_g
  requires θ_g·α_A > 0, stated.
- **Counterexample attempt.** α_A = 0 or θ_g = 0: D constant in g_g — the
  strictness qualifier covers exactly this. Blocked by the stated qualifier.

## Lemma `lem:anchor` (Nominal anchor) — SOUND

- Definitional: stationarity (constant real debt) + the nominal growth rule
  imply π = μ; Fisher pins r^ss. Domain: stationary equilibria only, stated.
  No counterexample exists within the stated domain; outside it (transitions)
  the paper never invokes the lemma.

## Proposition `prop:determinacy` (Existence and green determinacy) — SOUND-C

- **Assumptions.** ass:feasible + the *crossing condition* (bond supply
  exceeds bounded demand at the low-P edge) + regularity (R1)–(R2); θ_g = 0
  or indexed budget.
- **Honesty check.** The proof and text correctly state that the crossing
  condition is NOT implied by feasibility — the fiscal-space collapse is the
  documented failure mode. Good.
- **Kinks.** Uniqueness argument differentiates Φ at zeros
  (dΦ/dP = (S/P)(ε_S+1)); differentiability of aggregate S at crossings is
  the (R1)–(R2) regularity — flagged, and numerically the measured ε_S is
  smooth at every reported equilibrium.
- **Local/global.** Uniqueness is global on the feasibility interval *given*
  the elasticity hypothesis at every zero; correctly phrased ("wherever
  Φ = 0").
- **Counterexample attempts.** (1) Economy where the feasibility set is
  nonempty but demand exceeds B/P everywhere (no crossing): existence fails —
  this is exactly the excluded case, and the paper documents it as the
  collapse. (2) ε_S < −1 at some crossing: multiplicity — excluded by the
  (ii) hypothesis and realized in prop:sunspots. Both blocked by hypotheses
  that the text openly discusses.

## Lemma `lem:neutrality` (Nominal neutrality of debt issuance) — SOUND

- Pure homogeneity: B enters the real fixed point only through G_g/B.
  Airtight given the model's primitives (the borrowing limit is real; no
  other nominal object exists).
- **Counterexample attempts.** (1) Fixed *nominal* borrowing limit ā_N/P:
  would break neutrality — not a feature of the model (limit is real);
  worth remembering for extensions. (2) Transition/aggregate risk: neutrality
  fails (predetermined B matters) — the text states this scope limit
  explicitly. Blocked/acknowledged.

## Proposition `prop:muneutral` (Steady-state monetary neutrality) — SOUND

- Substitution: (i, μ) enter only through r^ss. Domain: deterministic
  stationary equilibria; the text states failure along transitions and under
  aggregate risk. No gap.

## Proposition `prop:suffstat` (Incidence formula, new) — SOUND-C

- **Assumptions.** Equilibrium crossing; differentiability of the composite
  S(P, g) at the crossing; ε_S ≠ −1.
- **Kinks — the real issue.** Aggregate S integrates household policies over
  an invariant distribution with atoms (finite income chain; mass at the
  constraint), so smoothness of the aggregate is not automatic: as (P, g)
  move, the constrained set changes and S can in principle have kink points.
  The proposition therefore takes differentiability at the crossing as a
  maintained hypothesis (generic, verified numerically at every reported
  equilibrium) — the proof says exactly this. Correctly labeled SOUND-C,
  matching the paper's status taxonomy.
- **[FIXED — this audit] Part (iii) demoted.** The original draft of the
  proposition included a part (iii) asserting that channel elasticities
  "scale with the liquid share" in a portfolio economy — an interpretation
  about an object (the two-asset economy) not defined in this paper, hence
  not provable here. Moved out of the proposition into the discussion
  paragraph, explicitly labeled an interpretation the two-asset extension
  makes concrete.
- **[FIXED — this audit] Notation clash resolved.** The draft defined
  η_x ≡ ∂lnS/∂x (semi-elasticities), silently clashing with
  prop:insulation's η_τ ≡ ∂lnS/∂lnτ (an *elasticity*, |η_τ| < 1 ≈ 0.3 at the
  benchmark — while the *semi*-elasticity is +2.60!). The proposition now
  writes the channel derivatives explicitly (∂lnS/∂τ etc.), reserving η_g
  for the composite only; prop:insulation now defines its η_τ explicitly as
  the elasticity, with the conversion to the Table 4 semi-elasticity stated.
- **Counterexample attempts.** (1) ε_S = −1 at the crossing (tangency): IFT
  fails, no differentiable branch — excluded by hypothesis, and it is the
  economically meaningful boundary (multiplicity). (2) Kink of S exactly at
  the crossing: formula's one-sided derivatives differ — excluded by the
  differentiability hypothesis; generic in the parameter space. Both blocked
  by stated hypotheses that carry economic meaning rather than hiding it.

## Proposition `prop:selffinancing` + Result `res:disinflation` — SOUND-C

- (i) exact identity; (ii) marginal identity at g_g = 0, with the
  convention-dependence away from the margin worked out explicitly
  [fixed earlier: the (1−κ)g_g coefficient algebra]; (iii) exposure vs
  signed incidence [fixed earlier this session: levy (L>0) progressive,
  windfall (L<0) regressive by wealth rank; income/welfare progressivity
  numerical only].
- res:disinflation carries the r^ss > 0 scope restriction [fixed earlier]:
  for r^ss < 0 the sign map from ΔP to ν_reval reverses.
- **Counterexample attempts.** (1) r^ss < 0 with disinflation: ν_reval flips
  sign — now inside the stated scope note. (2) ∂S/∂τ < 0 (loose limit):
  the result's own sufficient condition fails and the Angeletos
  configuration obtains — the text presents exactly this as the boundary.
  Blocked by stated conditions.

## Proposition `prop:sunspots` (Climate sunspots) — SOUND (conditional)

- IVT argument from the hypothesized transversal downward crossing plus
  boundary signs; at least three alternating zeros. The proof explicitly
  warns that ε_S < −1 on an interval does NOT imply a zero there — the
  hypothesis is the crossing itself. Welfare non-ranking between roots
  honestly left numerical.
- **Counterexample attempts.** (1) ε_S < −1 somewhere but Φ ≠ 0 there: no
  multiplicity — consistent, since the proposition hypothesizes the
  crossing. (2) Downward crossing at the boundary of the feasibility set
  (non-transversal): could yield exactly two zeros — excluded by
  "transversal" + interior boundary signs. Blocked.
- Calibrated region is empty and the paper says so everywhere it matters.

## Proposition `prop:insulation` (Anchor insulation) — SOUND-C

- Under the mandate dD/dP = 0, so ε_S = η_τ·dlnτ/dlnP with
  dlnτ/dlnP = −r^ss b/τ ∈ (−1, 0] for r^ss ≥ 0; for r^ss < 0 the algebra
  τ > |r^ss|b ⟺ g_g > 2|r^ss|b **checks out** (τ = g_g − |r^ss|b).
  The final step needs |η_τ| < 1 — numerically verified, and both the
  statement and Status line say so.
- **[FIXED — this audit]** η_τ now formally defined in the statement
  (elasticity, = semi-elasticity × τ), removing the ambiguity that made the
  |η_τ| < 1 bound look inconsistent with the measured +2.60 semi-elasticity.
- **Counterexample attempts.** (1) Accommodation with tiny program
  (g_g < 2|r^ss|b): the magnitude condition fails and |ε_S| can exceed 1 —
  the statement restricts to the region where the condition holds; genuine
  restriction, honestly stated. (2) |η_τ| ≥ 1 configuration (e.g. extreme
  risk aversion): outside the verified grid — the numerically-verified label
  covers it. Blocked by stated conditions.

## Proposition `prop:financingdesign` — SOUND-C (as labeled)

- Sign result under (i) S_τ ≥ 0 (measured) and (ii) approximate degree-one
  scaling in (1−ϑ) (exact in the homothetic limit; residual second-order for
  small ϑ). Proof is labeled a sketch; the P-ranking → ν_reval-ranking step
  carries the r^ss > 0 scope [fixed earlier this session].
- **Counterexample attempts.** (1) Large ϑ with strong non-homotheticity
  (ψ > 0 gradient): the approximation degrades — the Status line's
  "approximate" flag plus Table 6's exact numerical verification cover the
  reported region. (2) S_τ < 0: numerator flips and the design ordering
  reverses — excluded by condition (i), which is measured, not assumed.

## Proposition `prop:optimalmu` — SOUND-C (reduction + numerical location)

- The reduction (welfare depends on μ only through r^ss) is proved via
  prop:muneutral; the total-derivative framing correctly avoids the earlier
  conflation with transition windfalls [fixed in round 7]. Strict positivity
  of μ* follows analytically from the premise (concentrated bond wealth ⇒
  first-order interest-bill gain at μ = 0⁺, climate cost ∝ program size);
  *interiority* (the eventual downturn) is numerical and labeled so.
- **Counterexample attempt.** Bond wealth NOT more concentrated than income
  (e.g. forced saving at the bottom): the first-order gain argument fails —
  excluded by the stated premise, which the calibration satisfies by a wide
  margin. Blocked.

---

## Summary

| statement | verdict | open gaps |
|---|---|---|
| lem:S | SOUND | none |
| lem:climate | SOUND | none |
| lem:anchor | SOUND | none |
| prop:determinacy | SOUND-C | none (crossing condition openly conditional) |
| lem:neutrality | SOUND | none |
| prop:muneutral | SOUND | none |
| prop:suffstat | SOUND-C | none after this audit's two fixes |
| prop:selffinancing (+Result) | SOUND-C | none |
| prop:sunspots | SOUND (conditional) | none |
| prop:insulation | SOUND-C | none after the η_τ definition fix |
| prop:financingdesign | SOUND-C | none |
| prop:optimalmu | SOUND-C | none |

Three manuscript changes came out of this audit (all applied): the
suffstat part (iii) demotion, the η_τ semi-elasticity/elasticity clash, and
the missing formal definition of η_τ in prop:insulation. No statement has
an open GAP; every numerically-verified input is labeled as such at the
statement, per the paper's status taxonomy.
