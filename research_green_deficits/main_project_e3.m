% MAIN_PROJECT_E3  E3: does market-implied expected inflation FALL around
% announcements of large deficit-financed green-investment programs? The
% paper predicts DISINFLATION on impact (green investment raises safe-asset
% demand and lowers the price level); a sticky-price/New-Keynesian view
% predicts inflation or neutrality. The SIGN of the breakeven-inflation
% response is the discriminating test.
%
% Three layers, increasing rigor, all reported (a top-5 referee should see the
% raw data, the confound-stripped version, and the dynamic estimator):
%   [A] EVENT STUDY. Per-event cumulative change in breakeven inflation over
%       windows [0,+1], [0,+3], [0,+5] trading days (close before the event to
%       close k days after). Every event shown individually -- no averaging
%       that hides the raw moves.
%   [B] CONFOUND ORTHOGONALIZATION. The obvious alternative story is "it was
%       the Fed / oil, not green fiscal news." A nominal-yield move = real-yield
%       move + breakeven move, so we strip the SAME-DAY real-yield and oil
%       moves: regress daily d(breakeven) on d(real yield), d(oil), d(vix) over
%       the full sample and take residuals ("breakeven news not explained by
%       real-rate or energy shocks"), then re-run [A] on the residuals.
%   [C] LOCAL PROJECTIONS (Jorda). The dynamic generalization: regress the
%       h-day cumulative change y_{t+h}-y_{t-1} on the green-event dummy plus
%       same-day confound changes and lags, h=0..H, with Newey-West SEs. The
%       coefficient path beta_h IS the average announcement response at each
%       horizon; the theory predicts beta_h < 0 and PERSISTENT (a level jump,
%       not a blip). This is the primary estimator; [A]/[B] are transparency.
%
% HONESTY. Clean green-fiscal EXPANSION surprises are few and cluster in
% 2021-22, amid the post-COVID inflation surge and Fed tightening -- a hard
% confounding window. No estimator manufactures power from ~6 events. The
% contribution is (i) the SIGN, and its direct contrast with the NK
% prediction, and (ii) the marquee genuine surprise -- the IRA Schumer-Manchin
% deal, an event literally named for inflation. Magnitudes are reported with
% wide bands and the identification caveats are stated, not buried. US
% breakevens are the reliable free FRED series, so the events are US
% green-fiscal expansions; the euro-area extension (Green Deal 2019, NGEU
% 2020, REPowerEU 2022 against euro 5y5y ILS) is documented as needing ECB
% data and is not run here.
%
% REQUIRES: data/fred_e3_daily.csv (run download_fred_e3 first).
% USAGE   >> main_project_e3
% OUTPUT  PFig22_e3.{fig,png,pdf}, output/tables/e3_summary.txt,
%         output/e3_results.mat
% STATUS: IMPLEMENTED. Reduced-form evidence; sign test, NOT causal point
% identification -- labeled as such throughout.

clearvars; close all; clc; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));
pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end

csv = fullfile(rootdir, 'data', 'fred_e3_daily.csv');
if exist(csv, 'file') ~= 2
    error(['data/fred_e3_daily.csv not found -- run ' ...
           'download_fred_e3(''YOUR_FRED_KEY'') first.']);
end
T = readtable(csv);
T.date = datetime(T.date);
T = sortrows(T, 'date');
fprintf('loaded %d daily rows, %s .. %s\n', height(T), ...
    datestr(T.date(1)), datestr(T.date(end)));

% ---- primary outcome and confound columns ----
y      = T.be5y5y;                 % 5y5y forward breakeven (primary outcome)
y5     = T.be5;   y10 = T.be10;    % secondary outcomes
real5  = getcol(T,'real5');        % same-day confounds
oil    = getcol(T,'oil');
vix    = getcol(T,'vix');
dts    = T.date;

