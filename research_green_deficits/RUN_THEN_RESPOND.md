# What to run, and what to push back — round 6

## 1. What to run (MATLAB, from `research_green_deficits/`)

Everything in this round is either a text/proof fix (no run needed) or is
already covered by an existing driver. The **one new run** you need is the
fixed-real financing comparison; the rest refresh the numbers the paper reads.

**Minimum (new this round):**
```matlab
cd research_green_deficits
main_project_calibrated       % ensures output/calibrated_results.mat exists (beta*, Gg)
main_project_regimes          % fixed-nominal Table 6 (if not already current)
regimes_fixed_real            % NEW: fixed-real companion table (pure incidence)
export_paper_numbers          % writes paper/numbers_auto.tex incl. the *Real* macros
```
Then recompile the paper (`pdflatex; bibtex; pdflatex; pdflatex`). The
fixed-real table (Table, companion to Table 6) will switch from "–" placeholders
to numbers automatically.

**Optional robustness drivers added over the last rounds** (each writes a table
under `output/tables/` and is wired into `run_green_deficits_master`):
```matlab
verify_mu_neutrality            % Theorem 2 (mu enters only through r^ss)
sensitivity_climate_discipline  % nu / BCR over (theta_g, delta_g)
verify_transition_ssj           % Anderson vs sequence-space Newton + determinacy
decompose_tax_elasticity        % dS/dtau by wealth group + sign sweep
```
Or just run the whole pipeline: `FAST = true; run_green_deficits_master` for a
quick pass, or `run_green_deficits_master` for the na=500 benchmark.

**What to check in the output** (`output/tables/regimes_fixed_real.txt`):
- `nu_reval` should still swing from negative (lump-sum) to positive (levy /
  rebate), matching the fixed-nominal signs to ~third decimal;
- the bottom-50%/top-10% welfare reversal should persist.
If both hold, the incidence conclusion is convention-independent, which is the
claim the paper now makes.

## 2. What to push back (response to the referee)

> We thank the referee. Four detailed points:
>
> - **A.4 (mandate boundary) and A.5 (coefficient algebra).** Both were already
>   corrected in the previous revision; the report appears to be against the
>   earlier PDF. In the current source the Proposition 1 proof tracks the two
>   spending regimes separately — the high-P tax limit is `0` under a nominal
>   appropriation and `ḡ_g` under the indexed mandate — and the Appendix A.5
>   coefficients `τ−κg_g` (direct) and `τ−g_g` (equilibrium) are stated to differ
>   by `(1−κ)g_g`, with the identity shown explicitly. No result changes.
>
> - **§6.3 stationarization (dimensional ambiguity).** Fixed. We now detrend the
>   nominal stock along with the price level, `B̂_t ≡ B_t/(1+μ)^t = B_0`, and write
>   the cleared supply as `Ŝ_t = B̂_t/P̂_t = B_0/P̂_t` throughout the solver and the
>   sequence-space Jacobian — both sides detrended, no mixed units.
>
> - **§6.3 "deficit finance" label.** Fixed (also in the previous revision): the
>   benchmark DTPL transition holds the service rule `τ_t = r^ss b_t + g_{g,t}`, so
>   nominal debt grows only at trend and the real-debt path is revaluation, not a
>   primary deficit; the announcement result is now described as occurring under
>   *lump-sum* finance, with the genuine primary-deficit lever reserved for the
>   low-`φ_b` Phillips-curve diagnostics.
>
> On the five broader points: we agree, and the revision (i) adds a
> "contributions in order of robustness" paragraph that foregrounds the
> stationary incidence mechanism and demotes the sunspot, anchor-insulation,
> optimal-accommodation, and NK-contrast results to explicitly conditional
> extensions/diagnostics; (ii) recasts the one-asset revaluations as upper bounds
> scaled by the liquid nominal-government-debt share (`ω ≈ 0.15–0.25`), stating
> the endogenous-convenience-yield DTPL solve as the outstanding magnitude
> discipline; (iii) pivots the self-financing statements to frontier language,
> with `θ_g` reported as a contour rather than a trained magnitude and the
> mitigation/adaptation structural distinction made explicit; (iv) reframes the
> nonexistence result as a conditional incompatibility between the program, the
> incidence gradient, and a rigid `(i^ss,μ)`-plus-lump-sum instrument
> configuration — under an endogenous real rate the same pressure is a bound on
> the sustainable real rate, not a collapse; and (v) adds a **fixed-real
> financing-regime table** beside the fixed-nominal one (Proposition 7
> convention, `g_g` common across regimes), so the reader can separate true tax
> incidence from the price-level revaluation it induces and from the (second-
> order) real-scale drift. The levy-plus-rebate result is presented as a
> distributional tradeoff — the transition version runs through a large one-time
> bondholder revaluation — not as an unconditionally dominant recommendation.

