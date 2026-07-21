% MAIN_TWOASSET_STEP0  Two-asset DTPL, build-plan Step 0: the frictionless
% bonds-plus-tree economy in which the nominal government liability and the
% real asset clear in SEPARATE markets.
%
% WHAT THIS DELIVERS (build plan, Section 5):
%   1. A baseline stationary equilibrium (P, q) with an interior nominal
%      share: chi_b calibrated so liquid bond demand hits the debt target.
%   2. The financing experiment on the liquid margin: lump-sum vs
%      proportional-levy financing of the same real program, each a full
%      (P, q) equilibrium -> d ln P per instrument, with the one-asset
%      regime numbers printed alongside (how much of the one-asset
%      magnitude the portfolio margin absorbs; does the sign contrast
%      survive).
%   3. The d ln P vs zeta sweep: the price response as a function of the
%      convenience-yield curvature (elastic nominal share at low zeta,
%      rigid share as zeta grows).
%   4. The liquid-margin incidence block: same-revenue lump-sum / levy /
%      regressive-tilt responses of S_b at fixed prices (the audit's
%      direct-vs-distributional split, now on nominal-bond demand), plus
%      the tilt as a full (P, q) equilibrium.
%   5. A solver self-test: EGM (default) vs golden-search VFI on a coarse
%      grid, max |dS_b| and policy sup-norms.
%
% EQUILIBRIUM. r_b is policy-set (i, mu). Given q and taxes, the household
% problem + invariant distribution deliver S_b = int b' dOmega and
% S_k = int k' dOmega. Clearing:
%     S_k(q) = Kbar (=1)      -> q  (bisection; S_k increasing in q via the
%                                    spread makes the bracket scan robust),
%     P      = Bnom / S_b     -> P  (nominal market),
% and the lump-sum tax solves the damped fixed point tau = r_b*S_b(tau) + g.
% Household policies are cached and warm-started across every evaluation.
%
% USAGE   >> main_twoasset_step0
%         >> FAST = true; main_twoasset_step0     % coarse grids, short sweep
%
% OUTPUT  output/twoasset_step0.mat, output/tables/twoasset_step0.txt
%
% STATUS: scaffolded, untested pending a MATLAB run (authored without a
% MATLAB environment). Nothing from this driver is asserted in the paper;
% no result is described as portfolio-validated until the two markets clear
% separately in a converged run.

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

% ---- two-asset parameter block ----
p = struct();
p.sigma  = pg.sigma;
p.beta   = pg.beta;
calfile  = fullfile(projdir, 'output', 'calibrated_results.mat');
have_cal = exist(calfile, 'file') == 2;
if have_cal
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), p.beta = L.RCAL.beta_star; end
end
p.eGrid  = pg.eGrid; p.Pi = pg.Pi; p.stationary_e = pg.stationary_e;
p.tol_vfi   = 1e-6;   p.maxit_vfi  = 600;    % VFI reference solver
p.tol_pol   = 1e-7;   p.maxit_pol  = 800;    % EGM policy iteration
p.tol_dist  = 1e-10;  p.maxit_dist = 20000;
p.zeta_b = 2.0;                       % convenience curvature (KVJ-elastic)
p.chi_b  = 0.02;                      % liquidity weight, recalibrated below
p.hh2_solver = 'egm';                 % 'egm' (default) | 'vfi'
nx       = 220; if FAST, nx = 120; end
xmax     = 60;  if FAST, xmax = 40; end
u        = linspace(0, 1, nx)';
p.xGrid  = 0.05 + (xmax - 0.05) * (u.^2.2);   % cash-on-hand grid (>0)
na2      = 180; if FAST, na2 = 100; end
u2       = linspace(0, 1, na2)';
p.aGrid2 = 1e-4 + (0.92*xmax - 1e-4) * (u2.^2.2);  % total-outlay grid (EGM)

% policy / climate side (medium column, real budget)
D0     = 0.06;
r_b    = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom   = pg.Bnom;
b_targ = 1.10;                        % liquid target: public debt / income
d_div  = 0.12;                        % tree dividend (illiquid income share)
Kbar   = 1.0;
Gg     = 0.02 * (Bnom / b_targ);      % program: 2% of income, nominal appr.
if have_cal && isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
    Gg = L.RCAL.Gg_cal;
