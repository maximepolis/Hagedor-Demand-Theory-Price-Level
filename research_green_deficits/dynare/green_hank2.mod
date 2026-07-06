/*
 * GREEN_HANK2.MOD -- U7 tier 1b: TWO-ASSET green HANK (extended tier).
 *
 * ACCURACY STATUS: the first TWO runs are NOT REPORTABLE. Run 1
 * (rho_g=0.995, horizon 300): oscillatory IRFs + crash. Run 2: TAYLORBAL
 * returned an EXPLOSIVE pseudo-solution. ROOT CAUSE (adversarial audit,
 * confirmed): the dividend identity div = Y - wN - I - psip had been
 * dropped in the adaptation from hank_two_assets.mod, leaving div
 * residually defined by equity pricing (which then collapses ra = r
 * identically and unanchors the equity price), while the liquid-market
 * quantity constraint had no clearing price. BOTH fixed in this version:
 * the identity is restored and the liquidity premium omega is now an
 * ENDOGENOUS convenience yield clearing the liquid-bond market. No
 * tier-1b number enters the paper until the accuracy protocol passes.
 *
 * STATUS: IMPLEMENTED; run pending on the user's machine (requires the
 * same Dynare heterogeneity build that ran heterogeneity/hank_two_assets_
 * steady_state.mod -- this file follows that verified example closely).
 *
 * WHY A TWO-ASSET TIER: the paper's mechanism is about the demand for
 * LIQUID NOMINAL SAFE ASSETS specifically. In the one-asset tier
 * (green_hank.mod) all wealth is government bonds, so "asset demand" and
 * "bond demand" are indistinguishable. Here households hold liquid bonds
 * AND illiquid equity/capital with convex portfolio-adjustment costs
 * (Kaplan-Moll-Violante / Auclert-Bardoczy-Rognlie-Straub structure): the
 * green program's effect on the demand for the liquid nominal asset is
 * now a separate, observable object, wealthy hand-to-mouth households
 * exist, and MPC heterogeneity is realistic rather than proxied.
 *
 * WHAT IT ADDS RELATIVE TO green_hank.mod:
 *   - liquid bonds b vs illiquid equity a (chi0/chi1/chi2 adjustment costs)
 *   - production with CAPITAL, investment, Tobin Q, equity pricing
 *   - sticky WAGES (wage Phillips curve) in addition to sticky prices
 *   - ENDOGENOUS government debt bg with a financing-speed tax rule
 *     (PHIB define: 0.10 deficit-financed / 0.75 near-balanced)
 *   - ENDOGENOUS liquidity premium omega_t (convenience yield) clearing
 *     the liquid-bond market -- the green program's effect on the
 *     convenience yield of nominal safe assets is a plotted object
 *   - climate block on TFP: Y = (1-d) Z K^alpha N^(1-alpha), green public
 *     capital kg lowers emissions, carbon stock x drives damages d
 *   - liquid-bond supply is a fixed share lamB of government debt, so a
 *     deficit-financed program CHANGES THE SUPPLY OF LIQUID SAFE ASSETS --
 *     the dynamic counterpart of the paper's B/P margin
 *
 * WHAT IT STILL IS NOT: linearized sequence-space IRFs -- NOT the
 * nonlinear DTPL price-level transition (tier 2, HANK_TRANSITION_PLAN.md).
 * Grids default to ne=3, nb=15, na=30 (raised from the example's 10x20
 * after the wobbly first run): still moderate; magnitudes are indicative
 * until the accuracy protocol passes. Income-process alignment with the MATLAB
 * package's 7-state process remains future work (NE/RHOE/SIGE defines
 * below make it a run flag, default = verified example values).
 *
 * MONETARY/FISCAL REGIMES (run_green_hank2.m):
 *   WEAK        PHIPI=1.1
 *   TAYLOR      PHIPI=1.5 (default)
 *   GREENACCOM  PHIPI=1.5, PSIG=0.03
 *   TAYLORBAL   PHIPI=1.5, PHIB=0.75  (balanced-financing comparator)
 */

@#ifndef PHIPI
  @#define PHIPI = 1.5
@#endif
@#ifndef PSIG
  @#define PSIG = 0.0
@#endif
@#ifndef PHIB
  @#define PHIB = 0.10
@#endif
@#ifndef NE
  @#define NE = 3
