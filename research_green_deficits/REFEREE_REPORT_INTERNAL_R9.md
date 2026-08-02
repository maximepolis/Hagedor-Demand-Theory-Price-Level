# ERRATUM (added round 10, before the original text)

**§3(c) of this report is withdrawn. It was wrong in two ways.**

*First, factually.* I described the fixed-real-program comparison as a design
choice the paper had not made. The paper has made it and computed it:
`\subsection{The financing regimes at fixed real scale}`
(`subsec:regimesreal`, `tab:regimesreal`) holds `g_g` fixed at its baseline
across all four regimes, lets `G_g` adjust, notes that the damage dividend is
therefore identical across regimes, and reports that the revaluation swing and
the welfare reversal survive, with fixed-nominal and fixed-real revaluation
shares differing only in the third decimal. The numbers are live macros in
`paper/numbers_auto.tex`. I read the section map, saw the subsection title, and
did not open it. That is the error.

*Second, conceptually.* I framed the distinction as "fixed-nominal `B`" versus
"fixed-real `B`". That is a category error. The nominal debt stock `B` is the
same in both experiments; what differs is whether the **appropriation** is held
fixed in nominal terms (`G_g`) or in real terms (`g_g`). There is no
outstanding question about the debt stock, and my claim that "the comparison's
answer depends on whether the debt stock is held fixed in nominal or in real
terms" is simply false.

The correct editorial disposition, which supersedes §3(c) and the
corresponding row of §5 and §7:

- **retain** Experiment N (fixed `G_g`) as the institutional baseline, because
  the nominal denomination of public budgets is part of the paper's mechanism;
- **elevate** Experiment R (fixed `g_g`) from the supplementary appendix into
  the main quantitative section as the pure-incidence companion;
- present them **adjacent**, not as alternatives;
- never describe Experiment N as comparing the same physical program;
- never describe Experiment R as holding the nominal fiscal position constant.

That the two experiments produce near-identical financing rankings is evidence
for robustness. It is not evidence that the design question was open.

Everything below this line is the original round-9 text, unaltered except that
§3(c) should be read as withdrawn.

---

# Internal referee report, round 9

**Manuscript.** *Who Pays for Green Public Investment? Tax Incidence, Debt
Revaluation, and the Price Level in Incomplete-Markets Economies.*

**Scope of this report.** Substantive review against the question the title
asks. This is not a copy-editing pass and it supersedes the tranche-1 length
work, which is suspended.

**What I could and could not verify from this environment.** I read the full
manuscript source and the code that produces every number cited below. I did
**not** compile the document (no TeX toolchain here) and I did **not** run
MATLAB (none here); no page count, figure, or numerical claim in this report
is newly computed. Where I cite a number it is the number the manuscript
currently prints, quoted as such. The external literature the report invokes
(§7) could not be retrieved from this environment either; those entries state
what each reference is *needed for* and are marked for verification against
the actual papers before anything is written into the text.

---

## 1. Recommendation

**Major revision, with three conditions that are not negotiable.** I would
tell an editor that at AER/QJE/JPE this is closer to a *reject and resubmit*
than a conventional R&R — not because the economics is weak, but because the
restructuring required is large enough that the resubmitted paper will be a
different document, and it is better for everyone to say so.

The three conditions:

1. **The headline experiment must hold the real program fixed.** As written,
   the nominal appropriation is fixed and real investment is `g_g = G_g/P`, so
   instruments that move `P` differently finance *different quantities of
   adaptation capital*. The paper cannot claim to compare "who pays for the
   same public investment" until this is repaired. Everything else in the
   paper is downstream of this.
2. **The tax response of nominal-liability demand must be disciplined
   externally, component by component.** The manuscript itself reports that
   the distributional term contributes roughly nine-tenths of the total
   response. External MPC evidence disciplines the primitives behind the
   *direct* term only. So the dominant component of the paper's central
   sufficient statistic is currently model-generated with no external anchor.
