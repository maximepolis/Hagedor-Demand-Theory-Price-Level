function fh = plot_nominal_G(gout, params)
% PLOT_NOMINAL_G  Figure 4 replication: asset-market equilibrium with price-
% indexed (real) government debt and NOMINAL government expenditure, drawn in
% price-asset space (as in the paper's Figures 3-4).
%
% Panel (a) - real bonds: the asset-demand curve S(1+r^ss, tau(P)) is
%   INCREASING in P (higher P => lower real spending G/P => lower real taxes =>
%   higher precautionary asset demand; paper Result 1), while real bond supply
%   is FIXED at Breal. Their crossing determines P* even though bonds are real:
%   the nominal spending side is what makes the price level determinate.
% Panel (b) - nominal bonds + nominal G: demand S(1+r^ss, tau(P)) vs supply
%   B/P; the crossing gives P*.
%
% INPUTS
%   gout   : out-struct from solve_nominal_G_extension (fields .case1, .case2,
%            each with .Pgrid .S_curve .supply_curve .roots).
%   params : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure4_nominal_G.{fig,png,pdf}).
%
% PAPER SECTION: Figure 4.

    fh = figure('Name','Figure 4: Nominal government expenditure', ...
                'Color','w','Position',[100 100 1000 420]);

    cases  = {gout.case1, gout.case2};
    titles = {sprintf('(a) Real bonds B^{real}=%.2f, nominal G=%.2f', ...
                      gout.Breal, gout.Gnom), ...
              sprintf('(b) Nominal bonds B=%.2f, nominal G=%.2f', ...
                      gout.Bnom, gout.Gnom2)};
    supply_lab = {'bond supply  B^{real} (fixed)', 'bond supply  B/P'};

    for c = 1:2
        cs = cases{c};
        subplot(1,2,c); hold on; box on;

        good = isfinite(cs.S_curve);
        plot(cs.Pgrid(good), cs.S_curve(good), '-', 'LineWidth',2, ...
             'Color',[0.10 0.30 0.75]);
        plot(cs.Pgrid, cs.supply_curve, '-', 'LineWidth',2, ...
             'Color',[0.85 0.20 0.15]);

        for k = 1:numel(cs.roots)
            Sk = interp1(cs.Pgrid(good), cs.S_curve(good), cs.roots(k), 'linear');
            plot(cs.roots(k), Sk, 'o', 'MarkerFaceColor','k', ...
                 'MarkerEdgeColor','k', 'MarkerSize',8);
            text(cs.roots(k), Sk, sprintf('  P^*=%.3f', cs.roots(k)), 'FontSize',9);
        end

        Smax = max(cs.S_curve(good));
        if isfinite(Smax) && Smax > 0
            ylim([0, 1.6*Smax]);
        end

        xlabel('price level  P');
        ylabel('real assets');
        title(sprintf('%s [%d root(s)]', titles{c}, numel(cs.roots)));
        legend({'asset demand  S(1+r^{ss}, \tau(P))', supply_lab{c}}, ...
               'Location','best');
    end

    save_all_figs(fh, 'Figure4_nominal_G', params);
end
