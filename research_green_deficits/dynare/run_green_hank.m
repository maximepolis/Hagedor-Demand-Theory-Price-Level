% RUN_GREEN_HANK  U7 (tier 1) driver: runs green_hank.mod -- the native
% Dynare heterogeneity-framework HANK with the climate block -- under FOUR
% monetary regimes, collects the linearized sequence-space IRFs to the
% quasi-permanent deficit-financed green-investment shock, and produces the
% regime-comparison figure PFig14 plus a summary table.
%
%   WEAK         PHIPI=1.1              (weakly active rule)
%   TAYLOR       PHIPI=1.5              (default)
%   AGGRESSIVE   PHIPI=3.0
%   GREENACCOM   PHIPI=1.5, PSIG=0.03   (temporary accommodation tied to
%                the program flow, fading as it does)
%
% REQUIREMENTS: a Dynare version with the heterogeneity framework
% (heterogeneity_dimension / heterogeneity_solve) -- the version that ran
% heterogeneity/hank_one_asset_steady_state.mod successfully.
%
% HONEST SCOPE: LINEARIZED IRFs around the initial steady state. The
% nominal-rate + ex-post-Fisher block means surprise inflation revalues
% household asset positions (the paper's redistribution channel,
% linearized), but this is NOT the nonlinear DTPL price-level transition
% (appendix/HANK_TRANSITION_PLAN.md, tier 2, NOT YET IMPLEMENTED).
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_hank                        % resumes from checkpoint
%         >> FORCE_RERUN = true;  run_green_hank   % re-solve everything
%         >> SPAWN_MATLAB = true; run_green_hank   % crash-proof: one fresh
%                                                  % MATLAB process per regime
%
% OUTPUT: PFig14_hank_green_irfs.{fig,png,pdf} in ../output/figures,
%         hank_green_irfs.mat, ../output/tables/hank_irfs_summary.txt.

% keep the user-set control flags alive (a bare 'clear' would wipe them
% before they are read)
clearvars -except FORCE_RERUN SPAWN_MATLAB REGIME_ONLY RUN_ACCURACY; close all;
t0 = tic;

dyndir = fileparts(mfilename('fullpath'));
if isempty(dyndir), dyndir = pwd; end
cd(dyndir);
projdir = fileparts(dyndir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));
pg = setup_params_green();          % for figdir/tabdir only

if exist('dynare', 'file') ~= 2
    error(['Dynare not found on the MATLAB path. Install the Dynare ' ...
           'version with the heterogeneity framework and addpath ' ...
           '<dynare>/matlab, then rerun.']);
end

% TAYLORBAL repeats TAYLOR with near-balanced-budget financing (PHIB=0.75
% vs the 0.10 deficit benchmark): the TAYLOR-vs-TAYLORBAL gap isolates the
% DEFICIT-FINANCING component of the HANK response to the same program.
regimes = struct( ...
    'name',  {'WEAK', 'TAYLOR', 'AGGRESSIVE', 'GREENACCOM', 'TAYLORBAL'}, ...
    'defs',  {'-DPHIPI=1.1 -DPSIG=0.0', ...
              '-DPHIPI=1.5 -DPSIG=0.0', ...
              '-DPHIPI=3.0 -DPSIG=0.0', ...
              '-DPHIPI=1.5 -DPSIG=0.03', ...
              '-DPHIPI=1.5 -DPSIG=0.0 -DPHIB=0.75'});

% ---- crash resilience (same three layers as run_green_hank2): ----
% checkpoint-resume after every regime (re-run to continue after a crash;
% FORCE_RERUN=true re-solves everything, e.g. after a .mod edit);
% SPAWN_MATLAB=true runs each regime in a fresh "matlab -batch" child so
% a Dynare crash cannot kill this session; memory hygiene between solves.
if ~exist('FORCE_RERUN', 'var'),  FORCE_RERUN  = false; end
if ~exist('SPAWN_MATLAB', 'var'), SPAWN_MATLAB = false; end
accfile = fullfile(projdir, 'output', 'hank_green_irfs.mat');
mi = dir(fullfile(dyndir, 'green_hank.mod'));
modstamp = [mi.bytes, mi.datenum];
PREV = struct(); PREVCAL = struct();
if exist(accfile, 'file') == 2 && ~FORCE_RERUN
    try
        L = load(accfile);
        if isfield(L, 'modstamp') && isequal(L.modstamp, modstamp)
            PREV = L.RES;
            if isfield(L, 'CAL'), PREVCAL = L.CAL; end
        else
            fprintf(['  [checkpoint ignored: green_hank.mod changed since ' ...
                     'it was written -- all regimes will re-solve]\n']);
        end
    catch
    end
