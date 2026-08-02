function ij = bracket_finite(fq)
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
% First sign change between CONSECUTIVE FINITE entries of the q-scan,
% BRIDGING any NaN gap between them. The previous test demanded that the
% sign-change pair be grid-ADJACENT, so a single failed q in the middle of
% an otherwise good scan destroyed a bracket that plainly existed (e.g.
% Sk-K running from +57 down to -0.97 with two NaNs in between). Returns
% [i1 i2] with i1 < i2, or [] if the finite points never change sign.
    ij = [];
    fi = find(isfinite(fq));
    for jj = 1:numel(fi)-1
        if sign(fq(fi(jj))) ~= sign(fq(fi(jj+1)))
            ij = [fi(jj), fi(jj+1)];
            return;
        end
    end
end

