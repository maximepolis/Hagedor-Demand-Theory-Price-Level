function [resid, aux] = transition_residual_dtpl(logphat_free, ctx)
% TRANSITION_RESIDUAL_DTPL  Market-clearing residual of the nonlinear
% HANK-DTPL transition as a pure function of the FREE log-price path.
%
% This factors the per-path residual computation of
% solve_hank_dtpl_transition.m into a reusable function so a sequence-space
% Jacobian and a Newton solver can be built on top of it
% (ssj_transition_jacobian.m, solve_transition_ssj.m). It is a DELIBERATE
% second, independent implementation of the residual: the Anderson solver and
% the SSJ Newton solver therefore agree only if two independent residual codes
% agree, which is a stronger cross-check than sharing one (the correctness-gate
% philosophy of the sequence-space-Jacobian toolkit,
% \citealp{auclertetal2021}).
%
% THE OBJECT (see solve_hank_dtpl_transition.m for the economics): at every
% date the price level clears the asset market, phat_t = B0/S_t. The unknown
% is the free part of the stationarized log-price path, logphat(1:T-1); the
% terminal date phat(T) is pinned at the green steady-state price level.
%
% INPUTS
%   logphat_free : (T-1) x 1 log of the free price path phat(1:T-1).
%   ctx          : context from build_transition_ctx (below), carrying the
%                  boundary steady states, terminal value function VT, initial
%                  distribution dist0, and the calibrated params/regime.
%
% OUTPUTS
%   resid : 1 x T market-clearing residual (S_t - b_t)/b_t. resid(1:T-1) are
%           the free-unknown residuals the Newton step drives to zero;
%           resid(T) is the horizon-adequacy diagnostic at the pinned date.
%   aux   : struct with the consistent paths (phat, S_path, b_path, r_path,
%           tau_path, D_path, Kg, g_path, vart_path, feas).

    T    = ctx.T;
    B0   = ctx.B0;
    rbar = ctx.rbar;
    Gg   = ctx.Gg;
    pgc  = ctx.pgc;

    % assemble the full price path: free part + pinned terminal (green ss)
    phat        = zeros(1, T);
    phat(1:T-1) = exp(logphat_free(:).');
    phat(T)     = ctx.eq1.P;

    % ---- climate + fiscal paths implied by the trial price path ----
    if strcmpi(ctx.regime, 'indexed')
        g_path = (Gg / ctx.eq1.P) * ones(1, T);   % real mandate
    else
        g_path = Gg ./ phat;                       % nominal appropriation
    end
    dg = pgc.delta_g;
    qg = 1; if isfield(pgc,'q_g') && ~isempty(pgc.q_g), qg = pgc.q_g; end
    Kg = zeros(1, T);
    for t = 1:T
        Kprev = 0; if t > 1, Kprev = Kg(t-1); end
        Kg(t) = (1 - dg) * Kprev + qg * g_path(t);
    end
    D_path = pgc.D0 * exp(-pgc.theta_g * Kg);
    b_path = B0 ./ phat;
    if ctx.rebate
        vart_path = 2 * g_path ./ (1 - D_path);
        tau_path  = rbar .* b_path - g_path;
    else
        vart_path = zeros(1, T);
        tau_path  = rbar .* b_path + g_path;
    end
    % realized real return: surprise jump at t=1 against P0 = eq0.P
    phat_lag = [ctx.eq0.P, phat(1:T-1)];
    r_path   = (1 + rbar) .* phat_lag ./ phat - 1;

    % ---- backward: date-t policies from the terminal green ss ----
    [POL, feas] = transition_backward(ctx.VT, r_path, tau_path, D_path, pgc, ...
                                      vart_path);
    if ~feas
        resid = nan(1, T);
        aux = struct('feas', false);
        return;
    end

    % ---- forward: distribution + aggregate asset demand ----
    S_path = zeros(1, T);
    dist = ctx.dist0;
    for t = 1:T
        S_path(t) = POL(t).aGrid_dot_dist(dist);
        dist = POL(t).push(dist);
    end

    % ---- residual: excess demand (S>b) requires phat to FALL ----
    resid = (S_path - b_path) ./ b_path;

    aux = struct('feas', true, 'phat', phat, 'S_path', S_path, ...
        'b_path', b_path, 'r_path', r_path, 'tau_path', tau_path, ...
        'D_path', D_path, 'Kg', Kg, 'g_path', g_path, 'vart_path', vart_path);
end