---

# Round 7 — one more run, and the push-back

## Run this (fills the §5.8 elasticity-map table)
```matlab
cd research_green_deficits
decompose_tax_elasticity     % the primitive-sweep map (borrowing limit, risk, sigma, beta, instrument)
export_paper_numbers         % writes eps* macros into numbers_auto.tex
```
Then recompile. The new **elasticity-map table** in §5.8 switches from "–"
placeholders to numbers (as the fixed-real table already did). Optionally also
run `verify_mu_neutrality`, `sensitivity_climate_discipline`,
`verify_transition_ssj` to bank the other verification tables.

## Push-back to the referee
> We thank the referee for the careful reading of the appendix. Four points:
>
> - **A.9 (Prop 6, optimal μ).** Rewritten. We agree the previous argument
>   conflated a steady-state comparison with transition-style incidence. The
>   proof now reduces the problem to the real rate via the μ-neutrality result
>   (so V, the invariant distribution, real debt, taxes, the price level, real
>   green spending, and damages all enter only through r^ss), presents the
>   interest-bill redistribution and climate cost as total steady-state
>   derivatives, and states plainly that the interior optimum (r^ss*≈−0.5%) is
>   verified numerically, exactly as the optimum-quantity-of-debt level is in
>   Aiyagari–McGrattan. It is an analytic reduction plus a numerical location, and
>   is now labeled as such.
> - **A.4 (Prop 1 boundaries).** We now state the two maintained regularity
>   conditions explicitly — strictly-positive limiting asset demand and
>   feasibility of the limiting tax — as properties of the incomplete-markets
>   calibration rather than implications of the feasibility assumption, and we
>   add the negative-real-rate case (the interest-service term aids feasibility
>   as P falls).
> - **A.5 (Prop 3(iii) progressivity).** Scoped. The Gini establishes
>   progressivity by wealth rank only; progressivity relative to income,
>   consumption, or welfare is the numerical welfare-by-group finding, not a
>   corollary of the Gini, and the text now says so.
> - **A.8 label.** Fixed: the price-level ordering uses P*_lump-sum, and we note
>   all four regimes are balanced stationary tax-incidence comparisons.
>
> On the broader points: the tax semi-elasticity is now documented as a map in
> the main text (a table across borrowing limit, income risk, risk aversion, and
> debt target, plus the lump-sum-versus-levy sign flip and the constrained share
> of the demand shift), not merely as a package diagnostic; the abstract now
> flags the one-asset magnitudes as upper bounds scaling with the liquid
> nominal-government-debt share; the θ_g thresholds are presented strictly as
> internal technology frontiers with the mitigation/adaptation straddle and the
> outstanding physical calibration named; the announcement contrast is presented
> strictly as an internal DTPL prediction, with the opposite-signed NK result not
> leaned on absent a matched experiment; and the fixed-real financing table is
> now populated, confirming the incidence conclusion is convention-independent.

---

# Round 9 additions — matched experiment + structural trim

## New run (Dynare machine)
```matlab
cd research_green_deficits          % MATLAB with the heterogeneity-framework Dynare
main_project_transition             % if transition_results.mat is stale
cd dynare
run_matched_dtpl_nk                 % the matched DTPL-vs-NK announcement experiment
```
Writes `output/tables/matched_dtpl_nk.txt` with the announcement-window
inflation signs under the matched design (permanent path, DTPL scale, balanced
financing, labor margin shut, pure Taylor) and a SIGN VERDICT line. The paper's
§6.3 references the driver; quote the numbers only after this run.

## Structural trim done in the paper
The worked-example detail (parameters, benchmark table, ν(θ_g) sweep) and the
optimal-accommodation exercise now live in Appendix "Supplementary results";
the body keeps a one-paragraph worked example (with the demand-shift figure)
and a one-paragraph optimal-real-rate summary.

---

# Round 10 — decile-resolution incidence (+ the standing Round 9 runs)

## Run this (MATLAB, from `research_green_deficits/`)
```matlab
cd research_green_deficits
% prerequisites if their .mat files are stale or missing:
main_project_calibrated       % -> output/calibrated_results.mat
main_project_regimes          % -> output/regimes_results.mat
% the new driver:
welfare_incidence_deciles     % -> output/welfare_deciles_results.mat
                              %    + output/tables/welfare_deciles.txt
export_paper_numbers          % writes the \WDec* / \R*DecBot|DecTop|TopOne macros
```
Then recompile the paper. The "Decile resolution" paragraph in the
welfare-incidence subsection switches from "--" placeholders to numbers.

