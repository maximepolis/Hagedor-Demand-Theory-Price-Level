# Literature matrix

*Annotated bibliography grouped into the seven blocks of the research program.
Columns: role = **COMPETITOR** (direct), **BLOCK** (methodological building
block), **CALIB** (calibration source), **VALID** (empirical validation),
**POLICY** (policy/institutional). "Cite in" lists paper sections
(I=introduction, L=lit review, M=model, C=calibration appendix, E=empirics).
Verification: **[v]** = verified in this project (web-checked or in-repo),
**[k]** = standard reference, confident, **[u]** = user-supplied, NOT yet
independently verified — verify before citing in a submission. Never cite an
[u] item in the draft until verified.*

## A. Price-level determination (DTPL / FTPL / HA)

| Paper | Role | Mechanism | Relation to project | Gap remaining | Cite in |
|---|---|---|---|---|---|
| Hagedorn, *A Demand Theory of the Price Level*, IER 2026 [v: in repo] | **COMPETITOR** | P clears the asset market in incomplete markets; nominal growth pins inflation | the analytical backbone; we add the climate loop and show his nominal-rule uniqueness can fail | no physical state feeding back into S | I, L, M |
| Kaplan, Nikolakoudis & Violante, *Price Level and Inflation Dynamics in Heterogeneous Agent Economies* [u — verify exact outlet/year] | **COMPETITOR** | HA + nominal debt price-level/inflation dynamics | closest modern HA nominal-debt benchmark; our steady-state object is their long-run anchor | no climate block; no spending-denomination margin | I, L, M |
| Cochrane, *The Fiscal Theory of the Price Level*, Princeton UP 2023 [k] | BLOCK | valuation equation under active fiscal | the contrast theory; our fiscal policy is passive | — | L, M |
| Woodford, *Fiscal Requirements for Price Stability* (JMCB 2001) [k] | BLOCK | fiscal underpinnings of price stability | regime taxonomy | — | L |
| Leeper 1991 (JME) [k] | BLOCK | active/passive regime classification | our policy mix is M-active/F-passive | — | L, M |
| Sargent & Wallace, *Some Unpleasant Monetarist Arithmetic* (1981) + 1975 JPE [k] | BLOCK | missing-anchor indeterminacy; fiscal limits to monetary control | Corollary "missing-anchor corner"; fiscal-space collapse echoes unpleasant arithmetic | — | L, M |
| Höfer, *Price Levels in Heterogeneous-Agent Models* [u — UNVERIFIED; do not cite until located] | BLOCK? | reported: multiplicity math in HA fiscal-theory settings | would discipline our Proposition 3 statement | verify existence/outlet first | (L after verification) |

## B. Self-financing deficits / HANK fiscal / safe assets

| Paper | Role | Mechanism | Relation | Gap | Cite in |
|---|---|---|---|---|---|
| Angeletos, Lian & Wolf, *Can Deficits Finance Themselves?*, Econometrica 2024 [v] | **COMPETITOR** | non-Ricardian boom + inflation erosion self-finance transitory deficits | we do the permanent-program steady-state version; benchmark finds the erosion channel REVERSED (green disinflation) | permanent programs, endogenous long-run P, climate | I, L, M |
| Auclert, Rognlie & Straub, *Fiscal and Monetary Policy with Heterogeneous Agents* [u — verify outlet: NBER/handbook] | BLOCK | HANK fiscal-monetary toolkit | transition-dynamics blueprint | — | L |
| Kaplan, Moll & Violante, AER 2018 [v: bib] | BLOCK | HANK monetary transmission, MPC heterogeneity | household-block realism targets | — | L, C |
| Auclert, Bardóczy, Rognlie & Straub, Econometrica 2021 [k] | BLOCK | sequence-space Jacobians | the planned HANK transition method | — | L, App |
| Aiyagari & McGrattan, *The Optimum Quantity of Debt* (JME 1998) [k] | BLOCK/CALIB | welfare-optimal debt with incomplete markets | our W(mu) exercise is a nominal-growth analog | — | L, M |
| Krishnamurthy & Vissing-Jorgensen, *The Aggregate Demand for Treasury Debt* (JPE 2012) [k] | CALIB/VALID | convenience yield; downward demand for Treasuries | disciplines the PROPOSED liquidity channel of nu | channel not yet in model | L, C |
| Bayer, Born & Luetticke, *The Liquidity Channel of Fiscal Policy* (JME) [k] | BLOCK | liquidity effects of debt supply in HANK | same | — | L |

