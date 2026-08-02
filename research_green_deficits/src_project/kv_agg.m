function [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, q, d, tau, pe)
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
    bG = pe.bGrid(:); kG = pe.kGrid(:);
    nb = numel(bG); nk = numel(kG); ne = numel(pe.eGrid);
    lam = pe.lambda_adj; Rb = 1 + rb; ynet = pe.eGrid(:)' - tau;
    bch = zeros(nb,nk,ne); kch = zeros(nb,nk,ne);
    for ie = 1:ne
        xbk = min(max(ynet(ie) + Rb*bG + (q+d)*kG', pe.xGridA(1)), pe.xGridA(end));
        bpa = interp1(pe.xGridA, sol.polBa(:,ie), xbk, 'linear');
        kpa = interp1(pe.xGridA, sol.polKa(:,ie), xbk, 'linear');
        % non-adjuster illiquid position: k, or the compounded k' when part
        % of the dividend is retained inside the illiquid account (phi < 1)
        knon = kG';
        if isfield(sol, 'kNon'), knon = sol.kNon(:)'; end
        bch(:,:,ie) = lam*bpa + (1-lam)*squeeze(sol.polBn(:,:,ie));
        kch(:,:,ie) = lam*kpa + (1-lam)*repmat(knon, nb, 1);
    end
    Sb = sum(bch(:).*dist(:)); Sk = sum(kch(:).*dist(:));
end

