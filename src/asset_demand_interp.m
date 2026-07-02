function ad = asset_demand_interp(params, rgrid)
% ASSET_DEMAND_INTERP  Build a fast interpolant of the steady-state asset-demand
% function S(1+r) over a grid of real rates, for reuse by the root-finding
% modules (real tax rule, nominal G, capital, money) and the figure scripts.
%
% Rather than re-solve the full household problem at every trial price level,
% these modules evaluate S at many real rates; this helper solves S(1+r) once on
% a grid and returns a monotone linear interpolant (assets are increasing in r
% in the incomplete-markets model over the admissible range).
%
% INPUT
%   params : struct from setup_params.
%   rgrid  : (optional) row vector of real rates; defaults to a grid from
%            params.r_min to params.r_max with params.nr points.
%
% OUTPUT
%   ad : struct with
%        .rgrid, .Sgrid : the solved sweep (Sgrid = Inf/NaN where it diverges),
%        .converged     : logical mask of converged points,
%        .S_of_r        : function handle S = ad.S_of_r(r) (linear interp,
%                         NaN outside the converged range),
%        .rmax_finite   : largest r with a finite converged S,
%        .out           : the raw vector out-struct from aggregate_asset_demand.
%
% PAPER SECTION: Sections 2.2-2.4 (asset-demand function S(1+r)).

    if nargin < 2 || isempty(rgrid)
        rgrid = linspace(params.r_min, params.r_max, params.nr);
    end
    rgrid = rgrid(:)';

    [Svec, out] = aggregate_asset_demand(rgrid, params);

    conv = out.converged & isfinite(Svec) & ~out.diverged;

    rc = rgrid(conv);
    Sc = Svec(conv);
    % keep strictly increasing r for interp
    [rc, ord] = sort(rc);
    Sc        = Sc(ord);

    ad = struct();
    ad.rgrid       = rgrid;
    ad.Sgrid       = Svec;
    ad.converged   = conv;
    ad.out         = out;
    if numel(rc) < 2
        % Need at least two points to interpolate; degrade gracefully.
        ad.S_of_r      = @(r) nan(size(r));
        if isempty(rc), ad.rmax_finite = -Inf; else, ad.rmax_finite = max(rc); end
        warning('asset_demand_interp:few', ...
            'Fewer than 2 converged asset-demand points; S(r) interpolant is NaN.');
    else
        ad.rmax_finite = max(rc);
        ad.S_of_r = @(r) interp_clamped(rc, Sc, r);
    end
end

% -------------------------------------------------------------------------
function S = interp_clamped(rc, Sc, r)
% Linear interpolation; returns NaN outside [min(rc), max(rc)] (no extrapolation).
    S = interp1(rc, Sc, r, 'linear', NaN);
end
