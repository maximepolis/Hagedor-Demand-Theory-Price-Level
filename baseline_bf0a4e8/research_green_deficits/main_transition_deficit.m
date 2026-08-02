% MAIN_TRANSITION_DEFICIT  Does the announcement disinflation survive
% above-trend nominal issuance? The deficit-financed demand-theory path.
%
% THE QUESTION (external referee round, MC4). The benchmark transition
% imposes the contemporaneous service rule, so its announcement-year
% repricing is pure revaluation with no primary deficit. Whether the
% disinflation is a property of the MECHANISM or of that FINANCING TIMING
% is therefore untested: a deficit-financed program adds nominal issuance
% above trend, which dilutes the terminal price level, against the same
% asset-demand capitalization. Neither sign is imposed, and the answer
% decides how the paper's central untested prediction should be taken to
% data (announced green programs are typically deficit-financed at first).
%
% THE DESIGN. Indexed real program (identical spending path to the indexed
% benchmark, so ONLY tax timing differs); taxes phase in as
% tau_t = rbar*b_t + (1 - rho_d^t)*g, so the primary gap decays
% geometrically; real debt follows the exact recursion the nominal budget
% implies, and the terminal price is pinned by nominal neutrality at
% kappa_inf times the balanced terminal (same real economy, diluted
% stock). Solved by the same Anderson-accelerated fixed point as the
% benchmark, same convergence and horizon gates; nothing is reportable
% unless both pass.
%
% THE DECOMPOSITION. The impact response splits against two anchors:
%   dlnP_1(deficit) - dlnP_1(balanced)   the tax-timing wedge at impact
%   ln kappa_inf                          the pure terminal dilution
% If the impact wedge is close to +ln(kappa_inf), the announcement prices
% the ENTIRE future issuance immediately (full Ricardian capitalization of
% the dilution); if close to zero, the deficit is priced only as it is
% issued; a negative wedge would mean delayed taxes strengthen the
% disinflation (weaker early constraint-tightening cuts precautionary
% demand later, not sooner). Each is a distinct economics, and the run
% discriminates among them.
%
% USAGE   >> main_transition_deficit
%         >> FAST = true; main_transition_deficit      (na=150, T=60)
%         >> RHO_D = 0.9; main_transition_deficit      (slower phase-in)
%
% OUTPUT  output/tables/transition_deficit.txt, output/transition_deficit.mat

clearvars -except FAST RHO_D; close all; clc;
rng(20260729, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
rho_d = 0.8; if exist('RHO_D','var') && ~isempty(RHO_D), rho_d = RHO_D; end

pg = setup_params_green();
opts = struct('T', 80, 'tol', 2e-3, 'maxit', 120, 'xi', 0.5, 'verbose', true);
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    opts.T = 60; opts.maxit = 80;
    fprintf('*** FAST mode: na=%d, T=%d ***\n', pg.na, opts.T);
end

% ---- calibration: same protocol and grid-match guard as the tier-2 driver
D0_med = 0.06;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
beta_star = [];
if exist(calfile, 'file') == 2
    L = load(calfile);
    if isfield(L.RCAL, 'na') && L.RCAL.na == pg.na
        beta_star = L.RCAL.beta_star;  Gg_cal = L.RCAL.Gg_cal;
        fprintf('loaded calibration (na=%d): beta*=%.4f, Gg=%.5f\n', ...
            pg.na, beta_star, Gg_cal);
    end
end
if isempty(beta_star)
    fprintf('recalibrating beta on this grid (na=%d)...\n', pg.na);
    [beta_star, ~] = calibrate_beta(pg, (1+pg.i_ss)/(1+pg.mu)-1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
end
pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
opts.Gg_nom = Gg_cal;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'transition_deficit.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('DEFICIT-FINANCED DTPL ANNOUNCEMENT. na=%d T=%d rho_d=%.2f FAST=%d\n', ...
    pg.na, opts.T, rho_d, FAST);
tee('indexed real program; taxes phase in as 1-rho_d^t; debt is the residual\n\n');

% ---- balanced-timing anchor: the indexed benchmark (same real spending)
% Reuse the saved indexed path if its grid and horizon match; else re-solve.
TRi = [];
trf = fullfile(projdir, 'output', 'transition_results.mat');
if exist(trf, 'file') == 2
    Ltr = load(trf, 'TRi', 'pgc', 'opts');
    if ~isempty(Ltr.TRi) && Ltr.TRi.reportable ...
            && numel(Ltr.TRi.phat) == opts.T ...
            && isfield(Ltr.pgc, 'na') && Ltr.pgc.na == pg.na
        TRi = Ltr.TRi;
        tee('balanced anchor: loaded saved indexed path (T=%d)\n', numel(TRi.phat));
    end
end
if isempty(TRi)
    tee('balanced anchor: solving the indexed benchmark on this grid...\n');
    oi = opts; oi.regime = 'indexed';
    TRi = solve_hank_dtpl_transition(pgc, oi);
    tee('  %s\n', TRi.msg);
end
assert(TRi.reportable, 'indexed benchmark not reportable; fix it before the experiment');

% ---- the deficit path ----
tee('\n--- deficit financing, rho_d = %.2f ---\n', rho_d);
od = opts; od.regime = 'indexed'; od.financing = 'deficit'; od.rho_d = rho_d;
TRd = solve_hank_dtpl_transition(pgc, od);
tee('  %s\n', TRd.msg);
tee('  kappa_inf (terminal stock dilution) = %.4f (analytic seed %.4f)\n', ...
    TRd.kappa_inf, 1 + (rho_d/(1-rho_d)) * (Gg_cal/pg.Bnom));
tee('  cumulative primary gap = %.4f of annual income; peak-year gap = %.4f\n', ...
    sum(TRd.primary_gap), max(TRd.primary_gap));

% ---- results ----
tee('\n----- results -----\n');
if ~TRd.reportable
    tee('DEFICIT PATH NOT REPORTABLE (converged=%d horizon_ok=%d) -- no numbers below are quotable.\n', ...
        TRd.converged, TRd.horizon_ok);
end
d1_bal = log(TRi.phat(1) / TRi.eq0.P);
d1_def = log(TRd.phat(1) / TRd.eq0.P);
lk     = log(TRd.kappa_inf);
tee('impact d ln P: balanced %+0.4f | deficit %+0.4f | wedge %+0.4f\n', ...
    d1_bal, d1_def, d1_def - d1_bal);
tee('terminal dilution ln kappa_inf = %+0.4f\n', lk);
tee('capitalization ratio (impact wedge / ln kappa_inf) = %.3f\n', ...
    (d1_def - d1_bal) / lk);
tee('  1.0 => the announcement prices the entire future issuance at once;\n');
tee('  0.0 => the deficit is priced only as issued; <0 => timing deepens\n');
tee('  the disinflation. The ratio is the finding.\n');
surv = (d1_def < 0);
tee('announcement disinflation under deficit finance: %s (impact %+0.4f)\n', ...
    ternstr(surv, 'SURVIVES', 'OVERTURNED'), d1_def);
tee('front-loading share: balanced %.3f | deficit %.3f (vs own terminal)\n', ...
    TRi.frontload, (TRd.eq0.P - TRd.phat(1)) / (TRd.eq0.P - TRd.phat(end)));
tee('bondholder revaluation at t=1 (share of program PV): balanced %+0.3f | deficit %+0.3f\n', ...
    TRi.reval_pv_share, TRd.reval_pv_share);

save(fullfile(projdir, 'output', 'transition_deficit.mat'), ...
     'TRd', 'TRi', 'pgc', 'opts', 'rho_d');
tee('\n[main_transition_deficit] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