**What to check in `output/tables/welfare_deciles.txt`:**
- decile means should average to the aggregate (the driver warns if not);
- the lump-sum gradient should be monotone bottom-up (D1 worst), and the
  rebate gradient should reverse it, matching the quintile table's message;
- top-1% wealth share: expect well below the ~1/3 U.S. share (thin
  one-asset tail) — this number feeds the paper's tail-honesty caveat.

## Still pending from Round 9 (Dynare machine)
```matlab
cd research_green_deficits
main_project_transition       % if transition_results.mat is stale
cd dynare
run_matched_dtpl_nk           % -> output/tables/matched_dtpl_nk.txt (SIGN VERDICT)
```
Optionally commit `output/tax_elasticity_results.mat` so export_paper_numbers
repopulates the eps* macros automatically instead of the hand transcription.

---

# Round 11 — EGM cross-validation (accuracy + speed audit)

Rounds 9–10 are DONE (matched_dtpl_nk verdict OPPOSITE, banked in the paper;
decile macros populated). One new run:

## Run this (MATLAB, from `research_green_deficits/`)
```matlab
cd research_green_deficits
verify_egm_vs_vfi        % -> output/egm_validation_results.mat
                         %    + output/tables/egm_validation.txt
```
Solves the calibrated base/program steady states (all three damage columns)
under BOTH household solvers — the incumbent grid-choice VFI and the new
endogenous-grid method (continuous policies + Young-lottery distribution,
opt-in anywhere via `pg.hh_solver = 'egm'`) — and reports agreement in
(S, W, Gini), off-grid Euler-equation errors for both on one scale, and
wall-clock per solve.

**Decision rule (pre-registered in the driver header):**
- max |S_egm/S_vfi − 1| < 5e-4  →  published numbers are solver-robust;
  EGM can become the default for speed with no result change.
- larger  →  the finer-Euler-error solver (expected: EGM) is the accuracy
  benchmark; re-run affected tables with `pg.hh_solver='egm'` before the
  next submission.

**Push back:** `output/tables/egm_validation.txt` (+ the .mat). If the
verdict is "solver-robust", the paper's numerical appendix already carries
the right sentence; if not, say so and I will re-wire the affected drivers.

---

# Round 12 — EGM becomes the default + wealth-concentration fit

Round 11 verdict (banked): EGM cuts mean Euler errors 1e-2.1 -> 1e-5.4 at a
third of the wall-clock, but S differs by up to 3.7e-3 relative — above the
paper's reporting precision. Per the pre-registered rule, EGM is now the
pipeline default (`pg.hh_solver = 'egm'` in setup_params_green), so the
steady-state tables need ONE regeneration pass.

## Run this (MATLAB, from `research_green_deficits/`)
```matlab
cd research_green_deficits
run_green_deficits_master     % full regeneration under the EGM default
                              % (includes the new wealth_concentration_fit
                              %  stage and refreshes numbers_auto.tex)
```
If a full master pass is too long, the minimum set that feeds the paper:
```matlab
main_project_calibrated; main_project_regimes; regimes_fixed_real;
main_project_robustness; decompose_tax_elasticity;
welfare_incidence_deciles; wealth_concentration_fit; export_paper_numbers
```

## What to check / push back
- `output/tables/wealth_fit.txt`: the sweep should bracket the 33% top-1%
  target; check the `topnode` column stays < 1e-4 (otherwise raise amax —
  tell me and I'll wire a grid extension); the Stage-2 block reports how
  nu_reval and the decile gradient move under the fitted concentration.
- Push ALL of `output/` + regenerated `paper/numbers_auto.tex`.
- NOTE for me (Claude), after your push: reconcile the HARD-CODED numbers
  (Table "incidence" quintiles, extended-run values in §5.3, worked-example
  table, in-text P*/tau values) against the regenerated output — macros
  update themselves, typed numbers do not.
- If transition residuals degrade under the EGM terminal steady state
  (check `transition_dtpl_summary.txt`), set `pg.hh_solver='vfi'` for the
  transition stage only and tell me.

---

# Round 12b — SSJ Newton fix (after the EGM default flip)

## What broke and why
`verify_transition_ssj` diverged (residual 0.038 -> 11 -> Inf, singular-J
warnings): the transition's boundary objects (steady states, terminal V,
initial distribution) were being solved by the NEW EGM default while the
transition interior and its finite-difference Jacobian run the grid-choice
backward recursion — an inconsistent linearization. The Anderson solver
survived (it only needs residuals); the Newton did not.

