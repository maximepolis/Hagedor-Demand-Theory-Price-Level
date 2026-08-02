function tau = kv_tau_of(alpha, P, CTX)
% KV_TAU_OF  Lump-sum component: services the debt and the un-levied share of g.
    tau = CTX.r_b * (CTX.Bnom / P) + (1 - alpha) * CTX.g_real;
end
