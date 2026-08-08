% MAIN_HANK_HETEROGENEITY  Who holds the government debt, and whose demand
% moves when the financing instrument changes.
%
% ONE QUESTION PER EXHIBIT. This driver answers exactly one:
%
%     When the same real program is financed by a lump-sum tax rather than a
%     proportional levy, WHICH households change their demand for nominal
%     government debt, and by how much?
%
% That question is the paper's mechanism stated at the household level. The
% aggregate version -- financing instrument shifts S(P), which moves P, which
% revalues the nominal stock -- is what the incidence formula prices. Until
% now the paper reported only the endpoints of that chain: an elasticity and a
% price. The distribution doing the work was computed on every one of the
% seventeen household solves inside each regime bisection and then discarded
% one line later, because solve_regime_equilibrium kept two scalars out of it.
% It now keeps the household block at the root, at no extra cost, and this
% driver plots it.
%
% WHY THIS ECONOMY AND NOT THE TWO-ASSET ONE. The one-asset economy is the one
% that passes the numerical acceptance protocol. Under the Option A rescoping
% the two-asset specifications report the financing ORDERING and decline to
% report a level, so a heterogeneity exhibit drawn from them could not be
% quoted. Every number here is from the certified economy.
%
% WHAT IT PLOTS, and what each panel is for:
%
%   (a) the ergodic wealth distribution under each financing regime, as a
%       density over the asset grid. This is the object the model is about;
%       the paper has never shown it.
%   (b) the DECOMPOSITION of the change in aggregate bond demand: the
%       cumulative contribution to S^levy - S^lumpsum as one moves up the
%       wealth distribution. Its endpoint is the aggregate change, and its
%       shape says which households supply it. This panel is the answer to
%       the question in the title.
%   (c) the marginal propensity to consume by wealth, by income state. It
%       identifies the constrained region, which is where an instrument that
%       taxes proportionally rather than lump-sum does its work.
%   (d) the Lorenz curve of bond holdings. In a one-asset economy household
%       assets ARE the government debt, so this is literally the ownership
%       distribution -- the object the paper's incidence claim is about, and
%       the one a reader has to take on trust today.
%
% INPUT   output/regimes_results.mat, written by main_project_regimes.
%         That driver must have been run at R11.44 or later; earlier runs
%         predate the .hh field and this driver says so rather than failing
%         obscurely.
% OUTPUT  output/figures/PFig23_hank_heterogeneity.{fig,png,pdf}
%         output/tables/hank_heterogeneity.txt   (the numbers behind it)
%
% USAGE   >> clear; main_hank_heterogeneity
% COST    seconds. Nothing is solved here.

clear; close all; clc;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
run_project_path_setup(struct('quiet', true));

