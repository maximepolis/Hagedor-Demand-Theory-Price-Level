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
    % Semantic registry (see src/regime_style.m): nominal appropriation is
    % the baseline financing environment, the indexed mandate is the real
    % program, and the third path is the LEVY-PLUS-REBATE design -- see the
    % TRr line in the input list above. An earlier wiring of this file read it
    % as a 'reversal' path and drew it amber, which put the rebate regime in
    % one colour here and another in every financing figure: exactly the drift
    % the registry exists to stop, introduced by guessing the series' meaning
    % instead of reading the argument doc one screen up.
    %
    % LINE STYLE IS LOAD-BEARING HERE, not decoration. The nominal and indexed
    % price paths very nearly COINCIDE in panels (a) and (b) -- that near
    % coincidence is a result, not an accident -- so with both drawn solid the
    % second simply paints over the first and the figure appears to show two
    % series when it plots three. Taking the registry's line style as well as
    % its colour keeps the overlap visible, and keeps it visible in print.
    [BLUE,  LSN] = regime_style('nominal');
    [GREEN, LSI] = regime_style('indexed');
    [PURPLE, LSR] = regime_style('rebate');
    DAMCOL = regime_style('damage');

    fh = figure('Name','PFig18: nonlinear HANK-DTPL transition','Color','w', ...
                'Position',[60 60 1150 700]);
    % R11 safety patch: all three paths in this panel are BALANCED SERVICE-RULE
    % paths, so no label may contain the word 'deficit'. The stale checked-in
    % PDF carried 'nominal budget, deficit' and 'indexed mandate, deficit',
    % which described a different experiment from the one plotted.
    EMD  = char(8212);                       % em dash
    leg1 = {['Nominal appropriation ' EMD ' service rule'], ...
            ['Indexed mandate ' EMD ' service rule']};

    subplot(2,2,1); hold on; box on;
    plot(tv, TRn.phat, 'LineWidth', 2.0, 'Color', BLUE, 'LineStyle', LSN);
    if isfield(TRi,'phat')
        plot(tv, TRi.phat, 'LineWidth', 2.0, 'Color', GREEN, 'LineStyle', LSI);
    end
    if hasR
        plot(tv, TRr.phat, 'LineWidth', 2.0, 'Color', PURPLE, 'LineStyle', LSR);
        leg1{end+1} = ['Levy plus rebate ' EMD ' service rule'];
    end
    yline(TRn.P0, ':k', 'HandleVisibility','off');
    ylabel('price level  P_t/(1+\mu)^t');
    title('(a) stationarized price level');
    legend(leg1, 'Location','east');

    subplot(2,2,2); hold on; box on;
    plot(tv, 100*TRn.pi_path, 'LineWidth', 2.0, 'Color', BLUE, 'LineStyle', LSN);
    if isfield(TRi,'pi_path')
        plot(tv, 100*TRi.pi_path, 'LineWidth', 2.0, 'Color', GREEN, 'LineStyle', LSI);
    end
    if hasR
        plot(tv, 100*TRr.pi_path, 'LineWidth', 2.0, 'Color', PURPLE, 'LineStyle', LSR);
    end
    yline(100*pgc.mu, ':k', 'HandleVisibility','off');
    ylabel('inflation (% per year)');
    title('(b) inflation vs the 2% trend');

    subplot(2,2,3); hold on; box on;
    plot(tv, TRn.Kg_path, 'LineWidth', 2.0, 'Color', GREEN);
    xlabel('years since announcement');
    ylabel('green capital  K_{g,t}');
    title('(c) abatement capital');

    subplot(2,2,4); hold on; box on;
    % Damages, not a financing regime: the registry's damage colour, so this
    % panel cannot be misread as plotting one of the three policy paths.
    plot(tv, 100*TRn.D_path, 'LineWidth', 2.0, 'Color', DAMCOL);
    xlabel('years since announcement');
    ylabel('damages (% of endowment)');
    title('(d) climate damages');

    save_all_figs(fh, 'PFig18_dtpl_transition', pg);
    fprintf('\n  [saved] PFig18_dtpl_transition\n');
end
