% MAIN_TWOASSET_OWNERSHIP_KV  The combination that should finally produce
% WEALTHY HAND-TO-MOUTH households: the ownership recalibration (R2) --
% intermediation wedge, realistic direct liquid target, superstar income
% state -- run ON the infrequent-adjustment (Kaplan-Violante) household.
%
% The frictionless ownership run (main_twoasset_ownership) fixed wealth
% concentration and the liquid share but left WHtM = 0, because without an
% adjustment friction no household is stuck with low liquid + high illiquid.
% This driver supplies the friction: k rebalances only with probability
% lambda, so households accumulate illiquid wealth they cannot instantly
% convert -- the wealthy-hand-to-mouth configuration -- while the
% intermediation wedge keeps the DIRECT liquid claim (the revaluation base)
% at a realistic, skewed level.
%
% Equilibrium (as in main_twoasset_ownership, KV household/distribution):
%   bond:  int b dOmega = iota_H * B / P     (pins P)
%   fund dividend:  div(P) = d + r_b (1-iota_H)(B/P)/Kbar   (endogenous)
%   tree:  int k dOmega = Kbar               (pins q)
%
% USAGE   >> parpool; clear; FAST = true; main_twoasset_ownership_kv
% OUTPUT  output/twoasset_ownership_kv.mat, output/tables/twoasset_ownership_kv.txt
% STATUS: scaffolded, untested pending a MATLAB run.

clearvars -except FAST; close all; clc;
rng(20260723, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();

p = struct();
p.sigma = pg.sigma; p.beta = pg.beta;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), p.beta = L.RCAL.beta_star; end
end
% superstar income state
ss = struct('mult', 12, 'p_in', 0.006, 'p_out', 0.06);
wff = fullfile(projdir, 'output', 'wealth_fit_results.mat');
if exist(wff,'file') == 2
    Wf = load(wff, 'best');
    if isfield(Wf,'best')
        if isfield(Wf.best,'mult'),  ss.mult  = Wf.best.mult;  end
        if isfield(Wf.best,'p_in'),  ss.p_in  = Wf.best.p_in;  end
        if isfield(Wf.best,'p_out'), ss.p_out = Wf.best.p_out; end
    end
end
[eG2, Pi2, st2] = add_superstar_state(pg.eGrid(:), pg.Pi, ss);
p.eGrid = eG2(:)'; p.Pi = Pi2; p.stationary_e = st2;
p.zeta_b = 2.0; p.chi_b = 0.02; p.lambda_adj = 1/3;
p.tol_vfi = 1e-6; p.maxit_vfi = 500;
p.tol_dist = 1e-11; p.maxit_dist = 50000;
p.gold_outer = 0; p.gold_inner = 0;             % unused by the discrete solver
nb = 70; nk = 40; nx = 150; nac = 110; nsh = 25;
bmax = 12; kmax = 80; xmax = 160;               % superstar illiquid headroom
if FAST, nb = 48; nk = 26; nx = 100; nac = 74; nsh = 18; end
ub  = linspace(0,1,nb)';  p.bGrid  = 1e-4 + (bmax-1e-4)*(ub.^2.4);
uk  = linspace(0,1,nk)';  p.kGrid  = kmax*(uk.^2.4);
uxA = linspace(0,1,nx)';  p.xGridA = 0.05 + (xmax-0.05)*(uxA.^2.4);
uac = linspace(0,1,nac)'; p.acGrid = 1e-4 + (0.92*xmax-1e-4)*(uac.^2.4);
p.sGrid = linspace(1/nsh, 1, nsh);

D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; Kbar = 1.0; d_base = 0.12;
b_debt = 1.10; b_targ_H = 0.30; iota_H = b_targ_H/b_debt;
Gg = 0.02 * (Bnom / b_debt);
htm_b = 0.02; whtm_k = 0.50;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'twoasset_ownership_kv.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('OWNERSHIP + INFREQUENT ADJUSTMENT. nb=%d nk=%d nx=%d ne=%d lambda=%.2f FAST=%d\n', ...
    nb, nk, nx, numel(p.eGrid), p.lambda_adj, FAST);