## C. HANK optimal policy / endogenous risk / self-fulfilling

| Paper | Role | Mechanism | Relation | Gap | Cite in |
|---|---|---|---|---|---|
| Acharya, Challe & Dogra, AER 2023 [v] | BLOCK | optimal MP trades aggregate vs risk-sharing | our Prop. 5 inherits the tradeoff; instrument is mu | — | I, L, M |
| Acharya & Benhabib, *Self-Fulfilling Fluctuations in HANK* (NBER 32462/AER) [v] | **COMPETITOR** (for Prop. 3) | endogenous risk => belief-driven multiplicity | our multiplicity is across steady states via the climate stock | dynamics between our steady states | I, L, M |
| Acharya & Dogra, Econometrica 2020 [k] | BLOCK | PRANK determinacy with risk | elasticity language for eps_S | — | L |
| Bilbiie, *Monetary Policy and Heterogeneity* (REStud) [k] | BLOCK | analytical HANK determinacy map | compact statement of channels | — | L |
| Ravn & Sterk, JEEA 2021 [k] | BLOCK | unemployment-risk feedback loops | template for endogenous-risk loops | — | L |

## D. Climate macro / IAM / transition inflation

| Paper | Role | Mechanism | Relation | Gap | Cite in |
|---|---|---|---|---|---|
| Nordhaus (DICE; PNAS 2017) [v: bib] | CALIB | damage functions, SCC | LOW (conservative) damage calibration | — | L, C |
| Golosov, Hassler, Krusell & Tsyvinski, Econometrica 2014 [k] | BLOCK/CALIB | tractable IAM in GE | emissions/damage structure | — | L, M, C |
| Acemoglu, Aghion, Bursztyn & Hemous, AER 2012 [k] | BLOCK | directed technical change, clean/dirty | PROPOSED two-sector extension | not yet modeled | L |
| Barrage, REStud 2020 [v: bib] | BLOCK | climate + distortionary fiscal | referee risk #3 (distortionary taxes) | to implement | L, M |
| Dell, Jones & Olken (AEJ:Macro 2012) [k] | CALIB/VALID | temperature-growth regressions | MEDIUM damage discipline | — | C, E |
| Burke, Hsiang & Miguel (Nature 2015) [k] | CALIB | nonlinear temperature damages | MEDIUM damage discipline | — | C |
| Bilal & Känzig (NBER 32450) [v] | CALIB | global-temperature damages, much larger | HIGH damage robustness case | — | C |
| Del Negro, di Giovanni & Dogra, NY Fed SR 1053 [v] | **COMPETITOR** (nominal side) | multi-sector NK: is transition inflationary? | short-run sticky-price complement to our long-run result; our sign can differ | steady-state anchor absent there | I, L |
| Nakov & Thomas, *Climate-Conscious Monetary Policy* [u — verify] | BLOCK | MP with climate externalities | regime-comparison design | verify outlet | (L) |
| Economides & Xepapadeas [u — verify] | BLOCK | NK + climate stabilization | same | verify | (L) |
| Sahuc, Smets & Vermandel, *The New Keynesian Climate Model* [u — verify] | BLOCK | estimated NK climate | Dynare-skeleton benchmark | verify | (L) |

## E. Climate fiscal sustainability / green fiscal rules

