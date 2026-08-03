% MAIN_PARITY_D10_CALIBRATION  THREE-WAY calibration parity.
%
% ================= WHAT WAS WRONG WITH THE TWO-WAY TEST =================
% The previous version compared
%   (a) the current script's own call into calib_beta, against
%   (b) kv_calibrate_on_grid.
% After the D10 refactor BOTH of those resolve to the same extracted file
% src_project/calib_beta.m. The test therefore established that the new
% wrapper is consistent with the old call site, which was never in doubt, and
% could not detect that moving ten functions out of
% main_twoasset_ownership_kv's local-function block changed behaviour. There
% was no branch in it that did not depend on the moved code.
%
% ================= THE THREE LEGS =================
%   1. BASELINE  the script at pre-refactor commit bf0a4e8, executed by
%                main_baseline_capture from the frozen snapshot shipped in
%                <root>/baseline_bf0a4e8 (content-verified against a SHA-256
%                manifest; no git required), its outputs frozen into
%                output/baseline/baseline_d10_<tag>.mat.
%                THIS IS THE ONLY LEG THAT DOES NOT USE THE MOVED CODE.
%   2. SCRIPT    the current backward-compatible entry point
%                (main_twoasset_ownership_kv, which now calls the extracted
%                functions).
%   3. CALLABLE  kv_calibrate_on_grid.
%
% 1 vs 2 is the test that matters: it asks whether the refactor preserved
% behaviour. 2 vs 3 is the wrapper test the old version performed, retained
% because it localises a failure once 1 vs 2 has flagged one.
%
% EXPECTATION AND ITS INTERPRETATION. The refactor MOVED code rather than
% reimplementing it, so bitwise agreement is the expectation and any
% difference is informative. But a difference is REPORTED WITH A DIAGNOSIS
% rather than failing blind: kv_parity_compare separates EXACT / within-ULP /
% within-tolerance / FAIL, and the iteration counts are compared alongside the
% values, because the one benign cause of a last-bit difference is an
% iterative stopping rule firing a step earlier -- and that shows up in the
% counts.
%
% PRECONDITIONS, both enforced below:
%   * main_function_provenance_r10 has run and found no adverse shadowing;
%   * output/baseline/baseline_d10_<tag>.mat exists, and its FAST tag matches
%     this run's. A parity test across different grids is not a parity test.
%
% USAGE   >> clear; main_baseline_capture      (no git needed; see that file)
%         >> clear; restoredefaultpath; run_project_path_setup
%         >> clear; main_parity_d10_calibration
%         >> clear; FAST = true; main_parity_d10_calibration
%
% OUTPUT  output/tables/parity_d10_calibration.txt
%         output/parity_d10_calibration.mat
%
% NO PARITY IS CLAIMED UNTIL THIS HAS RUN AND PASSED. A clean static check
% establishes nothing about economic output.

clearvars -except FAST; close all; clc;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));
if ~exist('FAST','var'), FAST = false; end

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'parity_d10_calibration.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('D10 THREE-WAY CALIBRATION PARITY\n%s\n\n', repmat('=',1,60));
tee('%s\n\n', kv_code_version(mfilename('fullpath')));

tag = 'bench'; if FAST, tag = 'fast'; end
bf = fullfile(projdir, 'output', 'baseline', sprintf('baseline_d10_%s.mat', tag));

% ---- precondition 1: provenance ------------------------------------------
pv = fullfile(projdir, 'output', 'function_provenance_r10.mat');
if exist(pv,'file') ~= 2
    tee('*** run main_function_provenance_r10 first: a parity test on a shadowed\n');
    tee('*** function proves nothing about the code you think you ran.\n');
    fclose(fid);
    error('main_parity_d10_calibration:provenance', 'provenance audit has not run');
end
PV = load(pv, 'REC');
tee('provenance audit: %d names checked, %d shadowed\n', ...
    numel(PV.REC), sum([PV.REC.shadowed]));

