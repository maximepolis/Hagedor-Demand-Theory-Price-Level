% MAIN_BASELINE_CAPTURE  Freeze the PRE-REFACTOR outputs. No git required.
%
% WHY THIS WAS REWRITTEN. The first version required a git worktree and
% verified the baseline with `git rev-parse HEAD`. This project is distributed
% as a GitHub ZIP and extracted, so there is no .git directory: the git call
% returned "fatal: not a git repository", that string was compared against a
% commit hash, and the capture refused to run. The requirement was wrong, not
% the setup.
%
% WHAT REPLACES IT. The frozen baseline now SHIPS WITH THE PROJECT, in
%   <root>/baseline_bf0a4e8/
% which contains the 152 .m files of commit bf0a4e8 -- extracted from the
% commit object, not reconstructed -- plus MANIFEST_bf0a4e8.sha256 listing
% every file's SHA-256 and byte length. kv_verify_baseline re-hashes the
% directory and refuses to proceed unless it matches.
%
% That is a STRONGER guarantee than the git check it replaces. `HEAD ==
% bf0a4e8` says where the checkout started; it says nothing about whether a
% file was edited afterwards. A content manifest verifies the bytes you are
% about to execute.
%
% THIS IS NOT "RECREATING THE OLD IMPLEMENTATION IN THE CURRENT SOURCE TREE",
% which was rightly ruled out. Nothing here is rewritten or reconstructed: the
% files are byte-identical copies of the commit, they live OUTSIDE both source
% trees, and no driver in the current project ever puts them on the path --
% the main drivers add genpath(<root>/src) and genpath(<proj>/src_project),
% neither of which reaches <root>/baseline_bf0a4e8. This script adds them only
% after restoredefaultpath, and restores the original path when it exits.
%
% USAGE (from the MAIN research_green_deficits folder; nothing to download):
%     clear; main_baseline_capture
%     clear; FAST = true; main_baseline_capture
%
% Optional overrides:
%     BASELINE_SRC  the baseline root (default <root>/baseline_bf0a4e8)
%     BASELINE_OUT  where to write   (default <proj>/output/baseline)
%
% FAST must match the FAST setting of the current-code run this will be
% compared against. A parity test across different grids is not a parity test,
% so the parity drivers assert on the tag.
%
% OUTPUT  <BASELINE_OUT>/baseline_d10_<tag>.mat   calibration leg
%         <BASELINE_OUT>/baseline_d11_<tag>.mat   transition leg
%         <BASELINE_OUT>/baseline_capture.txt

clearvars -except BASELINE_SRC BASELINE_OUT FAST RHOBAR REUSE_D10; close all; clc;
t0 = tic;

MAINPROJ = fileparts(mfilename('fullpath'));
if isempty(MAINPROJ), MAINPROJ = pwd; end
MAINROOT = fileparts(MAINPROJ);

if ~exist('FAST','var'), FAST = false; end
if ~exist('RHOBAR','var') || isempty(RHOBAR), RHOBAR = 0.90; end
% REUSE_D10: skip leg 1 if its .mat is already there from an earlier run of
% THIS revision. Leg 1 is the ~17-minute pre-refactor calibration and it is
% unchanged by fixes to leg 2, so re-running it is pure cost. Off by default:
% reusing a captured result is a decision, not a convenience, and it must be
% asked for. The manifest is re-verified either way -- the skip covers the
% solve, never the integrity check.
if ~exist('REUSE_D10','var') || isempty(REUSE_D10), REUSE_D10 = false; end
if ~exist('BASELINE_SRC','var') || isempty(BASELINE_SRC)
    BASELINE_SRC = fullfile(MAINROOT, 'baseline_bf0a4e8');
end
if ~exist('BASELINE_OUT','var') || isempty(BASELINE_OUT)
    BASELINE_OUT = fullfile(MAINPROJ, 'output', 'baseline');
end
if ~isfolder(BASELINE_OUT), mkdir(BASELINE_OUT); end

tag = 'bench'; if FAST, tag = 'fast'; end
lf = fullfile(BASELINE_OUT, 'baseline_capture.txt');
fid = fopen(lf, 'w'); assert(fid > 0, 'cannot write %s', lf);
tee = @(varargin) tee2(fid, varargin{:});

