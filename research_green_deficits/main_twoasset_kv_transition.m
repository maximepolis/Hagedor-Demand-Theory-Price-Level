% MAIN_TWOASSET_KV_TRANSITION  The announcement path of the ownership +
% illiquidity economy, and the transition-inclusive incidence on initial
% portfolios -- the computation MC3 was blocked on.
%
% THE QUESTION. The paper's principal welfare object is transition-inclusive
% incidence: the consumption-equivalent transfer that makes a household
% indifferent between staying in the no-program steady state forever and
% entering date one of the announced path, announcement-date revaluation
% included. It is computed for the one-asset economy, where the transition
% DEEPENS the regressivity of lump-sum finance. But the paper's portfolio
% results say the revaluation's sign and incidence depend on who holds the
% debt and how easily they rebalance -- so the object that answers the
% title question in the disciplined economy is this one: the same
% announcement, solved in the KV (infrequent-adjustment) economy with the
% intermediation wedge and the superstar state, with both markets clearing
% at every date.
%
% THE METHOD (why this was previously "blocked" and now is not). The KV
% household carries a second endogenous state (illiquid k), so the
% cash-on-hand EGM transition of the frictionless economy does not apply.
% But the VALUE-FUNCTION formulation needs only ONE Bellman application per
% date on the (b,k,e) grid (twoasset_kv_bellman_step) -- the steady-state
% VFI's expensive fixed-point iteration is a property of stationarity, not
% of backward induction -- and the asset-state timing makes the push and
% the dating unambiguous. The path solver is the same Anderson-accelerated
% fixed point as the one-asset tier-2 transition, on the STACKED log-price
% system [Phat_path; q_path] with the terminal pinned at the program steady
% state. Nothing is reportable unless the fixed point converges AND the
% horizon is adequate (both terminal residuals small).
%
% VALIDATION BUILT IN. (i) At the terminal date the one-step Bellman
% operator agrees with the steady-state VFI by construction; the driver
% checks the terminal market clearing it implies. (ii) At constant prices
% the forward push reproduces the stationary distribution. (iii) The
% welfare block's steady-state column reproduces the steady-state incidence
% comparison independently of the path.
%
% COST. One residual evaluation = T Bellman sweeps + T sparse pushes on the
% (b,k,e) tensor: roughly 10-20 s at the full grid, T = 60. Expect
% O(40-90) Anderson iterations: ~15-45 min. TKV overrides the horizon.
%
% USAGE   >> clear; main_twoasset_kv_transition
%         >> clear; FAST = true; main_twoasset_kv_transition   (T = 40)
%         >> clear; TKV = 80; main_twoasset_kv_transition
%
% REQUIRES output/twoasset_ownership_kv.mat (the calibrated benchmark and
% its lump-sum experiment) -- run main_twoasset_ownership_kv first. The
% saved grids are used as-is: FAST here shortens the horizon only, because
% the initial distribution lives on the saved grids.
%
% OUTPUT  output/tables/twoasset_kv_transition.txt
%         output/twoasset_kv_transition.mat

