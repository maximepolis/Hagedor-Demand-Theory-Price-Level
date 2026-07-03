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
| U6 | RANK transitions — **machinery DONE** (external steady-state file; four monetary regimes WEAK/TAYLOR/AGGRESSIVE/GREENACCOM; `run_green_transitions.m` driver, PFig13). First runs: TAYLOR + AGGRESSIVE converged; near-peg corner redesigned (12-quarter program ramp-in, chained solver fallbacks, WEAK `phi_pi=1.1` replacing the peg, `psi_g=0.03`, per-regime .mod copies). Re-run pending | re-run pending | Dynare |
| U7 | HANK transitions — **TIER 1 IMPLEMENTED** (`dynare/green_hank.mod` + `run_green_hank.m`: native Dynare heterogeneity framework, one-asset HANK + climate block + nominal-rate/ex-post-Fisher revaluation channel; linearized sequence-space IRFs to a quasi-permanent green program under four regimes, PFig14; run pending). Tier 2 (nonlinear DTPL P* transition) remains PLAN ONLY (appendix/HANK_TRANSITION_PLAN.md) | tier-1 run pending; tier 2 weeks | Dynare heterogeneity build |
| U8 | Production economy with clean/dirty sectors + energy share heterogeneity (unlocks tax-base channel and energy-incidence welfare groups) | weeks | U4 |
| U9 | Empirics: E2 data collection (schema ready); E3 event-study around EU Green Deal / IRA surprises (Känzig-style identification); sovereign-yield validation | parallel track | data |
| U10 | Paper rewrite to the final structure (mechanism diagram, quantitative headline, regime-comparison and welfare-distribution figures); verification pass over the [u]-flagged references in LITERATURE_MATRIX.md | after U1–U5 |

## Submission decision rule

Target a general-interest submission once U1–U5 are done (steady-state paper
with credible calibration, distortionary taxes, maturity bounds, and the
three headline findings), holding U6–U8 for the revision round or a
companion paper. If referees demand dynamics up front, U6 (RANK tier)
addresses stability/selection; U7 is the full answer.
