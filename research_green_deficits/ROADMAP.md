# Roadmap: from current package to top-journal submission

*Separates what is submission-ready from what remains preliminary. Companion
to MODEL_STATUS.md (block-level labels) and referee_memo/REFEREE_MEMO.md.*

## Ready now (verified by runs)

- The steady-state HA price-level machinery, the climate blocks (both
  versions), the incidence gradient, the four-channel self-financing
  decomposition, the all-roots equilibrium solver with the elasticity
  diagnostic, the W(mu) accommodation exercise, and E1 empirics.
- Three headline findings that survive honest labeling:
  1. **Green disinflation / revaluation-sign reversal** (nu_reval = −0.24 at
     benchmark): mechanism-based, robust to the tax instrument, empirically
     diagnosable (E3).
  2. **Anchor-insulation rule design** (nominal debt + indexed green
     mandate): a determinacy theorem with an institutional instrument.
  3. **Fiscal-space collapse under regressive incidence** (existence failure
     at tight money + strong incidence): new, found by the extended run.
- The LaTeX draft with proofs, the verified bib, the reproducibility chain
  (master script, logs, parameter record).

## Preliminary (do not oversell)

- All magnitudes: climate parameters are illustrative until the calibration
  appendix is executed (low/medium/high damages).
- Multiplicity: a theorem plus a measured diagnostic, not (yet, possibly not
  ever) a calibrated quantitative result. The paper's quantitative core must
  remain the decomposition and the sign reversal.
- Everything dynamic.

## Upgrade sequence (ordered; each step is self-contained)

| # | Task | Est. effort | Blocks |
|---|---|---|---|
| U1 | ~~Rerun extended package post-fix; fill paper placeholders (frontier, X1, E1 CI)~~ **DONE** (master run: baseline 73.2 s + extended 48.3 s; frontier table, accommodation-neutrality result, and E1 inference now in the paper) | — | — |
| U2 | ~~Welfare by wealth quintile~~ **DONE** (corrected C4 run: deficit financing regressive in LOW/MED, all-quintile gains in HIGH; in the paper as Table "incidence" + PFig8) | — | — |
| U3 | ~~Calibration execution~~ **DONE for beta / program scale / damage columns** (beta*=0.9296 to debt/GDP=1.10; program 2% of income; nu = 0.15 / 0.56 / 2.01 across LOW/MED/HIGH damages — verified run, 147 s). Remaining within U3: theta_g from IEA abatement costs; psi from Känzig incidence; wealth-moment targeting of (rho, sig_eps) | partial | data access |
| U4 | ~~Financing regimes~~ **DONE** (run verified, 31.3 s: revaluation-sign flip across regimes; rebate design near-Pareto-dominates deficit financing; in the paper as Table "regimes", Result 5, Proposition 6 + PFig9). Remaining within U4: distortionary labor tax with an hours margin (Barrage template) — the levy's Pigouvian margin belongs to U8 | partial | — |
| U5 | ~~Debt maturity~~ **DONE** (run verified, 42.6 s: level-jump equivalence; indexation RAISES nu^M (0.563->0.579) because the channel is negative; foreign holders absorb the windfall (-0.058->-0.029); duration amplifies accommodation gains (+2.4%/+12.5%/+25.6% repricing at 1y/5y/10y); q_g sweep nu=0.563/0.449/0.329 -- all in the paper) | — | — |
| U6 | ~~RANK transitions~~ **DONE — run VERIFIED** (all four regimes CONVERGED after the ramp-in redesign; price-stable under active rules, regime-independent real green path, accommodation buys inflation not green capital; in the paper as Section "Transition diagnostics" + PFig13; validation in appendix/TRANSITION_VALIDATION.md and rank_transition_validation.txt) | — | — |
| U7 | HANK transitions — **TIER 1 RUN COMPLETED** (PFig14 produced, four regimes; numeric summary hank_irfs_summary.txt + hank_tier1_validation.txt PENDING transcription into the repo — paper reports figure + scope only until then). Tier 2 (nonlinear DTPL P* transition) remains PLAN ONLY (appendix/HANK_TRANSITION_PLAN.md) | transcribe summary; tier 2 weeks | — |
| U8 | Production economy with clean/dirty sectors + energy share heterogeneity (unlocks tax-base channel and energy-incidence welfare groups) | weeks | U4 |
| U9 | Empirics: E2 data collection (schema ready); E3 event-study around EU Green Deal / IRA surprises (Känzig-style identification); sovereign-yield validation | parallel track | data |
| U10 | Paper rewrite to the final structure — **PARTIALLY DONE** (transition section, safe-asset subsection, extended-welfare paragraph, conditional abstract, regime renaming, lit-review upgrade in place); mechanism diagram still to add. Literature verification pass **DONE** (10 items web-verified 2026-07-03, appendix/LITERATURE_VERIFICATION.md; 3 items remain [u] and stay out of the draft) | mostly done | — |
| S4 | Safe-asset-channel decomposition — **machinery DONE** (`decompose_safe_asset_channel.m`, PFig15, exact GE counterfactuals: tax / damage / risk / interaction + financing swap). RUN PENDING via `main_project_channels` | run pending | — |
| S5 | Extended welfare groups — **machinery DONE** (`welfare_groups_extended.m`, PFig16: income/bond quintiles, constrained, high-MPC proxy, exposure terciles). RUN PENDING via `main_project_channels` | run pending | — |
| S10 | Production Stage 1 — **machinery DONE** (`production_block_green.m`: tax-base/damage split, Bom–Ligthart-checkable elasticity; STYLIZED, not joined to HA block). Stage 2 (clean/dirty CES, Pigouvian margin) NOT YET IMPLEMENTED (=U8) | Stage 2 weeks | U8 |
| S2 | Master reproducibility — **DONE** (`run_green_deficits_master.m` runs all 6 MATLAB + 2 Dynare stages with failure tracking; `export_master_status.m` writes the full machine record). Full master RUN PENDING | run pending | — |

## Submission decision rule

Target a general-interest submission once U1–U5 are done (steady-state paper
with credible calibration, distortionary taxes, maturity bounds, and the
three headline findings), holding U6–U8 for the revision round or a
companion paper. If referees demand dynamics up front, U6 (RANK tier)
addresses stability/selection; U7 is the full answer.
