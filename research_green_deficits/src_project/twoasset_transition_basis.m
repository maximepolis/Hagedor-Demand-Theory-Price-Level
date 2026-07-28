function Phi = twoasset_transition_basis(T, taus, mfree)
% TWOASSET_TRANSITION_BASIS  Basis for the free part of a transition price
% path: free early dates plus decaying tail functions.
%
% WHY PROJECT AT ALL. Solved date by date, the unknown is 2(T-1) prices (238
% at T=120). A price at a distant date moves no market-clearing condition
% appreciably, so those Jacobian columns are ~0 in truth and pure NOISE under
% finite differences. The smallest singular value collapsed with the horizon
% (5.9e-05 at T=120), and the Newton stalled however it was damped: those
% directions are not identified from the residual.
%
% WHY THE BASIS NEEDS FREE EARLY DATES. A pure exponential basis fixed the
% conditioning (sigma_min 4.3e-03, terminal gap 1.4e-04) but left the system
% OVERDETERMINED: 238 equations in 14 unknowns cannot reach zero unless the
% true path lies in the span. The residual then concentrated, in every
% continuation step, at t = 1 and t = 2 -- precisely where the announcement
% produces a sharp jump that a sum of smooth decaying exponentials cannot
% represent. Giving the first mfree dates their own free coefficients adds
% exactly the flexibility the data ask for, where the economics lives, while
% the exponential tail keeps the far end identified.
%
%   log X_t = log X_term + sum_{j<=mfree} a_j 1{t=j}
%                        + sum_k b_k exp(-(t-1)/tau_k)
%
% The columns are orthonormalized before use: only the SPAN matters, and an
% orthonormal basis removes the near-collinearity between the early dummies
% and the exponentials (all of which equal one at t=1).
%
% INPUTS  T     : horizon.
%         taus  : decay time-constants for the tail (default spans fast to
%                 slow relative to the horizon).
%         mfree : number of initial dates left individually free (default 8).
% OUTPUT  Phi   : (T-1) x K orthonormal basis on t = 1..T-1.

    if nargin < 2 || isempty(taus)
        taus = [1 2 4 8 16 32 64] * max(T/120, 1);
    end
    if nargin < 3 || isempty(mfree), mfree = 8; end

    n = T - 1;
    mfree = min(mfree, n);
    t = (1:n).';

    E = exp(-(t - 1) ./ taus(:).');        % decaying tail
    D = zeros(n, mfree);                   % free announcement-window dates
    for j = 1:mfree, D(j, j) = 1; end

    Phi = orth([D, E]);                    % same span, orthonormal columns
end