% ============================ EVENT LIST =============================
% Pre-registered US green-fiscal EXPANSION announcements (deficit-financed
% green public investment). "surprise" flags a genuine news shock (markets
% did not price it in); non-surprises are anticipated legislative steps and
% are expected to move markets little (a placebo-ish check).
E = { % date          label                                    surprise
  '2021-03-31', 'American Jobs Plan (~$2tn, green infra) announced',      true;  ...
  '2021-06-24', 'Bipartisan Infrastructure Framework announced',         false; ...
  '2021-11-15', 'Infrastructure Investment & Jobs Act signed',           false; ...
  '2022-07-27', 'IRA Schumer-Manchin deal (SURPRISE; ~$370bn green)',    true;  ...
  '2022-08-07', 'IRA Senate passage',                                     false; ...
  '2022-08-16', 'IRA signed into law',                                    false; ...
};
edates = datetime(E(:,1));
elabel = E(:,2);
esurp  = cell2mat(E(:,3));
nE = numel(edates);

% map each event to the first trading-day index on/after the announcement
eidx = nan(nE,1);
for e = 1:nE
    k = find(dts >= edates(e), 1, 'first');
    if ~isempty(k), eidx(e) = k; end
end

% =====================================================================
% [A] EVENT STUDY: cumulative d(breakeven) over [0,+w] windows
%     response(w) = y(t_e + w) - y(t_e - 1)   (bp)
% =====================================================================
wins = [1 3 5];
A = struct('win', wins, 'be5y5y', nan(nE,numel(wins)), ...
           'be5', nan(nE,numel(wins)), 'be10', nan(nE,numel(wins)));
for e = 1:nE
    ii = eidx(e); if isnan(ii) || ii < 2, continue; end
    for w = 1:numel(wins)
        jj = ii + wins(w);
        if jj <= numel(y)
            A.be5y5y(e,w) = 100*(y(jj)   - y(ii-1));   % pp -> bp
            A.be5(e,w)    = 100*(y5(jj)  - y5(ii-1));
            A.be10(e,w)   = 100*(y10(jj) - y10(ii-1));
        end
    end
end

% =====================================================================
% [B] ORTHOGONALIZATION: strip same-day real-rate / oil / vix moves
% =====================================================================
dY  = [NaN; diff(y)];
dR  = ddiff(real5);  dO = ddiff(oil);  dV = ddiff(vix);
reg = [dR, dO, dV];
good = all(isfinite([dY, reg]), 2);
resid = nan(size(dY));
b_orth = [];
if sum(good) > 50
    Xo = [ones(sum(good),1), reg(good,:)];
    b_orth = Xo \ dY(good);
    resid(good) = dY(good) - Xo*b_orth;    % breakeven news orthogonal to confounds
end
% cumulate the residual and re-run the event windows on it
ry = nancumsum(resid);
B = struct('be5y5y', nan(nE,numel(wins)));
for e = 1:nE
    ii = eidx(e); if isnan(ii) || ii < 2, continue; end
    for w = 1:numel(wins)
        jj = ii + wins(w);
        if jj <= numel(ry), B.be5y5y(e,w) = 100*(ry(jj) - ry(ii-1)); end
    end
end

% =====================================================================
% [C] LOCAL PROJECTIONS: y_{t+h} - y_{t-1} = a_h + beta_h D_t + controls + e
%     D_t = green-event dummy; controls = same-day dR,dO,dV + 5 lags of dY.
%     beta_h (bp) is the average announcement response at horizon h.
% =====================================================================
H = 15;
D = zeros(numel(y),1); D(eidx(~isnan(eidx))) = 1;
% control block: same-day confounds + 5 lags of the daily outcome change
L = 5;
Xc = [dR, dO, dV];
for l = 1:L, Xc = [Xc, lagv(dY, l)]; end %#ok<AGROW>
LP = struct('h', (0:H)', 'beta', nan(H+1,1), 'se', nan(H+1,1), ...
            'beta_raw', nan(H+1,1), 'se_raw', nan(H+1,1));
