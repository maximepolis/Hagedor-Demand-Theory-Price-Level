% MAIN_TWOASSET_STEP0  Two-asset DTPL, build-plan Step 0: the frictionless
% bonds-plus-tree economy in which the nominal government liability and the
% real asset clear in SEPARATE markets.
%
% WHAT THIS DELIVERS (build plan, Section 5):
%   1. A baseline stationary equilibrium (P, q) with an interior nominal
%      share, chi_b calibrated so liquid bond demand hits the debt target.
%   2. The financing experiment on the liquid margin: lump-sum vs
%      proportional-levy financing of the same real program, each solved as
%      a full (P, q) equilibrium -> d ln P per instrument. This is the
%      two-asset counterpart of the one-asset regime comparison: the
%      revaluation now falls only on the NOMINAL market.
%   3. The d ln P vs zeta figure data: the price response as a function of
%      the convenience-yield curvature zeta_b (elastic nominal share at low
%      zeta, rigid share as zeta grows), spanning the one-asset bound.
%
% EQUILIBRIUM. r_b is policy-set (i, mu). Given q and taxes, the household
% problem + invariant distribution deliver S_b = int b' dOmega and
% S_k = int k' dOmega. Clearing:
%     S_k(q) = Kbar (=1)      -> q  (bisection; S_k decreasing in q),
%     P      = Bnom / S_b     -> P  (nominal market),
% and the lump-sum tax solves the budget tau = r_b*(Bnom/P) + g given P,
% i.e. the fixed point tau = r_b*S_b(tau) + g (damped iteration, as in the
% one-asset package).
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
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star'), p.beta = L.RCAL.beta_star; end
end
p.eGrid  = pg.eGrid; p.Pi = pg.Pi; p.stationary_e = pg.stationary_e;
p.tol_vfi   = 1e-6;   p.maxit_vfi  = 600;
p.tol_dist  = 1e-10;  p.maxit_dist = 20000;
p.zeta_b = 2.0;                       % convenience curvature (KVJ-elastic)
p.chi_b  = 0.02;                      % liquidity weight, recalibrated below
nx       = 220; if FAST, nx = 120; end
xmax     = 60;  if FAST, xmax = 40; end
u        = linspace(0, 1, nx)';
p.xGrid  = 0.05 + (xmax - 0.05) * (u.^2.2);   % cash-on-hand grid (>0)

% policy / climate side (medium column, real budget)
D0     = 0.06;
r_b    = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom   = pg.Bnom;
b_targ = 1.10;                        % liquid target: public debt / income
d_div  = 0.12;                        % tree dividend (illiquid income share)
Kbar   = 1.0;
Gg     = 0.02 * (Bnom / b_targ);      % program: 2% of income, nominal appr.
if exist(calfile,'file') == 2 && isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
    Gg = L.RCAL.Gg_cal;
end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf  = fullfile(pg.tabdir, 'twoasset_step0.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET STEP 0. nx=%d, ne=%d, zeta=%.2f, r_b=%.4f, d=%.3f, FAST=%d\n\n', ...
    nx, numel(p.eGrid), p.zeta_b, r_b, d_div, FAST);

% =====================================================================
% (1) BASELINE: calibrate chi_b to the liquid target, solve (P, q)
% =====================================================================
tee('----- (1) baseline equilibrium -----\n');
% chi_b bisection: higher chi -> more bond demand -> higher S_b
chi_lo = 1e-4; chi_hi = 0.5; eqb = [];
for itc = 1:40
    p.chi_b = sqrt(chi_lo * chi_hi);              % log-midpoint
    eqb = solve_twoasset_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, p);
    if ~eqb.ok, chi_lo = p.chi_b; continue; end   % failures at tiny chi
    if eqb.Sb > b_targ, chi_hi = p.chi_b; else, chi_lo = p.chi_b; end
    if abs(eqb.Sb - b_targ) < 5e-3, break; end