% ---- precondition 2: the frozen baseline ---------------------------------
if exist(bf,'file') ~= 2
    tee('\n*** NO PRE-REFACTOR BASELINE at\n***   %s\n', bf);
    tee(['***\n*** The two-way comparison this file used to run compared two branches\n' ...
         '*** that both call the extracted code, so it could not test the refactor.\n' ...
         '*** Build the baseline first -- NO GIT REQUIRED, the frozen snapshot\n' ...
         '*** ships with the project in <root>/baseline_bf0a4e8:\n' ...
         '***   >> clear; main_baseline_capture\n' ...
         '***   (add FAST = true first if this run uses FAST)\n']);
    fclose(fid);
    error('main_parity_d10_calibration:nobaseline', 'no frozen baseline at %s', bf);
end
BASE = load(bf);
tee('baseline        %s\n', bf);
tee('  commit        %s\n', BASE.env.commit);
tee('  MATLAB        %s on %s\n', BASE.env.matlab, BASE.env.platform);
tee('  FAST          %d (this run: %d)\n', BASE.env.fast, FAST);
assert(BASE.env.fast == FAST, ...
    'baseline was captured with FAST=%d but this run has FAST=%d; different grids', ...
    BASE.env.fast, FAST);
if isfield(BASE,'missing_fields') && ~isempty(BASE.missing_fields)
    tee('  NOT captured  %s\n', strjoin(BASE.missing_fields, ', '));
end
tee('\n');

% ---- precondition 3: THE CACHED INPUTS MUST MATCH ------------------------
% main_twoasset_ownership_kv reads calibrated_results.mat, wealth_fit_results
% .mat, twoasset_ownership.mat and kv_residual_scan.mat from output/, and
% changes its economy according to what it finds -- including ss.p_in, which
% sets the superstar income state and hence the ENTIRE income grid.
%
% When the baseline tree's output/ was empty and the current tree's was not,
% the two legs solved different economies: p_in 0.006 vs 0.000, chi 0.0015 vs
% 0.0022, and consequently different eGrid, beta, q, P and distribution. Every
% numeric difference reported was that, and none of it was the refactor. This
% gate makes the configuration difference impossible to mistake for a code
% difference again.
if isfield(BASE, 'input_caches')
    tee('cached inputs (must match the baseline capture):\n');
    IC = BASE.input_caches; cache_ok = true;
    for i = 1:numel(IC)
        f = fullfile(projdir, 'output', IC(i).name);
        here_present = exist(f, 'file') == 2;
        here_sha = '';
        if here_present
            fh = fopen(f,'r'); b = fread(fh, Inf, '*uint8'); fclose(fh);
            here_sha = kv_sha256(b);
        end
        same = (here_present == IC(i).present) && ...
               (~here_present || strcmp(here_sha, IC(i).sha));
        cache_ok = cache_ok && same;
        tee('  %-28s %s\n', IC(i).name, ternstr(same, 'match', ...
            sprintf('*** DIFFERS (baseline %s / here %s) ***', ...
                    shortsha(IC(i)), ternstr(here_present, first12(here_sha), 'ABSENT'))));
    end
    if ~cache_ok
        tee(['\n*** THE CACHED INPUTS DIFFER between the baseline capture and this\n' ...
             '*** tree, so the two legs would solve DIFFERENT ECONOMIES and any\n' ...
             '*** comparison would report a configuration difference as a refactor\n' ...
             '*** defect. Re-run  clear; FAST = %d; main_baseline_capture  to\n' ...
             '*** re-mirror the current caches into the baseline tree.\n'], FAST);
        fclose(fid);
        error('main_parity_d10_calibration:caches', ...
              'cached inputs differ from those used for the baseline capture');
    end
    tee('\n');
else
    tee(['*** this baseline .mat predates R11.8 and records no input caches, so\n' ...
         '*** the two legs may have solved different economies. Re-run\n' ...
         '*** main_baseline_capture before trusting any verdict below.\n\n']);
end

% ---- tolerances, fixed here ---------------------------------------------
TOL = struct('default', 1e-12, ...
             'eq_P', 1e-10, 'eq_q', 1e-10, 'eq_Sb', 1e-10, 'eq_Sk', 1e-10, ...
             'eq_tau', 1e-10, 'eq_dvd', 1e-10, ...
             'distribution', 1e-12, 'dP', 1e-10);
