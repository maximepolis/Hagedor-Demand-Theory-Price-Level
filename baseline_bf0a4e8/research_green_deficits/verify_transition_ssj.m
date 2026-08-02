% VERIFY_TRANSITION_SSJ  Cross-validate the nonlinear HANK-DTPL announcement
% transition two independent ways and report a sequence-space determinacy
% diagnostic.
%
%   (1) ANDERSON  solve_hank_dtpl_transition  -- the paper's headline solver
%       (Anderson-accelerated fixed point on the log price path).
%   (2) SSJ-NEWTON  solve_transition_ssj      -- an independent Newton solve in
%       sequence space using the GE Jacobian (Auclert-Bardoczy-Rognlie-Straub
%       2021), with a second, independent residual implementation.
%
% Two solvers built on two residual codes converging to the SAME price path is
% a strong correctness gate for the headline announcement result (77% of the
% green disinflation and the bondholder windfall in year one). The SSJ solver
% additionally returns a SEQUENCE-SPACE DETERMINACY diagnostic -- the smallest
% singular value / condition number of the GE Jacobian -- a dynamic complement
% to the steady-state eps_S<-1 elasticity test.
%
% USAGE   >> verify_transition_ssj
%         >> FAST = true; verify_transition_ssj      % short horizon / coarse grid
%
% OUTPUT  output/transition_ssj_results.mat,
%         output/tables/transition_ssj.txt, PFig_transition_ssj.*
%
% STATUS: verification driver. Drawn from the Dynare masterclass
% sequence-space-Jacobian toolkit (see HANK_METHODS.md). No number is asserted
% in the paper until this driver has run and the two solvers agree.

clearvars -except FAST NA; close all; clc;
rng(20260715, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if exist('NA','var') && ~isempty(NA)
    pg.na = NA;
elseif FAST
    pg.na = pg.fast.na;
end
if pg.na ~= numel(pg.aGrid)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'transition_ssj_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' TRANSITION CROSS-CHECK: Anderson vs sequence-space Newton, na=%d\n', pg.na);
fprintf('==============================================================\n');

% reuse the calibrated medium column
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), pg.beta = L.RCAL.beta_star; end
    if isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal'),   pg.Gg_nom = L.RCAL.Gg_cal; end
end
pg.climate_version = 1;
pg.D0 = 0.06;

T = 80; if FAST, T = 40; end
opts = struct('T', T, 'regime', 'nominal', 'financing', 'lumpsum', ...
              'verbose', true, 'tol', 2e-3);

% ---- (1) Anderson ----
fprintf('\n--- (1) Anderson fixed point ---\n');
TA = solve_hank_dtpl_transition(pg, opts);
fprintf('  %s\n', TA.msg);

% ---- (2) SSJ Newton (independent residual + GE Jacobian) ----
fprintf('\n--- (2) sequence-space Newton ---\n');
optsN = opts;
% The transition residual runs a DISCRETE-CHOICE (grid) backward pass, so it
% is piecewise-constant at fine scales: fd_step must average across policy
% flips (the old 1e-4 gave a noise Jacobian and the Newton stalled at the
% bridge). freeze_jac reuses the first good Jacobian for cheap chord steps
% (rebuilt automatically on any stall), so a larger iteration cap is
% affordable. newton_tol is 2e-3 -- the na=500 grid's residual floor, the
% same gate the Anderson solver meets -- not an unreachable 5e-4.
optsN.newton_maxit = 30; optsN.newton_tol = 2e-3;
optsN.fd_step = 5e-3;    optsN.freeze_jac = true;
TS = solve_transition_ssj(pg, optsN);
fprintf('  %s\n', TS.msg);

% ---- cross-check ----
agree = NaN; agree_pi = NaN;
if isfield(TA,'phat') && isfield(TS,'phat') && numel(TA.phat)==numel(TS.phat)
    agree    = max(abs(TA.phat - TS.phat) ./ TA.phat);
    agree_pi = max(abs(TA.pi_path - TS.pi_path));
end
fprintf('\n================ CROSS-CHECK ================\n');
fprintf(' max relative price-path gap   |dphat|/phat = %.3e\n', agree);
fprintf(' max inflation-path gap        |dpi|        = %.3e\n', agree_pi);
fprintf(' Anderson reportable=%d;  SSJ reportable=%d\n', ...
        logical(getf(TA,'reportable',false)), logical(getf(TS,'reportable',false)));
