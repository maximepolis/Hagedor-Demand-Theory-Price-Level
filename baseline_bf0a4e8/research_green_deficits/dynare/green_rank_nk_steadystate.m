function [ys, params, check] = green_rank_nk_steadystate(ys, exo, M_, options_)
% GREEN_RANK_NK_STEADYSTATE  External steady-state file for green_rank_nk.mod
% (Dynare convention: <modname>_steadystate.m). Solves the steady state
% robustly for ANY value of the green-investment exogenous e_g, so both the
% initial (no-program) and terminal (program) steady states of the perfect-
% foresight experiment are computed exactly rather than guessed.
%
% STEADY-STATE SYSTEM (pibar = 0):
%   gg = ggbar + e_g;         kg = gg/delta_g;   A = 1-exp(-theta_g*kg)
%   fixed point over damages d:
%     given d: labor n solves  n^phi_n * c^sigma = mc*(1-d),
%              with mc = (eps_p-1)/eps_p and c = (1-d)*n - gg
%     then y = (1-d)*n;  X = eps0*(1-alpha_A*A)*y/delta_x;
%              d' = Dmax*(1-exp(-gamma_x*X))
%   i = 1/beta - 1;  ppi = 0;  b = bbar;  tau = gg + (1/beta-1)*bbar;
%   w = mc*(1-d).
%
% check = 1 signals failure to Dynare (never silently proceeds).

    check = 0;

    % ---- read parameters by name ----
    P = struct();
    for k = 1:M_.param_nbr
        P.(deblank(M_.param_names{k})) = M_.params(k);
    end
    params = M_.params;

    % ---- exogenous: e_g ----
    e_g = 0;
    for k = 1:M_.exo_nbr
        if strcmp(deblank(M_.exo_names{k}), 'e_g'), e_g = exo(k); end
    end

    gg = P.ggbar + e_g;
    kg = gg / P.delta_g;
    A  = 1 - exp(-P.theta_g * kg);
    mc = (P.eps_p - 1) / P.eps_p;

    % ---- fixed point over damages ----
    d = 0.05;
    n = 0.9;
    for it = 1:200
        % inner: labor supply/demand given d (bisection on n)
        f = @(nn) nn^P.phi_n * max((1-d)*nn - gg, 1e-9)^P.sigma - mc*(1-d);
        lo = max(gg/(1-d) + 1e-6, 1e-6); hi = 3;
        if f(lo) > 0 || f(hi) < 0, check = 1; return; end
        for bb = 1:80
            mid = 0.5*(lo+hi);
            if f(mid) < 0, lo = mid; else, hi = mid; end
        end
        n  = 0.5*(lo+hi);
        y  = (1-d)*n;
        X  = P.eps0 * (1 - P.alpha_A*A) * y / P.delta_x;
        dn = P.Dmax * (1 - exp(-P.gamma_x * X));
        if abs(dn - d) < 1e-12, d = dn; break; end
        d = 0.5*dn + 0.5*d;
    end

    y   = (1-d)*n;
    c   = y - gg;
    w   = mc*(1-d);
    i   = 1/P.beta - 1;
    ppi = 0;
    b   = P.bbar;
    tau = gg + (1/P.beta - 1)*P.bbar;
    X   = P.eps0 * (1 - P.alpha_A*A) * y / P.delta_x;

    if c <= 0 || ~isfinite(d), check = 1; return; end

    % ---- write ys by endogenous-variable name ----
    vals = struct('c',c,'y',y,'n',n,'w',w,'ppi',ppi,'i',i,'mc',mc, ...
                  'b',b,'tau',tau,'gg',gg,'kg',kg,'x',X,'d',d);
    ys = zeros(M_.endo_nbr, 1);
    for k = 1:M_.orig_endo_nbr
        nm = deblank(M_.endo_names{k});
        if isfield(vals, nm)
            ys(k) = vals.(nm);
        else
            check = 1; return;   % unknown variable: fail loudly
        end
    end
end