3. **The deficit result must separate tax timing from terminal debt.** The
   present experiment moves both at once, so the phase-in threshold is not
   yet interpretable as a tax-timing object.

### Why the paper is nonetheless worth the work

The analytical core is genuinely new and correctly stated. Proposition
(incidence formula) organizes the whole exercise; the two-market Schur
extension is the right generalization; and the paper is unusually honest
about its own hierarchy — the boxed separation of the ROBUST claim (levy more
inflationary than lump-sum) from the PREFERRED-CALIBRATION claim (opposite
sides of zero) is exactly the discipline most papers in this area lack. The
problem is that the *architecture* does not yet match that hierarchy. The
manuscript still reads as though the straddling-zero result, the multiplicity
region, anchor insulation, optimal accommodation and the aggregate-risk
extension are co-equal findings. They are not, and the paper says so in one
paragraph while devoting body space as though the opposite were true.

---

## 2. Ranked revisions

### Essential (the paper is not publishable without these)

| # | Revision | Why |
|---|---|---|
| E1 | Fixed-real-program headline experiment | The title question is otherwise unanswered |
| E2 | External discipline of `∂ln S^bond/∂τ`, split into direct / distributional / GE | 9/10 of the statistic is unanchored |
| E3 | 2×2 deficit experiment (timing × terminal debt) with consolidation path | Current threshold is not interpretable |
| E4 | Reorganize around three results; demote the rest to online appendix | Architecture must match the stated hierarchy |
| E5 | Coherent climate interpretation (adaptation benchmark) | Variables currently mean two different things |

### Important (a referee will insist, and each is tractable)

| # | Revision | Why |
|---|---|---|
| I1 | Implementable financing schedules (labor tax, progressive surcharge, carbon levy + recycling) | Lump-sum is a theorem device, not a policy alternative |
| I2 | Decompose every tax into mean + mean-zero tilt | Separates revenue from redistribution |
| I3 | Nested NK ladder, or demote the sign contrast entirely | Current comparison cannot identify why signs differ |
| I4 | Incidence over the joint distribution, seven components, both rankings | "Who pays" is not answered by a price |
| I5 | Identification diagnostics for the preferred calibration | See §3 — this *is* the identification section |
| I6 | Credibility structure on the announcement | The announcement window is proposed as the empirical test |
| I7 | Quantitative verification appendix in normalized units | Absolute residual thresholds are not certification |

### Optional (strengthens, not required)

| # | Revision |
|---|---|
| O1 | Foreign and institutional holders separated from the intermediation wedge |
| O2 | Spatial/private capitalization of adaptation capital |
| O3 | Lifetime-resource ranking as the primary incidence cut, annual as robustness |
| O4 | Connect the resource benefit–cost measure to the MVPF accounting framework |

---

## 3. Three points I would add to the brief

These are not in the instruction set I was given and I think they matter.

**(a) The 9/10 distributional share turns the calibration into the
identification section.** If the endogenous wealth distribution carries
nine-tenths of the sufficient statistic, then whatever pins down the wealth
distribution *is* what identifies the paper's central elasticity. That makes
the targeted-versus-untargeted moment table not a robustness courtesy but the
paper's identification argument, and it should be presented as such — in the
body, before the results that depend on it. It also sharpens E2: the useful
external targets are moments of the *distribution's response*, not just its
level. Panel evidence on how liquid-asset holdings shift across the wealth
distribution following persistent tax changes is worth more here than another
cross-sectional MPC.

**(b) A knife-edge should be measured, not just labelled.** The manuscript
states that the preferred-calibration sign requires ownership concentration,
the adjustment friction, the intermediation wedge and the superstar income
state to hold *jointly*, and that "removing any one of them destroys it."
That is honest but it is not enough. A referee will ask how large the region
is in which the sign survives. Report it: a sign map over the two or three
parameters that matter most (λ, ι_H, and the concentration parameter), with
the calibrated point marked and the external evidence's plausible range
overlaid. If the region is thin, saying so with a picture is far stronger than
saying so in a sentence — and if it is not thin, the current text undersells
the result.

