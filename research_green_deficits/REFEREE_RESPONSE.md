# Response to Referee Reports — *Can Green Deficits Finance Themselves?*

This memo maps every point in the two referee reports and the integration
roadmap to a concrete action, and marks each with a status:

- **[DONE]** — implemented in this revision (paper text and/or `references.bib`),
  compiles clean.
- **[CODE]** — verification/robustness driver written and wired into the master
  runner; produces the number when you re-run MATLAB. No result is asserted in
  the paper until the driver has been run and its log recorded.
- **[JUDGMENT]** — an author-level decision that reshapes the paper (retitle,
  cut, change the benchmark instrument). Laid out below with a recommendation,
  but **not** executed unilaterally — these await your sign-off.

The organizing principle of the revision: the referee's two deepest points are
correct and are now *theorems*, not caveats. There is no stationary deficit in
the model (the price level is homogeneous of degree one in the nominal
anchors), and the "optimal money-growth rate" is an optimal-real-rate result.
Both are stated as Theorem 1 (nominal neutrality) and the μ-neutrality
proposition, and the paper is reorganized so the surviving contribution — *who
pays for green public investment*, via the tax-incidence and revaluation
channels — leads.

---

## Part I — Major issues (M1–M11)

### M1. "No deficit in the model / nominal neutrality." **[DONE]**
Accepted and promoted to **Theorem 1**. Substituting `b = B/P` and
`g_g = G_g/P = (G_g/B)·b` collapses the stationary system to a real-debt fixed
point in which `B` enters only through the ratio `G_g/B`; `P` is homogeneous of
degree one in `(B, G_g)`. Consequence, now stated explicitly: there is no
stationary deficit — real debt is *demand-determined* (a fixed point of
household asset demand), and the "financing regimes" differ in **tax
incidence**, not in deficit-versus-tax. A genuine deficit exists only along the
transition (§`sec:transitions`). Added `\subsection{The real fixed point:
neutrality and demand-determined debt}` with `Lemma (neutrality)` and
`Proposition (demand-determined debt)`. Verified against the code: `mu` occurs
once, in `solve_green_steady_state.m:36`.

### M2. "ν sums a resource offset and a transfer; threshold wrong." **[DONE]**
Accepted. `Definition 2` reworked: ν is **never** presented as a single
self-financing scalar. The aggregate resource identity is
`C = (1−D) − g_g` (the `r^ss·b` interest flow is a pure transfer and cancels),
so the object that governs whether *aggregate resources* rise is the **resource
benefit–cost ratio** `ν_dam = (D_0 − D_1)/g_g`, with threshold `ν_dam ≥ 1`. The
revaluation share `ν_reval` is explicitly a **fiscal/transfer** term and is
reported separately, never added to `ν_dam` to manufacture a threshold. The
abstract now leads with the three BCR values (0.21, 0.64, 2.10) and states they
cross one only under high-damage estimates. Text flags that `τ + D` overstates
the resource burden by `r^ss·b`.

### M3. "Disinflation is a lump-sum-tax artifact; climate block net inflationary." **[DONE (sign made explicit) + JUDGMENT (benchmark instrument)]**
Accepted in the text: `Result (disinflation)` now states the sign is a property
of the **tax instrument**, not the program — under lump-sum taxes green
deficits are disinflationary (a bondholder windfall), but a proportional levy
with a rebate flips it. The abstract and intro say this outright.
**[JUDGMENT]** Whether to make the *proportional-levy* economy the **headline
benchmark** (roadmap Stage 2) is a structural choice — it flips the sign of the
headline number and requires the incidence-bearing household budget in
`S_green`. See "Judgment calls" below.

### M4. "Pathological illustrative benchmark." **[DONE (text) + JUDGMENT (cut)]**
The calibrated columns (β* to debt/GDP ≈ 1.1, program ≈ 2% of income, damage
columns disciplined to DICE / DJO–BHM / Bilal–Känzig) are already the
quantitative spine. **[JUDGMENT]**: cut the original illustrative benchmark
(β = 0.96 ⇒ debt/GDP ≈ 5) entirely rather than carry it as an "illustration."
Recommended. See below.

