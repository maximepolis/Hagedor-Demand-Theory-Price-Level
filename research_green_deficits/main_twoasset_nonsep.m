% MAIN_TWOASSET_NONSEP  Two-asset DTPL, specification fork: NON-SEPARABLE
% liquidity. Tests whether the one-asset lump-sum DISINFLATION survives once
% consumption and liquidity are complementary rather than additively separable.
%
% In Step 0 (separable convenience utility) a lump-sum tax raises the marginal
% utility of consumption, which lowers the relative value of liquidity, so
% households cut bonds first and the one-asset lump-sum disinflation flips to a
% small inflation. With a CES bundle of elasticity xi < 1 the two are
% COMPLEMENTS, so higher marginal utility of consumption pulls liquidity
% demand UP -- potentially restoring d ln P < 0. This driver sweeps xi and
% reports the lump-sum and levy price responses, flagging the xi at which the
% lump-sum sign turns negative (if any).
%
% USAGE   >> main_twoasset_nonsep
%         >> FAST = true; main_twoasset_nonsep
% OUTPUT  output/twoasset_nonsep.mat, output/tables/twoasset_nonsep.txt
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
p.eGrid = pg.eGrid; p.Pi = pg.Pi; p.stationary_e = pg.stationary_e;
p.chi_b = 0.05; p.xi_liq = 0.5;
p.tol_vfi = 1e-6; p.maxit_vfi = 500;
p.tol_dist = 1e-10; p.maxit_dist = 20000;
nx = 200; nac = 120; nsh = 22; xmax = 70;
if FAST, nx = 120; nac = 80; nsh = 16; xmax = 50; end
uxg = linspace(0,1,nx)';  p.xGrid  = 0.05 + (xmax - 0.05)*(uxg.^2.2);
uac = linspace(0,1,nac)'; p.acGrid = 1e-4 + (0.92*xmax - 1e-4)*(uac.^2.2);
p.sGrid = linspace(1/nsh, 1, nsh);
% distribution routine expects these EGM fields; reuse the frictionless one
p.xGrid_dist = p.xGrid;

D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; b_targ = 1.10; d_div = 0.12; Kbar = 1.0;
Gg = 0.02 * (Bnom / b_targ);
if exist(calfile,'file') == 2 && isfield(L,'RCAL') && isfield(L.RCAL,'Gg_cal')
    Gg = L.RCAL.Gg_cal;
end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'twoasset_nonsep.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET NON-SEPARABLE LIQUIDITY. nx=%d nac=%d ns=%d ne=%d r_b=%.4f FAST=%d\n\n', ...
    nx, nac, nsh, numel(p.eGrid), r_b, FAST);

xis = [0.25 0.50 0.75 1.50];                    % <1 complements; >1 substitutes
if FAST, xis = [0.5 1.5]; end
tee('%-8s %10s %10s %12s %12s %10s\n', 'xi', 'chi_b', 'omega', 'dlnP(ls)', 'dlnP(levy)', 'ls sign');
% xi values are independent -> parfor (parallel with a pool, serial without)
fprintf('[%5.0fs] xi sweep: %d values in parallel\n', toc(t0), numel(xis));
NSc = cell(numel(xis), 1);
parfor iz = 1:numel(xis)
    pz = p; pz.xi_liq = xis(iz);
    % calibrate chi to the liquid target (secant in log-chi)
    [pz.chi_b, eq0] = calib_chi_ns(r_b, d_div, D0, Bnom, Kbar, b_targ, pz, 0.05, []);
    if isempty(eq0) || ~eq0.ok
        NSc{iz} = struct('xi',xis(iz),'chi',NaN,'omega',NaN, ...
            'dlnP_ls',NaN,'dlnP_levy',NaN,'ok',false);
        continue;
    end
    g_real = Gg / eq0.P;
    els = nseq(r_b, d_div, D0, g_real, 0, Bnom, Kbar, pz);
    elv = nseq(r_b, d_div, D0, g_real, 1, Bnom, Kbar, pz);
    dP_ls = NaN; dP_lv = NaN;
    if els.ok, dP_ls = log(els.P/eq0.P); end
    if elv.ok, dP_lv = log(elv.P/eq0.P); end
    om = eq0.Sb/(eq0.Sb + eq0.q*Kbar);
    NSc{iz} = struct('xi',xis(iz),'chi',pz.chi_b,'omega',om, ...
        'dlnP_ls',dP_ls,'dlnP_levy',dP_lv,'ok',els.ok && elv.ok);