**(c) The fixed-real experiment has a design choice the brief does not pin
down, and it is not innocuous.** Holding the real program fixed across
financing regimes means the *nominal* appropriation differs across regimes.
The nominal liability path is then also regime-dependent, and since the
revaluation channel operates on exactly that stock, the comparison's answer
depends on whether the debt stock is held fixed in nominal or in real terms.
The paper must state which, and why, and should probably report both:

- **fixed nominal `B`** — the revaluation base is common across regimes, so
  differences in revaluation incidence are attributable purely to the price
  response. This is the cleaner *incidence* experiment.
- **fixed real `B/P`** — the government's real liability position is common,
  which is the cleaner *fiscal* experiment.

These are different questions and the paper currently conflates them. I would
make fixed-nominal-`B` the headline (it isolates what the paper is about) and
report fixed-real-`B` alongside.

---

## 4. Claim-by-claim assessment

Status categories: **P** proved analytically; **C** calibrated (numerical,
gated, external discipline present); **X** conditional (numerical, gated, but
depends on unvalidated joint assumptions); **I** illustrative (no external
discipline, or the exercise is a diagnostic rather than a result).

| Claim | Status | Assessment |
|---|---|---|
| Financing incidence changes demand for nominal liabilities and hence the price response | **P** | The paper's real contribution. Proposition is exact and, per the code, symbolically verified. Keep as the single headline. |
| Sufficient-statistic incidence formula, with financing in the numerator and the determinacy margin in the denominator | **P** | Correct and well organized. The rewrite that restored endogenous debt service was necessary and is right. |
| Two-market Schur-complement extension | **P** | Correct generalization; collapses to the one-asset case. **But** the numerical validation of `dP/dα` is not yet passing — see §8. State it as theory now; do not cite a validated derivative. |
| Nominal neutrality; μ-neutrality; demand-determined debt | **P** | Fine. Supporting, not headline. |
| Levy more inflationary than lump-sum at the same appropriation | **C** | The robust quantitative result, and the one the paper should lead with after the theorem. Holds across every portfolio structure solved. **Must be re-established under the fixed-real program** before it can be quoted. |
| The two instruments lie on opposite sides of zero | **X** | Requires four features jointly. Honest labelling already present; needs the sign map of §3(b). Not a headline. |
| Response is ~9/10 distributional (direct term small) | **C→X** | The decomposition is exact and reconstructs to machine precision — that part is solid. Its *interpretation* is conditional because the dominant term has no external anchor. Currently overstated by placement, not by wording. |
| Announcement front-loads most of the long-run move | **C** | Robust across one-asset, frictionless two-asset and the preferred calibration — three structures with different signs, same timing. This is stronger than the paper makes it look and deserves promotion. |
| Two-asset announcement path (KV), four gates pass | **C** | Gates are real and documented. Precision is honestly banded. Fine as reported. |
| Deficit phase-in threshold (~1.4 yr) | **I** | **Not currently interpretable.** Confounds delayed taxation with permanently higher terminal debt. Withdraw the number until the 2×2 is run. |
| Multiplicity / sunspot region | **I** | The calibrated frontier never activates it. One paragraph in body, rest online. |
| Anchor insulation via indexed mandate | **I** | Off-equilibrium design insurance; the paper says so. One paragraph. |
| Optimal accommodation | **I** | An optimal-real-rate statement. Online appendix with a one-line body pointer. |
| Aggregate-risk extension | **I** | Interesting, orthogonal to the title question. Online appendix. |
| DTPL vs NK opposite signs | **I** | Cannot identify *why* signs differ; too many objects move at once. Either build the ladder or drop the contrast from the body. |
| Self-financing magnitudes | **I** | Correctly presented as frontiers. Keep in appendix. |
| Wealth-mobility validation, Layer 1 | **C** | Four definition-robust stylized facts pass. Layer 2 (quantitative comparison) blocked on data access and is not claimed. Correct as is. |