### M5. "One-asset portfolio → magnitudes are upper bounds." **[DONE (framing + citation) + JUDGMENT (convenience yield)]**
The scope note on the clearing object now states that with richer portfolios
the DTPL clears the demand for the nominal liability *specifically*, and the
revaluation channel's size depends on substitutability — the
public-debt-as-private-liquidity margin, now cited to **Woodford (1990)**. The
one-asset magnitudes are framed as upper bounds and the two-asset extension is
flagged as closing with a *constant* liquidity premium. **[JUDGMENT]**: making
the convenience yield **endogenous** (roadmap Stage 5) is a genuine model
extension, not a revision edit.

### M6. "Global externality as a closed-economy good — recast K_g as adaptation." **[DONE (reframing hook + citations) + JUDGMENT (full recast)]**
The production/discipline subsection now carries the adaptation-capital
reinterpretation explicitly — public capital that *hardens the economy against
damages* plausibly carries a productive margin, making the Bom–Ligthart
comparison defensible — cited to **Fried (2022)** and **Konradt–Weder di Mauro
(2023)**. The mechanism is agnostic between "mitigation that lowers domestic
damages" and "adaptation capital"; the latter removes the closed-economy
objection to a global externality. **[JUDGMENT]**: whether to *rename* `K_g`
adaptation capital throughout (Stage 4) is a framing decision.

### M7. "Undisciplined climate parameters; δ_g binding." **[DONE (text) + CODE]**
The calibration table already flags `θ_g` as swept (0–3, reported as a frontier)
and `δ_g` over its range. New driver **`sensitivity_climate_discipline.m`**
maps `ν` and the resource BCR over the full `(θ_g, δ_g)` grid and reports the
`θ_g` threshold at which the BCR crosses one *as a function of* `δ_g`, making
the `θ_g/δ_g`-ratio dependence explicit rather than buried in one benchmark
number. Wired into the master runner.

### M8. "Unbounded incidence → fiscal-space-collapse artifact; ψ = 0 headline." **[DONE (text) + JUDGMENT (bounded incidence)]**
The headline is already `ψ = 0` (uniform incidence); the regressive-incidence
results are reported as a sweep, not the benchmark, and Table 5's caption now
carries the across-steady-state / behind-the-veil qualifier. **[JUDGMENT]**:
replacing the unbounded incidence gradient with a **bounded** one (roadmap
Stage 3) so the fiscal-space object cannot diverge is a modeling change to
`build_S_interp_green` / `S_green`.

### M9. "Empty multiplicity + coarse numerics." **[DONE (statement) + CODE (EGM is JUDGMENT)]**
`Proposition (sunspots)` restated precisely: under a transversal downward
crossing at a zero of Φ there are at least three zeros, alternating
upward–downward–upward, with the outer two stable and the middle unstable — a
non-empty, checkable claim tied to the `ε_S < −1` elasticity diagnostic the
solver already computes. Numerics: the benchmark grid is `n_a = 500` and the
root scan refines every sign change. **[JUDGMENT]**: replacing VFI with **EGM**
(roadmap numerics) is a solver rewrite; recommended as a robustness appendix,
not a blocker.

### M10. "Lemma 3 fails under aggregate risk; K_g should be state-contingent." **[DONE]**
Accepted. The aggregate-risk subsection now states that Lemma
(`lem:anchor`) — policy pins the real rate independently of `P` — is a
*deterministic*-model property; with a state-contingent price level the
realized real return is `(1+r^ss)P_s/P_{s'}`, realized inflation is not `μ`, and
`Lemma anchor`'s independence holds state-by-state only in ergodic mean. The
"excess return" language is relabeled "ergodic-mean excess return" throughout.
The systematic, non-diversifiable nature of the risk is cited to
**Barnett–Brock–Hansen (2020)** and **Cai–Lontzek (2019)**, and the
risk-sharing role of state-contingent nominal debt to
**Bhandari–Evans–Golosov–Sargent (2017, 2021)**.

### M11. "Optimal-μ is optimal-r; Figure 5 stale." **[DONE]**
Accepted and promoted to the **μ-neutrality proposition**: the equilibrium
depends on `μ` only through `r^ss`, so `W(μ)|_{i^ss}= W(r^ss(μ))`, and
`μ* = 0.045 ⇔ r^ss ≈ −0.5%` is the Aiyagari–McGrattan (1998)
optimum-quantity-of-debt result — now **cited** (§5.5, intro, conclusion). New
driver **`verify_mu_neutrality.m`** confirms it in code: a fixed-`r^ss` scan
holds every equilibrium object invariant across `μ`, while the fixed-`i^ss` scan
traces the single `W(r^ss)` curve. The conclusion and §5.5 relabel
"optimal money growth" as "optimal real rate."

