function fh = plot_nominal_G(gout, params)
% PLOT_NOMINAL_G  Figure 4 replication: asset-market equilibrium with price-
% indexed (real) government debt Breal and NOMINAL government expenditure G.
%
% Panel (a) -- demand-curve family in (assets, interest-rate) space:
%   x-axis: real assets / bonds,  y-axis: gross real interest rate 1+r.
%   BLUE  = fixed real bond supply Breal (vertical line).
%   RED   = household asset demand S(1+r, tau(P)) for three price levels.
%   A higher P lowers real spending G/P and hence real taxes, shifting the
%   demand curve RIGHT (paper Result 1: S strictly decreasing in taxes).
%   Only ONE price level puts the demand curve through (Breal, 1+r^ss): that
%   is the equilibrium P* -- nominal spending determines the price level even
%   though bonds are real.
%
% Panel (b) -- equilibrium determination in (assets, price-level) space:
%   x-axis: real assets,  y-axis: price level P.
%   RED   = demand S(1+r^ss, tau(P)) traced over P (increasing in P).
%   BLUE  = bond supply Breal (vertical line).
%   Their intersection is the unique steady-state price level P*.
%
% INPUTS
%   gout   : out-struct from solve_nominal_G_extension (uses .case1 with
%            .family .Pgrid .S_curve .roots, plus .Breal .Gnom .r_ss).
%   params : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure4_nominal_G.{fig,png,pdf}).
%
% PAPER SECTION: Figure 4 (Eq. 66-69, Result 1).

    BLUE = [0.10 0.30 0.75];

    fh = figure('Name','Figure 4: Nominal government expenditure', ...
                'Color','w','Position',[100 100 1000 420]);

    cs = gout.case1;

    % ---------- (a) shifting demand curves ----------
    subplot(1,2,1); hold on; box on;
    if isfield(cs, 'family')
        fam    = cs.family;
        shades = [0.95 0.55 0.45; 0.85 0.20 0.15; 0.55 0.10 0.10];
        labs   = cell(1, numel(fam.P));
        grf    = 1 + fam.rgrid;
        yl     = [min(grf) - 0.002, max(grf) + 0.004];
        xmax   = 0;
        for a = 1:numel(fam.P)
            Sa   = fam.S(a, :);
            good = isfinite(Sa);
            plot(Sa(good), grf(good), '-', 'LineWidth', 2, 'Color', shades(a,:));
            labs{a} = sprintf('S(1+r, G/P),  P=%.2f', fam.P(a));
            xmax = max(xmax, max(Sa(good)));
        end
        plot([gout.Breal gout.Breal], yl, '-', 'LineWidth', 2, 'Color', BLUE);
        plot([0 1.05*xmax], [1+gout.r_ss, 1+gout.r_ss], '--', 'Color', [0.6 0.6 0.6]);
        plot(gout.Breal, 1+gout.r_ss, 'o', 'MarkerFaceColor','k', ...
             'MarkerEdgeColor','k', 'MarkerSize', 8);
        ylim(yl); xlim([0, 1.05*xmax]);
        legend([labs, {sprintf('B^{real}=%.2f (fixed)', gout.Breal), ...
                       'policy-pinned 1+r^{ss}'}], 'Location','southeast');
    end
    xlabel('real assets / bonds'); ylabel('gross real interest rate  1+r');
    title(sprintf('(a) Higher P shifts asset demand right (G=%.2f nominal)', ...
          gout.Gnom));

    % ---------- (b) equilibrium price level ----------
    subplot(1,2,2); hold on; box on;
    good = isfinite(cs.S_curve);
    plot(cs.S_curve(good), cs.Pgrid(good), '-', 'LineWidth', 2, ...
         'Color', [0.85 0.20 0.15]);
    if isempty(cs.roots)
        ymax = min(params.P_max, 4);
    else
        ymax = min(params.P_max, max(2, 2.2*max(cs.roots)));
    end
    plot([gout.Breal gout.Breal], [0 ymax], '-', 'LineWidth', 2, 'Color', BLUE);
    for k = 1:numel(cs.roots)
        plot(gout.Breal, cs.roots(k), 'o', 'MarkerFaceColor','k', ...
             'MarkerEdgeColor','k', 'MarkerSize', 8);
        text(gout.Breal, cs.roots(k), sprintf('  P^*=%.3f', cs.roots(k)), ...
             'FontSize', 9);
    end
    Smax = max(cs.S_curve(good));
    if isfinite(Smax) && Smax > 0
        xlim([0, 1.2*Smax]);
    end
    ylim([0, ymax]);
    xlabel('real assets / bonds'); ylabel('price level  P');
    title(sprintf('(b) Equilibrium: S(1+r^{ss}, G/P) = B^{real}  [%d root(s)]', ...
          numel(cs.roots)));
    legend({'asset demand  S(1+r^{ss}, \tau(P))', ...
            sprintf('bond supply  B^{real}=%.2f', gout.Breal)}, ...
           'Location','southeast');

    save_all_figs(fh, 'Figure4_nominal_G', params);
end
