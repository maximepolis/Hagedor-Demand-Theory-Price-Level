% MAIN_DEFICIT_DECOMPOSITION  Separate tax timing from the terminal-debt
% ratchet, using the three cases that are actually feasible.
%
% STATUS: scaffolded and static-checked. NOT YET RUN, and NOT YET AUTHORIZED
% to run. The manuscript's phase-in result is currently an ILLUSTRATIVE JOINT
% result precisely because this experiment does not exist; nothing here may be
% cited until it has run and passed the budget identities.
%
% THE PROBLEM. Under the rule tau_t = rbar*b_t + phi_t*g_t with a delayed
% phase-in phi_t = 1 - rho^t, delaying the tax does two things at once: it
% relieves the constrained early (TIMING), and it leaves revenue permanently
% unrecovered so the detrended nominal stock ends higher (RATCHET). The
% reported critical phase-in speed therefore cannot be read as a tax-timing
% threshold.
%
% WHY THIS IS NO LONGER A 2x2. The natural fourth cell -- contemporaneous
% taxation with a ratcheted terminal debt -- is INFEASIBLE, not merely unrun.
% Under the contemporaneous service rule the primary balance is zero at every
% date, so the flow identity gives B_t = (1+i^ss)B_{t-1}, detrended debt is
% constant, and the terminal stock is pinned at its initial value. A permanent
% ratchet requires cumulative primary deficits, which that rule permits at no
% date. The derivation is in kv_fiscal_spec's header and in
% DEFICIT_DECOMPOSITION_R10.md.
%
% The previous version reached that cell by bisecting an unexplained
% `phi1_C3` -- a single unfunded issuance at t = 1 -- which IS a cumulative
% primary deficit and so is not the contemporaneous service rule at all. It
% produced a number attached to no stated fiscal experiment. It is withdrawn.
%
% THE THREE FEASIBLE PATHS
%   C1  phi_t = 1,         xi_t = 0           contemporaneous service rule
%   C2  phi_t = 1 - rho^t, xi_t = a_xi h_t    delayed tax, CONSOLIDATED back
%                                             to C1's terminal debt
%   C4  phi_t = 1 - rho^t, xi_t = 0           delayed tax, no recovery
%                                             (the manuscript's experiment)
%
% ESTIMANDS
%   tax timing at MATCHED terminal debt          = C2 - C1
%   failure to consolidate, given the same delay = C4 - C2
%   total legacy joint effect                    = C4 - C1
%
% A fully independent factorial INTERACTION is not identified with this
% instrument set. Do not report one.
%
% THE TARGET IS HIT THROUGH THE TAX PATH. C2's amplitude a_xi is solved by
% kv_solve_consolidation, which calls the transition solver repeatedly with
% kappa left FREE and reads kappa_inf back off. The terminal price is never
% overridden and the debt recursion is never replaced, so
%       B_t = (1+i^ss) B_{t-1} + P_t ( g_{g,t} - tau_t )
% remains an identity at every date. That identity is a GATE (V4/V5), not a
% diagnostic.
%
% KAPPA'S ROLE. kv_kappa_legacy is still run, but only to record the
% pre-refactor legacy dilution and to check that C4 reproduces it. It does
% NOT supply a target to any case.
%
% CONSOLIDATION PARAMETERS ARE FIXED IN THE SPEC, NOT HERE, and T_c (start
% date) and H_c (half-life) are separate symbols with separate values even
% though the baseline sets both to 10.
%
% USAGE   >> clear; main_deficit_decomposition                (one-asset)
%         >> clear; FAST = true; main_deficit_decomposition
%         >> clear; TC = 5; HC = 5; main_deficit_decomposition (AFTER gates)
%
% OUTPUT  output/tables/deficit_decomposition.txt
%         output/deficit_decomposition.mat
%
% ONE-ASSET ONLY at present. The two-asset version is blocked by the
% certification gate and would write to output/quarantine/.

clearvars -except FAST TC HC RHOBAR; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));

if ~exist('FAST','var'), FAST = false; end
if ~exist('TC','var')     || isempty(TC),     TC = 10;    end  % consolidation START
if ~exist('HC','var')     || isempty(HC),     HC = 10;    end  % consolidation HALF-LIFE
if ~exist('RHOBAR','var') || isempty(RHOBAR), RHOBAR = 0.90; end
EPS_KAPPA = 1e-8;      % terminal-debt tolerance, fixed in the spec
TOL_V4    = 1e-9;      % period identity, normalized by g
TOL_V5    = 1e-7;      % present-value identity, normalized by b0

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'deficit_decomposition.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});

