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
