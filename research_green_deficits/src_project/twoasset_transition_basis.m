function Phi = twoasset_transition_basis(T, taus)
% TWOASSET_TRANSITION_BASIS  Decaying basis for the free part of a transition
% price path.
%
% WHY PROJECT. Solved date by date, the announcement path has 2(T-1) free
% prices: 238 of them at T=120. But a price at a distant date moves no
% market-clearing condition appreciably, so those Jacobian columns are ~0 in
% truth and pure NOISE under finite differences. The result is a Jacobian
% whose smallest singular value collapses with the horizon (5.9e-05 at
% T=120 against 8.8e-03 at T=40) and a Newton that stalls at a local
% minimum however it is damped. The free parameters are simply not
% identified from the residual.
%
% The paths themselves are smooth and decay monotonically to the terminal
% steady state, so a handful of decaying basis functions represents them to
% far better accuracy than the solver can resolve anyway:
%
%   log X_t = log X_term + sum_k a_k exp(-(t-1)/tau_k)
%
% This buys three things at once: the unknown falls from 2(T-1) to 2K, the
% least-squares problem becomes well conditioned because every retained
% direction genuinely moves the residual, and the Jacobian costs 2K solves
% instead of 2(T-1) (16 rather than 238 at T=120, with each column still an
% independent solve). Terminal convergence is automatic: every basis
% function has decayed by t=T, so the path meets the steady state without
% an imposed endpoint.
%
% INPUTS  T    : horizon.
%         taus : decay time-constants. Default spans fast to slow relative
%                to the horizon, so the fit can capture both the
%                announcement jump and the slow settling of the wealth
%                distribution.
% OUTPUT  Phi  : (T-1) x K basis evaluated on t = 1..T-1.

    if nargin < 2 || isempty(taus)
        taus = [1 2 4 8 16 32 64] * max(T/120, 1);
    end
    t   = (1:(T-1)).';
    Phi = exp(-(t - 1) ./ taus(:).');
end
