function dvd = kv_div_of(P, CTX)
% KV_DIV_OF  Intermediary pass-through: the fund holds (1-iota) of the stock
% and pays the coupon on it through as dividend.
    dvd = CTX.d_base + CTX.r_b * (1 - CTX.iota) * (CTX.Bnom / P) / CTX.Kbar;
end
