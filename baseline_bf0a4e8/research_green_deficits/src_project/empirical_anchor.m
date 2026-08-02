function emp = empirical_anchor(pg)
% EMPIRICAL_ANCHOR  Prediction E1 of the paper: long-run average inflation
% tracks the long-run growth of nominal government expenditure relative to
% real GDP with slope one (Lemma "nominal anchor"). Estimates
%     infl_c = alpha + beta * govexp_growth_c + u_c
% on the OECD cross-section shipped with the root replication package, with
% heteroskedasticity-robust (HC1) standard errors and a Wald test of beta = 1.
% Produces PFig5_empirical_anchor.{fig,png,pdf}.
%
% NO DATA ARE FABRICATED: if the CSV is absent or unusable the function
% reports .ok = false and the caller skips.
%
% INPUT
%   pg : project params (uses figdir; data path resolved to the repo root's
%        data/oecd_inflation_govexp.csv via load_oecd_data).
%
% OUTPUT
%   emp : struct with .ok .n .beta .alpha .se_beta_hc1 .t_beta_eq_1
%         .p_beta_eq_1 (normal approx) .rho .r2 .msg

    emp = struct('ok', false, 'msg', '');

    % locate the root package's CSV (repo root /data)
    projdir = fileparts(fileparts(mfilename('fullpath')));   % project folder
    csv = fullfile(fileparts(projdir), 'data', 'oecd_inflation_govexp.csv');
    data = load_oecd_data(csv);
    if ~data.ok
        emp.msg = sprintf('E1 skipped: %s', data.msg);
        fprintf('  %s\n', emp.msg);
        return;
    end

    x = data.gexp(:); y = data.infl(:); cc = data.country(:);
    keep = isfinite(x) & isfinite(y);
    x = x(keep); y = y(keep); cc = cc(keep);
    n = numel(y);
    if n < 5
        emp.msg = 'E1 skipped: fewer than 5 usable observations.';
        fprintf('  %s\n', emp.msg);
        return;
    end

    % ---- OLS with HC1 robust standard errors ----
    X  = [ones(n,1), x];
    XX = X' * X;
    bh = XX \ (X' * y);
    u  = y - X * bh;
    k  = size(X, 2);
    meat  = X' * (X .* (u.^2));            % sum x_i x_i' u_i^2
    Vhc1  = (n/(n-k)) * (XX \ meat / XX);  % HC1 sandwich
    se    = sqrt(diag(Vhc1));

    tstat = (bh(2) - 1) / se(2);           % H0: slope = 1
    pval  = 2 * (1 - normcdf_local(abs(tstat)));
    r2    = 1 - sum(u.^2) / sum((y - mean(y)).^2);
    Rc    = corrcoef(x, y); rho = Rc(1,2);

    emp.ok = true;
    emp.n = n; emp.alpha = bh(1); emp.beta = bh(2);
    emp.se_beta_hc1 = se(2); emp.t_beta_eq_1 = tstat; emp.p_beta_eq_1 = pval;
    emp.rho = rho; emp.r2 = r2;
    emp.msg = sprintf(['E1 (nominal anchor): n=%d, beta=%.3f (HC1 se %.3f), ' ...
        'test beta=1: t=%.2f p=%.3f, rho=%.3f, R2=%.3f.'], ...
        n, bh(2), se(2), tstat, pval, rho, r2);
    fprintf('  %s\n', emp.msg);

    % ---- PFig5 ----
    fh = figure('Name','PFig5: Nominal anchor (E1)','Color','w', ...
                'Position',[80 80 620 520]); hold on; box on;
    scatter(x, y, 42, [0.10 0.30 0.75], 'filled', 'MarkerFaceAlpha',0.75);
    for j = 1:n
        text(x(j), y(j), ['  ' cc{j}], 'FontSize',7, 'Color',[0.35 0.35 0.35]);
    end
    lo = min([x; y]); hi = max([x; y]);
    plot([lo hi], [lo hi], 'k--', 'LineWidth',1.2);               % 45-degree
    xf = linspace(min(x), max(x), 50);
    plot(xf, bh(1) + bh(2)*xf, '-', 'Color',[0.85 0.20 0.15], 'LineWidth',1.8);
    xlabel('avg. growth of nominal gov. expenditure / real GDP (%)');
    ylabel('avg. CPI inflation (%)');
    title(sprintf('Nominal anchor: \\beta=%.3f (HC1 se %.3f), 45^{\\circ} line', ...
          bh(2), se(2)));
    legend({'countries','45^\circ','OLS'}, 'Location','northwest');
    save_all_figs(fh, 'PFig5_empirical_anchor', pg);
end

% -------------------------------------------------------------------------
function p = normcdf_local(z)
% Standard normal CDF via erf (base MATLAB; no toolbox).
    p = 0.5 * (1 + erf(z / sqrt(2)));
end
