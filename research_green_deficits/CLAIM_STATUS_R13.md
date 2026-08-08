# Claim-status register, round 13 — reconciled against the referee's 23-item register

**What this file is.** `CLAIM_STATUS_R10.md` is our own register (30 rows). The
referee's register has 23 items in a different order and a different
vocabulary. This file maps one onto the other, item by item, and says who is
right where they differ.

**Provenance of the referee text (project rule 3).** There is no R13 report in
this repository: a repository search for "r13" returns only the two planning documents written alongside this file (CLAIM_STATUS_R13.md, PAPER_ARCHITECTURE_R13.md), neither of which is the referee report itself
are transcribed from the task brief and are **not** quotations verified against
a source in the tree. The same warning is already carried in the headers of
`main_sign_map.m` and `main_credibility_reversal.m`, which were commissioned
the same way. Nothing here may be cited as "the referee wrote".

**Vocabulary.** Unchanged from R10, and it is the only permitted set of
statuses. "Provisional" remains a narrative qualifier, not a ninth code.

| Code | Meaning |
|---|---|
| **PP** | proved from primitives |
| **NI** | numerical identity or decomposition (exact, verified by reconstruction) |
| **QV** | quantitatively validated (passes the numerical acceptance protocol) |
| **RO** | robust ordering (sign of a contrast, stable across structures) |
| **CS** | calibration-dependent sign (level sign, conditional on joint assumptions) |
| **IE** | illustrative extension (no external discipline, or a diagnostic) |
| **CU** | currently unsupported |
| **WP** | withdrawn pending validation |

**Status of the evidence.** The two-asset economy remains **UNCERTIFIED**, and
no two-asset LEVEL quantity below may be presented as established. Updated
2026-08-08: Track A has since returned a Gate 11 verdict on the NARROW frozen
family — the ORDERING certifies across all 9 cells (every $dP > 0$) while the
MAGNITUDE fails by 7.5x (0.752 against 0.10) and does not tighten under node
refinement. That is not yet the whole test. The refinement it survived held
the grid BOUNDS fixed and varied only node counts, so it cannot distinguish a
density problem from a boundary problem; the widened family authorised on
2026-08-04 (bmax x8, kmax x6) has never produced a Gate 11 verdict, because
the completed matrix was run with `WIDEN = false`. Item 8's two-asset leg is
therefore held at **WP** rather than moved to **RO**: the ordering result is
real but conditional on a family the outstanding run is designed to widen.

---

## 1. Item-by-item reconciliation

Legend for the agreement column: **=** our register agrees; **+** we are
stricter or sharper than the referee; **−** the referee is stricter or sharper
than we were, and we adopt their wording; **≠** substantive disagreement.