---

## 5. Revised body outline with page budgets

Target 43pp body (≈1,900 source lines at the manuscript's current density).

| § | Content | pp | Notes |
|---|---|---|---|
| 1 | Introduction, literature integrated | 8 | Four to five closest papers named; the rest become thematic sentences. Contribution list restated in the three-result order. |
| 2 | Minimal model + sufficient-statistic incidence theorem | 8 | Households, government, equilibrium, the mechanism figure. Climate sector reduced to the adaptation benchmark (~1pp); functional forms to appendix. |
| 3 | Portfolio structure, empirical discipline, calibration | 8 | Promoted and expanded. Contains the identification argument (§3(a)), the targeted/untargeted table, sensitivity, and the sign map (§3(b)). |
| 4 | Fixed-real-program financing comparison | 7 | **The headline.** Lump-sum, proportional levy, progressive levy-plus-rebate. Mean/tilt decomposition. Fixed-nominal-`B` primary, fixed-real-`B` reported. |
| 5 | Announcement dynamics; tax-timing × terminal-debt decomposition | 7 | Front-loading result, then the 2×2. NK contrast only if the ladder exists. |
| 6 | Household incidence, welfare, falsifiable predictions | 6 | Seven-component cumulative incidence figure; both rankings; three predictions with confounders. |
| 7 | Conclusion | 2 | |
| — | **Total** | **46** | Trim §1 and §7 by a page each to land at 44. |

The nominal-budget-feedback experiment (current headline) becomes a
subsection of §4, explicitly relabelled as an experiment about *budget
denomination* rather than about incidence.

---

## 6. Appendix demotion map

Exact targets, by current source location. Nothing is deleted; each keeps a
one-paragraph body summary and a pointer.

| Current location | Lines | Disposition |
|---|---|---|
| `\section{Related literature}` (L571) | 162 | Fold into §1. Keep 4–5 closest papers in text; remainder to a short thematic paragraph plus an appendix discussion. |
| `\subsection{The climate sector}` (L816) | 124 | Adaptation benchmark stays (~35 lines). Emissions/carbon-stock specification, abatement functional form, `q_g` implementation efficiency → online appendix as the *coordinated-global-mitigation robustness* case. |
| `\subsection{Determinacy}` (L1286) | 30 | One paragraph in body; the multiplicity analysis is already in `app:determinacy`. |
| `\subsection{Resource, fiscal, and revaluation accounting}` (L1519) | 112 | **Retain in body**, compressed to ~55. The BCR / fiscal self-financing / household-burden-offset distinction is what stops the paper making a misleading self-financing claim. Worked arithmetic → appendix. |
| `\subsection{Financing regimes...}` (L2221) | 143 | Keep lump-sum, proportional levy, progressive levy-plus-rebate (~85). Even mix and secondary variants → online appendix. |
| Anchor-insulation material in §Theory and §Transitions | ~40 | One paragraph; analysis to `app:determinacy`. |
| `\subsection{Optimal accommodation}` (app L5213, L5518) | — | Already appendix. Reduce body pointer to one sentence. |
| Aggregate-risk extension (app L4288) | — | Already appendix. Body pointer to one paragraph. |
| NK diagnostics (app L3997, L4065) | — | Already appendix. Body claim removed unless the ladder is built. |
| `app:numerics` (L4161) | 127 | Expand into the verification appendix of I7. |

Net body reduction from the map: ≈480 lines (≈11pp), taking the body from
69pp to ≈58pp. **The remaining 14pp must come from §4–§6 being rebuilt more
tightly than the current material they replace, not from further cutting.**
That is a rewrite, and it should happen after the new experiments exist —
otherwise we will cut text we then have to rewrite.

---

## 7. New experiments and their required controls

Marked ✅ where infrastructure already exists in the repo, ⚠️ where partial,
❌ where it must be built.

| # | Experiment | Controls held fixed | Status |
|---|---|---|---|
| X1 | **Fixed-real-program financing comparison.** Lump-sum, proportional levy, progressive levy-plus-rebate | real `g_g` path; `q_g`; discounted resource cost; initial `B`; terminal debt target; **and a stated choice of fixed-nominal vs fixed-real `B`** (§3(c)) | ⚠️ `main_regimes_fixed_real` exists and its output is currently in the supplementary appendix — this is a promotion plus a terminal-debt control, not a build from scratch |
| X2 | **Nominal-budget feedback.** Same nominal appropriation, endogenous real program | nominal `G_g`; everything else as X1 | ✅ this is the current headline, relabelled |
| X3 | **Deficit 2×2.** {contemporaneous, delayed} × {matched terminal debt, higher terminal debt}, delayed-and-matched including a consolidation path | real program; discounted revenue; initial `B` | ⚠️ the ρ_d ladder exists; matched-terminal-debt arm must be built |
| X4 | **Credibility.** Implementation probability, post-implementation reversal hazard, stochastic delay, learning about effectiveness | program scale; financing; damages | ❌ |
| X5 | **Nested NK ladder.** (i) flexible-price incomplete markets → (ii) + rigidity → (iii) + policy rule → (iv) + financing timing → (v) + RA aggregation | real investment path; financing path; climate technology; shock persistence, at every rung | ❌ (both NK models exist; the ladder and the matched controls do not) |
| X6 | **Tax anatomy.** Every schedule split into mean component and mean-zero incidence tilt | revenue; real program | ❌ |
| X7 | **Identification diagnostics.** Targeted vs untargeted moment table; local sensitivity / Jacobian; leave-one-target-out; payout-convention sensitivity; stated geography | calibration targets | ❌ |
| X8 | **Sign map** over (λ, ι_H, concentration) with the calibrated point and external ranges marked (§3(b)) | everything else at benchmark | ❌ |
| X9 | **Joint-distribution incidence.** Seven components by group, both rankings | — | ⚠️ welfare-by-group machinery exists; the seven-way split and the joint cut do not |
| X10 | **Verification appendix.** Euler errors by state; residuals normalized by output, revenue, debt service and the price movement; grid convergence at 500/750/1000; horizon at 80/120; one- vs two-asset cross-check | — | ⚠️ partly exists; normalization and the convergence ladders do not |

**Sequencing.** X1 and X3 first — they change headline numbers and therefore
change what the paper says. X7 and X8 next; they are cheap relative to their
effect on credibility. X5 and X4 last; both are large builds and neither
changes the paper's answer, only how well it is defended.

**A dependency the brief does not mention.** X1, X3 and X9 all run in the
preferred two-asset economy, whose stationary solver is currently *not*
delivering a grid-converged equilibrium: a pure grid change moved the tree
price by 7.7% and broke its monotonicity in the financing intensity, and the
root residual sits around 1e-2 while the comparative static across financing
regimes is 0.6% of the same variable. **The signal is currently smaller than
the noise.** Until that is resolved, X1 and X3 can be run in the one-asset
economy (where the solver is sound) and must be labelled as such. A
signal-to-noise driver and a recalibration-on-the-widened-grid path now exist
in the repo for exactly this purpose.

---

## 8. Annotated literature list

**Verification status.** The four references named in the brief could not be
retrieved from this environment. Each entry below states what the reference is
*needed for*; the parenthetical claims must be checked against the actual
papers before they are written into the manuscript. Do not cite any of them
in the text on the strength of this table alone.

### Directly load-bearing for the preferred calibration

| Reference | What it must inform | Check before citing |
|---|---|---|
| Gabaix, Koijen, Mainardi, Oh, Yogo | The intermediation wedge `ι_H = 0.273` and the ownership-concentration parameter; security-level evidence on direct versus intermediated household holdings | Whether the reported concentration is of *government bonds specifically*, and whether direct/indirect is measured on a basis compatible with our `ι_H` |
| Fagereng, Guiso, Ring | The adjustment frequency `λ = 0.15`; administrative evidence that portfolio responses to persistent tax-induced return changes are substantial but slow | Whether the estimated speed maps to an annual adjustment probability, and on which asset margin |
| Kaplan–Violante and the two-asset literature | The liquid/illiquid structure and the wealthy-hand-to-mouth share | Already used; check that our `div_payout = 1` convention is theirs (see below) |

**A calibration issue the numerics surfaced, which belongs in the paper.**
With `div_payout = 1`, dividends on illiquid wealth arrive as *liquid* income
that cannot be reinvested in the illiquid asset between adjustment dates. That
convention mechanically feeds the liquid tail, and it is doing real work: in
the diagnostic runs, top-of-grid liquid mass persisted at roughly 3e-3 and
fell only slowly as the grid was widened. The payout-convention sensitivity
the brief asks for in I5/X7 is therefore not a formality — we have direct
numerical evidence that this convention matters for the liquid distribution
that carries nine-tenths of the sufficient statistic.

### For the new experiments

| Reference | What it must inform |
|---|---|
| Ferrari & Nispi Landi | Credibility/expectations dimension of green-transition inflation (X4). Their mechanism differs from ours, which is precisely why credibility is a robustness dimension and not a competing explanation |
| Fiscal-foresight literature | X3: anticipated versus contemporaneous taxation as a distinct transmission channel from debt issuance |
| Carbon-pricing incidence literature | X6 and I1: which recycling schemes are policy-relevant, and the annual-versus-lifetime ranking problem in I4 |
| Hahn, Hendren, Metcalfe, Sprung-Keyser | O4: welfare accounting across climate tax and spending policies; the right frame for our resource benefit–cost measure, which is *not* a fiscal multiplier |
| Adaptation-capitalization evidence | E5/X1: `θ_g` as resilience effectiveness; implementation lags and depreciation; private capitalization and spatial spillovers as an incidence margin beyond taxpayers and bondholders |

### Already in the manuscript and correctly positioned

Hagedorn (demand theory of the price level) — the framework this extends;
Angeletos, Lian and Wolf (deficits) — the nominal channel whose sign we find
flips; Acharya et al. — optimal policy comparison; Auclert et al.
(sequence-space Jacobian) — the second solver; Leeper, Walker and Yang —
implementation efficiency `q_g`.

---

## 9. Deliverable 8 (revised abstract and introduction)

**Deferred, by instruction and on the merits.** The abstract currently leads
with the mechanism and hedges the level sign appropriately, but it will have
to be rewritten around the fixed-real-program experiment, and that experiment
does not exist yet. Writing it now would mean writing an abstract for results
we have not computed. I will draft it once §4's design is settled and X1 has
been run.

---

## 10. What I recommend doing first

1. **Decide the fixed-real experiment's design**, including the fixed-nominal
   versus fixed-real `B` question in §3(c). Everything downstream depends on
   it and it is a half-page decision, not a computation.
2. **Resolve the preferred economy's grid convergence**, or accept that X1 and
   X3 run in the one-asset economy for this draft and are labelled as such.
   The current state — signal smaller than noise — cannot support a headline.
3. **Build X7 and X8** (identification diagnostics and the sign map). They are
   cheap, they convert the paper's most-criticized conditional result into a
   measured one, and they do not depend on 1 or 2.
4. **Then** the demotion map in §6, then the rewrite of §4–§6, then the
   abstract.

Not before then: further prose compression, the NK ladder, the credibility
structure.
