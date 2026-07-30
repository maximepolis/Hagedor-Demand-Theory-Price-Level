% MAIN_VALIDATION_MOBILITY  Model-side wealth-mobility and liquid-asset
% transition moments, for the external validation of the dominant
% distributional term (referee item MC2(i)).
%
% WHY THIS EXISTS. Nine-tenths of the tax response of nominal-liability
% demand operates through the ENDOGENOUS WEALTH DISTRIBUTION (the
% decomposition in the safe-asset-channel section): a lump-sum tax pushes
% constraint-adjacent households toward the borrowing limit and the
% distribution reshuffles. That term is model-mediated, and the referee's
% ask is exactly right: the dynamics that carry it -- how fast households
% move through the wealth distribution, how persistent constrained status
% is -- are observable in panel data, so the model's mobility should be
% held against measured mobility BEFORE the distributional term is trusted
% quantitatively. This driver computes the MODEL side of that comparison
% on the calibrated benchmark. The DATA column is intentionally left as
% documented NaN slots: the published moments must be transcribed from the
% cited sources by hand (they are not bundled with the replication package,
% and no number should enter the paper untraced). Fill DATA below, re-run,
% and the driver prints the comparison and flags moments off by more than
% the stated band.
%
% SOURCES for the data column (transcribe, then cite in the paper):
%   [HLS]  Hurst, Luoh & Stafford (1998, BPEA): PSID 1984-89 and 1989-94
%          five-year wealth-quintile transition matrices.
%   [SCF]  Bricker et al., SCF 2007-09 panel: two-year wealth transitions.
%   [KVW]  Kaplan, Violante & Weidner (2014, BPEA): hand-to-mouth
%          persistence (share of HtM households still HtM after 2 years).
%
% The model is ANNUAL; the driver reports 2- and 5-year horizons to match.
%
% USAGE   >> clear; main_validation_mobility
%         >> clear; FAST = true; main_validation_mobility
% OUTPUT  output/tables/validation_mobility.txt, output/validation_mobility.mat

clearvars -except FAST; close all; clc;
rng(20260730, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end

% ---- DATA: transcribe from the cited sources, then re-run ----
% Each entry: {label, horizon(yrs), model slot (filled below), data, band}
% band = acceptable absolute gap before the driver flags the moment.
DATA = struct();
DATA.q1_stay_5y   = NaN;   % [HLS] P(bottom wealth quintile -> bottom, 5y)
DATA.q5_stay_5y   = NaN;   % [HLS] P(top -> top, 5y)
DATA.shorrocks_5y = NaN;   % [HLS] Shorrocks trace index of the 5y matrix
DATA.q1_stay_2y   = NaN;   % [SCF] P(bottom -> bottom, 2y)
DATA.q5_stay_2y   = NaN;   % [SCF] P(top -> top, 2y)
DATA.htm_stay_2y  = NaN;   % [KVW] P(HtM -> HtM, 2y)
BAND = 0.10;               % flag gaps beyond 10 percentage points

% ---- calibrated benchmark (same protocol as every tier-2 driver) ----
D0_med = 0.06;
r_ss = (1 + pg.i_ss)/(1 + pg.mu) - 1;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
beta_star = [];
if exist(calfile, 'file') == 2
    L = load(calfile);
    if isfield(L.RCAL, 'na') && L.RCAL.na == pg.na
        beta_star = L.RCAL.beta_star;
        fprintf('loaded calibration (na=%d): beta*=%.4f\n', pg.na, beta_star);
    end
end
if isempty(beta_star)
    fprintf('recalibrating beta on this grid (na=%d)...\n', pg.na);
    [beta_star, ~] = calibrate_beta(pg, r_ss, 1.10, D0_med);
end
pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;

% baseline stationary economy: debt/income at the 1.10 target, no program
tau0 = r_ss * 1.10;
[Sagg, out] = S_green(r_ss, tau0, D0_med, pgc);
assert(isfinite(Sagg) && out.feasible, 'baseline household solve failed');
dist = out.dist; polA = out.polA; Pi = out.Pi_eff;
aG = pgc.aGrid(:); na = numel(aG); ne = size(Pi, 1);

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'validation_mobility.txt');
fid = fopen(sf, 'w'); assert(fid > 0, 'cannot open %s', sf);
tee = @(varargin) tee2(fid, varargin{:});
tee('WEALTH-MOBILITY VALIDATION MOMENTS (model side). na=%d ne=%d beta=%.4f\n', ...
    na, ne, beta_star);
tee('baseline: tau = r*1.10, D = %.2f; S = %.4f (annual model)\n\n', D0_med, Sagg);

% ---- full (a,e) transition matrix: Young lottery x income mixing ----
A  = min(max(polA, aG(1)), aG(end));
kk = discretize(A, aG); kk = min(max(kk, 1), na - 1);
ww = (aG(kk + 1) - A) ./ (aG(kk + 1) - aG(kk));
ww = min(max(ww, 0), 1);
rows = cell(ne,1); cols = cell(ne,1); vals = cell(ne,1);
ridx = (1:na)';
for e = 1:ne
    src = ridx + (e-1)*na;
    r2 = repmat([src; src], ne, 1);
    c2 = zeros(2*na*ne, 1); v2 = zeros(2*na*ne, 1);
    for ep = 1:ne
        ix = (ep-1)*2*na + (1:2*na);
        c2(ix) = [kk(:,e); kk(:,e)+1] + (ep-1)*na;
        v2(ix) = [ww(:,e); 1-ww(:,e)] * Pi(e, ep);
    end
    rows{e} = r2; cols{e} = c2; vals{e} = v2;