@#endif
@#ifndef RHOE
  @#define RHOE = 0.966
@#endif
@#ifndef SIGE
  @#define SIGE = 0.92
@#endif
// NUMERICAL-ACCURACY DEFINES (oscillation protocol; see hank2_accuracy):
// NB/NA size the liquid/illiquid grids (defaults = the verified example's
// COARSE values); THORIZON is the sequence-space truncation horizon.
// RHOG sets program persistence: the first run used 0.995 (half-life 138
// quarters), which sits too close to the 300-quarter truncation horizon
// -- a classic source of end-of-horizon reflection/oscillation artifacts
// in sequence-space solutions. Default now 0.98 (half-life ~34 quarters,
// still quasi-permanent over the 120-quarter plot window) with
// THORIZON=400; the accuracy pass re-solves at THORIZON=500 and refined
// grids and compares. Grid defaults raised to nb=15, na=30 after the
// first run's visible wobble (the example's 10x20 is too coarse for the
// kinked portfolio-adjustment policies).
@#ifndef NB
  @#define NB = 15
@#endif
@#ifndef NA
  @#define NA = 30
@#endif
@#ifndef THORIZON
  @#define THORIZON = 400
@#endif
@#ifndef RHOG
  @#define RHOG = 0.98
@#endif

// Declare heterogeneity dimension
heterogeneity_dimension households;

// Household-level variables (verbatim from the verified two-asset example)
var(heterogeneity=households)
   b   (long_name = 'liquid assets (bonds)')
   a   (long_name = 'illiquid assets (equity)')
   c   (long_name = 'consumption')
   Va  (long_name = 'derivative of value function w.r.t. a')
   Vb  (long_name = 'derivative of value function w.r.t. b')
   u   (long_name = 'effective labor')
;

varexo(heterogeneity=households)
   e   (long_name = 'idiosyncratic efficiency')
;

// Aggregate variables
var
    piw    (long_name = 'wage inflation')
    psiw   (long_name = 'wage adjustment cost')
    rb     (long_name = 'return on bonds (liquid)')
    ra     (long_name = 'return on equity (illiquid)')
    tax    (long_name = 'tax rate on labor income')
    i      (long_name = 'nominal interest rate')
    psip   (long_name = 'price adjustment cost')
    I      (long_name = 'investment')
    Q      (long_name = 'Tobin Q')
    w      (long_name = 'real wage')
    N      (long_name = 'aggregate labor')
    K      (long_name = 'capital')
    div    (long_name = 'dividends')
    p      (long_name = 'equity price')
    pi     (long_name = 'inflation')
    mc     (long_name = 'marginal cost')
    r      (long_name = 'real interest rate')
    Y      (long_name = 'output')
    omega  (long_name = 'liquidity premium on nominal bonds (convenience yield)')
    bg     (long_name = 'government debt (real)')
    gg     (long_name = 'green public investment')
    kg     (long_name = 'green public capital')
    x      (long_name = 'carbon stock')
    d      (long_name = 'TFP damage factor')
;

// Aggregate shocks (e_g is the green program; the rest kept from the
// example for future experiments, zero variance here)
varexo
    e_g         (long_name = 'green-investment program shock')
    rstar       (long_name = 'monetary policy shock')
    markup      (long_name = 'price markup shock')
    markup_w    (long_name = 'wage markup shock')
    beta        (long_name = 'discount factor shock')
    Z           (long_name = 'productivity shock')
;

parameters
    kappap alpha epsI muw phi psig Bg lamB pshare delta
    kappaw frisch mup vphi eis
    chi0 chi1 chi2
    Z_ss beta_ss r_ss G_ss tax_ss wN_ss omega_ss
    rho_g phi_b
    delta_g theta_g alpha_A eps0 delta_x gamma_x Dmax
;

Bg = 2.8;
G_ss = 0.2;
chi0 = 0.25;
chi1 = 6.416;   // FIXED at the reference implementation's calibrated value:
                // with the liquid market clearing through the endogenous
                // premium omega_t, chi1 can no longer be a calibration target
chi2 = 2;
delta = 0.02;
eis = 0.5;
epsI = 4;
frisch = 1;
kappap = 0.1;
kappaw = 0.1;
muw = 1.1;
omega_ss = 0.005;  // initial guess for the ss convenience yield (now a VARIABLE:
                   // the liquid-bond market clears through omega_t, so the
                   // liquidity premium on nominal safe assets is an endogenous,
                   // plotted object -- the paper's convenience-yield channel)
