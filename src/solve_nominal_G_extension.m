function out = solve_nominal_G_extension(params)
% SOLVE_NOMINAL_G_EXTENSION  DTPL with NOMINAL government expenditure
% (paper Section on price-indexed debt and nominal spending, Figure 4).
% Shows the theory is broader than "demand for bonds": nominal spending G can
% determine the price level even when bonds are real (price-indexed).
%
% CASE 1 (paper Eq. 66-69: real bonds Breal, nominal G, endowment tax omega)
%   Nominal taxes:  T = (1+i) P_{-1} Breal + G - P*omega - P*Breal,
%   households:     c + a' = (1+r) a + (1-omega) e - tau,
%   real taxes:     tau(P) = G/P - omega + r^ss * Breal,
%   asset market:   S(1+r^ss, tau(P)) = Breal.
%   By the paper's Result 1, S is strictly DECREASING in tau, hence INCREASING
%   in P (higher P => lower real spending G/P => lower real taxes => higher
%   private asset demand). A unique P* obtains where the (increasing) demand
%   curve crosses the fixed level Breal.
%   NORMALIZATION (replicator): omega = Gnom/P_target with P_target = 1, and
%   Breal is computed as the model's own asset demand at r^ss under the scaled
%   endowment (1-omega)e -- so that P* = P_target = 1 is an equilibrium BY
%   CONSTRUCTION and the figure displays the mechanism cleanly. Override with
%   params.Breal to explore other configurations (existence not guaranteed).
%
% CASE 2 (nominal bonds Bnom + nominal spending G2)
%   Real taxes:     tau(P) = (r^ss * Bnom + G2)/P,
%   asset market:   S(1+r^ss, tau(P)) = Bnom/P.
%   G2 must be small relative to Bnom: large nominal G makes real taxes at the
%   equilibrium price level exceed minimum income (no equilibrium). Default
%   G2 = 0.02.
%
% INPUT
%   params : struct from setup_params. Optional fields:
%            .Gnom (0.20, case-1 nominal spending), .Gnom2 (0.02, case 2),
%            .P_target (1.0, case-1 normalization), .Breal (override).
%
% OUTPUT
%   out : struct with .Gnom .Gnom2 .omega .Breal .r_ss and per-case structs
%         .case1/.case2 carrying .roots .Pgrid .resid .S_curve .supply_curve
%         .tau_at_root .msg.
%
% PAPER SECTION: nominal-government-expenditure extension (Figure 4).

    if isfield(params,'Gnom')     && ~isempty(params.Gnom),     Gnom  = params.Gnom;     else, Gnom  = 0.20; end
    if isfield(params,'Gnom2')    && ~isempty(params.Gnom2),    Gnom2 = params.Gnom2;    else, Gnom2 = 0.02; end
    if isfield(params,'P_target') && ~isempty(params.P_target), P_target = params.P_target; else, P_target = 1.0; end
    Bnom  = params.Bnom;

    i_ss  = params.i_ss; pi_ss = params.pi_ss;
    r_ss  = (1 + i_ss)/(1 + pi_ss) - 1;

    out = struct();
    out.Gnom = Gnom; out.Gnom2 = Gnom2; out.Bnom = Bnom; out.r_ss = r_ss;

    Pgrid = linspace(params.P_min, params.P_max, params.nP);

    % =================================================================
    % CASE 1: real bonds + nominal G + endowment tax omega (Eq. 66-69)
    % =================================================================
    omega = Gnom / P_target;             % tax rate s.t. tau(P_target) = r*Breal
    out.omega = omega;

    p1 = params;
    p1.eGrid = (1 - omega) * params.eGrid;    % households keep (1-omega)e

    if isfield(params,'Breal') && ~isempty(params.Breal)
        Breal = params.Breal;                 % user override (no root guarantee)
    else
        % Model-consistent normalization: Breal = S at r^ss with tau = r*Breal,
        % which is exactly the aggregate_asset_demand fixed point under the
        % scaled endowment. Then P* = P_target solves case 1 by construction.
        fprintf('  [nominal-G] calibrating Breal = S(1+r^ss) under (1-omega)e ...\n');
        [Breal, adout1] = aggregate_asset_demand(r_ss, p1);
        if ~isfinite(Breal) || ~adout1.converged
            out.case1 = struct('roots',[],'Pgrid',Pgrid,'resid',nan(size(Pgrid)), ...
                'S_curve',nan(size(Pgrid)),'supply_curve',nan(size(Pgrid)), ...
                'tau_at_root',[],'msg','case 1: Breal calibration failed.');
            warning('solve_nominal_G_extension:Breal','%s', out.case1.msg);
            Breal = NaN;
        end
    end
    out.Breal = Breal;

    if isfinite(Breal)
        tau1 = @(P) Gnom ./ P - omega + r_ss * Breal;
        S1   = build_S_of_tau(r_ss, tau1(Pgrid), p1);
        F1   = @(P) S1(tau1(P)) - Breal;
        [roots1, resid1] = scan_and_solve(F1, Pgrid, params.tol_root);
        out.case1 = pack_case(roots1, Pgrid, resid1, ...
            resid1 + Breal, Breal * ones(size(Pgrid)), tau1, ...
            sprintf('real bonds Breal=%.3f, nominal G=%.2f (S=Breal)', Breal, Gnom));

        % Demand-curve FAMILY for Figure 4(a): S(1+r, tau(P)) traced over the
        % real rate for three price levels (below / at / above the equilibrium
        % normalization). Higher P => lower real spending G/P => lower real
        % taxes => the whole demand curve shifts RIGHT (paper Result 1).
        % P below 0.75*P_target is omitted: its implied tax would exceed the
        % feasibility bound under the scaled endowment.
        Pfam = P_target * [0.75, 1.0, 2.0];
        rfam = linspace(params.r_min, min(params.r_max, 0.026), 9);
        Sfam = nan(numel(Pfam), numel(rfam));
        for a = 1:numel(Pfam)
            taua = tau1(Pfam(a));
            for b = 1:numel(rfam)
                Sfam(a, b) = S_at_tau(rfam(b), taua, p1);
            end
            fprintf('  [fig4 demand curve %d/%d] P=%.2f (tau=%+.3f) done\n', ...
                    a, numel(Pfam), Pfam(a), taua);
        end
        out.case1.family = struct('P', Pfam, 'rgrid', rfam, 'S', Sfam);
    end

    % =================================================================
    % CASE 2: nominal bonds + nominal G (S = B/P)
    % =================================================================
    tau2 = @(P) (r_ss * Bnom + Gnom2) ./ P;
    S2   = build_S_of_tau(r_ss, tau2(Pgrid), params);
    F2   = @(P) S2(tau2(P)) - Bnom ./ P;
    [roots2, resid2] = scan_and_solve(F2, Pgrid, params.tol_root);
    out.case2 = pack_case(roots2, Pgrid, resid2, ...
        resid2 + Bnom ./ Pgrid, Bnom ./ Pgrid, tau2, ...
        sprintf('nominal bonds B=%.2f + nominal G=%.2f (S=B/P)', Bnom, Gnom2));

    fprintf('\n[nominal-G extension]\n  case1: %s\n  case2: %s\n', ...
        out.case1.msg, out.case2.msg);
