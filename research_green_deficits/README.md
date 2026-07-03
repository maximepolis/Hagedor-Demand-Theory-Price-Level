# Research project: Can Green Deficits Finance Themselves?

*Climate Investment, Asset Demand, and Self-Fulfilling Price Levels in
Incomplete-Markets Economies.*

This folder contains a self-contained research project built on the Hagedorn
(2026) "Demand Theory of the Price Level" replication package in the repository
root. It combines four literatures into one framework:

| Foundation | What we take | Where it shows up |
|---|---|---|
| Hagedorn (IER 2026), *A Demand Theory of the Price Level* | `P* = B/S(1+r)`: the price level clears the asset market | the backbone: every equilibrium is a root of `Phi(P) = S - B/P` |
| Angeletos, Lian & Wolf (Econometrica 2024), *Can Deficits Finance Themselves?* | deficits partly self-finance via booms + inflation erosion | Proposition 2: the self-financing share `nu = nu_reval + nu_damage` |
| Acharya, Challe & Dogra (AER 2023), *Optimal Monetary Policy According to HANK* | policy moves idiosyncratic risk; risk-sharing motive | the risk channel `sig_eps(D)` and Proposition 5 (optimal `mu`) |
| Acharya & Benhabib (NBER WP 32462 / AER), *Self-Fulfilling Fluctuations in HANK Economies* | endogenous risk creates belief-driven multiplicity | Proposition 3: green-boom vs brown-stagnation price levels |

plus the fiscal-theory positioning (DTPL vs FTPL vs Taylor) and a climate block
in the integrated-assessment tradition.

## Contents

```
PROPOSAL.md              research question, motivation, introduction, literature,
                         referee objections, road map
MODEL_AND_THEORY.md      formal model; Definitions 1-3; Lemmas 1-3;
                         Propositions 1-5; Corollaries 1-3; proof sketches;
                         theory-to-code map
paper/
  green_deficits_price_level.tex   FULL JOURNAL-ARTICLE DRAFT (top-journal
                         format): abstract, introduction, literature review,
                         model with in-depth climate sector (carbon stock,
                         emissions, damages with incidence gradient), all
                         lemmas/propositions/corollaries WITH PROOFS,
                         quantitative section using the benchmark run's
                         numbers, empirical section (E1-E3), appendices
  references.bib         bibliography (verified references only)
main_project_run_all.m   baseline experiments (Props 1-5, PFig1-4)
main_project_extended.m  EXTENDED experiments: carbon-stock sector +
                         incidence gradient, sunspot frontier over (psi, Gg),
                         extended self-financing, empirical anchor (PFig5-6)
src_project/
  setup_params_green.m   project calibration (extends root setup_params)
  climate_block.m        version 1: D = D0*exp(-theta_g*Kg)
  climate_block2.m       version 2: carbon stock X = E/delta_x, emissions,
                         damages D = Dmax*(1-exp(-gamma_x*X)) (fixed point)
  S_green.m              S(1+r; tau, D) + welfare + Ginis; damage-incidence
                         gradient chi(e) = e^(-psi)/E[e^(1-psi)]
  build_S_interp_green.m S on a (tau,D) grid -> bilinear interpolant
  solve_green_steady_state.m  all roots of Phi(P)=0, eps_S(P) diagnostic,
                         climate version switch
  self_financing_decomposition.m  nu decomposition + theta_g sweep
  optimal_policy_green.m W(mu) and the optimal accommodation mu*
  plot_green_figures.m   PFig1-PFig4
  empirical_anchor.m     E1: OLS + HC1 robust SEs, Wald test of slope=1
                         on the repo's OECD data (PFig5); no fabricated data
  load_green_budget_data.m  E2 loader: documented CSV schema for the
                         green-budget panel; skips gracefully if absent
output/                  figures/, tables/, logs/ (generated)
```

## How to run

From MATLAB, with this folder as the working directory (the scripts add the
repo root `src/` to the path themselves):

```matlab
>> main_project_run_all               % baseline experiments (na=500)
>> main_project_extended              % extended sector + empirics (na=500)
>> FAST = true; main_project_run_all  % quick pass (na=100)
```

To compile the article: `pdflatex green_deficits_price_level`, `bibtex`,
then `pdflatex` twice, inside `paper/` (figures are pulled from
`../output/figures/`; missing ones are skipped automatically).

## The five results (see MODEL_AND_THEORY.md for exact statements)

1. **Green determinacy** — the abatement block does not break Hagedorn's
   price-level determinacy (parallel to his capital extension).
2. **Self-financing green deficits** — exact decomposition
   `nu = nu_reval + nu_damage`; full self-financing iff `nu >= 1`; the
   revaluation part is a one-time levy on (wealth-concentrated) bondholders.
3. **Climate sunspots** — with a strong damage feedback, a *nominal* green
   budget admits green-boom and brown-stagnation price levels; beliefs select.
4. **Anchor insulation** — indexing the green budget (real mandate) while
   keeping debt nominal restores uniqueness: a reversal of the nominal-vs-real
   rule ranking for the spending line, with the Sargent-Wallace corner
   (index everything => no anchor) as the boundary case.
5. **Optimal accommodation** — utilitarian optimal nominal growth `mu*`
   trades the bondholder levy against real-green-spending erosion.

## Research-program layer (top-journal upgrade)

```
run_green_deficits_master.m   ONE-COMMAND master run: baseline + extended +
                              consolidated status/parameter record
MODEL_STATUS.md               block-by-block audit with labels: IMPLEMENTED /
                              PARTIALLY IMPLEMENTED / PROPOSED / PLACEHOLDER /
                              NOT YET IMPLEMENTED
LITERATURE_MATRIX.md          annotated bibliography in 7 blocks (A-G):
                              competitors vs building blocks vs calibration vs
                              validation vs policy sources; verification queue
ROADMAP.md                    submission-ready vs preliminary; upgrade steps
                              U1-U10 with the submission decision rule
referee_memo/REFEREE_MEMO.md  pre-emptive answers to 10 top-journal objections
appendix/CALIBRATION_APPENDIX.md  every parameter -> status + data source;
                              low/medium/high climate-damage plan; known
                              calibration tensions stated openly
dynare/green_rank_nk.mod      RANK-NK transition skeleton (PARTIALLY
                              IMPLEMENTED; see dynare/README.md for scope)
```

**Central contribution (one sentence).** Green deficits are not Ricardian
fiscal expansions: with nominal public liabilities, climate-dependent income
risk, and green public capital, the price level and the real fiscal burden of
climate investment are jointly determined by household demand for safe
nominal assets — a new fiscal arithmetic of green investment and a new
rule-design problem.

**Quantitative-scope statement (project standard #5).** Every quantitative
result to date is a STEADY-STATE result. Transition dynamics exist only as
the RANK-tier Dynare skeleton; HANK transitions and aggregate risk are NOT
YET IMPLEMENTED. See MODEL_STATUS.md.

## Honesty notes

- All quantitative statements in the documents are placeholders until
  generated by `main_project_run_all` (which writes
  `output/tables/project_summary.txt`).
- The climate calibration (`D0, theta_g, delta_g, phi_D`) is illustrative; the
  threshold at which Proposition 3's multiplicity appears is an output, not an
  assumption.
- The theory is stated in sign-agnostic elasticity form because the benchmark's
  measured `dS/dtau > 0` differs from the sign in Hagedorn's Result 1 (which
  holds under his conditions); the code *measures* `eps_S(P)`.
