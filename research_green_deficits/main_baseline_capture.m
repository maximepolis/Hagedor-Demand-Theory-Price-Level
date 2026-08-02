% MAIN_BASELINE_CAPTURE  Freeze the PRE-REFACTOR outputs.
%
% THIS FILE IS COPIED INTO THE BASELINE WORKTREE AND RUN THERE. It is the only
% file added to that worktree; it reads the pre-refactor code and does not
% modify a line of it. Everything it produces is written OUTSIDE the worktree,
% into the main tree's output/baseline/, so that the worktree stays byte-
% identical to commit bf0a4e8 and `make_prerefactor_baseline.sh verify` keeps
% passing.
%
% WHY THIS EXISTS. The D10 and D11 parity tests as originally written compare
%   (a) the current script calling the EXTRACTED functions, against
%   (b) the new callable interface calling THOSE SAME extracted functions.
% Both branches depend on the same moved code, so the comparison establishes
% wrapper consistency and nothing else. It cannot detect that moving ten
% functions out of main_twoasset_ownership_kv's local-function block changed
% behaviour, because there is no branch in it that does not use the moved
% code. The same applies to D11: comparing the legacy and explicit-fiscal
% branches of the already-refactored solver says nothing about the solver at
% the previous commit.
%
% The missing leg is this one: the code AT bf0a4e8, executed, with its outputs
% written to a versioned file. Only against that can the refactor be checked.
%
% USAGE, in MATLAB, from the WORKTREE's research_green_deficits directory:
%     clear; restoredefaultpath;
%     BASELINE_OUT = '/abs/path/to/main/tree/research_green_deficits/output/baseline';
%     main_baseline_capture
%
% Optional: FAST = true (must match the FAST setting of the current-code run
% it will be compared against -- a parity test across different grids is not
% a parity test).
%
% OUTPUT  <BASELINE_OUT>/baseline_d10_<tag>.mat   calibration leg
%         <BASELINE_OUT>/baseline_d11_<tag>.mat   transition leg
%         <BASELINE_OUT>/baseline_capture.txt

clearvars -except BASELINE_OUT FAST RHOBAR; close all; clc;
t0 = tic;

wtdir = fileparts(mfilename('fullpath'));
if isempty(wtdir), wtdir = pwd; end
cd(wtdir);
wtroot = fileparts(wtdir);

if ~exist('FAST','var'), FAST = false; end
if ~exist('RHOBAR','var') || isempty(RHOBAR), RHOBAR = 0.90; end
assert(exist('BASELINE_OUT','var') == 1 && ~isempty(BASELINE_OUT), ...
    ['BASELINE_OUT must be set to an ABSOLUTE path in the MAIN tree. Writing ' ...
     'into the worktree would leave it modified and break its verification.']);
if ~isfolder(BASELINE_OUT), mkdir(BASELINE_OUT); end

% The worktree must be the frozen commit, and it must be clean apart from
% this file. Checking here as well as in the shell script means the .mat
% cannot be produced from a tree someone edited "just to try something".
[~, headout] = system(sprintf('git -C "%s" rev-parse HEAD', wtroot));
HEAD = strtrim(headout);
[~, stout]   = system(sprintf('git -C "%s" status --porcelain', wtroot));
dirty = strtrim(stout);
dirty_tracked = '';
if ~isempty(dirty)
    L = strsplit(dirty, newline);
    keep = ~startsWith(strtrim(L), '??');
    dirty_tracked = strjoin(L(keep), '; ');
end
EXPECTED = 'bf0a4e8a4444f9d5b2c9d865a39b7de2136f67ec';

addpath(genpath(fullfile(wtroot, 'src')));
addpath(genpath(fullfile(wtdir, 'src_project')));

tag = 'bench'; if FAST, tag = 'fast'; end
lf = fullfile(BASELINE_OUT, 'baseline_capture.txt');
fid = fopen(lf, 'w'); assert(fid > 0);
tee = @(varargin) tee2(fid, varargin{:});

