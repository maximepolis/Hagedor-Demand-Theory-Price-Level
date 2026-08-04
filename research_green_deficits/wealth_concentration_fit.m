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

% SECOND CONCENTRATION MOMENT (referee R12 Major 2; ledger verdict V1).
% (mult, p_in) are TWO free parameters and were selected on ONE moment, so a
% one-dimensional family of configs reproduces any given top-1% share and the
% selected point is a property of the search grid rather than of the data.
% The fix is nearly free: top10 and gini are already computed for every
% config below, so a second target costs no additional solve.
%
% Left as a NaN SLOT on purpose. Filling it with a number from memory would
% be worse than leaving the fit under-identified, because a wrong target
% silently moves every downstream result instead of announcing itself.
% Transcribe from the SCF summary tables (record the vintage and the
% net-worth definition alongside TOP1_TARGET's own source), then re-run.
%
% While it is NaN the selection rule is BIT-IDENTICAL to the previous
% single-moment rule, so nothing downstream changes and no dependent result
% needs regenerating. What DOES run either way is the identification
% diagnostic below, which measures the flat direction instead of asserting
% it: it reports how much top10 and gini vary among the configs that match
% the top-1% target equally well. If that spread is wide, the fit is
% under-identified as a matter of arithmetic, not of opinion.
TOP10_TARGET = NaN;      % [SCF] top-10% net-worth share -- TRANSCRIBE
TOP1_BAND    = 0.02;     % configs within this of TOP1_TARGET count as ties

calf = fullfile(projdir, 'output', 'calibrated_results.mat');
assert(exist(calf, 'file') == 2, 'wealth_concentration_fit: run main_project_calibrated first.');
L = load(calf, 'RCAL', 'pgc');
RCAL = L.RCAL; pgc = L.pgc;

% SOLVER + GRID for the augmented economy. Pin to the grid-choice VFI: the
% EGM extrapolation is unreliable for the superstar column (a 8-16x income
% state saves far past amax, and interp1-extrap on its endogenous grid can
% return nonfinite consumption). Extend amax so the high earners have room
% to accumulate -- otherwise their mass piles at the top node and the
% top-1% share cannot reach the data target regardless of beta.
pgc.hh_solver = 'vfi';
if isfield(pgc, 'amax') && isfield(pgc, 'na') && isfield(pgc, 'abar') ...
        && exist('make_asset_grid', 'file') == 2
    acurv = 2.5; if isfield(pgc, 'acurv'), acurv = pgc.acurv; end
    pgc.amax  = max(pgc.amax, 300);           % headroom for the superstar tail
    pgc.aGrid = make_asset_grid(-pgc.abar, pgc.amax, pgc.na, acurv);
end

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
if isempty(okF)
    % Graceful exit (not a crash) so run_green_deficits_master continues:
    % write a diagnostic table and a NO-FIT results file instead of erroring.
    warning('wealth_concentration_fit:nofit', ...
        'No superstar config solved; writing NO-FIT diagnostic and returning.');
    tabdir = fullfile(projdir, 'output', 'tables');
    if ~isfolder(tabdir), mkdir(tabdir); end
    fid = fopen(fullfile(tabdir, 'wealth_fit.txt'), 'w');
    fprintf(fid, 'WEALTH-CONCENTRATION FIT -- NO CONFIG SOLVED\n');
    fprintf(fid, ['Every (mult,p_in) config returned a non-bracketing or ' ...
        'infeasible beta bisection.\nCheck: amax headroom for the superstar ' ...
        'tail, feasibility of tau=r*b at\nthe augmented min-endowment state, ' ...
        'and the [%.3f, ...] beta bracket.\n'], 0.85);
    fclose(fid);
    save(fullfile(projdir, 'output', 'wealth_fit_results.mat'), ...
         'FIT', 'r_cal', 'TOP1_TARGET', 'B_TARGET');
    fprintf('Wrote NO-FIT diagnostic. Elapsed %.1f s\n', toc(t0));
    return;
end
% ---- Stage 1b: the identification diagnostic, then the selection ----
% This runs before the selection on purpose. It measures whether the moment
% actually discriminates among the configs, which is a property of the fit
% and not of whichever config happens to win.
d1   = abs([okF.top1] - TOP1_TARGET);
ties = d1 <= TOP1_BAND;
IDENT = struct('n_ok', numel(okF), 'n_ties', sum(ties), ...
               'top1_band', TOP1_BAND, 'top10_spread', NaN, ...
               'gini_spread', NaN, 'underidentified', false, ...
               'rule', '', 'top10_target', TOP10_TARGET);
fprintf('--- identification diagnostic (ledger V1) ---\n');
fprintf('  %d configs solved; %d within %.2f of the top-1%% target.\n', ...
        numel(okF), sum(ties), TOP1_BAND);
if sum(ties) >= 2
    t10 = [okF(ties).top10]; gg = [okF(ties).gini];
    IDENT.top10_spread = max(t10) - min(t10);
    IDENT.gini_spread  = max(gg)  - min(gg);
    IDENT.underidentified = IDENT.top10_spread > TOP1_BAND;
    fprintf('  among those ties: top-10%% share spans %.3f, gini spans %.3f.\n', ...
            IDENT.top10_spread, IDENT.gini_spread);
    if IDENT.underidentified
        fprintf(['  => UNDER-IDENTIFIED. Configs that fit the top-1%% share\n' ...
                 '     equally well disagree about the top-10%% share by more\n' ...
                 '     than the tie band, so the single moment does not pin\n' ...
                 '     the distribution and the winner is chosen by the grid.\n']);
    else
        fprintf(['  => the tied configs agree on the untargeted moments, so\n' ...
                 '     the single moment happens to be locally sufficient HERE.\n' ...
                 '     That is a property of this grid, not a general result.\n']);
    end
else
    fprintf(['  fewer than two ties: the diagnostic cannot separate a\n' ...
             '  well-identified fit from a coarse search grid. Refine the\n' ...
             '  (mult, p_in) grid before reading this as identification.\n']);
end

if isfinite(TOP10_TARGET)
    % Equal RELATIVE weight, so the larger share does not dominate the
    % criterion merely by being larger.
    crit = (([okF.top1]  - TOP1_TARGET)  / TOP1_TARGET ).^2 + ...
           (([okF.top10] - TOP10_TARGET) / TOP10_TARGET).^2;
    [~, ib] = min(crit);
    IDENT.rule = 'two-moment (top-1% and top-10%), equal relative weight';
else
    [~, ib] = min(d1);
    IDENT.rule = 'single-moment (top-1% only) -- TOP10_TARGET not transcribed';
end
best = okF(ib);
fprintf('Selection rule: %s\n', IDENT.rule);
fprintf('Selected: mult %.0f, p_in %.0e (top1 %.1f%% vs target %.0f%%, ', ...
        best.mult, best.p_in, 100*best.top1, 100*TOP1_TARGET);
if isfinite(TOP10_TARGET)
    fprintf('top10 %.1f%% vs target %.1f%%).\n', 100*best.top10, 100*TOP10_TARGET);
else
    fprintf('top10 %.1f%% UNTARGETED).\n', 100*best.top10);
end

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
     'FIT', 'best', 'dec', 'wd', 'r_cal', 'TOP1_TARGET', 'B_TARGET', ...
     'TOP10_TARGET', 'IDENT');

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
fprintf(fid, 'Selection rule: %s\n', IDENT.rule);
fprintf(fid, ['IDENTIFICATION (ledger V1): %d configs solved, %d within ' ...
    '%.2f of the\ntop-1%% target.\n'], IDENT.n_ok, IDENT.n_ties, IDENT.top1_band);
