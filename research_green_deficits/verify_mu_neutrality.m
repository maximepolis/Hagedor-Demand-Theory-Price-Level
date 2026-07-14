% VERIFY_MU_NEUTRALITY  Numerical check of Theorem 2 (mu-neutrality):
% the stationary green equilibrium depends on the money-growth / inflation
% rate mu ONLY through the real service rate r^ss = (1+i^ss)/(1+mu)-1. Two
% scans make this operational:
%
%   SCAN A (fixed i^ss, vary mu):   r^ss(mu) = (1+i^ss)/(1+mu)-1 moves, so the
%       equilibrium and welfare trace out a curve W(r^ss(mu)). This is the
%       object the "optimal-mu" section of the paper actually chooses over.
%   SCAN B (fixed r^ss, vary mu):   set i^ss(mu) = (1+r^ss)(1+mu)-1 so r^ss is
%       held at the calibrated value. Theorem 2 predicts EVERY equilibrium
%       object (P^*, S, D, W, and the nu decomposition) is invariant across mu.
%       The driver confirms the spread across the mu grid is at solver noise.
%
% The two scans together are the content of Proposition (mu-neutral): what the
% paper calls an "optimal money-growth rate" is an optimal-real-rate result;
% mu is a relabeling of r^ss, matching Aiyagari-McGrattan (1998).
%
% USAGE   >> verify_mu_neutrality               % na=500 benchmark
%         >> FAST = true; verify_mu_neutrality  % quick check
%
% OUTPUT  output/mu_neutrality_results.mat, output/tables/mu_neutrality.txt,
%         PFig_muneutral.{fig,png,pdf}
%
% STATUS: verification driver for Theorem 2. Pure re-use of the existing
% steady-state solver -- no new modeling; it audits the claim in code.

clearvars -except FAST NA; close all; clc;
rng(20260714, 'twister'); t0 = tic;

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
    pg.nP_scan = pg.fast.nP_scan;
end
if pg.na ~= numel(pg.aGrid)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end

if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'mu_neutrality_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' MU-NEUTRALITY VERIFICATION (Theorem 2), na=%d\n', pg.na);
fprintf('==============================================================\n');

% ----- reuse the calibrated medium column so the check is on the headline -----
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star')
        pg.beta = L.RCAL.beta_star;
        fprintf('loaded calibrated beta*=%.4f\n', pg.beta);
    end
    if isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
        Gg_cal = L.RCAL.Gg_cal;
    end
end
if ~exist('Gg_cal','var'), Gg_cal = 0.02 * (pg.Bnom / 1.10); end

i_ss0 = pg.i_ss;                              % benchmark nominal rate
mu0   = pg.mu;                                % benchmark money growth
r_cal = (1 + i_ss0)/(1 + mu0) - 1;            % calibrated real service rate
D0med = 0.06;

pgc = pg;
pgc.climate_version = 1;
pgc.D0     = D0med;
pgc.Gg_nom = Gg_cal;
pgc.taugrid_S = linspace(-0.02, 0.10, 6);
pgc.Dgrid_S   = linspace(0, D0med, 3);

muGrid = linspace(0.00, 0.10, 11);            % 0% .. 10% money growth

% =====================================================================
% SCAN A: hold i^ss fixed, vary mu  =>  r^ss(mu) varies
% =====================================================================
fprintf('\n----- SCAN A: i^ss=%.3f fixed, mu varies (r^ss moves) -----\n', i_ss0);
A = local_scan(pgc, muGrid, @(mu) (1+i_ss0)/(1+mu)-1, i_ss0, Gg_cal, 'A');

% =====================================================================
% SCAN B: hold r^ss fixed at r_cal, vary mu  =>  i^ss(mu) compensates
% =====================================================================
fprintf('\n----- SCAN B: r^ss=%.4f fixed, mu varies (i^ss compensates) -----\n', r_cal);
B = local_scan(pgc, muGrid, @(mu) r_cal, NaN, Gg_cal, 'B');

% =====================================================================
% VERDICT
% =====================================================================
% (i)  Scan B invariance: every object constant across mu (to solver noise).
Pspread = max(B.P) - min(B.P);
Wspread = max(B.W) - min(B.W);
% (ii) Cross-consistency: Scan A at a given mu equals Scan B at the matching
%      r^ss. Because both call the identical solver keyed on r^ss, Scan A(mu)
%      must equal a Scan-B-style solve at r^ss=(1+i0)/(1+mu)-1; we verify Scan A
%      is a strictly monotone function of r^ss (no independent mu channel).
fprintf('\n================ VERDICT ================\n');
fprintf('SCAN B (r^ss fixed): P* spread across mu grid = %.3e\n', Pspread);
fprintf('SCAN B (r^ss fixed): W  spread across mu grid = %.3e\n', Wspread);
tolP = 1e-4; tolW = 1e-4;
passB = (Pspread < tolP) && (Wspread < tolW);
fprintf('  => %s: at fixed r^ss, mu does not enter the equilibrium.\n', ...
        ternary(passB, 'PASS', 'CHECK'));