phi  = @{PHIPI};
psig = @{PSIG};
r_ss = 0.0125;
rho_g = @{RHOG};
phi_b = @{PHIB};
lamB  = 1.04/2.8;   // liquid share of government debt (example: Bh/Bg)
// climate block: same parameters as the U6/U7 tiers (quarterly)
delta_g = 0.025;
theta_g = 1.2;
alpha_A = 0.9;
eps0    = 0.25;
delta_x = 0.0125;
gamma_x = 0.028;
Dmax    = 0.25;

verbatim;
% climate steady state with Y normalized to 1 (Z_ss absorbs damages):
% x_ss = eps0*Y/delta_x, d_ss = Dmax*(1-exp(-gamma_x*x_ss))
x_ss = 0.25*1/0.0125;
d_ss = 0.25*(1-exp(-0.028*x_ss));
tot_wealth = 14;
K_ss = 10;
p_ss = tot_wealth - Bg;
mc_ss = 1 - r_ss * (p_ss - K_ss);
end;

mup = 1 / mc_ss;
alpha = (r_ss + delta) * K_ss / mc_ss;
Z_ss = K_ss ^ (-alpha) / (1 - d_ss);   // normalization: (1-d_ss)*Z_ss*K^alpha*N^(1-alpha) = 1 at N=1
pshare = p_ss / (tot_wealth - lamB*Bg);
tax_ss = (r_ss * Bg + G_ss) / (mc_ss * (1 - alpha));
wN_ss  = mc_ss * (1 - alpha);   // steady-state wage bill (N_ss = 1)

verbatim;
w = mc_ss * (1 - alpha);
tax = (r_ss * Bg + G_ss) / w;
I = delta * K_ss;
div = 1 - w - I;
rb = r_ss - omega_ss;
ra = r_ss;

initial_guess = struct;
initial_guess.agg.piw = 0;
initial_guess.agg.psiw = 0;
initial_guess.agg.rb = rb;
initial_guess.agg.ra = ra;
initial_guess.agg.tax = tax;
initial_guess.agg.i = r_ss;
initial_guess.agg.psip = 0;
initial_guess.agg.I = I;
initial_guess.agg.Q = 1;
initial_guess.agg.w = w;
initial_guess.agg.N = 1;
initial_guess.agg.K = 10;
initial_guess.agg.div = div;
initial_guess.agg.p = 11.2;
initial_guess.agg.pi = 0;
initial_guess.agg.mc = mc_ss;
initial_guess.agg.r = r_ss;
initial_guess.agg.Y = 1;
initial_guess.agg.omega = omega_ss;
initial_guess.agg.bg = 2.8;
initial_guess.agg.gg = 0;
initial_guess.agg.kg = 0;
initial_guess.agg.x  = x_ss;
initial_guess.agg.d  = d_ss;

ne = @{NE};
rho_e = @{RHOE};
sig_e = @{SIGE};
[grid_e, ~, Pi_e] = rouwenhorst(rho_e, sig_e, ne, 1e-12, 1e5);
% guard against a shadowing LOG-grid rouwenhorst (see green_hank.mod)
assert(all(grid_e > 0) && any(abs(grid_e - 1) < 0.5), ...
    ['rouwenhorst returned a non-level grid -- the project src/rouwenhorst.m ' ...
     'is shadowing the Dynare heterogeneity framework version.']);
initial_guess.shocks.grids.e = grid_e;
initial_guess.shocks.Pi.e = Pi_e;

nb = @{NB};
na = @{NA};
a_max = 4000;
b_max = 50;
grid_a = logspace(log10(0.25), log10(a_max+0.25), na)-0.25;
grid_b = logspace(log10(0.25), log10(b_max+0.25), nb)-0.25;
initial_guess.pol.grids.a = grid_a;
initial_guess.pol.grids.b = grid_b;
initial_guess.pol.order = {'e', 'b', 'a'};