end

vars_keep = {'Y','pi','i','r','b','tau','gg','kg','d'};
RES = struct();
CAL = struct();
ok  = false(1, numel(regimes));

for rgm = 1:numel(regimes)
    rname = regimes(rgm).name;
    fprintf('\n===== HANK regime %s =====\n', rname);

    % checkpoint skip (sanity-gated: no restored path may be implausible)
    if isfield(PREV, rname)
        pv = PREV.(rname);
        if ~(isfield(pv,'pi') && (max(abs(pv.pi)) > 0.05 || max(abs(pv.Y)) > 0.25))
            RES.(rname) = pv;
            if isfield(PREVCAL, rname), CAL.(rname) = PREVCAL.(rname); end
            ok(rgm) = true;
            fprintf('  [restored from checkpoint -- set FORCE_RERUN=true to re-solve]\n');
            continue;
        else
            fprintf('  [checkpointed %s is implausible -- discarded, re-solving]\n', rname);
        end
    end

    try
        % memory hygiene before each heavy heterogeneity solve
        close all;
        clear functions; %#ok<CLFUNC>
        try, clear mex; catch, end %#ok<CLMEX,NOCOM>
        clear oo_ M_ options_;

        % per-regime copies: avoids stale preprocessor artifacts when one
        % .mod is re-run with different -D defines (see run_green_transitions)
        nm = sprintf('grnhk_%s', lower(rname));
        irfs = []; pn = {}; pvals = [];

        if SPAWN_MATLAB
            dynpath = fileparts(which('dynare'));
            outmat  = fullfile(dyndir, [nm '_out.mat']);
            if exist(outmat, 'file'), delete(outmat); end
            cmd = sprintf(['matlab -batch "cd(''%s''); ' ...
                'solve_hank_regime_batch(''green_hank'',''%s'',''%s'',''%s'',''%s'')"'], ...
                dyndir, nm, regimes(rgm).defs, dynpath, outmat);
            fprintf('  [spawning fresh MATLAB for %s]\n', rname);
            status = system(cmd);
            if status ~= 0 || exist(outmat, 'file') ~= 2
                warning('run_green_hank:childfail', ...
                    ['Regime %s: child MATLAB exited with status %d ' ...
                     '(a crash there does NOT kill this session).'], rname, status);
                continue;
            end
            Lc = load(outmat);
            irfs = Lc.irfs; pn = Lc.param_names; pvals = Lc.param_values;
        else
            copyfile('green_hank.mod', [nm '.mod']);
            if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
            if exist(nm, 'dir'), rmdir(nm, 's'); end
            eval(sprintf('dynare %s %s noclearall nolog', nm, regimes(rgm).defs));
            % collect IRFs defensively: the heterogeneity framework is new
            % and the output location may differ across Dynare builds
            if exist('oo_', 'var') && isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
                irfs = oo_.irfs;                       %#ok<NODEF>
            elseif exist('oo_', 'var') && isfield(oo_, 'heterogeneity') ...
                    && isfield(oo_.heterogeneity, 'irfs')
                irfs = oo_.heterogeneity.irfs;
            end
            if exist('M_', 'var')
                pn = cellstr(M_.param_names); pvals = M_.params; %#ok<NODEF>
            end
        end

        if isempty(irfs)
            warning('run_green_hank:noirfs', ...
                ['Regime %s: solved, but no IRFs found in oo_.irfs or ' ...
                 'oo_.heterogeneity.irfs. Inspect oo_ interactively ' ...
                 '(fieldnames(oo_)) and report the structure.'], rname);
            continue;
        end
        paths = struct();
        fn = fieldnames(irfs);
        for v = 1:numel(vars_keep)
            % standard Dynare IRF naming: <var>_<shock>
            hit = find(strcmpi(fn, [vars_keep{v} '_e_g']), 1);
            if isempty(hit)      % fallback: any field starting with var name
                hit = find(strncmpi(fn, [vars_keep{v} '_'], numel(vars_keep{v})+1), 1);
            end
            if ~isempty(hit), paths.(vars_keep{v}) = irfs.(fn{hit})(:).'; end
        end
        if ~isfield(paths, 'Y')
            warning('run_green_hank:names', ...
                'Regime %s: IRF fields found but none match expected names: %s', ...
                rname, strjoin(fn, ', '));
            continue;
        end
        % divergence gate (same rationale as the two-asset driver)
        if max(abs(paths.pi)) > 0.05 || max(abs(paths.Y)) > 0.25
            warning('run_green_hank:divergent', ...
                'Regime %s: DIVERGENT linearized solution -- excluded.', rname);
            continue;
        end
        RES.(rname) = paths;
        ok(rgm) = true;
        % record calibrated parameters for the validation table
        if ~isempty(pn)
            CAL.(rname) = struct( ...
                'beta', pvals(strcmp(pn,'beta')), ...
                'vphi', pvals(strcmp(pn,'vphi')), ...
                'B',    pvals(strcmp(pn,'B')));
        end
        fprintf('  [%s solved: IRF horizon %d]\n', rname, numel(paths.Y));

        % checkpoint immediately: a later crash loses nothing
        save(accfile, 'RES', 'CAL', 'regimes', 'ok', 'modstamp');
        fprintf('  [checkpoint saved]\n');
    catch ME
        warning('run_green_hank:fail', 'Regime %s failed: %s', rname, ME.message);
    end
