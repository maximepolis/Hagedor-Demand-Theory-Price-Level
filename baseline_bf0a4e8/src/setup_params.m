function params = setup_params()
% SETUP_PARAMS  Baseline calibration and numerical settings for the
% replication of Hagedorn (2026), "A Demand Theory of the Price Level" (IER).
%
% OUTPUT
%   params : struct with all preference, income, grid, fiscal/monetary and
%            numerical fields used throughout the package. It also embeds the
%            discretized income process (eGrid, Pi, stationary_e) so that the
%            household and distribution solvers are self-contained.
%
% EQUATIONS / PAPER SECTIONS
%   Preferences        : E0 sum beta^t u(c),  u CRRA (Section 2.1).
%   Budget constraint  : c + a' = (1+r) a + e - tau,  a' >= -abar (Eq. budget).
%   Steady-state price : P* = Bnom / S(1+r^ss)                    (baseline).
%   Fisher             : 1+r^ss = (1+i^ss)/(1+pi^ss)              (Eq. Fisher).
%
% IMPORTANT (replicator's note): the paper is *theoretical*. The numbers below
% are a TRANSPARENT BENCHMARK chosen by the replicator, NOT a calibration
% supplied by the paper. See REPLICATION_NOTES.md, sections 3-4. Any object
% that is "exactly from the paper" is flagged as such in the module comments.

    % =====================================================================
    % Frequency
    % =====================================================================
    params.freq = 'annual';        % this benchmark is annual

    % =====================================================================
    % Preferences (Section 2.1)
    % =====================================================================
    params.beta  = 0.96;           % annual discount factor
    params.sigma = 2.0;            % CRRA coefficient (log if sigma==1)

    % =====================================================================
    % Borrowing limit and asset grid
    % =====================================================================
    params.abar  = 0.0;            % borrowing limit: a' >= -abar
    params.na    = 500;            % number of asset grid points (baseline)
    params.amax  = 60.0;           % upper bound of asset grid
    params.acurv = 2.5;            % curvature (>1 => dense near constraint)
    params.aGrid = make_asset_grid(-params.abar, params.amax, ...
                                    params.na, params.acurv);

    % =====================================================================
    % Idiosyncratic income process (Section 2.1): AR(1) in logs, Rouwenhorst,
    % normalized so mean endowment E[e] = 1.
    % =====================================================================
    params.ne      = 7;            % number of income states
    params.rho     = 0.90;         % persistence of log income
    params.sig_eps = 0.20;         % std of innovation to log income
    [eGrid, Pi, stationary_e] = make_income_process(params);
    params.eGrid        = eGrid;         % 1 x ne, mean 1
    params.Pi           = Pi;            % ne x ne, rows sum to 1
    params.stationary_e = stationary_e;  % ne x 1 invariant dist of income

    % =====================================================================
    % Monetary / fiscal baseline (illustrative policy choice)
    % =====================================================================
    params.Bnom  = 1.0;            % nominal government debt (normalized)
    params.i_ss  = 0.04;           % steady-state nominal interest rate
    params.pi_ss = 0.02;           % steady-state inflation = nominal debt growth
    % Implied baseline real rate r^ss = (1+i)/(1+pi)-1. Kept safely below
    % 1/beta-1 so that aggregate asset demand is finite (Eq. existence).

    % =====================================================================
    % Real-rate sweep grid (for asset-demand curves / figures). Stops short
    % of the 1/beta-1 asymptote where incomplete-markets asset demand diverges.
    % =====================================================================
    params.betaR_max = 0.999;                          % max allowed beta*(1+r)
    r_asymptote      = 1/params.beta - 1;              % 1/beta - 1
    params.r_max     = min(0.045, params.betaR_max/params.beta - 1);
    params.r_min     = -0.02;
    params.nr        = 30;                              % # points on r-sweep
    params.r_asymptote = r_asymptote;

    % =====================================================================
    % Numerical tolerances and iteration guards (exposed here on purpose)
    % =====================================================================
    params.tol_vfi    = 1e-8;      % sup-norm tol for value function iteration
    params.maxit_vfi  = 5000;      % VFI iteration guard
    params.tol_dist   = 1e-12;     % stationary distribution tol
    params.maxit_dist = 200000;    % distribution iteration guard
    params.tol_S      = 1e-8;      % outer tax/asset fixed-point tol
    params.maxit_S    = 400;       % outer fixed-point guard
    params.lambda_S   = 0.5;       % damping in the outer S-update
    params.tol_root   = 1e-8;      % scalar root-finding tol (price level)
    params.S_guess    = 2.0;       % initial guess for aggregate assets

    % =====================================================================
    % Household solver method selector
    % =====================================================================
    params.hh_method  = 'vfi';     % 'vfi' (canonical) or 'egm' (speed option)

    % =====================================================================
    % Price-level scan window (root finding over P for nonlinear rules)
    % =====================================================================
    params.P_min  = 0.05;
    params.P_max  = 20.0;
    params.nP     = 400;

    % =====================================================================
    % I/O
    % =====================================================================
    params.figdir   = fullfile('output','figures');
    params.tabdir   = fullfile('output','tables');
    params.logdir   = fullfile('output','logs');
    params.datadir  = 'data';
    params.fig5_csv = fullfile('data','oecd_inflation_govexp.csv');

    % Fast-testing convenience flag (main_run_all can flip na down to 100)
    params.na_fast  = 100;
end

% -------------------------------------------------------------------------
function g = make_asset_grid(amin, amax, n, curv)
% Nonlinear grid: uniform grid in [0,1] mapped through a curvature power so
% points concentrate near the borrowing constraint amin. curv=1 => linear.
    u = linspace(0, 1, n)';
    g = amin + (amax - amin) * (u.^curv);
    g = g(:);
    g(1)   = amin;         % pin endpoints exactly
    g(end) = amax;
end
