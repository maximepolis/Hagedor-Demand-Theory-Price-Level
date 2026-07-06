# Transition validation (U6 RANK/NK + U7 tier-1 HANK)

*Records the verified transition runs, the validation criteria each path
must pass before it may be reported, and the honest scope of each tier.
Companion machine-written files (regenerated on every run):
`output/tables/rank_transition_validation.txt` and
`output/tables/hank_tier1_validation.txt`.*

## Scope labels (project standard)

| tier | label | what it is NOT |
|---|---|---|
| U6 `green_rank_nk.mod` | RANK/NK TRANSITION DIAGNOSTIC | not the DTPL price-level mechanism; inflation from NKPC + policy rule |
| U7 tier 1 `green_hank.mod` | TIER-1 LINEARIZED HANK IRF | not nonlinear DTPL price-level determination; a bridge, not the final answer |
| U7 tier 1b `green_hank2.mod` | TIER-1 LINEARIZED HANK IRF (two-asset) | FIRST RUN OSCILLATORY + crash -- NOT REPORTABLE until the accuracy protocol passes |
| U7 tier 2 `solve_hank_dtpl_transition.m` | NONLINEAR HANK-DTPL TRANSITION | v1 IMPLEMENTED, run pending; a non-converged path is not a result |

## Validation criteria (enforced by the drivers, unconverged paths discarded)