tee('PRE-REFACTOR BASELINE CAPTURE\n%s\n\n', repmat('=', 1, 60));
addpath(fullfile(MAINPROJ, 'src_project'));      % for kv_code_version
tee('%s\n', kv_code_version(mfilename('fullpath')));
tee('baseline source %s\n', BASELINE_SRC);
tee('output          %s\n', BASELINE_OUT);
tee('MATLAB          %s on %s\n', version, computer);
tee('FAST            %d   (tag "%s")\n\n', FAST, tag);

if ~isfolder(BASELINE_SRC)
    tee(['*** NO BASELINE DIRECTORY at\n***   %s\n***\n' ...
         '*** It ships with the project as baseline_bf0a4e8/. If your download\n' ...
         '*** predates it, re-download the repository, or point BASELINE_SRC at\n' ...
         '*** an extracted ZIP of commit bf0a4e8 with the manifest copied in.\n'], ...
        BASELINE_SRC);
    fclose(fid);
    error('main_baseline_capture:nosrc', 'no baseline at %s', BASELINE_SRC);
end

% ---- content verification, in place of the git check ---------------------
VB = kv_verify_baseline(BASELINE_SRC, tee);
if ~VB.ok
    tee(['\n*** REFUSING TO CAPTURE. The baseline directory does not match the\n' ...
         '*** manifest, so the code about to run is not commit bf0a4e8 and any\n' ...
         '*** parity result from it would be meaningless.\n']);
    fclose(fid);
    error('main_baseline_capture:verify', ...
          'baseline failed verification: %d modified, %d missing, %d unexpected', ...
          VB.n_bad, VB.n_missing, VB.n_extra);
end
tee('\n');

% Git, if it happens to be available, is a CROSS-CHECK and never a gate.
gh = try_git(MAINROOT);
if ~isempty(gh)
    tee('git present in the main tree; HEAD = %s\n', gh);
    tee('(informational only -- the baseline is verified by content, not by git)\n\n');
else
    tee('no git available; baseline verified by content manifest alone.\n\n');
end

ENV = struct('commit', 'bf0a4e8a4444f9d5b2c9d865a39b7de2136f67ec', ...
             'verified_by', 'sha256 manifest', ...
             'n_files', VB.n, 'n_exact', VB.n_exact, 'n_eol_only', VB.n_eol, ...
             'matlab', version, 'platform', computer, ...
             'release', version('-release'), 'fast', FAST, ...
             'baseline_src', BASELINE_SRC, 'main_root', MAINROOT, ...
             'captured_by', 'main_baseline_capture.m');

% ---- isolate the path ----------------------------------------------------
% ONLY the baseline is on the path from here. The current tree must not be
% reachable: a current function shadowing a baseline namesake would silently
% turn the "pre-refactor" leg into a mixture of both, which is exactly the
% failure this whole protocol exists to rule out.
BPROJ = fullfile(BASELINE_SRC, 'research_green_deficits');
BSRC  = fullfile(BASELINE_SRC, 'src');
assert(isfolder(BPROJ) && isfolder(BSRC), ...
    'baseline must contain research_green_deficits/ and src/');

% The snapshot carries source only, so the output directories the baseline
% script saves into do not exist yet. It creates output/tables itself but
% save()s straight into output/, which would error on a fresh extraction.
for d = {fullfile(BPROJ,'output'), fullfile(BPROJ,'output','tables'), ...
         fullfile(BPROJ,'output','figures')}
    if ~isfolder(d{1}), mkdir(d{1}); end
end

% The path is restored MANUALLY at the end and in the error handler, not by
% onCleanup. main_twoasset_ownership_kv opens with
%     clearvars -except FAST KMV ZETA LADDER WTARGET REGRID KFAC BFAC
% and an onCleanup object held in this workspace would once have been deleted
% by it and fired MID-RUN, restoring the main tree's path while the baseline
% script was still executing -- turning the "pre-refactor" leg into a mixture
% of both trees.
%
% That clearvars can no longer reach this workspace at all: the script is now
% invoked through run_ownership_isolated, a local function whose own workspace
% absorbs it. OLDPATH therefore survives as an ordinary variable, with no
% stash file and no enumeration of what to save.
OLDPATH = path; OLDCWD = pwd;
restoredefaultpath;
addpath(genpath(BSRC), '-begin');
addpath(genpath(fullfile(BPROJ, 'src_project')), '-begin');
addpath(BPROJ, '-begin');
cd(BPROJ);