tee('iota_H=%.3f (direct target %.2f of income); superstar mult=%.1f p_in=%.3f\n\n', ...
    iota_H, b_targ_H, ss.mult, ss.p_in);

% ---- baseline: calibrate chi to the direct liquid target ----
tee('----- (1) baseline -----\n');
[p.chi_b, eq0] = calib_chi(r_b, d_base, D0, 0, 0, Bnom, Kbar, b_targ_H, iota_H, p, t0);
assert(~isempty(eq0) && eq0.ok, 'ownership-kv baseline failed');
omega = eq0.Sb/(eq0.Sb + eq0.q*Kbar);
tee('chi_b=%.5f S_b=%.4f (target %.2f) q=%.4f P=%.4f omega=%.3f div=%.4f\n', ...
    p.chi_b, eq0.Sb, b_targ_H, eq0.q, eq0.P, omega, eq0.div);
H = htm_bk(eq0.dist, eq0.bch, eq0.kch, eq0.q, htm_b, whtm_k);
tee('HtM (b<%.2f): total %.3f | WEALTHY (qk>%.2f): %.3f | poor: %.3f\n', ...
    htm_b, H.htm, whtm_k, H.whtm, H.phtm);
tee('wealth shares: top10 %.2f top1 %.2f\n\n', H.top10, H.top1);

% ---- financing experiment ----
tee('----- (2) financing incidence (lump-sum vs levy) -----\n');
g_real = Gg / eq0.P;
eLS = solve_own_kv(r_b, d_base, D0, g_real, 0, Bnom, Kbar, iota_H, p);
eLV = solve_own_kv(r_b, d_base, D0, g_real, 1, Bnom, Kbar, iota_H, p);
EXK = struct('name',{},'P',{},'q',{},'dlnP',{});
if eLS.ok
    EXK(end+1) = struct('name','lump-sum','P',eLS.P,'q',eLS.q,'dlnP',log(eLS.P/eq0.P)); %#ok<SAGROW>
    tee('lump-sum P=%.4f dlnP=%+0.4f q=%.4f\n', eLS.P, log(eLS.P/eq0.P), eLS.q);
else, tee('lump-sum FAILED (%s)\n', eLS.msg); end
if eLV.ok
    EXK(end+1) = struct('name','levy','P',eLV.P,'q',eLV.q,'dlnP',log(eLV.P/eq0.P)); %#ok<SAGROW>
    tee('levy     P=%.4f dlnP=%+0.4f q=%.4f\n', eLV.P, log(eLV.P/eq0.P), eLV.q);
else, tee('levy FAILED (%s)\n', eLV.msg); end
if numel(EXK) >= 2
    tee('sign contrast survives: %d\n', sign(EXK(1).dlnP) ~= sign(EXK(2).dlnP));
end
tee(['\nReading: does the ADJUSTMENT FRICTION on top of the ownership wedge\n' ...
     'finally deliver WEALTHY hand-to-mouth households (WHtM > 0)? If so this\n' ...
     'is the calibration for the covariance-on-realistic-bond-ownership\n' ...
     'exercise and the disciplined welfare incidence.\n']);

save(fullfile(projdir,'output','twoasset_ownership_kv.mat'), 'eq0', 'EXK', ...
     'omega', 'H', 'p', 'iota_H', 'b_targ_H', 'ss', 'r_b', 'd_base', 'D0', 'Gg');
fclose(fid);
fprintf('[main_twoasset_ownership_kv] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [chi_star, eq0] = calib_chi(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, t0)
    lc = log(0.01); lc_p = NaN; e_p = NaN; eq0 = []; chi_star = exp(lc);
    for itc = 1:12
        p.chi_b = exp(lc);
        eqc = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, p);
        if ~eqc.ok, lc = lc + 0.5; continue; end
        eq0 = eqc; chi_star = p.chi_b;
        err = log(eqc.Sb) - log(btH);
        fprintf('[%5.0fs] chi=%.5f S_b=%.4f err=%+.4f\n', toc(t0), p.chi_b, eqc.Sb, err);
        if abs(err) < 8e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.2),-1.2);
        else, step = -sign(err)*0.4; end
        lc_p = lc; e_p = err; lc = lc + step;
    end
