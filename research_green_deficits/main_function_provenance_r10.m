% MAIN_FUNCTION_PROVENANCE_R10  Which file does each critical function name
% actually resolve to, and is anything shadowed?
%
% WHY THIS RUNS BEFORE PARITY, NOT AFTER. The D10 refactor moved ten
% functions out of main_twoasset_ownership_kv's local-function block into
% src_project/. A local function is visible to exactly one file; a file
% function is visible to every file on the path. The BODIES are unchanged, but
% the visibility is not, and a parity test that passes while a shadowed
% namesake is quietly winning proves nothing about the code you think you ran.
%
% The names that changed status are deliberately generic:
%   resid_of  report2d  eval_own  bracket_finite  calib_beta  calib_chi
%   calib_beta_chi  solve_own_kv  kv_agg  htm_bk
% `bracket_finite` in particular is a name any project might define.
%
% ALREADY KNOWN, AND THE REASON THIS FILE EXISTS. Two files named
% solve_household_egm.m are on the path with DIFFERENT SIGNATURES (five
% outputs in src/, four in src_project/) and two callers with incompatible
% expectations. One polarity errors; the other binds asset grid INDICES to a
% variable used as asset LEVELS and does not error. See
% run_project_path_setup for the full statement.
%
% OUTPUT  output/tables/function_provenance_r10.txt
%         output/function_provenance_r10.mat
%
% USAGE   >> clear; restoredefaultpath; run_project_path_setup
%         >> main_function_provenance_r10

clearvars -except KEEPPATH; close all; clc;
t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);

PATHINFO = run_project_path_setup(struct('quiet', true));

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'function_provenance_r10.txt');
fid = fopen(sf, 'w'); assert(fid > 0);
tee = @(varargin) tee2(fid, varargin{:});

tee('FUNCTION PROVENANCE AUDIT (R10/R11)\n');
tee('%s\n\n', repmat('=', 1, 70));
tee('%s\n', kv_code_version(mfilename('fullpath')));
tee('MATLAB %s on %s\n', version, computer);
tee('root    %s\n', rootdir);
tee('project %s\n', projdir);
tee('commit  %s\n\n', git_head(rootdir));

% The functions the calibration and transition drivers depend on, plus every
% name the D10 refactor promoted from local to global.
NAMES = { ...
  ... % --- moved out of main_twoasset_ownership_kv by D10 (generic names) ---
  'calib_beta', 'calib_beta_chi', 'calib_chi', 'resid_of', 'report2d', ...
  'eval_own', 'solve_own_kv', 'bracket_finite', 'kv_agg', 'htm_bk', ...
  ... % --- the household and equilibrium core ---
  'solve_household_egm', 'solve_household_vfi', 'solve_household_twoasset_kv', ...
  'kv_stationary_block', 'stationary_distribution_twoasset_kv', ...
  'push_forward_twoasset_kv', 'twoasset_kv_bellman_step', ...
  ... % --- the transition and fiscal chain ---
  'solve_hank_dtpl_transition', 'twoasset_kv_transition_residual', ...
  'transition_residual_dtpl', 'twoasset_fiscal_tax', 'S_green', ...
  ... % --- the kv_ helper layer introduced in R9/R10 ---
  'kv_solve_alpha', 'kv_solve_bond_given_q', 'kv_bracket_finite', ...
  'kv_node_status', 'kv_is_admissible', 'kv_boundary_mass', ...
  'kv_grid_curv', 'kv_grid_build', 'kv_widen_grids', 'kv_ensure_widened', ...
  'kv_grid_state', 'kv_grid_base', 'kv_hash', 'kv_prices_to_pe', ...
  'kv_tau_of', 'kv_div_of', 'kv_calibrate_on_grid', 'kv_fiscal_spec', ...
  'kv_kappa_legacy', 'kv_scan_node', 'kv_shapley_coalition', ...
  ... % --- setup ---
  'setup_params_green', 'setup_params', 'make_income_process', 'rouwenhorst'};

REC = struct('name', {}, 'winner', {}, 'all', {}, 'n', {}, 'sha', {}, ...
             'bytes', {}, 'shadowed', {}, 'missing', {}, 'in_matlab', {});

