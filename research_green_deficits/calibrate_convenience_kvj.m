% CALIBRATE_CONVENIENCE_KVJ  Close the liquidity-specification fork with
% data (internal report R3 / build plan Stage 2.2).
%
% The model's convenience yield is the equity-bond spread
%     spr = (q+d)/q - (1+r_b),
% and the Krishnamurthy--Vissing-Jorgensen (2012) regression object is the
% response of that spread to the SUPPLY of public debt: roughly -0.4 to
% -1.5 percentage points of spread per log point of debt/GDP, headline
% around -0.75 pp (Aaa-Treasury).
%
% IMPORTANT (fixed after the first run): the experiment must vary REAL debt
% supply, NOT nominal B. Nominal neutrality (paper Theorem 2) means a change
% in nominal B is absorbed one-for-one by P, leaving real debt B/P and the
% spread UNCHANGED -- the first version varied B and correctly measured a
% zero elasticity. Here we vary the REAL quantity of liquid public claims
% households absorb: the direct-liquid-holding target b_liq (the DTPL analog
% of debt/GDP available to the household sector), re-solve (q, tau) with the
% liquidity weight chi HELD FIXED at its baseline calibration, and read the
% spread. More liquid bonds -> lower marginal convenience value -> lower
% spread, exactly the KVJ sign. Sweeping the curvature zeta traces the model
% elasticity; the zeta matching the empirical estimate is the DISCIPLINED
% specification. (The CES xi of the non-separable variant is the follow-up.)
%
% USAGE   >> parpool; calibrate_convenience_kvj
%         >> FAST = true; calibrate_convenience_kvj
% OUTPUT  output/convenience_kvj.mat, output/tables/convenience_kvj.txt
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
p.tol_pol = 1e-7; p.maxit_pol = 800;
p.tol_dist = 1e-10; p.maxit_dist = 20000;
nx = 220; na2 = 180; xmax = 60;
if FAST, nx = 120; na2 = 100; xmax = 40; end
u  = linspace(0,1,nx)';  p.xGrid  = 0.05 + (xmax-0.05)*(u.^2.2);
u2 = linspace(0,1,na2)'; p.aGrid2 = 1e-4 + (0.92*xmax-1e-4)*(u2.^2.2);

D0 = 0.06; r_b = (1 + pg.i_ss)/(1 + pg.mu) - 1;
Bnom = pg.Bnom; b_targ = 1.10; d_div = 0.12; Kbar = 1.0;
hK = 0.08;                                       % +/- tree-supply perturbation
kvj_target = -0.75; kvj_lo = -1.5; kvj_hi = -0.4;  % pp per log point (KVJ)

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'convenience_kvj.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('CONVENIENCE-YIELD SUPPLY ELASTICITY vs KVJ. nx=%d na2=%d FAST=%d\n', nx, na2, FAST);
tee('experiment: tree supply Kbar -> Kbar*(1+/-%.2f) at FIXED (chi, zeta, beta);\n', hK);
tee('read spread and household real bond holdings S_b; elasticity = dspr/dlnS_b.\n');
tee('KVJ target %.2f pp/logpt (range [%.1f, %.1f]). SIGN should be NEGATIVE.\n\n', ...
    kvj_target, kvj_lo, kvj_hi);

zetas = [0.5 1.0 1.5 2.0 3.0 5.0 8.0];
if FAST, zetas = [1.0 2.0 5.0]; end
tee('%-8s %10s %10s %12s %12s %14s\n', 'zeta', 'chi_b', 'spr0(pp)', 'dln(S_b)', 'dspr(pp)', 'dspr/dlnS_b');
nz = numel(zetas); Zc = cell(nz,1);
parfor z = 1:nz
    pz = p; pz.zeta_b = zetas(z);
    % calibrate chi ONCE at the baseline tree supply, then hold it fixed
    [chi_z, e0] = calib_chi(r_b, d_div, D0, Bnom, Kbar, b_targ, pz);
    if isempty(e0) || ~e0.ok
        Zc{z} = struct('zeta',zetas(z),'chi',NaN,'spr0',NaN,'dlnSb',NaN, ...
                       'dspr',NaN,'el',NaN,'ok',false);
        continue;
    end
    pz.chi_b = chi_z;
    % REAL supply shift: perturb the tree supply +/- hK (chi fixed). The tree
    % market pins q -> the spread; household real bond holdings S_b adjust as
    % the residual, tracing the convenience-yield-vs-liquidity locus.
    ep = solve_eq(r_b, d_div, D0, Bnom, Kbar*(1+hK), pz);
    em = solve_eq(r_b, d_div, D0, Bnom, Kbar*(1-hK), pz);
    if ~ep.ok || ~em.ok
        Zc{z} = struct('zeta',zetas(z),'chi',chi_z,'spr0',NaN,'dlnSb',NaN, ...
                       'dspr',NaN,'el',NaN,'ok',false);
        continue;
    end
    sprp = 100*((ep.q + d_div)/ep.q - (1 + r_b));
    sprm = 100*((em.q + d_div)/em.q - (1 + r_b));
    spr0 = 100*((e0.q + d_div)/e0.q - (1 + r_b));
    dlnSb = log(ep.Sb) - log(em.Sb);                    % change in real bonds held
    dspr  = sprp - sprm;
    el = dspr / sign0(dlnSb);                            % pp per log point
    Zc{z} = struct('zeta',zetas(z),'chi',chi_z,'spr0',spr0,'dlnSb',dlnSb, ...
                   'dspr',dspr,'el',el,'ok',true);
