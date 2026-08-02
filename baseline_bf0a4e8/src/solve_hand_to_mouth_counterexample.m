function out = solve_hand_to_mouth_counterexample(params)
% SOLVE_HAND_TO_MOUTH_COUNTEREXAMPLE  Two-type (TANK-style) counterexample:
% a fraction of households are hand-to-mouth (HtM) and the rest are permanent-
% income (PIH) households. Shows that the steady-state price level is again
% INDETERMINATE because the PIH Euler equation pins the real rate at 1/beta - 1,
% leaving asset demand perfectly elastic (a horizontal schedule) rather than a
% nondegenerate downward/upward-sloping locus that could pin down P.
%
% LOGIC
%   * HtM households consume current income each period and hold no bonds:
%       c^{HtM} = e - tau,   a' = 0.  They contribute ZERO to bond demand.
%   * PIH households smooth consumption; their Euler equation in steady state
%       beta (1+r) = 1  =>  1 + r = 1/beta
%     pins the real rate regardless of how many bonds they hold. They are
%     willing to absorb any real bond supply at that rate.
%   Therefore aggregate real asset demand is a HORIZONTAL line at r = 1/beta-1:
%   changing P only rescales the real bond value B/P and reallocates it among
%   PIH households, without generating a unique intersection. No nondegenerate
%   S(1+r) schedule => P indeterminate.
%
% INPUT
%   params : struct from setup_params. Uses optional field params.htm_share
%            (default 0.3) for the fraction of hand-to-mouth households.
%
% OUTPUT
%   out : struct with
%         .r_pih        = 1/beta - 1,
%         .htm_share,
%         .unique       = false,
%         .Pgrid, .Breal_grid : continuum of admissible (P, B/P),
%         .demand_schedule    : struct with rgrid and a degenerate (flat) S,
%         .msg.
%
% PAPER SECTION: hand-to-mouth + PIH counterexample.

    if isfield(params, 'htm_share') && ~isempty(params.htm_share)
        htm_share = params.htm_share;
    else
        htm_share = 0.30;
    end

    r_pih = 1/params.beta - 1;

    % The "asset-demand schedule" is degenerate: perfectly elastic at r_pih.
    rgrid = linspace(params.r_min, params.r_max, params.nr);
    % Off r_pih, PIH households want +/-Inf bonds; at r_pih any level is optimal.
    % Represent this as NaN off the rate and "any value" at r_pih.
    Sflat = nan(size(rgrid));
    [~, i0] = min(abs(rgrid - r_pih));
    Sflat(i0) = NaN;   % undetermined level at the pinned rate

    Pgrid      = linspace(params.P_min, params.P_max, params.nP);
    Breal_grid = params.Bnom ./ Pgrid;

    out = struct();
    out.r_pih       = r_pih;
    out.htm_share   = htm_share;
    out.unique      = false;
    out.Pgrid       = Pgrid;
    out.Breal_grid  = Breal_grid;
    out.demand_schedule = struct('rgrid', rgrid, 'S', Sflat, 'r_pinned', r_pih);
    out.Bnom        = params.Bnom;
    out.msg = sprintf([ ...
        'HAND-TO-MOUTH + PIH: HtM share = %.2f hold no bonds; PIH Euler pins ' ...
        '1+r = 1/beta = %.4f. Asset demand is perfectly elastic at that rate ' ...
        '(a horizontal schedule), so changing P only redistributes the real ' ...
        'bond value B/P among PIH households and does NOT pin down P. The ' ...
        'price level is INDETERMINATE (no nondegenerate S(1+r) locus).'], ...
        htm_share, 1/params.beta);

    fprintf('\n[hand-to-mouth counterexample]\n%s\n', out.msg);
end
