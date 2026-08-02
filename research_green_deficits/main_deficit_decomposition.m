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
tee('*** SPECIFICATIONS BUILT AND FROZEN. Solving is not yet authorized:\n');
tee('*** main_parity_d11_deficit must run against the bf0a4e8 baseline and pass.\n\n');

save(fullfile(projdir,'output','deficit_decomposition.mat'), ...
     'SPEC','KB','T','TC','HC','RHOBAR','EPS_KAPPA','TOL_V4','TOL_V5','sopts');
tee('\n[main_deficit_decomposition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
