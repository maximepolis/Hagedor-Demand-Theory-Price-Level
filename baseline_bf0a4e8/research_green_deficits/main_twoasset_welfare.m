% MAIN_TWOASSET_WELFARE  "Who pays" in the two-asset world (internal report
% R1, the fatal gap): consumption-equivalent incidence by wealth decile in
% the two-asset steady states, baseline vs lump-sum vs levy financing, for
% BOTH the frictionless (Step 0) and infrequent-adjustment (variant b)
% economies.
%
% CE DEFINITION (exact under separable preferences). Split the value at
% state s into discounted components V(s) = Uc(s) + Ub(s), where Uc collects
% u(c_t) and Ub collects chi*v(b_t) along the optimal path. A proportional
% consumption transfer (1+lam) scales only Uc, by (1+lam)^(1-sigma). The CE
% incidence of a reform with value V1(s) is therefore
%     lam(s) = [ (V1(s) - Ub0(s)) / Uc0(s) ]^(1/(1-sigma)) - 1   (sigma ~= 1)
%     lam(s) = exp( (V1(s) - V0(s)) * (1-beta) ) - 1             (sigma == 1)
% evaluated against the BASELINE components, aggregated over the baseline
% distribution by deciles of baseline wealth. This is the same
% steady-state-comparison convention as the one-asset decile tables
% (transition-inclusive incidence is the next upgrade and is noted in the
% output).
%
% PRICES are read from the saved equilibria (twoasset_step0.mat /
% twoasset_kv.mat); taxes are reconstructed from the budget identities
% (lump-sum: tau = r_b B/P + g; levy: tau = r_b B/P, vartheta = g/(1-D)).
% Only HOUSEHOLD problems are re-solved here (cheap), not equilibria.
%
% USAGE   >> main_twoasset_welfare        (FAST irrelevant: minutes)
% REQUIRES output/twoasset_step0.mat (and optionally twoasset_kv.mat).
% OUTPUT  output/twoasset_welfare.mat, output/tables/twoasset_welfare.txt
% STATUS: scaffolded, untested pending a MATLAB run.

