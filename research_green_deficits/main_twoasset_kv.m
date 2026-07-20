% MAIN_TWOASSET_KV  Two-asset DTPL, build-plan variant (b): infrequent
% k-adjustment (Kaplan-Violante friction) generating wealthy hand-to-mouth
% households, on top of the Step 0 bonds-plus-tree economy.
%
% WHAT THIS DELIVERS:
%   1. Baseline (P, q) equilibrium at adjustment probability lambda, with
%      the hand-to-mouth decomposition: poor HtM (low b, low k), wealthy
%      HtM (low b, substantial illiquid k), liquid share, top wealth shares.
%      chi_b recalibrated to the liquid debt target at this lambda.
%   2. Financing experiment lump-sum vs levy (full equilibria) -> d ln P,
%      compared against Step 0 (frictionless) and the one-asset regimes.
%   3. Liquid-margin incidence at fixed prices: the same-revenue lump-sum /
%      levy / tilt responses of nominal-bond demand, the policy-flow vs
%      distribution split, AND the policy-flow term decomposed by
%      hand-to-mouth status -- with realistic bond ownership this is the
%      referee's Cov(m^b, dy^net) object computed where it belongs.
%   4. lambda sensitivity (short sweep) and a lambda -> 1 consistency check
%      against the frictionless Step 0 EGM at identical prices.
%
% USAGE   >> main_twoasset_kv
%         >> FAST = true; main_twoasset_kv       % coarse grids, short sweep
%
% OUTPUT  output/twoasset_kv.mat, output/tables/twoasset_kv.txt
%
% RUNTIME: the first household solve is the expensive one (nested vector
% golden over a 3D state); every later evaluation warm-starts from the last
% value function. FAST first; the full run is an overnight job.
%
% STATUS: scaffolded, untested pending a MATLAB run. Nothing asserted in
% the paper until the run.

clearvars -except FAST; close all; clc;
rng(20260720, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();

% ---- parameters ----
p = struct();
p.sigma = pg.sigma; p.beta = pg.beta;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), p.beta = L.RCAL.beta_star; end
end
p.eGrid = pg.eGrid; p.Pi = pg.Pi; p.stationary_e = pg.stationary_e;
p.zeta_b = 2.0; p.chi_b = 0.02;               % chi recalibrated below
p.lambda_adj = 1/3;                            % annual adj. prob (~3y spell)
p.tol_vfi = 1e-6;  p.maxit_vfi = 400;
p.tol_dist = 1e-10; p.maxit_dist = 20000;
p.gold_outer = 50; p.gold_inner = 25;
nb = 70; nk = 35; nx = 140; bmax = 25; kmax = 40; xmax = 90;
if FAST, nb = 45; nk = 22; nx = 90; p.gold_outer = 40; p.gold_inner = 20; end
ub = linspace(0,1,nb)'; p.bGrid  = 1e-4 + (bmax - 1e-4)*(ub.^2.2);
uk = linspace(0,1,nk)'; p.kGrid  = (kmax)*(uk.^2.2);
uxA = linspace(0,1,nx)'; p.xGridA = 0.05 + (xmax - 0.05)*(uxA.^2.2);

% policy / climate (medium column, real budget)
D0   = 0.06;
r_b  = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom;  b_targ = 1.10;  d_div = 0.12;  Kbar = 1.0;
Gg   = 0.02 * (Bnom / b_targ);
if exist(calfile,'file') == 2 && isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
    Gg = L.RCAL.Gg_cal;
end
% hand-to-mouth cutoffs (report both in the table)
htm_b  = 0.02;                                 % liquid < 2% of mean income
whtm_k = 0.50;                                 % illiquid value > 50% of it

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'twoasset_kv.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET VARIANT (b): infrequent k-adjustment. nb=%d nk=%d nx=%d ne=%d\n', ...
    nb, nk, nx, numel(p.eGrid));
tee('lambda=%.3f zeta=%.2f r_b=%.4f d=%.3f FAST=%d\n\n', ...
    p.lambda_adj, p.zeta_b, r_b, d_div, FAST);

% =====================================================================
% (1) BASELINE: chi_b to the liquid target, (P, q), HtM decomposition
% =====================================================================
tee('----- (1) baseline equilibrium and hand-to-mouth decomposition -----\n');
clo = 1e-5; chi = 1.0; eqb = [];
for itc = 1:30
    p.chi_b = sqrt(clo*chi);
    eqb = solve_kv_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, p);
    if ~eqb.ok, clo = p.chi_b; continue; end
    if eqb.Sb > b_targ, chi = p.chi_b; else, clo = p.chi_b; end
    if abs(eqb.Sb - b_targ) < 1e-2, break; end