end
M = sparse(vertcat(rows{:}), vertcat(cols{:}), vertcat(vals{:}), na*ne, na*ne);

% ---- wealth-quintile transition matrices at h = 2 and 5 years ----
w = dist(:) / sum(dist(:));
wealth = repmat(aG, ne, 1);
edges = wquantile(wealth, w, [0.2 0.4 0.6 0.8]);
qid = 1 + sum(wealth > edges(:)', 2);            % 1..5 per (a,e) state
Q2 = qmat(M, w, qid, 2); Q5 = qmat(M, w, qid, 5);
sh2 = (5 - trace(Q2)) / 4; sh5 = (5 - trace(Q5)) / 4;

tee('wealth-quintile transition matrix, 2-year horizon (rows = origin):\n');
print_qmat(tee, Q2);
tee('Shorrocks trace index (2y): %.3f\n\n', sh2);
tee('wealth-quintile transition matrix, 5-year horizon:\n');
print_qmat(tee, Q5);
tee('Shorrocks trace index (5y): %.3f\n\n', sh5);

% ---- constrained / hand-to-mouth persistence ----
% constrained region: within one grid step of the borrowing limit (the
% region carrying the distributional term's action)
con = wealth <= aG(1) + max(0.02, aG(3) - aG(1));
p_con = sum(w(con));
stay2 = stayprob(M, w, con, 2);
tee('constrained mass (a near the limit): %.3f\n', p_con);
tee('P(constrained -> still constrained, 2y): %.3f\n', stay2);
tee('P(escape within 2y): %.3f\n\n', 1 - stay2);

MODEL = struct('q1_stay_5y', Q5(1,1), 'q5_stay_5y', Q5(5,5), ...
    'shorrocks_5y', sh5, 'q1_stay_2y', Q2(1,1), 'q5_stay_2y', Q2(5,5), ...
    'htm_stay_2y', stay2);

% ---- comparison table (data slots may be NaN until transcribed) ----
tee('----- validation table (fill DATA in this file, re-run) -----\n');
tee('%-16s %8s %8s %8s  %s\n', 'moment', 'model', 'data', 'gap', 'status');
fn = fieldnames(MODEL);
n_filled = 0; n_flag = 0;
for i = 1:numel(fn)
    mv = MODEL.(fn{i}); dv = DATA.(fn{i});
    if isnan(dv)
        tee('%-16s %8.3f %8s %8s  %s\n', fn{i}, mv, '--', '--', 'data pending');
    else
        n_filled = n_filled + 1;
        gap = mv - dv;
        flag = abs(gap) > BAND;
        n_flag = n_flag + flag;
        tee('%-16s %8.3f %8.3f %+8.3f  %s\n', fn{i}, mv, dv, gap, ...
            ternstr(flag, 'FLAG: outside band', 'within band'));
    end
end
if n_filled == 0
    tee(['\nNo data moments transcribed yet. The model column above is the\n' ...
         'deliverable of this run; the comparison activates once the cited\n' ...
         'moments are entered. Until then the paper must continue to state\n' ...
         'the distributional term as externally unvalidated.\n']);
else
    tee('\n%d of %d moments transcribed; %d flagged outside the %.2f band.\n', ...
        n_filled, numel(fn), n_flag, BAND);
end

save(fullfile(projdir, 'output', 'validation_mobility.mat'), ...
     'MODEL', 'DATA', 'Q2', 'Q5', 'sh2', 'sh5', 'stay2', 'p_con', 'edges');
tee('\n[main_validation_mobility] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% ========================================================================
function q = wquantile(x, w, ps)
    [xs, io] = sort(x); cw = cumsum(w(io));
    q = zeros(size(ps));
    for i = 1:numel(ps)
        q(i) = xs(find(cw >= ps(i), 1, 'first'));
    end
end

function Q = qmat(M, w, qid, h)
% stationary-weighted quintile transition matrix at horizon h:
% start from the stationary mass restricted to quintile i, push h years,
% integrate the arrival mass by quintile.
    Q = zeros(5, 5);
    for i = 1:5
        v = w .* (qid == i);
        mi = sum(v);
        if mi <= 0, continue; end
        for s = 1:h, v = (M' * v); end
        for j = 1:5
            Q(i, j) = sum(v(qid == j)) / mi;
        end
    end
end

function s = stayprob(M, w, msk, h)
    v = w .* msk;
    m0 = sum(v);
    for s2 = 1:h, v = (M' * v); end
    s = sum(v(msk)) / max(m0, eps);
end

function print_qmat(tee, Q)
    tee('        to Q1     Q2     Q3     Q4     Q5\n');
    for i = 1:5
        tee('  Q%d   %6.3f %6.3f %6.3f %6.3f %6.3f\n', i, Q(i,:));
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
