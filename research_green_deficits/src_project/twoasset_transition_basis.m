function [Phi, knots] = twoasset_transition_basis(T, mfree, nknot)
% TWOASSET_TRANSITION_BASIS  Basis for the free part of a transition price
% path: piecewise-linear interpolation on a geometrically spaced knot grid.
%
% WHY PROJECT AT ALL. Solved date by date, the unknown is 2(T-1) prices (238
% at T=120). A price at a distant date moves no market-clearing condition
% appreciably, so those Jacobian columns are ~0 in truth and pure NOISE under
% finite differences. The smallest singular value collapsed with the horizon
% (5.9e-05 at T=120) and the Newton stalled however it was damped: those
% directions are not identified from the residual.
%
% WHY THIS BASIS AND NOT DECAYING EXPONENTIALS. Two earlier attempts failed
% in an informative way. Pure exponentials fixed the conditioning but left
% the residual stuck at t = 1, 2 (a smooth decaying sum cannot represent the
% announcement jump). Adding free indicator columns on t = 1..8 raised
% sigma_min to 2.2e-02 and cut cond to 1.4e+03 -- well conditioned -- yet the
% residual STAYED at t = 1, 2 and the LM step went numerically to zero: the
% solver was sitting on the true least-squares minimum of the reduced
% problem. The diagnostic that settles it is that the residual is almost
% exactly PROPORTIONAL to the shock size (||r||/g = 0.33, 0.34, 0.33, 0.36
% across the four continuation steps). For a small shock the solution path is
% approximately g times the linear impulse response v, so a residual linear
% in g means v itself lies outside the span. That is an approximation error,
% not a solver failure, and the fix is a basis that can represent v.
%
% Indicators plus exponentials also have a representational cliff: dates
% 1..mfree are free, and from mfree+1 onward the path must be a sum of smooth
% decaying functions, with nothing in between. Piecewise-linear interpolation
% on a knot grid has no such gap. It resolves every date, at a resolution
% that is fine where the announcement dynamics live and coarse where the path
% is smooth and the residual cannot identify it anyway:
%
%   log X_t = log X_term + sum_j a_j H_j(t),
%
% with H_j the hat function that is one at knot j, zero at its neighbours,
% and linear between. The span is exactly the set of paths that are linear
% between knots, so K knots buy K degrees of freedom placed where they earn
% their keep. Knots are every date up to mfree, then geometrically spaced to
% the horizon; the raw hat matrix has condition number 2-4 at every horizon
% we solve, against ~3e+05 for the indicator-plus-exponential set.
%
% INPUTS  T     : horizon.
%         mfree : number of initial dates given their own knot (default 8).
%         nknot : target total number of knots (default 20).
% OUTPUT  Phi   : (T-1) x K orthonormal basis on t = 1..T-1. Orthonormalized
%                 because only the SPAN matters, and equal column scale keeps
%                 one finite-difference step appropriate for every direction.
%         knots : the knot dates, for reporting.

    if nargin < 2 || isempty(mfree), mfree = 8; end
    if nargin < 3 || isempty(nknot), nknot = 20; end

    n = T - 1;
    mfree = max(1, min(mfree, n));

    knots = 1:mfree;
    if n > mfree
        ntail = max(nknot - mfree, 2);
        tail  = round(exp(linspace(log(mfree + 1), log(n), ntail)));
        knots = [knots, tail];
    end
    knots = unique(min(max(round(knots), 1), n));
    K = numel(knots);

    t = (1:n).';
    H = zeros(n, K);
    for j = 1:K
        c  = knots(j);
        lo = knots(max(j - 1, 1));
        hi = knots(min(j + 1, K));
        if j > 1
            m = (t >= lo) & (t <= c);
            H(m, j) = (t(m) - lo) / max(c - lo, 1);
        end
        if j < K
            m = (t >= c) & (t <= hi);
            H(m, j) = (hi - t(m)) / max(hi - c, 1);
        end
        H(c, j) = 1;
    end
    % Flat continuation outside the knot range. With the rule above
    % knots(1)=1 and knots(K)=n, so these are no-ops; kept so the basis stays
    % well defined if the knot rule is ever changed.
    H(t < knots(1), 1) = 1;
    H(t > knots(K), K) = 1;

    Phi = orth(H);
end
