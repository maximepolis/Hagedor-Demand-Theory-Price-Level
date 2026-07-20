# Response to the referee

We thank the referee for a demanding and constructive report. The revision has
changed both the paper's argument and its scope. We agree that the paper's
durable contribution is the financing-incidence mechanism: tax incidence
changes demand for nominal public liabilities, thereby determining the sign and
distribution of debt revaluation. We have reorganized the paper around that
result and drawn sharper lines between three categories of claim.

- The **analytical incidence result** is exact within the stated environment.
- The **sign of the benchmark financing comparison** is a calibrated model
  result whose primitive is the tax response of nominal-liability demand.
- The **point price-level magnitudes** are conditional on the one-asset
  portfolio structure and are reported as benchmark calculations, not as
  portfolio-validated predictions.

Where the referee identified logical errors, we corrected the statements and
proofs. Where an extension is necessary for a quantitative claim we make, we
either implemented it or narrowed the claim. Where an extension would answer a
different research question — most notably a full production economy — we
explain why we retain the benchmark environment and remove the broader
interpretation.

Each numbered item below is stated as **Comment / Response / Change**.

---

## 1. Proof of existence at the low-price boundary

**Comment.** The collapse argument at the low-$P$ boundary fails when real
rates are negative.

**Response.** Correct. The excess-demand map behaves differently according to
the sign of the coefficient on $1/P$; the original proof implicitly assumed the
positive case.

**Change.** The existence proof now splits on that sign. Where the coefficient
is positive the low-$P$ end drives excess demand to the feasibility edge; where
it is non-positive — the negative-real-rate configuration the referee raises —
existence follows from the high-$P$ boundary alone, without the collapse step.

## 2. Result 1 sufficient conditions

**Comment.** The global monotone comparison requires $\tau_1 \ge \tau_0$.

**Response.** Correct.

**Change.** Result 1 is now stated as sufficient under $\tau_1 \ge \tau_0$ (a
green program weakly raises the tax rate), or as a local statement at the
no-program point. The unqualified global claim is removed.

## 3. Regularity labels in the sufficient-statistic proposition

**Comment.** The differentiability the representation needs is conflated with
the feasibility conditions.

**Response.** Agreed; "regularity" was overloaded.

**Change.** The smoothness requirement is now a distinct condition (R3), kept
separate from the boundary/feasibility conditions (R1)–(R2), consistently
across the statement, the proof, and the status paragraph.

## 4. Strict income improvement vs. the damage floor

**Comment.** The strict-improvement claim conflicts with the bounded-incidence
damage floor.

**Response.** Correct.

**Change.** The statement is weakened to a weak income improvement, strict
except where the damage floor binds.

## 5. The covariance proposition overclaims

**Comment.** For a revenue-neutral reform the covariance governs the *direct*
incidence term, not the full stationary-equilibrium sign, which also contains a
distribution term and, in general, a price term.

**Response.** Correct, and important given that the paper emphasizes that the
stationary distribution moves materially. We have narrowed the proposition to
the exact object we can sign.

**Change.** The proposition now states the direct term, holding prices and the
distribution fixed, as exactly $\mathrm{Cov}(m_i^b, dy_i^{\mathrm{net}})$ for a
revenue-neutral reform, and writes the full response as
$\mathrm{Cov}(m_i^b, dy_i^{\mathrm{net}}) + \mathcal D_\alpha + \mathcal
G_\alpha$: a distribution term and a price term, the latter zero in the
endowment economy where the experiment fixes the real rate. We no longer call
the covariance "the exact micro-foundation" of the full sign. Whether the
covariance dominates is stated as a quantitative question and answered by a
direct computation on the calibrated distribution (direct covariance term
versus full tilt response, with the remainder assigned to $\mathcal D_\alpha$).

## 6. Labor supply under lump-sum taxation

**Comment.** A lump-sum tax's wealth effect raises labor supply; base-shrinking
comes from distortionary marginal rates.

**Response.** Correct.

**Change.** The sign is fixed: lump-sum financing raises hours through the
wealth effect; the base-shrinking intuition is attached to the distortionary
levy, not the lump-sum tax.

## 7. The tax semi-elasticity and empirical discipline

**Comment.** MPC-by-wealth evidence does not directly identify the aggregate
response to a permanent lump-sum tax; the semi-elasticity should not be
presented as empirically estimated.

**Response.** We agree and no longer describe it as measured. External MPC
evidence disciplines the household states and marginal responses that underlie
the mechanism, but it does not identify the aggregate stationary response to a
permanent tax.

**Change.** We made three changes. First, the semi-elasticity is described as a
model-implied calibrated object, not an empirical estimate; the phrase "the
formula's inputs are measured, not assumed" is removed. Second, we provide a
complete policy-versus-distribution decomposition and a sign-sweep over the
governing primitives. Third, the covariance representation states the mechanism
in terms of the covariance of saving propensities with tax incidence, whose
ingredients external evidence can in principle discipline, without claiming the
aggregate elasticity is directly estimated.

## 8. Two-asset portfolio structure