tee('TAX TIMING vs TERMINAL DEBT: THE THREE-PATH DECOMPOSITION\n\n');
tee('consolidation start T_c = %d yr; consolidation half-life H_c = %d yr\n', TC, HC);
tee('(these are DIFFERENT parameters; the baseline happens to set both to 10)\n');
tee('phase-in speed rho_bar = %.3f (tax half-life %.2f yr)\n', ...
    RHOBAR, log(2)/(-log(RHOBAR)));
tee('terminal-debt tolerance eps_kappa = %.0e\n\n', EPS_KAPPA);
tee('These parameters were fixed in DEFICIT_DECOMPOSITION_R10.md before this run.\n\n');

% =====================================================================
% WHY THERE IS NO C3. Stated in the output file as well as in the source,
% because a reader of the table needs to know that the missing cell is
% infeasible rather than merely unrun.
% =====================================================================
tee('WHY THERE IS NO FOURTH CASE\n');
tee('  Under the contemporaneous service rule tau_t = rbar*b_t + g_t the\n');
tee('  primary balance is zero at every date, so\n');
tee('      B_t = (1 + i^ss) B_{t-1}   =>   detrended B is CONSTANT.\n');
tee('  Contemporaneous taxation therefore PINS terminal detrended debt at its\n');
tee('  initial value. "Contemporaneous tax + permanently higher terminal debt"\n');
tee('  is not a hard cell to compute; it is an empty one. A fully independent\n');
tee('  factorial interaction is NOT identified here and is not reported.\n\n');

% =====================================================================
% STEP 0 (NOT one of the cases): record the legacy dilution as a REFERENCE.
% It is not imposed on anything. C4 must reproduce it; that is a parity check
% on the refactor, not an experimental result.
% =====================================================================
T = 80; if FAST, T = 60; end
pgc = setup_params_green();

tee('STEP 0  legacy dilution, recorded as a reference value\n');
KB = kv_kappa_legacy(pgc, T, RHOBAR, false);
tee('  kappa^legacy = B_inf^legacy / B_inf^baseline = %.10f / %.10f = %.10f\n', ...
    KB.B_inf_legacy, KB.B_inf_baseline, KB.kappa_legacy);
tee('  cumulative tax shortfall (undiscounted) : %.10f\n', KB.cum_tax_shortfall);
tee('  discounted primary-balance gap          : %.10f\n', KB.pv_primary_gap);
tee('  impact price response vs baseline       : %+.6f log points\n', KB.dlnP0);
tee('  ROLE: reference only. NOT a target for any case.\n\n');

% =====================================================================
% The three fiscal specifications, built OUTSIDE the solver.
% =====================================================================
sopts = struct('T', T, 'rho_bar', RHOBAR, ...
               'consolidation_start', TC, 'consolidation_half_life', HC, ...
               'kappa_tol', EPS_KAPPA, 'kappa_target', 1);
SPEC = struct();
for c = {'C1','C2','C4'}
    SPEC.(c{1}) = kv_fiscal_spec(c{1}, sopts);
end

tee('CASE SPECIFICATIONS (all built by kv_fiscal_spec; the solver sees only these)\n');
for c = {'C1','C2','C4'}
    f = SPEC.(c{1});
    tee('  %-3s timing=%-16s debt=%-28s kappa_mode=%s\n', ...
        f.case_id, f.timing, f.debt_target, f.kappa_mode);
end
tee('\n  tau_t = rbar*b_t + phi_t*g_t + xi_t,   xi_t = a_xi * h_t\n');
tee('  h_t = 0 for t < T_c, then 2^(-(t-T_c)/H_c);  h(T_c) = 1\n');
tee('  a_xi is solved ONLY for C2, by kv_solve_consolidation, so that C2''s\n');
tee('  REALIZED terminal debt equals C1''s. The terminal price is never\n');
tee('  overridden and the debt recursion is never replaced.\n\n');

% Verify C3 really is refused by the builder, rather than merely absent from
% the loop above. A withdrawal that is only a comment is not a withdrawal.
c3_refused = false;
try
    kv_fiscal_spec('C3', sopts);
catch ME
    c3_refused = strcmp(ME.identifier, 'kv_fiscal_spec:C3withdrawn');
    if ~c3_refused, rethrow(ME); end
end
assert(c3_refused, 'C3 was built; the withdrawal is not enforced in kv_fiscal_spec');
tee('C3 correctly refused by the builder (kv_fiscal_spec:C3withdrawn).\n\n');