tee('%-36s %5s  %-8s  %s\n', 'function', 'n', 'sha256(8)', 'resolves to');
tee('%s\n', repmat('-', 1, 100));
for i = 1:numel(NAMES)
    nm = NAMES{i};
    W = which('-all', nm);
    if ischar(W), W = {W}; end
    W = W(:)';
    % `which -all` lists built-ins and methods too; keep them, but say so.
    isfile_ = cellfun(@(s) exist(s,'file')==2, W);
    r = struct('name', nm, 'winner', '', 'all', {W}, 'n', numel(W), ...
               'sha', '', 'bytes', NaN, 'shadowed', numel(W) > 1, ...
               'missing', isempty(W), 'in_matlab', any(~isfile_));
    if ~isempty(W)
        r.winner = W{1};
        if exist(W{1}, 'file') == 2
            [r.sha, r.bytes] = filehash(W{1});
        end
    end
    REC(end+1) = r; %#ok<SAGROW>
    tee('%-36s %5d  %-8s  %s\n', nm, r.n, first8(r.sha), shorten(r.winner, rootdir));
    for j = 2:numel(W)
        tee('%-36s %5s  %-8s  SHADOWED: %s\n', '', '', '', shorten(W{j}, rootdir));
    end
end

% ---------------------------------------------------------------- verdicts
tee('\n%s\n', repmat('=', 1, 70));
tee('VERDICTS\n');
tee('%s\n\n', repmat('=', 1, 70));

miss = REC([REC.missing]);
if ~isempty(miss)
    tee('NOT FOUND ON THE PATH (%d):\n', numel(miss));
    for i = 1:numel(miss), tee('  ! %s\n', miss(i).name); end
    tee('\n');
end

sh = REC([REC.shadowed]);
tee('SHADOWED NAMES: %d\n', numel(sh));
for i = 1:numel(sh)
    tee('  ! %-32s %d files\n', sh(i).name, sh(i).n);
    for j = 1:sh(i).n
        tee('       %s %s\n', ternstr(j==1,'WINS   ','shadow '), shorten(sh(i).all{j}, rootdir));
    end
end
if isempty(sh), tee('  none\n'); end

% The specific collision that has a silent polarity gets checked by name and
% by SIGNATURE, not just by count: the danger is not that two files exist, it
% is that they return different numbers of outputs.
tee('\nsolve_household_egm ARITY CHECK\n');
% Set by the branch below and consumed by the verdict. Default TRUE only when
% there is no collision to be unsafe about; any live collision must prove its
% own safety rather than inherit it.
egm_safe_polarity = true;
E = REC(strcmp({REC.name}, 'solve_household_egm'));
if isempty(E) || E.n < 2
    tee('  only one definition on the path; collision resolved or absent.\n');
else
    for j = 1:E.n
        [no, sig] = out_arity(E.all{j});
        tee('  %s outputs=%d  %s\n', ternstr(j==1,'WINS  ','shadow'), no, shorten(E.all{j}, rootdir));
        tee('        %s\n', sig);
    end
    tee(['\n  If the FIVE-output file wins, src_project/S_green.m:108 asks for four\n' ...
         '  outputs and receives polA_idx, polA, polC bound to polA, polC, hhdiag.\n' ...
         '  Grid INDICES would be used as asset LEVELS, with no error raised.\n' ...
         '  If the FOUR-output file wins, src/aggregate_asset_demand.m:136 asks for\n' ...
         '  five and MATLAB errors immediately. Only the second is safe.\n']);
    % Decide it here rather than leaving the reader to. The safe polarity is
    % the FOUR-output file winning: its failure mode is a loud error in a
    % caller that wants five, whereas the other polarity binds grid INDICES
    % into an asset-LEVEL variable and returns a plausible wrong number.
    [nowin, ~] = out_arity(E.all{1});
    egm_safe_polarity = (nowin == 4);
    if egm_safe_polarity
        tee('  => SAFE POLARITY: the four-output file wins. A caller wanting five\n');
        tee('     errors loudly; nothing silently reinterprets indices as levels.\n');
    else
        tee('  => UNSAFE POLARITY: the five-output file wins. S_green would bind\n');
        tee('     polA_idx into polA and use grid INDICES as asset LEVELS, with no\n');
        tee('     error. Every number downstream of S_green is void until the path\n');
        tee('     is reordered or the file renamed.\n');
    end
end

% ---------------------------------------------------------------- exclusions
% NONE. This block previously announced that download_data.m was excluded from
% the block parser and pointed at a rationale document. That was written before
% the question was actually settled, and it was wrong on both counts: no
% exclusion is needed and no such document exists.
%
% The block-parser failure was in the PARSER. paper/check_matlab_blocks.py now
% implements MATLAB's real lexical rules and passes all 269 project files
% including download_data.m, which is well-formed (it uses a nested function,
% which naive parsers mis-balance). See FUNCTION_NAMESPACE_PLAN_R11.md section 3.
tee('\nDELIBERATE EXCLUSIONS\n');
tee('  none. download_data.m parses cleanly under paper/check_matlab_blocks.py;\n');
tee('  the earlier failure was a parser defect, not a file defect, and the data\n');
tee('  pipeline was not modified. See FUNCTION_NAMESPACE_PLAN_R11.md section 3.\n');

