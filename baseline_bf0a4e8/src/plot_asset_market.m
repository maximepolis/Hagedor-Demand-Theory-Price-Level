function fh = plot_asset_market(ad, ss, params)
% PLOT_ASSET_MARKET  Figure 1 replication: the asset market in the incomplete-
% markets economy, drawn in (assets, interest-rate) space:
%   x-axis: real assets / bonds,  y-axis: gross real interest rate 1+r.
%   BLUE  = government bond supply B/P (vertical line: fixed real value).
%   RED   = household (heterogeneous-agent) asset demand S(1+r).
%
% LEFT  : the demand curve and the bond-supply line B/P^*; their intersection
%         at 1+r^ss is the steady state.
% RIGHT : the paper's continuum illustration -- three hypothetical price levels
%         P1 < P2 < P3 give three bond-supply lines B/P_j, each intersecting
%         the demand curve at a DIFFERENT real rate. One equation (asset-market
%         clearing), two unknowns (r, P): policy must pin r to select P.
%
% INPUTS
%   ad     : asset-demand interpolant struct from asset_demand_interp.
%   ss     : baseline steady state from solve_steady_state_DTPL.
%   params : struct from setup_params.
%
% OUTPUT
%   fh : figure handle (also saved as Figure1_asset_market.{fig,png,pdf}).
%
% PAPER SECTION: Figure 1 (Section 3.1, Eq. 14).

    BLUE = [0.10 0.30 0.75];
    RED  = [0.85 0.20 0.15];

    conv = ad.converged;
    r    = ad.rgrid(conv);
    S    = ad.Sgrid(conv);
    gr   = 1 + r;                       % gross real rate (y-axis)
    yl   = [min(gr) - 0.002, max(gr) + 0.004];

    fh = figure('Name','Figure 1: Asset market (incomplete markets)', ...
                'Color','w','Position',[100 100 1000 420]);

    % ---------- LEFT: demand + supply, one equilibrium ----------
    subplot(1,2,1); hold on; box on;
    plot(S, gr, '-', 'LineWidth', 2, 'Color', RED);
    if isfield(ss,'exists') && ss.exists
        Breal = ss.Bnom / ss.Pstar;     % = S(1+r_ss) at equilibrium
        plot([Breal Breal], yl, '-', 'LineWidth', 2, 'Color', BLUE);
        plot([0 max(S)], [1+ss.r_ss, 1+ss.r_ss], '--', 'Color', [0.6 0.6 0.6]);
        plot(Breal, 1+ss.r_ss, 'o', 'MarkerFaceColor','k', ...
             'MarkerEdgeColor','k', 'MarkerSize', 8);
        text(Breal, 1+ss.r_ss, sprintf('  (B/P^*=%.2f, 1+r^{ss}=%.3f)', ...
             Breal, 1+ss.r_ss), 'FontSize', 9);
    end
    ylim(yl); xlim([0, 1.05*max(S)]);
    xlabel('real assets / bonds'); ylabel('gross real interest rate  1+r');
    title('(a) Asset-market clearing  S(1+r) = B/P');
    legend({'Heterogeneous-agent asset demand  S(1+r)', ...
            'Government bonds  B/P^*'}, 'Location','southeast');

    % ---------- RIGHT: continuum of (P_j, r_j) pairs ----------
    subplot(1,2,2); hold on; box on;
    plot(S, gr, '-', 'LineWidth', 2, 'Color', RED);
    if isfield(ss,'exists') && ss.exists && isfinite(ss.Pstar)
        Ps = ss.Pstar * [1.5, 1.0, 0.6];        % P1 > P2 > P3 => B/P1 < B/P2 < B/P3
    else
        Ps = params.Bnom ./ [min(S)+0.2, median(S), max(S)-0.2];
    end
    shades = [0.45 0.62 0.95; 0.25 0.45 0.85; 0.08 0.25 0.65];
    labs = cell(1, numel(Ps));
    for j = 1:numel(Ps)
        Br = params.Bnom / Ps(j);               % bond supply for price level P_j
        plot([Br Br], yl, '-', 'LineWidth', 1.8, 'Color', shades(j,:));
        % intersection: rate at which demand equals this supply
        rj = interp1(S, gr, Br, 'linear', NaN);
        if isfinite(rj)
            plot(Br, rj, 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k', ...
                 'MarkerSize', 7);
        end
        labs{j} = sprintf('B/P_%d  (P_%d=%.2f)', j, j, Ps(j));
    end
    ylim(yl); xlim([0, 1.05*max(S)]);
    xlabel('real assets / bonds'); ylabel('gross real interest rate  1+r');
    title('(b) One equation, two unknowns: each P_j clears at a different r');
    legend([{'HA asset demand  S(1+r)'}, labs], 'Location','southeast');

    save_all_figs(fh, 'Figure1_asset_market', params);
end