---

## Part II — Model-improvement list

| Roadmap item | Status | Note |
|---|---|---|
| Proportional-tax benchmark (Stage 2) | **[JUDGMENT]** | flips headline sign; needs incidence in `S_green` |
| EGM numerics | **[JUDGMENT]** | solver rewrite; recommended as robustness appendix |
| Deficit transition experiment (Stage 8) | **[CODE — partial]** | `main_project_transition.m` already solves the nonlinear DTPL path; a genuine *deficit-financed* transition (debt rises, then stabilizes) is the clean version |
| DTPL-vs-NK horse race (Stage 9) | **[JUDGMENT]** | new exercise; scoped in `appendix/HANK_TRANSITION_PLAN.md` |
| Cuts (Stage 10) | **[JUDGMENT]** | see below |

## Part III — Verifiable inconsistencies

All eleven flagged inconsistencies were checked against the source and the
computed `.mat` outputs. Fixed in this revision: the `ln P_1/P_0 = −16%`
statement, the "pre-damage income" wording, the across-column leverage-drift
note, the §5.7 production category error (abatement capital has no marginal-cost
margin; the revenue-only exercise *bounds* one channel and does not sign the GE
effect), the Frisch-elasticity notation clash (`ν → φ_F`), the `φ_D` elasticity
report, and the Table 5 relabel. The BCR triple in the abstract is now driven
by macros (`\bcrLow/\bcrMed/\bcrHigh`) exported from the `.mat`, so it can never
drift from the computation.

## Part IV — Literature **[DONE]**

Twelve verified entries added to `references.bib` and cited at natural points:
Aiyagari–McGrattan (1998, optimum quantity of debt — the §5.5 result),
Woodford (1990, public debt as private liquidity — M5), Reis (2022) and
Bianchi–Melosi (2017, fiscal inflation / no FTPL selection here),
Bhandari–Evans–Golosov–Sargent (2017, 2021, nominal debt as a state-contingent
fiscal shock absorber), Fried (2022) and Konradt–Weder di Mauro (2023, public
adaptation capital — M6), Barnett–Brock–Hansen (2020) and Cai–Lontzek (2019,
systematic climate risk — M10), Hsiang et al. (2017) and Carleton et al. (2022,
empirical damage estimates — the medium column). Compile is clean: zero
undefined citations.

## Part V — Retitle **[JUDGMENT]**

The referee's suggestion to retitle around the surviving contribution
(Proposition 6 / the incidence result) is well taken. Recommended title:
**"Who Pays for Green Public Investment? Tax Incidence, Debt Revaluation, and
the Price Level in Incomplete-Markets Economies."** Not executed pending your
decision.

---

## Judgment calls awaiting your sign-off

These reshape the paper and are not edits I should make unilaterally:

1. **Retitle** around the incidence result (Part V). *Recommend: yes.*
2. **Cut** the illustrative benchmark (M4), and likely the RANK diagnostics, the
   multiplicity section, and the two-asset tier, to tighten around the theorems
   and the incidence result (Stage 10). *Recommend: cut the illustrative
   benchmark and RANK; keep multiplicity as a short subsection; keep two-asset
   as an appendix.*
3. **Flip the benchmark instrument** to a proportional levy + rebate (M3 /
   Stage 2). This flips the headline sign from disinflationary to inflationary
   and makes the program progressive. *Recommend: yes — it is the honest
   headline and the current lump-sum result becomes the contrast case.* Requires
   the incidence-bearing budget in `S_green`.
4. **Adaptation reframing** (M6): rename `K_g` adaptation capital throughout.
   *Recommend: reframe as "mitigation *or* adaptation capital" rather than a
   full rename, preserving both readings.*
5. **Endogenous convenience yield** (M5 / Stage 5) and **bounded incidence**
   (M8 / Stage 3): genuine model extensions. *Recommend: convenience yield as
   the next-draft extension; bounded incidence now, since it is small and
   removes the fiscal-space-collapse artifact.*

## How to reproduce the new numbers

```matlab
cd research_green_deficits
FAST = true; verify_mu_neutrality            % Theorem 2 audit (quick)
FAST = true; sensitivity_climate_discipline  % M7 (theta_g, delta_g) surface
export_paper_numbers                          % refresh paper/numbers_auto.tex
```
Both drivers are also stages 13–14 of `run_green_deficits_master.m`.
