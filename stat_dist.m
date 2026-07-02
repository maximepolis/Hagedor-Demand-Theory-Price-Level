function d = stat_dist(P)
% Stationary distribution of a row-stochastic matrix P.
    n = size(P,1);
    d = ones(n,1)/n;
    for it = 1:10000
        dn = P'*d;
        if max(abs(dn-d)) < 1e-14, d = dn; break; end
        d = dn;
    end
    d = d / sum(d);
end