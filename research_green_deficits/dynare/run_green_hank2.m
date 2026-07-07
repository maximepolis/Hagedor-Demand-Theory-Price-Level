% RUN_GREEN_HANK2  U7 tier-1b driver: the TWO-ASSET green HANK
% (green_hank2.mod -- liquid nominal bonds vs illiquid equity/capital,
% sticky wages + prices, convex portfolio-adjustment costs, endogenous
% government debt, climate block) under FOUR regimes, collecting the
% linearized sequence-space IRFs to the quasi-permanent green-investment
% shock. Produces PFig17 plus summary and validation tables.
%
%   WEAK        PHIPI=1.1
%   TAYLOR      PHIPI=1.5 (default)               PHIB=0.10 (deficit)
%   GREENACCOM  PHIPI=1.5, PSIG=0.03
%   TAYLORBAL   PHIPI=1.5, PHIB=0.75              (balanced comparator;
%               the first run's divergence was caused by the missing
%               dividend identity, NOT by phi_b -- audit-confirmed and
%               fixed in green_hank2.mod, so the documented 0.75 returns)
%
% WHY THIS TIER: households now split wealth between LIQUID NOMINAL BONDS
% and illiquid equity, so the program's effect on liquid-bond demand -- the
% paper's B/P margin -- is observable (bg, rb, SUM(b) diagnostics) and MPC
% heterogeneity is realistic (wealthy hand-to-mouth). Closure follows the
% reference DYNAMICS example: dividend identity + single total-wealth
% clearing + constant premium omega (an endogenous convenience yield is
% boundary-singular in truncated sequence space -- see green_hank2.mod).
%
% REQUIREMENTS: the Dynare heterogeneity build that ran
% heterogeneity/hank_two_assets_steady_state.mod. EXPECT SLOWER SOLVES
% than the one-asset tier (3 calibrated parameters, 3D household state).
%
% HONEST SCOPE: LINEARIZED IRFs; NOT the nonlinear DTPL transition.
% Grid defaults ne=3, nb=15, na=30 (raised from the example's 10x20):
% magnitudes indicative until the accuracy protocol passes.
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_hank2                        % DEFAULT: each regime in
%                                                   % its own MATLAB process
%                                                   % (crash-proof), resuming
%                                                   % from checkpoint
%         >> FORCE_RERUN  = true;  run_green_hank2  % re-solve everything
%         >> SPAWN_MATLAB = false; run_green_hank2  % in-session solves
%         >> RUN_ACCURACY = true;  run_green_hank2  % force refinement pass
%
% OUTPUT: PFig17_hank2_green_irfs.{fig,png,pdf}, hank2_green_irfs.mat,
%         ../output/tables/hank2_irfs_summary.txt,
%         ../output/tables/hank2_validation.txt.

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
    error('Dynare not found on the MATLAB path.');
end

% ---- VERSION TRIPWIRE: refuse to run an outdated model ----
% The current green_hank2.mod contains the dividend identity AND the
% reference dynamics closure (single total-wealth clearing); older
% versions reproduce the explosive TAYLORBAL solve or the NaN
% (boundary-singular endogenous-omega) solutions. Fail loudly instead.
modtxt = fileread(fullfile(dyndir, 'green_hank2.mod'));
if ~contains(modtxt, "name='Dividends'") || ...
   ~contains(modtxt, 'Asset market clearing (total wealth)')
    error(['green_hank2.mod is an OUTDATED version (missing the dividend ' ...
           'identity and/or the reference dynamics closure). Re-download ' ...
           'the branch ZIP, replace the WHOLE research_green_deficits ' ...
           'folder, and re-run.']);
end
% delete stale summary/validation files so a failed run can never leave
% previous results lying around to be mistaken for current ones
for stale = {'hank2_irfs_summary.txt', 'hank2_validation.txt'}
    f = fullfile(pg.tabdir, stale{1});
    if exist(f, 'file') == 2, delete(f); end
end
% clean stale generated per-regime copies from older versions so a manual
% "dynare grn2_xxx" can never run an outdated model
old = dir(fullfile(dyndir, 'grn2_*.mod'));
for k = 1:numel(old), delete(fullfile(dyndir, old(k).name)); end

regimes = struct( ...
    'name',  {'WEAK', 'TAYLOR', 'GREENACCOM', 'TAYLORBAL'}, ...
    'defs',  {'-DPHIPI=1.1', ...
              '-DPHIPI=1.5', ...
              '-DPHIPI=1.5 -DPSIG=0.03', ...
              '-DPHIPI=1.5 -DPHIB=0.75'});

% ==================== CRASH RESILIENCE (three layers) ====================
% The Dynare 8-unstable heterogeneity framework has HARD-CRASHED MATLAB
% when several heavy solves run in one session. A hard process crash
% cannot be caught by try/catch, so the driver is engineered around it:
%
%  1. CHECKPOINT-RESUME (default, automatic): results are saved to
%     ../output/hank2_green_irfs.mat after EVERY regime. Already-solved
%     regimes are SKIPPED on the next run, so after a crash you simply
%     re-run run_green_hank2 and it continues where it stopped. Set
%     FORCE_RERUN = true to ignore the checkpoint and solve everything
%     fresh (do this after editing the .mod).
%  2. PROCESS ISOLATION (THE DEFAULT for this tier): each regime runs in
%     its own fresh MATLAB child process, invoked via the running
%     installation's exact executable (matlabroot -- no PATH setup
%     needed). If Dynare dies, only the child dies; this session records
%     the failure and continues. SPAWN_MATLAB = false opts out.
%  3. MEMORY HYGIENE between in-session solves (close figures, clear
%     generated functions/MEX, drop the previous solve's Dynare globals).
%
% REGIME_ONLY = '<name>' still restricts to a single regime if wanted.
if exist('REGIME_ONLY', 'var') && ~isempty(REGIME_ONLY)
    keep = strcmpi({regimes.name}, REGIME_ONLY);
    if any(keep), regimes = regimes(keep); end
    fprintf('*** single-regime mode: %s ***\n', regimes(1).name);
end
if ~exist('FORCE_RERUN', 'var'),  FORCE_RERUN  = false; end
% SPAWN IS THE DEFAULT for this tier: the Dynare 8-unstable two-asset
% heterogeneity solve has repeatedly hard-crashed MATLAB in-session on the
% user machine. Each regime therefore runs in its own disposable MATLAB
% process by default; a crash there can never kill this session. Set
% SPAWN_MATLAB = false to force in-session solves (not recommended).
if ~exist('SPAWN_MATLAB', 'var'), SPAWN_MATLAB = true; end
% resolve the EXACT executable of the running MATLAB (no PATH setup needed)
matlab_exe = fullfile(matlabroot, 'bin', 'matlab');
if ispc, matlab_exe = [matlab_exe '.exe']; end
if SPAWN_MATLAB && exist(matlab_exe, 'file') ~= 2
    warning('run_green_hank2:nomatlabexe', ...
        'Could not locate %s -- falling back to in-session solves.', matlab_exe);
    SPAWN_MATLAB = false;
end
accfile = fullfile(projdir, 'output', 'hank2_green_irfs.mat');
% model fingerprint: a checkpoint written under a DIFFERENT green_hank2.mod
% must never be restored (it would resurrect pre-fix runs)
mi = dir(fullfile(dyndir, 'green_hank2.mod'));
modstamp = [mi.bytes, mi.datenum];
PREV = struct(); PREVCAL = struct();
if exist(accfile, 'file') == 2 && ~FORCE_RERUN
    try
        L = load(accfile);
        if isfield(L, 'modstamp') && isequal(L.modstamp, modstamp)
            PREV = L.RES;
            if isfield(L, 'CAL'), PREVCAL = L.CAL; end
        else
            fprintf(['  [checkpoint ignored: green_hank2.mod changed since ' ...
                     'it was written -- all regimes will re-solve]\n']);
        end
    catch
    end
end

vars_keep = {'Y','pi','i','r','rb','ra','bg','tax','gg','kg','d','p','K','I','w','N'};
RES = struct();
CAL = struct();
DIVERGENT = struct();
ok  = false(1, numel(regimes));
restored = false(1, numel(regimes));
nfail_consec = 0;   % fail-fast: 2 consecutive solver failures => abort run

for rgm = 1:numel(regimes)
    rname = regimes(rgm).name;
    % FAIL-FAST GATE: two consecutive regimes failing at the solver level
    % (singular Jacobian, child crash, degenerate solution) means the tier
    % is systematically broken on this Dynare build -- do not burn ~10
    % minutes per remaining regime discovering the same thing.
    if nfail_consec >= 2
        warning('run_green_hank2:abort', ...
            ['%d consecutive solver-level failures -- aborting the remaining ' ...
             'regimes. The two-asset tier is EXPERIMENTAL and the paper does ' ...
             'not depend on it; see hank2_protocol_verdict.txt.'], nfail_consec);
        break;
    end
    fprintf('\n===== HANK2 regime %s =====\n', rname);

    % ---- layer 1: checkpoint skip (validity gates apply to restores) --
    if isfield(PREV, rname)
        pv = PREV.(rname);
        if ~all(structfun(@(v) all(isfinite(v)), pv)) || ...
           (isfield(pv,'pi') && (max(abs(pv.pi)) > 0.05 || max(abs(pv.Y)) > 0.25 ...
                || (isfield(pv,'bg') && max(abs(pv.bg)) > 5)))
            fprintf('  [checkpointed %s is DIVERGENT -- discarded, will re-solve]\n', rname);
            DIVERGENT.(rname) = true;
        else
            RES.(rname) = pv;
            if isfield(PREVCAL, rname), CAL.(rname) = PREVCAL.(rname); end
            ok(rgm) = true; restored(rgm) = true;
            fprintf('  [restored from checkpoint -- set FORCE_RERUN=true to re-solve]\n');
            continue;
        end
    end

    try
        % ---- layer 3: memory hygiene before each heavy solve ----
        close all;
        clear functions; %#ok<CLFUNC>
        try, clear mex; catch, end %#ok<CLMEX,NOCOM>
        clear oo_ M_ options_;

        nm = sprintf('grn2_%s', lower(rname));
        irfs = []; pn = {}; pvals = [];

        if SPAWN_MATLAB
            % ---- layer 2: one fresh MATLAB process per regime ----
            dynpath = fileparts(which('dynare'));
            outmat  = fullfile(dyndir, [nm '_out.mat']);
            if exist(outmat, 'file'), delete(outmat); end
            cmd = sprintf(['"%s" -batch "cd(''%s''); ' ...
                'solve_hank_regime_batch(''green_hank2'',''%s'',''%s'',''%s'',''%s'')"'], ...
                matlab_exe, dyndir, nm, regimes(rgm).defs, dynpath, outmat);
            fprintf('  [spawning fresh MATLAB for %s]\n', rname);
            status = system(cmd);
            if status ~= 0 || exist(outmat, 'file') ~= 2
                warning('run_green_hank2:childfail', ...
                    ['Regime %s: child MATLAB exited with status %d ' ...
                     '(a crash there does NOT kill this session).'], rname, status);
                nfail_consec = nfail_consec + 1;
                continue;
            end
            Lc = load(outmat);
            irfs = Lc.irfs; pn = Lc.param_names; pvals = Lc.param_values;
        else
            copyfile('green_hank2.mod', [nm '.mod']);
            if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
            if exist(nm, 'dir'), rmdir(nm, 's'); end
            eval(sprintf('dynare %s %s noclearall nolog', nm, regimes(rgm).defs));
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
            warning('run_green_hank2:noirfs', ...
                'Regime %s: solved but no IRFs found; inspect fieldnames(oo_).', rname);
            nfail_consec = nfail_consec + 1;
            continue;
        end
        paths = struct();
        fn = fieldnames(irfs);
        for v = 1:numel(vars_keep)
            hit = find(strcmpi(fn, [vars_keep{v} '_e_g']), 1);
            if isempty(hit)
                hit = find(strncmpi(fn, [vars_keep{v} '_'], numel(vars_keep{v})+1), 1);
            end
            if ~isempty(hit), paths.(vars_keep{v}) = irfs.(fn{hit})(:).'; end
        end
        if ~isfield(paths, 'Y')
            warning('run_green_hank2:names', ...
                'Regime %s: IRF fields do not match expected names: %s', ...
                rname, strjoin(fn, ', '));
            continue;
        end
        % VALIDITY GATE 1 (NaN): a NaN/Inf path means the linearized
        % solution is DEGENERATE. NOTE: 'NaN > x' is FALSE in MATLAB, so
        % the divergence gate alone lets NaN through -- which is exactly
        % how a NaN run got checkpointed and summarized once. Explicit
        % finiteness check first.
        if ~all(structfun(@(v) all(isfinite(v)), paths))
            warning('run_green_hank2:nanpath', ...
                ['Regime %s: linearized solution is DEGENERATE (NaN/Inf ' ...
                 'IRFs) -- excluded from all outputs, NOT checkpointed.'], ...
                rname);
            DIVERGENT.(rname) = true;
            nfail_consec = nfail_consec + 1;
            continue;
        end
        % VALIDITY GATE 2 (divergence): a finite IRF to a 1%-of-output
        % shock that moves inflation by >5% quarterly or output by >25%
        % is not a solution, it is a pathology. Excluded outright.
        if max(abs(paths.pi)) > 0.05 || max(abs(paths.Y)) > 0.25 ...
                || (isfield(paths,'bg') && max(abs(paths.bg)) > 5)
            warning('run_green_hank2:divergent', ...
                ['Regime %s: DIVERGENT linearized solution (|pi|max=%.3g, ' ...
                 '|Y|max=%.3g) -- excluded from all outputs.'], ...
                rname, max(abs(paths.pi)), max(abs(paths.Y)));
            DIVERGENT.(rname) = true;
            nfail_consec = nfail_consec + 1;
            continue;
        end
        RES.(rname) = paths;
        ok(rgm) = true;
        nfail_consec = 0;
        if isfield(DIVERGENT, rname), DIVERGENT = rmfield(DIVERGENT, rname); end
        if ~isempty(pn)
            CAL.(rname) = struct( ...
                'beta_ss', pvals(strcmp(pn,'beta_ss')), ...
                'vphi',    pvals(strcmp(pn,'vphi')), ...
                'chi1',    pvals(strcmp(pn,'chi1')));   % chi1 FIXED (6.416)
        end
        fprintf('  [%s solved: IRF horizon %d]\n', rname, numel(paths.Y));

        % ---- layer 1: checkpoint immediately (a later crash loses nothing)
        save(accfile, 'RES', 'CAL', 'regimes', 'ok', 'modstamp');
        fprintf('  [checkpoint saved]\n');
    catch ME
        warning('run_green_hank2:fail', 'Regime %s failed: %s', rname, ME.message);
        nfail_consec = nfail_consec + 1;
    end
end

if ~any(ok) && isempty(fieldnames(RES))
    % write a persistent verdict BEFORE erroring, so the protocol attempt
    % is on the record even though the run produced nothing reportable
    vf = fullfile(pg.tabdir, 'hank2_protocol_verdict.txt');
    fid = fopen(vf, 'w');
    if fid > 0
        dynver = 'unknown';
        try, dynver = dynare_version(); catch, end
        fprintf(fid, 'TIER-1b (two-asset HANK) ACCURACY PROTOCOL -- VERDICT\n');
        fprintf(fid, 'Attempted: %s;  Dynare: %s\n', ...
            datestr(now, 'yyyy-mm-dd HH:MM'), dynver);
        fprintf(fid, ['Outcome: NO regime produced a valid solution ' ...
            '(solver-level failures:\nsingular sequence-space Jacobian / ' ...
            'hard child-process crash in the Dynare\nheterogeneity solver). ' ...
            'Tier remains EXPERIMENTAL and NOT REPORTABLE.\n' ...
            'The paper does not depend on this tier (its scope statement ' ...
            'says so).\n']);
        fclose(fid);
        fprintf('  [saved] %s\n', vf);
    end
    error(['No HANK2 regime solved; verdict recorded in ' ...
           'hank2_protocol_verdict.txt. This tier is EXPERIMENTAL -- ' ...
           'the paper does not depend on it.']);
end

% ---- OSCILLATION DIAGNOSTIC (accuracy protocol, step 1) ----
% A well-resolved IRF to a monotone quasi-permanent shock should have few
% sign changes in its first differences beyond the impact quarters. Count
% them per variable over quarters 20..120; an oscillation score > OSC_TOL
% flags the path as numerically suspect -- suspect regimes are still
% SAVED (for diagnosis) but marked NOT REPORTABLE in the validation file.
OSC_TOL = 8;
OSC = struct();
rn = fieldnames(RES);
for k = 1:numel(rn)
    s = RES.(rn{k});
    vn = fieldnames(s);
    worst = 0; worstv = '';
    for v = 1:numel(vn)
        sc = osc_score(s.(vn{v}));
        if sc > worst, worst = sc; worstv = vn{v}; end
    end
    OSC.(rn{k}) = struct('score', worst, 'var', worstv, ...
                         'suspect', worst > OSC_TOL);
    if worst > OSC_TOL
        warning('run_green_hank2:oscillation', ...
            ['Regime %s: oscillation score %d on %s (tol %d) -- path is ' ...
             'numerically SUSPECT; not reportable.'], ...
            rn{k}, worst, worstv, OSC_TOL);
    else
        fprintf('  [%s oscillation check passed: score %d (%s)]\n', ...
            rn{k}, worst, worstv);
    end
end

% ---- ACCURACY REFINEMENT PASS (accuracy protocol, step 2) ----
% Re-solve the TAYLOR regime with a LONGER truncation horizon (600 vs 400)
% and FINER asset grids (nb 15->25, na 30->50), then compare IRFs. If the
% baseline solution is accurate, the two should agree closely; a large gap
% means the baseline grids/horizon are driving the results.
%
% CRASH NOTE: this is the HEAVIEST solve in the package; stacking it as a
% fifth in-session solve is the most likely cause of the hard MATLAB
% crash. It therefore runs by default ONLY when every main regime came
% from the checkpoint (i.e., in a fresh session with full memory
% headroom); in a session that just solved regimes, it defers with a
% message. Force it with RUN_ACCURACY = true; with SPAWN_MATLAB = true it
% runs out of process and cannot crash this session at all.
run_acc = isfield(RES, 'TAYLOR') && all(restored(ok)) && ...
    ~(exist('REGIME_ONLY','var') && ~isempty(REGIME_ONLY));
if exist('RUN_ACCURACY', 'var') && RUN_ACCURACY, run_acc = isfield(RES,'TAYLOR'); end
ACC = struct('ran', false);
if isfield(RES,'TAYLOR') && ~run_acc
    fprintf(['\n  [accuracy pass DEFERRED: re-run run_green_hank2 in a fresh\n' ...
             '   MATLAB session (regimes will restore from checkpoint and the\n' ...
             '   refinement solve gets full memory), or set RUN_ACCURACY=true,\n' ...
             '   or SPAWN_MATLAB=true for out-of-process execution]\n']);
end
if run_acc
    fprintf('\n===== HANK2 accuracy pass (TAYLOR, refined) =====\n');
    try
        close all;
        clear functions; %#ok<CLFUNC>
        try, clear mex; catch, end %#ok<CLMEX,NOCOM>
        clear oo_ M_ options_;
        nm = 'grn2_taylor_acc';
        % lighter refinement (500/20/40, was 600/25/50): the heaviest
        % solve repeatedly hard-crashed MATLAB in-session; still a genuine
        % refinement over the 400/15/30 baseline
        accdefs = '-DPHIPI=1.5 -DTHORIZON=500 -DNB=20 -DNA=40';
        if ~SPAWN_MATLAB
            fprintf(['  [note: for the accuracy pass, SPAWN_MATLAB=true is ' ...
                     'strongly recommended -- it cannot crash this session]\n']);
        end
        irfs = [];
        if SPAWN_MATLAB
            dynpath = fileparts(which('dynare'));
            outmat  = fullfile(dyndir, [nm '_out.mat']);
            if exist(outmat, 'file'), delete(outmat); end
            cmd = sprintf(['"%s" -batch "cd(''%s''); ' ...
                'solve_hank_regime_batch(''green_hank2'',''%s'',''%s'',''%s'',''%s'')"'], ...
                matlab_exe, dyndir, nm, accdefs, dynpath, outmat);
            status = system(cmd);
            if status == 0 && exist(outmat, 'file') == 2
                Lc = load(outmat); irfs = Lc.irfs;
            end
        else
            copyfile('green_hank2.mod', [nm '.mod']);
            if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
            if exist(nm, 'dir'), rmdir(nm, 's'); end
            eval(sprintf('dynare %s %s noclearall nolog', nm, accdefs));
            if exist('oo_', 'var') && isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
                irfs = oo_.irfs;
            elseif exist('oo_', 'var') && isfield(oo_, 'heterogeneity') ...
                    && isfield(oo_.heterogeneity, 'irfs')
                irfs = oo_.heterogeneity.irfs;
            end
        end
        if ~isempty(irfs)
            fnn = fieldnames(irfs);
            base = RES.TAYLOR;
            ACC.ran = true; ACC.maxdev = 0; ACC.report = {};
            for v = 1:numel(vars_keep)
                if ~isfield(base, vars_keep{v}), continue; end
                hit = find(strcmpi(fnn, [vars_keep{v} '_e_g']), 1);
                if isempty(hit), continue; end
                fine = irfs.(fnn{hit})(:).';
                T = min(120, min(numel(fine), numel(base.(vars_keep{v}))));
                bb = base.(vars_keep{v})(1:T); ff = fine(1:T);
                scale = max(max(abs(bb)), 1e-9);
                dev = max(abs(bb - ff)) / scale;
                ACC.report{end+1} = sprintf('%-6s rel.dev %.3f', vars_keep{v}, dev);
                ACC.maxdev = max(ACC.maxdev, dev);
            end
            ACC.pass = ACC.maxdev < 0.10;   % 10% relative agreement over 120q
            fprintf('  [accuracy pass: max relative deviation %.3f -> %s]\n', ...
                ACC.maxdev, ternary_str(ACC.pass, 'PASS', 'FAIL'));
        end
    catch ME
        warning('run_green_hank2:acc', 'Accuracy pass failed: %s', ME.message);
    end
end

% ---- PFig17 ----
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.20 0.55 0.25; 0.45 0.45 0.45];
panels = {'Y','output'; 'pi','inflation (net, qtr)'; 'bg','government debt'; ...
          'rb','liquid (bond) return'; 'kg','green capital'; 'p','equity price'};
