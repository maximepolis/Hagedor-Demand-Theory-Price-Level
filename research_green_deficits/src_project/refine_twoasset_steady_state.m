function S = refine_twoasset_steady_state(rb, d, g_real, Bnom, Kbar, pe, Pg, qg, tolS, verbose)
% REFINE_TWOASSET_STEADY_STATE  Re-solve a two-asset steady state to high
% accuracy using EXACTLY the household solver and forward operator that the
% transition residual uses.
%
% WHY THIS EXISTS. The transition pins its endpoints at the boundary steady
% states, so its market residual can never be smaller than the error in those
% endpoints. The Step 0 solver returns (P,q) accurate to its own bisection
% tolerance, roughly 1e-4 in the clearing conditions; feeding those to the
% transition put a floor of that size under every date's residual, which then
% swamped the finite-difference Jacobian and stalled the Newton solve. The
% floor is a property of the ENDPOINTS, not of the path solver: no amount of
% work on the path can beat the accuracy of what it is anchored to.
%
% Solving the same two conditions here, with the same operators, removes it:
%   bonds :  int b' dOmega = B / P
%   tree  :  int k' dOmega = Kbar
% in logs, by a damped 2-D Newton on (log P, log q).
%
% INPUTS  rb, d, g_real, Bnom, Kbar : prices/policy of the target steady state
%         pe   : parameters with the income grid ALREADY scaled for damages
%         Pg, qg : starting guesses (the Step 0 answer is a good one)
%         tolS : sup-norm target on the two log residuals (default 1e-11)
%         verbose : print the iteration trace (default false)
%
% OUTPUT  S : .P .q .tau .polB .polK .C .dist .Sb .Sk .resid .converged .iters

    if nargin < 9  || isempty(tolS),    tolS = 1e-11; end
    if nargin < 10 || isempty(verbose), verbose = false; end

    pe.tol_pol   = 1e-12;              % the endpoints must be far tighter than
    pe.maxit_pol = 4000;               % the path tolerance we are chasing

    x = [log(Pg); log(qg)];
    [r, S] = ss_resid(x);
    converged = false; it = 0;
    for it = 1:60
        if max(abs(r)) < tolS, converged = true; break; end
        h = 1e-6; J = zeros(2,2);
        for j = 1:2
            xp = x; xp(j) = xp(j) + h;
            rp = ss_resid(xp);
            J(:, j) = (rp - r)/h;
        end
        if rcond(J) < 1e-14, break; end
        dx = -(J \ r);
        % backtrack so a large early step cannot leave the feasible region
        acc = false; a = 1;
        for ls = 1:12
            [rt, St] = ss_resid(x + a*dx);
            if all(isfinite(rt)) && max(abs(rt)) < max(abs(r))
                x = x + a*dx; r = rt; S = St; acc = true; break;
            end
            a = 0.4*a;
        end
        if verbose
            fprintf('    ss refine %2d: ||r||inf = %.3e  P = %.6f  q = %.6f\n', ...
                    it, max(abs(r)), exp(x(1)), exp(x(2)));
        end
        if ~acc, break; end
    end
    if max(abs(r)) < tolS, converged = true; end
    S.resid = r; S.converged = converged; S.iters = it;

    function [r, S] = ss_resid(xv)
        P = exp(xv(1)); q = exp(xv(2));
        tau = rb*Bnom/P + g_real;
        [polB, polK, ~, C] = solve_household_twoasset_egm(rb, q, d, tau, pe, []);
        if isempty(polB)
            r = [1e3; 1e3];
            S = struct('P',P,'q',q,'tau',tau,'polB',[],'polK',[],'C',[], ...
                       'dist',[],'Sb',NaN,'Sk',NaN);
            return;
        end
        % invariant distribution of the TRANSITION's own forward operator
        nx = numel(pe.xGrid); ne = numel(pe.eGrid);
        dist = ones(nx, ne)/(nx*ne);
        for k = 1:20000
            d2 = push_forward_twoasset_x(dist, polB, polK, rb, q, d, tau, pe);
            if max(abs(d2(:) - dist(:))) < 1e-15, dist = d2; break; end
            dist = d2;
        end
        dist = dist / sum(dist(:));
        Sb = sum(sum(polB .* dist));
        Sk = sum(sum(polK .* dist));
        r = [log(max(Sb,1e-12)*P/Bnom); log(max(Sk,1e-12)/Kbar)];
        S = struct('P',P,'q',q,'tau',tau,'polB',polB,'polK',polK,'C',C, ...
                   'dist',dist,'Sb',Sb,'Sk',Sk);
    end
end
