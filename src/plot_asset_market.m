function fh = plot_asset_market(ad, ss, params)
% PLOT_ASSET_MARKET  Figure 1 replication: the asset market in the incomplete-
% markets economy.
%
% LEFT  : the heterogeneous-agent asset-demand curve S(1+r) against (1+r), with
%         the real bond supply B/P^* drawn as a vertical line (real supply) whose
%         intersection with S(1+r) is the steady state.
% RIGHT : for three hypothetical price levels P1<P2<P3, the real bond supplies
%         B/P_j intersect the asset-demand curve at different real rates when
%         policy has not yet pinned r^ss — illustrating why an extra condition
%         (the Fisher/policy block) is needed to select the equilibrium.
%
% INPUTS
%   ad     : asset-demand interpolant struct from asset_demand_interp.
%   ss     : baseline steady state from solve_steady_state_DTPL.
%   params : struct from setup_params.
%
% OUTPUT
%   fh : figure handle (also saved as Figure1_asset_market.{fig,png,pdf}).
%
% PAPER SECTION: Figure 1.

    conv = ad.converged;
    r    = ad.rgrid(conv);
    S    = ad.Sgrid(conv);
    gr   = 1 + r;   % gross real rate on the x-axis

    fh = figure('Name','Figure 1: Asset market (incomplete markets)', ...
                'Color','w','Position',[100 100 1000 420]);

    % ---------- LEFT ----------
    subplot(1,2,1); hold on; box on;
    plot(gr, S, '-', 'LineWidth', 2, 'Color', [0.10 0.30 0.75]);
    if isfield(ss,'exists') && ss.exists
        Breal = ss.S_assets;                      % = B/P* at equilibrium
        yl = [min(S) max(S)];
        plot([1+ss.r_ss, 1+ss.r_ss], yl, '--', 'Color',[0.6 0.6 0.6]);
        plot(1+ss.r_ss, ss.S_assets, 'o', 'MarkerFaceColor',[0.85 0.20 0.15], ...
             'MarkerEdgeColor','k','MarkerSize',8);
        text(1+ss.r_ss, ss.S_assets, sprintf('  (1+r^{ss}=%.3f, S=%.3f)', ...
             1+ss.r_ss, ss.S_assets), 'FontSize',9);
        yline_local(Breal, [min(gr) max(gr)], 'B/P^* (real supply)');
    end
    xlabel('gross real rate  1+r'); ylabel('real asset demand  S(1+r)');
    title('(a) HA asset demand & bond supply');
    legend({'Heterogeneous-agent asset demand'}, 'Location','northwest');

    % ---------- RIGHT ----------
    subplot(1,2,2); hold on; box on;
    plot(gr, S, '-', 'LineWidth', 2, 'Color', [0.10 0.30 0.75]);
    % three hypothetical price levels
    if isfield(ss,'exists') && ss.exists && isfinite(ss.Pstar)
        Ps = ss.Pstar * [1.5, 1.0, 0.6];   % P1>P2*(=P*)>P3
    else
        Ps = params.Bnom ./ [max(S), median(S), min(S)];
    end
    cols = [0.20 0.55 0.25; 0.85 0.55 0.10; 0.60 0.20 0.55];
    labs = cell(1,numel(Ps));
    for j = 1:numel(Ps)
        Br = params.Bnom / Ps(j);          % real supply B/P_j
        plot([min(gr) max(gr)], [Br Br], '--', 'LineWidth',1.5, 'Color', cols(j,:));
        % intersection real rate (interp inverse)
        labs{j} = sprintf('B/P_%d = %.3f  (P_%d=%.2f)', j, Br, j, Ps(j));
    end
    xlabel('gross real rate  1+r'); ylabel('real asset demand / supply');
    title('(b) Different P_j => different B/P_j');
    legend([{'HA asset demand'}, labs], 'Location','northeast');

    save_all_figs(fh, 'Figure1_asset_market', params);
end

% -------------------------------------------------------------------------
function yline_local(yval, xspan, txt)
    plot(xspan, [yval yval], '-.', 'Color',[0.85 0.20 0.15], 'LineWidth',1.5);
    text(xspan(1), yval, ['  ' txt], 'FontSize',9, 'Color',[0.85 0.20 0.15], ...
         'VerticalAlignment','bottom');
end
