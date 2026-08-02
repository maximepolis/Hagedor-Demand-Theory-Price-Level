function B = kv_grid_base()
% KV_GRID_BASE  The CALIBRATION grid, in one place.
%
% These are the bounds at which beta and chi_b were calibrated and at which
% every pre-widening number in the manuscript was produced. They are written
% here, once, because three separate drivers need to know whether a grid they
% loaded from disk has already been widened, and answering that question by
% comparing against a literal repeated in each of them is how the literals
% drift apart.
%
% The curvature exponent 2.4 is the exponent of the ORIGINAL power spacing,
%   b_j = blo + (bmax - blo) * u_j^2.4,     k_j = kmax * u_j^2.4,
% and is recorded so that kv_grid_curv's least-squares refit can be checked
% against the value it should recover on an unwidened grid.
%
% CHANGING THESE NUMBERS INVALIDATES EVERY STORED WIDENING FACTOR. A factor
% is meaningful only relative to a base; if the base moves, kfac = 6 stops
% denoting the grid it denoted when the scan verified it.

    B = struct( ...
        'kmax', 60, ...          % illiquid (tree) ceiling
        'bmax', 12, ...          % liquid (bond) ceiling
        'xmax', 420, ...         % adjuster cash-on-hand ceiling
        'blo',  1e-4, ...        % liquid floor
        'klo',  0, ...           % illiquid floor
        'curv', 2.4, ...         % power-spacing exponent of both grids
        'source', 'main_twoasset_ownership_kv.m: bmax=12; kmax=60; xmax=420');
end
