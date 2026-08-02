function x = kv_grid_build(lo, hi, g, n)
% KV_GRID_BUILD  Inverse of KV_GRID_CURV: x_j = lo + (hi-lo)*u_j^g.
    u = linspace(0, 1, n)';
    x = lo + (hi - lo) * (u.^g);
    x(1) = lo; x(end) = hi;                     % exact endpoints
end