end

% =========================================================================
function S_of_tau = build_S_of_tau(r, tau_span, p)
% Interpolant of S(r, tau) over the tau range implied by the price grid,
% clamped at the lump-sum feasibility bound tau < e_min + r*amin.
    tau_feasmax = min(p.eGrid) + r*(-p.abar) - 1e-4;
    tau_lo = max(min(tau_span), -1.0);
    tau_hi = min(max(tau_span), tau_feasmax);
    taugrid = linspace(tau_lo, tau_hi, 17);
    Stau = nan(size(taugrid));
    for m = 1:numel(taugrid)
        Stau(m) = S_at_tau(r, taugrid(m), p);
        fprintf('  [S(tau) node %2d/%2d] tau=%+.4f  S=%8.4f\n', ...
                m, numel(taugrid), taugrid(m), Stau(m));
    end
    good = isfinite(Stau);
    if nnz(good) < 2
        S_of_tau = @(t) nan(size(t));
        warning('solve_nominal_G_extension:interp', ...
            'Fewer than 2 finite S(tau) nodes; case cannot be solved.');
    else
        S_of_tau = @(t) interp1(taugrid(good), Stau(good), t, 'linear', NaN);
    end
end

% =========================================================================
function S = S_at_tau(r, tau, p)
% Aggregate asset holdings at EXOGENOUS (r, tau): one household solve + dist.
    if p.beta*(1+r) >= p.betaR_max
        S = Inf; return;
    end
    % lump-sum feasibility: poorest at the constraint must afford c > 0
    if tau >= min(p.eGrid) + r*(-p.abar) - 1e-6
        S = NaN; return;
    end
    [~, polA_idx, ~, ~, hd] = solve_household_vfi(r, tau, p);
    if ~hd.converged, S = NaN; return; end
    [dist, dd] = compute_stationary_distribution(polA_idx, p.Pi, p);
    if ~dd.converged, S = NaN; return; end
    S = p.aGrid(:)' * sum(dist, 2);
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
    roots = sort(roots);
    if ~isempty(roots)
        keep = [true; diff(roots) > 1e-6];
        roots = roots(keep);
    end
end

% =========================================================================
function c = pack_case(roots, Pgrid, resid, S_curve, supply_curve, tau_of_P, label)
    c = struct();
    c.roots        = roots;
    c.Pgrid        = Pgrid;
    c.resid        = resid;
    c.S_curve      = S_curve;        % asset demand S(r^ss, tau(P)) vs P
    c.supply_curve = supply_curve;   % Breal (flat) or B/P (hyperbola)
    c.tau_at_root  = tau_of_P(roots);
    if isempty(roots)
        c.msg = sprintf('%s: no positive price-level root on scan grid.', label);
    elseif numel(roots) == 1
        c.msg = sprintf('%s: P* = %.4f (unique).', label, roots(1));
    else
        c.msg = sprintf('%s: MULTIPLE P* = %s.', label, mat2str(roots',5));
    end
end
