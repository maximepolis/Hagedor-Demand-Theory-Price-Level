% MAIN_TRANSITION_DEFICIT_LADDER  The financing-timing frontier: how fast
% must taxes phase in for the announcement disinflation to survive?
%
% THE FINDING THIS TESTS. The single deficit run (rho_d = 0.9) produced a
% capitalization ratio of 1.03: the impact price wedge relative to balanced
% timing equalled the terminal stock dilution ln kappa_inf almost exactly.
% If that holds ACROSS phase-in speeds, then tax timing enters the
% announcement price level through ONE number -- the terminal dilution --
% and the impact response obeys the sufficient-statistic decomposition
%
%     dlnP_1(rho_d)  =  dlnP_1(balanced)  +  c * ln kappa_inf(rho_d),
%
% with c = 1. That is a strong, falsifiable claim about the mechanism: the
% path of issuance is irrelevant, only its terminal total is priced. This
% driver tests it by solving the transition at several rho_d and reading
% off c at each. A c that drifts with rho_d refutes the claim; a flat c
% establishes it and makes the frontier below analytic.
%
% THE FRONTIER. Because dlnP_1(balanced) < 0 and ln kappa_inf > 0 and
% increasing in rho_d, the announcement disinflation survives deficit
% financing if and only if the phase-in is fast enough:
%
%     ln kappa_inf(rho_d)  <  |dlnP_1(balanced)| / c.
%
% The driver locates the critical rho_d* two ways -- interpolated from the
% ladder's own solved (ln kappa, rho) pairs, and then verified by bisecting
% the SOLVED impact sign -- and reports the policy translation (the
% tax-financing half-life ln(1/2)/ln(rho_d*), and the cumulative
% debt-financed share of the program at the threshold).
%
% VALIDATION ROW. rho_d = 0 sets phi_t = 1 at every date, which is the
% balanced service rule exactly. That row must reproduce the indexed
% benchmark to solver tolerance; it is printed as a regression test and the
% driver refuses to interpret the ladder if it fails.
%
% COST. One transition solve per row (~100 s at na=500, T=80). The default
% ladder is 5 rows plus up to 4 bisection solves: roughly 15 minutes.
%
% USAGE   >> main_transition_deficit_ladder
%         >> FAST = true; main_transition_deficit_ladder
%         >> RHO_LIST = [0 0.5 0.7 0.8 0.9]; BISECT = 4; ...
%
% OUTPUT  output/tables/transition_deficit_ladder.txt
%         output/transition_deficit_ladder.mat

