function ep = empirical_panel(pg)
% EMPIRICAL_PANEL  E4: cross-country validation regressions on the World
% Bank panel produced by download_data.m. Two exercises, both presented as
% MECHANISM VALIDATION, never as causal identification:
%
%   E4a NOMINAL ANCHOR, LARGE PANEL. Country-average CPI inflation on the
%       country-average growth of nominal government consumption relative to
%       real GDP (the Lemma "nominal anchor" prediction: slope one). This
%       extends E1's 34-country OECD sample to the full World Bank coverage,
%       with an outlier-robust variant (excluding average inflation > 30%).
%       CAVEAT reported with the result: WB government CONSUMPTION is
%       narrower than the paper's expenditure concept.
%
%   E4b CLIMATE-FISCAL DESCRIPTIVES. Correlations of debt/GDP with CO2 per
%       capita and inflation with CO2 intensity -- descriptive context for
%       the fiscal-space discussion (BIS-style sovereign-climate patterns),
%       explicitly labeled descriptive.
%
% INPUT:  pg (paths). READS <repo root>/data/wb_panel.csv; SKIPS with a
%         clear message if absent (never fabricates).
% OUTPUT: ep struct with .ok .n .beta .se_hc1 .t_beta1 .p .rho .r2 (full and
%         trimmed samples) and .desc (E4b correlations). Figure PFig12.

    ep = struct('ok', false, 'msg', '');
    projdir = fileparts(fileparts(mfilename('fullpath')));
    csv = fullfile(fileparts(projdir), 'data', 'wb_panel.csv');
    if exist(csv, 'file') ~= 2
        ep.msg = sprintf(['E4 skipped: no panel at %s. Run download_data(pg) ' ...
                          'on a machine with internet.'], csv);
        fprintf('  %s\n', ep.msg);
        return;
    end

    T = readtable(csv);
    uc = unique(T.iso3, 'stable');
    infl_avg = nan(numel(uc),1); gg_avg = nan(numel(uc),1);
    debt_avg = nan(numel(uc),1); co2_avg = nan(numel(uc),1);
    for k = 1:numel(uc)
        m = strcmp(T.iso3, uc{k});
        yk = T.year(m); [~, o] = sort(yk);
        gv = T.govcons_nom(m); gv = gv(o);
        rg = T.rgdp(m);        rg = rg(o);
        cp = T.infl(m);        cp = cp(o);
        ratio = gv ./ rg;                        % nominal gov cons / real GDP
        gr = 100*(ratio(2:end)./ratio(1:end-1) - 1);
        gr = gr(isfinite(gr));
        % require at least 10 usable growth observations per country
        if numel(gr) >= 10
            gg_avg(k)   = mean(gr);
            infl_avg(k) = mean(cp(isfinite(cp)));
        end
        debt_avg(k) = mean(T.debt_gdp(m), 'omitnan');
        co2_avg(k)  = mean(T.co2pc(m), 'omitnan');
    end

    % ---- E4a: anchor regression, full and trimmed ----
    res_full = ols_hc1(gg_avg, infl_avg, inf);
    res_trim = ols_hc1(gg_avg, infl_avg, 30);     % drop avg inflation > 30%
    ep.full = res_full; ep.trim = res_trim;
    ep.ok = res_full.ok;
    if res_full.ok
        ep.msg = sprintf(['E4a anchor (WB panel): full n=%d beta=%.3f (HC1 %.3f); ' ...
            'trimmed(<30%%) n=%d beta=%.3f (HC1 %.3f), test beta=1: p=%.3f.'], ...
            res_full.n, res_full.beta, res_full.se, res_trim.n, res_trim.beta, ...
            res_trim.se, res_trim.p_beta1);
        fprintf('  %s\n', ep.msg);
    end

    % ---- E4b: descriptives ----
    good = isfinite(debt_avg) & isfinite(co2_avg);
    if nnz(good) > 10
        Rc = corrcoef(debt_avg(good), co2_avg(good));
        ep.desc.corr_debt_co2 = Rc(1,2);
        g2 = isfinite(infl_avg) & isfinite(co2_avg);
        Rc2 = corrcoef(infl_avg(g2), co2_avg(g2));
        ep.desc.corr_infl_co2 = Rc2(1,2);
        fprintf(['  E4b descriptives: corr(debt/GDP, CO2pc) = %.3f; ' ...
                 'corr(infl, CO2pc) = %.3f (descriptive only).\n'], ...
                ep.desc.corr_debt_co2, ep.desc.corr_infl_co2);
    end

    % ---- PFig12 ----
    g = isfinite(gg_avg) & isfinite(infl_avg) & infl_avg < 30 & abs(gg_avg) < 40;
    fh = figure('Name','PFig12: Anchor, World Bank panel','Color','w', ...
                'Position',[80 80 640 540]); hold on; box on;
    scatter(gg_avg(g), infl_avg(g), 30, [0.10 0.30 0.75], 'filled', ...
            'MarkerFaceAlpha', 0.6);
    lo = min([gg_avg(g); infl_avg(g)]); hi = max([gg_avg(g); infl_avg(g)]);
    plot([lo hi], [lo hi], 'k--', 'LineWidth', 1.2);
    if res_trim.ok
        xf = linspace(lo, hi, 40);
        plot(xf, res_trim.alpha + res_trim.beta*xf, '-', ...
             'Color',[0.85 0.20 0.15], 'LineWidth', 1.8);
    end
    xlabel('avg. growth of nominal gov. consumption / real GDP (%)');
    ylabel('avg. CPI inflation (%)');
    title(sprintf('Nominal anchor, WB panel (<30%% infl): \\beta=%.2f (HC1 %.2f)', ...
          res_trim.beta, res_trim.se));
    legend({'countries','45^\circ','OLS'}, 'Location','northwest');
    save_all_figs(fh, 'PFig12_anchor_wb_panel', pg);
    fprintf('  [saved] PFig12_anchor_wb_panel\n');
end

% -------------------------------------------------------------------------
function res = ols_hc1(x, y, infl_cap)
    keep = isfinite(x) & isfinite(y) & y < infl_cap & abs(x) < 100;
    x = x(keep); y = y(keep); n = numel(y);
    res = struct('ok', false, 'n', n);
    if n < 10, return; end
    X = [ones(n,1), x];
    b = (X'*X) \ (X'*y);
    u = y - X*b;
    V = (n/(n-2)) * ((X'*X) \ (X' * (X .* u.^2)) / (X'*X));
    se = sqrt(V(2,2));
    t1 = (b(2) - 1)/se;
    res.ok = true; res.alpha = b(1); res.beta = b(2); res.se = se;
    res.t_beta1 = t1;
    res.p_beta1 = 2*(1 - 0.5*(1 + erf(abs(t1)/sqrt(2))));
    res.r2 = 1 - sum(u.^2)/sum((y-mean(y)).^2);
end