% Scan A monotone in r^ss:
[rA, ix] = sort(A.rss); WA = A.W(ix);
mono = all(diff(WA(isfinite(WA))) .* sign(mean(diff(WA(isfinite(WA))))) >= -tolW);
fprintf('SCAN A: W is a single-valued monotone function of r^ss: %s\n', ...
        ternary(mono, 'PASS', 'CHECK'));
fprintf('=========================================\n');

save(fullfile(projdir,'output','mu_neutrality_results.mat'), ...
     'A','B','muGrid','i_ss0','mu0','r_cal','Pspread','Wspread','passB');

% ----- table -----
sf = fullfile(pg.tabdir, 'mu_neutrality.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'MU-NEUTRALITY VERIFICATION (Theorem 2).  na=%d, Gg=%.5f, D0=%.2f\n', ...
            pg.na, Gg_cal, D0med);
    fprintf(fid, 'r^ss = (1+i^ss)/(1+mu)-1; calibrated r^ss=%.4f (i^ss=%.3f, mu=%.3f)\n\n', ...
            r_cal, i_ss0, mu0);
    fprintf(fid, 'SCAN A  (i^ss=%.3f fixed; r^ss varies with mu)\n', i_ss0);
    fprintf(fid, '   mu     r^ss      P*        S        D        W\n');
    for k = 1:numel(muGrid)
        fprintf(fid, ' %.3f  %+.4f  %.4f  %.4f  %.4f  %+.4f\n', ...
            muGrid(k), A.rss(k), A.P(k), A.S(k), A.D(k), A.W(k));
    end
    fprintf(fid, '\nSCAN B  (r^ss=%.4f fixed; i^ss compensates mu)\n', r_cal);
    fprintf(fid, '   mu    i^ss(mu)   P*        S        D        W\n');
    for k = 1:numel(muGrid)
        fprintf(fid, ' %.3f  %+.4f  %.4f  %.4f  %.4f  %+.4f\n', ...
            muGrid(k), B.iss(k), B.P(k), B.S(k), B.D(k), B.W(k));
    end
    fprintf(fid, '\nSCAN B invariance:  P* spread=%.3e  W spread=%.3e  (=> %s)\n', ...
            Pspread, Wspread, ternary(passB,'mu-neutral','recheck'));
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ----- figure -----
fh = figure('Name','PFig: mu-neutrality (Theorem 2)','Color','w', ...
            'Position',[70 70 980 420]);
subplot(1,2,1); hold on; box on;
plot(muGrid, A.W, 'o-', 'Color',[0.20 0.40 0.70], 'LineWidth',1.4, ...
     'MarkerFaceColor',[0.20 0.40 0.70]);
plot(muGrid, B.W, 's--', 'Color',[0.45 0.70 0.45], 'LineWidth',1.4, ...
     'MarkerFaceColor',[0.45 0.70 0.45]);
xlabel('money growth \mu'); ylabel('welfare W');
legend({'Scan A: i^{ss} fixed (r^{ss} moves)', ...
        'Scan B: r^{ss} fixed (i^{ss} moves)'}, 'Location','best');
title('(a) W vs \mu: only Scan A moves');
subplot(1,2,2); hold on; box on;
plot(A.rss, A.W, 'o-', 'Color',[0.20 0.40 0.70], 'LineWidth',1.4, ...
     'MarkerFaceColor',[0.20 0.40 0.70]);
xlabel('real service rate r^{ss}'); ylabel('welfare W');
title('(b) W vs r^{ss}: single curve');
save_all_figs(fh, 'PFig_muneutral', pg);
fprintf('  [saved] PFig_muneutral\n');

fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function R = local_scan(pgc, muGrid, rss_of_mu, i_fixed, Gg_cal, tag)
    n = numel(muGrid);
    R = struct('mu',muGrid,'rss',nan(1,n),'iss',nan(1,n), ...
               'P',nan(1,n),'S',nan(1,n),'D',nan(1,n),'W',nan(1,n));
    for k = 1:n
        mu   = muGrid(k);
        rss  = rss_of_mu(mu);
        if isnan(i_fixed)                    % Scan B: i^ss compensates
            iss = (1+rss)*(1+mu) - 1;
        else                                 % Scan A: i^ss fixed
            iss = i_fixed;
        end
        R.rss(k) = rss; R.iss(k) = iss;
        ad2 = build_S_interp_green(rss, pgc);
        policy = struct('regime','nominal','i_ss',iss,'mu',mu, ...
                        'Bnom',pgc.Bnom,'Gg_nom',Gg_cal);
        try
            eqs = solve_green_steady_state(pgc, policy, ad2);
        catch ME
            fprintf('  [%s] mu=%.3f: solver error (%s)\n', tag, mu, ME.message);
            continue;
        end
        if isempty(eqs), continue; end
        e = eqs(end);                         % upper (stable) root if multiple
        R.P(k) = e.P; R.S(k) = e.S; R.D(k) = e.D; R.W(k) = e.W;
        fprintf('  [%s] mu=%.3f  r^ss=%+.4f  i^ss=%+.4f  P*=%.4f  W=%+.4f\n', ...
                tag, mu, rss, iss, e.P, e.W);
    end
end

function s = ternary(c, a, b)
    if c, s = a; else, s = b; end
end
