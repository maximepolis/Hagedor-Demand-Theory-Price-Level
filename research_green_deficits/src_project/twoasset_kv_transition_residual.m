function [f, aux] = twoasset_kv_transition_residual(x, ctx)
% TWOASSET_KV_TRANSITION_RESIDUAL  Two-market clearing residuals of the
% KV (infrequent-adjustment) announcement transition, as a function of the
% free log-price paths.
%
% The ownership + illiquidity economy's announcement path: at t = 1 the
% permanent lump-sum-financed program is announced; the unknowns are the
% detrended price-level path and the tree-price path,
%
%   x = [log Phat_1..Phat_{T-1} ; log q_1..q_{T-1}],
%
% with date T pinned at the program (terminal) steady state. Clearing:
%
%   bonds :  Sb_t = iota_H * Bnom / Phat_t   (direct household claim)
%   tree  :  Sk_t = Kbar
%
% The intermediated share (1-iota_H) of the debt is held by the fund and
% passed through as dividend: rolling (1-iota)Bnom/Phat_t of real debt at
% the realized return pays out exactly the COUPON on the current position,
% div_t = d + r_b (1-iota)(Bnom/Phat_t)/Kbar -- the revaluation gain on the
% fund's book is absorbed one-for-one by the requirement to hold next
% period's position, so the coupon convention is exact along the path, not
% an approximation. Taxes follow the same convention as the steady state
% (government pays the fixed coupon on the whole stock; the announcement
% revaluation is a capital gain on the stock, not a budget outlay):
% tau_t = r_b (Bnom/Phat_t) + g_real.
%
% SIGN CONVENTION (Anderson fixed-point form, matching the one-asset
% tier-2 solver rather than the Newton form of the frictionless residual):
%   f_b(t) = log( iota Bnom / (Phat_t Sb_t) )   excess demand -> f<0 -> P falls
%   f_q(t) = log( Sk_t / Kbar )                  excess demand -> f>0 -> q rises
% so the damped map x <- x + xi f moves each price toward clearing and the
% driver's Anderson acceleration combines the last few residuals.
%
% ctx fields: .T .p (superstar-augmented params, grids = the SAVED grids)
%   .r_b .d_base .iota .Bnom .Kbar .g_real .Dpath (1 x T) .P0
%   .Pterm .qterm .Vterm (terminal value function)
%   .dist0 (pre-announcement (b,k,e) distribution)
%   .want_V1 (optional: also return the date-1 value function)
%
% aux: .Sb .Sk .rb_t .tau_t .div_t .resid_b .resid_k (full length, incl.
%   the pinned terminal date -- the horizon diagnostics) .ksat .n_nonfin
%   .V1 (if requested) .feas

    T = ctx.T; n = T - 1;
    p = ctx.p; Kbar = ctx.Kbar; Bnom = ctx.Bnom; iota = ctx.iota;
    lp = x(1:n); lq = x(n+1:2*n);
    Ppath = [exp(lp(:)).', ctx.Pterm];
    qpath = [exp(lq(:)).', ctx.qterm];

    aux = struct('feas', false, 'Ppath', Ppath, 'qpath', qpath, ...
                 'Sb', nan(1,T), 'Sk', nan(1,T), 'ksat', 0, 'n_nonfin', 0);
    f = zeros(2*n, 1);

    % realized (stationarized) bond return; P0 is the pre-announcement price,
    % so the announcement-date revaluation enters through rb_1
    rb_t  = (1 + ctx.r_b) * [ctx.P0, Ppath(1:end-1)] ./ Ppath - 1;
    tau_t = ctx.r_b * (Bnom ./ Ppath) + ctx.g_real;
    div_t = ctx.d_base + ctx.r_b * (1 - iota) * (Bnom ./ Ppath) / Kbar;
    aux.rb_t = rb_t; aux.tau_t = tau_t; aux.div_t = div_t;

    % ---- backward: one Bellman application per date from the terminal V ----
    Vnext = ctx.Vterm;
    POL = cell(1, T);
    nnf = 0;
    for t = T:-1:1
        pe = p; pe.eGrid = (1 - ctx.Dpath(t)) * p.eGrid;
        [Vt, polt] = twoasset_kv_bellman_step(Vnext, rb_t(t), qpath(t), ...
                                              div_t(t), tau_t(t), pe);
        nnf = max(nnf, polt.n_nonfin);
        POL{t} = polt;
        if t == 1 && isfield(ctx, 'want_V1') && ctx.want_V1
            aux.V1 = Vt;
        end
        Vnext = Vt;
    end
    aux.n_nonfin = nnf;
    % a broadly infeasible trial path (many healed nodes) cannot price the
    % announcement; report a large finite residual and let the caller damp
    if nnf > 0.05 * numel(ctx.Vterm)
        f(:) = 1e3;
        return;
    end

    % ---- forward: roll the (b,k,e) distribution under the date-t policies ----
    Om = ctx.dist0;
    Sb = zeros(1, T); Sk = zeros(1, T); ksat = 0;
    for t = 1:T
        pe = p; pe.eGrid = (1 - ctx.Dpath(t)) * p.eGrid;
        Sb(t) = sum(POL{t}.bch(:) .* Om(:));
        Sk(t) = sum(POL{t}.kch(:) .* Om(:));
        kmass = squeeze(sum(sum(Om, 1), 3)); kmass = kmass(:);
        ksat = max(ksat, sum(kmass(max(1,end-1):end)) / max(sum(kmass), eps));
        if t < T
            Om = push_forward_twoasset_kv(Om, POL{t}, rb_t(t), qpath(t), ...
                                          div_t(t), tau_t(t), pe);
        end
    end
    aux.Sb = Sb; aux.Sk = Sk; aux.ksat = ksat; aux.feas = true;

    % full-length residuals: interior entries are the solver's unknowns, the
    % date-T entries are the HORIZON-ADEQUACY diagnostics (terminal pinned)
    aux.resid_b = log(iota * Bnom ./ (Ppath .* max(Sb, 1e-12)));
    aux.resid_k = log(max(Sk, 1e-12) / Kbar);
    f(1:n)     = aux.resid_b(1:n).';
    f(n+1:2*n) = aux.resid_k(1:n).';
end