end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'twoasset_step0.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET STEP 0. nx=%d, na2=%d, ne=%d, zeta=%.2f, r_b=%.4f, d=%.3f, solver=%s, FAST=%d\n\n', ...
    nx, na2, numel(p.eGrid), p.zeta_b, r_b, d_div, p.hh2_solver, FAST);

% =====================================================================
% (1) BASELINE: calibrate chi_b to the liquid target, solve (P, q)
% =====================================================================
tee('----- (1) baseline equilibrium -----\n');
[p.chi_b, eqb] = calibrate_chi(r_b, d_div, D0, Bnom, Kbar, b_targ, p);
assert(~isempty(eqb) && eqb.ok, 'baseline two-asset equilibrium failed');
omega = eqb.Sb / (eqb.Sb + eqb.q * Kbar);
tee('chi_b=%.5f  S_b=%.4f (target %.2f)  q=%.4f  P=%.4f\n', ...
    p.chi_b, eqb.Sb, b_targ, eqb.q, eqb.P);
tee('liquid share omega = %.3f;  equity-bond spread = %.4f (conv. yield)\n', ...
    omega, (eqb.q + d_div)/eqb.q - (1 + r_b));
tee('tau fixed-point resid = %.2e;  k-market resid = %.2e\n\n', ...
    eqb.tau_resid, eqb.k_resid);

% =====================================================================
% (2) FINANCING EXPERIMENT: lump-sum vs levy, full (P, q) equilibria
% =====================================================================
tee('----- (2) financing incidence on the nominal market -----\n');
g_real = Gg / eqb.P;                              % real program at baseline P
EX = struct('name',{},'P',{},'q',{},'Sb',{},'dlnP',{},'dlnq',{});
runs = {struct('name','lump-sum','g',g_real,'levy',0), ...
        struct('name','levy',    'g',g_real,'levy',1)};
for k = 1:numel(runs)
    ek = solve_twoasset_eq(r_b, d_div, D0, runs{k}.g, runs{k}.levy, Bnom, Kbar, p);
    if ek.ok
        EX(end+1) = struct('name',runs{k}.name,'P',ek.P,'q',ek.q,'Sb',ek.Sb, ...
            'dlnP',log(ek.P/eqb.P),'dlnq',log(ek.q/eqb.q)); %#ok<SAGROW>
        tee('%-9s P=%.4f (dlnP=%+.4f)  q=%.4f (dlnq=%+.4f)  S_b=%.4f\n', ...
            runs{k}.name, ek.P, log(ek.P/eqb.P), ek.q, log(ek.q/eqb.q), ek.Sb);
    else
        tee('%-9s FAILED: %s\n', runs{k}.name, ek.msg);
    end
end
% one-asset comparison, if the regimes run is available
regf = fullfile(projdir, 'output', 'regimes_results.mat');
if exist(regf, 'file') == 2 && numel(EX) >= 2
    R1 = load(regf, 'RREG', 'eq0');
    dlnP1_ls  = log(R1.RREG(1).P / R1.eq0.P);     % one-asset lump-sum
    dlnP1_lev = log(R1.RREG(2).P / R1.eq0.P);     % one-asset levy
    tee('\none-asset comparison:  lump-sum dlnP %+0.4f -> two-asset %+0.4f (ratio %.2f)\n', ...
        dlnP1_ls, EX(1).dlnP, EX(1).dlnP/dlnP1_ls);
    tee('                       levy     dlnP %+0.4f -> two-asset %+0.4f (ratio %.2f)\n', ...
        dlnP1_lev, EX(2).dlnP, EX(2).dlnP/dlnP1_lev);
    tee('sign contrast survives: %d\n', sign(EX(1).dlnP) ~= sign(EX(2).dlnP));
end
tee(['Reading: the two-asset d ln P is the revaluation falling on the\n' ...
     'NOMINAL market only; the ratio to the one-asset number measures how\n' ...
     'much of the one-asset magnitude the portfolio margin absorbs.\n\n']);