end

function eq = solve_own_kv(rb, d, D, g, use_levy, Bnom, Kbar, iota, p)
% (P, q, tau, div) equilibrium with the KV household + intermediation wedge
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'tau',NaN, ...
                'div',NaN,'dist',[],'bch',[],'kch',[]);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau = rb*1.10 + (~use_levy)*g;
    div = d + rb*(1-iota)*1.10/Kbar;
    Vc = [];
    qlo = 0.15*div/max(rb,5e-3); qhi = 1.8*div/max(rb,5e-3);
    qs = linspace(qlo, qhi, 6); fq = nan(size(qs));
    for i = 1:numel(qs), [fq(i), tau, div, ~, Vc] = evq(qs(i), tau, div, Vc); end
    kk = find(isfinite(fq(1:end-1)) & isfinite(fq(2:end)) & ...
              sign(fq(1:end-1)) ~= sign(fq(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket (Sk-K in [%+.3f,%+.3f])', min(fq), max(fq));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fq(kk); m = a; Sb = NaN;
    for it = 1:35
        m = 0.5*(a+b);
        [fm, tau, div, Sb, Vc, dist, bch, kch] = evq(m, tau, div, Vc);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 8e-4 || (b-a) < 1e-4, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, eq.msg = 'non-finite end'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.div = div;
    eq.P = iota*Bnom/Sb; eq.dist = dist; eq.bch = bch; eq.kch = kch;

    function [f, tt, dv, Sb, Vc, dist, bch, kch] = evq(qq, tinit, dvinit, Vc)
        tt = tinit; dv = dvinit; Sb = NaN; Sk = NaN; rprev = NaN;
        dist = []; bch = []; kch = [];
        for itt = 1:18
            [sol, dg] = solve_household_twoasset_kv(rb, qq, dv, tt, pe, Vc);
            if ~dg.converged, f = NaN; return; end
            Vc = sol.V;
            [dist, dd] = stationary_distribution_twoasset_kv(sol, rb, qq, dv, tt, pe);
            if ~dd.converged, f = NaN; return; end
            [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, qq, dv, tt, pe);
            P = iota*Bnom/max(Sb, 1e-9);
            tgt_tau = rb*(Bnom/P) + (~use_levy)*g;
            tgt_div = d + rb*(1-iota)*(Bnom/P)/Kbar;
            r1 = tgt_tau - tt;
            if abs(r1) < 1e-6 && abs(tgt_div - dv) < 1e-6, break; end
            if isfinite(rprev) && sign(r1)~=sign(rprev) && abs(r1)>abs(rprev)
                tt = 0.5*(tt + tgt_tau);
            else
                tt = tgt_tau;
            end
            dv = tgt_div; rprev = r1;
        end
        f = Sk - Kbar;
    end
end

function [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, q, d, tau, pe)
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb,nk,ne); kch = zeros(nb,nk,ne);
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(kG', nb, 1);
    end
    Sb = sum(bch(:).*dist(:)); Sk = sum(kch(:).*dist(:));
end

function H = htm_bk(dist, bch, kch, q, htm_b, whtm_k)
    w = dist(:)/sum(dist(:)); bv = bch(:); kv = kch(:);
    isb = bv <= htm_b; isk = q*kv >= whtm_k;
    H = struct('htm',sum(w(isb)),'whtm',sum(w(isb & isk)),'phtm',sum(w(isb & ~isk)));
    wealth = bv + q*kv; [ws, io] = sort(wealth); wsr = w(io);
    cw = cumsum(wsr); tw = sum(ws.*wsr);
    H.top10 = sum(ws(cw>=0.90).*wsr(cw>=0.90))/tw;
    H.top1  = sum(ws(cw>=0.99).*wsr(cw>=0.99))/tw;
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