end

if ~any(ok)
    error('No HANK regime solved; inspect the Dynare messages above.');
end

% ---- oscillation diagnostic (same protocol as run_green_hank2) ----
OSC = struct();
rnn = fieldnames(RES);
for k = 1:numel(rnn)
    s2 = RES.(rnn{k}); vn2 = fieldnames(s2);
    worst = 0; worstv = '';
    for v = 1:numel(vn2)
        sc = osc_score(s2.(vn2{v}));
        if sc > worst, worst = sc; worstv = vn2{v}; end
    end
    OSC.(rnn{k}) = struct('score', worst, 'var', worstv, 'suspect', worst > 8);
    if worst > 8
        warning('run_green_hank:oscillation', ...
            'Regime %s: oscillation score %d on %s -- numerically SUSPECT.', ...
            rnn{k}, worst, worstv);
    end
end

% ---- PFig14: regime comparison (IRFs, deviations from steady state) ----
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.85 0.55 0.10; 0.20 0.55 0.25; ...
        0.45 0.45 0.45];
panels = {'Y','output'; 'pi','inflation (net, qtr)'; 'b','real debt'; ...
          'kg','green capital'; 'd','damages'; 'r','ex-post real return'};
fh = figure('Name','PFig14: HANK green-program IRFs','Color','w', ...
            'Position',[60 60 1100 640]);
Tshow = 120;
names_ok = {regimes(ok).name};
for pp = 1:size(panels,1)
    subplot(2,3,pp); hold on; box on;
    for rgm = 1:numel(regimes)
        if ~ok(rgm), continue; end
        s = RES.(regimes(rgm).name);
        if isfield(s, panels{pp,1})
            v = s.(panels{pp,1});
            plot(0:min(Tshow,numel(v))-1, v(1:min(Tshow,numel(v))), ...
                 'LineWidth', 1.8, 'Color', cols(rgm,:));
        end
    end
    yline(0, ':', 'Color', [0.4 0.4 0.4]);
    xlabel('quarters'); title(panels{pp,2});
    if pp == 1, legend(names_ok, 'Location','best'); end
end
save_all_figs(fh, 'PFig14_hank_green_irfs', pg);
fprintf('\n  [saved] PFig14_hank_green_irfs\n');

save(fullfile(projdir, 'output', 'hank_green_irfs.mat'), 'RES', 'CAL', 'regimes', 'ok', 'OSC', 'modstamp');

