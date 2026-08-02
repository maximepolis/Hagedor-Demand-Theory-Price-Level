% MAIN_TWOASSET_KV  Two-asset DTPL, variant (b): infrequent k-adjustment
% (wealthy hand-to-mouth), SPEED-REBUILT version.
%
% What changed vs the first version (which could not finish overnight):
%   * household solver is a vectorized discrete-choice VFI (candidate
%     portfolio values computed once per sweep; one matrix max per state
%     block; deterministic map, so VFI contracts cleanly) -- see
%     solve_household_twoasset_kv;
%   * invariant distribution is a sparse-matrix power iteration;
%   * the lump-sum tax fixed point uses FULL updates (its contraction
%     factor is ~ r_b * dS_b/dtau ~ 0.06, so damping was waste) with an
%     oscillation safeguard;
%   * chi_b is calibrated by secant in logs (a handful of equilibria, not
%     ~30 bisection steps), and the value function is warm-started ACROSS
%     equilibria, not just within one;
%   * the lambda sweep runs under parfor (parallel with a pool, plain
%     serial otherwise);
%   * progress lines print continuously with elapsed time, so a stalled
%     run is visible immediately.
%
% USAGE   >> FAST = true; main_twoasset_kv     % smoke test (minutes)
%         >> clear; main_twoasset_kv           % full run
%
% OUTPUT  output/twoasset_kv.mat, output/tables/twoasset_kv.txt
% STATUS: scaffolded, untested pending a MATLAB run.

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
p.zeta_b = 2.0; p.chi_b = 0.02;
p.lambda_adj = 1/3;
p.tol_vfi = 1e-6;  p.maxit_vfi = 600;
p.tol_dist = 1e-11; p.maxit_dist = 50000;      % sparse matvecs: cheap
nb = 70; nk = 35; nx = 140; nac = 110; nsh = 25;
bmax = 25; kmax = 40; xmax = 90;
if FAST, nb = 45; nk = 22; nx = 90; nac = 70; nsh = 17; end
ub  = linspace(0,1,nb)';  p.bGrid  = 1e-4 + (bmax - 1e-4)*(ub.^2.2);
uk  = linspace(0,1,nk)';  p.kGrid  = kmax*(uk.^2.2);
uxA = linspace(0,1,nx)';  p.xGridA = 0.05 + (xmax - 0.05)*(uxA.^2.2);
uac = linspace(0,1,nac)'; p.acGrid = 1e-4 + (0.92*xmax - 1e-4)*(uac.^2.2);
p.sGrid = linspace(1/nsh, 1, nsh);             % liquid shares (s>0: v-Inada)

% policy / climate
D0   = 0.06;
r_b  = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom;  b_targ = 1.10;  d_div = 0.12;  Kbar = 1.0;
Gg   = 0.02 * (Bnom / b_targ);
if exist(calfile,'file') == 2 && isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
    Gg = L.RCAL.Gg_cal;
end
htm_b = 0.02;  whtm_k = 0.50;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'twoasset_kv.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET VARIANT (b), speed-rebuilt. nb=%d nk=%d nx=%d nac=%d ns=%d ne=%d\n', ...
    nb, nk, nx, nac, nsh, numel(p.eGrid));
tee('lambda=%.3f zeta=%.2f r_b=%.4f d=%.3f FAST=%d\n\n', ...
    p.lambda_adj, p.zeta_b, r_b, d_div, FAST);

% =====================================================================
% (1) BASELINE: secant chi calibration, (P, q), HtM decomposition
% =====================================================================
tee('----- (1) baseline equilibrium (chi secant) -----\n');
Vshare = [];                                    % V warm start across EVERYTHING
lc = log(0.02); eqb = [];
lsb_prev = NaN; lc_prev = NaN;
for itc = 1:12
    p.chi_b = exp(lc);
    [eqc, Vshare] = solve_kv_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, p, Vshare, t0);
    if ~eqc.ok
        fprintf('[%6.0fs] chi=%.5f FAILED (%s); trying larger chi\n', toc(t0), p.chi_b, eqc.msg);
        lc = lc + 0.7; continue;
    end
    eqb = eqc;
    err = log(eqc.Sb) - log(b_targ);
    fprintf('[%6.0fs] chi=%.5f  S_b=%.4f  err=%+.4f\n', toc(t0), p.chi_b, eqc.Sb, err);
    if abs(err) < 5e-3, break; end
    if isfinite(lsb_prev) && abs(err - lsb_prev) > 1e-8
        step = -err * (lc - lc_prev)/(err - lsb_prev);   % secant
        step = max(min(step, 1.5), -1.5);
    else
        step = -sign(err)*0.5;                           % first move
    end
    lc_prev = lc; lsb_prev = err; lc = lc + step;
end
assert(~isempty(eqb) && eqb.ok, 'variant-(b) baseline failed');
omega = eqb.Sb/(eqb.Sb + eqb.q*Kbar);
tee('chi_b=%.5f  S_b=%.4f (target %.2f)  q=%.4f  P=%.4f  omega=%.3f\n', ...
    p.chi_b, eqb.Sb, b_targ, eqb.q, eqb.P, omega);
