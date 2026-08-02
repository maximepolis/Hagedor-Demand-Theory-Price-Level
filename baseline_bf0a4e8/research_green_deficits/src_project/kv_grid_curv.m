function [lo, hi, g] = kv_grid_curv(x)
% KV_GRID_CURV  Recover the (lo, hi, curvature) triple of a power-spaced grid.
%
% Every state grid in the preferred economy is built as
%       x_j = lo + (hi - lo) * u_j^g,   u_j = (j-1)/(n-1),
% but only the NODES are carried around in the saved calibration. Any code
% that rebuilds a grid -- to coarsen it for a debug run, or to widen its top
% -- has to know g, and hard-coding the literal 2.4 or 2.8 from the
% calibration script silently desynchronises the moment either is changed.
% This recovers g from the nodes themselves, so a rebuild inherits whatever
% curvature the calibration actually used.
%
% g is fitted by least squares on log(u_j) over the interior nodes rather
% than read off a single node, so a grid that is only approximately
% power-spaced still gets its best power-law representation instead of an
% artefact of whichever node was picked.

    x = x(:);
    n = numel(x);
    assert(n >= 4, 'kv_grid_curv: need at least 4 nodes');
    lo = x(1); hi = x(end);
    assert(hi > lo, 'kv_grid_curv: grid is not increasing');

    u = (0:n-1)'/(n-1);
    z = (x - lo)/(hi - lo);
    j = 2:n-1;                                  % drop u=0 and u=1 (log 0/0)
    keep = j(z(j) > 0);
    lu = log(u(keep)); lz = log(z(keep));
    g = (lu' * lz) / (lu' * lu);                % LS through the origin
    if ~isfinite(g) || g <= 0, g = 1; end
end
