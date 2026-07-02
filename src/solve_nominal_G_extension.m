function out = solve_nominal_G_extension(params)
% SOLVE_NOMINAL_G_EXTENSION  DTPL with NOMINAL government expenditure. This
% section shows the theory is broader than "demand for bonds": nominal government
% spending G can determine the price level through an aggregate-demand channel,
% even when bonds are real (or in zero net supply).
%
% MECHANISM
%   A higher price level P lowers real government purchases G/P, which lowers the
%   real taxes/transfers needed to finance them. Because private demand does not
%   offset government demand one-for-one, aggregate real demand — and hence
%   equilibrium asset demand — changes with P. The price level adjusts so the
%   asset market clears.
%
% CASE 1 (real bonds, fixed real debt Breal)
%   Household tax:  tau(P) = r^ss * Breal + G/P   (interest + real spending).
%   Asset-market clearing:  S(1+r^ss, tau(P)) = Breal.
%   Solve for P^*.
%
% CASE 2 (nominal bonds Bnom + nominal spending G)
%   Household tax:  tau(P) = (r^ss * Bnom + G)/P.
%   Asset-market clearing:  S(1+r^ss, tau(P)) = Bnom/P.
%   Solve for P^*.
%
% INPUT
%   params : struct from setup_params. Optional params.Gnom (0.20),
%            params.Breal (1.0).
%
% OUTPUT
%   out : struct with case-1 and case-2 results:
%         .Gnom .Breal .r_ss
%         .case1 : struct .roots .Pgrid .resid .msg
%         .case2 : struct .roots .Pgrid .resid .msg
%         .tau_interp : the S(tau) interpolant used (fixed r^ss).
%
% PAPER SECTION: nominal-government-expenditure extension (Figure 4 analogue).

    if isfield(params,'Gnom') && ~isempty(params.Gnom), Gnom = params.Gnom; else, Gnom = 0.20; end
    if isfield(params,'Breal') && ~isempty(params.Breal), Breal = params.Breal; else, Breal = 1.0; end
    Bnom  = params.Bnom;

    i_ss  = params.i_ss; pi_ss = params.pi_ss;
    r_ss  = (1 + i_ss)/(1 + pi_ss) - 1;

    out = struct();
    out.Gnom = Gnom; out.Breal = Breal; out.Bnom = Bnom; out.r_ss = r_ss;

    % ---- Precompute S(tau) at fixed r^ss (only tau varies with P) ----
    % tau range: from small (large P) to large (small P). Cover generously.
    tau_lo = -0.5;
    tau_hi = r_ss*max(Bnom,Breal) + Gnom/params.P_min + 0.5;
    taugrid = linspace(tau_lo, tau_hi, max(25, round(params.nr)));
    Stau = nan(size(taugrid));
    for m = 1:numel(taugrid)
        Stau(m) = S_at_tau(r_ss, taugrid(m), params);
    end
    good = isfinite(Stau);
    S_of_tau = @(t) interp1(taugrid(good), Stau(good), t, 'linear', NaN);
    out.tau_interp = struct('taugrid', taugrid, 'Stau', Stau);

    Pgrid = linspace(params.P_min, params.P_max, params.nP);

    % ---- CASE 1: real bonds, S(r, tau(P)) = Breal ----
    tau1 = @(P) r_ss * Breal + Gnom ./ P;
    F1   = @(P) S_of_tau(tau1(P)) - Breal;
    [roots1, resid1] = scan_and_solve(F1, Pgrid, params.tol_root);
    out.case1 = pack_case(roots1, Pgrid, resid1, ...
        r_ss, @(P) 0*P + r_ss, tau1, 'real bonds (S=Breal)');

    % ---- CASE 2: nominal bonds + nominal G, S(r, tau(P)) = Bnom/P ----
    tau2 = @(P) (r_ss * Bnom + Gnom) ./ P;
    F2   = @(P) S_of_tau(tau2(P)) - Bnom ./ P;
    [roots2, resid2] = scan_and_solve(F2, Pgrid, params.tol_root);
    out.case2 = pack_case(roots2, Pgrid, resid2, ...
        r_ss, @(P) 0*P + r_ss, tau2, 'nominal bonds + nominal G (S=B/P)');

    fprintf('\n[nominal-G extension]\n  case1: %s\n  case2: %s\n', ...
        out.case1.msg, out.case2.msg);
end

% =========================================================================
function S = S_at_tau(r, tau, params)
% Aggregate asset holdings at EXOGENOUS (r, tau): one household solve + dist.
    if params.beta*(1+r) >= params.betaR_max
        S = Inf; return;
    end
    [~, polA_idx, ~, ~, hd] = solve_household_vfi(r, tau, params);
    if ~hd.converged, S = NaN; return; end
    [dist, dd] = stationary_distribution(polA_idx, params.Pi, params);
    if ~dd.converged, S = NaN; return; end
    S = params.aGrid(:)' * sum(dist, 2);
end

% =========================================================================
function [roots, resid] = scan_and_solve(F, Pgrid, tol)
    resid = arrayfun(F, Pgrid);
    roots = [];
    for k = 1:numel(Pgrid)-1
        f1 = resid(k); f2 = resid(k+1);
        if isfinite(f1) && isfinite(f2) && sign(f1) ~= sign(f2) && f1 ~= 0
            try
                pr = fzero(F, [Pgrid(k), Pgrid(k+1)], optimset('TolX', tol));
                if isfinite(pr) && pr > 0, roots(end+1,1) = pr; end %#ok<AGROW>
            catch
            end
        elseif isfinite(f1) && f1 == 0
            roots(end+1,1) = Pgrid(k); %#ok<AGROW>
        end
    end
    % dedup
    roots = sort(roots);
    if ~isempty(roots)
        keep = [true; diff(roots) > 1e-6];
        roots = roots(keep);
    end
end

% =========================================================================
function c = pack_case(roots, Pgrid, resid, r_ss, r_of_P, tau_of_P, label)
    c = struct();
    c.roots  = roots;
    c.Pgrid  = Pgrid;
    c.resid  = resid;
    c.r_ss   = r_ss;
    c.tau_at_root = tau_of_P(roots);
    if isempty(roots)
        c.msg = sprintf('%s: no positive price-level root on scan grid.', label);
    elseif numel(roots) == 1
        c.msg = sprintf('%s: P* = %.4f (unique).', label, roots(1));
    else
        c.msg = sprintf('%s: MULTIPLE P* = %s.', label, mat2str(roots',5));
    end
end
