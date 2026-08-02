% MAIN_PARITY_D11_DEFICIT  THREE-WAY transition parity.
%
% ================= WHAT WAS WRONG WITH THE TWO-WAY TEST =================
% The previous version solved the rho_d = 0.90 path twice inside the
% ALREADY-REFACTORED solver: once through the legacy branch and once with an
% explicit opts.fiscal. That establishes that the two branches of the current
% solver agree with each other. It says nothing about whether either agrees
% with the solver at the previous commit -- which is the question, since the
% refactor changed the file (420 lines at bf0a4e8, 473 now) and the paper
% treats these paths as independently cross-validated quantitative outputs.
%
% ================= THE THREE LEGS =================
%   1. BASELINE  solve_hank_dtpl_transition at bf0a4e8, executed by
%                main_baseline_capture from the content-verified snapshot in
%                <root>/baseline_bf0a4e8 (no git required). The only leg that
%                does not run the refactored file.
%   2. LEGACY    the current solver with opts.fiscal ABSENT.
%   3. EXPLICIT  the current solver with the legacy rho_d = 0.90 path passed
%                explicitly through kv_fiscal_spec (kappa_mode = 'free').
%
% 1 vs 2 tests the refactor. 2 vs 3 tests that the explicit interface is a
% faithful generalization of the internal rule.
%
% ================= WHAT IS COMPARED =================
% THE COMPLETE PATHS, not selected headline scalars:
%   taxes, nominal and real debt, the stationarized price level, realized real
%   returns, market-clearing residuals, the surcharge path, terminal debt
%   dilution kappa_inf, the impact price response, the front-loading and
%   revaluation measures, and the convergence and horizon diagnostics.
% Household distributions are compared where the solver stores them.
%
% Absolute AND relative differences are reported for each. Machine-precision
% agreement is the expectation for code moved verbatim; a discrepancy is
% reported with a diagnosis rather than failing blind, because an iterative
% stopping rule that fires one step earlier changes the last bits without
% changing anything economic -- and that shows up in the ITERATION COUNTS,
% which are compared alongside the values.
%
% ================= A CHANGE THIS TEST MUST NOT HIDE =================
% Round 11 removed the terminal-price override that kappa_mode = 'target'
% used to apply (phat(T) = kappa_target * eq1.P). Under kappa_mode = 'free'
% -- which is what all three legs here use -- that code never executed, so
% legs 2 and 3 should still match the baseline exactly. If they do not, the
% removal touched the free branch and that is a real defect.
%
% USAGE   >> clear; main_baseline_capture      (no git needed; see that file)
%         >> clear; restoredefaultpath; run_project_path_setup
%         >> clear; main_parity_d11_deficit
%
% OUTPUT  output/tables/parity_d11_deficit.txt
%         output/parity_d11_deficit.mat
%
% NO PARITY IS CLAIMED UNTIL THIS HAS RUN AND PASSED.

clearvars -except FAST RHOBAR; close all; clc;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));
if ~exist('FAST','var'), FAST = false; end
if ~exist('RHOBAR','var') || isempty(RHOBAR), RHOBAR = 0.90; end

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'parity_d11_deficit.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('D11 THREE-WAY TRANSITION PARITY\n%s\n\n', repmat('=',1,60));
tee('%s\n\n', kv_code_version(mfilename('fullpath')));

tag = 'bench'; if FAST, tag = 'fast'; end
bf = fullfile(projdir,'output','baseline', sprintf('baseline_d11_%s.mat', tag));

pv = fullfile(projdir,'output','function_provenance_r10.mat');
if exist(pv,'file') ~= 2
    tee('*** run main_function_provenance_r10 first.\n'); fclose(fid);
    error('main_parity_d11_deficit:provenance','provenance audit has not run');
end

if exist(bf,'file') ~= 2
    tee('\n*** NO PRE-REFACTOR BASELINE at\n***   %s\n', bf);
    tee(['***\n*** The two-way comparison this file used to run compared two branches\n' ...
         '*** of the ALREADY-REFACTORED solver, so it could not test the refactor.\n' ...
         '*** Build the baseline first -- NO GIT REQUIRED:\n' ...
         '***   >> clear; main_baseline_capture\n']);
    fclose(fid);
    error('main_parity_d11_deficit:nobaseline','no frozen baseline at %s', bf);
end
BASE = load(bf);
tee('baseline   %s\n', bf);
tee('  commit   %s\n', BASE.env.commit);
tee('  MATLAB   %s on %s\n', BASE.env.matlab, BASE.env.platform);
tee('  FAST     %d (this run: %d)\n', BASE.env.fast, FAST);
assert(BASE.env.fast == FAST, 'baseline FAST=%d but this run FAST=%d', BASE.env.fast, FAST);
assert(abs(BASE.rho_bar - RHOBAR) < 1e-15, ...
    'baseline rho_bar=%.6f but this run %.6f', BASE.rho_bar, RHOBAR);

