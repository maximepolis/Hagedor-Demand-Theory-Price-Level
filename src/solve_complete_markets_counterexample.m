function out = solve_complete_markets_counterexample(params)
% SOLVE_COMPLETE_MARKETS_COUNTEREXAMPLE  Demonstrates that in the complete-
% markets / representative-agent economy the steady-state price level is
% INDETERMINATE, in contrast to the incomplete-markets DTPL result.
%
% LOGIC (Section on complete-markets indeterminacy)
%   With complete markets a representative household prices bonds by its Euler
%   equation, which in steady state fixes the real rate at
%       1 + r^ss = 1/beta
%   INDEPENDENTLY of the real quantity of bonds. Asset demand is degenerate: the
%   household is willing to hold ANY quantity of real bonds at r = 1/beta - 1.
%   By Ricardian equivalence the real quantity of government debt is irrelevant
%   for real allocations, so the asset-market clearing condition B/P = S(1+r)
%   does NOT pin down P: for any nominal B and any P>0 the condition is either
%   redundant or trivially satisfiable. Hence a CONTINUUM of price levels is
%   admissible unless an active (FTPL-type) fiscal restriction is imposed.
%
% INPUT
%   params : struct from setup_params.
%
% OUTPUT
%   out : struct with
%         .r_complete   = 1/beta - 1 (the pinned real rate),
%         .unique       = false,
%         .Pgrid        = a continuum of admissible price levels,
%         .Breal_grid   = B/P for each admissible P (all admissible),
%         .msg          = explanatory message,
%         .ricardian    = true.
%
% This module intentionally does NOT solve for a unique price (doing so would be
% economically wrong here). See checks.m item (9).
%
% PAPER SECTION: complete-markets counterexample (Figure 2, right panel).

    r_complete = 1/params.beta - 1;

    % A continuum of admissible price levels (any positive P is consistent).
    Pgrid      = linspace(params.P_min, params.P_max, params.nP);
    Breal_grid = params.Bnom ./ Pgrid;    % real bond value varies freely

    out = struct();
    out.r_complete = r_complete;
    out.unique     = false;
    out.Pgrid      = Pgrid;
    out.Breal_grid = Breal_grid;
    out.ricardian  = true;
    out.Bnom       = params.Bnom;
    out.msg = sprintf([ ...
        'COMPLETE MARKETS: real rate pinned at 1+r = 1/beta = %.4f, ' ...
        'independent of B/P. Asset-market clearing is REDUNDANT because ' ...
        'Ricardian equivalence makes the real quantity of government bonds ' ...
        'irrelevant for steady-state real allocations. The price level is ' ...
        'INDETERMINATE: any P>0 is admissible (no unique P*).'], ...
        1/params.beta);

    fprintf('\n[complete-markets counterexample]\n%s\n', out.msg);
end