end
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
tee(['Reading: the two-asset d ln P is the revaluation falling on the\n' ...
     'NOMINAL market only; compare against the one-asset regime numbers to\n' ...
     'measure how much of the one-asset magnitude the portfolio margin\n' ...
     'absorbs, and whether the lump-sum-vs-levy SIGN contrast survives.\n\n']);

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
    % recalibrate chi at each zeta to keep the baseline liquid target fixed
    clo = 1e-5; chi = 1.0; ez0 = [];
    for itc = 1:40
        pz.chi_b = sqrt(clo * chi);
        ez0 = solve_twoasset_eq(r_b, d_div, D0, 0, 0, Bnom, Kbar, pz);
        if ~ez0.ok, clo = pz.chi_b; continue; end
        if ez0.Sb > b_targ, chi = pz.chi_b; else, clo = pz.chi_b; end
        if abs(ez0.Sb - b_targ) < 5e-3, break; end
    end
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
tee(['\nReading: as zeta grows the nominal share turns rigid and d ln P\n' ...
     'should approach the one-asset benchmark; at low zeta the elastic\n' ...
     'share absorbs the shift and d ln P shrinks. This is the d ln P vs\n' ...
     'convenience-elasticity figure the build plan names as deliverable 1.\n']);

save(fullfile(projdir,'output','twoasset_step0.mat'), 'eqb', 'EX', 'ZS', 'p', ...
     'omega', 'r_b', 'd_div', 'D0', 'Gg');
fclose(fid);
fprintf('[main_twoasset_step0] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function eq = solve_twoasset_eq(rb, d, D, g, use_levy, Bnom, Kbar, p)
% Full stationary (P, q, tau) equilibrium of the frictionless two-asset
% economy. use_levy = 1 finances the program with a proportional levy on
% effective endowments (tau covers only the interest bill); 0 = lump-sum.
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
                'tau',NaN,'tau_resid',NaN,'k_resid',NaN);
    pe = p;
    pe.eGrid = (1 - D) * p.eGrid;                    % damage scaling
    % program resource cost enters the government budget; a levy scales
    % endowments once more (endowment economy: non-distortionary)
    tau = rb * 1.10 + (~use_levy) * g;               % initialization
    if use_levy
        vth = g / ((1 - D) * 1.0);                   % levy rate: revenue = g
        pe.eGrid = (1 - vth) * pe.eGrid;
    end
    % outer: q bisection on the tree market; inner: damped tau fixed point.
    % Fundamental anchor: q = d/r_k with r_k in (rb, rb + wide spread), so
    % bracket well below and up to slightly above the frictionless bound d/rb.
    qlo = 0.15*d/max(rb, 5e-3); qhi = 1.5*d/max(rb, 5e-3);
    Sk_of = @(qq, tt) agg_two(rb, qq, d, tt, pe, Kbar);
    % find bracket with sign change in Sk - Kbar
    qs = linspace(qlo, qhi, 8); fs = nan(size(qs)); taus = nan(size(qs));
    for i = 1:numel(qs)
        [fs(i), taus(i)] = eval_at_q(qs(i));
        if ~isfinite(fs(i)), continue; end
    end
    kk = find(isfinite(fs(1:end-1)) & isfinite(fs(2:end)) & ...
              sign(fs(1:end-1)) ~= sign(fs(2:end)), 1, 'first');
    if isempty(kk)
        eq.msg = sprintf('no q bracket: Sk-K spans [%+.3f, %+.3f]', ...
                         min(fs), max(fs));
        return;
    end
    a = qs(kk); b = qs(kk+1); fa = fs(kk);
    for it = 1:45
        m = 0.5*(a+b); [fm, tau_m, Sb_m, res_m] = eval_at_q(m);
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

    function [f, tt, Sb, resid] = eval_at_q(qq)
        % damped tau fixed point at this q: tau = rb*S_b(tau) + (ls ? g : 0)
        tt = tau; Sb = NaN; resid = Inf;
        for itt = 1:30
            [Sb, Sk, okh] = Sk_of(qq, tt);
            if ~okh, f = NaN; return; end
            tgt = rb*Sb + (~use_levy)*g;
            resid = abs(tgt - tt);
            if resid < 1e-6, break; end
            tt = 0.5*tt + 0.5*tgt;
        end
        f = Sk - Kbar;
    end
end

function [Sb, Sk, ok] = agg_two(rb, q, d, tau, pe, Kbar) %#ok<INUSD>
    [~, polB, polK, ~, dg] = solve_household_twoasset(rb, q, d, tau, pe);
    if ~dg.converged, Sb = NaN; Sk = NaN; ok = false; return; end
    [dist, dd] = stationary_distribution_twoasset(polB, polK, rb, q, d, tau, pe);
    if ~dd.converged, Sb = NaN; Sk = NaN; ok = false; return; end
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