for h = 0:H
    yh = shiftv(y, h) - lagv(y, 1);          % y_{t+h} - y_{t-1}
    yh = 100*yh;                              % bp
    % controlled
    X = [ones(numel(y),1), D, Xc];
    m = all(isfinite([yh, X]), 2);
    if sum(m) > 30
        [bb, se] = ols_nw(X(m,:), yh(m), h+5);
        LP.beta(h+1) = bb(2); LP.se(h+1) = se(2);
    end
    % raw (dummy only)
    Xr = [ones(numel(y),1), D];
    mr = all(isfinite([yh, Xr]), 2);
    if sum(mr) > 30
        [bb, se] = ols_nw(Xr(mr,:), yh(mr), h+5);
        LP.beta_raw(h+1) = bb(2); LP.se_raw(h+1) = se(2);
    end
end

% marquee event: IRA Schumer-Manchin surprise
iIRA = find(strcmp(E(:,1), '2022-07-27'), 1);

save(fullfile(projdir,'output','e3_results.mat'), 'A','B','LP', ...
     'E','edates','elabel','esurp','eidx','b_orth');

% =====================================================================
% PFig22: (a) per-event bar (be5y5y, [0,+5]); (b) LP path with bands
% =====================================================================
fh = figure('Name','PFig22: E3 green-fiscal announcements & breakeven inflation', ...
            'Color','w','Position',[60 60 1150 430]);
subplot(1,2,1); hold on; box on;
bvals = A.be5y5y(:,3);                         % [0,+5] window
cols = repmat([0.45 0.45 0.45], nE, 1); cols(esurp,:) = repmat([0.10 0.30 0.75], sum(esurp),1);
hb = bar(bvals, 'FaceColor','flat'); hb.CData = cols;
yline(0,'k-');
set(gca,'XTick',1:nE,'XTickLabel',datestr(edates,'yyyy-mm-dd'),'XTickLabelRotation',35);
ylabel('\Delta 5y5y breakeven, [0,+5]d (bp)');
title('(a) per-event breakeven response (blue = surprise)');
subplot(1,2,2); hold on; box on;
hh = LP.h;
fill([hh; flipud(hh)], [LP.beta-1.64*LP.se; flipud(LP.beta+1.64*LP.se)], ...
     [0.75 0.82 0.95], 'EdgeColor','none', 'FaceAlpha',0.6);
plot(hh, LP.beta, '-o', 'Color',[0.10 0.30 0.75], 'LineWidth',1.8, 'MarkerFaceColor','w');
yline(0,'k-');
xlabel('horizon h (trading days)'); ylabel('LP response \beta_h (bp)');
title('(b) local projection: breakeven response to a green-fiscal announcement');
save_all_figs(fh, 'PFig22_e3', pg);
fprintf('\n  [saved] PFig22_e3\n');

