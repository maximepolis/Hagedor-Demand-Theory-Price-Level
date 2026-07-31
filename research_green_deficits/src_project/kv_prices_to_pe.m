function pe = kv_prices_to_pe(alpha, CTX)
% KV_PRICES_TO_PE  Household-facing parameters at financing intensity alpha:
%   effective endowments scaled by damages and by the levy (1 - vartheta),
%   vartheta(alpha) = alpha * g / (1 - D), so alpha = 1 funds g entirely by
%   the levy and alpha = 0 entirely by the lump-sum tax.
%
% Lifted out of main_preferred_decomposition so parallel workers can call it:
% a parfor body cannot see a script's local functions.
    pe = CTX.p;
    vth = alpha * CTX.g_real / (1 - CTX.D0);
    pe.eGrid = (1 - CTX.D0) * (1 - vth) * CTX.p.eGrid;
end
