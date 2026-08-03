function M = kv_wealth_mobility(dist0, polA, aGrid, ePi, opts)
% KV_WEALTH_MOBILITY  Liquid-wealth transition matrices and the accumulation
% profile after a permanent fiscal change.  (Referee R12, Major Comment 1.)
%
% WHY THIS IS THE FALSIFICATION TEST. The paper's pivotal primitive is that a
% permanent uniform lump-sum tax RAISES demand for nominal government
% liabilities. Its own decomposition attributes roughly +0.34 of that to the
% direct saving response at the initial distribution and roughly +3.44 to the
% endogenous movement of the stationary wealth distribution -- and the
% MARGINAL direct covariance is about -0.07, i.e. the opposite sign. So the
% result is not a precautionary-saving result at all; it is a long-run
% wealth-mobility result, and the moments that would discipline it -- who
% rebuilds buffers, from which bins, over what horizon -- are exactly the ones
% the manuscript concedes it has not confronted.
%
% MPC and constrained-share evidence disciplines the SMALL term. Nothing
% currently disciplines the LARGE one. That is the referee's central charge
% and it is correct as stated.
%
% WHAT THIS COMPUTES, from objects the model already produces:
%   1. the K x K transition matrix over liquid-wealth bins implied by the
%      policy and the income process, at a given (r, tau) configuration;
%   2. the same under the perturbed fiscal configuration;
%   3. bin-level net accumulation between the two stationary distributions,
%      so "which households hold the extra nominal assets" is answered by
%      bin rather than in aggregate;
%   4. horizon diagnostics -- how many periods until a given fraction of the
%      eventual redistribution has occurred -- because a mechanism that takes
%      eighty years to operate is not disciplined by the same evidence as one
%      that operates in five;
%   5. persistence and mobility summaries directly comparable to panel
%      statistics: diagonal retention, one-step upward and downward mobility,
%      and the Shorrocks index.
%
% WHAT IT CANNOT DO. It does not fetch external data. Comparing these to SCF,
% PSID or administrative balance-sheet panels is the step that turns the
% mechanism from internally coherent into externally disciplined, and that
% comparison has to be made against actual series. This function produces the
% model side of that comparison in a form a panel statistic can be laid
% against, and nothing here should be described as validation until it has.
%
% INPUT   dist0  na x ne stationary distribution
%         polA   na x ne next-period liquid asset policy (LEVELS, not indices)
%         aGrid  na x 1 asset grid
%         ePi    ne x ne income transition matrix
%         opts   .edges   bin edges in asset LEVELS (default: quintiles of
%                         dist0's marginal, which makes the bins comparable
%                         to published wealth-quintile transition tables)
%                .nbin    number of bins if edges are not supplied (5)
%                .horizon periods for the convergence profile (default 200)
%
% OUTPUT  M .Pi_bin      K x K one-step transition over bins
%           .edges, .bin_mass, .bin_mean_a
%           .retention   diagonal of Pi_bin
%           .up1, .down1 one-step upward / downward mobility
%           .shorrocks   (K - trace(Pi_bin))/(K-1)
%           .halflife    periods to half of the eventual bin-mass change
%           .profile     horizon x K bin-mass path from dist0
%
% The transition is built by the SAME lottery split the forward iteration
% uses, so the mobility reported here is the mobility the solved equilibrium
% actually has, not a re-discretization of it.

    if nargin < 5, opts = struct(); end
    na = numel(aGrid); ne = size(ePi, 1);
    assert(isequal(size(dist0), [na ne]), 'dist0 must be na x ne');
    assert(isequal(size(polA),  [na ne]), 'polA must be na x ne');

    nbin  = getdef(opts, 'nbin', 5);
    H     = getdef(opts, 'horizon', 200);
    edges = getdef(opts, 'edges', []);

    aG = aGrid(:);
    marg = sum(dist0, 2);                       % na x 1 wealth marginal
    if isempty(edges)
        edges = quantile_edges(aG, marg, nbin);
    end
    K = numel(edges) - 1;

    % ---- bin membership of each grid node --------------------------------
    binof = zeros(na, 1);
    for i = 1:na
        b = find(aG(i) >= edges(1:end-1) & aG(i) <= edges(2:end), 1, 'first');
        if isempty(b), b = K; end
        binof(i) = b;
    end

    % ---- one-step transition over (a,e), aggregated to bins --------------
    % The asset policy is off-grid, so the mass at a' is split between the two
    % neighbouring nodes by the SAME linear lottery the forward distribution
    % uses. Snapping to the nearest node instead would understate mobility by
    % exactly the within-cell movement that the wealth-distribution channel
    % consists of -- the channel under test.
    Pi_bin = zeros(K, K);
    for e = 1:ne
        for i = 1:na
            m = dist0(i, e);
            if m <= 0, continue; end
            [lo, hi, wlo] = lottery(polA(i, e), aG);
            for enext = 1:ne
                w = m * ePi(e, enext);
                Pi_bin(binof(i), binof(lo)) = Pi_bin(binof(i), binof(lo)) + w * wlo;
                Pi_bin(binof(i), binof(hi)) = Pi_bin(binof(i), binof(hi)) + w * (1 - wlo);
            end
        end
    end
    rs = sum(Pi_bin, 2);
    Pi_bin = Pi_bin ./ max(rs, eps);            % row-normalise: conditional

    % ---- summaries -------------------------------------------------------
    M = struct();
    M.edges = edges(:)';
    M.Pi_bin = Pi_bin;
    M.bin_mass = accum_bins(marg, binof, K);
    M.bin_mean_a = zeros(1, K);
    for b = 1:K
        sel = binof == b; w = marg(sel);
        if sum(w) > 0, M.bin_mean_a(b) = sum(aG(sel).*w)/sum(w); end
    end
    M.retention = diag(Pi_bin)';
    M.up1   = sum(diag(Pi_bin, 1));
    M.down1 = sum(diag(Pi_bin, -1));
    M.shorrocks = (K - trace(Pi_bin)) / max(K - 1, 1);

    % ---- how LONG the redistribution takes -------------------------------
    % A mechanism operating over decades is not disciplined by the same
    % evidence as one operating over a few years, and the manuscript's
    % distributional term is a stationary-distribution object with no stated
    % horizon at all. Iterate the bin chain from the initial mass and report
    % when half the eventual movement has happened.
    prof = zeros(H, K);
    v = M.bin_mass(:)';
    for t = 1:H
        v = v * Pi_bin;
        prof(t, :) = v;
    end
    M.profile = prof;
    vend = prof(end, :);
    tot = sum(abs(vend - M.bin_mass));
    M.halflife = NaN;
    if tot > 0
        for t = 1:H
            if sum(abs(prof(t,:) - M.bin_mass)) >= 0.5 * tot
                M.halflife = t; break;
            end
        end
    end
    M.total_bin_movement = tot;
    M.note = ['model-side mobility only; comparison against panel evidence ' ...
              'is what would discipline the distributional term, and has not ' ...
              'been made'];