H = htm_stats(eqb.dist, eqb.q, p, htm_b, whtm_k);
tee('HtM (b<%.2f): total %.3f | wealthy (qk>%.2f): %.3f | poor: %.3f\n', ...
    htm_b, H.htm, whtm_k, H.whtm, H.phtm);
tee('wealth shares: top10 %.2f top1 %.2f\n\n', H.top10, H.top1);

% =====================================================================
% (2) FINANCING: lump-sum vs levy (independent -> parfor-able, but each
%     warm-starts best from the baseline V, so run serially warm)
% =====================================================================
tee('----- (2) financing incidence -----\n');
g_real = Gg / eqb.P;
EXK = struct('name',{},'P',{},'q',{},'Sb',{},'dlnP',{});
runs = {struct('name','lump-sum','levy',0), struct('name','levy','levy',1)};
for k = 1:numel(runs)
    [ek, Vshare] = solve_kv_eq(r_b, d_div, D0, g_real, runs{k}.levy, Bnom, Kbar, p, Vshare, t0);
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
        tee('vs Step 0: ls %+0.4f -> %+0.4f | levy %+0.4f -> %+0.4f\n', ...
            S0r.EX(1).dlnP, EXK(1).dlnP, S0r.EX(2).dlnP, EXK(2).dlnP);
    end
end
if numel(EXK) >= 2
    tee('sign contrast survives: %d\n', sign(EXK(1).dlnP) ~= sign(EXK(2).dlnP));
end
tee('\n');

% =====================================================================
% (3) LIQUID-MARGIN INCIDENCE at fixed prices, by HtM group
% =====================================================================
tee('----- (3) liquid-margin incidence at fixed (q, r_b) -----\n');
dv = 0.01; rev = dv*(1-D0);
[Sb0, agg0] = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, 0, p, Vshare);
[SbLS, ~]   = kv_liquid(r_b, eqb.q, d_div, eqb.tau + rev, D0, 0, p, Vshare);
[SbLV, ~]   = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, dv, p, Vshare);
[SbTL, aggT] = kv_liquid(r_b, eqb.q, d_div, eqb.tau + rev, D0, -dv, p, Vshare);
if all(isfinite([Sb0 SbLS SbLV SbTL]))
    eLS = (log(SbLS)-log(Sb0))/rev; eLV = (log(SbLV)-log(Sb0))/rev;
    eTL = (log(SbTL)-log(Sb0))/rev;
    tee('per rev: lump-sum %+0.3f = levy %+0.3f + tilt %+0.3f [resid %+0.1e]\n', ...
        eLS, eLV, eTL, eLS-(eLV+eTL));
    dS_pol  = sum((aggT.bchoice(:) - agg0.bchoice(:)) .* agg0.dist(:));
    dS_dist = sum(aggT.bchoice(:) .* (aggT.dist(:) - agg0.dist(:)));
    tee('tilt split: policy-flow %+0.4f + distribution %+0.4f = %+0.4f\n', ...
        dS_pol, dS_dist, SbTL - Sb0);
    grp = htm_groups(agg0.dist, eqb.q, p, htm_b, whtm_k);
    dflow = (aggT.bchoice - agg0.bchoice) .* agg0.dist;
    tee('policy-flow by group: WHtM %+0.5f | poor-HtM %+0.5f | non-HtM %+0.5f\n\n', ...
        sum(dflow(grp.whtm)), sum(dflow(grp.phtm)), sum(dflow(grp.non)));
else
    eLS = NaN; eLV = NaN; eTL = NaN; dS_pol = NaN; dS_dist = NaN;
    tee('liquid-margin block failed (a leg did not converge)\n\n');
end

% =====================================================================
% (4) LAMBDA SENSITIVITY (parfor) + lambda->1 consistency check
% =====================================================================
tee('----- (4) lambda sensitivity + lambda->1 consistency -----\n');
lams = [0.15 0.60];                             % baseline 1/3 already done
if FAST, lams = []; end
if ~isempty(lams)
    res = cell(numel(lams), 1);
    parfor il = 1:numel(lams)
        pl = p; pl.lambda_adj = lams(il);
        el = solve_kv_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, pl, [], []);
        res{il} = el;
    end
    for il = 1:numel(lams)
        el = res{il};
        if el.ok
            pl = p; pl.lambda_adj = lams(il);
            Hl = htm_stats(el.dist, el.q, pl, htm_b, whtm_k);
            tee('lambda=%.2f: S_b=%.4f q=%.4f P=%.4f WHtM=%.3f\n', ...
                lams(il), el.Sb, el.q, el.P, Hl.whtm);
        else
            tee('lambda=%.2f: FAILED (%s)\n', lams(il), el.msg);
        end
    end
