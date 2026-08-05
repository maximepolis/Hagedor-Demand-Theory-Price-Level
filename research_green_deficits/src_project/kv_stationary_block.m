function out = kv_stationary_block(rb, q, dvd, tau, pe, V0, distIn)
% KV_STATIONARY_BLOCK  One evaluation of the preferred (ownership +
% illiquidity) household block: policies, distribution, and the two
% aggregates, at GIVEN prices and taxes.
%
% This is the single place where the preferred economy's household problem
% is turned into (S_b, S_k). The decomposition driver needs to evaluate
% policies and distributions at MISMATCHED arguments -- policies from one
% configuration aggregated against a distribution from another -- which is
% exactly what an exact policy/distribution decomposition requires, so the
% two steps are exposed separately here rather than fused.
%
% INPUT   rb, q, dvd, tau : scalars (bond return, tree price, dividend, tax)
%         pe              : params with eGrid ALREADY damage- and levy-scaled
%         V0              : optional warm start for the VFI
%         distIn          : optional. If supplied, the aggregates are formed
%                           against THIS distribution instead of the
%                           stationary one implied by the solved policies.
%                           This is the mismatched evaluation the
%                           decomposition needs.
% OUTPUT  out.sol .dist .Sb .Sk .bch .kch .ok .msg .dV .ddist
%
% The choice arrays bch/kch are the lambda-mixed adjuster/non-adjuster
% policies, identical in construction to the transition kernel's, so a
% stationary evaluation and a date of the path aggregate the same way.

    out = struct('ok', false, 'msg', '', 'Sb', NaN, 'Sk', NaN, ...
                 'sol', [], 'dist', [], 'bch', [], 'kch', [], ...
                 'dV', NaN, 'ddist', NaN, 'dist_loose', false, ...
                 'churn', NaN, 'churn_non', NaN, 'vfi_soft', true, ...
                 'vfi_iters', 0);
    if nargin < 6, V0 = []; end
    if nargin < 7, distIn = []; end

    [sol, dg] = solve_household_twoasset_kv(rb, q, dvd, tau, pe, V0);
    if ~dg.converged
        out.msg = sprintf('VFI failed (dV=%.2e after %d)', dg.supnorm, dg.iters);
        return;
    end
    out.sol = sol; out.dV = dg.supnorm;
    % Gate 6 of the acceptance protocol. Carried as a FRACTION that moved on
    % the final sweep, not as the consecutive-stable-sweep count also in dg:
    % the two have opposite polarity and the gate is "<= 0".
    if isfield(dg, 'churn_adj'), out.churn = dg.churn_adj; end
    if isfield(dg, 'churn_non'), out.churn_non = dg.churn_non; end
    % Did the VFI reach its own HARD tolerance, or did it soft-accept a
    % grid-limited fixed point? Gate 4.1 turns on this: a lowered gate-4
    % threshold must not be passable by the solver's own fallback.
    out.vfi_soft = isfield(dg, 'soft') && ~isempty(dg.soft) && dg.soft;
    % Sweep count, because gate 6 is only ANSWERABLE when at least two sweeps
    % ran: churn is a comparison between the last two, and a warm start that
    % is already at the fixed point converges on sweep 1 with nothing to
    % compare against. See the not-applicable branch in kv_gate_report.
    if isfield(dg, 'iters'), out.vfi_iters = dg.iters; end

    if isempty(distIn)
        [dist, dd] = stationary_distribution_twoasset_kv(sol, rb, q, dvd, tau, pe);
        % GRADED, not binary. The target is 1e-11; missing it by an order of
        % magnitude is not the same event as diverging, and treating the two
        % alike threw away otherwise usable prices as "infeasible". A run that
        % reached 1e-8 is reported as loose and carried, so the caller can
        % decide; only worse than that is a failure.
        if ~dd.converged && dd.supnorm > 1e-8
            out.msg = sprintf('distribution failed (dv=%.2e)', dd.supnorm);
            return;
        end
        out.dist_loose = ~dd.converged;
        out.ddist = dd.supnorm;
    else
        dist = distIn;                       % mismatched evaluation
        out.ddist = 0; out.dist_loose = false;
    end
    out.dist = dist;

    [out.Sb, out.Sk, out.bch, out.kch] = kv_agg_local(sol, dist, rb, q, dvd, tau, pe);
    out.ok = true;
end

function [Sb, Sk, bch, kch] = kv_agg_local(sol, dist, rb, q, d, tau, pe)
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb, nk, ne); kch = zeros(nb, nk, ne);
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        knon = kG'; if isfield(sol,'kNon'), knon = sol.kNon(:)'; end
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(knon, nb, 1);
    end
    Sb = sum(bch(:).*dist(:));
    Sk = sum(kch(:).*dist(:));
end
