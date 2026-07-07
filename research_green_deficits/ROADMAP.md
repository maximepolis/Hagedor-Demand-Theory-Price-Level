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
| U7 | HANK transitions — **TIER 1 DONE incl. TAYLORBAL, runs VERIFIED and in the paper** (five regimes; TAYLOR-vs-TAYLORBAL: deficit financing buys the debt path (+0.071 vs +0.007 at 40q), not the inflation path (+0.44% vs +0.36%); verified RHOG=0.98 master run 2026-07-06). **TIER 1b: RCOND=NaN MECHANISM FOUND AND FIXED, re-run pending** (`green_hank2.mod` + `run_green_hank2.m`: two-asset HANK; run 5 (2026-07-07) made the failure reproducible — calibration converges in every regime, then heterogeneity_solve returns RCOND=NaN — and the equation-level audit traced it to the template's sign()/abs()^(chi2-1) adjustment-cost forms, whose symbolic second derivatives contain abs(D)^(chi2-3) = 0^(-1) = Inf at the illiquid-constraint corner (D=0 exactly, positive mass), turned into 0*Inf = NaN by the (chi2-2)=0 factor, inside the sequence-space Jacobian. The .mod now carries the EXACT smooth chi2=2 polynomial equivalents and drops the model's only exo-lead auxiliary (Z(+1)→Z, zero-variance placeholder). Fix UNVERIFIED: driver kill-switched by default, test with TIER1B_FORCE=true; NOT REPORTABLE until the protocol passes; paper does not depend on it and discloses the history). **TIER 2 RUN VERIFIED & REPORTABLE, grid-consistent (na=500, T=80, 2026-07-07 rerun)** (`solve_hank_dtpl_transition.m` + `main_project_transition.m`, PFig18: price-level path clears the asset market at every date, backward/forward exact HA solution, Anderson-accelerated fixed point, interior resid <5e-4, terminal <5e-4, beta calibrated on this run's own na=500 grid so pre-announcement debt/GDP lands on the 1.10 target): impact disinflation −2.0%/yr (−3.9% price-level jump = 77% of the long-run −5.1% front-loaded at announcement), bondholder windfall 5.3% of program PV (both designs), back within a quarter-point of trend by year 2, nominal-vs-indexed near-identical on-path (insulation value is off-equilibrium) — the paper's dynamic centerpiece, in Section tier2 + Result 6 + abstract. Tier-1b accuracy protocol (oscillation diagnostic, refinement re-solve, crash-recovery single-regime mode) stands ready for the fixed model | tier-1b forced re-run (TIER1B_FORCE=true) to verify the NaN fix | — |
| U8 | Production economy with clean/dirty sectors + energy share heterogeneity (unlocks tax-base channel and energy-incidence welfare groups) | weeks | U4 |
| U9 | Empirics: E2 data collection (schema ready); E3 event-study around EU Green Deal / IRA surprises (Känzig-style identification); sovereign-yield validation | parallel track | data |
| U10 | Paper rewrite to the final structure — **DONE** (transition section, safe-asset subsection, extended-welfare paragraph, conditional abstract, regime renaming, lit-review upgrade, and the mechanism diagram (Figure 1, new Section 3.5, TikZ) all in place). Full compile VERIFIED 2026-07-07 (pdflatex+bibtex+pdflatex x2: 61 pages, 0 undefined refs, 0 duplicate labels, 0 missing citations, bibtex 0 warnings). Literature verification pass **DONE** (10 items web-verified 2026-07-03, appendix/LITERATURE_VERIFICATION.md; 3 items remain [u] and stay out of the draft) | done | — |
| S4 | ~~Safe-asset-channel decomposition~~ **DONE — run VERIFIED** (dlnP = −5.72% = tax −7.68% + damage −1.59% + risk +2.31% + interaction +1.24%; financing swap +8.74%; the two climate channels have OPPOSITE signs — in the paper as subsection "Why the price level moves" + PFig15) | — | — |
| S5 | ~~Extended welfare groups~~ **DONE — re-run VERIFIED with exact fractional split** (deficit income-q [-3.05 .. -1.20] monotone regressive, constrained −2.98%, high-MPC −2.54%; rebate reverses every ordering: income-q [+2.01 .. −0.25], constrained +1.89%; all in the paper + PFig16) | — | — |
| S10 | Production Stage 1 — **machinery DONE** (`production_block_green.m`: tax-base/damage split, Bom–Ligthart-checkable elasticity; STYLIZED, not joined to HA block). Stage 2 (clean/dirty CES, Pigouvian margin) NOT YET IMPLEMENTED (=U8) | Stage 2 weeks | U8 |
| S2 | Master reproducibility — **DONE** (`run_green_deficits_master.m` runs all 6 MATLAB + 2 Dynare stages with failure tracking; `export_master_status.m` writes the full machine record). Full master RUN PENDING | run pending | — |

## Submission decision rule

U1–U7 (incl. TAYLORBAL and the tier-2 nonlinear transition) and
S2/S4/S5 are run-verified: the steady-state paper with credible
calibration, maturity bounds, the safe-asset decomposition, the extended
welfare cuts, two tiers of Phillips-curve transition diagnostics, AND the
converged, grid-consistent nonlinear HANK-DTPL transition (the dynamic
centerpiece: 77% front-loaded announcement disinflation, windfall 5.3% of
program PV, pre-announcement debt on the 1.10 target) is assembled. The
full master reproducibility pass ran 9/9 stages (2026-07-06); the tier-2
grid-consistency rerun (2026-07-07) superseded the first converged pass.
E4 is DONE and in the paper (2026-07-07 run: full n=165 beta=1.365
consistent with one; trimmed n=158 beta=0.709 rejects one at p=0.001 —
reported plainly, attenuation diagnosed via the consumption-vs-expenditure
concept, PFig12 in the paper as fig:pfig12). The final [u]-reference sweep
is DONE (2026-07-07: all three [u] items absent from paper and bib; the
Banque de France match is the verified Sahuc-Smets-Vermandel WP 977, not
the unverified Dees-Seghini). Remaining before submission: only the
tier-1b accuracy re-run (nice-to-have, gated by its protocol, EXPERIMENTAL
tier — the paper does not depend on it). U8 (production/Pigouvian)
remains revision-round artillery.
