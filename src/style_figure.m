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

    set(fh, 'Color', 'w');

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

    % ---- data lines: enforce a legible minimum weight --------------------
    ln = findall(fh, 'Type', 'line');
    for k = 1:numel(ln)
        try
            if get(ln(k), 'LineWidth') < LW_MIN
                set(ln(k), 'LineWidth', LW_MIN);
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
