% MAIN_EMPIRICAL_FIGURE5_OPTIONAL  Figure 5 (empirical): cross-country average
% inflation vs average growth of nominal government expenditure / real GDP.
% This is OPTIONAL: it runs ONLY if a usable data file is present. No fake OECD
% data are hard-coded. Paper: Figure 5, Section 4.
%
% Government expenditure (paper definition): final consumption expenditure
% + gross capital formation + acquisitions less disposals of nonassets
% - consumption of fixed capital. See src/load_oecd_data.m for CSV layouts.

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## FIGURE 5 (optional, empirical) ##########\n');

data = load_oecd_data(params.fig5_csv);
if ~data.ok
    fprintf('  SKIPPED: %s\n', data.msg);
    fprintf('  To produce Figure 5, place a CSV at %s (see src/load_oecd_data.m).\n', ...
        params.fig5_csv);
    RES.fig5.ok = false; RES.fig5.msg = data.msg;
    return;
end

fprintf('  %s (layout: %s)\n', data.msg, data.layout);

x = data.gexp(:);    % avg growth of nominal gov exp / real GDP (%)
y = data.infl(:);    % avg inflation (%)
good = isfinite(x) & isfinite(y);
x = x(good); y = y(good); cc = data.country(good);

% cross-country correlation
if numel(x) >= 2
    R = corrcoef(x, y); rho = R(1,2);
else
    rho = NaN;
end

% OLS slope for reference
if numel(x) >= 2
    b = [ones(numel(x),1), x] \ y;
else
    b = [NaN; NaN];
end

fprintf('  countries=%d  correlation=%.3f  OLS slope=%.3f\n', numel(x), rho, b(2));

fh5 = figure('Name','Figure 5: Inflation vs nominal gov-exp growth', ...
             'Color','w','Position',[100 100 620 560]);
hold on; box on;
scatter(x, y, 42, [0.10 0.30 0.75], 'filled', 'MarkerFaceAlpha',0.7);
for k = 1:numel(cc)
    text(x(k), y(k), ['  ' cc{k}], 'FontSize',7, 'Color',[0.3 0.3 0.3]);
end
lo = min([x; y]); hi = max([x; y]);
plot([lo hi], [lo hi], 'k--', 'LineWidth',1.2);                 % 45-degree line
if isfinite(b(2))
    xf = linspace(min(x), max(x), 50);
    plot(xf, b(1)+b(2)*xf, '-', 'Color',[0.85 0.20 0.15], 'LineWidth',1.5); % OLS
end
xlabel('avg. growth of nominal gov. expenditure / real GDP (%)');
ylabel('avg. CPI inflation (%)');
title(sprintf('Figure 5: inflation vs nominal G growth  (\\rho=%.2f)', rho));
legend({'countries','45^\circ line','OLS fit'}, 'Location','northwest');

save_all_figs(fh5, 'Figure5_inflation_vs_G', params);
fprintf('  [saved] Figure5_inflation_vs_G.{fig,png,pdf}\n');

RES.fig5.ok  = true;
RES.fig5.rho = rho;
RES.fig5.slope = b(2);
RES.fig5.country = cc; RES.fig5.x = x; RES.fig5.y = y;