fprintf(' sequence-space determinacy:  sigma_min(J)=%.3e  cond(J)=%.2e  determinate=%d\n', ...
        getf(TS,'sigma_min',NaN), getf(TS,'cond_J',NaN), logical(getf(TS,'determinate',false)));
pass = isfinite(agree) && agree < 1e-2;
fprintf(' => %s: the two independent solvers %s.\n', ternary(pass,'PASS','CHECK'), ...
        ternary(pass,'agree on the announcement path','disagree -- inspect'));
fprintf('=============================================\n');

save(fullfile(projdir,'output','transition_ssj_results.mat'), 'TA','TS','agree','agree_pi','pass');

% ---- table ----
sf = fullfile(pg.tabdir, 'transition_ssj.txt');
fid = fopen(sf,'w');
if fid > 0
    fprintf(fid, 'TRANSITION CROSS-CHECK (Anderson vs sequence-space Newton). na=%d, T=%d\n\n', pg.na, T);
    fprintf(fid, 'Announcement-year (t=1) objects:\n');
    if isfield(TA,'pi_path')
        fprintf(fid, '  Anderson: pi_1 = %+.4f, P_1/P_0 = %.4f\n', TA.pi_path(1), TA.phat(1)/TA.P0);
    end
    if isfield(TS,'pi_path')
        fprintf(fid, '  SSJ     : pi_1 = %+.4f, P_1/P_0 = %.4f\n', TS.pi_path(1), TS.phat(1)/TS.P0);
    end
    fprintf(fid, '\nCross-check:\n');
    fprintf(fid, '  max |dphat|/phat = %.3e\n', agree);
    fprintf(fid, '  max |dpi|        = %.3e\n', agree_pi);
    fprintf(fid, '\nSequence-space determinacy (SSJ GE Jacobian at the solution):\n');
    fprintf(fid, '  sigma_min(J) = %.3e\n', getf(TS,'sigma_min',NaN));
    fprintf(fid, '  cond(J)      = %.3e\n', getf(TS,'cond_J',NaN));
    fprintf(fid, '  det sign     = %+d\n', getf(TS,'det_sign',0));
    fprintf(fid, '  determinate  = %d (sigma_min above tol)\n', logical(getf(TS,'determinate',false)));
    fprintf(fid, ['\nReading: a well-conditioned J with sigma_min bounded away from 0 is the\n' ...
        'sequence-space counterpart of a transversal, locally unique asset-market\n' ...
        'crossing; a near-singular J flags the dynamic analog of the flat-demand\n' ...
        'multiplicity region of Proposition (sunspots).\n']);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ---- figure ----
if isfield(TA,'pi_path') && isfield(TS,'pi_path')
    fh = figure('Name','PFig: transition cross-check','Color','w','Position',[70 70 980 420]);
    subplot(1,2,1); hold on; box on;
    yrs = 1:numel(TA.pi_path);
    plot(yrs, 100*TA.pi_path, 'o-', 'Color',[0.20 0.40 0.70], 'LineWidth',1.3, 'MarkerSize',4);
    plot(yrs, 100*TS.pi_path, 's--', 'Color',[0.85 0.45 0.20], 'LineWidth',1.3, 'MarkerSize',4);
    yline(0,'k-','HandleVisibility','off');
    xlabel('year'); ylabel('inflation \pi_t (%)');
    legend({'Anderson','SSJ-Newton'},'Location','best');
    title('(a) announcement inflation path');
    subplot(1,2,2); hold on; box on;
    plot(yrs, 100*(TA.phat - TS.phat)./TA.phat, 'k-', 'LineWidth',1.2);
    xlabel('year'); ylabel('price-path gap (%)');
    title(sprintf('(b) solver gap (max %.1e)', agree));
    save_all_figs(fh, 'PFig_transition_ssj', pg);
    fprintf('  [saved] PFig_transition_ssj\n');
end

fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function v = getf(s, f, d)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = d; end
end
function s = ternary(c, a, b)
    if c, s = a; else, s = b; end
end
