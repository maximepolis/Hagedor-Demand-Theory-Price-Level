/*
 * GREEN_HANK.MOD -- HANK transition tier (roadmap U7, tier 1).
 *
 * STATUS: IMPLEMENTED (native Dynare heterogeneity framework); run pending
 * on the user's machine (requires the Dynare version shipping
 * heterogeneity_dimension / heterogeneity_solve -- the same version that
 * successfully ran heterogeneity/hank_one_asset_steady_state.mod, per the
 * log in that folder).
 *
 * WHAT THIS IS: a one-asset HANK (heterogeneous households, borrowing
 * constraint, idiosyncratic efficiency) with Rotemberg-style NK pricing, a
 * nominal policy rate + ex-post Fisher equation (so SURPRISE INFLATION
 * REVALUES household asset positions -- the paper's redistribution channel,
 * here linearized), government debt with a slow debt-stabilizing tax rule
 * (deficit financing on impact), and the project's climate block: green
 * public capital kg, carbon stock x, TFP damages d. It computes LINEARIZED
 * sequence-space IRFs to a QUASI-PERMANENT (rho_g = 0.995) deficit-financed
 * green-investment shock.
 *
 * WHAT THIS IS NOT: the paper's nonlinear DTPL price-level transition
 * (P* pinned by asset demand). In this NK-HANK, inflation dynamics come
 * from the Phillips curve + policy rule; the nonlinear P* transition
 * remains specified in appendix/HANK_TRANSITION_PLAN.md (tier 2, NOT YET
 * IMPLEMENTED). Magnitudes are illustrative: the income process
 * (rho_e, sig_e) follows the Dynare example, not yet the MATLAB package's
 * calibration.
 *
 * STRUCTURE: household block and numerical settings follow
 * heterogeneity/hank_one_asset_steady_state.mod (verified to run);
 * the climate block and policy rules follow green_rank_nk.mod, so the
 * RANK (U6) and HANK (U7) tiers are directly comparable.
 *
 * MONETARY REGIMES (set by run_green_hank.m via -D defines):
 *   WEAK        : PHIPI=1.1             (weakly active rule)
 *   TAYLOR      : PHIPI=1.5             (default)
 *   AGGRESSIVE  : PHIPI=3.0
 *   GREENACCOM  : PHIPI=1.5, PSIG=0.03  (temporary accommodation tied to
 *                 the program flow gg, fading as the program does; with a
 *                 gg impact of ~0.009 this is a SMALL accommodation,
 *                 ~2.7e-4 quarterly = ~11bp annualized -- unlike the U6
 *                 RANK GREENACCOM, which keys off the much larger kg gap)
 */

@#ifndef PHIPI
  @#define PHIPI = 1.5
@#endif
@#ifndef PSIG
  @#define PSIG = 0.0
@#endif

// Declare heterogeneity dimension
heterogeneity_dimension households;

// Household-level variables
var(heterogeneity=households)
   c      (long_name = 'consumption')
   n      (long_name = 'labor supply')
   ns     (long_name = 'effective labor supply')
   a      (long_name = 'assets')
;

// Household-level shocks
varexo(heterogeneity=households)
   e      (long_name = 'idiosyncratic efficiency')
;

// Aggregate variables
var
   Y    (long_name = 'output')
   L    (long_name = 'labor')
   w    (long_name = 'real wage')
   pi   (long_name = 'inflation')
   i    (long_name = 'net nominal policy rate')
   r    (long_name = 'ex-post real return on nominal assets')
   Div  (long_name = 'dividends')
   tau  (long_name = 'lump-sum tax (per efficiency unit)')
   b    (long_name = 'real government debt')
   gg   (long_name = 'green public investment')
   kg   (long_name = 'green public capital')
   x    (long_name = 'carbon stock')
   d    (long_name = 'TFP damage factor')
;

// Aggregate shocks
varexo e_g;

// Parameters
parameters
   beta vphi
   eis frisch
   mu kappa phi psig
   rho_g phi_b
   delta_g theta_g alpha_A eps0 delta_x gamma_x Dmax
   Z B r_ss
;

Z       = 1;
eis     = 0.5;
frisch  = 0.5;
kappa   = 0.1;
mu      = 1.2;
phi     = @{PHIPI};
psig    = @{PSIG};
r_ss    = 0.005;
rho_g   = 0.995;   // quasi-permanent program (half-life ~ 35 years)
phi_b   = 0.10;    // slow debt-stabilizing tax response => deficit financing on impact
// climate block: identical to green_rank_nk.mod (U6), quarterly
delta_g = 0.025;
theta_g = 1.2;
alpha_A = 0.9;
eps0    = 0.25;
delta_x = 0.0125;
gamma_x = 0.028;
Dmax    = 0.25;
// debt level: targets debt/ANNUAL GDP = 1.10 (U3 calibration) at the
// steady state with climate damages, where Y_ss ~ 0.90 (see verbatim block)
B       = 3.96;

