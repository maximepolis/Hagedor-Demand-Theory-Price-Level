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
%   timing                  = C2 - C1
%   ratchet                 = C3 - C1
%   interaction             = C4 - C2 - C3 + C1
%   timing | ratchet        = C4 - C3
%
% ORDERING. C4 runs before C3 because kbar is READ from C4's endogenous
% kappa_inf and then imposed on C3. Choosing kbar independently would leave
% C3 - C1 measuring a different ratchet from the one C4 contains, and the 2x2
% would not be balanced.
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
% Case definitions. Each returns a tax-share path phi_t and a terminal
% dilution target; the solver reads them and nothing else differs.
% =====================================================================
T = 80; if FAST, T = 60; end
tvec = (1:T)';

CASES = struct('tag',{},'name',{},'phi',{},'kappa_target',{},'issue1',{});

CASES(1) = struct('tag','C1','name','contemporaneous, kappa=1', ...
                  'phi', ones(T,1), 'kappa_target', 1, 'issue1', 0);

CASES(2) = struct('tag','C2','name','delayed + consolidation, kappa=1', ...
                  'phi', [], 'kappa_target', 1, 'issue1', 0);   % phi solved below

CASES(3) = struct('tag','C3','name','contemporaneous + ratchet', ...
                  'phi', ones(T,1), 'kappa_target', NaN, 'issue1', NaN); % kbar from C4

CASES(4) = struct('tag','C4','name','delayed, no consolidation (current experiment)', ...
                  'phi', 1 - RHOBAR.^tvec, 'kappa_target', NaN, 'issue1', 0);

% =====================================================================
% NOT YET IMPLEMENTED BELOW THIS LINE.
%
% The path solver this driver must call is the one-asset deficit transition
% already in the project. Wiring it is decision D11: the existing driver
% embeds its own financing rule, and this experiment needs the rule passed IN
% as phi_t plus a terminal-dilution target, so the four cases differ in
% exactly one object and nothing else.
%
% Writing a second path solver here instead would reintroduce the defect this
% whole round is about -- two implementations of the same object that can
% silently diverge -- so it is not done unilaterally.
%
% What the wired version must do, in order:
%   1. solve C1; verify V1, V4, V5
%   2. solve C4 at rho_bar; READ kappa_inf^{C4}; set kbar := kappa_inf^{C4}
%   3. solve C3 with the one-off issuance sized to deliver kbar
%   4. solve C2: bisect s_0 on the consolidation surcharge
%          s_t = s_0 * (2^(-1/H_c))^(t - T_c),  t >= T_c
%      until |kappa_inf^{C2} - 1| < EPS_KAPPA
%   5. gates V1-V7 across all four
%   6. estimands, only if the gates pass
%   7. the within-case decomposition of the impact response
% =====================================================================

tee('*** NOT YET WIRED. See decision D11 in R10_EXECUTION_PLAN.md.\n');
tee('*** The case definitions, the consolidation rule, the ordering and the\n');
tee('*** budget gates are fixed above and in DEFICIT_2X2_SPEC_R10.md. What is\n');
tee('*** missing is the call into the existing one-asset deficit path solver,\n');
tee('*** which must accept phi_t and a terminal-dilution target as arguments\n');
tee('*** rather than embedding its own financing rule.\n\n');

tee('Case definitions as fixed:\n');
for i = 1:numel(CASES)
    c = CASES(i);
    if isempty(c.phi), ph = '(solved: phase-in + consolidation)';
    else, ph = sprintf('phi_1=%.4f phi_%d=%.4f', c.phi(1), T, c.phi(end));
    end
    if isnan(c.kappa_target), kt = 'kbar (read from C4)';
    else, kt = sprintf('%.6f', c.kappa_target);
    end
    tee('  %-3s %-44s %-42s kappa_inf -> %s\n', c.tag, c.name, ph, kt);
end

save(fullfile(projdir,'output','deficit_2x2.mat'), ...
     'CASES','T','TC','HC','RHOBAR','EPS_KAPPA','TOL_V4','TOL_V5');
tee('\n[main_deficit_2x2] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
