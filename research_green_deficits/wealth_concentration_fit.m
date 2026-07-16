% WEALTH_CONCENTRATION_FIT  Re-target the model's top-1% wealth share to the
% data with a rare high-income "superstar" state (Castaneda-Diaz-Gimenez-
% Rios-Rull 2003 device), then re-examine the paper's tail incidence under
% the fitted concentration.
%
% WHY. The one-asset Aiyagari tail is thin: the baseline top-1% wealth share
% is ~8% against roughly one-third in U.S. data (SCF), so the concentration
% of the bondholder windfall is understated. This driver asks the question
% that caveat leaves open: WITH a data-consistent top share, how do the
% revaluation term and the decile incidence gradient change? Expectation
% (stated before the run): concentration deepens the top-tail windfall and
% strengthens, not weakens, the incidence conclusions -- but the numbers
% decide.
%
% METHOD.
%   Stage 1 (fit): sweep (mult, p_in) of the superstar state; for each
%     config re-bisect beta IN THE AUGMENTED ECONOMY (via S_green, which
%     carries the superstar chain; the root calibrate_beta does not) so the
%     no-program medium-column steady state holds the same debt target
%     b = B_TARGET; record top-1%/top-10% shares and the wealth Gini.
%   Stage 2 (incidence): for the config closest to the top-1% target,
%     rebuild the S(tau,D) interpolant, re-run the medium-column
%     self-financing decomposition and the decile welfare incidence.
%
% READS   output/calibrated_results.mat
% WRITES  output/wealth_fit_results.mat, output/tables/wealth_fit.txt
%         export_paper_numbers picks up the \Sup* macros.
%
% USAGE   >> cd research_green_deficits; wealth_concentration_fit

clearvars -except FORCE_RERUN; close all; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

TOP1_TARGET = 0.33;      % SCF-style top-1% net-worth share
B_TARGET    = 1.10;      % debt target of the calibrated pass (main_project_calibrated)

calf = fullfile(projdir, 'output', 'calibrated_results.mat');
assert(exist(calf, 'file') == 2, 'wealth_concentration_fit: run main_project_calibrated first.');
L = load(calf, 'RCAL', 'pgc');
RCAL = L.RCAL; pgc = L.pgc;
r_cal  = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
cmed   = 2;                                   % medium column, as elsewhere
assert(~isempty(RCAL.dec{cmed}) && RCAL.dec{cmed}.ok, 'medium column missing.');
D_base = RCAL.dec{cmed}.base.D;
D0_med = RCAL.cols(cmed).D0;

% ---- Stage 1: fit sweep ----
configs = struct('mult', {}, 'p_in', {}, 'p_out', {});
for m = [8, 12, 16]
    for pin = [1e-4, 2e-4, 4e-4]
        configs(end+1) = struct('mult', m, 'p_in', pin, 'p_out', 0.06); %#ok<SAGROW>
    end
end

FIT = struct('mult',{},'p_in',{},'p_out',{},'beta',{},'b',{},'top1',{}, ...
             'top10',{},'gini',{},'topnode_mass',{},'ok',{});
fprintf('=== Stage 1: superstar fit sweep (%d configs, beta re-bisected each) ===\n', ...
        numel(configs));
for k = 1:numel(configs)
    cf = configs(k);
    pgs = pgc; pgs.climate_version = 1; pgs.D0 = D0_med;
    pgs.superstar = struct('active', true, 'mult', cf.mult, ...
                           'p_in', cf.p_in, 'p_out', cf.p_out);
    [beta_k, b_k, ok_k] = local_bisect_beta(pgs, r_cal, D_base, B_TARGET);
    rec = struct('mult', cf.mult, 'p_in', cf.p_in, 'p_out', cf.p_out, ...
                 'beta', beta_k, 'b', b_k, 'top1', NaN, 'top10', NaN, ...
                 'gini', NaN, 'topnode_mass', NaN, 'ok', false);
    if ok_k
        pgs.beta = beta_k;
        [~, o] = S_green(r_cal, r_cal * b_k, D_base, pgs);
        if o.feasible
            [rec.top1, rec.top10, rec.gini] = local_top_shares(o.dist, pgs.aGrid(:));
            rec.topnode_mass = sum(o.dist(end, :));
            rec.ok = true;
            if rec.topnode_mass > 1e-4
                warning('wealth_fit:gridtop', ...
                    'config %d: %.2e mass at the TOP asset node -- raise amax.', ...
                    k, rec.topnode_mass);
            end
        end
    end
    FIT(k) = rec;
    if rec.ok, tag = ''; else, tag = '(FAILED)'; end
    fprintf('  mult %4.0f p_in %.0e -> beta %.5f  top1 %5.1f%%  top10 %5.1f%%  gini %.3f %s\n', ...
        cf.mult, cf.p_in, rec.beta, 100*rec.top1, 100*rec.top10, rec.gini, tag);
end

okF = FIT([FIT.ok]);
assert(~isempty(okF), 'no superstar config solved.');
[~, ib] = min(abs([okF.top1] - TOP1_TARGET));
best = okF(ib);
fprintf('Selected: mult %.0f, p_in %.0e (top1 %.1f%% vs target %.0f%%).\n', ...
        best.mult, best.p_in, 100*best.top1, 100*TOP1_TARGET);

% ---- Stage 2: medium-column incidence under the fitted concentration ----
fprintf('=== Stage 2: medium-column decomposition + decile incidence ===\n');
pgb = pgc; pgb.climate_version = 1; pgb.D0 = D0_med;
pgb.Gg_nom = RCAL.Gg_cal; pgb.beta = best.beta;
pgb.superstar = struct('active', true, 'mult', best.mult, ...
                       'p_in', best.p_in, 'p_out', best.p_out);