tee('tolerances: prices/aggregates 1e-10, distribution 1e-12, default 1e-12\n');
tee('(the refactor MOVED code rather than reimplementing it, so anything above\n');
tee(' these is a real defect, not a numerical difference)\n');

% =====================================================================
% LEG 2: the current SCRIPT entry point.
% Run as a script, exactly as in production, so its local-function block --
% now reduced to tee2 alone -- and its calls into the extracted functions are
% both exercised.
% =====================================================================
tee('\nLEG 2: current script entry point (main_twoasset_ownership_kv) ...\n');
% Isolated, so the script's `clearvars -except FAST KMV ...` cannot delete
% this workspace. Inline, it would have wiped pg (needed at pg.Bnom below),
% the timer t2, and the stash path itself.
t2 = tic;
run_ownership_isolated(FAST, false);               % current script, extracted fns
t_script = toc(t2);
% fid and tee survive now, so the log file is NOT reopened: doing so would
% leave a second handle on an already-open file.
SCRIPT = capture_current(fullfile(projdir,'output','twoasset_ownership_kv.mat'));
tee('  done (%.1f s)\n', t_script);

% =====================================================================
% LEG 3: the CALLABLE interface, with identical inputs.
% =====================================================================
tee('\nLEG 3: kv_calibrate_on_grid with identical inputs ...\n');
p = SCRIPT.p; iota = SCRIPT.iota_H; r_b = SCRIPT.r_b; d_base = SCRIPT.d_base;
D0 = SCRIPT.D0; Bnom = pg.Bnom; Kbar = 1.0; b_targ_H = SCRIPT.b_targ_H;
q_ref = SCRIPT.eq_q;
t3 = tic;
C = kv_calibrate_on_grid( ...
      struct('p_base', p, 'bGrid', p.bGrid, 'kGrid', p.kGrid), ...
      struct('r_b', r_b, 'd_base', d_base, 'D0', D0, 'Bnom', Bnom, ...
             'Kbar', Kbar, 'iota_H', iota, 'b_targ_H', b_targ_H, ...
             'q_ref', q_ref, 'W_targ', [], 'tag', 'parity'));
CALL = capture_C(C);
tee('  done (%.1f s)\n', toc(t3));

% =====================================================================
% COMPARISONS. 1 vs 2 first: it is the one that tests the refactor.
% =====================================================================
tee('\n%s\n', repmat('=',1,60));
tee('COMPARISON A -- BASELINE (bf0a4e8) vs CURRENT SCRIPT\n');
tee('this is the leg that tests the refactor\n');
tee('%s\n', repmat('=',1,60));
CA = kv_parity_compare(pick(BASE), pick(SCRIPT), 'baseline', 'script', TOL, tee);

tee('\n%s\n', repmat('=',1,60));
tee('COMPARISON B -- CURRENT SCRIPT vs kv_calibrate_on_grid\n');
tee('wrapper consistency; localises a failure once A has flagged one\n');
tee('%s\n', repmat('=',1,60));
NOTCALLABLE = {'EXK', 'H', 'omega', 'Gg'};
tee('fields outside kv_calibrate_on_grid''s contract, excluded from B and C:\n');
tee('  %s  (compared in A, where both legs are the same entry point)\n\n', ...
    strjoin(NOTCALLABLE, ', '));
CB = kv_parity_compare(drop(pick(SCRIPT),NOTCALLABLE), drop(pick(CALL),NOTCALLABLE), ...
                       'script', 'callable', TOL, tee);

tee('\n%s\n', repmat('=',1,60));
tee('COMPARISON C -- BASELINE vs kv_calibrate_on_grid (end to end)\n');
tee('%s\n', repmat('=',1,60));
CC = kv_parity_compare(drop(pick(BASE),NOTCALLABLE), drop(pick(CALL),NOTCALLABLE), ...
                       'baseline', 'callable', TOL, tee);

