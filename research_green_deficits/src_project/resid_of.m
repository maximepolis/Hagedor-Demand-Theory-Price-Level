function [r, eqx] = resid_of(eqx, Wt, om_t)
% MOVED, NOT COPIED, round 10 (decision D10).
%
% This function was a local function of main_twoasset_ownership_kv.m. Track B
% of the two-asset certification protocol must recalibrate on every grid, and
% a local function cannot be called from anywhere else -- so the alternative
% was a second calibration implementation. That is exactly the defect this
% round exists to prevent: two implementations of one object drift, and the
% drift is silent because both "work".
%
% The body below is the original, moved verbatim. The calling script now calls
% this file. Any change here changes the paper's calibration.
    if isempty(eqx) || ~eqx.ok, r = [NaN; NaN]; eqx = []; return; end
    W  = eqx.Sb + eqx.q * eqx.Kbar;
    om = eqx.Sb / max(W, 1e-12);
    r  = [log(max(W,1e-12)) - log(Wt); log(max(om,1e-12)) - log(om_t)];
    if ~all(isfinite(r)), r = [NaN; NaN]; eqx = []; end
end

