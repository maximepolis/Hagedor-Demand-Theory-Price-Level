function pg = setup_params_green()
% SETUP_PARAMS_GREEN  Parameters for the research project "Can Green Deficits
% Finance Themselves?" -- extends the root replication package's benchmark
% (setup_params) with the climate block, the green program, and the grids used
% by the project experiments. See PROPOSAL.md and MODEL_AND_THEORY.md.
%
% OUTPUT
%   pg : struct = root params + project fields below.
%
% REQUIRES: the repository root's src/ on the MATLAB path (main_project_run_all
% adds it). All climate numbers are ILLUSTRATIVE calibrations chosen by the
% authors; none come from the four foundation papers.

    pg = setup_params();          % root benchmark (beta, sigma, grids, tols...)

    % ------------------------------------------------------------------
    % Project I/O: figures/tables/logs live inside the project folder
    % ------------------------------------------------------------------
    srcdir      = fileparts(mfilename('fullpath'));   % .../src_project
    projdir     = fileparts(srcdir);                  % .../research_green_deficits
    pg.projdir  = projdir;
    pg.figdir   = fullfile(projdir, 'output', 'figures');
    pg.tabdir   = fullfile(projdir, 'output', 'tables');
    pg.logdir   = fullfile(projdir, 'output', 'logs');

    % ------------------------------------------------------------------
    % Climate block:  D = D0 * exp(-theta_g * Kg),  Kg = g_g / delta_g
    % ------------------------------------------------------------------
    pg.D0      = 0.10;    % damages with zero abatement (10% of endowments)
    pg.theta_g = 1.20;    % abatement effectiveness (benchmark; swept below)
    pg.delta_g = 0.10;    % green-capital depreciation (annual)

    % Risk channel (Acharya-Challe-Dogra / Acharya-Benhabib ingredient):
    %   sig_eps(D) = sig_eps0 * (1 + phi_D * D). Set phi_D = 0 to switch off.
    pg.phi_D      = 0.50;
    pg.sig_eps0   = pg.sig_eps;    % root benchmark innovation s.d.

    % Damage-incidence gradient (paper Eq. "incidence"; Kaenzig 2023 / Fried-
    % Novan-Peterman evidence): y(e;D) = (1 - D*chi(e))*e with
    % chi(e) = e^(-psi)/E[e^(1-psi)]. psi_inc = 0 (default) = uniform damages,
    % preserving the original benchmark; the extended experiments sweep it.
    pg.psi_inc = 0;

    % ------------------------------------------------------------------
    % Climate version 2: carbon-stock sector (climate_block2)
    %   A = 1-exp(-theta_g*Kg); E = eps0*(1-alpha_A*A)*(1-D);
    %   X = E/delta_x;          D = Dmax*(1-exp(-gamma_x*X)).
    % Calibrated so no-abatement damages roughly match D0 = 0.10 above.
    % ------------------------------------------------------------------
    pg.climate_version = 1;       % 1 = reduced form; 2 = carbon stock
    pg.Dmax    = 0.25;
    pg.eps0    = 1.00;
    pg.delta_x = 0.05;
    pg.gamma_x = 0.028;
    pg.alpha_A = 0.90;

    % Extended-experiment settings (main_project_extended)
    pg.psi_sweep   = [0, 1, 2];   % incidence gradients for the sunspot probe
    pg.Gg_big      = 0.024;       % doubled program for the multiplicity search
    % Extended experiments are evaluated at an accommodative nominal-growth
    % stance near the welfare optimum mu* ~ 0.045: at mu = 0.02 the
    % incidence-amplified precautionary demand (S ~ 6) pushes P* so low that
    % the implied tax burden hits the lump-sum feasibility cliff and NO
    % stationary equilibrium exists -- itself a finding (fiscal-space
    % collapse), reported honestly, but not a useful benchmark to explore.
    pg.mu_ext      = 0.03;
    pg.green_csv   = fullfile(fileparts(srcdir), '..', 'data', ...
                              'green_budget_panel.csv');  % E2 data (optional)

    % ------------------------------------------------------------------
    % Green program and policy (nominal budget regime is the default)
    % ------------------------------------------------------------------
    % Nominal green budget. At the no-program price level (~0.26 with D0
    % damages) this targets real green spending g_g of roughly 5% of mean
    % endowment; the exact real size is an equilibrium outcome.
    pg.Gg_nom  = 0.012;
    pg.mu      = pg.pi_ss;        % nominal growth of B and Gg (=> pi_ss = mu)
    % i_ss, Bnom inherited from root params (0.04, 1.0)

    % ------------------------------------------------------------------
    % Experiment grids
    % ------------------------------------------------------------------
    % 2-D S(tau, D) interpolant nodes at the baseline real rate. tau_hi stays
    % clearly below the worst-case feasibility bound (1-D0)*e_min ~ 0.263.
    pg.taugrid_S = linspace(-0.05, 0.22, 7);
    pg.Dgrid_S   = linspace(0.0, pg.D0, 4);

    % Price-level scan for root finding (project-specific range)
    pg.P_scan_min = 0.05;
    pg.P_scan_max = 3.00;
    pg.nP_scan    = 240;

    % Damage-feedback sweep (Propositions 2-4 figures)
    pg.theta_sweep = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5];

    % Optimal-accommodation grid (Proposition 5). r(mu)=(1+i)/(1+mu)-1 must
    % stay inside the computable range; mu >= ~0.012 keeps beta(1+r) < 0.999.
    pg.mu_grid = [0.015, 0.02, 0.03, 0.045, 0.06, 0.08];

    % Reduced grids for the per-mu interpolants in optimal_policy_green
    pg.taugrid_mu = linspace(-0.02, 0.20, 5);
    pg.Dgrid_mu   = linspace(0.0, pg.D0, 3);

    % ------------------------------------------------------------------
    % FAST mode deltas (main_project_run_all applies them if FAST=true)
    % ------------------------------------------------------------------
    pg.fast.na          = pg.na_fast;   % 100 asset nodes
    pg.fast.taugrid_S   = linspace(-0.05, 0.22, 5);
    pg.fast.Dgrid_S     = linspace(0.0, pg.D0, 3);
    pg.fast.nP_scan     = 120;
    pg.fast.theta_sweep = [0.0, 1.2, 2.5];
    pg.fast.mu_grid     = [0.015, 0.03, 0.06];
end
