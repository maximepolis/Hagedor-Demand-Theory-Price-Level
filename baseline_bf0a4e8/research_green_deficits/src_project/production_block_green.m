function PB = production_block_green(g_g, pg)
% PRODUCTION_BLOCK_GREEN  Stage-1 production layer (editorial-roadmap Step
% 10): separates the OUTPUT/TAX-BASE channel from the avoided-damage
% dividend, which the endowment economy cannot distinguish (there the
% "output" effect IS the damage dividend).
%
%   Y = (1 - D(Kg)) * A(Kg) * N
%
%   D(Kg) : damages, from the existing climate block (version 1);
%   A(Kg) : green-public-capital productivity,
%           A = 1 + aY * (1 - exp(-thA * Kg)),
%           a reduced-form public-capital margin whose LOCAL slope maps to
%           the output elasticity of public capital (Bom-Ligthart 2014
%           meta-analysis: 0.08-0.12 for core infrastructure; we expose
%           eta_Y = dlnY/dlnKg at the benchmark so the calibration is
%           checkable, not asserted);
%   N     : labor, FIXED at N = 1 in Stage 1.
%
% HONEST SCOPE (labeled, not hidden):
%   * NO labor-supply margin yet: the tax-base channel is STYLIZED -- it
%     measures how much revenue existing tax rates raise on the LARGER
%     base, not behavioral responses. Stage 2 (clean/dirty CES, energy
%     input, Pigouvian margin, hours) is NOT YET IMPLEMENTED.
%   * This block is NOT yet joined to the HA household problem; it is the
%     aggregate layer used to SPLIT the decomposition channel
%       nu_damage  (endowment economy)  =  nu_damage + nu_taxbase
%     in the extended accounting below.
%
% INPUTS
%   g_g : real green investment flow (scalar or vector).
%   pg  : project params; uses climate fields + optional
%         pg.aY (default 0.20), pg.thA (default 0.8), pg.taxrate_base
%         (average effective tax take on output used for the tax-base
%         channel; default = tau/((1-D0)) is NOT assumed -- the caller
%         passes it explicitly via pg.taxbase_rate, default 0.30).
%
% OUTPUT struct PB (same length as g_g):
%   .Kg, .D, .A, .Y          production objects
%   .Y0, .D0                 no-program comparators (g=0)
%   .dY_damage               output gain from lower damages, at A(0)
%   .dY_product              output gain from the productivity margin, at D(g)
%   .dY_total                total output gain (= dY_damage + dY_product +
%                            interaction; interaction reported)
%   .dY_interact
%   .nu_taxbase              taxbase_rate * dY_total / g_g  (self-financing
%                            contribution of the larger base, stylized)
%   .eta_Y                   dlnY/dlnKg at each g (calibration diagnostic)
%
% STATUS: Stage 1 IMPLEMENTED (aggregate layer); Stage 2 and the HA join
% are NOT YET IMPLEMENTED.

    g_g = g_g(:)';
    aY  = 0.20; if isfield(pg,'aY')  && ~isempty(pg.aY),  aY  = pg.aY;  end
    thA = 0.8;  if isfield(pg,'thA') && ~isempty(pg.thA), thA = pg.thA; end
    trb = 0.30; if isfield(pg,'taxbase_rate') && ~isempty(pg.taxbase_rate)
        trb = pg.taxbase_rate;
    end

    qg = 1; if isfield(pg,'q_g') && ~isempty(pg.q_g), qg = pg.q_g; end
    Kg = qg * g_g / pg.delta_g;

    % damages from the existing climate block (version 1: D = D0*exp(-theta_g*Kg))
    D  = climate_block(g_g, pg);
    D0 = climate_block(0, pg);

    A  = 1 + aY * (1 - exp(-thA * Kg));
    A0 = 1;
    N  = 1;   % Stage 1: inelastic labor

    Y  = (1 - D)  .* A  * N;
    Y0 = (1 - D0) .* A0 * N;

    % channel split (exact accounting, interaction explicit)
    dY_damage  = ((1 - D) - (1 - D0)) .* A0 * N;   % damages move, A fixed
    dY_product = (1 - D0) .* (A - A0) * N;         % A moves, damages fixed
    dY_total   = Y - Y0;
    dY_interact = dY_total - dY_damage - dY_product;

    % stylized tax-base self-financing contribution
    nu_taxbase = trb * dY_total ./ max(g_g, eps);

    % local output elasticity of green public capital (calibration check)
    dY_dKg = (1 - D) .* aY .* thA .* exp(-thA * Kg) ...
             + pg.theta_g .* D0 .* exp(-pg.theta_g * Kg) .* A;  % via both margins
    eta_Y  = dY_dKg .* Kg ./ max(Y, eps);

    PB = struct('Kg',Kg, 'D',D, 'A',A, 'Y',Y, 'Y0',Y0, 'D0',D0, ...
        'dY_damage',dY_damage, 'dY_product',dY_product, ...
        'dY_total',dY_total, 'dY_interact',dY_interact, ...
        'nu_taxbase',nu_taxbase, 'eta_Y',eta_Y, ...
        'aY',aY, 'thA',thA, 'taxbase_rate',trb);
end
