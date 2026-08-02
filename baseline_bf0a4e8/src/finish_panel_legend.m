function finish_panel_legend(fh, leg_handles, leg_labels, ncol)
% FINISH_PANEL_LEGEND  Shared bottom legend for a multi-panel figure, without
% overlap: all axes are squeezed upward into a common region and the legend
% is centered in the reserved band underneath.
%
% Call AFTER all subplots are drawn:
%   finish_panel_legend(fh, leg_handles, leg_labels, ncol)
% where leg_handles are one representative line per scenario (from any panel)
% and ncol the number of legend columns (rows wrap automatically).
%
% Rationale: with the house style's larger fonts, MATLAB's default subplot
% margins leave no room for a figure-level legend; placing one at the bottom
% overprints the bottom row's axes. This helper (i) rescales every axes'
% vertical position into [band, top], preserving the relative layout, and
% (ii) puts one framed horizontal legend in the freed band.

    if nargin < 4 || isempty(ncol), ncol = numel(leg_labels); end
    valid = isgraphics(leg_handles);
    leg_handles = leg_handles(valid);
    leg_labels  = leg_labels(valid);
    if isempty(leg_handles), return; end
    nrow_leg = ceil(numel(leg_labels) / max(1,ncol));
    band = 0.035 + 0.055 * nrow_leg;      % bottom band height for the legend

    ax = findall(fh, 'Type', 'axes');
    ax = ax(~strcmp(get(ax, 'Tag'), 'legend'));
    lo = inf; hi = -inf;
    for k = 1:numel(ax)
        p = get(ax(k), 'Position');
        lo = min(lo, p(2)); hi = max(hi, p(2) + p(4));
    end
    tgt_lo = band + 0.075;                % leave room for bottom-row xlabels
    tgt_hi = 0.965;
    s = (tgt_hi - tgt_lo) / max(hi - lo, eps);
    for k = 1:numel(ax)
        p = get(ax(k), 'Position');
        p(2) = tgt_lo + (p(2) - lo) * s;
        p(4) = p(4) * s * 0.92;           % extra inter-row breathing room
        set(ax(k), 'Position', p);
    end

    lg = legend(leg_handles, leg_labels, 'Orientation', 'horizontal', ...
                'NumColumns', ncol, 'Box', 'on');
    drawnow;
    pos = lg.Position;                    % center in the reserved band
    lg.Position = [0.5 - pos(3)/2, max(0.008, (band - pos(4))/2), pos(3), pos(4)];
end