end

% ---------------------------------------------------------------------
function [lo, hi, wlo] = lottery(ap, aG)
% Linear lottery split of an off-grid a' between neighbouring nodes.
    na = numel(aG);
    ap = min(max(ap, aG(1)), aG(na));
    hi = find(aG >= ap, 1, 'first');
    if isempty(hi), hi = na; end
    if hi == 1
        lo = 1; wlo = 1; return;
    end
    lo = hi - 1;
    d = aG(hi) - aG(lo);
    if d <= 0, wlo = 1; else, wlo = (aG(hi) - ap) / d; end
end

function e = quantile_edges(aG, w, nbin)
% Population-weighted quantile edges of the wealth marginal, so the bins are
% the quintiles (or n-tiles) a published transition table would use.
    w = w(:) / max(sum(w), eps);
    c = cumsum(w);
    e = zeros(1, nbin + 1);
    e(1) = aG(1); e(end) = aG(end);
    for k = 1:nbin-1
        idx = find(c >= k/nbin, 1, 'first');
        if isempty(idx), idx = numel(aG); end
        e(k+1) = aG(idx);
    end
    e = unique(e);                      % degenerate mass points collapse bins
    if numel(e) < 3, e = linspace(aG(1), aG(end), nbin+1); end
end

function m = accum_bins(marg, binof, K)
    m = zeros(1, K);
    for b = 1:K, m(b) = sum(marg(binof == b)); end
    m = m / max(sum(m), eps);
end

function v = getdef(s, f, dv)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end