% =====================================================================
% (3) d ln P vs zeta (convenience-yield curvature)
% =====================================================================
tee('----- (3) d ln P vs zeta sweep (lump-sum instrument) -----\n');
tee('%-8s %10s %10s %12s %12s %10s\n', 'zeta', 'chi_b', 'omega', 'dlnP(ls)', 'dlnq(ls)', 'status');
zetas = [0.5 1.0 2.0 5.0 10.0];
if FAST, zetas = [1.0 2.0 5.0]; end
ZS = struct('zeta',{},'chi',{},'omega',{},'dlnP',{},'dlnq',{},'ok',{});
for z = 1:numel(zetas)
    pz = p; pz.zeta_b = zetas(z);
    [pz.chi_b, ez0] = calibrate_chi(r_b, d_div, D0, Bnom, Kbar, b_targ, pz);
    if isempty(ez0) || ~ez0.ok
        ZS(end+1) = struct('zeta',zetas(z),'chi',NaN,'omega',NaN, ...
                           'dlnP',NaN,'dlnq',NaN,'ok',false); %#ok<SAGROW>
        tee('%-8.2f %10s %10s %12s %12s %10s\n', zetas(z), '--','--','--','--','no-base');
        continue;
    end
    ez1 = solve_twoasset_eq(r_b, d_div, D0, Gg/ez0.P, 0, Bnom, Kbar, pz);
    okz = ez1.ok;
    dlnP = NaN; dlnq = NaN;
    if okz, dlnP = log(ez1.P/ez0.P); dlnq = log(ez1.q/ez0.q); end
    ZS(end+1) = struct('zeta',zetas(z),'chi',pz.chi_b, ...
        'omega',ez0.Sb/(ez0.Sb + ez0.q*Kbar),'dlnP',dlnP,'dlnq',dlnq,'ok',okz); %#ok<SAGROW>
    tee('%-8.2f %10.5f %10.3f %+12.4f %+12.4f %10s\n', zetas(z), pz.chi_b, ...
        ZS(end).omega, dlnP, dlnq, tern(okz,'ok','fail'));
end
tee(['Reading: as zeta grows the nominal share turns rigid, which PINS\n' ...
     'S_b and drives d ln P toward ZERO -- the rigid-share limit is not\n' ...
     'the one-asset economy (that is the no-tree limit, a different\n' ...
     'experiment). At low zeta the elastic share responds most.\n\n']);

% =====================================================================
% (4) LIQUID-MARGIN INCIDENCE: direct responses of S_b at fixed prices
% =====================================================================
tee('----- (4) liquid-margin incidence (fixed q, fixed r_b, fixed tau base) -----\n');
dv  = 0.01; rev = dv*(1-D0);
pe0 = scale_econ(p, D0, 0);                        % damage-scaled endowments
[Sb0, ~, ok0, polB0, dist0, C0c] = agg_two(r_b, eqb.q, d_div, eqb.tau, pe0, []);
assert(ok0, 'liquid-margin baseline failed');
% same-revenue lump-sum
[SbLS, ~, okA]       = agg_two(r_b, eqb.q, d_div, eqb.tau + rev, pe0, C0c);
% same-revenue levy
peL = scale_econ(p, D0, dv);
[SbLV, ~, okB]       = agg_two(r_b, eqb.q, d_div, eqb.tau, peL, C0c);
% regressive tilt (uniform tax + proportional subsidy)
peT = scale_econ(p, D0, -dv);
[SbTL, ~, okC, polBT, distT] = agg_two(r_b, eqb.q, d_div, eqb.tau + rev, peT, C0c);
if okA && okB && okC
    eLS = (log(SbLS) - log(Sb0))/rev;
    eLV = (log(SbLV) - log(Sb0))/rev;
    eTL = (log(SbTL) - log(Sb0))/rev;
    tee('per unit revenue, liquid margin: lump-sum %+0.3f = levy %+0.3f + tilt %+0.3f  [resid %+0.1e]\n', ...
        eLS, eLV, eTL, eLS - (eLV + eTL));
    % policy-flow vs distribution split of the tilt (audit Block B, liquid)
    dS_pol  = sum(sum((polBT - polB0) .* dist0));
    dS_dist = sum(sum(polBT .* (distT - dist0)));
    tee('tilt split: policy-flow %+0.4f + distribution %+0.4f = total %+0.4f (per rev: %+0.3f / %+0.3f)\n', ...
        dS_pol, dS_dist, SbTL - Sb0, dS_pol/(Sb0*rev), dS_dist/(Sb0*rev));
    tee(['=> compare with the one-asset audit: does the direct term stay\n' ...
         '   near zero on the liquid margin too, or does the portfolio\n' ...
         '   margin revive the direct channel?\n']);
else
    eLS = NaN; eLV = NaN; eTL = NaN; dS_pol = NaN; dS_dist = NaN;
    tee('liquid-margin block: a leg failed (ls %d, levy %d, tilt %d)\n', okA, okB, okC);
