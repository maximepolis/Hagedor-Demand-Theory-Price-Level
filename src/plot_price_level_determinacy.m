function fh = plot_price_level_determinacy(ad, ss, cm, params)
% PLOT_PRICE_LEVEL_DETERMINACY  Figure 2 replication: determinacy in incomplete
% markets versus indeterminacy in complete markets.
%
% LEFT  : impose r^ss = (1+i^ss)/(1+pi^ss)-1, evaluate S(1+r^ss), and show the
%         UNIQUE price level P* = B/S(1+r^ss). The asset-demand curve S(1+r) is
%         a genuine function of r, so once policy fixes r^ss there is one S and
%         one P*.
% RIGHT : complete markets. The real rate is pinned at 1+r = 1/beta INDEPENDENT
%         of B/P, so the "asset-demand curve" is a vertical line at 1/beta and
%         ANY real bond value B/P is consistent — the price level is
%         indeterminate. We plot a continuum of admissible (1+r, B/P) points.
%
% INPUTS
%   ad     : asset-demand interpolant (incomplete markets).
%   ss     : baseline steady state.
%   cm     : complete-markets counterexample struct.
%   params : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure2_determinacy.{fig,png,pdf}).
%
% PAPER SECTION: Figure 2.

    conv = ad.converged;
    r    = ad.rgrid(conv);
    S    = ad.Sgrid(conv);
    gr   = 1 + r;

    fh = figure('Name','Figure 2: Determinacy vs indeterminacy', ...
                'Color','w','Position',[100 100 1000 420]);

    % ---------- LEFT: incomplete markets, unique P* ----------
    subplot(1,2,1); hold on; box on;
    plot(gr, S, '-', 'LineWidth',2, 'Color',[0.10 0.30 0.75]);
    if isfield(ss,'exists') && ss.exists
        plot([1+ss.r_ss 1+ss.r_ss], [min(S) max(S)], '--','Color',[0.6 0.6 0.6]);
        plot([min(gr) max(gr)], [ss.S_assets ss.S_assets], '-.', ...
             'Color',[0.85 0.20 0.15],'LineWidth',1.5);
        plot(1+ss.r_ss, ss.S_assets, 'o','MarkerFaceColor',[0.85 0.2 0.15], ...
             'MarkerEdgeColor','k','MarkerSize',9);
        title(sprintf('(a) Incomplete markets: UNIQUE P* = %.3f', ss.Pstar));
        text(1+ss.r_ss, ss.S_assets, sprintf('  S=B/P*=%.3f', ss.S_assets),'FontSize',9);
    else
        title('(a) Incomplete markets');
    end
    xlabel('gross real rate  1+r'); ylabel('S(1+r)  and  B/P^*');
    legend({'HA asset demand','r^{ss} from policy','B/P^*'}, 'Location','northwest');

    % ---------- RIGHT: complete markets, indeterminate P ----------
    subplot(1,2,2); hold on; box on;
    grc = 1 + cm.r_complete;
    Br  = cm.Breal_grid;              % continuum of B/P values
    % vertical asset-demand "curve" at 1/beta
    plot([grc grc], [min(Br) max(Br)], '-', 'LineWidth',2.5, 'Color',[0.10 0.30 0.75]);
    % admissible points: any B/P at that rate
    plot(grc*ones(size(Br)), Br, '.', 'Color',[0.85 0.20 0.15], 'MarkerSize',6);
    % three example price levels P*_1 < P*_2 < P*_3, as labeled in the paper
    Bex = quantile_local(Br, [0.75 0.45 0.15]);
    for k = 1:3
        plot(grc, Bex(k), 'o', 'MarkerFaceColor',[0.85 0.20 0.15], ...
             'MarkerEdgeColor','k', 'MarkerSize',8);
        text(grc, Bex(k), sprintf('  B/P^*_%d', k), 'FontSize',9);
    end
    xline_span(grc, sprintf('1+r = 1/\\beta = %.3f', grc));
    xlabel('gross real rate  1+r'); ylabel('real bond value  B/P');
    xlim([min(gr) max([max(gr), grc*1.01])]);
    title('(b) Complete markets: P INDETERMINATE');
    legend({'Complete-mkt asset demand (vertical)','admissible B/P (continuum)'}, ...
           'Location','northeast');

    save_all_figs(fh, 'Figure2_determinacy', params);
end

% -------------------------------------------------------------------------
function xline_span(xval, txt)
    yl = ylim;
    text(xval, yl(1) + 0.9*(yl(2)-yl(1)), ['  ' txt], 'FontSize',9, ...
         'Color',[0.10 0.30 0.75]);
end

% -------------------------------------------------------------------------
function q = quantile_local(x, p)
% Toolbox-free quantiles of a vector (linear interpolation on sorted values).
    x = sort(x(:));
    n = numel(x);
    q = zeros(size(p));
    for k = 1:numel(p)
        idx  = 1 + p(k)*(n-1);
        lo   = floor(idx); hi = ceil(idx); w = idx - lo;
        q(k) = (1-w)*x(lo) + w*x(hi);
    end
end
