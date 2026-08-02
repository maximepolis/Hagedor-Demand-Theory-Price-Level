% MAIN_DEFICIT_2X2  Separate tax timing from the terminal-debt ratchet.
%
% STATUS: scaffolded and static-checked. NOT YET RUN. The manuscript's
% phase-in result is currently an ILLUSTRATIVE JOINT result precisely because
% this experiment does not exist; nothing here may be cited until it has run
% and passed the budget identities.
%
% THE PROBLEM. Under the rule tau_t = rbar*b_t + (1 - rho_d^t)*g, delaying the
% tax does two things at once: it relieves the constrained early (timing), and
% it leaves revenue permanently unrecovered so the detrended nominal stock ends
% higher (ratchet). The reported critical phase-in speed therefore cannot be
% read as a tax-timing threshold. This driver runs the 2x2 that separates them.
%
% THE FOUR CASES (see DEFICIT_2X2_SPEC_R10.md for the formal statement)
%   C1  contemporaneous tax, kappa_inf = 1                 reference
%   C2  delayed tax + consolidation surcharge, kappa_inf = 1   PURE TIMING
%   C3  contemporaneous tax + one-off issuance, kappa_inf = kbar  PURE RATCHET
%   C4  delayed tax, no consolidation, kappa_inf = kbar    the current experiment
%
% ESTIMANDS
%   timing at baseline debt       = C2 - C1
%   ratchet under contemporaneous = C3 - C1
%   timing conditional on ratchet = C4 - C3
%   ratchet conditional on delay  = C4 - C2
%   interaction                   = C4 - C3 - C2 + C1
%
% KAPPA IS FROZEN BEFORE THE FACTORIAL RUNS. kappa_bar is measured ONCE, in a
% preliminary step that is NOT one of the four cases (kv_kappa_legacy), from
% the legacy rho = 0.90 run, and then imposed identically on C3 and C4. A
% factorial design requires the ratchet treatment to be assigned independently
% of the timing treatment: if C4 defined kappa_bar from its own realized
% terminal stock, the ratchet would be endogenous to timing and would move
% across grids and initial conditions, so C4 - C3 and the interaction would
% not be contrasts of a common treatment. A case that cannot reach the frozen
% target is marked INFEASIBLE and does NOT adopt its realized stock as the
% target.
%
% CONSOLIDATION PARAMETERS ARE FIXED IN THE SPEC, NOT HERE, and T_c (start
% date) and H_c (half-life) are separate symbols with separate values even
% though the baseline sets both to 10.
%
% GATES. The government-budget identities V1-V7 of the spec are gates, not
% diagnostics: no estimand is reported unless they pass. In particular V4
% (period-by-period identity) and V5 (present value) catch a rule change that
% silently alters the real program, which is the failure mode that would make
% the whole 2x2 meaningless.
%
% USAGE   >> clear; main_deficit_2x2                  (one-asset, benchmark)
%         >> clear; FAST = true; main_deficit_2x2
%         >> clear; TC = 5; HC = 5; main_deficit_2x2  (robustness, AFTER gates)
%
% OUTPUT  output/tables/deficit_2x2.txt
%         output/deficit_2x2.mat
%
% ONE-ASSET ONLY at present. The two-asset version is blocked by the
% certification gate and would write to output/quarantine/.

clearvars -except FAST TC HC RHOBAR; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('TC','var')     || isempty(TC),     TC = 10;    end  % consolidation START
if ~exist('HC','var')     || isempty(HC),     HC = 10;    end  % consolidation HALF-LIFE
if ~exist('RHOBAR','var') || isempty(RHOBAR), RHOBAR = 0.90; end
EPS_KAPPA = 1e-8;      % terminal-debt tolerance, fixed in the spec
TOL_V4    = 1e-9;      % period identity, normalized by g
TOL_V5    = 1e-7;      % present-value identity, normalized by b0

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'deficit_2x2.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});

tee('TAX TIMING x TERMINAL DEBT: THE 2x2\n\n');
tee('consolidation start T_c = %d yr; consolidation half-life H_c = %d yr\n', TC, HC);
tee('(these are DIFFERENT parameters; the baseline happens to set both to 10)\n');
tee('phase-in speed rho_bar = %.3f (tax half-life %.2f yr)\n', ...
    RHOBAR, log(2)/(-log(RHOBAR)));
