function [ks, bs, ko, bo] = kv_boundary_mass(dist, kG, bG)
% KV_BOUNDARY_MASS  Truncation diagnostics for a stationary distribution.
%
% ks, bs : share of mass in the top TWO nodes of the k- and b-grids. This is
%   the gate: mass at a ceiling cannot respond to prices, so it enters every
%   aggregate as a rigid constant.
%
% ko, bo : the highest OCCUPIED node as a fraction of the grid top. This
%   guards the gate against being passed by stretching rather than by
%   fixing. Widening a grid mechanically shrinks the top-two-node mass, so a
%   small ks on its own proves nothing; ks small AND ko well below 1 is a
%   distribution with interior support, while ks small and ko ~ 1 is a
%   distribution still leaning on the wall through a thinner slice of it.
    km = squeeze(sum(sum(dist,1),3)); km = km(:);
    bm = squeeze(sum(sum(dist,2),3)); bm = bm(:);
    ks = sum(km(max(1,end-1):end))/max(sum(km),eps);
    bs = sum(bm(max(1,end-1):end))/max(sum(bm),eps);
    ko = NaN; bo = NaN;
    if nargin >= 3
        ik = find(km > 1e-8, 1, 'last'); ib = find(bm > 1e-8, 1, 'last');
        if ~isempty(ik), ko = kG(ik)/kG(end); end
        if ~isempty(ib), bo = bG(ib)/bG(end); end
    end
end
