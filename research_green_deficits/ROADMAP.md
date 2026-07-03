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
  4. **Opposite-signed climate channels** (safe-asset decomposition, S4 run):
     avoided damages are THEMSELVES disinflationary (income-level effect);
     only the risk channel pushes toward inflation — green disinflation is
     not a tax artifact.
  5. **Financing, not the program, is the inflationary margin** (U6 vs U7
     runs): tax-financed transitions are price-stable under any active rule;
     deficit financing flips impact inflation positive, with the size set by
     the monetary rule; the real green path is rule-independent in BOTH
     tiers.
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
| U7 | HANK transitions — **TIER 1 DONE, run VERIFIED and in the paper** (deficit financing flips impact inflation positive, +2.18% WEAK to +0.07% AGGRESSIVE; real green path rule-independent; beta=0.9796). Extension queued: TAYLORBAL (PHIB=0.75) isolates the financing component — run pending. Tier 2 (nonlinear DTPL P* transition) remains PLAN ONLY | TAYLORBAL run; tier 2 weeks | — |
| U8 | Production economy with clean/dirty sectors + energy share heterogeneity (unlocks tax-base channel and energy-incidence welfare groups) | weeks | U4 |
| U9 | Empirics: E2 data collection (schema ready); E3 event-study around EU Green Deal / IRA surprises (Känzig-style identification); sovereign-yield validation | parallel track | data |
| U10 | Paper rewrite to the final structure — **PARTIALLY DONE** (transition section, safe-asset subsection, extended-welfare paragraph, conditional abstract, regime renaming, lit-review upgrade in place); mechanism diagram still to add. Literature verification pass **DONE** (10 items web-verified 2026-07-03, appendix/LITERATURE_VERIFICATION.md; 3 items remain [u] and stay out of the draft) | mostly done | — |
| S4 | ~~Safe-asset-channel decomposition~~ **DONE — run VERIFIED** (dlnP = −5.72% = tax −7.68% + damage −1.59% + risk +2.31% + interaction +1.24%; financing swap +8.74%; the two climate channels have OPPOSITE signs — in the paper as subsection "Why the price level moves" + PFig15) | — | — |
| S5 | ~~Extended welfare groups~~ **DONE — run VERIFIED** (deficit regressive on every cut: constrained −2.98%, high-MPC −2.54%; rebate reverses every ordering: constrained +1.89%, bottom income +1.72%; in the paper + PFig16). Residual: income-q middle cell (state-boundary artifact, fractional split now coded, re-run fills it) | re-run (fast) | — |
| S10 | Production Stage 1 — **machinery DONE** (`production_block_green.m`: tax-base/damage split, Bom–Ligthart-checkable elasticity; STYLIZED, not joined to HA block). Stage 2 (clean/dirty CES, Pigouvian margin) NOT YET IMPLEMENTED (=U8) | Stage 2 weeks | U8 |
| S2 | Master reproducibility — **DONE** (`run_green_deficits_master.m` runs all 6 MATLAB + 2 Dynare stages with failure tracking; `export_master_status.m` writes the full machine record). Full master RUN PENDING | run pending | — |

## Submission decision rule

U1–U7 and S2/S4/S5 are now run-verified: the steady-state paper with
credible calibration, maturity bounds, the safe-asset decomposition, the
extended welfare cuts, AND two tiers of transition diagnostics is
assembled. Remaining before submission: the TAYLORBAL run + fast channels
re-run (fills two cells), the full master reproducibility pass, the E4
estimates, and a final [u]-reference sweep. U8 (production/Pigouvian) and
U7 tier 2 (nonlinear HANK-DTPL transition) are the revision-round
artillery, not preconditions.