tee('terminal-debt tolerance eps_kappa = %.0e\n\n', EPS_KAPPA);
tee('These parameters were fixed in DEFICIT_2X2_SPEC_R10.md before this run.\n\n');

% =====================================================================
% STEP 0 (NOT a factorial case): freeze the ratchet size.
%
% kappa_bar is measured ONCE from the legacy rho = 0.90 run and then imposed
% identically on C3 and C4. In a 2x2 factorial the ratchet treatment must be
% assigned independently of the timing treatment; if C4 defined kappa_bar from
% its own realized terminal stock, the ratchet would be endogenous to timing
% and would move across grids and initial conditions, so C4 - C3 and the
% interaction would not be contrasts of a common treatment.
%
% A case that cannot reach the frozen target is marked INFEASIBLE. It does not
% adopt its realized terminal stock as the target.
% =====================================================================
T = 80; if FAST, T = 60; end
pgc = setup_params_green();

tee('STEP 0  freezing the ratchet size from the legacy run\n');
KB = kv_kappa_legacy(pgc, T, RHOBAR, false);
tee('  kappa_bar = B_inf^legacy / B_inf^baseline = %.10f / %.10f = %.10f\n', ...
    KB.B_inf_legacy, KB.B_inf_baseline, KB.kappa_bar);
tee('  FROZEN before C1-C4 are solved; no case may redefine it.\n\n');
kappa_bar = KB.kappa_bar;

% =====================================================================
% The four fiscal specifications, built OUTSIDE the solver.
% =====================================================================
sopts = struct('T', T, 'rho_bar', RHOBAR, 'kappa_bar', kappa_bar, ...
               'consolidation_start', TC, 'consolidation_half_life', HC, ...
               'kappa_tol', EPS_KAPPA);
SPEC = struct();
for c = {'C1','C2','C3','C4'}
    SPEC.(c{1}) = kv_fiscal_spec(c{1}, sopts);
end

tee('CASE SPECIFICATIONS (all built by kv_fiscal_spec; solver sees only these)\n');
for c = {'C1','C2','C3','C4'}
    f = SPEC.(c{1});
    tee('  %-3s timing=%-16s debt=%-10s kappa_mode=%-6s kappa_target=%.10f\n', ...
        f.caseid, f.timing, f.debt_target, f.kappa_mode, f.kappa_target);
end
tee('\n  kappa^C1 = kappa^C2 = 1;  kappa^C3 = kappa^C4 = kappa_bar = %.10f\n\n', kappa_bar);

% =====================================================================
% NOT YET AUTHORIZED TO RUN. The remaining steps, in order:
%
%   1. solve C1, C3, C4 with their frozen targets
%   2. solve C2 by bisecting s_0 on the consolidation surcharge until
%      |kappa_inf^{C2} - 1| < EPS_KAPPA
%   3. verify TR.kappa_hit for every case; an unmet target is INFEASIBLE
%   4. budget identities V1-V7 (DEFICIT_2X2_SPEC_R10.md)
%   5. estimands, only if 3 and 4 pass:
%        timing at baseline debt     = C2 - C1
%        ratchet under contemporaneous = C3 - C1
%        timing conditional on ratchet = C4 - C3
%        ratchet conditional on delay  = C4 - C2
%        interaction                   = C4 - C3 - C2 + C1
%   6. the within-case decomposition of the impact response
%
% Steps 1-2 require the D11 parity test to have PASSED. That test has not
% been run in this environment and no parity is claimed.
% =====================================================================
tee('*** SPECIFICATIONS BUILT AND FROZEN. Solving is not yet authorized:\n');
tee('*** main_parity_d11_deficit must run and pass first.\n\n');

save(fullfile(projdir,'output','deficit_2x2.mat'), ...
     'SPEC','KB','kappa_bar','T','TC','HC','RHOBAR','EPS_KAPPA','TOL_V4','TOL_V5');
tee('\n[main_deficit_2x2] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