end
% the tilt as a full (P, q) equilibrium (GE counterpart)
eqT = solve_twoasset_tilt(r_b, d_div, D0, dv, Bnom, Kbar, p, eqb);
if eqT.ok
    tee('tilt GE: P=%.4f (dlnP=%+0.4f), q=%.4f (dlnq=%+0.4f)\n\n', ...
        eqT.P, log(eqT.P/eqb.P), eqT.q, log(eqT.q/eqb.q));
else
    tee('tilt GE: FAILED (%s)\n\n', eqT.msg);
end

% =====================================================================
% (5) SOLVER SELF-TEST: EGM vs VFI on a coarse grid
% =====================================================================
tee('----- (5) solver self-test (coarse grid) -----\n');
ps = p; ps.hh2_solver = 'vfi';
psx = linspace(0, 1, 90)';
ps.xGrid = 0.05 + (30 - 0.05) * (psx.^2.2);
pse = p; pse.xGrid = ps.xGrid;
u2s = linspace(0, 1, 80)';
pse.aGrid2 = 1e-4 + (0.92*30 - 1e-4) * (u2s.^2.2);
pe_s  = scale_econ(pse, D0, 0);
pe_sv = scale_econ(ps,  D0, 0);
[SbE, SkE, okE] = agg_two(r_b, eqb.q, d_div, eqb.tau, pe_s, []);
[SbV, SkV, okV] = agg_two(r_b, eqb.q, d_div, eqb.tau, pe_sv, []);
if okE && okV
    tee('EGM: S_b=%.5f S_k=%.5f | VFI: S_b=%.5f S_k=%.5f | dS_b=%.2e dS_k=%.2e\n\n', ...
        SbE, SkE, SbV, SkV, abs(SbE-SbV), abs(SkE-SkV));
else
    tee('self-test failed to run (EGM ok=%d, VFI ok=%d)\n\n', okE, okV);
end

save(fullfile(projdir,'output','twoasset_step0.mat'), 'eqb', 'EX', 'ZS', 'p', ...
     'omega', 'r_b', 'd_div', 'D0', 'Gg', 'eLS', 'eLV', 'eTL', 'dS_pol', ...
     'dS_dist', 'eqT');
fclose(fid);
fprintf('[main_twoasset_step0] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [chi_star, eq0] = calibrate_chi(rb, d, D, Bnom, Kbar, b_targ, p)
% bisect the liquidity weight so baseline liquid demand hits the target
    clo = 1e-5; chi = 1.0; eq0 = [];
    for itc = 1:40
        p.chi_b = sqrt(clo * chi);                % log-midpoint
        eq0 = solve_twoasset_eq(rb, d, D, 0, 0, Bnom, Kbar, p);
        if ~eq0.ok, clo = p.chi_b; continue; end  % failures at tiny chi
        if eq0.Sb > b_targ, chi = p.chi_b; else, clo = p.chi_b; end
        if abs(eq0.Sb - b_targ) < 5e-3, break; end
    end
    chi_star = p.chi_b;
end

function pe = scale_econ(p, D, vth)
% damage scaling + proportional levy/subsidy on endowments (vth<0 = subsidy)
    pe = p;
    pe.eGrid = (1 - D) * p.eGrid;
    if vth ~= 0, pe.eGrid = (1 - vth) * pe.eGrid; end
end

function eq = solve_twoasset_eq(rb, d, D, g, use_levy, Bnom, Kbar, p)
% Full stationary (P, q, tau) equilibrium. use_levy = 1 finances the
% program with a proportional levy (tau covers only the interest bill).
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
                'tau',NaN,'tau_resid',NaN,'k_resid',NaN);
    if use_levy
        vth = g / (1 - D);                        % revenue = vth*(1-D)*E[e]
        pe  = scale_econ(p, D, vth);
    else
        pe  = scale_econ(p, D, 0);
    end
    tau0 = rb * 1.10 + (~use_levy) * g;           % initialization
    cache = [];                                   % policy warm start
    % economically anchored q bracket around the frictionless bound d/rb
    qlo = 0.15*d/max(rb, 5e-3); qhi = 1.5*d/max(rb, 5e-3);
    qs = linspace(qlo, qhi, 8); fs = nan(size(qs));
    for i = 1:numel(qs)
        [fs(i), ~, ~, ~, cache] = eval_at_q(qs(i), tau0, cache);
    end
    kk = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
              sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket: Sk-K spans [%+.3f, %+.3f]', ...
                         min(fs), max(fs));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fs(kk);
    m = 0.5*(a+b); fm = NaN; tau_m = tau0; Sb_m = NaN; res_m = Inf;
    for it = 1:45
        m = 0.5*(a+b);
        [fm, tau_m, Sb_m, res_m, cache] = eval_at_q(m, tau_m, cache);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 1e-4 || (b-a) < 1e-6, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb_m) || Sb_m <= 0
        eq.msg = 'bisection ended on a non-finite evaluation';
        return;
    end
    eq.ok = true; eq.q = m; eq.Sk = fm + Kbar; eq.Sb = Sb_m; eq.tau = tau_m;
    eq.k_resid = fm; eq.tau_resid = res_m;
    eq.P = Bnom / Sb_m;

    function [f, tt, Sb, resid, cch] = eval_at_q(qq, tinit, cch)
        % damped tau fixed point at this q: tau = rb*S_b(tau) + (ls ? g : 0)
        tt = tinit; Sb = NaN; Sk = NaN; resid = Inf;
        for itt = 1:30
            [Sb, Sk, okh, ~, ~, cch] = agg_two(rb, qq, d, tt, pe, cch);
            if ~okh, f = NaN; return; end
            tgt = rb*Sb + (~use_levy)*g;
            resid = abs(tgt - tt);
            if resid < 1e-6, break; end
            tt = 0.5*tt + 0.5*tgt;
        end
        f = Sk - Kbar;
    end
