# Can Green Deficits Finance Themselves?
## Climate Investment, Asset Demand, and Self-Fulfilling Price Levels in Incomplete-Markets Economies

*Research proposal. This folder contains the proposal, the formal model and results
(`MODEL_AND_THEORY.md`), and an executable MATLAB implementation built on the
Hagedorn (2026) DTPL replication package in the repository root.*

---

## 1. Research question

**Can large-scale deficit-financed public climate investment finance itself — through
the endogenous price-level response of the asset market and the damage dividend it
generates — when the price level is determined by household asset demand (the Demand
Theory of the Price Level) rather than by an active Taylor rule or the FTPL? And does
the climate–fiscal feedback loop create scope for self-fulfilling "green boom" versus
"brown stagnation" equilibria that policy design can eliminate?**

Unpacking: the green transition is, in fiscal terms, a very large and persistent
increase in *nominal* government expenditure, financed at the margin by *nominal* debt.
In heterogeneous-agent incomplete-markets economies, three recent results change how we
should think about the fiscal arithmetic of that program. First, deficits are partially
self-financing when households are non-Ricardian (Angeletos, Lian and Wolf, 2024).
Second, the price level itself is a market outcome — it clears the asset market given
household precautionary demand for safe assets (Hagedorn, 2026) — so a nominal spending
program *moves the price level*, and with it the real value of nominal debt and of the
program itself. Third, when idiosyncratic risk is endogenous to aggregate outcomes,
beliefs can be self-fulfilling (Acharya and Benhabib; Acharya and Dogra, 2020). Climate
investment sits at the intersection of all three: it is debt-financed (self-financing
question), it is nominal (price-level question), and it determines future damages and
hence future income risk (belief question). No existing paper connects these margins.

## 2. Motivation

**Policy stakes.** Estimates of the public investment required for the climate
transition run to several percent of GDP per year for decades. Whether that spending
requires future tax increases — or partially pays for itself through induced
revaluation and avoided damages — is a first-order question for its political
feasibility. The post-2020 experience of large fiscal expansions followed by an
inflation surge, and the debate over `r < g` fiscal space, both suggest that the
*nominal* side of the fiscal expansion and the *price-level* response cannot be treated
as an afterthought. At the same time, carbon policy has sharp distributional incidence,
and monetary accommodation of a green fiscal program is itself a distributional choice:
inflation is a levy on nominal asset holders, and asset holdings are concentrated.

**Scientific stakes.** The four foundations of this project have not been combined:

1. *Angeletos, Lian and Wolf (Econometrica, 2024), "Can Deficits Finance Themselves?"*
   show that with non-Ricardian households, deficit-financed stimulus is partially
   self-financing through the induced boom (tax base) and inflation erosion of nominal
   debt. Their analysis is about transitory stimulus in a New Keynesian setting; the
   green transition is a *permanent* program, and its self-financing must be evaluated
   in the long run — which is precisely where the DTPL disciplines the price level.
2. *Hagedorn (IER, 2026), "A Demand Theory of the Price Level"* shows that in
   incomplete-markets economies the steady-state price level is uniquely determined by
   asset-market clearing, `S(1+r^ss) = B/P`, once monetary policy sets `i` and fiscal
   policy sets nominal growth. Crucially, his uniqueness result for nominal rules relies
   on policy pinning the real rate and `S` being a *function* at that rate. We show
   this logic can fail when climate damages feed back into asset demand through the
   real value of the nominal green budget.
3. *Acharya, Challe and Dogra (AER, 2023), "Optimal Monetary Policy According to HANK"*
   show optimal policy trades off aggregate stabilization against consumption
   risk-sharing when policy moves idiosyncratic risk. In our economy, the analogous
   choice variable is the nominal growth rate `mu`: it is simultaneously a levy on
   concentrated bond wealth and — through the price level — a determinant of real green
   investment, hence of damages and of the income risk households face.
4. *Acharya and Benhabib, "Self-Fulfilling Fluctuations in HANK Economies" (NBER WP
   32462; AER)* show that endogenous idiosyncratic risk generates belief-driven
   multiplicity in HANK. We find the steady-state analog: the *price level itself* can
   be indeterminate across a "green" and a "brown" steady state when the climate–fiscal
   feedback is strong, because expected damages move precautionary asset demand, which
   moves the price level, which moves real green investment, which determines damages.

