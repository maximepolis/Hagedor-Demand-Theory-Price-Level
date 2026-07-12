% MAIN_PROJECT_AGGRISK_STAGEB  Aggregate climate risk, Stage B: the
% aggregate-risk channel in the self-financing decomposition and in welfare
% (appendix/AGGREGATE_RISK_PLAN.md, Stage B). Two questions:
%
%  1. FISCAL. Does the compressed climate-risk premium add a term to the
%     self-financing share nu? ANALYTICALLY, NO. The government's
%     ergodic-expected real interest bill is
%         E_pi[ sum_s' Pi(s,s') (R(s,s')-1) b_s ] = r^ss * B * E_pi[1/P_s],
%     which is INDEPENDENT of the risk premium (the state-contingent returns
%     average to r^ss * b over the ergodic distribution -- the premium is a
%     risk-TIMING wedge that washes out in expectation). So the aggregate-risk
%     self-financing decomposition is nu = nu_reval + nu_dam (ergodic-averaged),
%     with NO separate nu_aggrisk fiscal term. This driver verifies the
%     identity numerically (the ergodic bill matches r^ss*B*E[1/P] to solver
%     tolerance) and reports nu against the deterministic benchmark.
%
%  2. WELFARE. The premium is instead a RISK-SHARING object: compressing it
%     is worth something to the households who bear the climate risk. We price
%     it with an equal-mean-reduction counterfactual. The actual green program
%     lowers damages MORE in the severe state (compressing dispersion); the
%     counterfactual lowers both states by the SAME amount, so the ergodic-mean
%     damage falls identically but the dispersion is not compressed. The
%     consumption-equivalent gap between the two, by wealth group and aggregate
%     state, is the pure insurance value of the risk compression -- expected
%     to be positive and concentrated on the constrained / bottom-wealth
%     households, who are most exposed to the disaster state.
%
%       lambda_total : baseline            -> green (actual)      [full gain]
%       lambda_level : baseline            -> green (equal-red.)  [mean-D gain]
%       lambda_risk  : green (equal-red.)  -> green (actual)      [dispersion]
%
% REQUIRES: output/calibrated_results.mat (calibrated beta), as in
% main_project_aggrisk. All results STOCHASTIC AGGREGATE RISK, STEADY STATE.
%
% USAGE   >> main_project_aggrisk_stageB              % na=500 benchmark
%         >> NA = 250; main_project_aggrisk_stageB    % mid-resolution
%         >> FAST = true; main_project_aggrisk_stageB % na=100 quick check
%
% OUTPUT  PFig21_aggrisk_welfare.{fig,png,pdf}, output/aggrisk_stageB.mat,
%         output/tables/aggrisk_stageB_summary.txt

clearvars -except FAST NA; close all; clc;
t0 = tic;

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
logfile = fullfile(pg.logdir, 'aggrisk_stageB_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

% calibrated discount factor (same source as Stage A)
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star')
        pg.beta = L.RCAL.beta_star;
        fprintf('loaded calibrated beta*=%.4f\n', pg.beta);
    end
end

rbar = (1 + pg.i_ss)/(1 + pg.mu) - 1;      % deterministic real service rate
B    = pg.Bnom;
piagg = ergodic_of(pg.Pi_agg);             % 1 x ns ergodic aggregate marginal

% ---- program and the two damage vectors ----
D0s     = pg.agg.D_states;                 % [Calm, Severe] no-abatement
g_g     = 0.02;                            % real green spending (2% of income)
Kg      = g_g / pg.delta_g;
Dg      = D0s .* exp(-pg.theta_g * Kg);    % ACTUAL green damages (state-contingent)
dbar    = piagg * (D0s - Dg)';             % ergodic-mean damage reduction
Dg_eq   = D0s - dbar;                      % EQUAL-reduction counterfactual (same mean)

fprintf('==============================================================\n');
fprintf(' AGGREGATE RISK STAGE B: na=%d, beta*=%.4f, g_g=%.3f\n', pg.na, pg.beta, g_g);
fprintf(' D0=[%.3f %.3f], Dg=[%.3f %.3f], Dg_eq=[%.3f %.3f] (mean red. %.4f)\n', ...
        D0s, Dg, Dg_eq, dbar);
fprintf('==============================================================\n');

optb = struct('i_nom', pg.i_ss, 'Bnom', B, 'verbose', true, 'g_g', 0);
optg = struct('i_nom', pg.i_ss, 'Bnom', B, 'verbose', true, 'g_g', g_g);

fprintf('\n--- BASELINE (no program) ---\n');       TRb = solve_dtpl_aggrisk(pg, D0s,   optb);
fprintf('\n--- GREEN (actual, dispersion-compressing) ---\n'); TRg = solve_dtpl_aggrisk(pg, Dg, optg);
fprintf('\n--- GREEN (equal-reduction counterfactual) ---\n'); TRe = solve_dtpl_aggrisk(pg, Dg_eq, optg);
if ~(TRb.converged && TRg.converged && TRe.converged)
    warning('a Stage-B equilibrium did not converge -- results not reportable');
end

% =====================================================================
% 1. FISCAL: ergodic-averaged decomposition + premium-inertness identity
% =====================================================================
EinvP0 = piagg * (1 ./ TRb.P(:));   EinvPg = piagg * (1 ./ TRg.P(:));
ED0    = piagg * D0s(:);            EDg    = piagg * Dg(:);
nu_reval = rbar * B * (EinvP0 - EinvPg) / g_g;
nu_dam   = (ED0 - EDg) / g_g;
nu       = nu_reval + nu_dam;
% premium-inertness: the ergodic expected real interest bill computed from
% the FULL state-contingent returns should equal r^ss*B*E[1/P] exactly.
bill_direct = ergodic_interest_bill(TRg.R, TRg.P, B, pg.Pi_agg, piagg);
bill_formula = rbar * B * EinvPg;
FISC = struct('nu', nu, 'nu_reval', nu_reval, 'nu_dam', nu_dam, ...
    'premium_base', TRb.premium, 'premium_green', TRg.premium, ...
    'bill_direct', bill_direct, 'bill_formula', bill_formula, ...
    'bill_gap', abs(bill_direct - bill_formula));
fprintf('\n[1] FISCAL: nu = %.3f (reval %+.3f + dam %.3f)\n', nu, nu_reval, nu_dam);
fprintf('    premium %.4f -> %.4f (compressed %.4f)\n', ...
        TRb.premium, TRg.premium, TRb.premium - TRg.premium);
fprintf('    ergodic interest bill: direct %.6f vs r^ss*B*E[1/P] %.6f (gap %.2e)\n', ...
        bill_direct, bill_formula, FISC.bill_gap);
fprintf('    => the premium is FISCALLY INERT (no nu_aggrisk term); it is a\n');
fprintf('       welfare/risk-sharing object, priced next.\n');

% =====================================================================
% 2. WELFARE: CE gains and the level/risk split, by group and state
% =====================================================================
lam_total = ce_aggrisk(TRb.V, TRg.V, pg);   % baseline -> green actual
lam_level = ce_aggrisk(TRb.V, TRe.V, pg);   % baseline -> equal-reduction
lam_risk  = ce_aggrisk(TRe.V, TRg.V, pg);   % equal -> actual (dispersion)
dist0 = TRb.mu;                              % cut on the baseline distribution

% The pointwise split is EXACT: (1+lam_total)=(1+lam_level)(1+lam_risk) at
% every (a,e,s), so all three are aggregated on the same baseline
% distribution -- the "who values it" cut is on baseline household positions.
WEL = struct();
WEL.total = groupstats_agg(lam_total, dist0, pg);
WEL.level = groupstats_agg(lam_level, dist0, pg);
WEL.risk  = groupstats_agg(lam_risk,  dist0, pg);
fprintf('\n[2] WELFARE (consumption-equivalent, %%):\n');
fprintf('    total  overall %+.3f | Calm %+.3f Severe %+.3f | Q1 %+.3f Q5 %+.3f | constr %+.3f\n', ...
    100*WEL.total.overall, 100*WEL.total.state(1), 100*WEL.total.state(2), ...
    100*WEL.total.wq(1), 100*WEL.total.wq(5), 100*WEL.total.constrained);
fprintf('    RISK   overall %+.3f | Calm %+.3f Severe %+.3f | Q1 %+.3f Q5 %+.3f | constr %+.3f\n', ...
    100*WEL.risk.overall, 100*WEL.risk.state(1), 100*WEL.risk.state(2), ...
    100*WEL.risk.wq(1), 100*WEL.risk.wq(5), 100*WEL.risk.constrained);

save(fullfile(projdir,'output','aggrisk_stageB.mat'), ...
     'FISC','WEL','TRb','TRg','TRe','pg','g_g','D0s','Dg','Dg_eq','piagg');

% =====================================================================
% PFig21: (a) fiscal decomposition bar; (b) risk-value CE by group
% =====================================================================
fh = figure('Name','PFig21: aggregate-risk Stage B','Color','w', ...
            'Position',[60 60 1120 420]);
subplot(1,2,1); hold on; box on;
b1 = bar([1 2 3], [nu_reval nu_dam nu], 0.6);
b1.FaceColor = 'flat';
b1.CData = [0.10 0.30 0.75; 0.20 0.55 0.25; 0.35 0.35 0.35];
yline(1,'k--'); yline(0,'k-');
set(gca,'XTick',1:3,'XTickLabel',{'\nu_{reval}','\nu_{dam}','\nu (total)'});
ylabel('self-financing share'); title('(a) fiscal decomposition (premium inert)');
subplot(1,2,2); hold on; box on;
gg = [WEL.risk.constrained, WEL.risk.wq(1), WEL.risk.wq(3), WEL.risk.wq(5), ...
      WEL.risk.state(1), WEL.risk.state(2), WEL.risk.overall];
bar(100*gg, 'FaceColor', [0.55 0.20 0.55]);
set(gca,'XTick',1:7,'XTickLabel',{'constr','Q1','Q3','Q5','Calm','Severe','all'}, ...
    'XTickLabelRotation',30);
ylabel('insurance value (CE %)'); yline(0,'k-');
title('(b) welfare value of risk compression, by group');
save_all_figs(fh, 'PFig21_aggrisk_welfare', pg);
fprintf('\n  [saved] PFig21_aggrisk_welfare\n');

% =====================================================================
% summary table
% =====================================================================
sf = fullfile(pg.tabdir, 'aggrisk_stageB_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'AGGREGATE RISK STAGE B -- STOCHASTIC AGGREGATE RISK, STEADY STATE\n');
    fprintf(fid, 'na=%d, beta*=%.4f, program g_g=%.3f (2%% of income), i=%.3f\n', ...
            pg.na, pg.beta, g_g, pg.i_ss);
    fprintf(fid, 'Pi_agg=[%.2f %.2f; %.2f %.2f], ergodic pi=[%.3f %.3f]\n\n', ...
            pg.Pi_agg', piagg);
    fprintf(fid, '[1] FISCAL DECOMPOSITION (ergodic-averaged)\n');
    fprintf(fid, '  nu = nu_reval + nu_dam = %+.3f + %.3f = %.3f\n', ...
            nu_reval, nu_dam, nu);
    fprintf(fid, '  climate-risk premium: %.4f (baseline) -> %.4f (green), compressed %.4f\n', ...
            TRb.premium, TRg.premium, TRb.premium - TRg.premium);
    fprintf(fid, '  PREMIUM-INERTNESS CHECK: ergodic real interest bill\n');
    fprintf(fid, '    direct (state-contingent returns) = %.6f\n', bill_direct);
    fprintf(fid, '    r^ss * B * E_pi[1/P_s]            = %.6f\n', bill_formula);
    fprintf(fid, '    gap = %.2e (=> the premium adds NO fiscal term: nu has no\n', FISC.bill_gap);
    fprintf(fid, '    nu_aggrisk component; the premium is a welfare object)\n\n');
    fprintf(fid, '[2] WELFARE (consumption-equivalent gain, %%), cut on baseline dist\n');
    fprintf(fid, '  channel     overall   Calm    Severe   Q1(poor) Q3      Q5(rich) constr\n');
    prow = @(nm, g) fprintf(fid, '  %-10s %+7.3f %+7.3f %+7.3f %+8.3f %+7.3f %+8.3f %+7.3f\n', ...
        nm, 100*g.overall, 100*g.state(1), 100*g.state(2), ...
        100*g.wq(1), 100*g.wq(3), 100*g.wq(5), 100*g.constrained);
    prow('total',  WEL.total);
    prow('level',  WEL.level);
    prow('RISK',   WEL.risk);
    fprintf(fid, '\n  "total" = baseline -> green (actual); "level" = baseline -> green\n');
    fprintf(fid, '  with the SAME ergodic-mean damage reduction spread equally across\n');
    fprintf(fid, '  states (no dispersion compression); "RISK" = level -> actual, the\n');
    fprintf(fid, '  pure value of compressing the climate-risk the safe asset carries.\n');
    fprintf(fid, '  Dg=[%.3f %.3f] (actual), Dg_eq=[%.3f %.3f] (equal-reduction).\n', ...
            Dg, Dg_eq);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function pistat = ergodic_of(Pmat)
% ergodic (stationary) distribution of a row-stochastic matrix
    [V, Dg] = eig(Pmat');
    [~, k]  = min(abs(diag(Dg) - 1));
    pistat  = real(V(:,k));  pistat = (pistat / sum(pistat))';
end

function bill = ergodic_interest_bill(R, P, B, Piagg, piagg)
% ergodic-expected real interest bill: sum_s pi_s sum_s' Pi(s,s') (R(s,s')-1) b_s
% with b_s = B/P_s. (Should equal r^ss*B*E_pi[1/P] -- premium-inertness.)
    ns = numel(P); bill = 0;
    for s = 1:ns
        b_s = B / P(s);
        for sp = 1:ns
            bill = bill + piagg(s) * Piagg(s,sp) * (R(s,sp) - 1) * b_s;
        end
    end
end

function lam = ce_aggrisk(V0, Vg, pg)
% consumption-equivalent gain lambda(a,e,s) between two aggregate-risk value
% functions, using the same CRRA transform as welfare_by_group /
% welfare_groups_extended (with the sigma>1 validity guard).
    sigma = pg.sigma; beta = pg.beta;
    if abs(sigma - 1) < 1e-12
        lam = exp((Vg - V0) * (1 - beta)) - 1;
    else
        cshift = 1 / ((1 - sigma) * (1 - beta));
        Vt0 = V0 + cshift;  Vtg = Vg + cshift;
        if sigma > 1 && (max(Vt0(:)) >= 0 || max(Vtg(:)) >= 0)
            warning('ce_aggrisk:transform', ...
                'CE transform invalid (sigma>1, tilde-V >= 0); returning NaN.');
            lam = nan(size(V0)); return;
        end
        lam = (Vtg ./ Vt0).^(1/(1 - sigma)) - 1;
    end
end

function g = groupstats_agg(lam, dist, pg)
% aggregate lambda(a,e,s) over the distribution dist(a,e,s) by:
%   .overall, .state(s) (Calm/Severe), .wq(1..5) wealth quintiles,
%   .constrained (mass at the borrowing limit a = aGrid(1))
    [na, ne, ns] = size(dist);
    W = @(m) sum(lam(m) .* dist(m)) / max(sum(dist(m)), eps);
    g.overall = sum(lam(:) .* dist(:)) / max(sum(dist(:)), eps);
    % by aggregate state
    g.state = nan(1, ns);
    for s = 1:ns
        ms = false(na, ne, ns); ms(:,:,s) = true;
        g.state(s) = W(ms);
    end
    % wealth (=bond) quintiles: marginal over a (sum over e,s)
    wa = squeeze(sum(sum(dist, 3), 2));  cwa = cumsum(wa) / sum(wa);
    g.wq = nan(1,5); prev = 0;
    for q = 1:5
        hi = find(cwa >= q/5, 1, 'first'); if isempty(hi), hi = na; end
        mq = false(na, ne, ns); mq(prev+1:hi, :, :) = true;
        g.wq(q) = W(mq); prev = hi;
    end
    % constrained: at the borrowing limit (first asset node)
    mc = false(na, ne, ns); mc(1,:,:) = true;
    g.constrained = W(mc);
end