grid_a_3d = reshape(grid_a, 1, 1, []);
grid_b_3d = reshape(grid_b, 1, [], 1);
grid_e_3d = reshape(grid_e, [], 1, 1);
coh = (1+rb)*grid_b_3d+(1+ra)*grid_a_3d+(1-tax)*w*grid_e_3d;
b = grid_b_3d .* ones(ne, nb, na);
a = (1+ra) * grid_a_3d .* ones(ne, nb, na);
c = max(coh - a - b, 1e-8);
Vb = (1+rb) * (c .^ (-1/eis));
Va = (1+ra) * (c .^ (-1/eis));
u = grid_e_3d .* (c .^ (-1/eis));

initial_guess.pol.values.Va = Va;
initial_guess.pol.values.Vb = Vb;
initial_guess.pol.values.a = a;
initial_guess.pol.values.b = b;
initial_guess.pol.values.c = c;
initial_guess.pol.values.u = u;

initial_guess.free_parameters.beta_ss.initial_guess = 0.97;
initial_guess.free_parameters.beta_ss.lower_bound = 0.01;
initial_guess.free_parameters.beta_ss.upper_bound = 0.999;
initial_guess.free_parameters.vphi.initial_guess = 1.7;
initial_guess.free_parameters.vphi.lower_bound = 0.01;
end;

// Household optimization problem (verbatim from the verified example)
model(heterogeneity=households);
   [name='Euler equation for liquid assets']
   c^(-1/eis) - (beta_ss+beta) * Vb(+1) = 0 ⟂ b >= 0;

   [name='Euler equation for illiquid assets']
   c^(-1/eis)*(1 + chi1 * sign(a-(1+ra)*a(-1)) * (abs(a-(1+ra)*a(-1))/((1+ra)*a(-1)+chi0))^(chi2-1)) - (beta_ss+beta) * Va(+1) = 0 ⟂ a >= 0;

   [name='Budget constraint with adjustment costs']
   (1 + ra) * a(-1) + (1 + rb) * b(-1) - (chi1 / chi2) * abs(a-(1+ra)*a(-1))^chi2 * ((1+ra)*a(-1)+chi0)^(1-chi2) + (1-tax) * w * N * e - c - a - b;

   [name='Effective labor']
   u = e * c^(-1/eis);

   [name='Envelope condition for illiquid assets']
   Va = (1 + ra)*(1 - (chi1/chi2) * ( - chi2 * sign(a-(1+ra)*a(-1)) * (abs(a-(1+ra)*a(-1))/((1+ra)*a(-1)+chi0))^(chi2-1) + (1-chi2) * (abs(a-(1+ra)*a(-1))/((1+ra)*a(-1)+chi0))^chi2 )) * c^(-1/eis);

   [name='Envelope condition for liquid assets']
   Vb = (1 + rb) * c^(-1/eis);
end;