| Source | Role | Relation | Cite in |
|---|---|---|---|
| IMF, *Public Debt Dynamics during the Climate Transition* [u — institutional; locate exact WP/FM chapter] | **COMPETITOR** (policy) | argues spending-heavy strategies worsen debt absent carbon pricing; we test this with revaluation + endogenous safe-asset demand — benchmark partially overturns it (nu=0.6 of cost self-financed) and partially confirms it (theta_g below ~0.5 implies nu<0: worse than sticker price) | I, L, POLICY |
| IMF, *Green Fiscal Rules?* + Fiscal Monitor *Climate Crossroads* [u — institutional] | POLICY | rule-design competitor; our anchor-insulation corollary is a concrete rule proposal | L, POLICY |
| Banque de France (Dees & Seghini), *The Green Transition and Public Finances* [u] | POLICY | European fiscal framing | L |
| IEA *Net Zero by 2050*; NGFS scenarios; OECD green finance [k: institutional] | CALIB | program-size calibration for Gg (percent-of-GDP green investment paths) | C |

## F. Distributional climate policy

| Paper | Role | Relation | Cite in |
|---|---|---|---|
| Känzig, *Unequal Consequences of Carbon Pricing* (NBER 31221) [v] | CALIB/VALID | disciplines the incidence gradient psi; template for E3 event study | I, L, C, E |
| Douenne, Hummel & Pedroni [u — verify outlet] | BLOCK | optimal climate fiscal policy with heterogeneity | (L) |
| Fried, Novan & Peterman (RED 2018) [v: bib] | CALIB | carbon-tax distributional incidence | C |
| ECB/BoE/CEPR household energy-exposure evidence [k: family] | VALID | energy-share heterogeneity (PROPOSED block) | E |

## G. Climate finance / sovereign risk

| Source | Role | Relation | Cite in |
|---|---|---|---|
| Hurtado, Nuño & Thomas, *Monetary Policy and Sovereign Debt Sustainability*, JEEA 21(1) 2023 [v — replication package in `MP and Sovereign Debt Sustainability Code/`] | BLOCK/CALIB | inflation as state-contingent partial default on long-term nominal debt without commitment; disciplines the credibility limits of the revaluation channel and supplies the bond-pricing template for the U5 maturity extension; their repayment region connects to our fiscal-space-collapse result | I, L, M (maturity), referee memo R9 |
| BIS, *Decoding Climate-Related Risks in Sovereign Bond Pricing* [u — institutional] | VALID | sovereign-yield discipline for the fiscal-capacity channel | E |
| IMF, *Sovereign Climate Debt Instruments* [u] | POLICY | green/cat bond institutional detail | L |
| ECB/FSB nature-risk reports; NGFS documentation [k: institutional] | POLICY | optional biodiversity extension | L |

## Direct competitors vs building blocks (summary)

**Direct competitors** (the introduction must differentiate against each):
Hagedorn (we break and repair his nominal-rule uniqueness); Kaplan–
Nikolakoudis–Violante (HA nominal-debt price level — verify and read before
submission); Angeletos–Lian–Wolf (our revaluation channel reverses sign);
IMF climate-fiscal work (we give the missing revaluation/safe-asset margin);
Del Negro–di Giovanni–Dogra (short-run NK vs our long-run anchor);
Acharya–Benhabib (for the multiplicity result specifically).

**Building blocks**: FTPL classics, sequence-space/HANK methods, IAM and
carbon-tax papers, incidence papers, sovereign-climate-risk sources.

## Verification queue (do before submission)

1. Kaplan–Nikolakoudis–Violante: exact title, outlet, year. 2. Höfer: locate
or drop. 3. Auclert–Rognlie–Straub fiscal-monetary: outlet. 4. Nakov–Thomas;
Economides–Xepapadeas; Sahuc–Smets–Vermandel; Douenne–Hummel–Pedroni: outlets.
5. IMF/BIS/BdF institutional pieces: exact titles, years, and report numbers.
None of these appear in `paper/references.bib` yet precisely because they are
unverified — the bib contains only verified entries.