% =====================================================================
% NOT YET AUTHORIZED TO RUN. The remaining steps, in order:
%
%   1. solve C1 and C4 (both kappa FREE; nothing is targeted)
%   2. solve C2 by kv_solve_consolidation: bisect a_xi so that
%      |kappa_inf^{C2} / kappa_inf^{C1} - 1| < EPS_KAPPA
%   3. verify C4's kappa_inf reproduces KB.kappa_legacy -- a PARITY check
%   4. budget identities V1-V7 (DEFICIT_DECOMPOSITION_R10.md); V4 and V5 in
%      particular catch a rule change that silently alters the real program,
%      which is the failure mode that would make the whole exercise meaningless
%   5. estimands, only if 3 and 4 pass:
%        tax timing at matched terminal debt          = C2 - C1
%        failure to consolidate, given the same delay = C4 - C2
%        total legacy joint effect                    = C4 - C1
%   6. the within-case decomposition of the impact response
%
% Steps 1-2 require the D11 THREE-WAY parity test to have PASSED against the
% pre-refactor baseline at bf0a4e8. That test has not been run in this
% environment and no parity is claimed.
% =====================================================================
% =====================================================================
% AUTHORIZED 2026-08-05. The gate this driver waited on was the D11
% three-way parity test against the pre-refactor baseline at bf0a4e8. It has
% now run and PASSED: 48 fields exact across all three legs, with the
% nominal-neutrality gap exactly zero. The block below is what the header
% listed as steps 1-6.
%
% THE PARAMETER VECTOR IS THE LEGACY ONE, NOT setup_params_green's DEFAULT.
% This is the defect that has broken two drivers in this project: passing the
% default beta leaves no root in the solver's [0.5, 1.3] bracket and the
% baseline steady state does not exist. Every transition driver calls
% kv_legacy_transition_setup, and so does this one.
% =====================================================================
[pgc_run, opts_run, calinfo] = kv_legacy_transition_setup(FAST);
opts_run.T = T; opts_run.verbose = false;
% REGIME IS NOT A FREE CHOICE HERE, AND MUST NOT BE "TIDIED" TO 'nominal'.
% Supplying opts.fiscal sets deficit = true inside the solver, and the solver
% then asserts regime = 'indexed'. The assertion is economics, not
% bookkeeping: this experiment holds the REAL program fixed so that ONLY the
% tax timing differs between C1, C2 and C4. Under a nominal appropriation the
% terminal dilution would shrink the real program, so C4's higher terminal
% debt would buy a SMALLER programme than C1's -- and the difference C4 - C1
% would then mix tax timing, the debt ratchet, and a change in the size of the
% thing being financed. An earlier version of this block set 'nominal' and the
% assertion caught it before a single transition had been solved.
opts_run.regime = 'indexed';
tee('STEP 1  solving C1 and C4 (kappa FREE in both; nothing is targeted)\n');
tee('  parameters: beta*=%.6f  D0=%.3f  Gg_nom=%.6f  T=%d  (legacy setup)\n', ...
    pgc_run.beta, pgc_run.D0, opts_run.Gg_nom, T);

SOL = struct();
for c = {'C1','C4'}
    o = opts_run; o.fiscal = SPEC.(c{1});
    SOL.(c{1}) = solve_hank_dtpl_transition(pgc_run, o);
    tee('  %-3s converged=%d horizon_ok=%d  kappa_inf=%.10f  dlnP1=%+0.6f\n', ...
        c{1}, SOL.(c{1}).converged, SOL.(c{1}).horizon_ok, ...
        SOL.(c{1}).kappa_inf, log(SOL.(c{1}).phat(1)/SOL.(c{1}).P0));
end

% ---- STEP 2: C2, by solving the surcharge amplitude ---------------------
tee('\nSTEP 2  solving C2''s consolidation amplitude a_xi so that C2''s REALIZED\n');
tee('        terminal debt equals C1''s. kappa is FREE at every evaluation.\n');
kappa_C1 = SOL.C1.kappa_inf;
RC2 = kv_solve_consolidation(pgc_run, opts_run, sopts, kappa_C1, tee);
tee('  status=%s  a_xi=%.10f  kappa_inf=%.10f  gap=%.3e  hit=%d  (%d iters)\n', ...
    RC2.status, RC2.a_xi, RC2.kappa_inf, RC2.gap, RC2.hit, RC2.iters);
SOL.C2 = RC2.TR;

% ---- STEP 3: parity of C4 against the legacy dilution -------------------
tee('\nSTEP 3  PARITY: C4''s realized dilution against the legacy reference\n');
kappa_C4 = SOL.C4.kappa_inf;
par_gap  = abs(kappa_C4 / KB.kappa_legacy - 1);
tee('  kappa_inf^C4 = %.10f   kappa^legacy = %.10f   rel gap = %.3e\n', ...
    kappa_C4, KB.kappa_legacy, par_gap);
par_ok = par_gap < 1e-6;
tee('  %s\n', ternstr(par_ok, 'PARITY OK: C4 reproduces the manuscript experiment', ...
    'PARITY FAILED: C4 is not the manuscript experiment -- estimands withheld'));