clearvars; close all; clc;
rng(20260723, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

pg = setup_params_green();
s0f = fullfile(projdir, 'output', 'twoasset_step0.mat');
assert(exist(s0f,'file') == 2, 'run main_twoasset_step0 first');
S0 = load(s0f);
p0 = S0.p; r_b = S0.r_b; d_div = S0.d_div; D0 = S0.D0; Gg = S0.Gg;
Bnom = pg.Bnom;
assert(isfield(S0,'EX') && numel(S0.EX) >= 2, 'step0 EX incomplete');

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'twoasset_welfare.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('TWO-ASSET WELFARE INCIDENCE BY DECILE (steady-state comparison)\n');
tee('CE transfer exact under separable preferences (Uc/Ub split).\n\n');

% =====================================================================
% (1) FRICTIONLESS (Step 0) economy
% =====================================================================
tee('===== frictionless (Step 0) =====\n');
eqb = S0.eqb; g_real = Gg / eqb.P;
% prices and taxes per regime (reconstructed from budget identities)
regs = struct( ...
  'name', {'baseline','lump-sum','levy'}, ...
  'P',    {eqb.P,  S0.EX(1).P, S0.EX(2).P}, ...
  'q',    {eqb.q,  S0.EX(1).q, S0.EX(2).q}, ...
  'vth',  {0, 0, g_real/(1-D0)});
sols = cell(1,3); Uc = cell(1,3); Ub = cell(1,3); Vv = cell(1,3);
for j = 1:3
    pe = p0; pe.eGrid = (1 - D0)*p0.eGrid;
    if regs(j).vth ~= 0, pe.eGrid = (1 - regs(j).vth)*pe.eGrid; end
    tau_j = r_b*Bnom/regs(j).P + (j == 2)*g_real;    % levy: tau = interest only
    [pB, pK, pC, ~, ~, dg] = solve_household_twoasset_egm(r_b, regs(j).q, d_div, tau_j, pe);
    assert(dg.converged, 'frictionless household solve failed (%s)', regs(j).name);
    [ucj, ubj] = eval_components_x(pB, pK, pC, r_b, regs(j).q, d_div, tau_j, pe, p0);
    sols{j} = struct('pB',pB,'pK',pK,'pC',pC,'tau',tau_j,'pe',pe);
    Uc{j} = ucj; Ub{j} = ubj; Vv{j} = ucj + ubj;
end
% baseline distribution and wealth ranking (W = x - ynet0(e))
peb = sols{1}.pe;
[dist0, dd0] = stationary_distribution_twoasset(sols{1}.pB, sols{1}.pK, ...
    r_b, regs(1).q, d_div, sols{1}.tau, peb);
assert(dd0.converged, 'baseline distribution failed');
xG = p0.xGrid(:); ne = numel(peb.eGrid);
Wlth = repmat(xG, 1, ne) - repmat(peb.eGrid(:)' - sols{1}.tau, numel(xG), 1);
WA = struct();
for j = 2:3
    lam = ce_lambda(Vv{j}, Uc{1}, Ub{1}, Vv{1}, p0.sigma, p0.beta);
    [dec, bot, top, t10] = decile_means(lam, Wlth, dist0);
    WA.(matname(regs(j).name)) = struct('lam_dec',dec,'bot',bot,'top',top,'t10',t10);
    tee('%-9s CE by baseline-wealth decile (%%):\n  %s\n', regs(j).name, ...
        sprintf('%+.2f ', 100*dec));
    tee('  bottom decile %+.2f | top decile %+.2f | top 10%% %+.2f\n', ...
        100*bot, 100*top, 100*t10);
end
tee('\n');

% =====================================================================
% (2) INFREQUENT-ADJUSTMENT (variant b) economy -- if available
% =====================================================================
kvf = fullfile(projdir, 'output', 'twoasset_kv.mat');
WK = struct();
if exist(kvf, 'file') == 2
    tee('===== infrequent adjustment (variant b) =====\n');
    K0 = load(kvf);
    pk = K0.p; eqk = K0.eqb; gk = K0.Gg / eqk.P; D0k = K0.D0;
    assert(isfield(K0,'EXK') && numel(K0.EXK) >= 2, 'kv EXK incomplete');
    kreg = struct( ...
      'name', {'baseline','lump-sum','levy'}, ...
      'P', {eqk.P, K0.EXK(1).P, K0.EXK(2).P}, ...
      'q', {eqk.q, K0.EXK(1).q, K0.EXK(2).q}, ...
      'vth', {0, 0, gk/(1-D0k)});
    UcK = cell(1,3); UbK = cell(1,3); VK = cell(1,3); solK = cell(1,3);
    for j = 1:3
        pe = pk; pe.eGrid = (1 - D0k)*pk.eGrid;
        if kreg(j).vth ~= 0, pe.eGrid = (1 - kreg(j).vth)*pe.eGrid; end
        tau_j = K0.r_b*Bnom/kreg(j).P + (j == 2)*gk;
        [sol, dg] = solve_household_twoasset_kv(K0.r_b, kreg(j).q, K0.d_div, tau_j, pe);
        assert(dg.converged, 'kv household solve failed (%s)', kreg(j).name);
        [ucj, ubj] = eval_components_bk(sol, K0.r_b, kreg(j).q, K0.d_div, tau_j, pe);
        solK{j} = struct('sol',sol,'tau',tau_j,'pe',pe);
        UcK{j} = ucj; UbK{j} = ubj; VK{j} = ucj + ubj;
    end
    [distK, ddK] = stationary_distribution_twoasset_kv(solK{1}.sol, K0.r_b, ...
        kreg(1).q, K0.d_div, solK{1}.tau, solK{1}.pe);
    assert(ddK.converged, 'kv baseline distribution failed');
    bG = pk.bGrid(:); kGr = pk.kGrid(:); nek = numel(pk.eGrid);
    [BB, KK] = ndgrid(bG, kGr);
    WlthK = repmat(BB + kreg(1).q*KK, 1, 1, nek);
    for j = 2:3
        lam = ce_lambda(VK{j}, UcK{1}, UbK{1}, VK{1}, pk.sigma, pk.beta);
        [dec, bot, top, t10] = decile_means(lam, WlthK, distK);
        WK.(matname(kreg(j).name)) = struct('lam_dec',dec,'bot',bot,'top',top,'t10',t10);
        tee('%-9s CE by baseline-wealth decile (%%):\n  %s\n', kreg(j).name, ...
            sprintf('%+.2f ', 100*dec));
        tee('  bottom decile %+.2f | top decile %+.2f | top 10%% %+.2f\n', ...
            100*bot, 100*top, 100*t10);
    end
else
    tee('(variant b skipped: twoasset_kv.mat not found)\n');
end

tee(['\nConvention: steady-state comparison at unchanged household state,\n' ...
     'aggregated over the baseline distribution -- the same convention as\n' ...
     'the one-asset decile tables. Transition-inclusive incidence (which\n' ...
     'adds the announcement-date revaluation of the initial portfolio) is\n' ...
     'the next upgrade, via main_twoasset_transition.\n']);

save(fullfile(projdir,'output','twoasset_welfare.mat'), 'WA', 'WK');
fclose(fid);
fprintf('[main_twoasset_welfare] wrote %s (%.1f s)\n', sf, toc(t0));

% =========================================================================
function [Uc, Ub] = eval_components_x(pB, pK, pC, rb, q, d, tau, pe, p0)
% discounted component values on the (x,e) grid by linear policy evaluation
    xG = p0.xGrid(:); nx = numel(xG); ne = numel(pe.eGrid);
    ynet = pe.eGrid(:)' - tau; Rb = 1 + rb;
    fc = zeros(nx, ne); fb = zeros(nx, ne);
    for ie = 1:ne
        fc(:, ie) = ucrra(pC(:, ie), p0.sigma);
        fb(:, ie) = p0.chi_b * vfun(pB(:, ie), p0.zeta_b);
    end
    Uc = fc / (1 - p0.beta); Ub = fb / (1 - p0.beta);
    for it = 1:3000
        Ucn = fc; Ubn = fb;
        for ie = 1:ne
            base = Rb*pB(:, ie) + (q + d)*pK(:, ie);
            cc = zeros(nx,1); cb = zeros(nx,1);
            for jep = 1:ne
                xp = min(max(ynet(jep) + base, xG(1)), xG(end));
                cc = cc + pe.Pi(ie, jep) * interp1(xG, Uc(:, jep), xp, 'linear');
                cb = cb + pe.Pi(ie, jep) * interp1(xG, Ub(:, jep), xp, 'linear');
            end
            Ucn(:, ie) = Ucn(:, ie) + p0.beta * cc;
            Ubn(:, ie) = Ubn(:, ie) + p0.beta * cb;
        end
        dU = max([abs(Ucn(:) - Uc(:)); abs(Ubn(:) - Ub(:))]);
        Uc = Ucn; Ub = Ubn;
        if dU < 1e-8 * max(1, max(abs(Uc(:)))), break; end
    end
end

function [Uc, Ub] = eval_components_bk(sol, rb, q, d, tau, pe)
% component evaluation on the (b,k,e) grid with the lambda adjust/no-adjust
% mix; adjuster policies interpolated off the x-grid
    bG = pe.bGrid(:); kG = pe.kGrid(:); xA = pe.xGridA(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    % per-(b,k,e) adjuster policies and flows
    fca = zeros(nb,nk,ne); fba = zeros(nb,nk,ne);
    bpa = zeros(nb,nk,ne); kpa = zeros(nb,nk,ne);
    fcn = zeros(nb,nk,ne); fbn = zeros(nb,nk,ne);
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q + d)*kG', xA(1)), xA(end));
        bpa(:,:,ie) = interp1(xA, sol.polBa(:,ie), xbk, 'linear');
        kpa(:,:,ie) = interp1(xA, sol.polKa(:,ie), xbk, 'linear');
        ca = interp1(xA, sol.polCa(:,ie), xbk, 'linear');
        fca(:,:,ie) = ucrra(max(ca,1e-10), pe.sigma);
        fba(:,:,ie) = pe.chi_b * vfun(max(bpa(:,:,ie),1e-12), pe.zeta_b);
        fcn(:,:,ie) = ucrra(max(sol.polCn(:,:,ie),1e-10), pe.sigma);
        fbn(:,:,ie) = pe.chi_b * vfun(max(sol.polBn(:,:,ie),1e-12), pe.zeta_b);
    end
    Uc = (lam*fca + (1-lam)*fcn) / (1 - pe.beta);
    Ub = (lam*fba + (1-lam)*fbn) / (1 - pe.beta);
    for it = 1:3000
        % premix over e' (continuation state independent of e')
        EUc = zeros(nb,nk,ne); EUb = zeros(nb,nk,ne);
        for ie = 1:ne
            for jep = 1:ne
                EUc(:,:,ie) = EUc(:,:,ie) + pe.Pi(ie,jep)*Uc(:,:,jep);
                EUb(:,:,ie) = EUb(:,:,ie) + pe.Pi(ie,jep)*Ub(:,:,jep);
            end
        end
        Ucn = zeros(nb,nk,ne); Ubn = zeros(nb,nk,ne);
        for ie = 1:ne
            % adjuster continuation at (b'a, k'a): bilinear
            ca = bilin(EUc(:,:,ie), bG, kG, bpa(:,:,ie), kpa(:,:,ie));
            cb = bilin(EUb(:,:,ie), bG, kG, bpa(:,:,ie), kpa(:,:,ie));
            % non-adjuster continuation at (b'n, k): interp in b per k column
            cnc = zeros(nb,nk); cnb = zeros(nb,nk);
            for ik = 1:nk
                bp = min(max(sol.polBn(:,ik,ie), bG(1)), bG(end));
                cnc(:,ik) = interp1(bG, EUc(:,ik,ie), bp, 'linear');
                cnb(:,ik) = interp1(bG, EUb(:,ik,ie), bp, 'linear');
            end
            Ucn(:,:,ie) = lam*(fca(:,:,ie) + pe.beta*ca) ...
                        + (1-lam)*(fcn(:,:,ie) + pe.beta*cnc);
            Ubn(:,:,ie) = lam*(fba(:,:,ie) + pe.beta*cb) ...
                        + (1-lam)*(fbn(:,:,ie) + pe.beta*cnb);
        end
        dU = max([abs(Ucn(:) - Uc(:)); abs(Ubn(:) - Ub(:))]);
        Uc = Ucn; Ub = Ubn;
        if dU < 1e-8 * max(1, max(abs(Uc(:)))), break; end
    end
end

function v2 = bilin(E, bG, kG, bq, kq)
    nb = numel(bG); nk = numel(kG);
    bq = min(max(bq, bG(1)), bG(end)); kq = min(max(kq, kG(1)), kG(end));
    ib = discretize(bq, bG); ib = min(max(ib,1), nb-1);
    ik = discretize(kq, kG); ik = min(max(ik,1), nk-1);
    wb = (bq - bG(ib))./(bG(ib+1)-bG(ib));
    wk = (kq - kG(ik))./(kG(ik+1)-kG(ik));
    i11 = ib+(ik-1)*nb; i21 = ib+1+(ik-1)*nb; i12 = ib+ik*nb; i22 = ib+1+ik*nb;
    v2 = (1-wb).*(1-wk).*E(i11) + wb.*(1-wk).*E(i21) ...
       + (1-wb).*wk.*E(i12)     + wb.*wk.*E(i22);
end

function lam = ce_lambda(V1, Uc0, Ub0, V0, sigma, beta)
% exact CE transfer under separable preferences (see header)
    if abs(sigma - 1) < 1e-12
        lam = exp((V1 - V0)*(1 - beta)) - 1;
    else
        ratio = (V1 - Ub0) ./ Uc0;
        ratio = max(ratio, 1e-12);               % guard (Uc0 < 0 for sigma>1)
        lam = ratio.^(1/(1 - sigma)) - 1;
    end
end

function [dec, bot, top, t10] = decile_means(lam, W, dist)
% distribution-weighted decile means of lam by wealth W
    w = dist(:) / sum(dist(:)); lv = lam(:); Wv = W(:);
    [Ws, io] = sort(Wv); lv = lv(io); w = w(io); %#ok<ASGLU>
    cw = cumsum(w);
    dec = zeros(10,1);
    lo = 0;
    for dq = 1:10
        hi = dq/10;
        m = cw > lo & cw <= hi + 1e-12;
        if any(m), dec(dq) = sum(lv(m).*w(m))/sum(w(m)); end
        lo = hi;
    end
    bot = dec(1); top = dec(10);
    m10 = cw > 0.9;
    t10 = sum(lv(m10).*w(m10))/max(sum(w(m10)), 1e-12);
end

function s = matname(nm)
    s = strrep(nm, '-', '_');
end

function u = ucrra(c, sig)
    if abs(sig-1) < 1e-12, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function v = vfun(b, zet)
    bb = max(b, 1e-12);
    if abs(zet-1) < 1e-12, v = log(bb); else, v = (bb.^(1-zet))/(1-zet); end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end
