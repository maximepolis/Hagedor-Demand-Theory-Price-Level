# Status audit — 2026 Q3 (editorial-roadmap Step 1)

*Synchronization audit of every status-bearing file against the code and
output artifacts actually in the repository. Format per finding: file
inspected → claim found → code/output support → corrected label → required
paper edit. Executed 2026-07-03; all corrections applied in the same
commit series as this file.*

## Findings and corrections

| # | File inspected | Claim found | Code/output support | Corrected label | Paper edit |
|---|---|---|---|---|---|
| 1 | MODEL_STATUS.md §3 | "Carbon taxes NOT YET IMPLEMENTED" | `solve_regime_equilibrium.m` + `S_green.m` vartheta implement the proportional levy; run verified (regimes_summary.txt) | Proportional levy IMPLEMENTED; **Pigouvian carbon tax** (production margin) still NOT YET IMPLEMENTED | Regimes subsection now carries the required non-Pigouvian disclaimer sentence |
| 2 | MODEL_STATUS.md §3 | "Targeted transfers NOT YET IMPLEMENTED" | R3 rebate (negative tau_ls) implemented and run | Lump-sum rebate IMPLEMENTED; targeted (state-contingent) transfers still NOT YET IMPLEMENTED | none (paper already precise) |
| 3 | MODEL_STATUS.md §3, §8 | "Debt maturity NOT YET IMPLEMENTED" | `debt_maturity_revaluation.m` run verified (maturity results in the paper) | IMPLEMENTED (arithmetic + bounds tier); full long-bond pricing equilibrium NOT YET IMPLEMENTED | Maturity subsection already labeled "arithmetic"; referee memo R15 added |
| 4 | MODEL_STATUS.md §7 | "CE units PROPOSED; welfare by quintile PROPOSED" | `welfare_by_group.m` run verified; Table "incidence" in the paper | IMPLEMENTED (with sigma>1 validity guard) | none |
| 5 | MODEL_STATUS.md §8 | Safe-asset channel "separately reportable" (not reported) | NEW `decompose_safe_asset_channel.m` + driver | IMPLEMENTED, run pending | NEW paper subsection "Why the price level moves" (numbers pending run) |
| 6 | MODEL_STATUS.md §2, §8 | Output/tax-base channel unidentifiable in endowment economy | NEW `production_block_green.m` Stage 1 | PARTIALLY IMPLEMENTED (aggregate layer; stylized, no labor margin, not joined to HA block) | none yet — enters the paper only after a run |
| 7 | run_green_deficits_master.m | Ran only 2 of 6 MATLAB drivers; hand-written status block; "debt maturity PROPOSED" in its output | 6 MATLAB + 2 Dynare stages exist | REWRITTEN: runs all stages with per-stage failure tracking; `export_master_status.m` writes the full machine record | none |
| 8 | main_project_regimes.m + paper | Regime name "R2-CARBON" implies a carbon tax | levy has no emissions-price margin | Renamed R1-DEFICIT / R2-PROP-LEVY / R3-PROP-LEVY-REBATE / R4-MIXED-DEFICIT-LEVY (code + paper + tables) | Table \& text renamed; disclaimer sentence added |
| 9 | dynare/README.md, .mod headers | GREENACCOM described as "~70bp annualized" | psi_g=0.03 × kg-gap 0.6 = 1.8pp QUARTERLY | Corrected to ~7.2pp annualized (U6) / ~11bp (U7, keys off gg not kg); labeled "deliberately large experiment" | Transition section states the true magnitude |
| 10 | ROADMAP.md U6/U7 vs MODEL_STATUS.md | U6 "run pending" vs verified converged run | transitions_summary.txt (user upload, all four CONVERGED) | U6 run VERIFIED; U7 tier-1 run completed, numeric summary pending | Transition section reports verified U6 numbers; HANK numbers withheld until summary transcribed |
| 11 | LITERATURE_MATRIX.md | 10 [u]-flagged entries | web-verification pass (appendix/LITERATURE_VERIFICATION.md) | 10 verified → [v] with dates; 3 remain [u] and stay OUT of the draft; claimed CEPR DP 20820 NOT confirmable (U Toronto WP 807 used) | Lit review now cites KNV, Höfer, ARS, Sahuc–Smets–Vermandel, Nakov–Thomas, both IMF WPs, Ando et al. |
| 12 | paper abstract | decomposition list omitted safe-asset-demand channel and rebates | new module + verified regime run | — | Abstract rewritten (conditional, full channel list, bottom-half welfare) |

## Claim-labeling conventions confirmed project-wide

Every component carries one of: IMPLEMENTED / PARTIALLY IMPLEMENTED /
PROPOSED / PLACEHOLDER / NOT YET IMPLEMENTED. Every quantitative result
carries one of: STEADY STATE / RANK-NK TRANSITION DIAGNOSTIC /
TIER-1 LINEARIZED HANK IRF / NONLINEAR HANK-DTPL TRANSITION (none yet) /
STOCHASTIC AGGREGATE RISK (none yet).

## Standing red lines (unchanged)

1. Never "green deficits finance themselves" unconditionally — the
   headline is partial self-financing at conservative/medium damages; full
   self-financing only in the high-damage/high-effectiveness region.
2. RANK/NK paths and tier-1 HANK IRFs are never presented as the DTPL
   price-level mechanism.
3. Multiplicity stays a theorem + measured diagnostic (the calibrated
   benchmark does NOT generate it, and the paper says so).
4. The levy is not called a Pigouvian carbon tax anywhere.
5. No number enters the paper without a verified run behind it.
