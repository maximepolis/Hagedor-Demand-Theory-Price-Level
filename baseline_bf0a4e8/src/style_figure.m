function style_figure(fh)
% STYLE_FIGURE  Apply the project-wide common formatting standard to a figure.
%
% Called once by SAVE_ALL_FIGS, immediately before export, so that EVERY
% figure the replication package produces -- regardless of which driver made
% it -- shares one visual standard: the same fonts, font sizes, axis line
% weights, tick style, grid, legend look, and a minimum data-line weight for
% legibility when a 2x3 panel is scaled to \textwidth in the paper.
%
% Design goals (top-5-journal camera-ready):
%   * Serif font (Times-like) at a size that stays readable when a 1100x640
%     figure is printed at 0.6--0.95\textwidth.
%   * Thin but crisp axes, ticks pointing out, a light dotted grid.
%   * Data lines never thinner than 1.6pt.
%   * Framed, opaque legends at a consistent size.
% The function is deliberately CONSERVATIVE: it standardizes appearance only
% and never moves, rescales, or deletes data, so re-styling an existing figure
% cannot change what it reports.
%
% INPUT
%   fh : figure handle. If empty or invalid the function is a no-op.

    if nargin < 1 || isempty(fh) || ~ishandle(fh), return; end

    % ---- house style constants (single source of truth) ------------------
    FONT      = 'Times New Roman';   % falls back gracefully if unavailable
    FS_AXIS   = 14;                  % tick labels
    FS_LABEL  = 15;                  % x/y labels
    FS_TITLE  = 15;                  % subplot titles
    FS_LEGEND = 13;
    LW_AXIS   = 0.9;                 % axis/box line width
    LW_MIN    = 1.8;                 % minimum data-line width
    GRIDA     = 0.15;                % grid alpha (light)
    MS_MIN    = 5;                   % minimum marker size

    % House palette: one ordering used by EVERY figure, so a given series
    % position carries the same colour throughout the paper. Colourblind-safe
    % (Okabe-Ito ordering) and legible in greyscale, where the sequence also
    % runs light-to-dark. Applying it here rather than in each driver is what
    % makes figures produced by different drivers look like one set.
    PALETTE = [ 0.00 0.45 0.70;      % blue
                0.84 0.37 0.00;      % vermillion
                0.00 0.62 0.45;      % green
                0.80 0.47 0.65;      % purple
                0.90 0.62 0.00;      % amber
                0.35 0.35 0.35;      % grey
                0.34 0.71 0.91 ];    % sky

    set(fh, 'Color', 'w');
    try, colororder(fh, PALETTE); catch, end   % no-op on older releases

    % ---- axes ------------------------------------------------------------
    ax = findall(fh, 'Type', 'axes');
    for k = 1:numel(ax)
        a = ax(k);
        try
            set(a, 'FontName', FONT, 'FontSize', FS_AXIS, ...
                   'LineWidth', LW_AXIS, 'TickDir', 'out', ...
                   'Box', 'on', 'Layer', 'top', ...
                   'XGrid', 'on', 'YGrid', 'on', ...
                   'GridLineStyle', ':', 'GridAlpha', GRIDA, ...
                   'TickLength', [0.015 0.015]);
            set(a.XLabel, 'FontName', FONT, 'FontSize', FS_LABEL);
            set(a.YLabel, 'FontName', FONT, 'FontSize', FS_LABEL);
            set(a.Title,  'FontName', FONT, 'FontSize', FS_TITLE, ...
                          'FontWeight', 'bold');
        catch
            % polaraxes / geoaxes etc. -- skip silently
        end
    end

    % ---- data lines: enforce a legible minimum weight and marker size ----
    ln = findall(fh, 'Type', 'line');
    for k = 1:numel(ln)
        try
            if get(ln(k), 'LineWidth') < LW_MIN
                set(ln(k), 'LineWidth', LW_MIN);
            end
            if ~strcmp(get(ln(k), 'Marker'), 'none') && ...
                    get(ln(k), 'MarkerSize') < MS_MIN
                set(ln(k), 'MarkerSize', MS_MIN);
            end
        catch
        end
    end

    % ---- zero reference line: same weight/colour wherever one is drawn ---
    % Many panels report deviations, where the y = 0 line is the reading aid.
    % Standardizing it here keeps that cue identical across the paper.
    for k = 1:numel(ax)
        try
            a = ax(k); yl = get(a, 'YLim');
            if yl(1) < 0 && yl(2) > 0
                hold(a, 'on');
                z = plot(a, get(a,'XLim'), [0 0], '-', ...
                         'Color', [0.45 0.45 0.45], 'LineWidth', 0.8);
                uistack(z, 'bottom');
                set(get(get(z,'Annotation'),'LegendInformation'), ...
                    'IconDisplayStyle', 'off');   % keep it out of legends
            end
        catch
        end
    end

    % ---- text objects (annotations inside axes) --------------------------
    tx = findall(fh, 'Type', 'text');
    for k = 1:numel(tx)
        try, set(tx(k), 'FontName', FONT); catch, end
    end

    % ---- legends: framed, opaque, consistent size ------------------------
    lg = findall(fh, 'Type', 'legend');
    for k = 1:numel(lg)
        try
            set(lg(k), 'FontName', FONT, 'FontSize', FS_LEGEND, ...
                       'Box', 'on', 'Color', 'w', ...
                       'EdgeColor', [0.4 0.4 0.4]);
        catch
        end
    end

    % ---- colorbars -------------------------------------------------------
    cb = findall(fh, 'Type', 'colorbar');
    for k = 1:numel(cb)
        try, set(cb(k), 'FontName', FONT, 'FontSize', FS_AXIS); catch, end
    end
end
