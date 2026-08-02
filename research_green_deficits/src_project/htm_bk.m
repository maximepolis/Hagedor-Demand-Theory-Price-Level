function H = htm_bk(dist, bch, kch, q, htm_b, whtm_k)
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
    w = dist(:)/sum(dist(:)); bv = bch(:); kv = kch(:);
    isb = bv <= htm_b; isk = q*kv >= whtm_k;
    H = struct('htm',sum(w(isb)),'whtm',sum(w(isb & isk)),'phtm',sum(w(isb & ~isk)));
    wealth = bv + q*kv; [ws, io] = sort(wealth); wsr = w(io);
    cw = cumsum(wsr); tw = sum(ws.*wsr);
    H.top10 = sum(ws(cw>=0.90).*wsr(cw>=0.90))/tw;
    H.top1  = sum(ws(cw>=0.99).*wsr(cw>=0.99))/tw;
end

