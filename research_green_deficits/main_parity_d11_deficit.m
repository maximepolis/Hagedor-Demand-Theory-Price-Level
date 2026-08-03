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

% pgc AND the opts COME FROM THE BASELINE .mat, not from a second call to
% setup_params_green here. The legacy setup involves a calibrated beta
% (calibrate_beta), a rebuilt FAST asset grid, climate_version, D0 and Gg_nom;
% reconstructing all of that on this side would be a second implementation of
% the experiment, and any drift between the two would show up as a "parity
% failure" that is really a setup difference. Reusing the captured struct makes
% the INPUTS identical by construction, so the only thing that differs between
% legs is the CODE -- which is the entire point.
%
% pgc contains no function handles (checked), so it carries no reference back
% into the baseline tree.
assert(isfield(BASE,'pgc'), ...
    ['this baseline .mat predates R11.6 and has no pgc. Re-run ' ...
     'main_baseline_capture; the earlier transition leg used an ' ...
     'uncalibrated beta and was not the legacy experiment.']);
pgc = BASE.pgc;
o   = BASE.opts_deficit;   o.verbose = false;
ob  = BASE.opts_baseline;  ob.verbose = false;
if isfield(BASE,'calinfo')
    tee('  legacy setup from the baseline: na=%d, T=%d, beta*=%.6f, Gg=%.6f\n', ...
        BASE.calinfo.na, BASE.calinfo.T, BASE.calinfo.beta_star, BASE.calinfo.Gg_cal);
end
t2 = tic;
TR2d = solve_hank_dtpl_transition(pgc, o);
check_TR(TR2d, 'current legacy-branch deficit');
TR2b = solve_hank_dtpl_transition(pgc, ob);
check_TR(TR2b, 'current legacy-branch baseline');
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
check_TR(TR3d, 'current explicit-fiscal deficit');
tee('  done (%.1f s)\n', toc(t3));

% =====================================================================
% Flatten and compare.
% =====================================================================
L2 = derived(merge(flat(TR2d,'d'), flat(TR2b,'b')));
L3 = derived(merge(flat(TR3d,'d'), flat(TR2b,'b')));   % same balanced leg
L1 = derived(pickbase(BASE));

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
% .resid is a residual HISTORY, not a scalar. Passing it straight to a %.3e
% made fprintf recycle the whole format string once per element and print
% forty lines of "FINAL RESIDUAL", burying the counts it sits next to. Reduce
% to sup-norms first.
tee('\nITERATION COUNTS  baseline %s / legacy %s / explicit %s\n', ...
    numstr(getfd(BASE,'d_iters')), numstr(geti(TR2d,'iters')), numstr(geti(TR3d,'iters')));
tee('BEST ITER         baseline %s / legacy %s / explicit %s\n', ...
    numstr(getfd(BASE,'d_best_iter')), numstr(geti(TR2d,'best_iter')), numstr(geti(TR3d,'best_iter')));
tee('RESIDUAL sup-norm baseline %s / legacy %s / explicit %s\n', ...
    supstr(getfd(BASE,'d_resid')), supstr(geti(TR2d,'resid')), supstr(geti(TR3d,'resid')));

% ---------------------------------------------------------------- convergence
% PARITY AND CONVERGENCE ARE DIFFERENT QUESTIONS AND MUST NOT BE CONFLATED.
% Reproducing a NON-converged path bit-for-bit is a perfectly valid parity
% result -- arguably a sharper one, since it reproduces the entire iteration
% history rather than a converged fixed point both legs would reach from
% anywhere. But it licenses NOTHING economic. This block makes that explicit
% so that a green parity verdict is never mistaken for a usable number.
conv = struct('d', tern2(isfield(TR2d,'converged'), getfl(TR2d,'converged'), NaN), ...
              'b', tern2(isfield(TR2b,'converged'), getfl(TR2b,'converged'), NaN));
allconv = isequal(conv.d, true) && isequal(conv.b, true);
tee('\nCONVERGENCE (a separate question from parity)\n');
tee('  deficit path converged  : %s\n', yn(conv.d));
tee('  balanced path converged : %s\n', yn(conv.b));
if isfield(TR2d,'msg'), tee('  deficit  : %s\n', TR2d.msg); end
if isfield(TR2b,'msg'), tee('  balanced : %s\n', TR2b.msg); end
if ~allconv
    tee(['\n  *** NOT CONVERGED. Parity may still be ESTABLISHED below and that\n' ...
         '  *** conclusion is valid -- the legs reproduce each other exactly. But\n' ...
         '  *** NO ECONOMIC NUMBER from this run may be quoted: not kappa, not\n' ...
         '  *** dlnP0, not the front-loading statistics. Re-run at the benchmark\n' ...
         '  *** setting (T=80, maxit=120) before reading anything off it.\n']);
end

% ---------------------------------------------------------------- theory gate
% Nominal neutrality: the terminal price must scale one-for-one with the
% terminal nominal stock. This is a check on the MODEL, identical across legs,
% and it is the sharpest test that the debt recursion and the terminal pin are
% mutually consistent.
if isfield(L2,'neutrality_gap')
    tee('\nNOMINAL NEUTRALITY  P_inf^d / P_inf^b  vs  kappa_inf\n');
    tee('  relative gap %+.3e   %s\n', L2.neutrality_gap, ...
        tern(abs(L2.neutrality_gap) < 1e-3, 'consistent', '*** INCONSISTENT ***'));