% Prove the isolation rather than assuming it.
w = which('main_twoasset_ownership_kv');
tee('main_twoasset_ownership_kv resolves to\n  %s\n', w);
assert(startsWith(canon(w), canon(BPROJ)), ...
    ['the baseline script is being shadowed by %s -- the path isolation ' ...
     'failed and the capture would not be pre-refactor code'], w);
nloc = count_local_functions(w);
% The pre-refactor file declares 12 `function` statements (11 at column 1
% plus one indented); the post-refactor file declares 1. Any count in double
% figures is the old file, which is what this is testing.
tee('  and declares %d function statements (pre-refactor 12, post-refactor 1)\n', nloc);
assert(nloc >= 10, ...
    ['the resolved main_twoasset_ownership_kv has only %d function ' ...
     'declarations; the pre-refactor file has 11 local functions, so this ' ...
     'is the POST-refactor file'], nloc);
wt = which('solve_hank_dtpl_transition');
tee('solve_hank_dtpl_transition resolves to\n  %s\n\n', wt);
assert(startsWith(canon(wt), canon(BASELINE_SRC)), 'transition solver is shadowed');

% =====================================================================
% LEG 1 (D10): the calibration.
%
% Invoked through run_ownership_isolated so that its
%     clearvars -except FAST KMV ZETA LADDER WTARGET REGRID KFAC BFAC
% is absorbed by that function's workspace and cannot touch this one.
%
% It is still run AS A SCRIPT, which is deliberate: that is exactly how it is
% invoked in production, including its local-function block, which is the
% thing under test. The isolation changes where its variables live, not how it
% executes.
% =====================================================================
f10 = fullfile(BASELINE_OUT, sprintf('baseline_d10_%s.mat', tag));
if REUSE_D10 && exist(f10, 'file') == 2
    tee(['LEG 1 (D10): REUSED from %s\n' ...
         '  (REUSE_D10 = true; the pre-refactor calibration was not re-run.\n' ...
         '   The baseline manifest was still verified above.)\n'], f10);
    Dchk = load(f10, 'env');
    if isfield(Dchk,'env') && isfield(Dchk.env,'fast') && Dchk.env.fast ~= FAST
        path(OLDPATH); cd(OLDCWD);
        error('main_baseline_capture:reusefast', ...
            'the reused leg-1 file has FAST=%d but this run has FAST=%d', ...
            Dchk.env.fast, FAST);
    end
else
    lastwarn('');
    tee('LEG 1 (D10): running the pre-refactor main_twoasset_ownership_kv ...\n');
    fclose(fid); fid = -1;                          % the script writes a lot
    try
        [WS, wmsg, wid] = run_ownership_isolated(FAST, false);
    catch ME_capture
        path(OLDPATH); cd(OLDCWD);
        rethrow(ME_capture);
    end
    fid = fopen(lf, 'a'); tee = @(varargin) tee2(fid, varargin{:});

    own = fullfile(BPROJ, 'output', 'twoasset_ownership_kv.mat');
    D10 = struct();
    D10.env = ENV;
    D10.warning_last = struct('msg', wmsg, 'id', wid);
    [D10, missing10] = harvest(D10, WS, own, { ...
        'eq0', 'EXK', 'omega', 'H', 'p', 'iota_H', 'b_targ_H', 'ss', ...
        'r_b', 'd_base', 'D0', 'Gg'});
    D10 = flatten_eq(D10, 'eq0');
    D10.missing_fields = missing10;
    save(f10, '-struct', 'D10');
    tee('  wrote %s\n', f10);
    if ~isempty(missing10)
        tee('  NOT CAPTURED (absent at this commit): %s\n', strjoin(missing10, ', '));
    end
end

% =====================================================================
% LEG 2 (D11): the transition, at the LEGACY rho_d = 0.90 rule.
% =====================================================================
tee('\nLEG 2 (D11): pre-refactor solve_hank_dtpl_transition, rho_d = %.2f ...\n', RHOBAR);
[pgc, opts_base, calinfo] = legacy_transition_setup(ENV.fast);
T = opts_base.T;
tee('  legacy setup: na=%d, T=%d, beta*=%.6f, D0=%.3f, Gg=%.6f\n', ...
    calinfo.na, T, calinfo.beta_star, calinfo.D0_med, calinfo.Gg_cal);