if IDENT.n_ties >= 2
    fprintf(fid, ['Among the tied configs the top-10%% share spans %.3f and ' ...
        'the gini spans\n%.3f. '], IDENT.top10_spread, IDENT.gini_spread);
    if IDENT.underidentified
        fprintf(fid, ['UNDER-IDENTIFIED: one moment does not pin the ' ...
            'distribution, so\nthe selected config is a property of the ' ...
            'search grid rather than of the\ndata. Transcribe TOP10_TARGET ' ...
            'to close this at no additional solve cost.\n']);
    else
        fprintf(fid, ['The tied configs agree on the untargeted moments, so ' ...
            'the single\nmoment is locally sufficient on THIS grid. That is ' ...
            'not a general result.\n']);
    end
else
    fprintf(fid, ['Fewer than two ties: the diagnostic cannot separate a ' ...
        'well-identified\nfit from a coarse search grid.\n']);
end
if ~isfinite(TOP10_TARGET)
    fprintf(fid, ['The top-10%% share is therefore an UNTARGETED prediction ' ...
        'of this fit\nand belongs in the validation census, not in the ' ...
        'targeted-moment count.\n']);
end
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
    % hi must keep beta*(1+r) safely BELOW betaR_max (=0.999): the old
    % min(0.999,(1-1e-4)/(1+r)) gave beta*(1+r)=0.99984>=0.999 at r=0.0196,
    % so S_green returned Inf and every config aborted with NaN. Match
    % calibrate_beta's safe ceiling. Adding the superstar state raises
    % aggregate saving, so the beta that hits the SAME debt target is LOWER
    % than the baseline betaStar, and [0.85,0.955] brackets it.
    betaR_max = 0.999; if isfield(pgs,'betaR_max'), betaR_max = pgs.betaR_max; end
    lo = 0.85; hi = min(0.955, 0.9985 * betaR_max / (1 + r));
    ok = false; b_star = NaN;
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