pgb.taugrid_S = linspace(-0.01, 0.08, 5);
pgb.Dgrid_S   = linspace(0, D0_med, 3);
ad2b = build_S_interp_green(r_cal, pgb);
dec  = self_financing_decomposition(pgb, ad2b);
assert(dec.ok, 'wealth_concentration_fit: decomposition failed under the fit.');
wd = welfare_by_decile(r_cal, dec.base, dec.prog, pgb);

save(fullfile(projdir, 'output', 'wealth_fit_results.mat'), ...
     'FIT', 'best', 'dec', 'wd', 'r_cal', 'TOP1_TARGET', 'B_TARGET');

tabdir = fullfile(projdir, 'output', 'tables');
if ~isfolder(tabdir), mkdir(tabdir); end
fid = fopen(fullfile(tabdir, 'wealth_fit.txt'), 'w');
fprintf(fid, 'WEALTH-CONCENTRATION FIT (superstar state; medium column)\n');
fprintf(fid, 'Target: top-1%% share %.0f%%; debt target b = %.2f; r = %.4f.\n\n', ...
        100*TOP1_TARGET, B_TARGET, r_cal);
fprintf(fid, '%-6s %-8s %-8s %-9s %7s %7s %7s %10s\n', 'mult', 'p_in', ...
        'p_out', 'beta', 'top1%', 'top10%', 'gini', 'topnode');
for k = 1:numel(FIT)
    if ~FIT(k).ok, continue; end
    fprintf(fid, '%-6.0f %-8.0e %-8.2f %-9.5f %7.1f %7.1f %7.3f %10.2e\n', ...
        FIT(k).mult, FIT(k).p_in, FIT(k).p_out, FIT(k).beta, ...
        100*FIT(k).top1, 100*FIT(k).top10, FIT(k).gini, FIT(k).topnode_mass);
end
fprintf(fid, '\nSELECTED: mult %.0f, p_in %.0e -> top1 %.1f%%, beta %.5f\n', ...
        best.mult, best.p_in, 100*best.top1, best.beta);
fprintf(fid, ['\nMedium-column decomposition under the fit:\n' ...
    '  nu %.3f = nu_reval %+.3f + nu_damage %.3f   (P0 %.4f -> P1 %.4f)\n'], ...
    dec.nu, dec.nu_reval, dec.nu_damage, dec.base.P, dec.prog.P);
if wd.ok
    fprintf(fid, 'Decile CE (%%): %s\n', mat2str(round(100*wd.lambda_dec, 2)));
    fprintf(fid, 'top5 %+.2f  top1 %+.2f  agg %+.2f  (model top-1%% wealth share now %.1f%%)\n', ...
        100*wd.lambda_top5, 100*wd.lambda_top1, 100*wd.lambda_agg, 100*best.top1);
end
fclose(fid);
fprintf('Wrote output/tables/wealth_fit.txt. Elapsed %.1f s\n', toc(t0));

% -------------------------------------------------------------------------
function [beta_star, b_star, ok] = local_bisect_beta(pgs, r, D, b_target)
% Bisect beta so the no-program fixed point b = S(1+r; tau = r*b, D) hits
% b_target, INSIDE the augmented economy (S_green carries the superstar
% chain; the root calibrate_beta does not).
    lo = 0.88; hi = min(0.999, (1 - 1e-4) / (1 + r)); ok = false; b_star = NaN;
    f = @(bta) local_b_fixed_point(pgs, bta, r, D);
    flo = f(lo) - b_target; fhi = f(hi) - b_target;
    if ~(isfinite(flo) && isfinite(fhi)) || flo * fhi > 0
        beta_star = NaN; return;
    end
    for it = 1:40
        mid = (lo + hi) / 2; fm = f(mid) - b_target;
        if ~isfinite(fm), hi = mid; continue; end
        if abs(fm) < 1e-4, break; end
        if fm * flo < 0, hi = mid; else, lo = mid; flo = fm; end
    end
    beta_star = (lo + hi) / 2;
    b_star = f(beta_star);
    ok = isfinite(b_star) && abs(b_star - b_target) < 5e-3;
end

function b = local_b_fixed_point(pgs, bta, r, D)
% Damped iteration on b: tau = r*b, b <- S(1+r; tau, D).
    pgs.beta = bta; b = 1.0;
    for it = 1:60
        S = S_green(r, r * b, D, pgs);
        if ~isfinite(S), b = NaN; return; end
        bn = 0.5 * b + 0.5 * S;
        if abs(bn - b) < 1e-7, b = bn; return; end
        b = bn;
    end
end

function [top1, top10, g] = local_top_shares(dist, aG)
% Wealth shares of the top 1% / 10% by fractional mass splitting.
    wa = sum(dist, 2); wa = wa / sum(wa);
    cwHi = cumsum(wa); cwLo = [0; cwHi(1:end-1)];
    ov = @(lo) max(0, min(cwHi, 1) - max(cwLo, lo));
    tot = sum(wa .* aG);
    top1  = sum(ov(0.99) .* aG) / tot;
    top10 = sum(ov(0.90) .* aG) / tot;
    mu = tot; cxw = cumsum(wa .* aG) / mu;
    Lp = [0; cxw(1:end-1)]; Fp = [0; cwHi(1:end-1)];
    g = 1 - 2 * sum((cwHi - Fp) .* (cxw + Lp) / 2);
end
