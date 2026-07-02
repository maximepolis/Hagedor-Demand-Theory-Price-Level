function out = ftpl_comparison(params, ss)
% FTPL_COMPARISON  Contrast the Demand Theory of the Price Level (DTPL) with the
% Fiscal Theory of the Price Level (FTPL). The DTPL is NOT the FTPL.
%
% DTPL (this paper, passive/Ricardian fiscal policy)
%   Fiscal policy adjusts taxes to satisfy the government budget constraint
%   (tau^ss = r^ss S). The price level is determined by PRIVATE ASSET DEMAND and
%   ASSET-MARKET CLEARING:  P*_DTPL = B / S(1+r^ss).
%
% FTPL (active fiscal policy, complete markets / representative agent)
%   The real rate is pinned by preferences (1+r = 1/beta) and the price level is
%   selected so the real value of nominal liabilities equals the present value of
%   real primary surpluses {s_t}:
%       B / P_FTPL = sum_{t>=0} (1/(1+r))^t s_t = s / r   (constant surplus s).
%   =>  P_FTPL = B r / s.
%
% These prices GENERICALLY DIFFER: DTPL uses the heterogeneous-agent asset-demand
% schedule and passive fiscal policy; FTPL uses a present-value fiscal condition
% and active fiscal policy. This module computes both and reports the gap.
%
% INPUTS
%   params : setup_params struct. Optional params.ftpl_surplus (default: matches
%            the DTPL steady-state real primary surplus for a fair comparison).
%   ss     : baseline DTPL steady state (from solve_steady_state_DTPL).
%
% OUTPUT
%   out : struct with .P_DTPL .P_FTPL .r_DTPL .r_FTPL .surplus .gap .msg.
%
% PAPER SECTION: FTPL comparison / discussion. The main replication is DTPL; the
% FTPL is implemented ONLY for contrast (see REPLICATION_NOTES).

    out = struct();

    % ----- DTPL price (from asset-market clearing) -----
    out.P_DTPL = ss.Pstar;
    out.r_DTPL = ss.r_ss;

    % ----- FTPL price (present value of real primary surpluses) -----
    r_ftpl = 1/params.beta - 1;    % complete-markets real rate
    % pick a real primary surplus; default to the DTPL steady-state tax so the
    % comparison is like-for-like (any active surplus would do).
    if isfield(params,'ftpl_surplus') && ~isempty(params.ftpl_surplus)
        s = params.ftpl_surplus;
    else
        if isfinite(ss.tau_ss), s = max(ss.tau_ss, 1e-4); else, s = 0.02; end
    end
    out.surplus = s;
    out.r_FTPL  = r_ftpl;

    if r_ftpl > 0
        out.P_FTPL = params.Bnom * r_ftpl / s;   % B/P = s/r  => P = B r / s
    else
        out.P_FTPL = NaN;
    end

    if isfinite(out.P_DTPL) && isfinite(out.P_FTPL)
        out.gap = out.P_FTPL - out.P_DTPL;
    else
        out.gap = NaN;
    end

    out.msg = sprintf([ ...
        'DTPL vs FTPL: P_DTPL = B/S(1+r^ss) = %.4f (r^ss=%.4f, passive fiscal);\n' ...
        '  P_FTPL = B r/s = %.4f (r=1/beta-1=%.4f, active fiscal, surplus s=%.4f).\n' ...
        '  gap (P_FTPL - P_DTPL) = %.4f. These generically DIFFER: DTPL is\n' ...
        '  determined by asset-market clearing under passive fiscal policy;\n' ...
        '  FTPL by a present-value fiscal condition under active fiscal policy.'], ...
        out.P_DTPL, out.r_DTPL, out.P_FTPL, out.r_FTPL, s, out.gap);

    fprintf('\n[FTPL comparison]\n%s\n', out.msg);
end
