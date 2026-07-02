function [D, Kg] = climate_block(g_real, pg)
% CLIMATE_BLOCK  Steady-state climate damages from real green spending.
%
% EQUATIONS (MODEL_AND_THEORY.md, Section 1)
%   Kg = g_real / delta_g            (green capital maintained by investment)
%   D  = D0 * exp(-theta_g * Kg)     (damages decline in abatement capital)
%
% INPUTS
%   g_real : real green spending g_g = Gg/P (scalar or vector; g_real >= 0,
%            negative inputs are clamped to 0).
%   pg     : project params (uses D0, theta_g, delta_g).
%
% OUTPUTS
%   D  : damage factor in [0, D0], same size as g_real.
%   Kg : green capital, same size.
%
% Lemma 2: under a nominal budget, g_real = Gg/P is decreasing in P, so D(P)
% is increasing in P -- the climate-fiscal feedback loop.

    g  = max(g_real, 0);
    Kg = g ./ pg.delta_g;
    D  = pg.D0 .* exp(-pg.theta_g .* Kg);
end
