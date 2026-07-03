function M = debt_maturity_revaluation(P0, P1, r0, r1, g_real, nu_reval, nu_damage, grids)
% DEBT_MATURITY_REVALUATION  Maturity-, indexation- and holder-adjusted
% self-financing decomposition nu^M (roadmap U5; paper Section "Bounding the
% revaluation channel"). Pure arithmetic on saved equilibrium objects -- no
% household solves.
%
% HONEST STRUCTURE OF THE CHANNEL (the module's main point):
%  (1) LEVEL-JUMP EQUIVALENCE. In a steady-state comparison at unchanged
%      (i, mu), the price level jumps once (P0 -> P1) and inflation is mu in
%      both steady states. A one-time level jump revalues ALL nominal
%      promises proportionally, REGARDLESS of maturity: duration does not
%      shield or amplify a pure level shift. Maturity per se therefore does
%      NOT change nu_reval in the program experiment -- contrary to the
%      naive reading of the inflating-away literature.
%  (2) INDEXATION LEAKAGE. A share alpha_I of indexed (real) debt does not
%      revalue: the FISCAL revaluation scales by (1-alpha_I)
%      (Hilscher-Raviv-Reis limit #1).
%  (3) HOLDER COMPOSITION. A share alpha_F of nominal debt held abroad does
%      not change the fiscal gain, but reallocates the DOMESTIC incidence:
%      domestic-household revaluation scales by (1-alpha_I)(1-alpha_F)
%      (Doepke-Schneider limit #2). With green DISINFLATION (nu_reval < 0)
%      foreign holders absorb part of the windfall, so the domestic welfare
%      cost of the channel shrinks.
%  (4) DURATION MATTERS WHERE THE REAL RATE MOVES: in the accommodation
%      experiment (mu changes, r changes), legacy long bonds reprice. With
%      geometric-coupon debt (decay delta_m, price q = 1/(1+r-delta_m),
%      Macaulay duration ~ (1+r)/(1+r-delta_m)), the holding revaluation of
%      the legacy portfolio adds a duration term (Hall-Sargent accounting).
%
% INPUTS
%   P0, P1     : no-program and program price levels (program experiment).
%   r0, r1     : real rates before/after the ACCOMMODATION move (pass
%                r1 = r0 to switch the duration term off).
%   g_real     : real program cost per period (g_g at the program SS).
%   nu_reval   : baseline revaluation share (one-period nominal debt).
%   nu_damage  : damage-dividend share.
%   grids      : struct with .alpha_I (indexed shares), .alpha_F (foreign
%                shares), .delta_m (coupon-decay rates; 0 = one-period).
%
% OUTPUT
%   M : struct with
%       .fiscal    table over alpha_I: nu^M = (1-alpha_I)*nu_reval + nu_damage
%       .domestic  table over (alpha_I, alpha_F): domestic-incidence reval
%       .duration  table over delta_m: bond-price change q(r1)/q(r0)-1 and
%                  the implied legacy-portfolio revaluation per unit of
%                  market value (accommodation experiment)
%       .notes     the level-jump equivalence statement.

    aI = grids.alpha_I(:)';   aF = grids.alpha_F(:)';   dm = grids.delta_m(:)';

    % (2) fiscal nu^M over indexation share
    M.fiscal = struct('alpha_I', aI, ...
        'nu_reval_fiscal', (1 - aI) * nu_reval, ...
        'nu_M', (1 - aI) * nu_reval + nu_damage);

    % (3) domestic incidence over (alpha_I, alpha_F)
    dom = zeros(numel(aI), numel(aF));
    for i = 1:numel(aI)
        for j = 1:numel(aF)
            dom(i, j) = (1 - aI(i)) * (1 - aF(j)) * nu_reval;
        end
    end
    M.domestic = struct('alpha_I', aI, 'alpha_F', aF, 'nu_reval_domestic', dom);

    % (4) duration term (accommodation experiment): geometric-coupon price
    q0 = 1 ./ (1 + r0 - dm);
    q1 = 1 ./ (1 + r1 - dm);
    dur = (1 + r0) ./ (1 + r0 - dm);                 % Macaulay duration
    % real revaluation of the legacy portfolio per unit of initial real
    % market value: price effect x level-jump effect
    hold_reval = (q1 ./ q0) .* (P0 / P1) - 1;
    M.duration = struct('delta_m', dm, 'duration_years', dur, ...
        'q0', q0, 'q1', q1, 'price_change', q1./q0 - 1, ...
        'holding_revaluation', hold_reval);

    M.inputs = struct('P0',P0,'P1',P1,'r0',r0,'r1',r1,'g_real',g_real, ...
                      'nu_reval',nu_reval,'nu_damage',nu_damage);
    M.notes = ['Level-jump equivalence: in steady-state comparisons at ' ...
        'unchanged (i,mu), maturity does not alter the revaluation of a ' ...
        'one-time price-level jump; only indexation (fiscal leakage) and ' ...
        'holder composition (incidence reallocation) do. Duration matters ' ...
        'only where the real rate moves (accommodation experiments).'];

    % console table
    fprintf('\n[debt maturity / indexation / holders -- nu^M]\n');
    fprintf('  level-jump equivalence: maturity-neutral in the program experiment.\n');
    fprintf('  fiscal nu^M by indexed share:');
    fprintf('  aI=%.2f: %.3f |', [aI; M.fiscal.nu_M]);
    fprintf('\n  domestic reval at aI=%.2f: ', aI(min(2,numel(aI))));
    fprintf(' aF=%.2f: %+.3f |', [aF; dom(min(2,numel(aI)), :)]);
    fprintf('\n  duration (accommodation r %.4f -> %.4f):', r0, r1);
    fprintf('  dm=%.2f (%.1fy): hold-reval %+.3f |', [dm; dur; hold_reval]);
    fprintf('\n');
end
