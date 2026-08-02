function plot_transition_fig(TRn, TRi, pgc, pg, TRr)
% PLOT_TRANSITION_FIG  PFig18: the nonlinear HANK-DTPL price-level transition.
% Four key panels (journal layout): the stationarized price-level path and
% the inflation path -- where the announcement effect and the financing sign
% flip live -- plus green capital and damages, the slow real accumulation
% they contrast with. Convergence diagnostics (market-clearing residuals,
% b_t vs S_t) are NOT plotted here: they are reported numerically in the
% transition summary table, which is where a reader checks them.
%
% INPUTS: TRn/TRi solved transition structs (nominal / indexed), pgc the
% calibrated params used for the run (mu), pg project params (figdir),
% TRr (optional) the rebate-financed design (third line in the price and
% inflation panels).

    if nargin < 5, TRr = []; end
    if isempty(TRn.msg) || ~isfield(TRn, 'phat')
        fprintf('  [plot_transition_fig] no converged nominal path -- skipped\n');
        return;
    end
    hasR = ~isempty(TRr) && isfield(TRr, 'phat') && ...
           isfield(TRr, 'reportable') && TRr.reportable;
    T  = numel(TRn.phat);
    tv = 1:T;
    BLUE = [0.10 0.30 0.75]; GREEN = [0.20 0.55 0.25];
    ORANGE = [0.85 0.55 0.10];

    fh = figure('Name','PFig18: nonlinear HANK-DTPL transition','Color','w', ...
                'Position',[60 60 1150 700]);
    leg1 = {'nominal appropriation, service rule', 'indexed mandate, service rule'};

    subplot(2,2,1); hold on; box on;
    plot(tv, TRn.phat, 'LineWidth', 2.0, 'Color', BLUE);
    if isfield(TRi,'phat'), plot(tv, TRi.phat, 'LineWidth', 2.0, 'Color', GREEN); end
    if hasR
        plot(tv, TRr.phat, 'LineWidth', 2.0, 'Color', ORANGE);
        leg1{end+1} = 'levy + rebate';
    end
    yline(TRn.P0, ':k', 'HandleVisibility','off');
    ylabel('price level  P_t/(1+\mu)^t');
    title('(a) stationarized price level');
    legend(leg1, 'Location','east');

    subplot(2,2,2); hold on; box on;
    plot(tv, 100*TRn.pi_path, 'LineWidth', 2.0, 'Color', BLUE);
    if isfield(TRi,'pi_path'), plot(tv, 100*TRi.pi_path, 'LineWidth', 2.0, 'Color', GREEN); end
    if hasR, plot(tv, 100*TRr.pi_path, 'LineWidth', 2.0, 'Color', ORANGE); end
    yline(100*pgc.mu, ':k', 'HandleVisibility','off');
    ylabel('inflation (% per year)');
    title('(b) inflation vs the 2% trend');

    subplot(2,2,3); hold on; box on;
    plot(tv, TRn.Kg_path, 'LineWidth', 2.0, 'Color', GREEN);
    xlabel('years since announcement');
    ylabel('green capital  K_{g,t}');
    title('(c) abatement capital');

    subplot(2,2,4); hold on; box on;
    plot(tv, 100*TRn.D_path, 'LineWidth', 2.0, 'Color', ORANGE);
    xlabel('years since announcement');
    ylabel('damages (% of endowment)');
    title('(d) climate damages');

    save_all_figs(fh, 'PFig18_dtpl_transition', pg);
    fprintf('\n  [saved] PFig18_dtpl_transition\n');
end
