% MAIN_TWOASSET_OWNERSHIP  Ownership-calibrated two-asset economy (internal
% report R2): households hold only the DIRECTLY-HELD slice of public debt,
% the rest sits inside the illiquid fund, and the income process carries the
% superstar state -- the recalibration that makes "who holds the nominal
% claim" match the data in level and distribution.
%
% CHANGES vs Step 0:
%   * Intermediation wedge: households clear iota_H of real debt directly,
%       int b dOmega = iota_H * B / P   (pins P);
%     the fund holds (1-iota_H)*B/P plus the capital stock, so the illiquid
%     asset's per-share dividend is ENDOGENOUS to P:
%       div(P) = d + r_b * (1-iota_H) * (B/P) / Kbar,
%     and a price-level change revalues the fund's bond book (illiquid
%     wealth), not only direct holdings -- the incidence channel the
%     uniform-ownership calibration suppressed.
%   * Direct liquid target: b_targ_H = 0.30 of mean income (SCF-scale
%     deposits + direct Treasuries; parameter, documented) instead of the
%     full 1.10 debt stock. iota_H = b_targ_H / 1.10.
%   * Superstar income state (Castaneda et al.), config read from the
%     one-asset fit (wealth_fit_results.mat) when available.
%
% REPORTS baseline (P, q), omega, HtM decomposition (does WHtM turn on?),
% top wealth shares, and the lump-sum vs levy financing experiment.
%
% USAGE   >> parpool; clear; FAST = true; main_twoasset_ownership
% OUTPUT  output/twoasset_ownership.mat, output/tables/twoasset_ownership.txt
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
% ---- income process WITH the superstar state ----
ss = struct('mult', 10, 'p_in', 0.01, 'p_out', 0.10);   % defaults
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
p.zeta_b = 2.0; p.chi_b = 0.02;
p.tol_pol = 1e-7; p.maxit_pol = 800;
p.tol_dist = 1e-10; p.maxit_dist = 20000;
nx = 220; na2 = 180; xmax = 160;                % superstar tail needs headroom
if FAST, nx = 130; na2 = 110; xmax = 110; end
u  = linspace(0,1,nx)';  p.xGrid  = 0.05 + (xmax-0.05)*(u.^2.4);
u2 = linspace(0,1,na2)'; p.aGrid2 = 1e-4 + (0.92*xmax-1e-4)*(u2.^2.4);

D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; Kbar = 1.0; d_base = 0.12;
b_debt   = 1.10;                                 % total public debt / income
b_targ_H = 0.30;                                 % DIRECT household liquid target
iota_H   = b_targ_H / b_debt;
Gg = 0.02 * (Bnom / b_debt);
htm_b = 0.02; whtm_k = 0.50;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'twoasset_ownership.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('OWNERSHIP-CALIBRATED TWO-ASSET ECONOMY. nx=%d ne=%d FAST=%d\n', ...
    nx, numel(p.eGrid), FAST);
tee('iota_H=%.3f (direct liquid target %.2f of income; total debt %.2f)\n', ...
    iota_H, b_targ_H, b_debt);
tee('superstar: mult=%.1f p_in=%.3f p_out=%.3f\n\n', ss.mult, ss.p_in, ss.p_out);

% ---- baseline: calibrate chi to the DIRECT liquid target ----
tee('----- (1) baseline -----\n');
[p.chi_b, eq0] = calib_chi_own(r_b, d_base, D0, 0, 0, Bnom, Kbar, b_targ_H, iota_H, p, t0);
assert(~isempty(eq0) && eq0.ok, 'ownership baseline failed');
omega = eq0.Sb/(eq0.Sb + eq0.q*Kbar);
tee('chi_b=%.5f  S_b=%.4f (target %.2f)  q=%.4f  P=%.4f  omega=%.3f  div=%.4f\n', ...
    p.chi_b, eq0.Sb, b_targ_H, eq0.q, eq0.P, omega, eq0.div);
H = htm_own(eq0, p, htm_b, whtm_k);
tee('HtM (b<%.2f): total %.3f | wealthy (qk>%.2f): %.3f | poor: %.3f\n', ...
    htm_b, H.htm, whtm_k, H.whtm, H.phtm);
tee('wealth shares: top10 %.2f top1 %.2f\n\n', H.top10, H.top1);

% ---- financing experiment ----
tee('----- (2) financing incidence (lump-sum vs levy) -----\n');
g_real = Gg / eq0.P;
eLS = solve_own(r_b, d_base, D0, g_real, 0, Bnom, Kbar, iota_H, p);
eLV = solve_own(r_b, d_base, D0, g_real, 1, Bnom, Kbar, iota_H, p);
EXO = struct('name',{},'P',{},'q',{},'dlnP',{});
if eLS.ok
    EXO(end+1) = struct('name','lump-sum','P',eLS.P,'q',eLS.q,'dlnP',log(eLS.P/eq0.P)); %#ok<SAGROW>
    tee('lump-sum P=%.4f dlnP=%+0.4f  q=%.4f\n', eLS.P, log(eLS.P/eq0.P), eLS.q);
else, tee('lump-sum FAILED (%s)\n', eLS.msg);
end
if eLV.ok
    EXO(end+1) = struct('name','levy','P',eLV.P,'q',eLV.q,'dlnP',log(eLV.P/eq0.P)); %#ok<SAGROW>
    tee('levy     P=%.4f dlnP=%+0.4f  q=%.4f\n', eLV.P, log(eLV.P/eq0.P), eLV.q);
