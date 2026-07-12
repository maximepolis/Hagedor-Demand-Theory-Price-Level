function plot_transition_fig(TRn, TRi, pgc, pg)
% PLOT_TRANSITION_FIG  PFig18: the nonlinear HANK-DTPL price-level transition
% (nominal-appropriation and indexed-mandate designs), from solved paths.
% Extracted from main_project_transition so the figure can be re-exported
% from output/transition_results.mat without re-solving the transition.
%
% INPUTS: TRn/TRi solved transition structs (nominal / indexed), pgc the
% calibrated params used for the run (mu), pg project params (figdir).

    if isempty(TRn.msg) || ~isfield(TRn, 'phat')
        fprintf('  [plot_transition_fig] no converged nominal path -- skipped\n');
        return;
    end
    T  = numel(TRn.phat);
    tv = 1:T;
    BLUE = [0.10 0.30 0.75]; GREEN = [0.20 0.55 0.25];
    RED  = [0.85 0.20 0.15]; ORANGE = [0.85 0.55 0.10];

    fh = figure('Name','PFig18: nonlinear HANK-DTPL transition','Color','w', ...
                'Position',[60 60 1100 660]);
    subplot(2,3,1); hold on; box on;
    plot(tv, TRn.phat, 'LineWidth', 1.8, 'Color', BLUE);
    if isfield(TRi,'phat'), plot(tv, TRi.phat, 'LineWidth', 1.8, 'Color', GREEN); end
    yline(TRn.P0, ':k', 'HandleVisibility','off');
    yline(TRn.eq1.P, '--k', 'HandleVisibility','off');
    title('stationarized price level P_t/(1+\mu)^t');
    legend({'nominal budget','indexed mandate'}, 'Location','best');
    subplot(2,3,2); hold on; box on;
    plot(tv, 100*TRn.pi_path, 'LineWidth', 1.8, 'Color', BLUE);
    if isfield(TRi,'pi_path'), plot(tv, 100*TRi.pi_path, 'LineWidth', 1.8, 'Color', GREEN); end
    yline(100*pgc.mu, ':k', 'HandleVisibility','off');
    title('inflation (% per year)');
    subplot(2,3,3); hold on; box on;
    plot(tv, TRn.b_path, 'LineWidth', 1.8, 'Color', BLUE);
    plot(tv, TRn.S_path, '--', 'LineWidth', 1.6, 'Color', RED);
    title('real debt b_t vs asset demand S_t');
    legend({'b_t = B_t/P_t','S_t'}, 'Location','best');
    subplot(2,3,4); hold on; box on;
    plot(tv, TRn.Kg_path, 'LineWidth', 1.8, 'Color', GREEN);
    xlabel('years'); title('green capital K_{g,t}');
    subplot(2,3,5); hold on; box on;
    plot(tv, TRn.D_path, 'LineWidth', 1.8, 'Color', ORANGE);
    xlabel('years'); title('damages D_t');
    subplot(2,3,6); hold on; box on;
    semilogy(tv, abs(TRn.resid), 'LineWidth', 1.6, 'Color', BLUE);
    if isfield(TRi,'resid'), semilogy(tv, abs(TRi.resid), 'LineWidth', 1.6, 'Color', GREEN); end
    xlabel('years'); ylabel('|S_t - b_t|/b_t');
    title('market-clearing residuals');
    save_all_figs(fh, 'PFig18_dtpl_transition', pg);
    fprintf('\n  [saved] PFig18_dtpl_transition\n');
end