end
assert(~isempty(eqb) && eqb.ok, 'variant-(b) baseline failed: %s', eqb.msg);
omega = eqb.Sb/(eqb.Sb + eqb.q*Kbar);
tee('chi_b=%.5f  S_b=%.4f (target %.2f)  q=%.4f  P=%.4f  omega=%.3f\n', ...
    p.chi_b, eqb.Sb, b_targ, eqb.q, eqb.P, omega);
H = htm_stats(eqb.dist, eqb.q, p, htm_b, whtm_k);
tee('HtM (b<%.2f): total %.3f | wealthy (qk>%.2f): %.3f | poor: %.3f\n', ...
    htm_b, H.htm, whtm_k, H.whtm, H.phtm);
tee('wealth shares: top10 %.2f top1 %.2f (total wealth b+qk)\n\n', ...
    H.top10, H.top1);

% =====================================================================
% (2) FINANCING: lump-sum vs levy, full equilibria
% =====================================================================
tee('----- (2) financing incidence -----\n');
g_real = Gg / eqb.P;
EXK = struct('name',{},'P',{},'q',{},'Sb',{},'dlnP',{});
runs = {struct('name','lump-sum','levy',0), struct('name','levy','levy',1)};
for k = 1:numel(runs)
    ek = solve_kv_eq(r_b, d_div, D0, g_real, runs{k}.levy, Bnom, Kbar, p);
    if ek.ok
        EXK(end+1) = struct('name',runs{k}.name,'P',ek.P,'q',ek.q, ...
            'Sb',ek.Sb,'dlnP',log(ek.P/eqb.P)); %#ok<SAGROW>
        tee('%-9s P=%.4f dlnP=%+0.4f  q=%.4f  S_b=%.4f\n', ...
            runs{k}.name, ek.P, log(ek.P/eqb.P), ek.q, ek.Sb);
    else
        tee('%-9s FAILED: %s\n', runs{k}.name, ek.msg);
    end
end
s0f = fullfile(projdir, 'output', 'twoasset_step0.mat');
if exist(s0f,'file') == 2 && numel(EXK) >= 2
    S0r = load(s0f, 'EX');
    if isfield(S0r,'EX') && numel(S0r.EX) >= 2
        tee('vs Step 0 (frictionless): ls %+0.4f -> %+0.4f | levy %+0.4f -> %+0.4f\n', ...
            S0r.EX(1).dlnP, EXK(1).dlnP, S0r.EX(2).dlnP, EXK(2).dlnP);
    end
end
if numel(EXK) >= 2
    tee('sign contrast survives: %d\n', sign(EXK(1).dlnP) ~= sign(EXK(2).dlnP));
end
tee('\n');

% =====================================================================
% (3) LIQUID-MARGIN INCIDENCE at fixed prices, by HtM status
% =====================================================================
tee('----- (3) liquid-margin incidence at fixed (q, r_b) -----\n');
dv = 0.01; rev = dv*(1-D0);
[Sb0, agg0] = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, 0, p, eqb.Vcache);
[SbLS, ~]   = kv_liquid(r_b, eqb.q, d_div, eqb.tau + rev, D0, 0, p, eqb.Vcache);
[SbLV, ~]   = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, dv, p, eqb.Vcache);
[SbTL, aggT] = kv_liquid(r_b, eqb.q, d_div, eqb.tau + rev, D0, -dv, p, eqb.Vcache);
if all(isfinite([Sb0 SbLS SbLV SbTL]))
    eLS = (log(SbLS)-log(Sb0))/rev; eLV = (log(SbLV)-log(Sb0))/rev;
    eTL = (log(SbTL)-log(Sb0))/rev;
    tee('per rev: lump-sum %+0.3f = levy %+0.3f + tilt %+0.3f [resid %+0.1e]\n', ...
        eLS, eLV, eTL, eLS-(eLV+eTL));
    % policy-flow vs distribution split of the tilt + HtM decomposition
    dS_pol  = sum((aggT.bchoice(:) - agg0.bchoice(:)) .* agg0.dist(:));
    dS_dist = sum(aggT.bchoice(:) .* (aggT.dist(:) - agg0.dist(:)));
    tee('tilt split: policy-flow %+0.4f + distribution %+0.4f = %+0.4f\n', ...
        dS_pol, dS_dist, SbTL - Sb0);
    grp = htm_groups(agg0.dist, eqb.q, p, htm_b, whtm_k);
    dflow = (aggT.bchoice - agg0.bchoice) .* agg0.dist;
    tee('policy-flow by group: WHtM %+0.5f | poor-HtM %+0.5f | non-HtM %+0.5f\n', ...
        sum(dflow(grp.whtm)), sum(dflow(grp.phtm)), sum(dflow(grp.non)));
    tee(['=> with realistic bond ownership, does the wealthy hand-to-mouth\n' ...
         '   group carry a nonzero direct response? (the one-asset direct\n' ...
         '   term was ~0; this line is the referee-facing answer)\n\n']);
