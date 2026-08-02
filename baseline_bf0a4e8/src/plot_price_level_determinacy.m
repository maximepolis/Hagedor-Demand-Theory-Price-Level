function fh = plot_price_level_determinacy(ad, ss, cm, params)
% PLOT_PRICE_LEVEL_DETERMINACY  Figure 2 replication: determinacy in incomplete
% markets versus indeterminacy in complete markets, drawn in the same
% (assets, interest-rate) space as Figure 1:
%   x-axis: real assets / bonds,  y-axis: gross real interest rate 1+r.
%   BLUE  = government bond supply B/P (vertical line),
%   RED   = household asset demand.
%
% LEFT  : incomplete markets. Policy pins 1+r^ss = (1+i^ss)/(1+pi^ss); the
%         upward-sloping demand curve gives a single asset level S(1+r^ss), so
%         the bond-supply line B/P must pass through that point: UNIQUE
%         P* = B/S(1+r^ss).
% RIGHT : complete markets / representative agent. The demand "curve" is a
%         HORIZONTAL line at 1+r = 1/beta: the household absorbs ANY quantity
%         of real bonds at that rate. Every bond-supply line B/P*_j intersects
%         it, so a continuum of price levels P*_1, P*_2, P*_3, ... satisfies
%         all equilibrium conditions: P is INDETERMINATE.
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
% PAPER SECTION: Figure 2 (Sections 3.1, 3.4, Eq. 23-24).

    BLUE = [0.10 0.30 0.75];
    RED  = [0.85 0.20 0.15];

    conv = ad.converged;
    r    = ad.rgrid(conv);
    S    = ad.Sgrid(conv);
    gr   = 1 + r;
    grc  = 1 + cm.r_complete;                    % 1/beta
    yl   = [min(gr) - 0.002, max(max(gr), grc) + 0.004];
    xmax = 1.05 * max(S);

    fh = figure('Name','Figure 2: Determinacy vs indeterminacy', ...
                'Color','w','Position',[100 100 1000 420]);

    % ---------- LEFT: incomplete markets, unique P* ----------
    subplot(1,2,1); hold on; box on;
    plot(S, gr, '-', 'LineWidth', 2, 'Color', RED);
    if isfield(ss,'exists') && ss.exists
        Breal = ss.Bnom / ss.Pstar;              % = S(1+r_ss)
        plot([Breal Breal], yl, '-', 'LineWidth', 2, 'Color', BLUE);
        plot([0 xmax], [1+ss.r_ss, 1+ss.r_ss], '--', 'Color', [0.6 0.6 0.6]);
        plot(Breal, 1+ss.r_ss, 'o', 'MarkerFaceColor','k', ...
             'MarkerEdgeColor','k', 'MarkerSize', 8);
        text(Breal, 1+ss.r_ss, sprintf('  B/P^*, P^*=%.3f', ss.Pstar), ...
             'FontSize', 9);
        title(sprintf('(a) Incomplete markets: UNIQUE P^* = %.3f', ss.Pstar));
    else
        title('(a) Incomplete markets');
    end
    ylim(yl); xlim([0, xmax]);
    xlabel('real assets / bonds'); ylabel('gross real interest rate  1+r');
    legend({'HA asset demand  S(1+r)', 'Government bonds  B/P^*', ...
            'policy-pinned  1+r^{ss}'}, 'Location','southeast');

    % ---------- RIGHT: complete markets, indeterminate P ----------
    subplot(1,2,2); hold on; box on;
    % horizontal demand line: any asset quantity absorbed at 1+r = 1/beta
    plot([0 xmax], [grc grc], '-', 'LineWidth', 2.5, 'Color', RED);
    % three example bond-supply lines B/P*_1 < B/P*_2 < B/P*_3
    Bex = xmax * [0.25, 0.50, 0.75];
    shades = [0.45 0.62 0.95; 0.25 0.45 0.85; 0.08 0.25 0.65];
    labs = cell(1,3);
    for k = 1:3
        plot([Bex(k) Bex(k)], yl, '-', 'LineWidth', 1.8, 'Color', shades(k,:));
        plot(Bex(k), grc, 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k', ...
             'MarkerSize', 7);
        labs{k} = sprintf('B/P^*_%d', k);
    end
    text(0.02*xmax, grc, sprintf('  1+r = 1/\\beta = %.3f', grc), ...
         'FontSize', 9, 'Color', RED, 'VerticalAlignment','bottom');
    ylim(yl); xlim([0, xmax]);
    xlabel('real assets / bonds'); ylabel('gross real interest rate  1+r');
    title('(b) Complete markets: P INDETERMINATE (continuum of P^*_j)');
    legend([{'RA asset demand (any quantity at 1/\beta)'}, labs], ...
           'Location','southeast');

    save_all_figs(fh, 'Figure2_determinacy', params);
end