tee('PRE-REFACTOR BASELINE CAPTURE\n%s\n\n', repmat('=', 1, 60));
tee('worktree        %s\n', wtroot);
tee('HEAD            %s\n', HEAD);
tee('expected        %s\n', EXPECTED);
tee('tracked changes %s\n', ternstr(isempty(dirty_tracked), '(none)', dirty_tracked));
tee('MATLAB          %s on %s\n', version, computer);
tee('FAST            %d   (tag "%s")\n\n', FAST, tag);
if ~strcmp(HEAD, EXPECTED)
    tee('*** HEAD IS NOT THE FROZEN BASELINE. Refusing to capture.\n');
    fclose(fid);
    error('main_baseline_capture:head', 'HEAD %s is not %s', HEAD, EXPECTED);
end
if ~isempty(dirty_tracked)
    tee('*** TRACKED FILES DIFFER FROM THE COMMIT. Refusing to capture.\n');
    fclose(fid);
    error('main_baseline_capture:dirty', 'worktree has tracked modifications');
end

ENV = struct('commit', HEAD, 'matlab', version, 'platform', computer, ...
             'release', version('-release'), 'fast', FAST, ...
             'worktree', wtroot, 'captured_by', 'main_baseline_capture.m');

% =====================================================================
% LEG 1 (D10): the calibration.
%
% main_twoasset_ownership_kv is a SCRIPT and begins with `clearvars -except
% FAST KMV ZETA LADDER WTARGET REGRID KFAC BFAC`, so it will wipe this
% workspace. Stash what is needed, run it, reload. Running it as a script (not
% a function) is deliberate: that is exactly how it is invoked in production,
% including its local-function block, which is the thing under test.
% =====================================================================
stash = fullfile(tempdir, 'baseline_capture_stash.mat');
save(stash, 'BASELINE_OUT', 'tag', 'ENV', 'RHOBAR', 'lf', 'wtdir', 'wtroot');

lastwarn('');
warnstate = warning('off', 'backtrace');
tee('LEG 1 (D10): running the pre-refactor main_twoasset_ownership_kv ...\n');
main_twoasset_ownership_kv;                      % the pre-refactor script
warning(warnstate);
[wmsg, wid] = lastwarn;

S = load(stash);
BASELINE_OUT = S.BASELINE_OUT; tag = S.tag; ENV = S.ENV;
RHOBAR = S.RHOBAR; lf = S.lf; wtdir = S.wtdir; wtroot = S.wtroot;
fid = fopen(lf, 'a'); tee = @(varargin) tee2(fid, varargin{:});

% Everything the script left in the shared workspace is visible here, plus
% whatever it saved. Harvest from BOTH, and record what was not found rather
% than quietly omitting it -- a capture missing a field would make the
% comparison pass by default.
own = fullfile(wtdir, 'output', 'twoasset_ownership_kv.mat');
D10 = struct();
D10.env = ENV;
D10.warning_last = struct('msg', wmsg, 'id', wid);
[D10, missing10] = harvest(D10, own, { ...
    'eq0', 'EXK', 'omega', 'H', 'p', 'iota_H', 'b_targ_H', 'ss', ...
    'r_b', 'd_base', 'D0', 'Gg'});

% Flatten the pieces the comparison actually needs into scalars and arrays,
% so kv_parity_compare has typed fields rather than one opaque struct.
D10 = flatten_eq(D10, 'eq0');
D10.grid = struct('bGrid', getf(D10,'p','bGrid'), 'kGrid', getf(D10,'p','kGrid'), ...
                  'xGridA', getf(D10,'p','xGridA'), 'acGrid', getf(D10,'p','acGrid'), ...
                  'sGrid', getf(D10,'p','sGrid'), 'eGrid', getf(D10,'p','eGrid'));
D10.tolerances = struct('tol_vfi', getf(D10,'p','tol_vfi'), ...
                        'maxit_vfi', getf(D10,'p','maxit_vfi'), ...
                        'tol_dist', getf(D10,'p','tol_dist'), ...
                        'maxit_dist', getf(D10,'p','maxit_dist'));
D10.parameters_final = struct('beta', getf(D10,'p','beta'), ...
                              'chi_b', getf(D10,'p','chi_b'), ...
                              'zeta_b', getf(D10,'p','zeta_b'), ...
                              'bbar_liq', getf(D10,'p','bbar_liq'), ...
                              'lambda_adj', getf(D10,'p','lambda_adj'), ...
                              'div_payout', getf(D10,'p','div_payout'));