else
    eLS = NaN; eLV = NaN; eTL = NaN; dS_pol = NaN; dS_dist = NaN;
    tee('liquid-margin block failed (a leg did not converge)\n\n');
end

% =====================================================================
% (4) LAMBDA SENSITIVITY + frictionless consistency check
% =====================================================================
tee('----- (4) lambda sensitivity + lambda->1 consistency -----\n');
lams = [0.15 1/3 0.60];
if FAST, lams = [1/3]; end %#ok<NBRAK>
for il = 1:numel(lams)
    pl = p; pl.lambda_adj = lams(il);
    el = solve_kv_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, pl);
    if el.ok
        Hl = htm_stats(el.dist, el.q, pl, htm_b, whtm_k);
        tee('lambda=%.2f: S_b=%.4f q=%.4f P=%.4f WHtM=%.3f\n', ...
            lams(il), el.Sb, el.q, el.P, Hl.whtm);
    else
        tee('lambda=%.2f: FAILED (%s)\n', lams(il), el.msg);
    end
end
% lambda -> 1 at fixed baseline prices vs the Step 0 EGM household
pl = p; pl.lambda_adj = 0.999;
[SbF, aggF] = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, 0, pl, []);
pe0 = p; pe0.eGrid = (1 - D0)*p.eGrid;
pe0.xGrid = p.xGridA;
ux2 = linspace(0,1,120)'; pe0.aGrid2 = 1e-4 + (0.92*xmax - 1e-4)*(ux2.^2.2);
pe0.tol_pol = 1e-7; pe0.maxit_pol = 800;
[pB0, pK0, ~, ~, ~, dg0] = solve_household_twoasset_egm(r_b, eqb.q, d_div, eqb.tau, pe0, []);
if dg0.converged && isfinite(SbF)
    [d0, dd0] = stationary_distribution_twoasset(pB0, pK0, r_b, eqb.q, d_div, eqb.tau, pe0);
    if dd0.converged
        SbEGM = sum(sum(pB0 .* d0));
        tee('lambda->1 check: KV S_b=%.4f vs frictionless EGM S_b=%.4f (gap %.2e)\n', ...
            SbF, SbEGM, abs(SbF - SbEGM));
    end
end

save(fullfile(projdir,'output','twoasset_kv.mat'), 'eqb', 'EXK', 'omega', ...
     'H', 'p', 'r_b', 'd_div', 'D0', 'Gg', 'eLS', 'eLV', 'eTL', ...
     'dS_pol', 'dS_dist', 'htm_b', 'whtm_k');
fclose(fid);
fprintf('[main_twoasset_kv] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function eq = solve_kv_eq(rb, d, D, g, use_levy, Bnom, Kbar, p)
% full stationary (P, q, tau) equilibrium of the variant-(b) economy
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
                'tau',NaN,'dist',[],'Vcache',[]);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau0 = rb*1.10 + (~use_levy)*g;
    Vc = [];
    qlo = 0.15*d/max(rb,5e-3); qhi = 1.5*d/max(rb,5e-3);
    qs = linspace(qlo, qhi, 7); fs = nan(size(qs)); tau_m = tau0;
    for i = 1:numel(qs)
        [fs(i), tau_m, ~, ~, ~, Vc] = eval_q(qs(i), tau_m, Vc);
    end
    kk = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
              sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket (Sk-K in [%+.3f, %+.3f])', min(fs), max(fs));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fs(kk);
    m = a; Sb_m = NaN; dist_m = []; %#ok<NASGU>
    for it = 1:35
        m = 0.5*(a+b);
        [fm, tau_m, Sb_m, dist_m, ~, Vc] = eval_q(m, tau_m, Vc);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 2e-4 || (b-a) < 1e-5, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb_m) || Sb_m <= 0, eq.msg = 'non-finite end state'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb_m; eq.tau = tau_m;
    eq.P = Bnom/Sb_m; eq.dist = dist_m; eq.Vcache = Vc;

    function [f, tt, Sb, dist, Sk, Vc2] = eval_q(qq, tinit, Vc2)
        tt = tinit; Sb = NaN; Sk = NaN; dist = [];
        for itt = 1:25
            [soli, dgi] = solve_household_twoasset_kv(rb, qq, d, tt, pe, Vc2);
            if ~dgi.converged, f = NaN; return; end
            Vc2 = soli.V;
            [dist, ddi] = stationary_distribution_twoasset_kv(soli, rb, qq, d, tt, pe);
            if ~ddi.converged, f = NaN; return; end
            [Sb, Sk] = kv_aggregates(soli, dist, rb, qq, d, tt, pe);
            tgt = rb*Sb + (~use_levy)*g;
            if abs(tgt - tt) < 1e-5, break; end
            tt = 0.5*tt + 0.5*tgt;
        end
        f = Sk - Kbar;
    end
