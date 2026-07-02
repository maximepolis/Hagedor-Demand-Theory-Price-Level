function fh = plot_nominal_G(gout, params)
% PLOT_NOMINAL_G  Figure 4 replication: asset-market equilibrium with price-
% indexed (real) government debt and NOMINAL government expenditure. Shows how
% nominal G can determine the price level through the aggregate-demand channel,
% even when bonds are real (case 1) or when both bonds and spending are nominal
% (case 2).
%
% We plot the market-clearing residual against the price level P for each case;
% the zero crossing(s) are the equilibrium price level(s).
%
% INPUTS
%   gout   : out-struct from solve_nominal_G_extension (fields .case1, .case2).
%   params : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure4_nominal_G.{fig,png,pdf}).
%
% PAPER SECTION: Figure 4.

    fh = figure('Name','Figure 4: Nominal government expenditure', ...
                'Color','w','Position',[100 100 1000 420]);

    cases  = {gout.case1, gout.case2};
    titles = {sprintf('(a) Real bonds: S(r,G/P)=B^{real}=%.2f', gout.Breal), ...
              sprintf('(b) Nominal bonds+G: S(r,G/P)=B/P')};
    colr   = {[0.10 0.30 0.75], [0.20 0.55 0.25]};

    for c = 1:2
        cs = cases{c};
        subplot(1,2,c); hold on; box on;
        plot(cs.Pgrid, cs.resid, '-', 'LineWidth',2, 'Color',colr{c});
        plot([min(cs.Pgrid) max(cs.Pgrid)], [0 0], 'k--', 'LineWidth',1);
        for k = 1:numel(cs.roots)
            plot(cs.roots(k), 0, 'o', 'MarkerFaceColor',[0.85 0.20 0.15], ...
                 'MarkerEdgeColor','k','MarkerSize',8);
            text(cs.roots(k), 0, sprintf('  P*=%.3f', cs.roots(k)), 'FontSize',9);
        end
        xlabel('price level  P'); ylabel('market-clearing residual');
        title(sprintf('%s [%d root(s)]', titles{c}, numel(cs.roots)));
    end

    save_all_figs(fh, 'Figure4_nominal_G', params);
end