else, tee('levy FAILED (%s)\n', eLV.msg);
end
if numel(EXO) >= 2
    tee('sign contrast survives: %d\n', sign(EXO(1).dlnP) ~= sign(EXO(2).dlnP));
end
tee(['\nReading: with iota_H < 1 the direct revaluation base shrinks by the\n' ...
     'intermediation wedge while the fund''s bond book revalues into ILLIQUID\n' ...
     'wealth; compare dlnP and the HtM shares against the uniform-ownership\n' ...
     'Step 0 to see how much of the incidence answer ownership carries.\n']);

save(fullfile(projdir,'output','twoasset_ownership.mat'), 'eq0', 'EXO', ...
     'omega', 'H', 'p', 'iota_H', 'b_targ_H', 'ss', 'r_b', 'd_base', 'D0', 'Gg');
fclose(fid);
fprintf('[main_twoasset_ownership] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [chi_star, eq0] = calib_chi_own(rb, d, D, g, lv, Bnom, Kbar, btH, iota, p, t0)
    lc = log(0.01); lc_p = NaN; e_p = NaN; eq0 = []; chi_star = exp(lc);
    for itc = 1:14
        p.chi_b = exp(lc);
        eqc = solve_own(rb, d, D, g, lv, Bnom, Kbar, iota, p);
        if ~eqc.ok, lc = lc + 0.5; continue; end
        eq0 = eqc; chi_star = p.chi_b;
        err = log(eqc.Sb) - log(btH);
        fprintf('[%5.0fs] chi=%.5f S_b=%.4f err=%+.4f\n', toc(t0), p.chi_b, eqc.Sb, err);
        if abs(err) < 5e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.2),-1.2);
        else, step = -sign(err)*0.4; end
        lc_p = lc; e_p = err; lc = lc + step;
    end
end

function eq = solve_own(rb, d, D, g, use_levy, Bnom, Kbar, iota, p)
% (P, q, tau, div) equilibrium with the intermediation wedge:
%   bond market: S_b = iota * B / P  ->  P = iota * B / S_b
%   fund dividend: div(P) = d + rb*(1-iota)*(B/P)/Kbar (endogenous to P)
%   tree market: S_k(q) = Kbar
% Inner loop iterates (tau, div) jointly with warm-started policies.
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'tau',NaN, ...
                'div',NaN,'dist',[],'polB',[],'polK',[]);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau = rb*1.10 + (~use_levy)*g;               % interest on TOTAL debt
    div = d + rb*(1-iota)*1.10/Kbar;             % init at target debt level
    C = [];
    qlo = 0.15*div/max(rb,5e-3); qhi = 1.8*div/max(rb,5e-3);
    qs = linspace(qlo, qhi, 6); fq = nan(size(qs));
    for i = 1:numel(qs)
        [fq(i), tau, div, ~, C] = evq(qs(i), tau, div, C);
    end
    kk = find(isfinite(fq(1:end-1)) & isfinite(fq(2:end)) & ...
              sign(fq(1:end-1)) ~= sign(fq(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket (Sk-K in [%+.3f,%+.3f])', min(fq), max(fq));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fq(kk); m = a; Sb = NaN;
    for it = 1:40
        m = 0.5*(a+b);
        [fm, tau, div, Sb, C, dist, pB, pK] = evq(m, tau, div, C);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 5e-4 || (b-a) < 1e-4, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, eq.msg = 'non-finite end'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.div = div;
    eq.P = iota*Bnom/Sb; eq.dist = dist; eq.polB = pB; eq.polK = pK;

    function [f, tt, dv, Sb, C, dist, pB, pK] = evq(qq, tinit, dvinit, C)
        tt = tinit; dv = dvinit; Sb = NaN; Sk = NaN; rprev = NaN;
        dist = []; pB = []; pK = [];
        for itt = 1:20
            [pB, pK, ~, Cn, ~, dg] = solve_household_twoasset_egm(rb, qq, dv, tt, pe, C);
            if ~dg.converged, f = NaN; return; end
            C = Cn;
            [dist, dd] = stationary_distribution_twoasset(pB, pK, rb, qq, dv, tt, pe);
            if ~dd.converged, f = NaN; return; end
            Sb = sum(sum(pB .* dist)); Sk = sum(sum(pK .* dist));
            P  = iota*Bnom/max(Sb, 1e-9);
            tgt_tau = rb*(Bnom/P) + (~use_levy)*g;   % interest on TOTAL real debt
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

function H = htm_own(eq, p, htm_b, whtm_k)
% HtM/wealth stats on the (x,e) distribution using end-of-period choices
    dist = eq.dist; pB = eq.polB; pK = eq.polK; q = eq.q;
    w = dist(:)/sum(dist(:));
    bv = pB(:); kv = pK(:);
    isb = bv <= htm_b; isk = q*kv >= whtm_k;
    H = struct('htm', sum(w(isb)), 'whtm', sum(w(isb & isk)), ...
               'phtm', sum(w(isb & ~isk)));
    wealth = bv + q*kv;
    [ws, io] = sort(wealth); wsr = w(io);
    cw = cumsum(wsr); tw = sum(ws.*wsr);
    H.top10 = sum(ws(cw >= 0.90).*wsr(cw >= 0.90))/tw;
    H.top1  = sum(ws(cw >= 0.99).*wsr(cw >= 0.99))/tw;
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