The determinacy literature (Sargent and Wallace, 1975; Leeper, 1991; Sims, 1994;
Woodford, 1995; Cochrane, 2023) is silent on climate feedback loops, and climate–macro
work in the tradition of Golosov, Hassler, Krusell and Tsyvinski (2014), Nordhaus
(2017) and Barrage (2020) abstracts from nominal determinacy altogether. This project
occupies that empty intersection.

## 3. Introduction (draft)

We ask whether green deficits finance themselves, and what they do to the price level.
Our laboratory is a Bewley–Huggett incomplete-markets economy (Bewley, 1980; Huggett,
1993; Aiyagari, 1994) in which the price level is a market-clearing object in the sense
of Hagedorn (2026): households hold nominal government bonds for precautionary reasons,
fiscal policy sets the growth rate of nominal debt and nominal green spending, monetary
policy sets the nominal interest rate, and the price level adjusts so that the real
supply of government liabilities equals aggregate asset demand.

We add a climate block in the spirit of the integrated-assessment tradition, reduced to
its minimal general-equilibrium content: carbon damages scale endowments by `(1-D)`,
public green (abatement) capital reduces damages, and green capital is maintained by
*real* green investment `g_g = G_g/P` — the real value of a *nominal* budget line.
This single link — nominal budget, real abatement — generates all of our results. A
second, optional link makes damages raise the *dispersion* of idiosyncratic income
risk, importing the risk channel of Acharya, Challe and Dogra (2023) and Acharya and
Benhabib.

Our contributions come as five results, developed formally in `MODEL_AND_THEORY.md`:

- **Proposition 1 (Green determinacy).** Without climate feedback (or with an indexed
  green budget), the green steady state exists and the price level is unique under the
  same conditions as in Hagedorn: the abatement-capital equation adds one real equation
  that pins `K_g`, exactly as physical capital does in his extension, and asset-market
  clearing still pins `P`.
- **Proposition 2 (Self-financing green deficits).** A permanent green program financed
  by nominal debt is *partially self-financed* by two channels that require no future
  tax increase: (i) a **revaluation channel** — the program raises the price level,
  eroding the real interest burden on nominal debt and levying a one-time real capital
  loss on bondholders — the steady-state counterpart of the inflation-erosion channel
  in Angeletos, Lian and Wolf (2024); and (ii) a **damage dividend** — avoided damages
  raise mean endowments one-for-one. We define the self-financing share `nu` and
  decompose it exactly; full self-financing (`nu >= 1`) obtains when the marginal
  damage abatement per unit of real green spending, `kappa = |D'(K_g)|/delta_g`, plus
  the equilibrium revaluation term, exceeds one. The incidence is progressive on the
  wealth margin: the levy falls on bondholders, who sit at the top of the wealth
  distribution.
- **Proposition 3 (Climate sunspots).** Under a nominal green budget with strong damage
  feedback, the asset market admits (at least) two steady states: a *green boom* (low
  `P`, high real abatement, low damages and risk, high asset demand) and a *brown
  stagnation* (high `P`, low abatement, high damages and risk). Beliefs about the price
  level select the climate trajectory. This is the steady-state, price-level analog of
  self-fulfilling fluctuations in HANK economies, operating through the DTPL asset
  market rather than an interest-rate rule.
- **Proposition 4 (Anchor insulation; rule-ranking reversal).** Indexing the green
  budget (a *real* green mandate) while keeping debt nominal removes the damage channel
  from the demand elasticity and restores uniqueness. This *reverses* Hagedorn's rule
  ranking for the spending line: without climate feedback, nominal-growth rules
  guarantee uniqueness regardless of the shape of asset demand; with feedback, the
  guarantee survives only for indexed spending. Full indexation of *everything* is a
  Sargent–Wallace corner: it removes the nominal anchor and P becomes indeterminate.
  Determinacy requires a nominal anchor that is *insulated from the climate loop*.
- **Proposition 5 (Optimal accommodation).** The optimal nominal growth rate `mu*`
  trades off the bondholder levy and tax relief for constrained households (the
  risk-sharing motive of Acharya, Challe and Dogra, 2023) against the erosion of real
  green spending (damages and risk up). With bond wealth more concentrated than income
  and the risk channel active, `mu* > 0` strictly: some inflation is an efficient part
  of green finance.

