function eqx = eval_own(rb, d, D, g, lv, Bnom, Kbar, iota, pp, q_ref)
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
    eqx = solve_own_kv(rb, d, D, g, lv, Bnom, Kbar, iota, pp, q_ref, false);
    if isstruct(eqx) && eqx.ok, eqx.Kbar = Kbar; end
end