end

function eq = solve_twoasset_tilt(rb, d, D, dv, Bnom, Kbar, p, eqb)
% full (P, q) equilibrium of the revenue-neutral regressive tilt overlaid on
% the baseline government (tau + rev with a proportional subsidy dv)
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN);
    rev = dv*(1-D);
    pe  = scale_econ(p, D, -dv);
    cache = [];
    qlo = 0.15*d/max(rb, 5e-3); qhi = 1.5*d/max(rb, 5e-3);
    qs = linspace(qlo, qhi, 8); fs = nan(size(qs));
    tau_t = eqb.tau + rev;
    for i = 1:numel(qs)
        [Sb_i, Sk_i, ok_i, ~, ~, cache] = agg_two(rb, qs(i), d, tau_t, pe, cache);
        if ok_i, fs(i) = Sk_i - Kbar; end %#ok<NASGU>
    end
    kk = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
              sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    if isempty(kk), eq.msg = 'no q bracket for the tilt'; return; end
    a = qs(kk); b = qs(kk+1);
    [Sb_a, Sk_a, ok_a, ~, ~, cache] = agg_two(rb, a, d, tau_t, pe, cache);
    if ~ok_a, eq.msg = 'tilt bracket eval failed'; return; end
    fa = Sk_a - Kbar; Sb_m = Sb_a; m = a;
    for it = 1:45
        m = 0.5*(a+b);
        [Sb_m, Sk_m, ok_m, ~, ~, cache] = agg_two(rb, m, d, tau_t, pe, cache);
        if ~ok_m, b = m; continue; end
        fm = Sk_m - Kbar;
        if abs(fm) < 1e-4 || (b-a) < 1e-6, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb_m) || Sb_m <= 0, eq.msg = 'tilt bisection failed'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb_m; eq.P = Bnom/Sb_m;
end

function [Sb, Sk, ok, polB, dist, cache] = agg_two(rb, q, d, tau, pe, cache)
% household solve (EGM default, VFI reference) + invariant distribution
    Sb = NaN; Sk = NaN; ok = false; polB = []; dist = [];
    if isfield(pe, 'hh2_solver') && strcmpi(pe.hh2_solver, 'vfi')
        if ~isempty(cache), pe.V0 = cache; end
        [V, polB, polK, ~, dg] = solve_household_twoasset(rb, q, d, tau, pe);
        if ~dg.converged, return; end
        cache = V;
    else
        [polB, polK, ~, C, ~, dg] = solve_household_twoasset_egm(rb, q, d, tau, pe, cache);
        if ~dg.converged, return; end
        cache = C;
    end
    [dist, dd] = stationary_distribution_twoasset(polB, polK, rb, q, d, tau, pe);
    if ~dd.converged, return; end
    Sb = sum(sum(polB .* dist));
    Sk = sum(sum(polK .* dist));
    ok = true;
end

function s = tern(c, a, b)
    if c, s = a; else, s = b; end
end

function tee2(fid, varargin)
    fprintf(varargin{:});
    fprintf(fid, varargin{:});
end
