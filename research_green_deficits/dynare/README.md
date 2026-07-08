# Dynare block — transition dynamics

**Status: IMPLEMENTED at the RANK tier (U6) and at the HANK tier-1
(U7, native heterogeneity framework); both runs pending on the user's
machine.**

## Files

| file | tier | what it produces |
|---|---|---|
| `green_rank_nk.mod` + `run_green_transitions.m` | U6 RANK | nonlinear perfect-foresight **transition paths** for the permanent program, four regimes, PFig13 |
| `green_hank.mod` + `run_green_hank.m` | U7 tier 1 HANK | **linearized sequence-space IRFs** to a quasi-permanent green-investment shock, five regimes incl. the TAYLORBAL financing comparator, PFig14 (requires the Dynare heterogeneity framework — the version that ran `heterogeneity/hank_one_asset_steady_state.mod`) |
| `green_hank2.mod` + `run_green_hank2.m` | U7 tier 1b HANK (two-asset) | liquid nominal bonds vs illiquid equity/capital (KMV/ABRS structure, from the verified `hank_two_assets` example), sticky wages+prices, Tobin-Q investment, ENDOGENOUS government debt with the PHIB financing-speed margin, climate block on TFP; four regimes, PFig17. **NOW SOLVES (run 6, 2026-07-07): the chi2=2 smoothing fix (removing the sequence-space Jacobian NaN from sign()/abs()^(chi2-1) kink derivatives at the illiquid-constraint corner) + the base-workspace IRF-harvest fix in `solve_hank_regime_batch.m` took the tier through — all four regimes solve, finite non-divergent IRFs, oscillation-clean. OPT-IN (`TIER1B_FORCE = true; run_green_hank2`, ~70 min). Magnitudes NOT YET REPORTED: refinement re-solve pending** |
| `green_rank_nk_steadystate.m` | U6 | exact steady states for any program size |

The HANK tier-1 model carries the paper's *redistribution* channel in
linearized form (nominal policy rate + ex-post Fisher equation, so surprise
inflation revalues household asset positions across the wealth
distribution) but **not** the DTPL price-*level* mechanism; the nonlinear
P\* transition is tier 2, implemented in pure MATLAB outside this Dynare
block (`src_project/solve_hank_dtpl_transition.m` +
`main_project_transition.m`; run VERIFIED & REPORTABLE 2026-07-07,
na=500, T=80, Anderson-accelerated).

`green_rank_nk.mod` is a representative-agent New Keynesian skeleton
(Rotemberg pricing, inertial Taylor rule, real debt with a debt-stabilizing
tax rule, green public capital, carbon stock, TFP damages). Running

```
dynare green_rank_nk
```

produces perfect-foresight **transition paths** for a permanent
deficit-financed green-investment program (output, inflation, debt, green
capital, carbon stock, damages, taxes) — the tier-1 answer to referee risk
R1 ("only steady state").

**Honest scope limits:**

- This block does **not** contain the paper's price-level mechanism. The
  DTPL requires incomplete markets; in RANK, inflation dynamics come from
  the Taylor rule + Phillips curve, and the price *level* is not pinned by
  asset demand. Use it only for transition shapes of the real/nominal block.
- Roadmap step U7 is now split and largely done: tier-1 linearized HANK
  IRFs run here (`green_hank.mod`, VERIFIED), and the nonlinear DTPL
  P\* transition runs in pure MATLAB
  (`main_project_transition`, VERIFIED & REPORTABLE). The belief-switch
  experiment between green-boom and brown-stagnation equilibria (where
  they exist) remains **NOT YET IMPLEMENTED**.
- The calibration is quarterly and illustrative; the steady-state block may
  need `initval` tuning depending on your Dynare version. Treat failures of
  `steady` as calibration issues in this skeleton, not as statements about
  the paper's model.

**Four-regime comparison (implemented):** `run_green_transitions.m` runs
the .mod under WEAK / TAYLOR / AGGRESSIVE / GREENACCOM (temporary
accommodation tied to the green-capital gap, fading as kg converges),
collects the perfect-foresight paths, and produces PFig13 plus
`transitions_summary.txt`. Steady states are computed exactly for any
program size by `green_rank_nk_steadystate.m` (fixed point over damages,
bisection on labor) -- no hand-tuned initval.

## Crash resilience (HANK tiers)

The Dynare 8-unstable heterogeneity framework has hard-crashed MATLAB
when several heavy solves run in one session (first observed in the
final tier-1b regime; a hard process crash cannot be caught by
try/catch). Both HANK drivers are engineered around it, three layers:

0. **Tier-1b is EXPERIMENTAL and opt-in.** The two-asset solves are the
   crash source; `run_green_hank2` is excluded from the master pipeline
   and, when run manually, executes each regime in its own disposable
   MATLAB process **by default** (invoked via the running installation's
   exact executable — no PATH setup). A Dynare crash can no longer kill
   your session under the defaults.
1. **Checkpoint-resume (automatic).** Results are saved after EVERY
   regime; on the next run, solved regimes restore from
   `output/hank*_green_irfs.mat` and only the missing ones solve. After
   a crash: just re-run the same script. `FORCE_RERUN = true` re-solves
   everything. Checkpoints are stamped with the `.mod` file's
   fingerprint, so a checkpoint written under an older model version is
   ignored automatically (never restores pre-fix runs).
2. **Process isolation (`SPAWN_MATLAB = true`).** Each regime runs in a
   fresh `matlab -batch` child (`solve_hank_regime_batch.m`; requires
   `matlab` on the system PATH). If Dynare dies, only the child dies —
   the parent session records the failure and continues. This is the
   configuration that guarantees your session survives.
3. **Memory hygiene** between in-session solves (figures closed,
   generated functions and MEX cleared, previous solve's `M_`/`oo_`
   dropped), and the tier-1b **accuracy refinement pass** — the heaviest
   solve — is deferred to a fresh session by default (it runs when all
   main regimes come from checkpoint, or with `RUN_ACCURACY = true`).

**Convergence notes (from the first two runs):**

- A pure interest-rate peg (`phi_pi = 0`, and even `phi_pi = 1.01`)
  violates or barely satisfies the Taylor principle and leaves the stacked
  perfect-foresight Newton system singular or near-singular; the near-peg
  corner is therefore represented by WEAK (`phi_pi = 1.1`, `rho_i = 0.5`).
- GREENACCOM uses `psi_g = 0.03`. With a peak kg-gap of 0.6 this is a
  **large** accommodation experiment — ~1.8pp quarterly (~7.2pp
  annualized) initial rate cut, fading with the gap — deliberately sized
  to make the accommodation channel visible (the verified run shows a
  +22.6% annualized impact-inflation spike against −0.5% under TAYLOR).
  Values much beyond this destroy convergence.
- The program **ramps in linearly over 12 quarters** (implementation
  delays, Leeper–Walker–Yang) instead of jumping — more realistic and far
  easier numerically.
- The solver call is **chained** (default, then `stack_solve_algo=6`, then
  higher `maxit`), each attempt warm-starting from the previous iterate.
- The driver enforces a **hard convergence check**
  (`oo_.deterministic_simulation.status`) plus a mechanical validation of
  the kg accumulation law; unconverged paths are discarded, never reported.
- Each regime runs as its own copy `grnk_<name>.mod` to avoid stale
  preprocessor artifacts when one .mod is re-run with different `-D`
  defines (a known failure mode on Windows).