end

function [Sb, agg] = kv_liquid(rb, q, d, tau, D, vth, p, Vc)
% household + distribution at FIXED prices; returns aggregate liquid demand
% and the per-node effective bond choice / distribution for decompositions
    pe = p; pe.eGrid = (1 - D)*p.eGrid;
    if vth ~= 0, pe.eGrid = (1 - vth)*pe.eGrid; end
    Sb = NaN; agg = struct('bchoice',[],'kchoice',[],'dist',[]);
    [sol, dg] = solve_household_twoasset_kv(rb, q, d, tau, pe, Vc);
    if ~dg.converged, return; end
    [dist, dd] = stationary_distribution_twoasset_kv(sol, rb, q, d, tau, pe);
    if ~dd.converged, return; end
    [Sb, ~, bch, kch] = kv_aggregates(sol, dist, rb, q, d, tau, pe);
    agg.bchoice = bch; agg.kchoice = kch; agg.dist = dist;
end

function [Sb, Sk, bch, kch] = kv_aggregates(sol, dist, rb, q, d, tau, pe)
% effective end-of-period asset choices: lambda-weighted adjust/no-adjust
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb, nk, ne); kch = zeros(nb, nk, ne);
    for ie = 1:ne
        xbk = ynet(ie) + Rb*bG + (q + d)*kG';
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear', 'extrap');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear', 'extrap');
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(kG', nb, 1);
    end
    Sb = sum(bch(:) .* dist(:));
    Sk = sum(kch(:) .* dist(:));
end

function H = htm_stats(dist, q, p, htm_b, whtm_k)
% hand-to-mouth decomposition + wealth concentration on (b,k,e)
    bG = p.bGrid(:); kG = p.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(p.eGrid);
    [BB, KK] = ndgrid(bG, kG);
    isb = BB <= htm_b; isk = q*KK >= whtm_k;
    mh = 0; mw = 0; mp = 0;
    M = zeros(nb*nk, 1);
    for ie = 1:ne
        Mie = dist(:,:,ie);
        mh = mh + sum(Mie(isb));
        mw = mw + sum(Mie(isb & isk));
        mp = mp + sum(Mie(isb & ~isk));
        M = M + Mie(:);
    end
    H = struct('htm', mh, 'whtm', mw, 'phtm', mp);
    wealth = BB(:) + q*KK(:);
    [ws, ord] = sort(wealth); ms = M(ord);
    cm = cumsum(ms)/sum(ms); tw = sum(ws.*ms);
    H.top10 = sum(ws(cm >= 0.90).*ms(cm >= 0.90))/tw;
    H.top1  = sum(ws(cm >= 0.99).*ms(cm >= 0.99))/tw;
end

function grp = htm_groups(dist, q, p, htm_b, whtm_k)
% logical masks over the full (b,k,e) array for the three HtM groups
    bG = p.bGrid(:); kG = p.kGrid(:); ne = numel(p.eGrid);
    [BB, KK] = ndgrid(bG, kG);
    isb = BB <= htm_b; isk = q*KK >= whtm_k;
    grp = struct();
    grp.whtm = repmat(isb & isk,  1, 1, ne);
    grp.phtm = repmat(isb & ~isk, 1, 1, ne);
    grp.non  = repmat(~isb,       1, 1, ne);
    assert(isequal(size(grp.whtm), size(dist)));
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    fprintf(fid, varargin{:});
end