PASS = CA.pass && CB.pass && CC.pass;
tee('\n%s\nVERDICT\n%s\n', repmat('=',1,60), repmat('=',1,60));
tee('  A baseline vs script    : %s\n', ternstr(CA.pass,'PASS','FAIL'));
tee('  B script vs callable    : %s\n', ternstr(CB.pass,'PASS','FAIL'));
tee('  C baseline vs callable  : %s\n', ternstr(CC.pass,'PASS','FAIL'));
tee('\n  D10 PARITY: %s\n', ternstr(PASS,'ESTABLISHED','NOT ESTABLISHED'));
if ~PASS
    tee(['\n  Do not proceed to Track A or Track B. A failure in A alone is a\n' ...
         '  REFACTOR defect; a failure in B alone is a WRAPPER defect; a failure\n' ...
         '  in both points at the extracted functions themselves.\n']);
end

save(fullfile(projdir,'output','parity_d10_calibration.mat'), ...
     'CA','CB','CC','PASS','TOL','BASE','SCRIPT','CALL','tag');
tee('\n[main_parity_d10_calibration] wrote %s\n', sf);
fclose(fid);

% =====================================================================
function [WS, wmsg, wid] = run_ownership_isolated(FAST, REGRID)
% Run main_twoasset_ownership_kv in a PRIVATE workspace and hand back what it
% produced, as a struct.
%
% WHY A FUNCTION AND NOT AN INLINE CALL. That script opens with
%     clearvars -except FAST KMV ZETA LADDER WTARGET REGRID KFAC BFAC
% so calling it inline DELETES the caller's variables. Everything not on that
% keep-list is gone: the stash path, timers, the parameter struct, the log
% file handle. Working around it by writing the needed variables to a .mat and
% reloading them requires enumerating them correctly, and I got that
% enumeration wrong twice -- first by holding the path-restoring onCleanup
% object in a variable that clearvars deleted MID-RUN, then by storing the
% stash path in a variable named `stash` and then calling load(stash) after
% `stash` itself had been cleared.
%
% Inside a function the clearvars can only reach THIS workspace, which holds
% nothing that needs to survive: FAST and REGRID are on the script's own
% keep-list, and every other variable here is created AFTER the script
% returns. The caller's workspace is untouched by construction rather than by
% bookkeeping.
%
% THIS IS A LOCAL FUNCTION, not a file in src_project, because the caller runs
% with a deliberately isolated MATLAB path (only the frozen baseline is on it).
% A file helper would not be findable, and adding the current tree to the path
% to reach it is exactly the shadowing the isolation exists to prevent.
    if nargin < 1 || isempty(FAST),   FAST = false;   end
    if nargin < 2 || isempty(REGRID), REGRID = false; end
    lastwarn('');
    main_twoasset_ownership_kv;                 %#ok<NASGU> resolved via the path
    [wmsg, wid] = lastwarn;
    WS = struct();
    v = who;
    for i = 1:numel(v)
        if any(strcmp(v{i}, {'WS','wmsg','wid','v','i'})), continue; end
        WS.(v{i}) = eval(v{i});
    end
end

function D = capture_current(matfile)
% Harvest the current script's saved output into the same field names the
% baseline capture used, so the two are directly comparable.
    D = struct();
    M = load(matfile);
    for f = {'p','iota_H','b_targ_H','r_b','d_base','D0','Gg','omega','H','EXK','ss'}
        if isfield(M, f{1}), D.(f{1}) = M.(f{1}); end
    end
    if isfield(M,'eq0')
        e = M.eq0;
        % THE SAME LIST the baseline capture's flatten_eq uses. It was shorter
        % here, so div/min_c/msg/n_infeas/code/alpha were reported as MISSING
        % in the script leg when the script had produced them perfectly well.
        for n = {'P','q','Sb','Sk','tau','dvd','Fk','Fb','ok','mass_err', ...
                 'ksat','bsat','code','msg','alpha','div','min_c','n_infeas'}
            if isfield(e, n{1}), D.(['eq_' n{1}]) = e.(n{1}); end
        end
        if isfield(e,'dist'), D.distribution = e.dist; end
        if isfield(e,'sol')
            for n = {'V','polBa','polKa','polCa','polBn','polCn'}
                if isfield(e.sol, n{1}), D.(['pol_' n{1}]) = e.sol.(n{1}); end
            end
        end
    end
    D = add_derived(D);
end

