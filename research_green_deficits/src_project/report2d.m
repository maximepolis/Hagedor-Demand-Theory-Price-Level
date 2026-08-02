function report2d(t0, it, x, eqx, r, lb_max)
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
    if isempty(eqx), return; end
    W = eqx.Sb + eqx.q * eqx.Kbar;
    fprintf(['[%5.0fs] 2D %2d: beta=%.5f chi=%.5f | W=%.3f omega=%.3f ' ...
             'S_b=%.4f q=%.3f | rW=%+.4f rom=%+.4f\n'], ...
            toc(t0), it, exp(min(x(1), lb_max)), exp(x(2)), W, ...
            eqx.Sb/max(W,1e-12), eqx.Sb, eqx.q, r(1), r(2));
end