T = BASE.T;
tee('  T        %d, rho_bar %.4f\n\n', T, RHOBAR);

TOL = struct('default', 1e-12, ...
             'd_phat', 1e-11, 'd_tau_path', 1e-11, 'd_b_path', 1e-11, ...
             'd_r_path', 1e-11, 'd_kappa_path', 1e-11, 'd_S_path', 1e-11, ...
             'b_phat', 1e-11, 'b_tau_path', 1e-11, 'b_b_path', 1e-11, ...
             'dlnP0', 1e-11, 'kappa_legacy', 1e-11);

% =====================================================================
% LEG 2: current solver, opts.fiscal ABSENT (the legacy branch).
% =====================================================================
tee('LEG 2: current solver, legacy branch (no opts.fiscal) ...\n');
pgc = setup_params_green();
o  = struct('T', T, 'regime', 'indexed', 'financing', 'deficit', ...
            'rho_d', RHOBAR, 'verbose', false);
ob = o; ob.financing = 'lumpsum'; ob.rho_d = 0;
t2 = tic;
TR2d = solve_hank_dtpl_transition(pgc, o);
TR2b = solve_hank_dtpl_transition(pgc, ob);
tee('  done (%.1f s)\n', toc(t2));

% =====================================================================
% LEG 3: current solver, legacy path supplied EXPLICITLY.
% phi_t = 1 - rho^t is exactly what C4 is, and kappa is left FREE, so this
% must reproduce the legacy branch line for line.
% =====================================================================
tee('\nLEG 3: current solver, legacy path passed explicitly ...\n');
sopts = struct('T', T, 'rho_bar', RHOBAR, 'consolidation_start', 10, ...
               'consolidation_half_life', 10, 'kappa_tol', 1e-8);
fsC4 = kv_fiscal_spec('C4', sopts);
assert(all(abs(fsC4.consolidation_path) < 1e-15), ...
    'C4 must carry no surcharge; the legacy rule has none');
o3 = o; o3.fiscal = fsC4;
t3 = tic;
TR3d = solve_hank_dtpl_transition(pgc, o3);
tee('  done (%.1f s)\n', toc(t3));

% =====================================================================
% Flatten and compare.
% =====================================================================
L2 = flat(TR2d, 'd'); L2 = merge(L2, flat(TR2b, 'b'));
L2.dlnP0 = log(TR2d.phat(1)/TR2b.phat(1));
L2.kappa_legacy = TR2d.kappa_path(end)/TR2b.kappa_path(end);
L2 = derived(L2, TR2d, TR2b);

L3 = flat(TR3d, 'd'); L3 = merge(L3, flat(TR2b, 'b'));   % same baseline leg
L3.dlnP0 = log(TR3d.phat(1)/TR2b.phat(1));
L3.kappa_legacy = TR3d.kappa_path(end)/TR2b.kappa_path(end);
L3 = derived(L3, TR3d, TR2b);

L1 = pickbase(BASE);
L1 = derived_from_fields(L1);

tee('\n%s\nCOMPARISON A -- BASELINE (bf0a4e8) vs CURRENT LEGACY BRANCH\n', repmat('=',1,60));
tee('this is the leg that tests the refactor\n%s\n', repmat('=',1,60));
CA = kv_parity_compare(L1, common(L2, L1), 'baseline', 'legacy', TOL, tee);

tee('\n%s\nCOMPARISON B -- CURRENT LEGACY vs CURRENT EXPLICIT FISCAL\n', repmat('=',1,60));
tee('is the explicit interface a faithful generalization of the internal rule\n%s\n', repmat('=',1,60));
CB = kv_parity_compare(L2, L3, 'legacy', 'explicit', TOL, tee);

tee('\n%s\nCOMPARISON C -- BASELINE vs CURRENT EXPLICIT FISCAL (end to end)\n%s\n', ...
    repmat('=',1,60), repmat('=',1,60));
CC = kv_parity_compare(L1, common(L3, L1), 'baseline', 'explicit', TOL, tee);

% Iteration counts, reported next to the verdict: the one benign explanation
% for a last-bit difference is a stopping rule firing a step earlier, and
% that is only distinguishable if the counts are on the page.
tee('\nITERATION COUNTS  baseline %s / legacy %d / explicit %d\n', ...
    numstr(getfd(BASE,'d_iters')), geti(TR2d,'iters'), geti(TR3d,'iters'));