D10.missing_fields = missing10;

f10 = fullfile(BASELINE_OUT, sprintf('baseline_d10_%s.mat', tag));
save(f10, '-struct', 'D10');
tee('  wrote %s\n', f10);
if ~isempty(missing10)
    tee('  NOT CAPTURED (absent at this commit): %s\n', strjoin(missing10, ', '));
end

% =====================================================================
% LEG 2 (D11): the transition, at the LEGACY rho_d = 0.90 rule.
% Called as a function, so no workspace games are needed.
% =====================================================================
tee('\nLEG 2 (D11): pre-refactor solve_hank_dtpl_transition, rho_d = %.2f ...\n', RHOBAR);
pgc = setup_params_green();
T = 80; if ENV.fast, T = 60; end
o = struct('T', T, 'regime', 'indexed', 'financing', 'deficit', ...
           'rho_d', RHOBAR, 'verbose', false);
TRd = solve_hank_dtpl_transition(pgc, o);

ob = o; ob.financing = 'lumpsum'; ob.rho_d = 0;
TRb = solve_hank_dtpl_transition(pgc, ob);

D11 = struct('env', ENV, 'opts_deficit', o, 'opts_baseline', ob, ...
             'T', T, 'rho_bar', RHOBAR);
D11 = flatten_TR(D11, TRd, 'd');
D11 = flatten_TR(D11, TRb, 'b');
D11.dlnP0 = log(TRd.phat(1) / TRb.phat(1));
D11.kappa_legacy = TRd.kappa_path(end) / TRb.kappa_path(end);
D11.TR_deficit_full = TRd;      % kept whole as well, for anything not flattened
D11.TR_baseline_full = TRb;

f11 = fullfile(BASELINE_OUT, sprintf('baseline_d11_%s.mat', tag));
save(f11, '-struct', 'D11');
tee('  wrote %s\n', f11);
tee('\n  kappa_legacy    %.12f\n', D11.kappa_legacy);
tee('  dlnP0           %+.12f\n', D11.dlnP0);
tee('\n[main_baseline_capture] done (%.1f s)\n', toc(t0));
fclose(fid);
delete(stash);

% =====================================================================
function [D, missing] = harvest(D, matfile, names)
% Take each name from the caller's workspace if it is there, else from the
% saved .mat, else record it as missing. Never invent a default.
    missing = {};
    M = struct();
    if exist(matfile, 'file') == 2, M = load(matfile); end
    for i = 1:numel(names)
        n = names{i};
        if evalin('caller', sprintf('exist(''%s'',''var'')==1', n))
            D.(n) = evalin('caller', n);
        elseif isfield(M, n)
            D.(n) = M.(n);
        else
            missing{end+1} = n; %#ok<AGROW>
        end
    end
end

function D = flatten_eq(D, fld)
% Pull the equilibrium object apart into separately comparable fields.
    if ~isfield(D, fld) || ~isstruct(D.(fld)), return; end
    e = D.(fld);
    names = {'P','q','Sb','Sk','tau','dvd','Fk','Fb','ok','mass_err', ...
             'ksat','bsat','code','msg','alpha','pe'};
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
end

function D = flatten_TR(D, TR, sfx)
% The COMPLETE path, not selected headline scalars: the manuscript treats
% these as independently cross-validated quantitative outputs, so parity has
% to cover every series the solver returns.
    names = {'phat','P0','pi_path','r_path','tau_path','D_path','Kg_path', ...
             'S_path','b_path','g_path','vart_path','phi_path','kappa_path', ...
             'xi_path','primary_gap','kappa_inf','rho_d','resid','iters', ...
             'best_iter','kappa_mode','kappa_target','kappa_gap','kappa_hit', ...
             'financing','converged','horizon','T'};
    for i = 1:numel(names)
        if isfield(TR, names{i})
            D.([sfx '_' names{i}]) = TR.(names{i});
        end
    end
end

function v = getf(D, s, f)
    v = NaN;
    if isfield(D, s) && isstruct(D.(s)) && isfield(D.(s), f), v = D.(s).(f); end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