% =====================================================================
% summary table
% =====================================================================
sf = fullfile(pg.tabdir, 'e3_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'E3: GREEN-FISCAL ANNOUNCEMENTS AND BREAKEVEN INFLATION\n');
    fprintf(fid, 'Reduced-form sign test (NOT causal point identification).\n');
    fprintf(fid, 'Outcome: 5y5y forward breakeven inflation (FRED T5YIFR), bp.\n');
    fprintf(fid, 'Sample: %s .. %s (%d daily rows).\n\n', ...
        datestr(dts(1)), datestr(dts(end)), height(T));
    fprintf(fid, '[A] PER-EVENT breakeven response (bp), close(t-1) -> close(t+w)\n');
    fprintf(fid, '%-44s %-6s %8s %8s %8s\n','event','surp','[0,+1]','[0,+3]','[0,+5]');
    for e = 1:nE
        fprintf(fid, '%-44s %-6s %8.1f %8.1f %8.1f\n', trunc(elabel{e},44), ...
            tf(esurp(e)), A.be5y5y(e,1), A.be5y5y(e,2), A.be5y5y(e,3));
    end
    fprintf(fid, 'mean (all)                                   %6s %8.1f %8.1f %8.1f\n', ...
        '', nanmean(A.be5y5y(:,1)), nanmean(A.be5y5y(:,2)), nanmean(A.be5y5y(:,3)));
    fprintf(fid, 'mean (surprises only)                        %6s %8.1f %8.1f %8.1f\n', ...
        '', nanmean(A.be5y5y(esurp,1)), nanmean(A.be5y5y(esurp,2)), nanmean(A.be5y5y(esurp,3)));
    if ~isempty(iIRA)
        fprintf(fid, '\nMARQUEE (IRA Schumer-Manchin surprise, 2022-07-27):\n');
        fprintf(fid, '  5y5y  %+.1f / %+.1f / %+.1f bp   |  5y %+.1f  10y %+.1f bp ([0,+5])\n', ...
            A.be5y5y(iIRA,1), A.be5y5y(iIRA,2), A.be5y5y(iIRA,3), A.be5(iIRA,3), A.be10(iIRA,3));
    end
    fprintf(fid, '\n[B] ORTHOGONALIZED (breakeven news net of same-day real-yield,\n');
    fprintf(fid, '    oil, vix moves); response (bp) over the same windows\n');
    if ~isempty(b_orth)
        fprintf(fid, '    projection: d(be) = %.2f + %.2f d(real5) + %.3f d(oil) + %.3f d(vix)\n', ...
            b_orth(1), b_orth(2), b_orth(3), b_orth(4));
    end
    fprintf(fid, '%-44s %8s %8s %8s\n','event','[0,+1]','[0,+3]','[0,+5]');
    for e = 1:nE
        fprintf(fid, '%-44s %8.1f %8.1f %8.1f\n', trunc(elabel{e},44), ...
            B.be5y5y(e,1), B.be5y5y(e,2), B.be5y5y(e,3));
    end
    fprintf(fid, 'mean (surprises only)                        %8.1f %8.1f %8.1f\n', ...
        nanmean(B.be5y5y(esurp,1)), nanmean(B.be5y5y(esurp,2)), nanmean(B.be5y5y(esurp,3)));
    fprintf(fid, '\n[C] LOCAL PROJECTION: beta_h = avg response at horizon h (bp),\n');
    fprintf(fid, '    controlled for same-day real-yield/oil/vix + 5 lags; NW SE\n');
    fprintf(fid, '%-4s %10s %10s   %10s %10s\n','h','beta','se','beta_raw','se_raw');
    for h = 0:H
        fprintf(fid, '%-4d %10.2f %10.2f   %10.2f %10.2f\n', ...
            h, LP.beta(h+1), LP.se(h+1), LP.beta_raw(h+1), LP.se_raw(h+1));
    end
    fprintf(fid, ['\nREADING: the theory predicts beta_h < 0 and persistent ' ...
        '(a disinflationary\nlevel jump); the New Keynesian view predicts ' ...
        'beta_h >= 0. With ~%d events\nin a confounded 2021-22 window, the ' ...
        'SIGN is the test, not the magnitude.\n'], nE);
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('\nElapsed: %.1f s\n', toc(t0));

% ------------------------------ helpers ------------------------------
function c = getcol(T, nm)
    if ismember(nm, T.Properties.VariableNames), c = T.(nm); else, c = nan(height(T),1); end
end
function d = ddiff(x), d = [NaN; diff(x)]; end
function v = lagv(x, l), v = [nan(l,1); x(1:end-l)]; end
function v = shiftv(x, h)   % x_{t+h}
    if h == 0, v = x; else, v = [x(h+1:end); nan(h,1)]; end
end
function s = nancumsum(x), x(~isfinite(x)) = 0; s = cumsum(x); end
function m = nanmean(x), x = x(isfinite(x)); if isempty(x), m = NaN; else, m = mean(x); end, end
function s = tf(b), if b, s='yes'; else, s='no'; end, end
function s = trunc(str, n), if numel(str) > n, s = str(1:n); else, s = str; end, end

function [b, se] = ols_nw(X, y, L)
% OLS with Newey-West (Bartlett) HAC standard errors, lag L.
    n = size(X,1); k = size(X,2);
    b = X \ y;
    u = y - X*b;
    XtXinv = inv(X'*X);
    S = (X.*u)' * (X.*u);
    for l = 1:L
        w = 1 - l/(L+1);
        G = (X(l+1:end,:).*u(l+1:end))' * (X(1:end-l,:).*u(1:end-l));
        S = S + w*(G + G');
    end
    V = XtXinv * S * XtXinv;
    se = sqrt(max(diag(V), 0));
end
