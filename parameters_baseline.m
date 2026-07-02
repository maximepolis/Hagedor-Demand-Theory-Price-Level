function par = parameters_baseline()
% Baseline calibration + grids for the incomplete-markets / nominal-bond
% (FTPL) replication. Reduced-form fiscal block; swap in the paper's Eqs.

    % --- preferences / endowment ---
    par.beta  = 0.95;            % 1/beta - 1 = 0.0526 is the asymptote
    par.sigma = 2.0;
    par.w     = 1.0;
    par.amin  = 0.0;             % borrowing limit

    % --- asset (savings) grid: nonlinear, dense near constraint ---
    par.na    = 200;             % dev value; raise to 300 for final run
    par.amax  = 50;
    par.agrid = par.amin + (par.amax - par.amin) * (linspace(0,1,par.na)'.^3);

    % --- idiosyncratic income: AR(1) via Rouwenhorst ---
    par.ne      = 7;
    par.rho     = 0.90;
    par.sig_eps = 0.20;
    [eg, Pi]    = rouwenhorst(par.ne, par.rho, par.sig_eps);
    eg          = exp(eg);
    pst         = stat_dist(Pi);
    eg          = eg / (pst(:)' * eg(:));     % normalize E[e] = 1
    par.egrid   = eg(:)';
    par.Pi      = Pi;

    % --- EGM controls ---
    par.egm_tol   = 1e-6;
    par.egm_maxit = 2000;

    % --- STEP 1: real-rate sweep grid stops short of the 1/beta asymptote ---
    par.r_floor_betaR = 0.985;                       % max allowed beta*(1+r)
    r_max_safe        = par.r_floor_betaR/par.beta - 1.0;
    par.r_max         = min(0.030, r_max_safe);      % stay computable
    par.r_min         = -0.030;
    par.nr            = 25;

    % --- reduced-form FTPL / fiscal block (replace with paper Eqs. 34-38) ---
    % Steady-state gross real return implied by the tax rule:
    %   R(P) = 1 + gamma + taustar * (P / B)
    par.B            = 1.0;        % nominal debt (normalized)
    par.taustar_base = 0.0;
    par.gamma_base   = 0.01;

    % --- price-level scan window (STEP 5) ---
    par.P_min  = 0.05;
    par.P_max  = 3.00;
    par.nscan  = 600;

    % --- Figure 5 (STEP 4) ---
    par.fig5_datafile = 'gov_inflation_data.csv';  % columns: country,year,cpi_growth,gexp_growth
    par.fig5_y0       = 1960;     % <-- set to the paper's Section-4 window
    par.fig5_y1       = 2017;
    par.fig5_mincov   = 0.90;     % require >=90% year coverage per country
end