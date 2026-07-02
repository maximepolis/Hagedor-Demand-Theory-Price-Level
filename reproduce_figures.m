function reproduce_figures(par, ad, R)
% REPRODUCE_FIGURES  Regenerate Figures 1-5 of Hagedorn (2026).
% Figures 1-4 are schematic in the paper; we reproduce them QUANTITATIVELY from
% the computed asset-demand curve S(1+r) and the price-level results in R.
% Figure 5 is empirical; data are downloaded live from the internet (World Bank
% WDI) via load_oecd_data, with cache/placeholder fallback.

    if ~exist(par.figdir,'dir'), mkdir(par.figdir); end
    onepr = ad.onepr; S = ad.S; rr = onepr - 1; asym = 1/par.beta;

    %% ---------- Figure 1: asset market in incomplete-markets economy --------
    f1 = figure('Name','Figure 1','Color','w','Position',[100 100 900 380]);
    subplot(1,2,1); hold on; box on;
    plot(S, rr, 'r-', 'LineWidth', 2);
    yline(asym-1, 'k--');
    BP = par.B / R.baseline.S;
    xline(BP, 'b-', 'LineWidth', 1.5);
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(left) one B/P'); legend({'S(1+r;...)','1/\beta','Gov. Bonds B/P'}, 'Location','southeast');
    text(max(S)*0.6, asym-1-0.002, '1/\beta');
    subplot(1,2,2); hold on; box on;
    plot(S, rr, 'r-', 'LineWidth', 2);
    yline(asym-1, 'k--');
    P3 = [0.8;1.0;1.3]*R.baseline.P;
    for k=1:3, xline(par.B/P3(k), 'b-', 'LineWidth', 1.2); end
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(right) B/P_1, B/P_2, B/P_3');
    sgtitle('Figure 1: Asset market in incomplete-markets economy');
    save_figure(f1, 'Figure1', par.figdir);

    %% ---------- Figure 2: determinacy (a) vs indeterminacy (b) --------------
    f2 = figure('Name','Figure 2','Color','w','Position',[100 100 900 380]);
    subplot(1,2,1); hold on; box on;
    plot(S, rr, 'r-', 'LineWidth', 2);
    yline(asym-1,'k--');
    r_pol = R.baseline.r_ss; BPb = par.B/R.baseline.S;
    yline(r_pol, 'k:'); xline(BPb, 'b-', 'LineWidth',1.5);
    plot(BPb, r_pol, 'ko','MarkerFaceColor','k');
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(a) Incomplete markets: DETERMINATE');
    legend({'S(1+r;...)','1/\beta','(1+i_{ss})/(1+\pi_{ss})-1','B/P*'},'Location','southeast');
    subplot(1,2,2); hold on; box on;
    yline(asym-1, 'r-', 'LineWidth', 2);
    Pcm = R.cm.cm.P; for k=1:numel(Pcm), xline(par.B/Pcm(k),'b-','LineWidth',1.2); end
    ylim([min(rr) asym-1+0.01]);
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(b) Complete markets: INDETERMINATE');
    legend({'HH demand (=1/\beta, any qty)','B/P_1^*, B/P_2^*, B/P_3^*'},'Location','southeast');
    sgtitle('Figure 2: Asset-market equilibrium');
    save_figure(f2, 'Figure2', par.figdir);

    %% ---------- Figure 3: real tax rule (price-asset space) -----------------
    f3 = figure('Name','Figure 3','Color','w','Position',[100 100 900 380]);
    rt = R.rtr;
    subplot(1,2,1); hold on; box on;
    plot(rt.fig.supply, rt.fig.P, 'b-', 'LineWidth', 2);
    plot(rt.fig.demand, rt.fig.P, 'r-', 'LineWidth', 2);
    for k=1:numel(rt.P), plot(rt.BP(k), rt.P(k), 'ko','MarkerFaceColor','k'); end
    xlabel('Assets (Bonds)'); ylabel('Price Level P');
    title(sprintf('\\tau*=%.3f (as calibrated)', rt.tau_star));
    legend({'Gov. Bonds B/P','HH Real Asset Demand'},'Location','best');
    par2 = par; par2.tau_star = -par.tau_star;
    rt2 = real_tax_rules(par2, ad);
    subplot(1,2,2); hold on; box on;
    plot(rt2.fig.supply, rt2.fig.P, 'b-', 'LineWidth', 2);
    plot(rt2.fig.demand, rt2.fig.P, 'r-', 'LineWidth', 2);
    for k=1:numel(rt2.P), plot(rt2.BP(k), rt2.P(k), 'ko','MarkerFaceColor','k'); end
    xlabel('Assets (Bonds)'); ylabel('Price Level P');
    title(sprintf('\\tau*=%.3f (sign flipped)', rt2.tau_star));
    legend({'Gov. Bonds B/P','HH Real Asset Demand'},'Location','best');
    sgtitle('Figure 3: Asset-market equilibrium with real tax rule (Eq. 34)');
    save_figure(f3, 'Figure3', par.figdir);

    %% ---------- Figure 4: nominal gov. expenditure / price-indexed debt -----
    f4 = figure('Name','Figure 4','Color','w','Position',[100 100 900 380]);
    gx = R.gov;
    subplot(1,2,1); hold on; box on;
    cols = lines(size(gx.fig.curves,2));
    for c=1:size(gx.fig.curves,2)
        plot(gx.fig.curves(:,c), gx.fig.r, '-', 'Color', cols(c,:), 'LineWidth', 1.8);
    end
    xline(gx.fig.Breal, 'b-', 'LineWidth', 1.5);
    yline(1/par.beta-1, 'k--');
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(a) Asset demand curve shifts with P');
    legend(arrayfun(@(p) sprintf('S(1+r;G/P), P=%.2f',p), gx.fig.Plevels, 'uni',0),'Location','southeast');
    subplot(1,2,2); hold on; box on;
    if isfinite(gx.caseA.P)
        rr2 = gx.fig.r;
        eq = nan(size(rr2)); parA=par; parA.inc_scale=(1-par.omega_e);
        for k=1:numel(rr2)
            if par.beta*(1+rr2(k))<1
                eq(k)=aggregate_savings(parA, rr2(k), par.G/gx.caseA.P - par.omega_e + rr2(k)*gx.fig.Breal);
            end
        end
        plot(eq, rr2, 'r-', 'LineWidth', 2);
        xline(gx.fig.Breal, 'b-', 'LineWidth', 1.5);
        yline(gx.r_ss, 'k:'); plot(gx.fig.Breal, gx.r_ss, 'ko','MarkerFaceColor','k');
    end
    yline(1/par.beta-1,'k--');
    xlabel('Assets (Bonds)'); ylabel('Real interest rate r');
    title('(b) Equilibrium price level P*');
    sgtitle('Figure 4: Asset market with nominal G / price-indexed debt B^{real}');
    save_figure(f4, 'Figure4', par.figdir);

    %% ---------- Figure 5: inflation vs nominal gov. expenditure growth ------
    D = load_oecd_data(par);          % <-- now downloads live from the internet
    % toolbox-free correlation on complete cases
    gg = D.govexp(:); ii = D.infl(:);
    ok = isfinite(gg) & isfinite(ii);
    if nnz(ok) >= 2
        C  = corrcoef(gg(ok), ii(ok));
        cc = C(1,2);
    else
        cc = NaN;
    end

    f5 = figure('Name','Figure 5','Color','w','Position',[100 100 600 560]);
    hold on; box on;
    plot(gg(ok), ii(ok), 'o', 'MarkerFaceColor',[0.1 0.2 0.5], 'MarkerEdgeColor','k');
    if isfield(D,'country')
        for k=find(ok).'
            text(gg(k)+0.05, ii(k), D.country{k}, 'FontSize',7, 'Color',[0.3 0.3 0.3]);
        end
    end
    lo = min([gg(ok);ii(ok)]); hi = max([gg(ok);ii(ok)]);
    plot([lo hi],[lo hi],'r-','LineWidth',1.5);                 % 45-degree line
    xlabel('Nom. Gov. Expenditure / Real GDP growth (percent)');
    ylabel('Inflation Rate (percent)');
    if D.is_real && ~D.is_proxy
        ttl = sprintf('Figure 5: corr = %.2f (paper: 0.93)', cc);
    elseif D.is_real && D.is_proxy
        ttl = sprintf('Figure 5: corr = %.2f (paper: 0.93) [WEB PROXY, differs from NIPA def]', cc);
    else
        ttl = sprintf('Figure 5: corr = %.2f [ILLUSTRATIVE PLACEHOLDER - NOT REAL DATA]', cc);
    end
    title(ttl,'Interpreter','none');
    axis equal; grid on;
    % source footnote
    annotation('textbox',[0.02 0.005 0.96 0.05],'String',['Source: ' D.source], ...
               'EdgeColor','none','FontSize',7,'Interpreter','none', ...
               'Color',[0.4 0.4 0.4],'HorizontalAlignment','left');
    save_figure(f5, 'Figure5', par.figdir);

    fprintf('\nAll figures written to %s/ (png, pdf, fig). Fig.5 corr=%.3f | source: %s\n', ...
             par.figdir, cc, D.source);
end