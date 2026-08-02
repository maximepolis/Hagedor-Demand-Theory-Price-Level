function INFO = run_project_path_setup(opts)
% RUN_PROJECT_PATH_SETUP  Put the project on the MATLAB path in an order that
% is DECLARED rather than inherited, and report what that order decides.
%
% WHY THIS IS NOT A CONVENIENCE. Two files named solve_household_egm.m exist
% in this repository, with DIFFERENT SIGNATURES:
%
%   src/solve_household_egm.m
%       [V, polA_idx, polA, polC, hhdiag] = solve_household_egm(r, tau, params)
%   src_project/solve_household_egm.m
%       [V, polA,     polC, hhdiag]       = solve_household_egm(r, tau, p)
%
% and two callers with incompatible expectations:
%
%   src/aggregate_asset_demand.m:136   [~,polA_idx,polA,polC,hhdiag] = solver(...)
%   src_project/S_green.m:108          [V,polA,polC,hhdiag] = solve_household_egm(...)
%
% ONE OF THE TWO POLARITIES FAILS SILENTLY. If src_project wins, the src
% caller asks for five outputs from a four-output function and MATLAB raises
% an error -- loud, immediate, harmless. If src wins, S_green asks for four
% outputs from a five-output function and gets them, bound as
%
%       polA   <- polA_idx     (integer grid INDICES, 1..na)
%       polC   <- polA         (asset levels)
%       hhdiag <- polC         (consumption)
%
% with no error of any kind. Asset indices would be used as asset holdings
% and the run would complete and produce numbers. Which polarity you get is
% decided by the order of two addpath calls.
%
% Every driver in this project currently does
%       addpath(genpath(.../src)); addpath(genpath(.../src_project));
% and addpath PREPENDS, so the second call wins and the safe polarity holds.
% It holds by accident of ordering, not by design, and `restoredefaultpath`
% followed by a different order flips it. This function makes the order
% explicit, states which file wins, and fails loudly if the winner changes.
%
% THE PERMANENT FIX IS A RENAME, NOT AN ORDERING. See
% FUNCTION_NAMESPACE_PLAN_R11.md: the src_project file becomes
% solve_household_egm_green.m and the collision stops existing. Until that
% rename has been made and parity has been re-run, this function is the
% guard.
%
% USAGE   >> clear; restoredefaultpath; run_project_path_setup
%         >> INFO = run_project_path_setup(struct('quiet',true));
%
% OUTPUT  INFO .rootdir .projdir .added .collisions .winner .ok

    if nargin < 1, opts = struct(); end
    quiet = isfield(opts,'quiet') && opts.quiet;

    projdir = fileparts(mfilename('fullpath'));
    if isempty(projdir), projdir = pwd; end
    rootdir = fileparts(projdir);

    % DECLARED ORDER. src first, then src_project at higher precedence.
    % '-begin' is written out rather than relying on addpath's default so that
    % the precedence is visible in the source and survives a reader who does
    % not remember which end addpath adds to.
    addpath(genpath(fullfile(rootdir, 'src')),        '-begin');
    addpath(genpath(fullfile(projdir, 'src_project')), '-begin');
    addpath(projdir, '-begin');

    INFO = struct('rootdir', rootdir, 'projdir', projdir, ...
                  'added', {{fullfile(rootdir,'src'), ...
                             fullfile(projdir,'src_project'), projdir}}, ...
                  'collisions', {{}}, 'winner', struct(), 'ok', true);

    % ---- collisions between the two source trees -------------------------
    a = listfns(fullfile(rootdir, 'src'));
    b = listfns(fullfile(projdir, 'src_project'));
    both = intersect(a, b);
    INFO.collisions = both;

    if ~quiet
        fprintf('PROJECT PATH, in declared precedence order (first wins):\n');
        fprintf('  1. %s   (and the project drivers)\n', projdir);
        fprintf('  2. %s\n', fullfile(projdir,'src_project'));
        fprintf('  3. %s\n', fullfile(rootdir,'src'));
        fprintf('\n');
    end

    for i = 1:numel(both)
        nm = both{i};
        w = which(nm);
        INFO.winner.(matlab.lang.makeValidName(nm)) = w;
        exp_win = fullfile(projdir, 'src_project', [nm '.m']);
        agree = strcmp(fullpath_(w), fullpath_(exp_win));
        if ~agree, INFO.ok = false; end
        if ~quiet
            fprintf('COLLISION  %s\n', nm);
            fprintf('   winner : %s\n', w);
            fprintf('   shadow : %s\n', fullfile(rootdir,'src',[nm '.m']));
            fprintf('   %s\n', ternstr(agree, ...
                'src_project wins, which is the safe polarity (see the header).', ...
                '*** src WINS. THIS IS THE SILENT-CORRUPTION POLARITY. STOP. ***'));
        end
    end
    if isempty(both) && ~quiet
        fprintf('no filename collisions between src/ and src_project/\n');
    end
    if ~INFO.ok
        error('run_project_path_setup:shadow', ...
            ['a src/ file is shadowing its src_project/ namesake. One of the two ' ...
             'polarities of the solve_household_egm collision binds asset INDICES ' ...
             'to an asset-level variable without raising an error; refusing to ' ...
             'continue on that path order.']);
    end
end

% ---------------------------------------------------------------------
function n = listfns(d)
    n = {};
    if ~isfolder(d), return; end
    f = dir(fullfile(d, '**', '*.m'));
    n = cell(1, numel(f));
    for i = 1:numel(f), [~, n{i}] = fileparts(f(i).name); end
    n = unique(n);
end

function s = fullpath_(p)
% Normalise without the JVM: this has to work under -nojvm, which is how the
% cluster runs and how a headless parity job would run.
    s = '';
    if isempty(p), return; end
    s = char(p);
    s = strrep(s, '\', '/');
    s = regexprep(s, '/\./', '/');
    while true
        t = regexprep(s, '/[^/]+/\.\./', '/', 'once');
        if strcmp(t, s), break; end
        s = t;
    end
    s = regexprep(s, '/+$', '');
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