pg = setup_params_green();
pg.figdir = fullfile(projdir, 'output', 'figures');
if ~isfolder(pg.figdir), mkdir(pg.figdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'hank_heterogeneity.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});

tee('HANK HETEROGENEITY: WHO HOLDS THE DEBT, AND WHOSE DEMAND MOVES\n');
tee('%s\n', kv_code_version(mfilename('fullpath')));
tee('read-only over output/regimes_results.mat; nothing is solved here.\n\n');

f = fullfile(projdir, 'output', 'regimes_results.mat');
if exist(f, 'file') ~= 2
    tee('regimes_results.mat not found. Run: clear; main_project_regimes\n');
    fclose(fid); return;
end
L = load(f);
if ~isfield(L, 'RREG') || isempty(L.RREG)
    tee('regimes_results.mat has no RREG. Re-run main_project_regimes.\n');
    fclose(fid); return;
end
RREG = L.RREG;

% A .mat WITHOUT .hh IS OLD, NOT BROKEN. The field was added when the regime
% solver stopped discarding its own household block. Say which driver to
% re-run rather than dot-indexing into a struct that does not have it -- the
% same staleness lesson the identification ledger learned.
if ~isfield(RREG, 'hh') || all(arrayfun(@(x) isempty(x.hh), RREG))
    tee('*** regimes_results.mat predates the .hh household block (R11.44).\n');
    tee('*** It loads, and it simply does not carry the distributions this\n');
    tee('*** figure plots. Re-run:  clear; main_project_regimes\n');
    fclose(fid); return;
end

aG = pg.aGrid(:);
na = numel(aG);

% ---- pick the regimes this exhibit contrasts --------------------------
% Lump-sum and levy finance the SAME real program and differ only in
% incidence, which is what makes their difference a clean financing-design
% contrast. The rebate is carried as the progressive third point.
want = {'R1-LUMPSUM', 'R2-PROP-LEVY', 'R3-PROP-LEVY-REBATE'};
lab  = {'lump-sum', 'proportional levy', 'levy plus rebate'};
sty  = {'lumpsum', 'levy', 'rebate'};
idx  = nan(1, numel(want));
for i = 1:numel(want)
    j = find(strcmp({RREG.name}, want{i}), 1, 'first');
    if ~isempty(j) && ~isempty(RREG(j).hh), idx(i) = j; end
end
keep = ~isnan(idx);
if sum(keep) < 2
    tee('fewer than two of the contrasted regimes carry a household block;\n');
    tee('re-run main_project_regimes.\n'); fclose(fid); return;
end

% ---- marginals, aggregates ---------------------------------------------
WA = nan(na, numel(want));       % wealth marginal per regime
Sagg = nan(1, numel(want));
for i = find(keep)
    d = RREG(idx(i)).hh.dist;
    WA(:, i) = sum(d, 2);
    WA(:, i) = WA(:, i) / sum(WA(:, i));      % guard against drift
    Sagg(i)  = aG' * WA(:, i);
end

tee('%-22s %10s %10s %12s\n', 'regime', 'P', 'S (assets)', 'gini(wealth)');
for i = find(keep)
    R = RREG(idx(i));
    g = NaN; if isfield(R.hh,'gini_a'), g = R.hh.gini_a; end
    tee('%-22s %10.4f %10.4f %12.4f\n', lab{i}, R.P, Sagg(i), g);
end
tee('\n');

fh = figure('Name','PFig23: HANK heterogeneity','Color','w', ...
            'Position',[60 60 1150 760]);

% ===== (a) the ergodic wealth distribution ==============================
% Plotted over the region that carries the mass. A full-grid x-axis would be
% mostly empty: the grid is built with curvature to resolve the constrained
% region, and the top of it exists for the superstar tail.
subplot(2,2,1); hold on; box on;
cut = find(cumsum(WA(:, find(keep,1))) > 0.995, 1, 'first');
if isempty(cut), cut = na; end
xmax = aG(min(cut, na));
for i = find(keep)
    [c, ls] = regime_style(sty{i});
    plot(aG, WA(:, i), 'LineWidth', 2.0, 'Color', c, 'LineStyle', ls);
end
xlim([0 xmax]);
xlabel('assets  a  (multiples of mean income)');
ylabel('ergodic mass');
title('(a) the wealth distribution, by financing regime');
legend(lab(keep), 'Location', 'northeast');

% ===== (b) where the change in bond demand comes from ===================
% cumsum(a .* (w_levy - w_lumpsum)) as a function of a. The endpoint is
% S^levy - S^lumpsum exactly; the path says which households deliver it.
% This is the panel the exhibit exists for.
subplot(2,2,2); hold on; box on;
ils = find(strcmp(want,'R1-LUMPSUM'));
if keep(ils)
    for i = find(keep)
        if i == ils, continue; end
        contrib = cumsum(aG .* (WA(:, i) - WA(:, ils)));
        [c, ls] = regime_style(sty{i});
        plot(aG, contrib, 'LineWidth', 2.0, 'Color', c, 'LineStyle', ls);
        tee('cumulative dS at the top of the grid, %s minus lump-sum: %+0.5f\n', ...
            lab{i}, contrib(end));
    end
end
yline(0, 'k-', 'HandleVisibility', 'off');
xlim([0 xmax]);
xlabel('assets  a');
ylabel('cumulative contribution to \DeltaS');
title('(b) which households change their bond demand');

% ===== (c) MPC by wealth and income state ===============================
% MPC out of cash on hand. Along the asset dimension, d(coh)/da = 1 + r, so
% the MPC is the slope of the consumption policy in a, divided by (1+r).
% Reported for the lowest, median and highest income states: the spread
% between them is the heterogeneity a representative agent cannot carry.
subplot(2,2,3); hold on; box on;
i0 = find(keep, 1, 'first');
H  = RREG(idx(i0)).hh;
% The real rate is not a stored field anywhere: the project derives it from
% the Fisher identity at the policy pair, exactly as main_project_regimes
% does at its line 71. Deriving it the same way here rather than inventing a
% pg.r_ss that does not exist.
pgr = pg; if isfield(L,'pgc') && isstruct(L.pgc), pgr = L.pgc; end
r_use = NaN;
if isfield(pgr,'i_ss') && isfield(pgr,'mu')
    r_use = (1 + pgr.i_ss)/(1 + pgr.mu) - 1;
end
if isfield(H, 'polC') && ~isempty(H.polC) && isfinite(r_use)
    ne = size(H.polC, 2);
    pick = unique([1, max(1, round(ne/2)), ne]);
    nm = {'lowest income', 'median income', 'highest income'};
    da = diff(aG);
    % The axis is clipped to [0,1] because that is where an MPC belongs, but
    % clipping a diagnostic silently is how a bad policy function survives a
    % figure. The RAW range is reported to the table: anything outside [0,1]
    % is a statement about the solve, not about the economy.
    for t = 1:numel(pick)
        mpc = diff(H.polC(:, pick(t))) ./ da / (1 + r_use);
        tee('MPC range, %-14s : [%+0.3f, %+0.3f]%s\n', nm{t}, ...
            min(mpc), max(mpc), ...
            ternstr_(min(mpc) < -1e-6 || max(mpc) > 1+1e-6, ...
                     '   <== OUTSIDE [0,1], inspect the policy', ''));
        plot(aG(1:end-1), min(max(mpc, 0), 1), 'LineWidth', 1.8);
    end
    xlim([0 xmax]); ylim([0 1]);
    xlabel('assets  a'); ylabel('MPC out of cash on hand');
    title('(c) consumption response, by income state');
    legend(nm(1:numel(pick)), 'Location', 'northeast');
else
    text(0.5, 0.5, 'polC or r unavailable', 'HorizontalAlignment','center');
    title('(c) MPC -- unavailable');
end

% ===== (d) the Lorenz curve of bond holdings ============================
% In the one-asset economy household assets ARE the government debt, so the
% Lorenz curve of a is the ownership distribution of the nominal stock. The
% incidence result says the revaluation accrues along this curve.
subplot(2,2,4); hold on; box on;
for i = find(keep)
    w = WA(:, i);
    popc = cumsum(w);
    valc = cumsum(aG .* w); valc = valc / max(valc(end), eps);
    [c, ls] = regime_style(sty{i});
    plot(popc, valc, 'LineWidth', 2.0, 'Color', c, 'LineStyle', ls);
end
plot([0 1], [0 1], 'k:', 'LineWidth', 1.0, 'HandleVisibility','off');
xlim([0 1]); ylim([0 1]);
xlabel('cumulative share of households');
ylabel('cumulative share of bonds held');
title('(d) who holds the nominal debt');

save_all_figs(fh, 'PFig23_hank_heterogeneity', pg);

% ---- the numbers behind the picture ------------------------------------
tee('\nOWNERSHIP CONCENTRATION (panel d), by financing regime\n');
tee('%-22s %12s %12s %12s\n', 'regime', 'bottom 50%', 'top 10%', 'top 1%');
for i = find(keep)
    w = WA(:, i); popc = cumsum(w);
    valc = cumsum(aG .* w); valc = valc / max(valc(end), eps);
    % MOST GRID POINTS CARRY NO MASS, so the population CDF has long flat
    % stretches and interp1 would reject it: its sample points must be
    % distinct. Take the last index at each distinct CDF value, which is the
    % top of each plateau and the correct representative for a quantile.
    [pu, iu] = unique(popc, 'last');
    vu = valc(iu);
    b50 = interp1(pu, vu, 0.50, 'linear', 'extrap');
    t10 = 1 - interp1(pu, vu, 0.90, 'linear', 'extrap');
    t01 = 1 - interp1(pu, vu, 0.99, 'linear', 'extrap');
    tee('%-22s %11.1f%% %11.1f%% %11.1f%%\n', lab{i}, 100*b50, 100*t10, 100*t01);
end
tee(['\nRead panel (d) with the incidence formula: the revaluation of the\n' ...
     'nominal stock accrues along this curve, so the concentration reported\n' ...
     'here is the distribution of the transfer, not a descriptive aside.\n']);

% HOW CONCENTRATED IS THIS ECONOMY, AGAINST THE TARGET THE PROJECT USES?
% Panel (d) is ABOUT concentration, and the incidence claim is about who
% holds the debt, so an economy that understates concentration understates
% the very thing the panel is for. The superstar state exists to hit the
% top-1% share and it is OFF by default in setup_params_green, so this must
% be measured and stated rather than left for a reader to assume.
ss_on = false;
pgs = pg; if isfield(L,'pgc') && isstruct(L.pgc), pgs = L.pgc; end
if isfield(pgs,'superstar') && isstruct(pgs.superstar) && ...
        isfield(pgs.superstar,'active')
    ss_on = logical(pgs.superstar.active);
end
t1_target = NaN;
wf = fullfile(projdir, 'output', 'wealth_fit_results.mat');
if exist(wf, 'file') == 2
    WF = load(wf, 'TOP1_TARGET');
    if isfield(WF, 'TOP1_TARGET'), t1_target = WF.TOP1_TARGET; end
end
i1 = find(keep, 1, 'first');
w1 = WA(:, i1); pc1 = cumsum(w1);
vc1 = cumsum(aG .* w1); vc1 = vc1 / max(vc1(end), eps);
[pu1, iu1] = unique(pc1, 'last');
t1_model = 1 - interp1(pu1, vc1(iu1), 0.99, 'linear', 'extrap');

tee('\nHOW CONCENTRATED IS THIS ECONOMY?\n');
tee('  superstar income state active in this run : %d\n', ss_on);
tee('  model top-1%% wealth share                 : %.1f%%\n', 100*t1_model);
if isfinite(t1_target)
    tee('  target used by wealth_concentration_fit   : %.1f%%\n', 100*t1_target);
    if t1_model < 0.5 * t1_target
        tee(['  *** THE PANEL UNDERSTATES CONCENTRATION BY MORE THAN HALF.\n' ...
             '  *** This economy carries no superstar state, so its top tail is\n' ...
             '  *** the Rouwenhorst tail and nothing else. The ORDERING and the\n' ...
             '  *** MECHANISM in panels (a)-(c) do not depend on that; panel (d)\n' ...
             '  *** does. Quote panel (d) as the model''s ownership curve, never\n' ...
             '  *** as a calibrated one, and do not compare its shares to data.\n' ...
             '  *** To close the gap the regime run needs the superstar state\n' ...
             '  *** switched on, which is a recalibration and not a re-plot.\n']);
    end
else
    tee('  no TOP1_TARGET on disk; run wealth_concentration_fit to compare.\n');
end

tee('\n[main_hank_heterogeneity] wrote %s\n', sf);
fclose(fid);
fprintf('[main_hank_heterogeneity] wrote PFig23 and %s\n', sf);

% =========================================================================
function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr_(c, a, b)
    if c, s = a; else, s = b; end
end
