/*
 * GREEN_RANK_NK.MOD -- transition-dynamics skeleton for the project
 * "Can Green Deficits Finance Themselves?"
 *
 * STATUS: PARTIALLY IMPLEMENTED (tier-1 of roadmap step U6).
 *
 * WHAT THIS IS: a representative-agent New Keynesian economy with Rotemberg
 * pricing, a Taylor rule, real government debt with a debt-stabilizing tax
 * rule, public green (abatement) capital, a carbon stock, and TFP damages.
 * It produces perfect-foresight TRANSITION PATHS for a deficit-financed
 * green-investment program: output, inflation, debt, green capital,
 * emissions, damages -- addressing referee risk R1 at the RANK tier.
 *
 * WHAT THIS IS NOT: the price-level determination mechanism of the paper.
 * The DTPL requires incomplete markets (a nondegenerate asset-demand
 * schedule); in this RANK block the price LEVEL is not pinned by asset
 * demand and inflation dynamics come from the Taylor rule + Phillips curve.
 * The HANK transition (sequence-space, roadmap U7) is NOT YET IMPLEMENTED.
 *
 * USAGE:  dynare green_rank_nk
 * (deterministic simulation of a permanent green-investment increase)
 */

var c        // consumption
    y        // output
    n        // labor
    w        // real wage
    ppi      // net inflation
    i        // net nominal rate
    mc       // real marginal cost
    b        // real government debt (end of period)
    tau      // lump-sum tax (benchmark instrument; see referee memo R3)
    gg       // real green public investment
    kg       // green public capital
    x        // carbon stock
    d;       // damage factor on TFP

varexo e_g;  // green-investment program shock (permanent via terminal value)

parameters beta sigma phi_n eps_p kappa_r
           phi_pi rho_i
           delta_g theta_g alpha_A eps0 delta_x gamma_x Dmax
           phi_b bbar ggbar;

beta    = 0.99;    // quarterly
sigma   = 2;
phi_n   = 1;
eps_p   = 6;
kappa_r = 100;     // Rotemberg adjustment cost
phi_pi  = 1.5;
rho_i   = 0.8;
delta_g = 0.025;   // quarterly
theta_g = 1.2;
alpha_A = 0.9;
eps0    = 0.25;    // quarterly emissions scale
delta_x = 0.0125;
gamma_x = 0.028;
Dmax    = 0.25;
phi_b   = 0.10;    // debt-stabilizing tax response
bbar    = 1.0;
ggbar   = 0.0;     // no program initially

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

  // Taylor rule (inertial)
  i = rho_i*i(-1) + (1-rho_i)*( (1/beta-1) + phi_pi*ppi );

  // program
  gg = ggbar + e_g;
end;

initval;
  ppi = 0; i = 1/beta-1; gg = 0; kg = 0;
  x  = eps0/delta_x*0.9;          // rough pre-program stock
  d  = Dmax*(1-exp(-gamma_x*eps0/delta_x*0.9));
  n  = 1; y = 1-d; c = y; w = (eps_p-1)/eps_p*(1-d);
  mc = (eps_p-1)/eps_p; b = bbar; tau = (1/beta-1)*bbar;
end;
steady;
check;

// permanent green program of 1.5% of output from period 1
endval;
  e_g = 0.015;
end;
steady;

perfect_foresight_setup(periods=300);
perfect_foresight_solver;

// paths of interest: y ppi b kg x d tau c
rplot y;
rplot ppi;
rplot b;
rplot kg;
rplot d;