end
Z = [Zc{:}];
for z = 1:nz
    if Z(z).ok
        tee('%-8.2f %10.5f %10.3f %12.4f %12.4f %+14.3f\n', Z(z).zeta, ...
            Z(z).chi, Z(z).spr0, Z(z).dlnSb, Z(z).dspr, Z(z).el);
    else
        tee('%-8.2f %10s %10s %12s %12s %14s\n', Z(z).zeta, '--','--','--','--','fail');
    end
end
% interpolate the zeta matching the KVJ headline (model elasticity should be
% negative and increasing in magnitude with curvature)
ok = [Z.ok]; zs = [Z(ok).zeta]; els = [Z(ok).el];
zeta_star = NaN;
if numel(zs) >= 2 && min(els) < kvj_target && max(els) > kvj_target
    [els_s, io] = sort(els); zs_s = zs(io);
    zeta_star = interp1(els_s, zs_s, kvj_target, 'linear');
    tee('\nzeta matching the KVJ headline (%.2f pp/logpt): zeta* = %.2f\n', ...
        kvj_target, zeta_star);
    tee('=> rerun main_twoasset_step0 with p.zeta_b = %.2f for the DISCIPLINED\n', zeta_star);
    tee('   financing experiment; that dlnP(lump-sum) sign is the paper''s answer.\n');
else
    tee(['\nKVJ headline not bracketed by the swept zetas: model elasticities in ' ...
         '[%+.3f, %+.3f].\n'], min(els), max(els));
    tee(['If all model elasticities are SMALLER in magnitude than the KVJ range,\n' ...
         'the separable specification cannot generate the observed supply\n' ...
         'sensitivity and the CES variant (main_twoasset_nonsep) takes over.\n']);
end

save(fullfile(projdir,'output','convenience_kvj.mat'), 'Z', 'zeta_star', ...
     'kvj_target', 'kvj_lo', 'kvj_hi', 'hK', 'p');
fclose(fid);
fprintf('[calibrate_convenience_kvj] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [chi_star, eq0] = calib_chi(rb, d, D, Bnom, Kbar, b_targ, p)
% secant in log-chi to the liquid target (baseline B)
    lc = log(0.03); lc_p = NaN; e_p = NaN; eq0 = []; chi_star = exp(lc);
    for itc = 1:14
        p.chi_b = exp(lc);
        eqc = solve_eq(rb, d, D, Bnom, Kbar, p);
        if ~eqc.ok, lc = lc + 0.5; continue; end
        eq0 = eqc; chi_star = p.chi_b;
        err = log(eqc.Sb) - log(b_targ);
        if abs(err) < 5e-3, break; end
        if isfinite(e_p) && abs(err-e_p) > 1e-9
            step = -err*(lc-lc_p)/(err-e_p); step = max(min(step,1.2),-1.2);
        else, step = -sign(err)*0.4; end
        lc_p = lc; e_p = err; lc = lc + step;
    end
end

function eq = solve_eq(rb, d, D, Bnom, Kbar, p)
% stationary (P, q, tau) equilibrium, frictionless EGM household, no program
    eq = struct('ok',false,'P',NaN,'q',NaN,'Sb',NaN,'tau',NaN);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    tau = rb * 1.10; C = [];
    qlo = 0.15*d/max(rb,5e-3); qhi = 1.5*d/max(rb,5e-3);
    qs = linspace(qlo, qhi, 6); fq = nan(size(qs));
    for i = 1:numel(qs), [fq(i), tau, ~, C] = evq(qs(i), tau, C); end
    kk = find(isfinite(fq(1:end-1)) & isfinite(fq(2:end)) & ...
              sign(fq(1:end-1)) ~= sign(fq(2:end)), 1, 'first');
    if isempty(kk), return; end
    a = qs(kk); b = qs(kk+1); fa = fq(kk); m = a; Sb = NaN;
    for it = 1:40
        m = 0.5*(a+b);
        [fm, tau, Sb, C] = evq(m, tau, C);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 5e-4 || (b-a) < 1e-4, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.P = Bnom/Sb;

    function [f, tt, Sb, C] = evq(qq, tinit, C)
        tt = tinit; Sb = NaN; Sk = NaN; rprev = NaN;
        for itt = 1:15
            [pB, pK, ~, Cn, ~, dg] = solve_household_twoasset_egm(rb, qq, d, tt, pe, C);
            if ~dg.converged, f = NaN; return; end
            C = Cn;
            [dist, dd] = stationary_distribution_twoasset(pB, pK, rb, qq, d, tt, pe);
            if ~dd.converged, f = NaN; return; end
            Sb = sum(sum(pB .* dist)); Sk = sum(sum(pK .* dist));
            tgt = rb*Sb; r1 = tgt - tt;
            if abs(r1) < 1e-6, break; end
            if isfinite(rprev) && sign(r1)~=sign(rprev) && abs(r1)>abs(rprev)
                tt = 0.5*(tt+tgt); else, tt = tgt; end
            rprev = r1;
        end
        f = Sk - Kbar;
    end
end

function s = sign0(x)
% x with a small floor of matching sign, to avoid division by zero
    if x >= 0, s = max(x, 1e-9); else, s = min(x, -1e-9); end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