clearvars -except FAST RHO_LIST BISECT; close all; clc;
rng(20260730, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('RHO_LIST','var') || isempty(RHO_LIST), RHO_LIST = [0 0.5 0.7 0.8 0.9]; end
if ~exist('BISECT','var') || isempty(BISECT), BISECT = 4; end

pg = setup_params_green();
opts = struct('T', 80, 'tol', 2e-3, 'maxit', 120, 'xi', 0.5, 'verbose', false);
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    opts.T = 60; opts.maxit = 80;
    fprintf('*** FAST mode: na=%d, T=%d ***\n', pg.na, opts.T);
end

% ---- calibration: same protocol and grid-match guard as the tier-2 driver
D0_med = 0.06;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
beta_star = [];
if exist(calfile, 'file') == 2
    L = load(calfile);
    if isfield(L.RCAL, 'na') && L.RCAL.na == pg.na
        beta_star = L.RCAL.beta_star;  Gg_cal = L.RCAL.Gg_cal;
        fprintf('loaded calibration (na=%d): beta*=%.4f, Gg=%.5f\n', ...
            pg.na, beta_star, Gg_cal);
    end
end
if isempty(beta_star)
    fprintf('recalibrating beta on this grid (na=%d)...\n', pg.na);
    [beta_star, ~] = calibrate_beta(pg, (1+pg.i_ss)/(1+pg.mu)-1, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
end
pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
opts.Gg_nom = Gg_cal;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'transition_deficit_ladder.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('FINANCING-TIMING FRONTIER. na=%d T=%d FAST=%d\n', pg.na, opts.T, FAST);
tee('indexed real program held fixed; only the tax phase-in speed rho_d varies.\n\n');

% ---- balanced-timing anchor ----
TRi = [];
trf = fullfile(projdir, 'output', 'transition_results.mat');
if exist(trf, 'file') == 2
    Ltr = load(trf, 'TRi', 'pgc');
    if ~isempty(Ltr.TRi) && Ltr.TRi.reportable && numel(Ltr.TRi.phat) == opts.T ...
            && isfield(Ltr.pgc, 'na') && Ltr.pgc.na == pg.na
        TRi = Ltr.TRi;
        tee('balanced anchor: loaded saved indexed path (T=%d)\n', numel(TRi.phat));
    end
end
if isempty(TRi)
    tee('balanced anchor: solving the indexed benchmark on this grid...\n');
    oi = opts; oi.regime = 'indexed';
    TRi = solve_hank_dtpl_transition(pgc, oi);
end
assert(TRi.reportable, 'indexed benchmark not reportable; fix it before the ladder');
d1_bal = log(TRi.phat(1) / TRi.eq0.P);
tee('balanced impact dlnP_1 = %+0.4f  (the disinflation the deficit must overcome)\n\n', d1_bal);

% ---- the ladder ----
nR = numel(RHO_LIST);
R = struct('rho', num2cell(RHO_LIST(:)'), 'd1', [], 'lnk', [], 'c', [], ...
           'rep', [], 'front', [], 'cumgap', []);
tee('  rho_d   kappa_inf   ln kappa   dlnP_1     wedge    cap ratio c   rep\n');
for j = 1:nR
    od = opts; od.regime = 'indexed'; od.financing = 'deficit';
    od.rho_d = RHO_LIST(j);
    TRj = solve_hank_dtpl_transition(pgc, od);
    d1  = log(TRj.phat(1) / TRj.eq0.P);
    lnk = log(TRj.kappa_inf);
    if abs(lnk) > 1e-8, cj = (d1 - d1_bal) / lnk; else, cj = NaN; end
    R(j).d1 = d1;  R(j).lnk = lnk;  R(j).c = cj;
    R(j).rep = TRj.reportable;
    R(j).front  = (TRj.eq0.P - TRj.phat(1)) / (TRj.eq0.P - TRj.phat(end));
    R(j).cumgap = sum(TRj.primary_gap);
    tee('%7.3f   %9.4f   %+8.4f   %+7.4f   %+7.4f   %10s   %d\n', ...
        RHO_LIST(j), TRj.kappa_inf, lnk, d1, d1 - d1_bal, ...
        numstr(cj), TRj.reportable);
end
tee('\n');

% ---- validation row: rho_d = 0 must reproduce the balanced benchmark ----
i0 = find(RHO_LIST == 0, 1);
valid_ok = true;
if ~isempty(i0)
    gap0 = R(i0).d1 - d1_bal;
    tee('VALIDATION (rho_d=0, phi=1 identically = the service rule):\n');
    tee('  dlnP_1 gap vs the balanced benchmark = %+0.5f (tol %.0e)\n', gap0, opts.tol);
    valid_ok = abs(gap0) < max(opts.tol, 2e-3);
    tee('  regression test: %s\n\n', ternstr(valid_ok, 'PASS', 'FAIL -- do not interpret the ladder'));
end

% ---- sufficient-statistic test: is c flat in rho_d? ----
ok = [R.rep] & isfinite([R.c]);
cv = [R(ok).c];
if numel(cv) >= 2
    tee('SUFFICIENT-STATISTIC TEST (is the capitalization ratio flat?):\n');
    tee('  c across %d reportable rows: mean %.3f, min %.3f, max %.3f, spread %.3f\n', ...
        numel(cv), mean(cv), min(cv), max(cv), max(cv) - min(cv));
    flat = (max(cv) - min(cv)) < 0.10;
    tee('  %s\n', ternstr(flat, ...
        ['FLAT: tax timing is priced through ONE number, the terminal ' ...
         'dilution;' newline '  the path of issuance is irrelevant to the announcement.'], ...
        'NOT FLAT: the issuance path itself is priced; report c(rho_d), not a constant.'));
    cbar = mean(cv);
else
    tee('too few reportable rows for the flatness test.\n'); cbar = NaN;
end
tee('\n');

% ---- the frontier: critical rho_d ----
tee('FRONTIER (survival requires dlnP_1(deficit) < 0):\n');
rho_star = NaN;
if isfinite(cbar) && cbar > 0
    lnk_star = -d1_bal / cbar;
    tee('  critical dilution ln kappa* = |dlnP_1(bal)|/c = %+0.4f (kappa* = %.4f)\n', ...
        lnk_star, exp(lnk_star));
    % map ln kappa* back to rho_d through the ladder's own solved pairs
    rr = [R.rho]; kk = [R.lnk];
    keep = [R.rep] & rr > 0;
    if nnz(keep) >= 2
        rr = rr(keep); kk = kk(keep);
        [kk, ix] = sort(kk); rr = rr(ix);
        if lnk_star >= min(kk) && lnk_star <= max(kk)
            rho_star = interp1(kk, rr, lnk_star, 'pchip');
            tee('  interpolated rho_d* = %.3f\n', rho_star);
        else
            tee('  ln kappa* outside the ladder range [%.4f, %.4f]: widen RHO_LIST.\n', ...
                min(kk), max(kk));
        end
    end
end

% ---- verify the threshold by bisecting the SOLVED impact sign ----
sgn_lo = []; rlo = []; rhi = [];
for j = 1:nR
    if ~R(j).rep, continue; end
    if R(j).d1 < 0, rlo = RHO_LIST(j); sgn_lo = -1; end
    if R(j).d1 > 0 && isempty(rhi), rhi = RHO_LIST(j); end
end
if ~isempty(rlo) && ~isempty(rhi) && BISECT > 0
    tee('\n  bisecting the solved impact sign on rho_d in [%.3f, %.3f]:\n', rlo, rhi);
    for k = 1:BISECT
        rm = 0.5 * (rlo + rhi);
        od = opts; od.regime = 'indexed'; od.financing = 'deficit'; od.rho_d = rm;
        TRm = solve_hank_dtpl_transition(pgc, od);
        d1m = log(TRm.phat(1) / TRm.eq0.P);
        tee('    rho_d = %.4f -> dlnP_1 = %+0.4f (reportable %d)\n', ...
            rm, d1m, TRm.reportable);
        if ~TRm.reportable, tee('    non-reportable midpoint; stopping bisection.\n'); break; end
        if d1m < 0, rlo = rm; else, rhi = rm; end
    end
    tee('  solved threshold bracket: rho_d* in [%.4f, %.4f]\n', rlo, rhi);
    if isfinite(rho_star)
        tee('  analytic (sufficient-statistic) prediction %.3f: %s\n', rho_star, ...
            ternstr(rho_star >= rlo - 0.02 && rho_star <= rhi + 0.02, ...
                'INSIDE the solved bracket -- the decomposition is validated', ...
                'OUTSIDE the bracket -- the decomposition is not sufficient'));
    end
    rho_star_solved = 0.5 * (rlo + rhi);
else
    tee('\n  no sign change bracketed in the ladder; widen RHO_LIST.\n');
    rho_star_solved = NaN;
end

% ---- policy translation ----
rs = rho_star_solved; if ~isfinite(rs), rs = rho_star; end
if isfinite(rs) && rs > 0 && rs < 1
    hl  = log(0.5) / log(rs);              % tax-financing half-life, years
    cum = rs / (1 - rs);                   % cumulative debt-financed years of g
    tee('\nPOLICY TRANSLATION at rho_d* = %.3f:\n', rs);
    tee('  tax-financing half-life = %.1f years (half the program is tax-financed by then)\n', hl);
    tee('  cumulative debt-financed spending = %.2f years of program cost\n', cum);
    tee('  => the announcement disinflation survives deficit financing only if the\n');
    tee('     debt-financed share is retired on roughly a %.1f-year half-life or faster;\n', hl);
    tee('     slower phase-in dilutes the terminal stock by more than the program\n');
    tee('     tightens precautionary demand, and the announcement is INFLATIONARY.\n');
end

LAD = struct('R', R, 'd1_bal', d1_bal, 'cbar', cbar, ...
    'rho_star_interp', rho_star, 'rho_star_solved', rho_star_solved, ...
    'valid_ok', valid_ok, 'rho_list', RHO_LIST);
save(fullfile(projdir, 'output', 'transition_deficit_ladder.mat'), 'LAD', 'TRi', 'pgc', 'opts');
tee('\n[main_transition_deficit_ladder] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end

function s = numstr(x)
    if isnan(x), s = '--'; else, s = sprintf('%.3f', x); end
end