end
tee('lambda=%.2f: S_b=%.4f q=%.4f P=%.4f WHtM=%.3f (baseline)\n', ...
    p.lambda_adj, eqb.Sb, eqb.q, eqb.P, H.whtm);
% lambda -> 1 at fixed baseline prices vs the frictionless Step 0 EGM
pl = p; pl.lambda_adj = 0.999;
[SbF, ~] = kv_liquid(r_b, eqb.q, d_div, eqb.tau, D0, 0, pl, []);
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
function [eq, Vc] = solve_kv_eq(rb, d, D, g, use_levy, Bnom, Kbar, p, Vc, t0)
% full stationary (P, q, tau) equilibrium; Vc warm-starts and is returned
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
                'tau',NaN,'dist',[]);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau_w = rb*1.10 + (~use_levy)*g;
    qlo = 0.15*d/max(rb,5e-3); qhi = 1.5*d/max(rb,5e-3);
    qs = linspace(qlo, qhi, 5); fs = nan(size(qs));
    for i = 1:numel(qs)
        [fs(i), tau_w, ~, ~, ~, Vc] = eval_q(qs(i), tau_w, Vc);
        fprintf('[%6.0fs]   scan q=%.3f  Sk-K=%+.4f  tau=%.4f\n', ...
                elt(t0), qs(i), fs(i), tau_w);
    end
    kk = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
              sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket (Sk-K in [%+.3f, %+.3f])', min(fs), max(fs));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fs(kk);
    m = a; Sb_m = NaN; dist_m = [];
    for it = 1:30
        m = 0.5*(a+b);
        [fm, tau_w, Sb_m, dist_m, ~, Vc] = eval_q(m, tau_w, Vc);
        if ~isfinite(fm), b = m; continue; end
        fprintf('[%6.0fs]   bisect q=%.4f  Sk-K=%+.5f\n', elt(t0), m, fm);
        if abs(fm) < 5e-4 || (b-a) < 1e-4, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb_m) || Sb_m <= 0, eq.msg = 'non-finite end state'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb_m; eq.tau = tau_w;
    eq.P = Bnom/Sb_m; eq.dist = dist_m;

    function [f, tt, Sb, dist, Sk, Vc2] = eval_q(qq, tinit, Vc2)
        tt = tinit; Sb = NaN; Sk = NaN; dist = []; tprev = NaN; fprev = NaN;
        for itt = 1:12
            [soli, dgi] = solve_household_twoasset_kv(rb, qq, d, tt, pe, Vc2);
            if ~dgi.converged, f = NaN; return; end
            Vc2 = soli.V;
            [dist, ddi] = stationary_distribution_twoasset_kv(soli, rb, qq, d, tt, pe);
            if ~ddi.converged, f = NaN; return; end
            [Sb, Sk] = kv_aggregates(soli, dist, rb, qq, d, tt, pe);
            tgt = rb*Sb + (~use_levy)*g;
            r1 = tgt - tt;
            if abs(r1) < 1e-6, break; end
            % full update (contraction ~ rb*dSb/dtau ~ 0.06); damp only if
            % the residual oscillates and grows
            if isfinite(fprev) && sign(r1) ~= sign(fprev) && abs(r1) > abs(fprev)
                tt = 0.5*(tt + tgt);
            else
                tprev = tt; fprev = r1; tt = tgt; %#ok<NASGU>
            end
        end
        f = Sk - Kbar;
    end
end

function [Sb, agg] = kv_liquid(rb, q, d, tau, D, vth, p, Vc)
% household + distribution at FIXED prices
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
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb, nk, ne); kch = zeros(nb, nk, ne);
    for ie = 1:ne
        xbk = ynet(ie) + Rb*bG + (q + d)*kG';
        xbk = min(max(xbk, pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(kG', nb, 1);
    end
    Sb = sum(bch(:) .* dist(:));
    Sk = sum(kch(:) .* dist(:));
end

function H = htm_stats(dist, q, p, htm_b, whtm_k)
    bG = p.bGrid(:); kG = p.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(p.eGrid);
    [BB, KK] = ndgrid(bG, kG);
    isb = BB <= htm_b; isk = q*KK >= whtm_k;
    mh = 0; mw = 0; mp = 0; M = zeros(nb*nk, 1);
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
    bG = p.bGrid(:); kG = p.kGrid(:); ne = numel(p.eGrid);
    [BB, KK] = ndgrid(bG, kG);
    isb = BB <= htm_b; isk = q*KK >= whtm_k;
    grp = struct();
    grp.whtm = repmat(isb & isk,  1, 1, ne);
    grp.phtm = repmat(isb & ~isk, 1, 1, ne);
    grp.non  = repmat(~isb,       1, 1, ne);
    assert(isequal(size(grp.whtm), size(dist)));
end

function s = elt(t0)
% elapsed seconds, robust to empty/invalid timer handles (parfor workers)
    s = 0;
    if ~isempty(t0)
        try s = toc(t0); catch, s = 0; end
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    fprintf(fid, varargin{:});
end