function D = capture_C(C)
    D = struct();
    if isfield(C,'p'), D.p = C.p; end
    fmap = {'iota_H','b_targ_H','r_b','d_base','D0'};
    for i = 1:numel(fmap)
        if isfield(C,'inputs') && isfield(C.inputs, fmap{i})
            D.(fmap{i}) = C.inputs.(fmap{i});
        end
    end
    if isfield(C,'equilibrium')
        e = C.equilibrium;
        % THE SAME LIST the baseline capture's flatten_eq uses. It was shorter
        % here, so div/min_c/msg/n_infeas/code/alpha were reported as MISSING
        % in the script leg when the script had produced them perfectly well.
        for n = {'P','q','Sb','Sk','tau','dvd','Fk','Fb','ok','mass_err', ...
                 'ksat','bsat','code','msg','alpha','div','min_c','n_infeas'}
            if isfield(e, n{1}), D.(['eq_' n{1}]) = e.(n{1}); end
        end
    end
    if isfield(C,'distribution'), D.distribution = C.distribution; end
    if isfield(C,'policies')
        for n = {'V','polBa','polKa','polCa','polBn','polCn'}
            if isfield(C.policies, n{1}), D.(['pol_' n{1}]) = C.policies.(n{1}); end
        end
    end
    D = add_derived(D);
end

function D = add_derived(D)
    if isfield(D,'p')
        for n = {'beta','chi_b','zeta_b','bbar_liq','lambda_adj','div_payout'}
            if isfield(D.p, n{1}), D.(['theta_' n{1}]) = D.p.(n{1}); end
        end
        for n = {'bGrid','kGrid','xGridA','acGrid','sGrid','eGrid'}
            if isfield(D.p, n{1}), D.(['grid_' n{1}]) = D.p.(n{1}); end
        end
        for n = {'tol_vfi','maxit_vfi','tol_dist','maxit_dist'}
            if isfield(D.p, n{1}), D.(['tol_' n{1}]) = D.p.(n{1}); end
        end
    end
end

function Q = pick(D)
% Compare only comparable fields, and FLATTEN nested structs rather than
% comparing them whole.
%
% A struct comparison collapses to a single isequaln bit, which is why EXK and
% H reported "1.0000e+00 FAIL" -- a value that means "not equal" and says
% nothing about which leaf moved. Their scalar leaves are expanded into
% EXK_<leaf>, H_<leaf> instead, so a difference names itself.
%
% eq0 is dropped because every one of its fields is already present flattened
% as eq_*; comparing it as well would double-count and add an uninformative
% whole-struct bit on top of the informative per-field ones.
    Q = struct(); f = fieldnames(D);
    SKIP = {'p','ss','env','missing_fields','warning_last','eq0', ...
            'input_caches','distribution_full'};
    for i = 1:numel(f)
        n = f{i};
        if any(strcmp(n, SKIP)), continue; end
        v = D.(n);
        if isstruct(v) && isscalar(v)
            g = fieldnames(v);
            for j = 1:numel(g)
                w = v.(g{j});
                if (isnumeric(w) || islogical(w)) && isscalar(w)
                    Q.([n '_' g{j}]) = w;
                end
            end
        else
            Q.(n) = v;
        end
    end
end

function Q = drop(Q, names)
% Remove fields the CALLABLE is not contracted to produce. kv_calibrate_on_grid
% is a calibration interface: it does not run the Shapley extension (EXK), the
% hand-to-mouth decomposition (H), the liquid share (omega) or the program size
% (Gg). Reporting those as parity failures would be reporting a difference in
% SCOPE as a difference in behaviour. They are still compared in A, where both
% legs are the same entry point and a missing field is a real defect.
    for i = 1:numel(names)
        f = fieldnames(Q);
        hit = f(startsWith(f, names{i}));
        for j = 1:numel(hit), Q = rmfield(Q, hit{j}); end
    end
end

function s = shortsha(r)
    if r.present && ~isempty(r.sha), s = r.sha(1:12); else, s = 'ABSENT'; end
end

function s = first12(h)
    if isempty(h), s = 'ABSENT'; else, s = h(1:min(12,numel(h))); end
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