## The fix (already committed)
1. `solve_hank_dtpl_transition` and `solve_transition_ssj` now pin their
   LOCAL params copy to `hh_solver='vfi'`, so tier-2 is a self-contained
   grid-choice object regardless of the global EGM default.
2. The SSJ Newton is hardened: nonfinite-J/residual guards, pinv fallback
   when rcond(J) < 1e-14, and a backtracking line search (step halved up to
   7 times; only strictly-descending finite steps accepted).

## Re-run (MATLAB; regenerates the transition family under the pin)
```matlab
cd research_green_deficits
main_project_transition           % boundaries back to the VFI steady states
main_project_transition_welfare
verify_transition_ssj             % should now converge as in Round 8
export_paper_numbers
cd dynare
run_matched_dtpl_nk               % DTPL side re-read from transition_results
```
Expect: Anderson and Newton agree again; the Newton log may print
"(step damped to ...)" once or twice — that is the line search working, not
a problem. Boundary P0 returns to ~0.9051 (VFI), while the EGM steady-state
tables show ~0.9033 — the appendix now discloses this 0.4%-bounded solver
gap explicitly. Push output/ + numbers_auto.tex as usual.

---

# Round 13 — referee response + remaining runs

## Status of your last push (what I verified)
- Transition family regenerated under the VFI pin: lumpsum REPORTABLE
  (impact 0.9607, front-loading 77.1%, reval -5.32% of PV); rebate
  REPORTABLE (+12.80 impact, levy +17.19% of PV). Matched verdict OPPOSITE
  unchanged. Steady-state tables did NOT regenerate (numbers_auto.tex
  unchanged) — so the draft is still uniformly VFI-based and internally
  consistent.
- verify_transition_ssj: the hardened Newton no longer crashes but STALLED
  at the initial bridge (transition_ssj.txt records disagreement with
  Anderson). Diagnosis: fd_step 1e-4 is below the grid-flip resolution of
  the discrete-choice residual, so the Jacobian was noise. FIXED: default
  fd_step now 5e-3 with adaptive enlargement when the line search finds no
  descent.
- wealth_concentration_fit has NOT run yet (no wealth_fit.txt in output).

## Run next (MATLAB)
```matlab
cd research_green_deficits
verify_transition_ssj         % rerun with the adaptive chord Jacobian;
                              % expect agreement with Anderson now
wealth_concentration_fit      % still pending from Round 12
export_paper_numbers
```
(The full EGM steady-state regeneration remains a pre-submission step; the
draft is currently consistent on the grid-choice solver, as the numerical
appendix states.)

## Referee round (this round) — what was implemented
- #1 (A.8): the P-ranking -> nu_reval-ranking step now carries the r^ss>0
  scope restriction, in the proof and at the Table 6 pointer.
- #2 (Sec 4.4): comparative statics aligned with the measured map — sign
  driven by the constrained mass (pivotal primitive: borrowing limit; flips
  only at the loose corner), magnitude explicitly non-monotone in the other
  primitives, deferring to Table 4 instead of asserting monotonicity.
- #3 (A.5): exposure vs signed incidence separated — concentration makes a
  levy (L>0) progressive and a windfall (L<0, the lump-sum benchmark case)
  regressive; matches Prop 3(iii)'s sign convention.
- Broad 1 (magnitudes): omega-scaled counterparts now attached at the 6.3
  headline sites (3.9% impact -> ~0.6–1.0%; +12.8% rebate -> ~2–3%);
  shares/signs flagged as scale-free; two-asset endogenous-convenience-yield
  DTPL named as the outstanding item (unchanged).
- Broad 2 (elasticity discipline): new "Observable counterparts" paragraph —
  constrained share 17.7% vs ~1/3 hand-to-mouth (Kaplan–Violante–Weidner
  2014), MPC evidence (Kaplan–Moll–Violante 2018); sign disciplined,
  magnitude bounded-not-trained.
- Broad 4 (incidence accounting): Table 5 caption now states households are
  evaluated at the same real asset position across invariant distributions
  (no predetermined-claim revaluation in those numbers); 5.8's "windfall"
  language recast as the steady-state FLOW counterpart with the stock
  revaluation pointed to 6.3.
- Broad 5 (commitment): Section 6.3 now closes with an explicit
  perfect-foresight-benchmark scope statement (partial credibility spreads
  the capitalization; terminal steady states unchanged; belief block out of
  scope).
- Broad 3 (theta_g): already contour-framed from earlier rounds; no change.