sf = fullfile(pg.tabdir, 'hank_irfs_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1: HANK IRFs to a quasi-permanent green-investment shock\n');
    fprintf(fid, '(native Dynare heterogeneity framework; LINEARIZED sequence-space\n');
    fprintf(fid, 'solution; NOT the nonlinear DTPL price-level transition)\n\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s pi impact %+.5f (annualized %+.2f%%), ' ...
            'Y impact %+.5f, debt(40q) %+.4f, kg(40q) %+.4f, d(40q) %+.6f\n'], ...
            regimes(rgm).name, s.pi(1), 400*s.pi(1), s.Y(1), ...
            s.b(min(40,end)), s.kg(min(40,end)), s.d(min(40,end)));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ---- validation table (audit requirement: hank_tier1_validation.txt) ----
vf = fullfile(pg.tabdir, 'hank_tier1_validation.txt');
fid = fopen(vf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1 HANK VALIDATION\n');
    fprintf(fid, 'Scope label: TIER-1 LINEARIZED HANK IRF (sequence-space, Dynare heterogeneity\n');
    fprintf(fid, 'framework, truncation horizon 300). Contains the Fisher revaluation channel\n');
    fprintf(fid, '(nominal rate + ex-post real return on nominal assets) but NOT nonlinear\n');
    fprintf(fid, 'DTPL price-level determination -- a bridge to the tier-2 transition, not it.\n\n');
    fprintf(fid, 'Income process: rho_e=0.966, sig_e=0.5, 3 states (DYNARE-EXAMPLE calibration,\n');
    fprintf(fid, 'NOT the MATLAB package''s 7-state process -- alignment is future work).\n');
    fprintf(fid, 'Debt: B=3.96 gives debt/annual-GDP = 1.099 at the damaged steady state (U3 target ~1.10).\n');
    fprintf(fid, 'Steady-state market-clearing residuals: see the Dynare log of each regime\n');
    fprintf(fid, '(heterogeneity_compute_steady_state prints them; tol 1e-4).\n\n');
    fprintf(fid, '%-11s %-8s %-8s %-10s %-10s %-11s %-11s %-11s %-11s\n', ...
        'regime', 'solved', 'horizon', 'beta*', 'B', ...
        'pi impact', 'Y impact', 'b(40q)', 'd(40q)');
    for rgm = 1:numel(regimes)
        if ~ok(rgm)
            fprintf(fid, '%-11s %-8s\n', regimes(rgm).name, 'NO');
            continue;
        end
        s = RES.(regimes(rgm).name);
        bstar = NaN; Bv = NaN;
        if isfield(CAL, regimes(rgm).name)
            bstar = CAL.(regimes(rgm).name).beta;
            Bv    = CAL.(regimes(rgm).name).B;
        end
        fprintf(fid, '%-11s %-8s %-8d %-10.6f %-10.3f %+-11.5f %+-11.5f %+-11.5f %+-11.6f\n', ...
            regimes(rgm).name, 'yes', numel(s.Y), bstar, Bv, ...
            s.pi(1), s.Y(1), s.b(min(40,end)), s.d(min(40,end)));
    end
    fprintf(fid, '\nIRFs are deviations from steady state to a ONE-STD e_g shock (0.009,\n');
    fprintf(fid, '~1%% of steady-state output); persistence rho_g set by -DRHOG (0.995 =\n');
    fprintf(fid, 'verified-run default; 0.98 recommended for the accuracy re-verification).\n');
    fprintf(fid, '\n--- OSCILLATION DIAGNOSTIC ---\n');
    onn = fieldnames(OSC);
    for k = 1:numel(onn)
        if OSC.(onn{k}).suspect, tag = 'SUSPECT (not reportable)'; else, tag = 'ok'; end
        fprintf(fid, 'oscillation %-11s score %2d on %-5s -> %s\n', onn{k}, ...
            OSC.(onn{k}).score, OSC.(onn{k}).var, tag);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', vf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));


% -------------------------------------------------------------------------
function sc = osc_score(v)
% sign changes in the first differences of an IRF over quarters 20..120
    v = v(:).';
    T = min(120, numel(v));
    if T < 25, sc = 0; return; end
    dv = diff(v(20:T));
    scale = max(abs(v(1:T)));
    dv(abs(dv) < 1e-6 * max(scale, 1e-12)) = 0;
    ss = sign(dv); ss = ss(ss ~= 0);
    sc = sum(abs(diff(ss)) > 0);
end
