/*
 * GREEN_RANK_NK.MOD -- transition-dynamics tier (roadmap U6).
 *
 * STATUS: IMPLEMENTED at the RANK tier (run pending on the user's machine).
 *
 * WHAT THIS IS: a representative-agent New Keynesian economy with Rotemberg
 * pricing, real government debt with a debt-stabilizing tax rule, public
 * green (abatement) capital, a carbon stock, TFP damages, and FOUR monetary
 * regimes selected by macro-defines. It produces perfect-foresight
 * TRANSITION PATHS for a permanent deficit-financed green-investment
 * program -- the tier-1 answer to referee risk R1 ("only steady state").
 *
 * WHAT THIS IS NOT: the paper's price-level mechanism. The DTPL requires
 * incomplete markets; in RANK, inflation dynamics come from the Taylor rule
 * + Phillips curve. The HANK transition is specified in
 * appendix/HANK_TRANSITION_PLAN.md and is NOT YET IMPLEMENTED.
 *
 * MONETARY REGIMES (set by run_green_transitions.m via -D defines):
 *   PEG          : RHOI=0.999, PHIPI=0   (near-frozen nominal rate)
 *   TAYLOR       : RHOI=0.8,   PHIPI=1.5 (standard inertial Taylor)
 *   AGGRESSIVE   : RHOI=0.0,   PHIPI=3.0 (strict inflation targeting)
 *   GREENACCOM   : TAYLOR + PSIG=0.5     (temporary accommodation tied to
 *                  the green-capital gap: i is cut while kg is below its
 *                  terminal level, fading automatically as the transition
 *                  completes)
 *
 * USAGE:  dynare green_rank_nk                              (Taylor default)
 *         dynare green_rank_nk -DPHIPI=3.0 -DRHOI=0.0       (aggressive IT)
 * or run all four via run_green_transitions.m.
 *
 * Steady states are computed exactly by green_rank_nk_steadystate.m for any
 * program size, so initval/endval never rely on hand guesses.
 */

@#ifndef PHIPI
  @#define PHIPI = 1.5
@#endif
@#ifndef RHOI
  @#define RHOI = 0.8
@#endif
@#ifndef PSIG
  @#define PSIG = 0.0
@#endif
@#ifndef GSIZE
  @#define GSIZE = 0.015
@#endif

var c        // consumption
    y        // output
    n        // labor
    w        // real wage
    ppi      // net inflation
    i        // net nominal rate
    mc       // real marginal cost
    b        // real government debt (end of period)
    tau      // lump-sum tax (transparent benchmark instrument)
    gg       // real green public investment
    kg       // green public capital
    x        // carbon stock
    d;       // damage factor on TFP

varexo e_g;  // green-investment program (permanent via endval)

parameters beta sigma phi_n eps_p kappa_r
           phi_pi rho_i psi_g
           delta_g theta_g alpha_A eps0 delta_x gamma_x Dmax
           phi_b bbar ggbar;

beta    = 0.99;    // quarterly
sigma   = 2;
phi_n   = 1;
eps_p   = 6;
kappa_r = 100;     // Rotemberg adjustment cost
phi_pi  = @{PHIPI};
rho_i   = @{RHOI};
psi_g   = @{PSIG};
delta_g = 0.025;   // quarterly
theta_g = 1.2;
alpha_A = 0.9;
eps0    = 0.25;    // quarterly emissions scale
delta_x = 0.0125;
gamma_x = 0.028;
Dmax    = 0.25;
phi_b   = 0.10;    // debt-stabilizing tax response
bbar    = 1.0;
ggbar   = 0.0;

model;
  // Euler equation
  c^(-sigma) = beta*(1+i)/(1+ppi(+1)) * c(+1)^(-sigma);

  // labor supply
  n^phi_n = w * c^(-sigma);

  // production with TFP damages
  y = (1-d) * n;

  // marginal cost
  mc = w / (1-d);

  // Rotemberg Phillips curve
  (ppi)*(1+ppi) = beta*( (c(+1)/c)^(-sigma) * (ppi(+1))*(1+ppi(+1)) * y(+1)/y )
                  + eps_p/kappa_r * ( mc - (eps_p-1)/eps_p );

  // resource constraint (price-adjustment cost in output units)
  y = c + gg + (kappa_r/2)*ppi^2 * y;

  // green public capital
  kg = (1-delta_g)*kg(-1) + gg;

  // carbon stock: emissions net of abatement
  x = (1-delta_x)*x(-1) + eps0*(1 - alpha_A*(1-exp(-theta_g*kg(-1))))*y;

  // damages
  d = Dmax*(1-exp(-gamma_x*x(-1)));

  // government budget (real debt) + tax rule
  b = (1+i(-1))/(1+ppi)*b(-1) + gg - tau;
  tau = phi_b*(b(-1)-bbar) + gg + (1/beta-1)*bbar;

  // monetary rule: inertial Taylor + temporary green accommodation tied to
  // the green-capital gap (fades as kg -> terminal steady state)
  i = rho_i*i(-1) + (1-rho_i)*( (1/beta-1) + phi_pi*ppi
        - psi_g*(steady_state(kg) - kg) );

  // program
  gg = ggbar + e_g;
end;

initval;
  e_g = 0;
end;
steady;
check;

endval;
  e_g = @{GSIZE};
end;
steady;

perfect_foresight_setup(periods=300);
perfect_foresight_solver;

rplot y;
rplot ppi;
rplot b;
rplot kg;
rplot d;
