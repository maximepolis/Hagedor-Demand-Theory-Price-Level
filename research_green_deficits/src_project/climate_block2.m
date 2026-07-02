function [D, Kg, X, E] = climate_block2(g_real, pg)
% CLIMATE_BLOCK2  Carbon-stock climate sector ("climate version 2", paper
% Section 3.2, Eq. (climate fixed point)). Steady state of:
%
%   Kg = g_real / delta_g                       (abatement capital)
%   A  = 1 - exp(-theta_g*Kg)                   (abatement share, in [0,1))
%   E  = eps0 * (1 - alpha_A*A) * (1 - D)       (emissions)
%   X  = E / delta_x                            (carbon stock)
%   D  = Dmax * (1 - exp(-gamma_x*X))           (damages)
%
% The last three equations define a fixed point in D; the map is continuous
% and DECREASING in D, so the fixed point exists and is unique (Lemma,
% "Climate block"). Solved by damped iteration from D = 0.
%
% INPUTS
%   g_real : real green spending (scalar or vector; clamped at 0).
%   pg     : project params (uses theta_g, delta_g, and version-2 fields
%            Dmax, eps0, delta_x, gamma_x, alpha_A).
%
% OUTPUTS
%   D  : damage factor in [0, Dmax), same size as g_real.
%   Kg : abatement capital.  X : carbon stock.  E : emissions.
%
% Backward compatibility: climate_block.m (version 1) remains the reduced
% form D = D0*exp(-theta_g*Kg).

    g  = max(g_real, 0);
    Kg = g ./ pg.delta_g;
    A  = 1 - exp(-pg.theta_g .* Kg);

    D = zeros(size(g));
    X = zeros(size(g));
    E = zeros(size(g));
    for k = 1:numel(g)
        Dk = 0;
        for it = 1:200
            Ek = pg.eps0 * (1 - pg.alpha_A * A(k)) * (1 - Dk);
            Xk = Ek / pg.delta_x;
            Dn = pg.Dmax * (1 - exp(-pg.gamma_x * Xk));
            if abs(Dn - Dk) < 1e-12, Dk = Dn; break; end
            Dk = 0.5*Dn + 0.5*Dk;          % damped (map is decreasing)
        end
        D(k) = Dk;
        E(k) = pg.eps0 * (1 - pg.alpha_A * A(k)) * (1 - Dk);
        X(k) = E(k) / pg.delta_x;
    end
end