clearvars -except FAST TKV; close all; clc;
rng(20260730, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
T = 60; if FAST, T = 40; end
if exist('TKV','var') && ~isempty(TKV), T = TKV; end

mf = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
assert(exist(mf, 'file') == 2, ...
    'twoasset_ownership_kv.mat not found -- run main_twoasset_ownership_kv first');
S = load(mf);
assert(isfield(S,'eq0') && S.eq0.ok, 'saved benchmark equilibrium not ok');
p = S.p; iota = S.iota_H;
r_b = S.r_b; d_base = S.d_base; D0 = S.D0; Gg = S.Gg;
pgtmp = setup_params_green(); Bnom = pgtmp.Bnom; Kbar = 1.0;
eq0 = S.eq0;
ils = find(strcmp({S.EXK.name}, 'lump-sum'), 1);
assert(~isempty(ils), 'lump-sum experiment missing from saved EXK');
Pterm = S.EXK(ils).P; qterm = S.EXK(ils).q;
g_real = Gg / eq0.P;

if ~isfolder(pgtmp.tabdir), mkdir(pgtmp.tabdir); end
sf = fullfile(pgtmp.tabdir, 'twoasset_kv_transition.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('KV TWO-ASSET ANNOUNCEMENT TRANSITION (ownership + illiquidity)\n');
tee('grids: nb=%d nk=%d ne=%d (saved); T=%d; lambda=%.2f iota_H=%.3f\n', ...
    numel(p.bGrid), numel(p.kGrid), numel(p.eGrid), T, p.lambda_adj, iota);
tee('boundary: P %.4f -> %.4f (dlnP %+0.4f), q %.4f -> %.4f\n\n', ...
    eq0.P, Pterm, log(Pterm/eq0.P), eq0.q, qterm);

pe0 = p; pe0.eGrid = (1 - D0) * p.eGrid;

% ---- terminal objects: V at the program steady state + consistency gate ----
tau_term = r_b * (Bnom / Pterm) + g_real;
div_term = d_base + r_b * (1 - iota) * (Bnom / Pterm) / Kbar;
tee('terminal household solve (program steady state)...\n');
[solT, dgT] = solve_household_twoasset_kv(r_b, qterm, div_term, tau_term, pe0, []);
assert(dgT.converged, 'terminal VFI failed (dV=%.1e)', dgT.supnorm);
Vterm = solT.V;
[dsT, ddT] = stationary_distribution_twoasset_kv(solT, r_b, qterm, div_term, tau_term, pe0);
assert(ddT.converged, 'terminal distribution failed');
[SbT, SkT] = agg_kv(solT, dsT, r_b, qterm, div_term, tau_term, pe0);
tee('  terminal clearing check: Sb*P/(iota B) = %.4f, Sk/Kbar = %.4f (both ~1)\n', ...
    SbT * Pterm / (iota * Bnom), SkT / Kbar);

% ---- baseline stay-put objects: V0 and the consumption-utility part Uc0 ----
tau0 = r_b * (Bnom / eq0.P);
div0 = eq0.div;
tee('baseline household solve (stay-put values)...\n');
[sol0, dg0] = solve_household_twoasset_kv(r_b, eq0.q, div0, tau0, pe0, []);
assert(dg0.converged, 'baseline VFI failed');
V0 = sol0.V;
tee('  policy-evaluating the consumption-utility component Uc0...\n');
Uc0 = uc_policy_eval(sol0, r_b, eq0.q, div0, tau0, pe0, 600, 1e-8);

% ---- the path: Anderson-accelerated fixed point on [log P; log q] ----
ctx = struct('T', T, 'p', p, 'r_b', r_b, 'd_base', d_base, 'iota', iota, ...
    'Bnom', Bnom, 'Kbar', Kbar, 'g_real', g_real, 'Dpath', D0 * ones(1, T), ...
    'P0', eq0.P, 'Pterm', Pterm, 'qterm', qterm, 'Vterm', Vterm, ...
    'dist0', eq0.dist, 'want_V1', false);
n = T - 1;
x = [log(Pterm) * ones(n,1); log(qterm) * ones(n,1)];  % flat-at-terminal seed

tol = 2e-3; maxit = 80; if FAST, maxit = 60; end
xi0 = 0.5; mAnd = 5;
Xh = {}; Fh = {};
best = struct('resnorm', Inf);
tee('\nsolving the path (tol %.0e, maxit %d)...\n', tol, maxit);
for it = 1:maxit
    [fv, aux] = twoasset_kv_transition_residual(x, ctx);
    if ~aux.feas
        tee('  iter %2d: INFEASIBLE trial path (healed nodes %d) -- damping\n', ...
            it, aux.n_nonfin);
        x = best_or_seed(best, x);   % retreat toward the best known iterate
        xi0 = 0.5 * xi0;  Xh = {}; Fh = {};
        if xi0 < 0.02, break; end
        continue;
    end
    resnorm = max(abs(fv));
    res_term = max(abs([aux.resid_b(T), aux.resid_k(T)]));
    if resnorm < best.resnorm
        best = struct('resnorm', resnorm, 'x', x, 'aux', aux, ...
                      'res_term', res_term, 'it', it);
    end
    tee('  iter %2d: interior max|f| = %.5f (bond %.5f tree %.5f), terminal = %.5f (mem=%d)\n', ...
        it, resnorm, max(abs(fv(1:n))), max(abs(fv(n+1:end))), res_term, ...
        min(numel(Fh), mAnd));
    if resnorm < tol, break; end
    if it == maxit, break; end
    Xh{end+1} = x; Fh{end+1} = fv; %#ok<AGROW>
    if numel(Fh) > mAnd + 1, Fh = Fh(end-mAnd:end); Xh = Xh(end-mAnd:end); end
    m = numel(Fh) - 1;
    if m < 1
        xn = x + xi0 * fv;
    else
        F = [Fh{:}]; X = [Xh{:}];
        dF = diff(F, 1, 2); dX = diff(X, 1, 2);
        ws = warning('off', 'MATLAB:rankDeficientMatrix');
        gamma = dF \ fv;
        warning(ws);
        xn = x + xi0 * fv - (dX + xi0 * dF) * gamma;
        if ~all(isfinite(xn)) || norm(gamma) > 1e3
            xn = x + xi0 * fv; Xh = Xh(end); Fh = Fh(end);
        end
    end
    step = max(min(xn - x, log(1.10)), log(0.90));    % per-date trust region
    x = x + step;
end

converged  = best.resnorm < tol;
horizon_ok = best.res_term < max(tol, 5e-3);
reportable = converged && horizon_ok;
tee('\nfixed point %s (interior %.5f), horizon %s (terminal %.5f), REPORTABLE = %d\n', ...
    ternstr(converged, 'CONVERGED', 'NOT CONVERGED'), best.resnorm, ...
    ternstr(horizon_ok, 'OK', 'INADEQUATE'), best.res_term, reportable);

% ---- path statistics + the welfare block, at the best iterate ----
ctx.want_V1 = true;
[~, auxb] = twoasset_kv_transition_residual(best.x, ctx);
Pp = auxb.Ppath; qp = auxb.qpath;
tee('\nimpact:   dlnP_1 = %+0.4f, dln q_1 = %+0.4f\n', ...
    log(Pp(1)/eq0.P), log(qp(1)/eq0.q));
tee('terminal: dlnP   = %+0.4f (steady-state experiment %+0.4f)\n', ...
    log(Pp(T)/eq0.P), S.EXK(ils).dlnP);
denomP = log(Pp(T)/eq0.P);
if abs(denomP) > 1e-6
    tee('front-loading share of the long-run price move: %.3f\n', ...
        log(Pp(1)/eq0.P) / denomP);
end
tee('k-grid top mass along the path (max): %.4f; healed nodes (max): %d\n', ...
    auxb.ksat, auxb.n_nonfin);

tee('\n----- transition-inclusive incidence on initial portfolios -----\n');
if ~reportable
    tee('PATH NOT REPORTABLE -- the numbers below are diagnostics, not results.\n');
end
sig = p.sigma;
V1 = auxb.V1;
base_tr  = (V1 - V0) ./ Uc0 + 1;         % stay-put consumption scaling, path
base_ss  = (Vterm - V0) ./ Uc0 + 1;      % entering the program ss directly
ok_tr = isfinite(base_tr) & base_tr > 0 & Uc0 < 0;
ok_ss = isfinite(base_ss) & base_ss > 0 & Uc0 < 0;
CEtr = nan(size(V0)); CEss = nan(size(V0));
CEtr(ok_tr) = base_tr(ok_tr).^(1/(1-sig)) - 1;
CEss(ok_ss) = base_ss(ok_ss).^(1/(1-sig)) - 1;

w  = eq0.dist(:) / sum(eq0.dist(:));
[BB, KK] = ndgrid(p.bGrid(:), p.kGrid(:));
bv = repmat(BB(:), numel(p.eGrid), 1);
kv = repmat(KK(:), numel(p.eGrid), 1);
wealth = bv + eq0.q * kv;
tee('%-22s %14s %14s\n', 'group (baseline)', 'CE transition', 'CE steady-state');
grp = {
    'bottom quintile',  in_wealth_band(wealth, w, 0.00, 0.20)
    'bottom half',      in_wealth_band(wealth, w, 0.00, 0.50)
    'middle 50-90',     in_wealth_band(wealth, w, 0.50, 0.90)
    'top decile',       in_wealth_band(wealth, w, 0.90, 1.00)
    'top 1 percent',    in_wealth_band(wealth, w, 0.99, 1.00)
    'constrained b<=0.02', bv <= 0.02
    'wealthy HtM',      (bv <= 0.02) & (eq0.q * kv >= 0.50)
    'ALL',              true(size(bv))
};
for i = 1:size(grp, 1)
    msk = grp{i,2};
    tee('%-22s %+13.2f%% %+13.2f%%\n', grp{i,1}, ...
        100 * wmean(CEtr, w, msk), 100 * wmean(CEss, w, msk));
end
tee(['\nreading: the one-asset transition DEEPENED the regressivity of\n' ...
     'lump-sum finance (windfall at the top, front-loaded taxes at the\n' ...
     'constrained bottom). Whether that survives realistic ownership and\n' ...
     'illiquidity -- where the top holds most of the revaluation base but\n' ...
     'cannot instantly rebalance -- is exactly what the two columns above\n' ...
     'decide. The CE columns answer the title question in this economy.\n']);

KVTR = struct('Ppath', Pp, 'qpath', qp, 'resid_b', auxb.resid_b, ...
    'resid_k', auxb.resid_k, 'Sb', auxb.Sb, 'Sk', auxb.Sk, ...
    'converged', converged, 'horizon_ok', horizon_ok, 'reportable', reportable, ...
    'resnorm', best.resnorm, 'res_term', best.res_term, 'iters', best.it, ...
    'CEtr', CEtr, 'CEss', CEss, 'T', T);
save(fullfile(projdir, 'output', 'twoasset_kv_transition.mat'), ...
     'KVTR', 'V0', 'Uc0', 'Vterm', 'eq0', 'p', 'iota', 'g_real', 'T');
tee('\n[main_twoasset_kv_transition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% ========================================================================
function v = getf(s, f, d)
    if isfield(s, f), v = s.(f); else, v = d; end
end

function x = best_or_seed(best, x0)
    if isfinite(best.resnorm), x = best.x; else, x = x0; end
end

function [Sb, Sk] = agg_kv(sol, dist, rb, q, d, tau, pe)
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    Sb = 0; Sk = 0;
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        knon = kG'; if isfield(sol, 'kNon'), knon = sol.kNon(:)'; end
        bch = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch = lam*kpa + (1-lam)*repmat(knon, nb, 1);
        Sb = Sb + sum(sum(bch .* dist(:,:,ie)));
        Sk = Sk + sum(sum(kch .* dist(:,:,ie)));
    end
end

function Uc = uc_policy_eval(sol, rb, q, dvd, tau, pe, maxit, tol)
% Consumption-utility component of the value under the SOLVED policies:
%   Uc(b,k,e) = lam*[u(c_a) + beta E Uc(b'_a,k'_a)]
%             + (1-lam)*[u(c_n) + beta E Uc(b'_n, k'_non)],
% iterated to its fixed point (a linear operator: contraction at rate beta).
% Needed because consumption-equivalent transfers scale u(c) but not the
% convenience utility chi v(b), so CE = (V-ratio)^(1/(1-sigma)) would be
% exact only if the two curvatures coincided. Uc isolates the scalable part.
    bG = pe.bGrid(:); kG = pe.kGrid(:); xG = pe.xGridA(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; sig = pe.sigma; Rb = 1 + rb;
    ynet = pe.eGrid(:)' - tau;
    if isfield(pe,'div_payout'), phi = min(max(pe.div_payout,0),1); else, phi = 1; end
    ua = ucrra(max(sol.polCa, 1e-10), sig);         % nx x ne
    Uc = ucrra(max(sol.polCn, 1e-10), sig) / (1 - pe.beta);  % warm start
    knon = kG; if isfield(sol, 'kNon'), knon = sol.kNon(:); end
    ikn = discretize(min(max(knon, kG(1)), kG(end)), kG); ikn = min(max(ikn,1), nk-1);
    wkn = min(max((knon - kG(ikn))./(kG(ikn+1)-kG(ikn)), 0), 1);
    for it = 1:maxit
        EU = zeros(nb, nk, ne);
        for ie = 1:ne
            for jep = 1:ne
                EU(:,:,ie) = EU(:,:,ie) + pe.Pi(ie, jep) * Uc(:,:,jep);
            end
        end
        Un = zeros(nb, nk, ne);
        for ie = 1:ne
            Ee = EU(:,:,ie);
            % adjuster: continuation at the chosen (b',k') via bilinear interp
            bpa = min(max(sol.polBa(:,ie), bG(1)), bG(end));
            kpa = min(max(sol.polKa(:,ie), kG(1)), kG(end));
            ib = discretize(bpa, bG); ib = min(max(ib,1), nb-1);
            ik = discretize(kpa, kG); ik = min(max(ik,1), nk-1);
            wb = min(max((bpa - bG(ib))./(bG(ib+1)-bG(ib)), 0), 1);
            wk = min(max((kpa - kG(ik))./(kG(ik+1)-kG(ik)), 0), 1);
            EUa = (1-wb).*(1-wk).*Ee(ib+(ik-1)*nb) + wb.*(1-wk).*Ee(ib+1+(ik-1)*nb) ...
                + (1-wb).*wk.*Ee(ib+ik*nb)         + wb.*wk.*Ee(ib+1+ik*nb);
            UcaX = ua(:,ie) + pe.beta * EUa;         % on xGridA
            for ik2 = 1:nk
                jb = sol.polBnIdx(:,ik2,ie);
                Eek = (1-wkn(ik2))*Ee(:, ikn(ik2)) + wkn(ik2)*Ee(:, min(ikn(ik2)+1, nk));
                un = ucrra(max(sol.polCn(:,ik2,ie), 1e-10), sig);
                % adjuster branch evaluated at this slice's cash-on-hand
                xaa = min(max(ynet(ie) + Rb*bG + (q + dvd)*kG(ik2), xG(1)), xG(end));
                UaI = interp1(xG, UcaX, xaa, 'linear');
                Un(:,ik2,ie) = lam * UaI + (1 - lam) * (un + pe.beta * Eek(jb));
            end
        end
        dU = max(abs(Un(:) - Uc(:))) / max(1, max(abs(Un(:))));
        Uc = Un;
        if dU < tol, break; end
    end
end

function u = ucrra(c, sig)
    if sig == 1, u = log(c); else, u = (c.^(1-sig))/(1-sig); end
end

function msk = in_wealth_band(wealth, w, qlo, qhi)
% mask of households whose baseline-wealth RANK lies in (qlo, qhi]
    [ws, io] = sort(wealth); cw = cumsum(w(io));
    lo_val = ws(find(cw >= qlo, 1, 'first'));
    hi_val = ws(find(cw >= qhi - 1e-12, 1, 'first'));
    if isempty(hi_val), hi_val = ws(end); end
    if qlo <= 0
        msk = wealth <= hi_val;
    else
        msk = wealth > lo_val & wealth <= hi_val;
    end
end

function m = wmean(x, w, msk)
    v = msk & isfinite(x);
    if ~any(v), m = NaN; return; end
    m = sum(x(v) .* w(v)) / sum(w(v));
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