end

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
function check_TR(TR, name)
% A transition that produced no path is a DIAGNOSIS, not a missing field.
    if isstruct(TR) && isfield(TR, 'phat') && ~isempty(TR.phat), return; end
    m = '(the solver returned no message)';
    if isstruct(TR) && isfield(TR, 'msg') && ~isempty(TR.msg), m = TR.msg; end
    error('main_parity_d11_deficit:failed', ...
        'the %s transition produced no price path.\n  solver message: %s', name, m);
end

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

function D = derived(D)
% The reported statistics, computed HERE from the flattened paths -- one
% implementation for all three legs, so a change in how any solver reports a
% statistic cannot make the parity test pass. (There were two implementations
% before, one reading TR structs and one reading flat fields; they had to be
% kept in step by hand, and a field added to one would have shown up as
% MISSING against the other.)
    if ~isfield(D,'d_phat') || ~isfield(D,'b_phat'), return; end
    d = D.d_phat(:)'; b = D.b_phat(:)';
    P0 = NaN; if isfield(D,'d_P0'), P0 = D.d_P0; end

    % OWN-PATH front-loading, F^j = (P_1^j - P_0)/(P_inf^j - P_0). One per
    % path, each with its OWN denominator. This is the statistic the claim
    % register defines.
    D.front_loading_d = (d(1) - P0) / (d(end) - P0);
    D.front_loading_b = (b(1) - P0) / (b(end) - P0);

    % CROSS-INSTRUMENT ratio. Deliberately NOT called "front-loading": its
    % denominator is a difference between two DIFFERENT paths' terminals, so a
    % value above 1 is OVERSHOOTING of the long-run financing gap, not a
    % fraction of a path's own long-run move. Conflating the two is the error
    % the register corrected, and naming this field front_loading would have
    % walked it straight back in.
    D.overshoot_cross = (d(1) - b(1)) / (d(end) - b(end));

    D.revaluation = d(1)/b(1) - 1;

    % dlnP0 and kappa_legacy are the two statistics the capture writes into
    % the baseline .mat as top-level fields, so they MUST be computed here too
    % or the baseline carries them and the current legs do not. Consolidating
    % the derived statistics into this one function in R11.7 dropped them, and
    % they then read as "MISSING in legacy" -- two FAILs on a run in which
    % every economic field was bit-identical. Same class as the pgc/calinfo
    % rows the same revision fixed: the harness inventing a difference.
    %
    % dlnP0 is log(1 + revaluation) by construction; both are kept because the
    % manuscript quotes the log form and the capture reports the ratio.
    D.dlnP0 = log(d(1)/b(1));
    if isfield(D,'d_kappa_path') && isfield(D,'b_kappa_path')
        D.kappa_legacy = D.d_kappa_path(end) / D.b_kappa_path(end);
    end
    if isfield(D,'d_kappa_path'), D.terminal_dilution = D.d_kappa_path(end); end

    % NOMINAL-NEUTRALITY GATE. A permanent proportional rescaling of the
    % nominal stock must move the terminal price one-for-one, so
    %     P_inf^deficit / P_inf^balanced  ==  kappa_inf.
    % This is a THEORY check on the solved path, not a parity check: it holds
    % or fails identically in all three legs. It is the sharpest available
    % test that the debt recursion and the terminal pin are mutually
    % consistent, and it is exactly what the withdrawn terminal-price override
    % would have made vacuous by construction.
    if isfield(D,'d_kappa_inf') && isfinite(D.d_kappa_inf) && D.d_kappa_inf ~= 0
        D.neutrality_gap = (d(end)/b(end)) / D.d_kappa_inf - 1;
    end
end

function Q = pickbase(B)
    Q = struct(); f = fieldnames(B);
    % pgc and calinfo are INPUTS recorded for provenance, not outputs. Leaving
    % them in made the comparison report them as "MISSING in legacy" and count
    % two FAILs, so a run in which all 47 economic fields were bit-identical
    % was reported as NOT ESTABLISHED. The harness was manufacturing a failure
    % out of its own metadata.
    skip = {'env','opts_deficit','opts_baseline','TR_deficit_full', ...
            'TR_baseline_full','T','rho_bar','pgc','calinfo'};
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

function s = yn(v)
    if isequal(v, true), s = 'YES'; elseif isequal(v, false), s = 'NO';
    else, s = '(not reported)'; end
end

function y = tern2(c, a, b)
    if c, y = a; else, y = b; end
end

function y = getfl(S, f)
    y = NaN; if isstruct(S) && isfield(S, f), y = S.(f); end
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end

function s = supstr(v)
% Sup-norm of a possibly-vector residual, as ONE number.
    if isempty(v) || ~isnumeric(v), s = '(none)'; return; end
    v = v(isfinite(v));
    if isempty(v), s = '(nonfinite)'; return; end
    s = sprintf('%.3e', max(abs(v)));
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