end
NS = [NSc{:}];
for iz = 1:numel(NS)
    if isfinite(NS(iz).chi)
        tee('%-8.2f %10.4f %10.3f %+12.4f %+12.4f %10s\n', NS(iz).xi, ...
            NS(iz).chi, NS(iz).omega, NS(iz).dlnP_ls, NS(iz).dlnP_levy, ...
            sgnstr(NS(iz).dlnP_ls));
    else
        tee('%-8.2f %10s %10s %12s %12s %10s\n', NS(iz).xi,'--','--','--','--','--');
    end
end
tee(['\nReading: the one-asset lump-sum response is disinflationary (d ln P<0).\n' ...
     'Step 0 (separable) flips it positive. If some xi<1 (complements) turns\n' ...
     'dlnP(ls) negative again, the disinflation is a feature of complementary\n' ...
     'liquidity, not separable convenience utility -- the specification the\n' ...
     'paper should then adopt as its benchmark.\n']);

save(fullfile(projdir,'output','twoasset_nonsep.mat'), 'NS', 'p', 'r_b', ...
     'd_div', 'D0', 'Gg', 'xis');
fclose(fid);
fprintf('[main_twoasset_nonsep] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [chi_star, eq0] = calib_chi_ns(rb, d, D, Bnom, Kbar, b_targ, p, chi0, t0)
    lc = log(chi0); lc_p = NaN; e_p = NaN; eq0 = [];
    for itc = 1:14
        p.chi_b = exp(lc);
        eqc = nseq(rb, d, D, 0, 0, Bnom, Kbar, p);
        if ~eqc.ok, lc = lc + 0.5; continue; end
        eq0 = eqc; err = log(eqc.Sb) - log(b_targ);
        el = 0; if ~isempty(t0), try el = toc(t0); catch, el = 0; end, end
        fprintf('[%5.0fs] xi=%.2f chi=%.4f S_b=%.4f err=%+.4f\n', ...
                el, p.xi_liq, p.chi_b, eqc.Sb, err);
        if abs(err) < 6e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.2),-1.2);
        else, step = -sign(err)*0.4; end
        lc_p = lc; e_p = err; lc = lc + step;
    end
    chi_star = p.chi_b;
end

function eq = nseq(rb, d, D, g, use_levy, Bnom, Kbar, p)
% stationary (P,q,tau) equilibrium with the non-separable household
    eq = struct('ok',false,'P',NaN,'q',NaN,'Sb',NaN,'tau',NaN);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau = rb*1.10 + (~use_levy)*g; Vc = [];
    qlo = 0.15*d/max(rb,5e-3); qhi = 1.5*d/max(rb,5e-3);
    qs = linspace(qlo, qhi, 6); fq = nan(size(qs));
    for i = 1:numel(qs)
        [fq(i), tau, ~, Vc] = evalq(qs(i), tau, Vc);
    end
    kk = find(isfinite(fq(1:end-1)) & isfinite(fq(2:end)) & ...
              sign(fq(1:end-1)) ~= sign(fq(2:end)), 1, 'first');
    if isempty(kk), return; end
    a = qs(kk); b = qs(kk+1); fa = fq(kk); m = a; Sb = NaN;
    for it = 1:40
        m = 0.5*(a+b);
        [fm, tau, Sb, Vc] = evalq(m, tau, Vc);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 5e-4 || (b-a) < 1e-4, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.P = Bnom/Sb;

    function [f, tt, Sb, Vc] = evalq(qq, tinit, Vc)
        tt = tinit; Sb = NaN; Sk = NaN; rprev = NaN;
        for itt = 1:15
            [Sb, Sk, ok, Vc] = agg_ns(rb, qq, d, tt, pe, Vc);
            if ~ok, f = NaN; return; end
            tgt = rb*Sb + (~use_levy)*g; r1 = tgt - tt;
            if abs(r1) < 1e-6, break; end
            if isfinite(rprev) && sign(r1)~=sign(rprev) && abs(r1)>abs(rprev)
                tt = 0.5*(tt+tgt); else, tt = tgt; end
            rprev = r1;
        end
        f = Sk - Kbar;
    end
end

function [Sb, Sk, ok, Vc] = agg_ns(rb, q, d, tau, pe, Vc)
    Sb = NaN; Sk = NaN; ok = false;
    [polB, polK, ~, V, dg] = solve_household_twoasset_ns(rb, q, d, tau, pe, Vc);
    if ~dg.converged, return; end
    Vc = V;
    [dist, dd] = stationary_distribution_twoasset(polB, polK, rb, q, d, tau, pe);
    if ~dd.converged, return; end
    Sb = sum(sum(polB .* dist)); Sk = sum(sum(polK .* dist)); ok = true;
end

function s = sgnstr(x)
    if ~isfinite(x), s = '--'; elseif x < 0, s = 'NEG(!)'; else, s = 'pos'; end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