verbatim;
% steady-state fixed point over damages (same logic as
% green_rank_nk_steadystate.m): Y = (1-d)*L with L ~ 1,
% x = eps0*Y/delta_x, d = Dmax*(1-exp(-gamma_x*x))
d = 0.10;
for it = 1:500
    Yv = (1 - d);
    xv = 0.25*Yv/0.0125;
    dn = 0.25*(1 - exp(-0.028*xv));
    if abs(dn - d) < 1e-12, d = dn; break; end
    d = dn;
end
Yv = 1 - d;
xv = 0.25*Yv/0.0125;
w   = (1 - d)/1.2;          % NKPC steady state: real mc = 1/mu
Div = Yv - w*1;             % L guess = 1
tau = 0.005*3.96;           % r_ss*B

initial_guess = struct;
initial_guess.agg.Y   = Yv;
initial_guess.agg.L   = 1;
initial_guess.agg.w   = w;
initial_guess.agg.pi  = 0;
initial_guess.agg.i   = 0.005;
initial_guess.agg.r   = 0.005;
initial_guess.agg.Div = Div;
initial_guess.agg.tau = tau;
initial_guess.agg.b   = 3.96;
initial_guess.agg.gg  = 0;
initial_guess.agg.kg  = 0;
initial_guess.agg.x   = xv;
initial_guess.agg.d   = d;

rho_e = 0.966;
sig_e = 0.5;
[grid_e, ~, Pi_e] = rouwenhorst(rho_e, sig_e, 3, 1e-12, 1e5);
initial_guess.shocks.grids.e = grid_e;
initial_guess.shocks.Pi.e = Pi_e;

grid_a = logspace(log10(0.25), log10(200.25), 30)-0.25;
initial_guess.pol.grids.a = grid_a;

T = (Div-tau)*grid_e;
coh = (1+0.005)*grid_a + w*grid_e + T;
c = 0.1*coh;
a = coh - c;
n = ones(size(a));
ns = n .* grid_e;

initial_guess.pol.values.c = c;
initial_guess.pol.values.a = a;
initial_guess.pol.values.n = n;
initial_guess.pol.values.ns = ns;

initial_guess.free_parameters.beta.initial_guess = 0.98;
initial_guess.free_parameters.beta.upper_bound = 0.999;
initial_guess.free_parameters.beta.lower_bound = 0;

initial_guess.free_parameters.vphi.initial_guess = 0.78;
initial_guess.free_parameters.vphi.lower_bound = 0.01;

initial_guess.pol.order = {'e', 'a'};
end;

// Household optimization problem (identical to the verified example)
model(heterogeneity=households);
   [name='Euler equation with borrowing constraint']
   c^(-1/eis) - beta * (1 + r(+1)) * c(+1)^(-1/eis) = 0 ⟂ a >= 0;

   [name='Budget constraint']
   (1 + r) * a(-1) + w * n * e + (Div-tau) * e - c - a;

   [name='Labor supply']
   vphi*n^(1/frisch) - w*e*c^(-1/eis);

   [name='Effective labor supply']
   ns = n * e;
end;

// Aggregate equilibrium conditions
model;
   [name='Labor demand']
   L - Y / ((1-d)*Z);

   [name='Dividends']
   Div - (Y - w * L - mu / (mu - 1) / (2 * kappa) * log(1 + pi)^2 * Y);

   [name='Nominal policy rule with green accommodation']
   i - (r_ss + phi * pi - psig * gg);

   [name='Fisher: ex-post real return on nominal assets']
   (1 + i(-1)) / (1 + pi) - 1 - r;

   [name='Government budget constraint']
   b - ((1 + r) * b(-1) + gg - tau);

   [name='Tax rule (slow: deficit-finances the program on impact)']
   tau - (r_ss * B + phi_b * (b(-1) - B));

   [name='New Keynesian Phillips curve']
   kappa * (w / ((1-d)*Z) - 1 / mu)
   + Y(+1)/Y * log(1 + pi(+1)) / (1 + r(+1))
   - log(1 + pi);

   [name='Green investment program (quasi-permanent AR)']
   gg - rho_g * gg(-1) - e_g;

   [name='Green capital accumulation']
   kg - (1-delta_g)*kg(-1) - gg;

   [name='Carbon stock']
   x - (1-delta_x)*x(-1) - eps0*(1 - alpha_A*(1-exp(-theta_g*kg(-1))))*Y;

   [name='Damages']
   d - Dmax*(1-exp(-gamma_x*x(-1)));

   [name='Asset market clearing']
   SUM(a) - b;

   [name='Labor market clearing']
   SUM(ns) - L;
end;

// Aggregate shock: 1% of steady-state output of green investment on impact
shocks;
    var e_g; stderr 0.009;
end;

//==========================================================================
// STEP 1: Steady state with parameter calibration (beta, vphi free)
//==========================================================================
heterogeneity_compute_steady_state(variable = initial_guess,
    calibration_target_equations=['Asset market clearing', 'Labor market clearing'],
    time_iteration_solver_stop_on_error);

//==========================================================================
// STEP 2: Linearized solution via sequence-space Jacobians
//==========================================================================
heterogeneity_solve(truncation_horizon = 300);

//==========================================================================
// STEP 3: IRFs to the quasi-permanent green-investment shock
//==========================================================================
heterogeneity_simulate(irf = 200);
