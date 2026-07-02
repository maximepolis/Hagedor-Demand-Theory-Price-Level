function [hh, diag] = solve_household_problem(par, R, cpol_init)
% EGM solver for the household savings problem at gross real return R.
% STEP 3: accepts optional warm-start cpol_init.
% STEP 2: convergence flag requires BOTH policy convergence AND Euler accuracy.

    na = par.na;  ne = par.ne;
    a  = par.agrid(:);          % na x 1  (also the savings/next-asset grid)
    e  = par.egrid(:)';         % 1  x ne
    Pi = par.Pi;                % ne x ne, Pi(i,j)=Prob(e'=j|e=i)
    beta = par.beta; sigma = par.sigma; w = par.w; amin = par.amin;

    if nargin < 3 || isempty(cpol_init)
        c = max(1e-6, (R-1)*a + w.*e);     % consume interest + labor income
    else
        c = cpol_init;
    end

    err = inf;
    for it = 1:par.egm_maxit
        mu_next = c.^(-sigma);             % na x ne, marginal utility at a'=a
        Emu     = mu_next * Pi';           % na x ne, E[mu(a',e')|e]
        c_endog = (beta*R*Emu).^(-1/sigma);
        a_today = (c_endog + a - w.*e)./R; % current assets implying a'=a

        apol = zeros(na,ne);
        for j = 1:ne
            [xq, iu] = unique(a_today(:,j));     % ensure monotone for interp1
            yq       = a(iu);
            ap       = interp1(xq, yq, a, 'linear', 'extrap');
            ap(a < a_today(1,j)) = amin;         % borrowing constraint binds
            apol(:,j) = min(max(ap, amin), a(end));
        end
        cpol = max(R.*a + w.*e - apol, 1e-10);

        err = max(abs(cpol(:) - c(:)));
        c   = cpol;
        if err < par.egm_tol, break; end
    end

    % --- Euler residual diagnostic (relative, unconstrained points) ---
    mu  = cpol.^(-sigma);
    res = zeros(na,ne);
    for j = 1:ne
        ap   = apol(:,j);
        EmuN = zeros(na,1);
        for jp = 1:ne
            cN   = max(interp1(a, cpol(:,jp), ap, 'linear', 'extrap'), 1e-10);
            EmuN = EmuN + Pi(j,jp) * cN.^(-sigma);
        end
        rhs    = beta*R*EmuN;
        unc    = apol(:,j) > amin + 1e-9;
        res(unc,j) = abs(1 - rhs(unc)./mu(unc,j));
    end

    diag.iter      = it;
    diag.err       = err;
    diag.euler_max = max(res(:));
    % STEP 2: honest convergence flag
    diag.converged = (err <= par.egm_tol) && (diag.euler_max < 10*par.egm_tol);

    hh.cpol = cpol;
    hh.apol = apol;
end