tee('  (beta is CALIBRATED, as every legacy driver does; the default beta\n');
tee('   leaves no root in the solver''s hard-coded [0.5, 1.3] price bracket)\n');

o = opts_base; o.regime = 'indexed'; o.financing = 'deficit'; o.rho_d = RHOBAR;
TRd = solve_hank_dtpl_transition(pgc, o);
check_TR(TRd, 'deficit');
tee('  deficit  : %s\n', getmsg(TRd));

ob = opts_base; ob.regime = 'indexed'; ob.financing = 'lumpsum'; ob.rho_d = 0;
TRb = solve_hank_dtpl_transition(pgc, ob);
check_TR(TRb, 'balanced baseline');
tee('  balanced : %s\n', getmsg(TRb));

D11 = struct('env', ENV, 'opts_deficit', o, 'opts_baseline', ob, ...
             'pgc', pgc, 'calinfo', calinfo, 'T', T, 'rho_bar', RHOBAR);
D11 = flatten_TR(D11, TRd, 'd');
D11 = flatten_TR(D11, TRb, 'b');
D11.dlnP0 = log(TRd.phat(1) / TRb.phat(1));
D11.kappa_legacy = TRd.kappa_path(end) / TRb.kappa_path(end);
D11.TR_deficit_full = TRd;
D11.TR_baseline_full = TRb;

f11 = fullfile(BASELINE_OUT, sprintf('baseline_d11_%s.mat', tag));
save(f11, '-struct', 'D11');
tee('  wrote %s\n', f11);
tee('\n  kappa_legacy    %.12f\n', D11.kappa_legacy);
tee('  dlnP0           %+.12f\n', D11.dlnP0);
tee('\n[main_baseline_capture] done (%.1f s)\n', toc(t0));
fclose(fid); fid = -1;

% ---- restore the caller's environment -----------------------------------
path(OLDPATH); cd(OLDCWD);
fprintf('path and working directory restored.\n');
fprintf('If a run is ever interrupted before this line, recover with:\n');
fprintf('  clear; restoredefaultpath; run_project_path_setup\n');