// Aggregate equilibrium conditions
model;
   [name='New Keynesian Phillips curve']
   kappap * (mc - 1 / mup) + Y(+1) / Y * log(1 + pi(+1)) / (1 + r(+1)) + markup - log(1 + pi);

   [name='Equity pricing']
   div(+1) + p(+1) - p * (1 + r(+1));

   [name='Production function with TFP damages']
   N = (Y / ((Z_ss+Z)*(1-d)) / K(-1) ^ alpha) ^ (1 / (1 - alpha));

   [name='Labor demand']
   mc = w * N / (1 - alpha) / Y;

   [name='Tobin Q']
   (K / K(-1) - 1) / (delta * epsI) + 1 - Q;

   [name='Valuation equation']
   alpha * (Z_ss+Z(+1)) * (1-d(+1)) * (N(+1) / K) ^ (1 - alpha) * mc(+1) - (K(+1) / K -
   (1 - delta) + (K(+1) / K - 1) ^ 2 / (2 * delta * epsI)) + K(+1) / K * Q(+1) - (1 + r(+1)) * Q;

   [name='Price adjustment cost']
   mup / (mup - 1) / 2 / kappap * log(1 + pi) ^ 2 * Y - psip;

   [name='Dividends']
   // the firm flow identity div = Y - wN - I - psip (hank_two_assets.mod
   // l.160). DROPPING it -- as this file's first version did -- leaves div
   // residually defined by equity pricing, collapses ra to r identically,
   // unanchors the equity price, and produced the first run's explosive
   // TAYLORBAL solution. psiw is deliberately NOT subtracted (utility-cost
   // convention of the reference implementation).
   Y - w * N - I - psip - div;

   [name='Capital accumulation']
   K - (1 - delta) * K(-1) + K(-1) * (K / K(-1) - 1) ^ 2 / (2 * delta * epsI) - I;

   [name='Taylor rule with green accommodation']
   rstar + r_ss + phi * pi - psig * gg - i;

   [name='Government budget constraint (dynamic)']
   bg - ((1 + r) * bg(-1) + G_ss + gg - tax * w * N);

   [name='Tax rule (financing speed phi_b)']
   // scaled by the STEADY-STATE wage bill for a clean lump-sum reading of
   // the debt correction. NOTE (audit): the denominator choice is
   // FIRST-ORDER IRRELEVANT (it multiplies a zero debt gap at the steady
   // state), so it was NOT the cause of the first run's TAYLORBAL
   // divergence -- the missing dividend identity was (see 'Dividends').
   tax - (tax_ss + phi_b * (bg(-1) - Bg) / wN_ss);

   [name='Return on liquid assets']
   // omega is ENDOGENOUS: the liquid-bond clearing condition determines the
   // convenience yield households pay for liquid nominal safe assets.
   // TIMING (NaN fix): the premium is set at ISSUANCE -- rb_t = r_t -
   // omega_{t-1} -- so omega_t directly prices the bonds households choose
   // at t (through the liquid Euler on rb_{t+1}) and can clear
   // lamB*bg_t = SUM(b_t). The first endogenous-omega version used
   // rb_t = r_t - omega_t, which gives date-t omega only an income effect
   // on predetermined holdings: a near-singular system whose linearized
   // solution came back NaN in all regimes. Steady state is unchanged.
   r - omega(-1) - rb;

   [name='Return on illiquid assets']
   pshare * (div + p) / p(-1) + (1 - pshare) * (1 + r) - 1 - ra;

   [name='Fisher equation']
   1 + i(-1) - (1 + r) * (1 + pi);

   [name='Wage inflation']
   (1 + pi) * w / w(-1) - 1 - piw;

   [name='Wage adjustment cost']
   // utility-cost convention of the reference example (muw/(1-muw) < 0);
   // psiw is INERT here (it feeds no other equation, in particular NOT the
   // resource/dividend identity above -- Rotemberg wage costs are a utility
   // loss, not a goods loss), so its sign does not affect any result. Kept
   // verbatim from the verified template rather than "corrected" to avoid
   // deviating from the steady-state-solving reference.
   muw / (1 - muw) / 2 / kappaw * log(1 + piw) ^ 2 * N - psiw;

   [name='Wage Phillips curve']
   kappaw * (vphi * N ^ (1 + 1 / frisch) - (1 - tax) * w * N * SUM(u) / muw) + (beta_ss+beta) * log(1 + piw(+1)) + markup_w - log(1 + piw);

   [name='Green investment program (quasi-permanent AR)']
   gg - rho_g * gg(-1) - e_g;

   [name='Green capital accumulation']
   kg - (1-delta_g)*kg(-1) - gg;

   [name='Carbon stock']
   x - (1-delta_x)*x(-1) - eps0*(1 - alpha_A*(1-exp(-theta_g*kg(-1))))*Y;

   [name='Damages']
   d - Dmax*(1-exp(-gamma_x*x(-1)));

   [name='Illiquid asset market clearing']
   p + bg - SUM(a) - SUM(b);

   [name='Liquid asset market clearing']
   lamB * bg - SUM(b);
end;

// Green program shock: ~1% of steady-state output, quasi-permanent
shocks;
    var e_g; stderr 0.01;
end;

//==========================================================================
// STEP 1: Steady state, calibrating (beta_ss, vphi, chi1) to clear the
// wage Phillips curve and both asset markets (as in the verified example)
//==========================================================================
heterogeneity_compute_steady_state(variable = initial_guess,
    calibration_target_equations=['Wage Phillips curve',
        'Illiquid asset market clearing'],
    time_iteration_tol=1e-10,
    time_iteration_max_iter=2000,
    time_iteration_early_stopping=0,
    time_iteration_solver_tolf=1e-12,
    time_iteration_solver_tolx=1e-14);

//==========================================================================
// STEP 2: Linearized solution via sequence-space Jacobians
//==========================================================================
heterogeneity_solve(truncation_horizon = @{THORIZON});

//==========================================================================
// STEP 3: IRFs to the green-investment shock
//==========================================================================
heterogeneity_simulate(irf = 200);