fh = figure('Name','PFig17: two-asset HANK green-program IRFs','Color','w', ...
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
save_all_figs(fh, 'PFig17_hank2_green_irfs', pg);
fprintf('\n  [saved] PFig17_hank2_green_irfs\n');

save(fullfile(projdir, 'output', 'hank2_green_irfs.mat'), 'RES', 'CAL', 'regimes', 'ok', 'OSC', 'ACC', 'modstamp');

% ---- summary ----
sf = fullfile(pg.tabdir, 'hank2_irfs_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1b: TWO-ASSET HANK IRFs to a quasi-permanent green shock\n');
    fprintf(fid, '(liquid bonds vs illiquid equity; LINEARIZED; NOT the DTPL transition)\n\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s pi impact %+.5f (ann %+.2f%%), Y impact %+.5f, ' ...
            'rb impact %+.5f, bg(40q) %+.4f, kg(40q) %+.4f, d(40q) %+.6f, p impact %+.4f\n'], ...
            regimes(rgm).name, s.pi(1), 400*s.pi(1), s.Y(1), s.rb(1), ...
            s.bg(min(40,end)), s.kg(min(40,end)), s.d(min(40,end)), s.p(1));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ---- validation ----
vf = fullfile(pg.tabdir, 'hank2_validation.txt');
fid = fopen(vf, 'w');
if fid > 0
    fprintf(fid, 'U7 TIER-1b TWO-ASSET HANK VALIDATION\n');
    fprintf(fid, 'Scope: TIER-1 LINEARIZED HANK IRF (two-asset; sequence-space; horizon 400 default).\n');
    fprintf(fid, 'Liquid nominal bonds vs illiquid equity with convex adjustment costs;\n');
    fprintf(fid, 'endogenous government debt; REFERENCE DYNAMICS CLOSURE (dividend\n');
    fprintf(fid, 'identity + single total-wealth clearing + constant premium omega --\n');
    fprintf(fid, 'an endogenous convenience yield is boundary-singular in truncated\n');
    fprintf(fid, 'sequence space and remains PROPOSED). Fisher equation present.\n');
    fprintf(fid, 'NOT nonlinear DTPL price-level determination.\n');
    fprintf(fid, 'Grids: ne=3 (rho_e=0.966, sig_e=0.92, example calibration), nb=15, na=30\n');
    fprintf(fid, '-- COARSE; magnitudes indicative. Steady-state residuals: Dynare log.\n\n');
    fprintf(fid, '%-11s %-8s %-8s %-10s %-9s %-9s %-11s %-11s %-11s\n', ...
        'regime', 'solved', 'horizon', 'beta_ss*', 'vphi*', 'chi1*', ...
        'pi impact', 'Y impact', 'bg(40q)');   % chi1 column = fixed value
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s %-8s\n', regimes(rgm).name, 'NO'); continue; end
        s = RES.(regimes(rgm).name);
        cb = struct('beta_ss',NaN,'vphi',NaN,'chi1',NaN);
        if isfield(CAL, regimes(rgm).name), cb = CAL.(regimes(rgm).name); end
        fprintf(fid, '%-11s %-8s %-8d %-10.6f %-9.4f %-9.4f %+-11.5f %+-11.5f %+-11.5f\n', ...
            regimes(rgm).name, 'yes', numel(s.Y), cb.beta_ss, cb.vphi, cb.chi1, ...
            s.pi(1), s.Y(1), s.bg(min(40,end)));
    end
    fprintf(fid, '\nIRFs: one-std e_g shock (0.01 ~ 1%% of output), rho_g=0.98\n');
    fprintf(fid, '(reduced from 0.995 after the first run: persistence too close to the\n');
    fprintf(fid, 'truncation horizon produces reflection/oscillation artifacts).\n');
    fprintf(fid, '\n--- ACCURACY PROTOCOL ---\n');
    rn = fieldnames(OSC);
    for k = 1:numel(rn)
        fprintf(fid, 'oscillation %-11s score %2d on %-5s -> %s\n', rn{k}, ...
            OSC.(rn{k}).score, OSC.(rn{k}).var, ...
            ternary_str(OSC.(rn{k}).suspect, 'SUSPECT (not reportable)', 'ok'));
    end
    dn = fieldnames(DIVERGENT);
    for k = 1:numel(dn)
        fprintf(fid, 'DIVERGENT   %-11s excluded from all outputs (pathological linearized solution)\n', dn{k});
    end
    if ACC.ran
        fprintf(fid, 'refinement (TAYLOR, THORIZON 500, nb 20, na 40): max rel. dev %.3f -> %s\n', ...
            ACC.maxdev, ternary_str(ACC.pass, 'PASS', 'FAIL (baseline grids/horizon drive results)'));
        for k = 1:numel(ACC.report), fprintf(fid, '  %s\n', ACC.report{k}); end
    else
        fprintf(fid, 'refinement pass: NOT RUN this session\n');
    end
    fprintf(fid, ['\nREPORTING RULE: no tier-1b number enters the paper unless the\n' ...
        'oscillation check and the refinement pass BOTH pass.\n']);
    fclose(fid);
    fprintf('  [saved] %s\n', vf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));

% -------------------------------------------------------------------------
function sc = osc_score(v)
% number of sign changes in the first differences of an IRF over quarters
% 20..120 (ignoring numerically negligible wiggles relative to path scale)
    v = v(:).';
    T = min(120, numel(v));
    if T < 25, sc = 0; return; end
    dv = diff(v(20:T));
    scale = max(abs(v(1:T)));
    dv(abs(dv) < 1e-6 * max(scale, 1e-12)) = 0;
    ss = sign(dv); ss = ss(ss ~= 0);
    sc = sum(abs(diff(ss)) > 0);
end

function s = ternary_str(cond, a, b)
    if cond, s = a; else, s = b; end
end
