function dist = stationary_distribution(par, apol)
% Young (2010) lottery on the asset grid. STEP 3: preallocated triplets.

    na = par.na; ne = par.ne; a = par.agrid(:); Pi = par.Pi;

    nnz_max = 2*na*ne*ne;
    rows = zeros(nnz_max,1); cols = zeros(nnz_max,1); vals = zeros(nnz_max,1);
    k = 0;

    for j = 1:ne
        [il, wl] = lottery(a, apol(:,j));   % lower index, weight on lower node
        for i = 1:na
            from = (j-1)*na + i;
            lo   = il(i);  hi = min(il(i)+1, na);  wL = wl(i);
            for jp = 1:ne
                p = Pi(j,jp);
                k = k+1; rows(k)=from; cols(k)=(jp-1)*na+lo; vals(k)=p*wL;
                k = k+1; rows(k)=from; cols(k)=(jp-1)*na+hi; vals(k)=p*(1-wL);
            end
        end
    end
    rows = rows(1:k); cols = cols(1:k); vals = vals(1:k);
    T = sparse(rows, cols, vals, na*ne, na*ne);   % row-stochastic

    d = ones(na*ne,1)/(na*ne);
    for it = 1:10000
        dn = T'*d;
        if max(abs(dn-d)) < 1e-13, d = dn; break; end
        d = dn;
    end
    dist = reshape(d/sum(d), na, ne);
end

function [il, wl] = lottery(a, ap)
    na  = numel(a);
    ap  = min(max(ap, a(1)), a(end));
    il  = discretize(ap, a);
    il(isnan(il)) = na-1;
    il  = min(il, na-1);
    wl  = (a(il+1) - ap) ./ (a(il+1) - a(il));
    wl  = min(max(wl, 0), 1);
end