tee('BEST ITER         baseline %s / legacy %d / explicit %d\n', ...
    numstr(getfd(BASE,'d_best_iter')), geti(TR2d,'best_iter'), geti(TR3d,'best_iter'));
tee('FINAL RESIDUAL    baseline %s / legacy %.3e / explicit %.3e\n', ...
    numstr(getfd(BASE,'d_resid')), geti(TR2d,'resid'), geti(TR3d,'resid'));

PASS = CA.pass && CB.pass && CC.pass;
tee('\n%s\nVERDICT\n%s\n', repmat('=',1,60), repmat('=',1,60));
tee('  A baseline vs legacy    : %s\n', ternstr(CA.pass,'PASS','FAIL'));
tee('  B legacy vs explicit    : %s\n', ternstr(CB.pass,'PASS','FAIL'));
tee('  C baseline vs explicit  : %s\n', ternstr(CC.pass,'PASS','FAIL'));
tee('\n  D11 PARITY: %s\n', ternstr(PASS,'ESTABLISHED','NOT ESTABLISHED'));
if ~PASS
    tee(['\n  Do not run main_deficit_decomposition. A failure in A is a REFACTOR\n' ...
         '  defect in the transition solver; a failure in B alone means the\n' ...
         '  explicit fiscal interface is not a faithful generalization of the\n' ...
         '  internal rho_d rule.\n']);
end

save(fullfile(projdir,'output','parity_d11_deficit.mat'), ...
     'CA','CB','CC','PASS','TOL','L1','L2','L3','TR2d','TR2b','TR3d','tag');
tee('\n[main_parity_d11_deficit] wrote %s\n', sf);
fclose(fid);

% =====================================================================
function D = flat(TR, sfx)
    D = struct();
    names = {'phat','P0','pi_path','r_path','tau_path','D_path','Kg_path', ...
             'S_path','b_path','g_path','vart_path','phi_path','kappa_path', ...
             'xi_path','primary_gap','kappa_inf','rho_d','resid','iters', ...
             'best_iter','kappa_mode','kappa_target','kappa_gap','kappa_hit', ...
             'financing','converged','horizon','T'};
    for i = 1:numel(names)
        if isfield(TR, names{i}), D.([sfx '_' names{i}]) = TR.(names{i}); end
    end
end

function D = derived(D, TRd, TRb)
% The reported statistics, recomputed here from the paths rather than read
% from either solver, so a change in how a solver reports them cannot make a
% parity test pass.
    D.front_loading = (TRd.phat(1) - TRb.phat(1)) / (TRd.phat(end) - TRb.phat(1));
    D.revaluation   = TRd.phat(1)/TRb.phat(1) - 1;
    D.terminal_dilution = TRd.kappa_path(end);
end

function D = derived_from_fields(D)
    if isfield(D,'d_phat') && isfield(D,'b_phat')
        D.front_loading = (D.d_phat(1) - D.b_phat(1)) / (D.d_phat(end) - D.b_phat(1));
        D.revaluation   = D.d_phat(1)/D.b_phat(1) - 1;
    end
    if isfield(D,'d_kappa_path'), D.terminal_dilution = D.d_kappa_path(end); end
end

function Q = pickbase(B)
    Q = struct(); f = fieldnames(B);
    skip = {'env','opts_deficit','opts_baseline','TR_deficit_full', ...
            'TR_baseline_full','T','rho_bar'};
    for i = 1:numel(f)
        if any(strcmp(f{i}, skip)), continue; end
        Q.(f{i}) = B.(f{i});
    end
end

function Q = common(D, REF)
% Compare only what the BASELINE actually captured. Fields the refactor added
% (xi_path) have no counterpart at bf0a4e8; comparing them would report a
% spurious MISSING against a commit that predates them.
    Q = struct(); f = fieldnames(D);
    for i = 1:numel(f)
        if isfield(REF, f{i}), Q.(f{i}) = D.(f{i}); end
    end
end

function D = merge(D, E)
    f = fieldnames(E);
    for i = 1:numel(f), D.(f{i}) = E.(f{i}); end
end

function v = getfd(S, f)
    v = NaN; if isfield(S, f), v = S.(f); end
end

function v = geti(TR, f)
    v = NaN; if isfield(TR, f), v = TR.(f); end
end

function s = numstr(v)
    if isempty(v) || (isnumeric(v) && all(isnan(v(:)))), s = '(not captured)';
    elseif isnumeric(v) && isscalar(v) && v == fix(v), s = sprintf('%d', v);
    elseif isnumeric(v) && isscalar(v), s = sprintf('%.3e', v);
    else, s = '(non-scalar)';
    end
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
