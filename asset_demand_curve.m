function curve = asset_demand_curve(par)
% Aggregate savings S(R) swept over the trimmed real-rate grid.
% STEP 3: warm-starts consumption policy across adjacent rate nodes.

    Rgrid = 1 + linspace(par.r_min, par.r_max, par.nr);
    S    = nan(par.nr,1);
    emax = nan(par.nr,1);
    conv = false(par.nr,1);

    cprev = [];
    for ir = 1:par.nr
        [hh, d] = solve_household_problem(par, Rgrid(ir), cprev);
        cprev   = hh.cpol;                    % warm start
        if ~d.converged
            warning('rate node %d (R=%.4f, beta*R=%.4f): euler=%.2e, not fully converged', ...
                     ir, Rgrid(ir), par.beta*Rgrid(ir), d.euler_max);
        end
        dist    = stationary_distribution(par, hh.apol);
        S(ir)   = sum(sum(dist .* hh.apol));  % aggregate savings = E[a']
        emax(ir)= d.euler_max;
        conv(ir)= d.converged;
    end

    curve.R          = Rgrid(:);
    curve.S          = S;
    curve.euler_max  = emax;
    curve.converged  = conv;

    fprintf('Asset demand: valid pts = %d/%d, max Euler resid = %.2e\n', ...
            sum(conv), par.nr, max(emax));
end