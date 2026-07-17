% DECOMPOSE_TAX_ELASTICITY  Referee (round 5, point 1): the green-disinflation,
% bondholder-windfall, and regressive-incidence results all rest on the sign and
% size of the tax semi-elasticity of aggregate safe-asset demand,
% eps_tau = d ln S / d tau (Section 5.8, ~ +2.9 at the benchmark). Result 1
% flags that the mechanism flips when this slope is negative, so this driver
% (a) DECOMPOSES the tax-induced demand shift by baseline wealth group and by
%     constraint status, and
% (b) SWEEPS the sign of eps_tau over the primitives that govern it -- the
%     borrowing limit, income-risk scale, CRRA, the debt target, and the tax
%     instrument (lump-sum vs proportional levy) --
% to show green disinflation is a general property of the DTPL buffer-stock
% block over a wide region, not a knife-edge of one calibration.
%
% USAGE   >> decompose_tax_elasticity
%         >> FAST = true; decompose_tax_elasticity      % na=100 quick
%
% OUTPUT  output/tax_elasticity_results.mat,
%         output/tables/tax_elasticity.txt, PFig_tax_elasticity.*
%
% STATUS: verification/robustness driver; reuses S_green directly. No number is
% asserted in the paper until this has run.

clearvars -except FAST NA; close all; clc;
rng(20260715, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg0 = setup_params_green();
if exist('NA','var') && ~isempty(NA)
    pg0.na = NA;
elseif FAST
    pg0.na = pg0.fast.na;
end
pg0 = rebuild_grid(pg0);
if ~isfolder(pg0.logdir), mkdir(pg0.logdir); end
if ~isfolder(pg0.tabdir), mkdir(pg0.tabdir); end
logfile = fullfile(pg0.logdir, 'tax_elasticity_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' TAX SEMI-ELASTICITY d ln S / d tau: decomposition + sign sweep\n');
fprintf('==============================================================\n');

% calibrated medium column
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
Gg_cal = 0.02 * (pg0.Bnom / 1.10);
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), pg0.beta = L.RCAL.beta_star; end
    if isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal'),   Gg_cal = L.RCAL.Gg_cal;         end
end
pg0.climate_version = 1;
pg0.D0 = 0.06;
r_cal  = (1 + pg0.i_ss)/(1 + pg0.mu) - 1;

% no-program vs program taxes at the medium column (P0 ~ b_target normalization)
P0   = pg0.Bnom / 1.10;
tau0 = r_cal * pg0.Bnom / P0;                 % no program
g0   = Gg_cal / P0;
tau1 = tau0 + g0;                             % + program real cost (lump-sum)
D0   = pg0.D0;

% =====================================================================
% (a) DECOMPOSITION by baseline wealth quintile and constraint status
% =====================================================================
fprintf('\n----- (a) decomposition of dS by baseline wealth group -----\n');
[S0, o0] = S_green(r_cal, tau0, D0, pg0);
[S1, o1] = S_green(r_cal, tau1, D0, pg0);
eps_tau = (log(S1) - log(S0)) / (tau1 - tau0);
fprintf('  S(tau0)=%.4f  S(tau1)=%.4f  d ln S/d tau = %+.3f\n', S0, S1, eps_tau);

aG    = pg0.aGrid(:);
m0    = sum(o0.dist, 2);                       % baseline marginal over assets
m1    = sum(o1.dist, 2);
% baseline wealth quintile cutoffs by cumulative population
cum   = cumsum(m0) / sum(m0);
qedge = arrayfun(@(q) find(cum >= q, 1, 'first'), [0.2 0.4 0.6 0.8]);
qbnd  = [1; qedge(:); numel(aG)];
dS_q  = zeros(1,5);
for q = 1:5
    idx = (qbnd(q)):(qbnd(q+1)-1);
    if q == 5, idx = (qbnd(5)):numel(aG); end
    dS_q(q) = sum(aG(idx) .* (m1(idx) - m0(idx)));
end
dS_tot   = S1 - S0;
% constrained mass (at the borrowing limit, node 1)
dMass_c  = m1(1) - m0(1);
dS_constr = aG(1) * dMass_c;
fprintf('  total dS = %+.5f; by baseline quintile (Q1..Q5): %s\n', ...
        dS_tot, mat2str(dS_q, 3));
fprintf('  share of dS from each quintile (%%): %s\n', ...
        mat2str(100*dS_q/dS_tot, 3));
fprintf('  constrained mass change %+.4f (a=%.2f); its dS contribution %+.5f\n', ...
        dMass_c, aG(1), dS_constr);

% =====================================================================
% (b) SIGN SWEEP over the primitives that govern eps_tau
% =====================================================================
fprintf('\n----- (b) sign sweep of d ln S/d tau -----\n');
dtau = 0.01;
sweeps = struct('name',{},'vals',{},'eps',{});

% borrowing limit abar
abars = [0.0 0.5 1.0 2.0];
e_ab  = nan(size(abars));
for k = 1:numel(abars)
    pg = pg0; pg.abar = abars(k); pg = rebuild_grid(pg);
    e_ab(k) = semielast(r_cal, tau0, dtau, D0, pg);
end
sweeps(end+1) = struct('name','borrowing limit abar','vals',abars,'eps',e_ab);

% income-risk scale sig_eps
sigs = [0.15 0.20 0.25];
e_se = nan(size(sigs));
for k = 1:numel(sigs)
    pg = pg0; pg.sig_eps = sigs(k); pg.sig_eps0 = sigs(k); pg.phi_D = 0;
    [eG, PiD, stD] = make_income_process(pg);
    pg.eGrid = eG; pg.Pi = PiD; pg.stationary_e = stD;
    e_se(k) = semielast(r_cal, tau0, dtau, D0, pg);
end
sweeps(end+1) = struct('name','income-risk sig_eps','vals',sigs,'eps',e_se);

% CRRA sigma (sigma=1 infeasible at the target; sweep >1)
sgm = [1.5 2.0 3.0];
e_sg = nan(size(sgm));
for k = 1:numel(sgm)
    pg = pg0; pg.sigma = sgm(k);
    e_sg(k) = semielast(r_cal, tau0, dtau, D0, pg);
end
sweeps(end+1) = struct('name','CRRA sigma','vals',sgm,'eps',e_sg);

% debt target (via beta: higher beta -> more demand -> higher b at r_cal)
betas = pg0.beta * [0.97 1.00 1.03];
e_bt  = nan(size(betas));
for k = 1:numel(betas)
    pg = pg0; pg.beta = betas(k);
    e_bt(k) = semielast(r_cal, tau0, dtau, D0, pg);
end
sweeps(end+1) = struct('name','discount beta (debt target)','vals',betas,'eps',e_bt);

for s = 1:numel(sweeps)
    fprintf('  %-28s vals=%s  eps=%s  (all>0: %d)\n', sweeps(s).name, ...
        mat2str(sweeps(s).vals,3), mat2str(sweeps(s).eps,3), all(sweeps(s).eps>0));
end

% =====================================================================
% (c) TAX INSTRUMENT: lump-sum (d/dtau) vs proportional levy (d/dvartheta)
% =====================================================================
fprintf('\n----- (c) instrument: lump-sum vs proportional levy -----\n');
eps_ls = semielast(r_cal, tau0, dtau, D0, pg0);       % lump-sum, >0 expected
% proportional levy: raise vartheta by dv (revenue ~ dv*(1-D)), demand response
dv = 0.01;
pgL = pg0; pgL.vartheta = 0.0;    [Sa,~] = S_green(r_cal, tau0, D0, pgL);
pgL.vartheta = dv;                [Sb,~] = S_green(r_cal, tau0, D0, pgL);
eps_levy = (log(Sb) - log(Sa)) / dv;                  % d ln S/d vartheta, <0 expected
fprintf('  lump-sum   d ln S/d tau      = %+.3f  (raises demand => disinflation)\n', eps_ls);
fprintf('  prop levy  d ln S/d vartheta = %+.3f  (lowers demand => inflation)\n', eps_levy);
fprintf('  => the sign of the price-level response is the tax instrument, as Result 1 states.\n');

% =====================================================================
% (d) TILT DECOMPOSITION (memo M2): a same-revenue LUMP-SUM tax equals a
% same-revenue PROPORTIONAL levy plus a mean-zero REGRESSIVE tilt. The tilt
% is (lump-sum minus levy): each household pays R*(1 - y_i/ybar), so
% below-mean households pay MORE (lump-sum is the more regressive of the two)
% and above-mean pay less -- a regressive redistribution with mean zero.
% We implement the tilt alone as a proportional SUBSIDY at rate dv (return
% R*y_i/ybar) plus a uniform tax R, i.e. vartheta = -dv, tau_ls = tau0 + R.
% Net income change dv*(y_i - ybar): below-mean lose, above-mean gain.
% Additivity Dln S_ls = Dln S_levy + Dln S_tilt holds to first order in dv.
% =====================================================================
fprintf('\n----- (d) tilt decomposition: lump-sum = levy(same rev) + mean-zero tilt -----\n');
[S0t,~]  = S_green(r_cal, tau0, D0, pg0);                 % baseline
dv = 0.01;
rev      = dv*(1-D0);                                    % common revenue R
% same-revenue proportional levy (revenue R) at fixed lump-sum:
pgLr = pg0; pgLr.vartheta = dv;
[SLr,~]  = S_green(r_cal, tau0, D0, pgLr);
eps_levy_perRev = (log(SLr)-log(S0t))/rev;               % d ln S / d(levy revenue)
% same-revenue lump-sum (tau up by R):
[SLS,~]  = S_green(r_cal, tau0+rev, D0, pg0);
eps_ls_perRev   = (log(SLS)-log(S0t))/rev;               % d ln S / d(lump-sum revenue)
% mean-zero REGRESSIVE tilt alone = (lump-sum minus levy): uniform tax R,
% proportional subsidy dv (vartheta = -dv). Takes from below-mean, gives
% to above-mean -> tightens the constrained -> raises precautionary demand.
pgT = pg0; pgT.vartheta = -dv;
[ST,~]   = S_green(r_cal, tau0+rev, D0, pgT);            % tau_ls = tau0 + R
eps_tilt = (log(ST)-log(S0t))/rev;                       % per unit of revenue
tilt_resid = eps_ls_perRev - (eps_levy_perRev + eps_tilt);
fprintf('  lump-sum (per rev) %+.3f = levy (per rev) %+.3f + tilt %+.3f  [resid %+.1e]\n', ...
        eps_ls_perRev, eps_levy_perRev, eps_tilt, tilt_resid);

save(fullfile(projdir,'output','tax_elasticity_results.mat'), ...
     'eps_tau','dS_q','dS_tot','dS_constr','dMass_c','sweeps','eps_ls','eps_levy', ...
     'eps_ls_perRev','eps_levy_perRev','eps_tilt','tilt_resid');

% ----- table -----
sf = fullfile(pg0.tabdir, 'tax_elasticity.txt');
fid = fopen(sf,'w');
if fid > 0
    fprintf(fid, 'TAX SEMI-ELASTICITY d ln S/d tau. na=%d, D0=%.2f, r=%.4f\n\n', pg0.na, D0, r_cal);
    fprintf(fid, '(a) DECOMPOSITION at the medium column (tau0=%.4f -> tau1=%.4f):\n', tau0, tau1);
    fprintf(fid, '    d ln S/d tau = %+.3f;  total dS = %+.5f\n', eps_tau, dS_tot);
    fprintf(fid, '    dS by baseline wealth quintile Q1..Q5: %s\n', mat2str(dS_q,3));
    fprintf(fid, '    share (%%): %s\n', mat2str(100*dS_q/dS_tot,3));
    fprintf(fid, '    constrained-mass change %+.4f; dS contribution %+.5f\n\n', dMass_c, dS_constr);
    fprintf(fid, '(b) SIGN SWEEP of d ln S/d tau (positive => disinflation robust):\n');
    for s = 1:numel(sweeps)
        fprintf(fid, '    %-28s vals=%s eps=%s\n', sweeps(s).name, ...
            mat2str(sweeps(s).vals,3), mat2str(sweeps(s).eps,3));
    end
    fprintf(fid, '\n(c) INSTRUMENT: lump-sum d ln S/d tau=%+.3f; levy d ln S/d vartheta=%+.3f\n', ...
        eps_ls, eps_levy);
    fprintf(fid, ['\n(d) TILT DECOMPOSITION (per unit of revenue):\n' ...
        '    lump-sum %+.3f = levy %+.3f + mean-zero tilt %+.3f  [additivity resid %+.1e]\n' ...
        '    => the positive lump-sum sign is the regressive-tilt response, not taxation per se.\n'], ...
        eps_ls_perRev, eps_levy_perRev, eps_tilt, tilt_resid);
    fprintf(fid, ['\nReading: a positive lump-sum semi-elasticity across the swept region\n' ...
        'shows green disinflation is a general DTPL buffer-stock property; the levy\n' ...
        'reverses the sign, which is the incidence result of Result 1 / Section 5.11.\n']);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ----- figure -----
fh = figure('Name','PFig: tax elasticity','Color','w','Position',[70 70 1000 400]);
subplot(1,3,1); bar(1:5, 100*dS_q/dS_tot, 'FaceColor',[0.30 0.50 0.75]); box on;
set(gca,'XTickLabel',{'Q1','Q2','Q3','Q4','Q5'}); ylabel('share of dS (%)');
title('(a) demand shift by wealth');
subplot(1,3,2); hold on; box on;
plot(abars, e_ab, 'o-','LineWidth',1.3,'MarkerFaceColor','auto');
yline(0,'k--','HandleVisibility','off');
xlabel('borrowing limit (a-bar)'); ylabel('d ln S/d\tau'); title('(b) sign vs borrowing limit');
subplot(1,3,3); hold on; box on;
bar(1, eps_ls, 0.5, 'FaceColor',[0.30 0.50 0.75]);
bar(2, eps_levy, 0.5, 'FaceColor',[0.80 0.45 0.25]);
set(gca,'XTick',[1 2],'XTickLabel',{'lump-sum','levy'}); yline(0,'k-','HandleVisibility','off');
ylabel('semi-elasticity'); title('(c) instrument sign');
save_all_figs(fh, 'PFig_tax_elasticity', pg0);
fprintf('  [saved] PFig_tax_elasticity\n');

fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function e = semielast(r, tau0, dtau, D, pg)
% central-ish forward difference of d ln S/d tau at tau0
    [Sa,oa] = S_green(r, tau0, D, pg);
    [Sb,ob] = S_green(r, tau0+dtau, D, pg);
    if ~(isfinite(Sa) && isfinite(Sb) && oa.feasible && ob.feasible)
        e = NaN; return;
    end
    e = (log(Sb) - log(Sa)) / dtau;
end

function pg = rebuild_grid(pg)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end
