function [S, out] = S_green(r, tau, D, pg)
% S_GREEN  Aggregate asset demand S(1+r; tau, D) of the climate economy.
%
% Wraps the root package's household VFI and exact stationary distribution for
% the environment of MODEL_AND_THEORY.md Section 1:
%   * effective endowments (1-D)*e  (damage level channel),
%   * income risk sig_eps(D) = sig_eps0*(1 + phi_D*D)  (risk channel),
%   * lump-sum tax tau.
%
% INPUTS
%   r   : real interest rate (scalar).
%   tau : real lump-sum tax (scalar; may be negative = transfer).
%   D   : damage factor in [0, D0].
%   pg  : project params from setup_params_green.
%
% OUTPUTS
%   S   : aggregate assets (NaN if infeasible / no convergence; Inf if the
%         rate violates the beta(1+r) bound).
%   out : struct with .W (utilitarian welfare = sum V.*dist), .C (aggregate
%         consumption), .gini_a / .gini_y (wealth and effective-income Ginis),
%         .feasible, .hhdiag, .distdiag, .dist, .V.
%
% PAPER OBJECT: Lemma 1 (regularity/scaling); the code treats D as a genuine
% second argument because the risk channel breaks the exact scaling identity.

    out = struct('W',NaN,'C',NaN,'gini_a',NaN,'gini_y',NaN,'feasible',false);

    if pg.beta*(1+r) >= pg.betaR_max
        S = Inf; return;
    end

    % ---- rebuild the income process if the risk channel is active ----
    % pg.D_risk (optional) lets the caller evaluate the RISK channel at a
    % different damage level than the endowment level/incidence channel --
    % used by decompose_safe_asset_channel to isolate the two. Default: D.
    p = pg;
    if pg.phi_D > 0
        Drisk = D;
        if isfield(pg, 'D_risk') && ~isempty(pg.D_risk), Drisk = pg.D_risk; end
        p.sig_eps = pg.sig_eps0 * (1 + pg.phi_D * Drisk);
        [eG, PiD, statD] = make_income_process(p);
        p.eGrid = eG; p.Pi = PiD; p.stationary_e = statD;
    end

    % ---- damage level channel: scale endowments ----
    % With an incidence gradient psi_inc > 0 (paper Eq. "incidence"), damages
    % fall disproportionately on low-endowment households:
    %   y(e;D) = (1 - D*chi(e))*e,  chi(e) = e^(-psi)/E[e^(1-psi)],
    % normalized so the population-average damage share equals D. psi_inc = 0
    % recovers the uniform scaling (1-D)*e.
    psi = 0;
    if isfield(pg, 'psi_inc') && ~isempty(pg.psi_inc), psi = pg.psi_inc; end
    if psi > 0
        ev   = p.eGrid(:);
        wst  = p.stationary_e(:);
        cnorm = wst' * (ev.^(1 - psi));           % E[e^(1-psi)]
        chi   = (ev.^(-psi)) / cnorm;             % E[chi(e) e] = 1
        scale = 1 - D * chi;
        % BOUNDED INCIDENCE (M8): no household loses more than (1-floor) of its
        % endowment to damages, so the fiscal-space object cannot diverge from
        % an unbounded incidence tail. floor is an ECONOMIC parameter (default
        % 0.05, = the previous hard cap); binds only under strong regressive
        % incidence (large psi, large D).
        floor_s = 0.05;
        if isfield(pg,'scale_floor') && ~isempty(pg.scale_floor)
            floor_s = pg.scale_floor;
        end
        if any(scale < floor_s)
            scale = max(scale, floor_s);
        end
        p.eGrid = (scale .* ev)';
    else
        p.eGrid = (1 - D) * p.eGrid;
    end

    % ---- proportional levy (U4 financing regimes) ----
    % A carbon-tax-style levy at rate vartheta on effective endowments:
    % household resources become (1 - vartheta)*(1 - D*chi(e))*e. In the
    % endowment economy this instrument is non-distortionary, so financing
    % regimes differ through INCIDENCE (proportional vs lump-sum) and the
    % induced price level, not through aggregate resources; the Pigouvian
    % margin requires the production extension (roadmap U8) and is NOT
    % claimed here.
    if isfield(pg, 'vartheta') && ~isempty(pg.vartheta) && pg.vartheta ~= 0
        p.eGrid = (1 - pg.vartheta) * p.eGrid;
    end

    % ---- lump-sum feasibility: poorest at the constraint must afford c>0 ----
    if tau >= min(p.eGrid) + r*(-p.abar) - 1e-6
        S = NaN; return;
    end

    % ---- household block + exact distribution ----
    [V, polA_idx, ~, polC, hhdiag] = solve_household_vfi(r, tau, p);
    if ~hhdiag.converged, S = NaN; out.hhdiag = hhdiag; return; end
    [dist, distdiag] = compute_stationary_distribution(polA_idx, p.Pi, p);
    if ~distdiag.converged, S = NaN; out.distdiag = distdiag; return; end

    S = p.aGrid(:)' * sum(dist, 2);

    % ---- welfare and distributional diagnostics ----
    out.W        = sum(sum(V .* dist));
    out.C        = sum(sum(polC .* dist));
    out.feasible = true;
    out.hhdiag   = hhdiag;
    out.distdiag = distdiag;
    out.dist     = dist;
    out.V        = V;
    out.polC     = polC;
    out.eGrid_eff = p.eGrid;   % post-damage/levy effective endowments

    % Ginis: wealth over aGrid marginal; income over effective endowments
    wa = sum(dist, 2);                       % marginal over assets
    out.gini_a = gini_from_weights(p.aGrid(:), wa);
    wy = sum(dist, 1)';                      % marginal over income states
    out.gini_y = gini_from_weights(p.eGrid(:), wy);
end

% -------------------------------------------------------------------------
function g = gini_from_weights(x, w)
% Gini coefficient of a discrete distribution (values x, weights w>=0).
% Standard formula on the sorted values; returns NaN for degenerate input.
    w = w(:) / sum(w);
    [x, idx] = sort(x(:));
    w = w(idx);
    mu = sum(w .* x);
    if mu <= 0, g = NaN; return; end
    cw  = cumsum(w);                 % cumulative population share
    cxw = cumsum(w .* x) / mu;       % cumulative income share (Lorenz)
    % trapezoidal area under the Lorenz curve
    Lprev = [0; cxw(1:end-1)];
    Fprev = [0; cw(1:end-1)];
    areaL = sum((cw - Fprev) .* (cxw + Lprev) / 2);
    g = 1 - 2*areaL;
end
