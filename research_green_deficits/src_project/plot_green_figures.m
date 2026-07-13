function plot_green_figures(RESP, pg)
% PLOT_GREEN_FIGURES  The four project figures (saved as .fig/.png/.pdf to the
% project's output/figures via the root package's save_all_figs):
%
%   PFig1: the green-disinflation mechanism in one picture -- the NO-PROGRAM
%          and PROGRAM asset-demand curves against the bond-supply hyperbola
%          B/P, with both equilibria marked: the program SHIFTS the demand
%          schedule and the price level falls (Prop. 1-2). This is the
%          paper's own chart (a demand-shift comparison), deliberately not
%          the single-crossing supply/demand figure of Hagedorn (2026).
%   PFig2: self-financing -- (a) decomposition bars at the benchmark;
%          (b) nu as a function of theta_g with the full-financing line.
%   PFig3: climate sunspots vs anchor insulation -- (a) Phi-curves /
%          crossings; (b) demand elasticity eps_S(P) against -1 (Prop. 3-4).
%   PFig4: welfare W(mu) with the optimum marked (Prop. 5).
%
% Journal-style conventions used throughout: single-axes figures carry NO
% in-figure title (the caption does that work); multi-panel figures carry
% SHORT "(a)"/"(b)" titles only; legends are placed outside the data region.
%
% INPUTS
%   RESP : project results struct assembled by main_project_run_all
%          (.bench, .bench_eqs, .dec (with .out_base/.out_prog), .sun, .opt).
%   pg   : project params (figdir used by save_all_figs).

    BLUE  = [0.10 0.30 0.75];
    RED   = [0.85 0.20 0.15];
    GREEN = [0.20 0.55 0.25];
    GRAY  = [0.45 0.45 0.45];

    % ================= PFig1: the demand-shift mechanism =================
    d  = RESP.dec;
    ob = []; op = [];
    if isfield(d, 'out_base'), ob = d.out_base; end
    if isfield(d, 'out_prog'), op = d.out_prog; end
    fh = figure('Name','PFig1: Green steady state','Color','w', ...
                'Position',[80 80 760 560]); hold on; box on;
    if ~isempty(ob) && isfield(ob,'S_curve') && ~isempty(op) && isfield(op,'S_curve')
        gb = isfinite(ob.S_curve); gp = isfinite(op.S_curve);
        plot(ob.S_curve(gb), ob.Pgrid(gb), '-',  'LineWidth',2.2, 'Color',GRAY);
        plot(op.S_curve(gp), op.Pgrid(gp), '-',  'LineWidth',2.2, 'Color',GREEN);
        plot(ob.BoverP(gb),  ob.Pgrid(gb), '--', 'LineWidth',2.0, 'Color',BLUE);
        P0 = d.base.P;  P1 = d.prog.P;  B = pg.Bnom;
        plot(B/P0, P0, 'o', 'MarkerFaceColor',GRAY,  'MarkerEdgeColor','k', ...
             'MarkerSize',9, 'HandleVisibility','off');
        plot(B/P1, P1, 'o', 'MarkerFaceColor',GREEN, 'MarkerEdgeColor','k', ...
             'MarkerSize',9, 'HandleVisibility','off');
        % annotate the green disinflation P0 -> P1 along the supply curve
        plot([B/P0 B/P1], [P0 P1], ':', 'Color','k', 'LineWidth',1.4, ...
             'HandleVisibility','off');
        text(B/P1, P1, sprintf('  P_1^{*}=%.3f', P1), 'FontSize',13, ...
             'VerticalAlignment','top');
        text(B/P0, P0, sprintf('  P_0^{*}=%.3f', P0), 'FontSize',13, ...
             'VerticalAlignment','bottom');
        Smax = max([ob.S_curve(gb), op.S_curve(gp)]);
        if isfinite(Smax) && Smax > 0, xlim([0, 1.35*Smax]); end
        ylim([0, 2.2*max(P0, P1)]);
        legend({'asset demand, no program', 'asset demand, green program', ...
                'bond supply  B/P'}, 'Location','northeast');
    else
        % fallback: single-equilibrium chart from the benchmark solve
        b = RESP.bench;
        good = isfinite(b.S_curve);
        plot(b.S_curve(good), b.Pgrid(good), '-', 'LineWidth',2.2, 'Color',RED);
        plot(b.BoverP(good),  b.Pgrid(good), '--','LineWidth',2.0, 'Color',BLUE);
        for k = 1:numel(RESP.bench_eqs)
            e = RESP.bench_eqs(k);
            plot(e.breal, e.P, 'o', 'MarkerFaceColor','k', ...
                 'MarkerEdgeColor','k', 'MarkerSize',9, 'HandleVisibility','off');
        end
        legend({'asset demand','bond supply  B/P'}, 'Location','northeast');
    end
    xlabel('real assets / real bonds');
    ylabel('price level  P');
    save_all_figs(fh, 'PFig1_green_steady_state', pg);

    % ================= PFig2: self-financing =================
    fh = figure('Name','PFig2: Self-financing','Color','w', ...
                'Position',[80 80 1150 470]);
    subplot(1,2,1); hold on; box on;
    vals = [d.nu_reval, d.nu_damage, d.nu];
    cols = [BLUE; GREEN; 0.30 0.30 0.30];
    for k = 1:3
        bar(k, vals(k), 0.55, 'FaceColor', cols(k,:));
        text(k, vals(k) + 0.04*sign(vals(k)+eps), sprintf('%.2f', vals(k)), ...
             'HorizontalAlignment','center', 'FontSize',13);
    end
    yline(1, 'k--', 'LineWidth',1.2);
    yline(0, 'k-',  'LineWidth',0.8);
    set(gca, 'XTick',1:3, 'XTickLabel', ...
        {'revaluation','damage dividend','total \nu'});
    ylabel('share of real program cost');
    title('(a) decomposition at the benchmark');

    subplot(1,2,2); hold on; box on;
    sw = d.sweep;
    plot(sw.theta_g, sw.nu, 'o-', 'LineWidth',2.2, 'Color',[0.30 0.30 0.30], ...
         'MarkerFaceColor',[0.30 0.30 0.30], 'MarkerSize',5);
    plot(sw.theta_g, sw.nu_reval,  's--', 'LineWidth',1.8, 'Color',BLUE);
    plot(sw.theta_g, sw.nu_damage, 'd--', 'LineWidth',1.8, 'Color',GREEN);
    yline(1, 'k--', 'LineWidth',1.2, 'HandleVisibility','off');
    yline(0, 'k-',  'LineWidth',0.8, 'HandleVisibility','off');
    xlabel('abatement effectiveness  \theta_g');
    ylabel('self-financing share  \nu');
    title('(b) \nu(\theta_g), full financing at the dashed line');
    legend({'total \nu','revaluation','damage dividend'}, ...
           'Location','northwest');
    save_all_figs(fh, 'PFig2_self_financing', pg);

    % ================= PFig3: sunspots vs mandate =================
    sn = RESP.sun.nominal_hi;   % nominal budget at high theta_g
    sr = RESP.sun.real_hi;      % real mandate at the same theta_g
    fh = figure('Name','PFig3: Climate sunspots vs anchor insulation', ...
                'Color','w','Position',[80 80 1150 470]);
    subplot(1,2,1); hold on; box on;
    gn = isfinite(sn.Phi); gr_ = isfinite(sr.Phi);
    plot(sn.Pgrid(gn),  sn.Phi(gn),  '-', 'LineWidth',2.2, 'Color',RED);
    plot(sr.Pgrid(gr_), sr.Phi(gr_), '-', 'LineWidth',2.2, 'Color',BLUE);
    yline(0, 'k--', 'LineWidth',1.0, 'HandleVisibility','off');
    for k = 1:numel(RESP.sun.nominal_eqs)
        plot(RESP.sun.nominal_eqs(k).P, 0, 'o', 'MarkerFaceColor',RED, ...
             'MarkerEdgeColor','k','MarkerSize',9, 'HandleVisibility','off');
    end
    for k = 1:numel(RESP.sun.real_eqs)
        plot(RESP.sun.real_eqs(k).P, 0, 's', 'MarkerFaceColor',BLUE, ...
             'MarkerEdgeColor','k','MarkerSize',9, 'HandleVisibility','off');
    end
    xlabel('price level  P'); ylabel('excess demand  \Phi(P)');
    title('(a) roots of \Phi(P)');
    legend({'nominal green budget','real green mandate'}, 'Location','southeast');

    subplot(1,2,2); hold on; box on;
    plot(sn.Pgrid, sn.eps_S, '-', 'LineWidth',2.2, 'Color',RED);
    plot(sr.Pgrid, sr.eps_S, '-', 'LineWidth',2.2, 'Color',BLUE);
    yline(-1, 'k--', 'LineWidth',1.4);
    xlabel('price level  P'); ylabel('demand elasticity  \epsilon_S(P)');
    title('(b) uniqueness margin \epsilon_S vs -1');
    legend({'nominal green budget','real green mandate','\epsilon_S = -1'}, ...
           'Location','east');
    save_all_figs(fh, 'PFig3_sunspots_vs_mandate', pg);

    % ================= PFig4: optimal accommodation =================
    o = RESP.opt;
    fh = figure('Name','PFig4: Optimal accommodation','Color','w', ...
                'Position',[80 80 720 520]); hold on; box on;
    gw = isfinite(o.W);
    plot(o.mu_grid(gw), o.W(gw), 'o-', 'LineWidth',2.2, 'Color',RED, ...
         'MarkerFaceColor',RED, 'MarkerSize',5);
    if isfinite(o.mu_star)
        plot(o.mu_star, o.W_star, 'p', 'MarkerSize',18, ...
             'MarkerFaceColor',[0.95 0.75 0.10], 'MarkerEdgeColor','k');
        text(o.mu_star, o.W_star, sprintf('  \\mu^{*}=%.3f', o.mu_star), ...
             'FontSize',14, 'VerticalAlignment','bottom');
    end
    xlabel('nominal growth / steady-state inflation  \mu');
    ylabel('utilitarian welfare  W(\mu)');
    save_all_figs(fh, 'PFig4_optimal_policy', pg);

    fprintf('  [saved] PFig1..PFig4 to %s\n', pg.figdir);
end
