function plot_green_figures(RESP, pg)
% PLOT_GREEN_FIGURES  The four project figures (saved as .fig/.png/.pdf to the
% project's output/figures via the root package's save_all_figs):
%
%   PFig1: the green steady state -- asset demand vs bond supply in
%          (assets, price-level) space with the equilibrium marked (Prop. 1).
%   PFig2: self-financing -- (a) decomposition bars at the benchmark;
%          (b) nu as a function of theta_g with the full-financing line (Prop. 2).
%   PFig3: climate sunspots vs anchor insulation -- (a) Phi-curves / crossings
%          for the nominal budget at high theta_g and the real mandate;
%          (b) demand elasticity eps_S(P) against the -1 line (Prop. 3-4).
%   PFig4: welfare W(mu) with the optimum marked (Prop. 5).
%
% INPUTS
%   RESP : project results struct assembled by main_project_run_all
%          (.bench: out-struct of the benchmark nominal solve;
%           .dec: self-financing decomposition; .sun: struct with .nominal_hi
%           and .real_hi out-structs at the high theta_g; .opt: optimal policy).
%   pg   : project params (figdir used by save_all_figs).
%
% Colors follow the repo convention: bond supply BLUE, asset demand RED.

    BLUE = [0.10 0.30 0.75];
    RED  = [0.85 0.20 0.15];

    % ================= PFig1: green steady state =================
    b = RESP.bench;
    fh = figure('Name','PFig1: Green steady state','Color','w', ...
                'Position',[80 80 620 480]); hold on; box on;
    good = isfinite(b.S_curve);
    plot(b.S_curve(good), b.Pgrid(good), '-', 'LineWidth',2, 'Color',RED);
    plot(b.BoverP, b.Pgrid, '-', 'LineWidth',2, 'Color',BLUE);
    for k = 1:numel(RESP.bench_eqs)
        e = RESP.bench_eqs(k);
        plot(e.breal, e.P, 'o', 'MarkerFaceColor','k', 'MarkerEdgeColor','k', ...
             'MarkerSize',8);
        text(e.breal, e.P, sprintf('  P^*=%.3f, D=%.3f', e.P, e.D), 'FontSize',9);
    end
    Smax = max(b.S_curve(good));
    if ~isempty(Smax) && isfinite(Smax) && Smax > 0
        xlim([0, 1.4*Smax]);
    end
    if ~isempty(RESP.bench_eqs)
        ylim([0, min(pg.P_scan_max, 2.2*max([RESP.bench_eqs.P]))]);
    end
    xlabel('real assets / bonds'); ylabel('price level  P');
    title(sprintf('Green steady state (nominal budget, \\theta_g=%.2f)', pg.theta_g));
    legend({'asset demand  S(1+r^{ss};\tau(P),D(P))','bond supply  B/P'}, ...
           'Location','northeast');
    save_all_figs(fh, 'PFig1_green_steady_state', pg);

    % ================= PFig2: self-financing =================
    d = RESP.dec;
    fh = figure('Name','PFig2: Self-financing','Color','w', ...
                'Position',[80 80 1000 420]);
    subplot(1,2,1); hold on; box on;
    vals = [d.nu_reval, d.nu_damage, d.nu];
    bh = bar(1:3, vals, 0.55);
    set(bh, 'FaceColor', [0.55 0.65 0.85]);
    plot([0.5 3.5], [1 1], 'k--', 'LineWidth',1.2);
    set(gca, 'XTick',1:3, 'XTickLabel', ...
        {'revaluation \nu_{reval}','damage dividend \nu_{dam}','total \nu'});
    ylabel('share of real program cost');
    title(sprintf('(a) Decomposition at \\theta_g=%.2f  (\\nu=%.2f)', ...
          pg.theta_g, d.nu));
    text(3.4, 1.02, 'full self-financing', 'FontSize',8, ...
         'HorizontalAlignment','right', 'VerticalAlignment','bottom');

    subplot(1,2,2); hold on; box on;
    sw = d.sweep;
    plot(sw.theta_g, sw.nu, 'o-', 'LineWidth',2, 'Color',RED, ...
         'MarkerFaceColor',RED);
    plot(sw.theta_g, sw.nu_reval, 's--', 'LineWidth',1.2, 'Color',BLUE);
    plot(sw.theta_g, sw.nu_damage, 'd--', 'LineWidth',1.2, 'Color',[0.2 0.55 0.25]);
    plot([min(sw.theta_g) max(sw.theta_g)], [1 1], 'k--', 'LineWidth',1.2);
    xlabel('damage-abatement effectiveness  \theta_g');
    ylabel('self-financing share  \nu');
    title('(b) \nu(\theta_g)');
    legend({'total \nu','revaluation','damage dividend','full financing'}, ...
           'Location','northwest');
    save_all_figs(fh, 'PFig2_self_financing', pg);

    % ================= PFig3: sunspots vs mandate =================
    sn = RESP.sun.nominal_hi;   % nominal budget at high theta_g
    sr = RESP.sun.real_hi;      % real mandate at the same theta_g
    fh = figure('Name','PFig3: Climate sunspots vs anchor insulation', ...
                'Color','w','Position',[80 80 1000 420]);
    subplot(1,2,1); hold on; box on;
    gn = isfinite(sn.Phi); gr_ = isfinite(sr.Phi);
    plot(sn.Pgrid(gn), sn.Phi(gn), '-', 'LineWidth',2, 'Color',RED);
    plot(sr.Pgrid(gr_), sr.Phi(gr_), '-', 'LineWidth',2, 'Color',BLUE);
    plot([pg.P_scan_min pg.P_scan_max], [0 0], 'k--', 'LineWidth',1);
    for k = 1:numel(RESP.sun.nominal_eqs)
        plot(RESP.sun.nominal_eqs(k).P, 0, 'o', 'MarkerFaceColor',RED, ...
             'MarkerEdgeColor','k','MarkerSize',8);
    end
    for k = 1:numel(RESP.sun.real_eqs)
        plot(RESP.sun.real_eqs(k).P, 0, 's', 'MarkerFaceColor',BLUE, ...
             'MarkerEdgeColor','k','MarkerSize',8);
    end
    xlabel('price level  P'); ylabel('\Phi(P) = S - B/P');
    title(sprintf('(a) Roots at \\theta_g=%.2f: nominal %d vs mandate %d', ...
          sn.theta_g, sn.n_roots, sr.n_roots));
    legend({'nominal green budget','real green mandate'}, 'Location','southeast');

    subplot(1,2,2); hold on; box on;
    plot(sn.Pgrid, sn.eps_S, '-', 'LineWidth',2, 'Color',RED);
    plot(sr.Pgrid, sr.eps_S, '-', 'LineWidth',2, 'Color',BLUE);
    plot([pg.P_scan_min pg.P_scan_max], [-1 -1], 'k--', 'LineWidth',1.2);
    xlabel('price level  P'); ylabel('demand elasticity  \epsilon_S(P)');
    title('(b) Uniqueness requires \epsilon_S > -1 at crossings (Def. 3)');
    legend({'nominal green budget','real green mandate','\epsilon_S = -1'}, ...
           'Location','southeast');
    save_all_figs(fh, 'PFig3_sunspots_vs_mandate', pg);

    % ================= PFig4: optimal accommodation =================
    o = RESP.opt;
    fh = figure('Name','PFig4: Optimal accommodation','Color','w', ...
                'Position',[80 80 620 480]); hold on; box on;
    gw = isfinite(o.W);
    plot(o.mu_grid(gw), o.W(gw), 'o-', 'LineWidth',2, 'Color',RED, ...
         'MarkerFaceColor',RED);
    if isfinite(o.mu_star)
        plot(o.mu_star, o.W_star, 'p', 'MarkerSize',16, ...
             'MarkerFaceColor',[0.95 0.75 0.10], 'MarkerEdgeColor','k');
        text(o.mu_star, o.W_star, sprintf('  \\mu^*=%.3f', o.mu_star), 'FontSize',10);
    end
    xlabel('nominal growth / steady-state inflation  \mu');
    ylabel('utilitarian welfare  W(\mu)');
    title('Optimal accommodation of the green program (Prop. 5)');
    save_all_figs(fh, 'PFig4_optimal_policy', pg);

    fprintf('  [saved] PFig1..PFig4 to %s\n', pg.figdir);
end