| # | Referee item (condensed) | R10 row | Agree | Our R13 status, and who is right | Repository evidence | What would change the status, and which run |
|---|---|---|---|---|---|---|
| 1 | Existence proved under maintained assumptions; needs crossing and feasibility conditions not implied by the preference restriction alone | 1 | **=** | **PP** under Assumption 1 + the crossing condition + (R1)–(R2). Referee is right and the paper already says so. | `paper/green_deficits_price_level.tex` 1217–1221 (Assumption `ass:feasible`); 1290–1307 (`prop:determinacy`), where 1299–1303 state in terms that the crossing condition "is not implied by Assumption~\ref{ass:feasible} alone" | Nothing numerical. Only a weaker sufficient condition (a proof, not a run) would change it. Existence *failures* stay solver-reported, not smoothed — `subsec:optmu`, tex 5209–5212 (no equilibrium at $\mu=0.015$) |
| 2 | Uniqueness proved under maintained assumptions; conditional on all crossings satisfying the elasticity restriction | 2 | **=** | **PP**, conditional. The proposition's own wording is "if $\varepsilon_S(P)>-1$ **wherever** $\Phi=0$" — a condition at every crossing, exactly as the referee states. | tex 1296 | A global (rather than at-crossing) condition would need a proof. Numerically, the calibrated $\varepsilon_S$ map is what `main_sign_map.m` measures; it bears on how far the condition is from binding, not on the theorem |
| 3 | Nominal neutrality proved from primitives, ONLY for joint proportional rescaling of nominal debt AND nominal appropriation | 3 | **−** | **PP**, with the joint-rescaling restriction now *part of the claim*. The referee is sharper than R10 row 3, which bundled neutrality, $\mu$-neutrality and demand-determined debt into one unqualified row. The paper is already correct; our register was loose. | tex 1334–1342 (`lem:neutrality`: $B$ enters only through $G_g/B$); tex 1351–1357 states explicitly that raising $B$ *alone* at fixed $G_g$ is **not** neutral | Nothing. This is an algebraic property of `eq:realfp`. Register wording adopted from the referee |
| 4 | Steady-state monetary neutrality proved from primitives at a fixed real rate | 3 | **=** | **PP** at fixed $r^{ss}$; fails along the transition and under aggregate risk, which the paper states. | tex 1386–1395 (`prop:muneutral`); tex 1403–1407 records the failure off the deterministic steady state | Nothing |
| 5 | Sufficient-statistic incidence formula proved under maintained assumptions; differentiability at a borrowing-constraint mass point maintained and numerically checked | 4 | **=** | **PP** under maintained condition (R3), numerically verified. Referee's characterization is verbatim the paper's own status line. | tex 1433–1470; the status block at 1462–1470 names "the finite income-state space and the mass point at the borrowing constraint" as the reason (R3) is a hypothesis rather than a primitive | A non-smooth (Clarke-derivative) version would be a proof. Numerically, the check is the finite-difference validation inside `audit_tax_incidence.m` and `decompose_tax_elasticity.m` |
| 6 | Resource and fiscal decompositions: exact accounting identity | 6, 30 | **=** with one refinement | **NI** for (i)–(ii). Refinement: part (iii) is *two* claims — the wealth-rank statement is exact, the income/welfare reading is numerical, not an identity. | tex 1523–1567; status block 1564–1567 makes exactly that split | Nothing for (i)–(ii). The welfare reading of (iii) moves with `welfare_incidence_deciles.m` / `main_project_regimes.m` |
| 7 | One-asset green disinflation: calibration-dependent sign, not a theorem | — (no R10 row; implicit in 11) | **−** | **CS**. Correct, and R10 had no row for it — a gap. Precisely: `res:disinflation` is a conditional equivalence whose sufficient condition ($\partial\Sfun/\partial\tau\ge0$) is *checked in the calibration*, and whose sign also requires $r^{ss}>0$. | tex 1569–1587: sufficient conditions at 1577–1580; the $r^{ss}>0$ requirement and the sign flip under accommodation at 1573–1577 | Measuring the *size* of the sign region rather than labelling it: `main_sign_map.m` over $(\lambda,\iota_H,\text{concentration})$ with the calibrated point marked. It cannot promote **CS** to **PP**; it can show the calibrated point is interior rather than knife-edge |
| 8 | Financing ordering: PROVISIONAL pending certification | 8, 9 | **≠ (split)** | **RO** for the **one-asset** leg — not downstream of the two-asset gate, but see the grid caveat in §X below; **WP** for the **two-asset** leg. The referee's blanket "provisional" is right for two-asset and over-strong for one-asset. | One-asset: `subsec:regimesreal` / `tab:regimesreal`, tex 5163–5176. Two-asset: `TWO_ASSET_FAILURE_FALLBACK_MEMO.md` §1.1 (lines 37–45) — the ordering *sign* survives benchmark 60/34/150 vs FAST 40/22/100 while the ordering gap moves 0.0363→0.0224 (38%) and the lump-sum level moves 52% | Track A → Gate 11 ORDERING block (`main_twoasset_grid_certification.m` with `kv_gate_report.m`; the provisional ORDERING/MAGNITUDE split is `CODE_VERSION.txt` R11.19, lines 12–22). If the ordering certifies and the magnitude does not, this row becomes **RO** two-asset with the level withheld |
| 9 | Straddling-zero result: PROVISIONAL pending certification | 10 | **+** | **WP**, not "provisional". We are right and stricter: this is a claim about *levels on opposite sides of zero*, and the level is not merely uncertain, it is **not currently measurable**. A pure `bmax` change (12→96) moves the root 7.7% against a 0.6% financing signal; at FAST the tree price is identical to four decimals across $\alpha=0$ and $\alpha=1$. | `TWO_ASSET_FAILURE_FALLBACK_MEMO.md` lines 21–27 (7.7% / 0.6% / signal-to-noise ≈0.08) and line 45 ($\Delta q$ = −0.0237 benchmark vs 0.0000 FAST) | Track A → Gate 11 MAGNITUDE block passing at the 0.10 threshold. Nothing short of that. If Gate 11 fails, this row is not "provisional", it is withdrawn, and `TWO_ASSET_FAILURE_FALLBACK_MEMO.md` §2–§4 governs |
| 10 | Covariance decomposition: exact accounting identity for the direct term | 6 | **=** | **NI** for the direct term only. Referee's qualifier "for the direct term" is exactly the paper's. | tex 1728–1751 (`prop:covincidence`); status 1752–1759 explicitly says the covariance "governs the *direct* incidence term, not by itself the sign of the full equilibrium response" | Nothing for the identity |
| 11 | Distributional response: calibration-dependent sign; dominant component not externally identified | 7 | **≠ (split), and we are sharper** | **NI** for the split (it is an identity, not a calibration-dependent sign); **CU** for the external discipline of the dominant term. The referee conflates the two. And the arithmetic is worse than "not externally identified": the *marginal direct* term carries the **opposite sign**. | `REFEREE_R12_RESPONSE_PLAN.md` §2.2 (lines 110–113): +3.44 distributional against +0.34 direct, marginal direct −0.07. **Caveat:** `PAPER_SAFETY_PATCH_R11.md` §D4 records that these are macro-driven and the manuscript sites are **still untraced** — the numbers stand as recorded in the response plan, the tex line numbers do not yet exist | External comparison against liquid-wealth panel transitions. Model side is built: `src_project/kv_wealth_mobility.m` (transition matrix on the forward iteration's own lottery split, plus a redistribution half-life). Data side is Layer 2 of `main_validation_mobility.m` and is **blocked on data access**. Until then **CU** cannot move |
| 12 | Fixed-real robustness: quantitatively certified within the one-asset stationary model | 9 | **=** | **RO** / **QV**, one-asset stationary only, **under EGM** — see the grid caveat in §X below. The referee's scope restriction is correct and should travel with the number. | tex 5163–5176; the paper's own statement is that fixed-nominal and fixed-real revaluation shares "differ only in the third decimal" (5175–5176) | `regimes_fixed_real.m` regenerating `tab:regimesreal`. Extending the certification to the transition would need a transition-welfare error bound, which does not exist (see item 17) |
| 13 | Two-asset Schur result: proved under maintained assumptions | 5 | **=**, with a correction the referee needs | **PP** (theory), **WP** (any number read off it). Correction: R12's Major 2 item 4 asserted the decomposition "has not yet been performed". It **is implemented** — `schur_validate` computes $F_{bP},F_{bq},F_{b\alpha},F_{kq}$, $N$, $M$ and $-N/M$ by central difference over a step-size ladder against a solved finite difference. Implemented ≠ certified. | tex 1680–1706 (`prop:twomarket`), status 1707–1717; `main_preferred_decomposition.m` — `schur_validate` begins at line 582; the manuscript sentence at tex 1712–1717 has already been corrected (`PAPER_SAFETY_PATCH_R11.md` §F2, APPLIED) | Certification of the numbers is downstream of Gate 11. Note the specific hazard: at FAST, $F_{k\alpha}$ is numerically **zero**, and a grid on which one Schur component vanishes cannot support the decomposition at all (`TWO_ASSET_FAILURE_FALLBACK_MEMO.md` lines 60–66) |
| 13a | Major 2 item 1 — full parameter table classifying how each parameter is disciplined | — (no R10 row) | **+** | **IE** as a diagnostic, **NI** for its algebraic entries. DISCHARGED by `main_identification_ledger` section A: 30 parameters across NORM/EXT/CAL/DECL/NUM with value, target moment and source, on a run where all four source calibrations load. It does the harder part too — $\iota_H = 0.2727$ is exposed as algebraic ($0.30/1.10$), NOT a free parameter and NOT a second moment, so the table cannot be read as manufacturing identification out of arithmetic. Independent of Gate 11 (V5). | `output/tables/identification_ledger.txt`, run 2026-08-08 | Nothing. The classification is a property of the code, not of a calibration |
| 13b | Major 2 item 2 — order condition | — | **+** | **NI**. DISCHARGED and answered more precisely than asked: the count FAILS a priori, 5 internally solved parameters against 3 targeted moments. The ledger then asks per block whether the slack is REAL. V1 measures it away for the superstar pair (9 configs, 3 tie within 0.02; among ties top-10 spans 0.0137, gini 0.0065 — inside the tie band, so the single moment is locally sufficient on this grid). V6 (the $\chi$ transplant from the frictionless companion) and V2 (whtm structural zero, governed by the two DECL parameters $\phi$ and $\bar b$) are where the slack actually sits. A count can overstate slack; it cannot understate it. | Ledger sections B and D | A wider superstar grid would test V1's local sufficiency globally; V6 is a modelling choice to be stated, not a run |
| 13c | Major 2 item 3 — untargeted-moment census | — | **=** | **CU** for the validation exercise, with one **QV** row. The census EXISTS and is complete (13 rows, every model value present, 0 with no model value) but 12 of 13 data slots are untranscribed, so it currently sets the comparison up rather than performing it. The one graded row is favourable and is the only external check the two-asset block has passed: the demand-curve log-elasticity, $-1.8174$ at the calibrated liquid position, lies INSIDE the published KVJ range $[-2.0548, -0.5479]$, 16% of its width from the elastic end. Note the grading rule matters — a symmetric band around the point estimate rejects a value lying inside the range, and did so until R11.40. New verdict V7 records an identity no transcription can rescue: the liquid FOC makes the convenience yield and the tree-bond excess return the SAME number, 5.9472 pp, so one quantity must answer to two literatures an order of magnitude apart. | Ledger section C and V7 | Transcribing the 12 slots turns the census into verdicts. `DATA.convenience_pp` and `DATA.equity_premium` SIZE V7's tension; neither can remove it |
| 14 | Ownership-and-illiquidity sign restoration: PROVISIONAL | 13 | **+** | **WP**. We are stricter and right, for the same reason as item 9: the restored level sign is the object the grid cannot resolve. "Provisional" invites a reader to weight a number against a precision it does not have. | Same evidence as item 9. Manuscript rescoping is drafted but **held**: `PAPER_SAFETY_PATCH_R11.md` §A1a, §A3–§A6 (tex 278–283, 2363, 2370–2371, 2376–2377, 2387, 2402, 3243–3244, 5676) | Gate 11 MAGNITUDE. If it fails, the claim does not return in any form and Option A/B/C of the fallback memo is chosen |
| 15 | Two-asset welfare incidence: PROVISIONAL; also excludes climate benefits in the transition | 12, 15 | **=**, referee's second clause is a real addition | **WP**, and the second clause is independently correct: damages are held fixed along the two-asset transition, so Table 4 prices the *financing announcement*, not the title question. | `PAPER_SAFETY_PATCH_R11.md` §D6 (Table 4 caption must be qualified as financing-side); `REFEREE_R12_RESPONSE_PLAN.md` §3 row 7 records the same gap as R12 Major 7 | Two conditions, both needed: Gate 11, **and** a two-asset transition with damages moving (`main_twoasset_kv_transition.m` / `main_twoasset_welfare.m`). Neither is available now |
| 16 | Announcement capitalization: certified in the one-asset model; PROVISIONAL cross-portfolio | 16a–16d | **=**, but our four-way split must be preserved | **QV** one-asset direction and fraction; **WP** two-asset; **CS** for the *sign*; **CS/WP** for welfare incidence. The referee's single item collapses four estimands with three denominators. The 107% figure is $F^{L-LS}_P$, **cross-instrument overshooting**, and is not a front-loading fraction of either regime. | `CLAIM_STATUS_R10.md` rows 16a–16d; definition set in `R10_EXECUTION_PLAN.md` §5, lines 163–173 ($F^j_P$ vs $F^{L-LS}_P$). **Two open items:** (a) `PAPER_SAFETY_PATCH_R11.md` §A8 records the manuscript sites as macro-driven and **not yet located** — no edit proposed until traced; (b) the one-asset fraction is written **77%** in `CLAIM_STATUS_R10.md` row 16b and `R10_EXECUTION_PLAN.md` line 171, and **78%** in `PAPER_SAFETY_PATCH_R11.md` §A8. Unresolved here on purpose: it must be read off the macro, not chosen | Magnitude bounding, not sign: `main_credibility_reversal.m` (announcement probability $p$, per-period reversal hazard $h$, reports $d\ln P_1$ and $F_P$). It is unrun. Cross-portfolio status still needs Gate 11 |
| 17 | Transition welfare: calibration-dependent sign | 15 (partial) | **−, and we add a harder problem** | **CS** one-asset; **WP** two-asset. The referee is right on the sign. Sharper: the manuscript's claim that "the transition adds almost nothing" has **no welfare-error bound below the reported differences**, so it is not even a sign statement — it is an unbounded numerical comparison. | `PAPER_SAFETY_PATCH_R11.md` §D7 (tex 2765), which proposes retaining the sentence only if such a bound is in hand and records that none is | A transition-accuracy run: `verify_transition_ssj.m` plus a converged (not FAST) path. The current FAST transitions are explicitly **NOT CONVERGED** at T=60, maxit=80 (`REFEREE_R12_RESPONSE_PLAN.md` §3a, lines 336–338) |
| 18 | Deficit-ratchet reversal point: illustrative extension | 20 | **=**, we are more specific | **IE** as a joint result; the *tax-timing* leg has moved out of **WP**: `main_deficit_decomposition` (run 2026-08-06, every gate passed) computes the matched-terminal-debt path. **NI** for the split $C4{-}C1=(C2{-}C1)+(C4{-}C2)$, cross-checked against `kv_kappa_legacy` to 3.7e-04; **QV** for the sign reversal at matched terminal debt at the reported speed ($C1=-0.039622$, $C2=+0.022093$, $C4=+0.142100$) — timing alone flips the sign, so a timing claim is licensed *in kind*. The magnitude stays a joint object: 34% timing, 66% ratchet. The frontier LOCATION is now measured on both rules: `main_timing_frontier` validates the manuscript's 1.4-year figure as the **joint** frontier ($\rho^*=0.6121\to1.41$ y, bracketed on [0.60, 0.65], cross-checked against the decomposition to 3.5e-05), and the re-run of 2026-08-07 closed the timing bracket — **QV**: the pure-timing crossing is $\rho^*=0.7977\to3.07$ y, bracketed on [0.70, 0.80] with no gap, **2.2×** the joint figure. The convexity suspicion recorded here was confirmed: the wide-bracket interpolation had said 2.62 y. | Decomposition: `output/deficit_decomposition.mat` (EST.reportable=true); estimands reprinted by `main_deficit_estimands`. Frontier: `output/timing_frontier.mat`; the manuscript caveat at the old tex 3296–3300 ("is not computed") is now REWRITTEN to report the computed decomposition via `\DefDec*` macros, and the timing frontier enters as `\DefRhoStarTiming`/`\DefHalfStarTiming`, exporter-gated so a provisional bracket renders `\pendingnum` | The $\rho=0.80$ re-run (consolidation bracketing fixed R11.33) closes the timing-frontier bracket and flips its macros from `\pendingnum` to numbers. Equal-PV and equal-terminal-real cases are still to be added |
| 19 | Multiplicity: proved under maintained assumptions; calibrated multiple-root region EMPTY | 23 | **−** | **PP-conditional** for the proposition, **IE** for its role in the paper. The referee is right that R10's flat "IE" understated the theory: `prop:sunspots` is proved, conditional on a transversal downward crossing. The referee's second clause is the paper's own status line. | tex 4440–4467 (`prop:sunspots`); status 4468–4470: conditional on the crossing "which the calibrated frontier does not exhibit" | A calibration in which $\varepsilon_S$ crosses $-1$. `main_sign_map.m` measures the swept box; the frontier table is `tab:frontier` (tex 4610). Finding a nonempty region would move this from **IE** to a substantive result |
| 20 | Indexation: numerically verified LOCAL result; prevents the modelled multiplicity channel, not nonexistence | 24 | **−** | **QV** (numerically verified local elasticity bound), not **IE**. The referee is right on both clauses and R10 row 24 was too dismissive. The paper already says exactly this. | tex 4478–4499 (`prop:insulation`): the magnitude condition is "verified numerically across the calibrated $(\theta_g,\psi,\phi_D)$ range, not established analytically for all parameters" (4489–4492), and 4494–4495: "it does not by itself guarantee existence". Reinforced at tex 1312–1315 | `main_partial_indexation.m` — the $\xi$ sweep, with the endpoint identity ($\xi=1$ → real mandate, $\xi=0$ → nominal appropriation, both max-abs-diff 0) run as a **gate** before the sweep (`REFEREE_R12_RESPONSE_PLAN.md` §2.1). A result at interior $\xi$ would upgrade this from two endpoints to a schedule |
| 21 | Optimal-real-rate result: numerically verified local result | 25 | **=** | **PP** for the reduction, **IE/QV** for the located optimum. Referee's wording matches the paper's status line: analytic *reduction* to a real-rate problem plus a numerically located interior optimum. $\mu^*\approx4.5\%$ is an existence-and-direction result at an illustrative scale, never an inflation prescription. | tex 5511–5529 (`prop:optimalmu` + status); tex 5197–5212 (`subsec:optmu`), including the non-existence at $\mu=0.015$ reported by the solver rather than smoothed | Nothing changes the reduction. The located optimum moves with any recalibration; it must not be quoted as a policy magnitude under any run |
| 22 | Aggregate-risk extension: illustrative extension | 26 | **=** | **IE**. Orthogonal to the title question; the paper scopes it to an appendix. | tex 5533–5555 (`subsec:aggrisk`), which points to `app:aggrisk` | `main_project_aggrisk_stageB.m`. External discipline on the climate regime process would be needed to move it off **IE**; none is proposed |
| 23 | NK comparison: illustrative extension, diagnostic not a horse race | 27 | **≠ (split)** | **IE** for the appendix diagnostic — the referee is right, and R10's flat **CU** was too blunt. **CU stands for the headline opposite-sign contrast**, which R10 removed and which must not return: the comparison changes rigidity, household structure, financing, persistence, scale and closure simultaneously. | tex 3300–3315 already concedes that RA variants under active rules price the announcement negative, so the contrast is "a property of the matched design, not of price stickiness as such" | The nested ladder — `dynare/run_matched_dtpl_nk.m` with `green_rank_nk.mod` / `green_hank2.mod`, varying **one** dimension at a time. Only that promotes the contrast from **CU** to a claim; otherwise the diagnostic stays in the appendix |

---

## 2. Two things this repository knows that the referee does not

Neither is in the referee's 23 items. Both change what is owed.

### 2.1 The refactor is excluded as a source of numerical doubt — D10 and D11 parity are ESTABLISHED

| test | result |
|---|---|
| **D10 A/B/C** — calibration refactor, all three legs | **PASS: 40 / 32 / 32 fields exact, 0 FAIL** |
| **D11 A/B/C** — transition solver, all three legs | **PASS: 48 fields exact**, `neutrality_gap` exactly 0 |

Evidence: `CODE_VERSION.txt` line 113 ("R11.13 D10 PARITY ESTABLISHED (A/B/C
all PASS: 40/32/32 fields exact)"); `REFEREE_R12_RESPONSE_PLAN.md` line 326 for
D11. The transition solver reproduces the pre-refactor commit bit-for-bit
including its residual history, and $P^d_\infty/P^b_\infty=\kappa_\infty$ holds
to zero relative gap — the sharpest available internal check that the debt
recursion and the terminal pin are mutually consistent.

**What this does and does not buy.** It buys the exclusion of one hypothesis:
the numerical problems are *not* an artefact of the refactor. It buys nothing
about whether the discretization resolves the economics — the FAST transition
paths are still NOT CONVERGED (T=60, maxit=80) and the two-asset grid noise
still exceeds the financing signal. A referee who suspects the code should be
answered with this; a referee who suspects the grid should not.

**Consequence for this file (project rule 4):** the six solvers that carry
parity — `solve_hank_dtpl_transition.m`, `solve_household_twoasset_kv.m`,
`kv_solve_alpha.m`, `kv_solve_bond_given_q.m`, `kv_stationary_block.m`,
`kv_calibrate_on_grid.m` — must not be touched. No status above may be moved by
editing them.

### 2.2 The preferred two-asset economy is solved on a grid its own distribution has outgrown

The Track A pre-flight evaluates the boundary gates on the benchmark
distribution already stored in the `.mat`, before solving anything. On the
paper's own preferred grid family:

| gate | value | threshold |
|---|---|---|
| 7 liquid top-two-node mass | 0.00275 | < 1e-4 |
| 8 illiquid top-two-node mass | 0.00143 | < 1e-4 |
| 9 occupied support, liquid | **1.0000** | < 0.90 |
| 9.1 occupied support, illiquid | **1.0000** | < 0.90 |

Evidence: `REFEREE_R12_RESPONSE_PLAN.md` lines 248–253 for the measured values;
`src_project/kv_gate_report.m` lines 106–109 for the gate definitions and lines
154–163 for the thresholds (`boundary` = 1e-4, `occupancy` = 0.90).

**Occupancy of exactly 1.0000 on both axes means the distribution carries mass
at the very top node of both grids.** Gates 7–8 fail by one to two orders of
magnitude *before any refinement is attempted*.

**Why this is sharper than the referee's Major 4 / Major 11.** The referee asks
for numerical uncertainty to be reported alongside each price movement, on the
assumption that the underlying solves are sound and the fragility is
*calibration-dependence*. The measurement says something stronger and
independent of calibration: the preferred specification does not clear the
project's own pre-registered admissibility criteria, and gates 7–9 are
properties of grid **extent**, not of node count — so they cannot improve with
a finer grid of the same reach. Adding nodes is not the fix; that is why the
frozen family was widened (bmax ×8, kmax ×6, node counts scaled by
$F^{1/\text{curvature}}$ so widening is not also coarsening), with the
resulting `target_drift` against the $S_b=0.30$ target reported per cell rather
than assumed small (`CODE_VERSION.txt` R11.16, lines 66–73).

**The honest sentence for the paper, in either branch:** *on the
discretizations we can currently solve, the two-asset level response is not
resolved.*

---

## 3. Rows whose status moves relative to R10

| item | R10 | R13 | Reason |
|---|---|---|---|
| 3 (nominal neutrality) | **PP**, unqualified row | **PP**, joint-rescaling restriction part of the claim | Referee sharper; R10 row 3 bundled three distinct statements |
| 7 (green disinflation) | no row | **CS** | Gap in R10. `res:disinflation` had no register row despite being a headline |
| 8 (financing ordering) | **RO** both legs | **RO** one-asset / **WP** two-asset | Explicit split, so the certified leg is not withdrawn with the uncertified one |
| 11 (distributional) | **NI** + **CU** | unchanged, plus the marginal direct term's opposite sign recorded | Referee's "calibration-dependent sign" mischaracterizes an identity |
| 19 (multiplicity) | **IE** | **PP-conditional** (theory) / **IE** (role in paper) | R10 understated the theorem |
| 20 (indexation) | **IE** | **QV** local elasticity bound | R10 understated a numerically verified result the paper states correctly |
| 23 (NK) | **CU** | **IE** (appendix diagnostic) / **CU** (headline contrast) | Flat **CU** was too blunt; the demotion, not the deletion, is what is owed |
| 18 (deficit ratchet) | **IE** (R10 row 20) | **NI** (timing/ratchet split) / **QV** (sign reversal at matched terminal debt) / **QV** (both frontier locations, re-run 2026-08-07) | `main_deficit_decomposition` run 2026-08-06: $C2{-}C1$ reverses the sign at matched terminal debt; 34/66 timing/ratchet split; `main_timing_frontier` validates 1.41 y as the *joint* frontier and measures the timing frontier at 3.07 y (2.2×) |

One row moves *upward* out of **WP**: the item-18 tax-timing leg — sign on the matched-terminal-debt run (`main_deficit_decomposition`, 2026-08-06), and location on the completed sweep (`main_timing_frontier`, 2026-08-07: timing $\rho^*=0.7977\to3.07$ y against joint 1.41 y). No two-asset status changed.

---

## 4. Standing constraints

1. **Binding rule (from R10, unchanged).** Every sentence in the abstract,
   introduction and conclusion must map to exactly one row of this register.
2. **No one-asset publication fallback is approved.** If Gate 11 fails, the
   three architectural options in `TWO_ASSET_FAILURE_FALLBACK_MEMO.md` §2–§4
   are compared and a choice is made explicitly. §7 of that memo records that
   no option has been chosen and that choosing before Track A reports would be
   premature.
3. **Unlocated items are flagged, not dropped.** `PAPER_SAFETY_PATCH_R11.md`
   §A7 ("the data reject" — NOT FOUND in the source), §A8 (the 89%/78%
   announcement fractions) and §D4 (the −0.07 / +0.34 / +3.44 / +3.78
   decomposition sites) are all macro-driven or absent, and no patch is
   proposed for any of them until the string is located.
4. **The two-asset economy is UNCERTIFIED.** No number in this file presents a
   two-asset quantity as established.


---

## §X. Grid caveat on the one-asset legs (added after adversarial verification)

Rows 8 and 12 above call the one-asset leg certified. That is defensible only
with a solver qualification, which an earlier draft of this register omitted
and which an adversarial check caught.

`output/tables/grid_convergence.txt` ends:

> `VERDICT: CHECK -- reported research-grid (na=500) outcomes are NOT stable to`
> `grid refinement at the stated tolerances (aggregates 1e-3; derivative 5e-2;`
> `distribution stats 1e-2).`

The verdict is CHECK because the file reports **both** solvers and they
disagree on the medium → research refinement:

| solver | \|dS\| | \|db0\| | \|deps\| | verdict |
|---|---|---|---|---|
| vfi | 9.85e-03 | 9.91e-03 | 2.17e-01 | **FAIL** |
| egm | 4.64e-04 | 4.93e-04 | 5.42e-04 | **PASS** |

EGM has been the default household solver since Round 12
(`setup_params_green.m`, `pg.hh_solver = 'egm'`, with the cross-validation
recorded in that file's header: mean off-grid Euler errors 1e-5.4 EGM versus
1e-2.1 grid-choice VFI). So the correct statement is:

**The one-asset leg passes grid refinement under the solver the paper actually
uses, and fails it under the solver the paper does not.** The derivative
metric is where VFI fails worst — 2.17e-01 against a 5e-2 tolerance — and the
derivative is exactly the object the incidence formula reads.

Two consequences that should travel with any one-asset number:

1. Wherever a one-asset result is called certified, the solver must be named.
   "Certified" without "under EGM" overstates what the stored artifact shows.
2. The tier-2 transition deliberately uses the grid-restricted VFI machinery
   for internal boundary consistency (`setup_params_green.m` header). Any
   transition number therefore inherits the FAILING leg's discretization, not
   the passing one. That is a real gap and it is not closed by this register.