% ---- VERDICT, THREE-WAY -------------------------------------------------
% The previous rule demanded that EVERY shadowed name resolve inside
% src_project. That is too narrow and it fired a false alarm on its first
% real run: `rouwenhorst` lives in the ROOT package's src/ and has no
% src_project copy, so it could never satisfy the test however correctly it
% resolved. The run then printed "DO NOT RUN PARITY" on an installation whose
% resolution was in fact safe on both counts.
%
% The distinction that actually matters is not which project folder wins, but
% whether the winner is a PROJECT FILE AT ALL, and whether a same-name pair
% inside the project resolves to the safe polarity:
%
%   INTERNAL collision   two files in this repository share a name. Fixable
%                        only by renaming; whether it is dangerous depends on
%                        the arity check below.
%   EXTERNAL contamination  the shadow comes from outside the repository --
%                        another toolchain on the user's MATLAB path. Fixable
%                        by path hygiene (restoredefaultpath), and dangerous
%                        precisely because it varies by machine and by what
%                        else the user ran in the same session.
inproj = @(f) startsWith(f, rootdir);
n_ext_win = 0; n_int = 0; n_ext_shadow = 0;
for i = 1:numel(sh)
    if ~inproj(sh(i).winner), n_ext_win = n_ext_win + 1; end
    others = sh(i).all;
    for j = 1:numel(others)
        if strcmp(others{j}, sh(i).winner), continue; end
        if inproj(others{j}), n_int = n_int + 1; else, n_ext_shadow = n_ext_shadow + 1; end
    end
end
allok = (n_ext_win == 0) && egm_safe_polarity;
tee('\nSHADOW CLASSIFICATION\n');
tee('  winners outside the repository        : %d  (any is disqualifying)\n', n_ext_win);
tee('  internal name collisions (rename)     : %d\n', n_int);
tee('  external shadows, project file wins   : %d  (path hygiene; machine-dependent)\n', n_ext_shadow);
if n_ext_shadow > 0
    tee('  NOTE: an external shadow that loses TODAY can win TOMORROW. Path\n');
    tee('  order decides, and adding another toolchain in the same MATLAB\n');
    tee('  session can reorder it. Always restoredefaultpath first.\n');
end
tee('\nRESULT: %s\n', ternstr(allok, ...
    ['every shadowed name resolves to a PROJECT file and the arity polarity ' ...
     'is safe -- parity may run'], ...
    ['a name resolves OUTSIDE the repository, or the unsafe arity polarity ' ...
     'wins -- DO NOT RUN PARITY']));

save(fullfile(projdir, 'output', 'function_provenance_r10.mat'), ...
     'REC', 'PATHINFO', 'NAMES');
tee('\n[main_function_provenance_r10] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function [h, n] = filehash(f)
    h = ''; n = NaN;
    fh = fopen(f, 'r');
    if fh < 0, return; end
    b = fread(fh, Inf, '*uint8'); fclose(fh);
    n = numel(b);
    % kv_sha256 is pure MATLAB: no JVM, which R2025b does not have.
    h = kv_sha256(b);
end

function [n, sig] = out_arity(f)
% Count declared outputs from the function signature line.
    n = NaN; sig = '(could not read)';
    fh = fopen(f, 'r'); if fh < 0, return; end
    while true
        l = fgetl(fh);
        if ~ischar(l), break; end
        t = strtrim(l);
        if startsWith(t, 'function')
            sig = t;
            m = regexp(t, '^function\s*\[([^\]]*)\]\s*=', 'tokens', 'once');
            if ~isempty(m)
                n = numel(strsplit(strtrim(m{1}), ','));
            else
                n = double(~isempty(regexp(t, '^function\s+\w+\s*=', 'once')));
            end
            break;
        end
    end
    fclose(fh);
end

function s = git_head(d)
% Informational only, and it must NEVER let git's stderr become the answer.
% The project is normally used from an extracted ZIP with no .git, where an
% unguarded version of this returned "fatal: not a git repository ..." and
% that string was printed as though it were a commit.
    s = '(no git; project distributed as a ZIP)';
    try
        [st, o] = system(sprintf('git -C "%s" rev-parse HEAD', d));
        if st ~= 0, return; end
        t = strtrim(o);
        if isempty(regexp(t, '^[0-9a-f]{40}$', 'once')), return; end
        s = t;
        [st2, o2] = system(sprintf('git -C "%s" status --porcelain', d));
        if st2 == 0 && ~isempty(strtrim(o2)), s = [s '  (WORKING TREE DIRTY)']; end
    catch
    end
end

function s = shorten(p, rootdir)
    s = p;
    if ~isempty(rootdir) && startsWith(s, rootdir)
        s = ['<root>' s(numel(rootdir)+1:end)];
    end
end

function s = first8(h)
    if isempty(h), s = '--------'; else, s = h(1:min(8, numel(h))); end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