1. `oo_.deterministic_simulation.status` must be true (U6) / the
   heterogeneity solver must return IRFs (U7) — a failed Newton iterate is
   never reported (this discipline caught the first run's garbage paths).
2. Mechanical identity: `kg_t = (1-delta_g) kg_{t-1} + gg_t` to 1e-6 on all
   interior columns (the appended terminal-steady-state column is excluded;
   it sits a truncation gap ~ kg_gap*0.975^300 ≈ 3.4e-4 off the law, which
   is a property of horizon truncation, not of the solution).
3. Steady states computed exactly by `green_rank_nk_steadystate.m` /
   `heterogeneity_compute_steady_state` (no hand-tuned initval); the Dynare
   log prints market-clearing residuals (tol 1e-4 for the HANK tier).

## Verified U6 run (user machine, Dynare 8-unstable-2026-05-19)

All four regimes CONVERGED (solver residuals ~1e-14 after the chained
calls; every path passed the kg-law check).

| regime | pi impact (ann.) | pi peak (qtr) | debt peak | kg(40q) | d(40q) |
|---|---|---|---|---|---|
| WEAK       | −0.04% | +0.0039 | 1.004 | 0.349 | 0.0925 |
| TAYLOR     | −0.52% | +0.0007 | 1.004 | 0.349 | 0.0925 |
| AGGRESSIVE | −0.24% | +0.0003 | 1.004 | 0.349 | 0.0925 |
| GREENACCOM | +22.55% | +0.0564 | 1.004 | 0.349 | 0.0933 |

(Initial steady state: d = 0.0972, kg = 0; terminal: d = 0.0601, kg = 0.6.)

**Interpretation.**
- Tax-financed ramped program ⇒ essentially price-stable under any active
  rule (impact between −0.5% and 0.0% annualized; peak < +1.6% annualized).
- Real green transition is regime-independent: kg(40q) and d(40q)
  identical to three decimals across the active rules.
- GREENACCOM is a deliberately LARGE experiment (psi_g = 0.03 × kg-gap 0.6
  ≈ 1.8pp quarterly ≈ 7.2pp annualized initial cut). It yields a +22.6%
  annualized impact-inflation spike, the same kg(40q), and slightly HIGHER
  damages (output boom ⇒ more emissions): accommodation buys inflation,
  not green capital.
- FISCAL NOTE: the U6 tax rule finances gg contemporaneously by design;
  the deficit-financing experiments live in the steady-state MATLAB block
  and the HANK tier.

## Verified U7 tier-1 HANK run (user machine)

All four regimes SOLVED (IRF horizon 200; calibrated beta = 0.979640,
B = 3.96 targeting debt/annual-GDP = 1.10 at the damaged steady state).
IRFs to a one-std e_g shock (0.009 ≈ 1% of output, rho_g = 0.995,
deficit-financed on impact, phi_b = 0.10):

| regime | pi impact (ann.) | Y impact | b(40q) | kg(40q) | d(40q) |
|---|---|---|---|---|---|
| WEAK       | +2.18% | +0.0042 | +0.1023 | +0.2048 | −0.0039 |
| TAYLOR     | +0.31% | +0.0044 | +0.1023 | +0.2048 | −0.0039 |
| AGGRESSIVE | +0.07% | +0.0045 | +0.1022 | +0.2048 | −0.0039 |
| GREENACCOM | +0.53% | +0.0044 | +0.1023 | +0.2048 | −0.0039 |

**Interpretation.**
- DEFICIT financing flips the impact-inflation sign relative to the
  tax-financed U6 diagnostics (+ across all rules here vs − there); the
  size of the inflation impact is almost entirely a monetary-rule choice
  (+2.18% → +0.07% across rules).
- The real green path is again rule-independent (kg, d identical to three
  decimals across regimes) — the U6 finding survives heterogeneity and
  Fisher redistribution.
- Debt rises 0.102 (~2.6% of the stock) by 40 quarters vs a flat debt
  path in tax-financed U6.

Caveats (also printed in the validation file): income process is the
Dynare-example 3-state Rouwenhorst (rho_e = 0.966, sig_e = 0.5), NOT the
quantitative model's 7-state process — magnitudes indicative; alignment
is future work.

**TAYLORBAL run (VERIFIED):** near-balanced financing (PHIB = 0.75) of
the identical program under the Taylor rule gives pi impact +0.23%
annualized (vs +0.31% deficit-financed), Y impact +0.0048, b(40q) +0.0117
(vs +0.1023). READING: within the linearized HANK, **deficit financing
buys the debt path, not the inflation path** — the debt buildup is almost
entirely a financing choice (10× smaller under fast taxes) while impact
inflation barely moves; the mild inflation belongs to the unanticipated
program itself, its size set by the monetary rule. The steady-state DTPL
is where the financing margin moves the price level (through asset-demand
incidence) — a mechanism the linearized NKPC cannot represent, so the
contrast between tiers is itself informative (stated in the paper).

## U7 tier 1b: TWO-ASSET green HANK (green_hank2.mod) — RUN PENDING

Extended tier following the verified `heterogeneity/hank_two_assets_
steady_state.mod` example: liquid nominal bonds vs illiquid
equity/capital (chi0/chi1/chi2 convex adjustment costs), sticky wages AND
prices, capital/investment/Tobin-Q/equity pricing, ENDOGENOUS government
debt with the PHIB financing-speed margin, liquid-bond supply = lamB*bg
(a deficit-financed program changes the supply of liquid safe assets —
the dynamic counterpart of the paper's B/P margin), climate block on TFP.
Driver `run_green_hank2.m`: WEAK / TAYLOR / GREENACCOM / TAYLORBAL,
PFig17, hank2_irfs_summary.txt + hank2_validation.txt. Grids ne=3, nb=10,
na=20 (verified-example values — COARSE, magnitudes indicative);
NE/RHOE/SIGE macro-defines expose the income process for future
alignment with the MATLAB package's 7-state process.

## Tier-1b accuracy incident (recorded, not hidden)

First tier-1b run: WEAK/TAYLOR/GREENACCOM solved, final regime crashed
MATLAB, and the IRFs showed a pronounced oscillatory pattern -- a
numerical red flag, treated as such. Diagnosis (ranked): (1) shock
persistence 0.995 (half-life 138q) too close to the 300-quarter
sequence-space truncation horizon => reflection artifacts; (2) coarse
example grids (nb=10, na=20); (3) near-unit-root debt under slow
financing interacting with (1). Fixes in green_hank2.mod +
run_green_hank2.m: rho_g -> 0.98 with THORIZON=400 default; NB/NA/THORIZON
defines; oscillation diagnostic (sign flips of the differenced IRF over
q20-120, tol 8) marking suspect paths NOT REPORTABLE; refinement re-solve
(THORIZON=600, nb=20, na=40) with a 10% max-relative-deviation PASS rule;
memory hygiene between solves + REGIME_ONLY single-session mode with
cross-session accumulation for the crash. REPORTING RULE: no tier-1b
number enters the paper unless oscillation check AND refinement pass
both pass. The incident and the protocol are disclosed in the paper.

## Tier-2 validation criteria (for the pending first run)

1. Market-clearing residuals |S_t - b_t|/b_t reported at EVERY date; the
   converged tolerance is 2e-3; a non-converged path is labeled so.
2. Boundary consistency: phat_1..T must start from the announcement jump
   and end at the green steady-state price (terminal condition pinned).
3. Government budget holds by construction at every trial path
   (tau_t = rbar*b_t + g_t) -- not a residual, an identity.
4. The t=1 revaluation and the steady-state comparison nu_reval must
   agree in sign (cross-check against the S4 decomposition).
5. FAST pass (na=150, T=100) before the full run (na=500, T=150).

## Tier-1b second run (protocol result) + fixes

Second run (with the accuracy protocol): WEAK/TAYLOR/GREENACCOM solved
with plausible impacts (pi impact -0.27%/-0.53%/-0.30% annualized -- note
the possible SIGN REVERSAL vs the one-asset tier; NOT reportable until
the oscillation + refinement protocol passes on the fixed model);
TAYLORBAL returned an EXPLOSIVE pseudo-solution (pi impact -10.59
QUARTERLY, equity price +181) that the old summary writer recorded as if
it were a result.

ROOT CAUSE (adversarial equation-level audit, CONFIRMED): the firm
cash-flow identity div = Y - w*N - I - psip was DROPPED in adapting the
reference two-asset model. We had copied the STEADY-STATE-calibration
variant (hank_two_assets_steady_state.mod), which omits that identity
because it uses BOTH asset-market clearings as calibration targets;
the dedicated DYNAMICS example (hank_two_assets.mod l.160) carries the
identity and only ONE clearing. Without it, div is defined residually by
equity pricing, which forces ra = r identically for all t (the equity
valuation channel is destroyed, p is unanchored) and violates
goods-market feasibility out of steady state -- invisible at the steady
state (verified: div_ss = 0.14 = r_ss*p_ss both ways), explosive in the
dynamics.

An EARLIER hypothesis -- that the tax rule's contemporaneous-wage-bill
denominator caused the blow-up -- was REFUTED by the audit: that
denominator multiplies a zero debt gap at the steady state, so it is
first-order irrelevant to the linearized solution. (The rule was still
switched to the steady-state wage bill wN_ss for a clean lump-sum
reading, but that was not the fix.)

Fixes applied:
1. RESTORE the dividend identity div = Y - w*N - I - psip;
2. make the liquidity premium omega an ENDOGENOUS convenience yield that
   clears the liquid-bond market (rb = r - omega_t), chi1 fixed at 6.416
   -- this re-anchors the equity price AND makes the price of liquid
   nominal safe assets a plotted equilibrium object (on-theme);
3. calibration targets reduced to Wage Phillips curve + Illiquid clearing
   (2 targets, 2 free params beta_ss, vphi);
4. DIVERGENCE GATE: any path with |pi| > 5% quarterly, |Y| > 0.25, or
   |bg| > 5 is excluded from every output (applies to restored results);
5. grid defaults raised to nb=15, na=30; rho_g 0.98 / THORIZON 400;
6. TAYLORBAL restored to the documented phi_b = 0.75 (the divergence was
   never about phi_b);
7. oscillation diagnostic + refinement pass gate reporting as before.

Tier-1 note: the same oscillation diagnostic is now wired into
run_green_hank.m, and RHOG/THORIZON defines allow re-verification of the
tier-1 numbers at rho_g = 0.98 / horizon 400 (requested; the paper's
tier-1 numbers keep their verified-run label meanwhile).

## Tier-1b third run: solved-but-NaN, and the omega-timing fix

Third run (post-dividend-identity model): all four regimes SOLVED incl.
TAYLORBAL (chi1 fixed at 6.416, beta_ss* = 0.9706) -- but every IRF was
NaN. Cause: with rb_t = r_t - omega_t, date-t omega touches only the
return on PREDETERMINED holdings (income effect), so the liquid-clearing
condition faced a nearly powerless instrument: near-singular linearized
system, NaN solution. Fix: ISSUANCE timing, rb_t = r_t - omega_{t-1} --
the premium set at issuance directly prices the bonds households choose
at t through the liquid Euler (steady state unchanged).

Driver holes closed at the same time: NaN passes any '>' comparison in
MATLAB, so NaN paths slipped through the divergence gate, were
checkpointed, and (restored on the second invocation) triggered the heavy
accuracy pass = the MATLAB crash. Both HANK drivers now gate on
finiteness at solve AND restore; the accuracy refinement is lightened to
THORIZON=500/nb=20/na=40 with SPAWN_MATLAB recommended for it.

## Tier-1b run 4 and the closure decision (final)

Run 4 (issuance-timing endogenous omega, rb_t = r_t - omega_{t-1}):
heterogeneity.solve reported "Matrix is singular ... RCOND = NaN" and NaN
IRFs in all regimes; the drivers' finiteness gates excluded everything
(correct behavior -- nothing bogus written, no crash). DIAGNOSIS: in the
TRUNCATED sequence-space system the terminal omega_T enters no equation
inside the horizon (its only appearance is rb_{T+1}) -- an exactly-zero
Jacobian column. The contemporaneous timing (run 3) has the mirror-image
near-singularity at the impact date (income effect on predetermined
holdings only). CONCLUSION: "omega clears the liquid market" is
boundary-singular in this framework under either timing.

DECISION: adopt the reference DYNAMICS example's own closure
(hank_two_assets.mod): dividend identity + ONE total-wealth clearing
(p + bg - SUM(a) - SUM(b)) + constant premium omega = 0.005, chi1 fixed
at the example's calibrated 6.416419681906506; calibration targets reduce
to (Wage Phillips curve -> vphi, total-wealth clearing -> beta_ss). The
liquid tranche lamB*bg is a reported DIAGNOSTIC, not an imposed
constraint; the endogenous convenience-yield channel is PROPOSED (needs
either a non-truncated method or a premium specification with interior
instruments at both boundaries).

OPEN ITEM for the next run's log: the run-4 steady state printed
household Euler residuals ~11 (infinite-norm over the grid) where the
one-asset example prints ~1e-10. If these persist under the reference
closure while aggregate residuals are ~0 and IRFs are finite and smooth,
they are likely raw complementarity/kink-point residuals of the two-asset
policies (constrained gridpoints violate the unconstrained Euler by
construction); if IRFs remain suspect, this becomes the next
investigation target.