% =====================================================================
function [pgc, opts, info] = legacy_transition_setup(FAST)
% Build (pgc, opts) EXACTLY as the legacy transition drivers do.
%
% WHY THIS EXISTS. The first version of this capture called
%     pgc = setup_params_green();
%     o   = struct('T',T,'regime','indexed','financing','deficit','rho_d',0.90);
% and the solver failed with "regime TR-BASE: no sign change on [0.5, 1.3]
% (Phi ends: +2.018 / +3.078)". It was not a solver defect. Every real caller
% -- main_transition_deficit.m lines 55-83, main_project_transition.m -- does
%
%     pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
%     opts.Gg_nom = Gg_cal;
%
% with beta_star from calibrate_beta. Passing the DEFAULT beta leaves asset
% demand far above debt supply at every P in the hard-coded bracket, so Phi is
% positive at both ends and no root exists. The FAST branch additionally
% rebuilds the asset grid at pg.fast.na, which the first version also skipped:
% it only shortened T.
%
% So the earlier D11 leg was never the legacy experiment. That defect was
% shared by kv_kappa_legacy, which is corrected the same way.
%
% THE CALIBRATION IS ALWAYS RECOMPUTED, never read from
% output/calibrated_results.mat as the legacy driver optionally does. A cached
% beta that exists in one tree and not the other would make the two legs
% differ by their CACHE rather than by their code, which is precisely what a
% parity test must not permit.
    pg = setup_params_green();
    opts = struct('T', 80, 'tol', 2e-3, 'maxit', 120, 'xi', 0.5, 'verbose', false);
    if FAST
        pg.na    = pg.fast.na;
        u        = linspace(0, 1, pg.na)';
        pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u .^ pg.acurv);
        pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
        opts.T = 60; opts.maxit = 80;
    end
    D0_med = 0.06;
    [beta_star, ~] = calibrate_beta(pg, (1 + pg.i_ss)/(1 + pg.mu) - 1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
    pgc = pg;
    pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
    opts.Gg_nom = Gg_cal;
    info = struct('beta_star', beta_star, 'D0_med', D0_med, 'Gg_cal', Gg_cal, ...
                  'na', pg.na, 'T', opts.T, ...
                  'source', 'main_transition_deficit.m lines 55-83');
end

function check_TR(TR, name)
% A transition that did not produce a path is a DIAGNOSIS, not a missing
% field. Accessing TR.phat on a failed solve raised "Unrecognized field name",
% which says nothing about why the solve failed even though the solver had put
% the reason in TR.msg.
    if isstruct(TR) && isfield(TR, 'phat') && ~isempty(TR.phat), return; end
    m = '(the solver returned no message)';
    if isstruct(TR) && isfield(TR, 'msg') && ~isempty(TR.msg), m = TR.msg; end
    error('transition:failed', ...
        ['the %s transition produced no price path.\n  solver message: %s\n' ...
         '  A "no sign change on [0.5, 1.3]" here usually means pgc.beta is ' ...
         'the DEFAULT rather than the calibrated value -- see ' ...
         'legacy_transition_setup.'], name, m);
end

function s = getmsg(TR)
    s = '(no message)';
    if isstruct(TR) && isfield(TR,'msg') && ~isempty(TR.msg), s = TR.msg; end
end

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

function s = canon(p)
    s = strrep(char(p), '\', '/');
    s = regexprep(s, '/+$', '');
    if ispc, s = lower(s); end
end

function n = count_local_functions(f)
% How many `function` declarations the resolved file carries. The pre-refactor
% main_twoasset_ownership_kv has 11; the post-refactor one has 1 (tee2). This
% is a content check on the file actually resolved, so it catches the case
% where the path looks right but the file is the current one.
    n = 0;
    fh = fopen(f, 'r'); if fh < 0, return; end
    while true
        l = fgetl(fh);
        if ~ischar(l), break; end
        if ~isempty(regexp(strtrim(l), '^function\>', 'once')), n = n + 1; end
    end
    fclose(fh);
end

function h = try_git(d)
% Informational only. Never gates anything, and never lets git's stderr text
% be mistaken for a commit hash -- which is precisely what the first version
% of this file did.
    h = '';
    try
        [st, out] = system(sprintf('git -C "%s" rev-parse HEAD', d));
        if st ~= 0, return; end
        s = strtrim(out);
        if ~isempty(regexp(s, '^[0-9a-f]{40}$', 'once')), h = s; end
    catch
    end
end

function [D, missing] = harvest(D, WS, matfile, names)
% Take each name from the script's returned workspace if it is there, else
% from the saved .mat, else record it as missing. Never invent a default: a
% capture that quietly omitted a field would make the comparison pass by
% default rather than fail.
    missing = {};
    M = struct();
    if exist(matfile, 'file') == 2, M = load(matfile); end
    for i = 1:numel(names)
        n = names{i};
        if isstruct(WS) && isfield(WS, n)
            D.(n) = WS.(n);
        elseif isfield(M, n)
            D.(n) = M.(n);
        else
            missing{end+1} = n; %#ok<AGROW>
        end
    end
end

function D = flatten_eq(D, fld)
    if ~isfield(D, fld) || ~isstruct(D.(fld)), return; end
    e = D.(fld);
    names = {'P','q','Sb','Sk','tau','dvd','Fk','Fb','ok','mass_err', ...
             'ksat','bsat','code','msg','alpha','div','min_c','n_infeas'};
    for i = 1:numel(names)
        if isfield(e, names{i}), D.(['eq_' names{i}]) = e.(names{i}); end
    end
    if isfield(e,'dist'), D.distribution = e.dist; end
    if isfield(e,'sol')
        s = e.sol;
        pn = {'V','polBa','polKa','polCa','polBn','polCn'};
        for i = 1:numel(pn)
            if isfield(s, pn{i}), D.(['pol_' pn{i}]) = s.(pn{i}); end
        end
    end
    if isfield(D,'p') && isstruct(D.p)
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

function D = flatten_TR(D, TR, sfx)
% The COMPLETE path, not selected headline scalars.
    names = {'phat','P0','pi_path','r_path','tau_path','D_path','Kg_path', ...
             'S_path','b_path','g_path','vart_path','phi_path','kappa_path', ...
             'xi_path','primary_gap','kappa_inf','rho_d','resid','iters', ...
             'best_iter','kappa_mode','kappa_target','kappa_gap','kappa_hit', ...
             'financing','converged','horizon','T'};
    for i = 1:numel(names)
        if isfield(TR, names{i}), D.([sfx '_' names{i}]) = TR.(names{i}); end
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    if fid > 0, fprintf(fid, varargin{:}); end
end