Methodologically, everything is computed with global heterogeneous-agent tools — value
function iteration, exact stationary distributions, and root-finding on the
asset-market condition — building directly on the replication package for Hagedorn
(2026) in this repository, and consistent with the sequence-space tradition of Auclert,
Bardóczy, Rognlie and Straub (2021) and the HANK tradition of Kaplan, Moll and Violante
(2018) for the planned transition-dynamics extension.

## 4. Related literature

Fiscal price-level determination: Leeper (1991), Sims (1994), Woodford (1995), Cochrane
(2023) — we differ because fiscal policy is passive and the price level clears the
asset market (DTPL), not the government valuation equation. Determinacy in HA models:
Hagedorn (2026), Acharya and Dogra (2020), Bilbiie's analytical HANK framework — we add
a physical (climate) state that feeds back into asset demand. Self-financing deficits:
Angeletos, Lian and Wolf (2024) — we provide the permanent-program, steady-state
counterpart with an exact decomposition. Optimal policy in HANK: Acharya, Challe and
Dogra (2023) — our inflation-choice problem inherits their risk-sharing tradeoff.
Self-fulfilling equilibria in HANK: Acharya and Benhabib; Ravn and Sterk (2021) — our
multiplicity is in the steady-state price level and climate stock. Climate–macro:
Golosov, Hassler, Krusell and Tsyvinski (2014), Nordhaus (2017), Barrage (2020) — we
add nominal determinacy and incomplete markets.

## 5. Empirical motivation

The replication package's Figure 5 documents (for 34 OECD countries) that long-run
average inflation lines up with the average growth of nominal government expenditure
relative to real GDP with a slope close to one — prima facie evidence for the
nominal-expenditure anchor at the heart of the DTPL. The green transition is precisely
a large, persistent shift in nominal government expenditure; through the lens of the
theory, how it is *denominated* (nominal budgets versus indexed mandates) is not an
accounting detail but a determinant of inflation, determinacy, and the fiscal burden.

## 6. Anticipated referee objections — and answers

1. **"Steady-state analysis only."** True; our determinacy and self-financing results
   are about stationary equilibria, deliberately, because that is where the DTPL
   disciplines the price level independently of stability arguments. The transition
   dynamics extension (sequence-space Jacobians around each steady state; Auclert et
   al., 2021) is the natural next step and Proposition 3's two steady states are its
   boundary conditions.
2. **"Lump-sum taxes."** Chosen to isolate the revaluation and damage channels from
   distortionary-taxation effects (Barrage, 2020, shows those interactions matter; they
   are complementary). The self-financing share `nu` would only rise with distortionary
   taxes if avoided damages relax marginal rates.
3. **"Endowment economy."** The DTPL machinery extends to production (the root package
   implements Hagedorn's capital extension); the endowment version makes the
   asset-demand mechanism transparent. Adding capital adds one real equation and does
   not change determinacy — Proposition 1 already covers the parallel argument.
4. **"No aggregate shocks."** Multiplicity here is across steady states; Acharya and
   Benhabib show how endogenous risk turns such multiplicity into sunspot *dynamics*.
   Our Proposition 3 gives the fixed points between which such dynamics would move.
5. **"Calibration of the damage feedback `theta_g`."** We do not claim to know it; we
   report the threshold `theta_bar` at which multiplicity appears and the sensitivity
   of `nu` to `theta_g` (both generated by the code), and we flag the mapping from
   integrated-assessment damage functions to `theta_g` as the key measurement task.

## 7. Deliverables and road map

**In this folder now:** formal model with lemmas/propositions/corollaries and proof
sketches (`MODEL_AND_THEORY.md`); executable MATLAB package (`main_project_run_all.m` +
`src_project/`) producing four project figures (PFig1–PFig4) and a results table; all
numbers in the documents marked as generated-by-code, never hard-coded.

**To full paper:** (i) transition dynamics between the two steady states of
Proposition 3 (sequence-space); (ii) production economy with green *and* brown capital;
(iii) distortionary taxes and an optimal carbon-price companion instrument;
(iv) calibration of `theta_g` to integrated-assessment damage schedules;
(v) cross-country evidence extending Figure 5 by the greenness of public investment.

**Target outlets:** general-interest top-5, with the theory (Propositions 3–4:
climate sunspots and anchor insulation) as the headline and the quantitative
self-financing decomposition (Proposition 2) as the applied payoff.