% ---- STEP 4: budget identities -----------------------------------------
tee('\nSTEP 4  budget identities (V1-V7). Period residual is normalized by\n');
tee('        program expenditure, present-value residual by initial debt.\n');
tee('  %-3s %14s %14s %10s %10s\n', 'case', 'max|V4 period|', 'V5 PV resid', 'V4 gate', 'V5 gate');
BID = struct(); all_budget_ok = true;
for c = {'C1','C2','C4'}
    B = kv_budget_identities(SOL.(c{1}), pgc_run, opts_run);
    BID.(c{1}) = B;
    ok4 = B.max_period_resid < TOL_V4;
    ok5 = B.pv_resid < TOL_V5;
    all_budget_ok = all_budget_ok && ok4 && ok5;
    tee('  %-3s %14.3e %14.3e %10s %10s\n', c{1}, B.max_period_resid, B.pv_resid, ...
        ternstr(ok4,'PASS','FAIL'), ternstr(ok5,'PASS','FAIL'));
end
tee('  thresholds: V4 < %.0e, V5 < %.0e\n', TOL_V4, TOL_V5);

% ---- STEP 5: the estimands, ONLY if 3 and 4 pass ------------------------
tee('\nSTEP 5  ESTIMANDS\n');
conv_ok = SOL.C1.converged && SOL.C2.converged && SOL.C4.converged;
gate_ok = par_ok && all_budget_ok && conv_ok && RC2.hit;
if ~gate_ok
    tee('  WITHHELD. A gate failed, and a decomposition of a path that does not\n');
    tee('  satisfy the government budget identity at every date is not a\n');
    tee('  decomposition of anything. Gates: parity=%d budget=%d converged=%d\n', ...
        par_ok, all_budget_ok, conv_ok);
    tee('  consolidation-hit=%d\n', RC2.hit);
    EST = struct('reportable', false);
else
    d1 = @(TR) log(TR.phat(1)/TR.P0);
    EST = struct('reportable', true, ...
        'timing_matched_debt', d1(SOL.C2) - d1(SOL.C1), ...
        'failure_to_consolidate', d1(SOL.C4) - d1(SOL.C2), ...
        'legacy_joint', d1(SOL.C4) - d1(SOL.C1), ...
        'dlnP1', struct('C1', d1(SOL.C1), 'C2', d1(SOL.C2), 'C4', d1(SOL.C4)));
    tee('  impact response dlnP1:  C1 %+0.6f   C2 %+0.6f   C4 %+0.6f\n', ...
        EST.dlnP1.C1, EST.dlnP1.C2, EST.dlnP1.C4);
    tee('  tax timing at MATCHED terminal debt   (C2-C1) = %+0.6f\n', EST.timing_matched_debt);
    tee('  failure to consolidate, same delay    (C4-C2) = %+0.6f\n', EST.failure_to_consolidate);
    tee('  total legacy joint effect             (C4-C1) = %+0.6f\n', EST.legacy_joint);
    tee('\n  READING. C4-C1 is what the manuscript''s phase-in experiment measures.\n');
    tee('  It is the SUM of a tax-timing effect and a terminal-debt ratchet, and\n');
    tee('  the split above is the whole point of this driver. A tax-timing claim\n');
    tee('  is licensed by C2-C1 alone. If C2-C1 is small relative to C4-C2, the\n');
    tee('  manuscript''s reversal is a debt-ratchet result wearing timing clothes.\n');
    shr = abs(EST.timing_matched_debt) / max(abs(EST.legacy_joint), eps);
    tee('  |C2-C1| / |C4-C1| = %.4f  (share of the joint effect due to timing)\n', shr);
    tee('\n  NO INTERACTION TERM IS REPORTED. With three feasible paths and two\n');
    tee('  margins, a fully independent factorial interaction is NOT identified;\n');
    tee('  the withdrawn C3 was the cell that would have identified it, and it is\n');
    tee('  infeasible under the contemporaneous service rule. Do not report one.\n');
end

save(fullfile(projdir,'output','deficit_decomposition.mat'), ...
     'SPEC','KB','T','TC','HC','RHOBAR','EPS_KAPPA','TOL_V4','TOL_V5','sopts', ...
     'SOL','RC2','BID','EST','par_gap','calinfo');

tee('\n[main_deficit_decomposition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
% Local, because this driver had no local-function block before the solve
% steps were wired in and ternstr is not a shared function in src_project.
% Verified by search rather than assumed: an undefined name here would have
% errored at the first gate print, after both transitions had already been
% solved -- the most expensive possible place to discover a typo.
    if c, s = a; else, s = b; end
end