**Comment.** A nonlinear portfolio model is required to interpret the
price-level magnitudes as quantitative predictions.

**Response.** We agree for portfolio-validated *magnitudes*, and disagree that
it is required for the paper's main *theoretical* result. The price-response
formula and the financing-incidence proposition are statements about the demand
schedule for the nominal liability $S_b$; they remain valid in a richer
portfolio environment after replacing total saving with nominal-bond demand.
The one-asset economy provides a transparent benchmark in which that schedule
can be solved globally.

**Change.** We removed the point price-level magnitudes from the abstract and
relabeled them throughout as one-asset benchmark calculations; the quantitative
contribution is recast around signs, the sufficient statistic, and sensitivity
bounds. We do not assert that magnitudes or orderings survive a richer portfolio
structure — that is stated as an open quantitative question. A minimally
sufficient nonlinear portfolio extension is under development; we will first
determine whether a one-dimensional total-wealth state admits valid aggregation
and, if not, use separate liquid and illiquid asset states. No result will be
described as portfolio-validated until the two markets clear separately.

## 9. Production and distortionary taxes

**Comment.** Add a production economy with distortionary taxes and tax-base
effects.

**Response.** We agree production is required to quantify endogenous tax-base
revenue and private-capital crowd-out, and respectfully disagree that it is
required for the incidence result. The endowment economy is deliberate: it
isolates the household nominal-liability demand channel without conflating it
with production multipliers, labor-supply responses, and wage/marginal-cost
effects that would obscure the incidence mechanism. A full production economy
answers a different question.

**Change.** We removed any claim that the benchmark model quantifies total
fiscal self-financing, report the resource benefit–cost ratio and the
nominal-debt revaluation term as separate objects (never summed into a
"self-financing" headline), and keep the production/tax-base calculation as an
appendix accounting bound rather than a body result.

## 10. Event study

**Comment.** Add an empirical announcement-window event study.

**Response.** We agree that announcement-window inflation expectations are the
natural discriminator, and do not believe the existing set of policy
announcements permits credible separation of spending, financing, regulatory,
and monetary news. A weakly identified event study would reduce credibility.

**Change.** We present the opposite-sign prediction as a testable implication
and, in place of an underidentified event study, report a matched $2\times2$
model experiment that varies price determination and financing independently,
establishing the theoretical sign restriction future empirical work should test.

## 11. Numerical transition accuracy

**Comment.** Market-clearing residuals near $5\times10^{-4}$ and cross-solver
agreement near one percent are not research-grade for a large announcement
repricing.

**Response.** We agree the original tolerances are insufficient for treating the
announcement magnitudes as precise estimates, and we now distinguish the robust
sign, the qualitative front-loading, and the provisional magnitude. We do not
claim the front-loading share is structure-free; it is a one-asset benchmark
that a richer portfolio, credibility, or maturity structure could move.

**Change (in progress).** We are tightening the transition computation
(continuous-lottery interpolation, finer grids, refreshed Jacobian) and will
report, across asset grids, the change in the impact price response, the
front-loading share, and the maximum residual, together with independent-solver
agreement. Until that is complete the magnitude is labeled provisional and the
sign and timing pattern carry the argument.

## 12. Prune the paper

**Comment.** The paper is too long; multiplicity, aggregate risk, optimal
accommodation, and the unmatched NK/HANK exercises belong in an online appendix.

**Response.** We agree.

**Change (in progress).** The main text is being reduced to the incidence
theorem, the baseline model, the financing comparison, the tax-response
mechanism, the welfare incidence, the nonlinear DTPL transition, and the matched
NK comparison. The multiplicity, aggregate-risk, optimal-real-rate, and
unmatched RANK/HANK exercises are moving to the online appendix, and the
introduction no longer previews them as contributions.

## 13. Multiplicity is not quantitatively active

**Comment.** Move it to the appendix and drop it from the keywords.

**Response.** Agreed; the calibrated frontier never activates it.

**Change.** The self-fulfilling-equilibria keyword is removed and the
multiplicity material is being moved to the online appendix as design insurance,
not a headline result.

---

## Summary of stance

| Comment | Stance | Action |
|---|---|---|
| Proof corrections (1–4) | Agree | Statements and proofs changed |
| Covariance overclaim (5) | Agree | Narrowed to the direct term + $\mathcal D_\alpha$ + $\mathcal G_\alpha$ |
| Labor-supply sign (6) | Agree | Corrected |
| Tax semi-elasticity empirics (7) | Partially agree | Relabeled as model-implied; decomposition added |
| Two-asset model (8) | Partially disagree | Required for magnitudes, not the theorem; magnitudes narrowed; extension under development |
| Production economy (9) | Respectfully disagree for the main paper | Fiscal claims narrowed; accounting bound kept in appendix |
| Event study (10) | Respectfully disagree as a requirement | Testable implication + matched $2\times2$ |
| Prune (12) / multiplicity (13) | Agree | Reorganization in progress |
| Transition accuracy (11) | Agree | Tightening in progress; magnitude labeled provisional |
