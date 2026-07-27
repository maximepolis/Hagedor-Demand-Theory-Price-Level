function [resid, aux] = twoasset_transition_residual(x, ctx)
% TWOASSET_TRANSITION_RESIDUAL  Market-clearing residuals of the two-asset
% announcement transition, as a function of the free log-price paths.
%
% The two-asset counterpart of transition_residual_dtpl. There the aggregate
% unknown is a scalar per date (the log price level); here it is a PAIR per
% date, because two markets must clear at every date:
%
%   nominal bonds :  int b'_t dOmega_t  =  B / P_t
%   Lucas tree    :  int k'_t dOmega_t  =  Kbar
%
% so the sequence-space system is 2(T-1) equations in 2(T-1) unknowns (the
% terminal date is pinned at the program steady state).
%
% INPUT
%   x   : 2(T-1) x 1 stacked free log prices, [log P_1..P_{T-1};
%         log q_1..q_{T-1}].
%   ctx : context built by the driver, with fields
%         .T .p .r_b .d_div .Bnom .Kbar .Dpath .g_real
%         .P0 (pre-announcement price) .Pterm .qterm
%         .Cterm (terminal consumption policy) .Omega0 (initial distribution)
%
% OUTPUT
%   resid : 2(T-1) x 1 residuals, in LOGS so both blocks are scale-free and
%           the Newton step is not dominated by whichever market happens to
%           carry the larger level:
%             bond block  log( S^b_t P_t / B )
%             tree block  log( S^k_t / Kbar )
%   aux   : .feas .Ppath .qpath .Sb .Sk .rb_t .tau_t .tbad
%
% Infeasibility is reported, never thrown: the household solver returns empty
% policies when the equity-bond spread turns non-positive, which a Newton
% trial step can provoke. The caller backtracks on aux.feas = false rather
% than treating it as an error.

    T  = ctx.T;  n = T - 1;
    p  = ctx.p;  Kbar = ctx.Kbar;  Bnom = ctx.Bnom;
    lp = x(1:n);  lq = x(n+1:2*n);
    Ppath = [exp(lp(:)).', ctx.Pterm];
    qpath = [exp(lq(:)).', ctx.qterm];

    aux = struct('feas', false, 'Ppath', Ppath, 'qpath', qpath, ...
                 'Sb', nan(1,T), 'Sk', nan(1,T), 'rb_t', nan(1,T), ...
                 'tau_t', nan(1,T), 'tbad', 0);
    resid = zeros(2*n, 1);

    % Stationarized real gross bond return, (1+r_b) Phat_{t-1}/Phat_t, with
    % Phat_0 the PRE-announcement price: the announcement-date revaluation
    % enters through P_0/P_1.
    Rb_t  = (1 + ctx.r_b) * [ctx.P0, Ppath(1:end-1)] ./ Ppath;
    rb_t  = Rb_t - 1;
    tau_t = rb_t * Bnom ./ Ppath + ctx.g_real;
    aux.rb_t = rb_t; aux.tau_t = tau_t;

    % ---- backward pass: one EGM step per date, from the terminal policy ----
    Cnext = ctx.Cterm;
    polB = cell(1,T); polK = cell(1,T);
    szx = [numel(p.xGrid) numel(p.eGrid)];
    for t = T:-1:1
        pet = p; pet.eGrid = (1 - ctx.Dpath(t)) * p.eGrid;
        pet.maxit_pol = 1; pet.tol_pol = 0;          % exactly one backward step
        [bB, bK, ~, Ct] = solve_household_twoasset_egm( ...
                              rb_t(t), qpath(t), ctx.d_div, tau_t(t), pet, Cnext);
        if isempty(bB) || isempty(Ct) || ~isequal(size(bB), szx)
            aux.tbad = t;                            % non-positive spread here
            resid(:) = 1e3;                          % large but finite
            return;
        end
        polB{t} = bB; polK{t} = bK; Cnext = Ct;
    end

    % ---- forward pass: roll the distribution, collect the two aggregates ----
    Om = ctx.Omega0; Sb = zeros(1,T); Sk = zeros(1,T);
    for t = 1:T
        pet = p; pet.eGrid = (1 - ctx.Dpath(t)) * p.eGrid;
        Sb(t) = sum(sum(polB{t} .* Om));
        Sk(t) = sum(sum(polK{t} .* Om));
        Om = push_forward_2a(Om, polB{t}, polK{t}, rb_t(t), qpath(t), ...
                             ctx.d_div, tau_t(t), pet);
    end
    aux.Sb = Sb; aux.Sk = Sk; aux.feas = true;

    % ---- residuals on the free dates ----
    resid(1:n)       = log(max(Sb(1:n), 1e-12) .* Ppath(1:n) / Bnom).';
    resid(n+1:2*n)   = log(max(Sk(1:n), 1e-12) / Kbar).';
end

function Om2 = push_forward_2a(Om, polB, polK, rb, q, d, tau, pe)
% One-period forward push of the (nx x ne) distribution on the cash-on-hand
% grid (Young lottery, e'-specific targets). Kept local so the residual is
% self-contained and the Jacobian can be evaluated without the driver.
    xG = pe.xGrid(:); nx = numel(xG); ne = numel(pe.eGrid);
    ynet = pe.eGrid(:)' - tau; Rb = 1 + rb;
    Om2 = zeros(nx, ne);
    for ie = 1:ne
        col = Om(:, ie); if ~any(col), continue; end
        base = Rb*polB(:, ie) + (q + d)*polK(:, ie);
        for jep = 1:ne
            xp  = min(max(ynet(jep) + base, xG(1)), xG(end));
            idx = discretize(xp, xG); idx(~isfinite(idx)) = nx-1;
            idx = min(max(idx,1), nx-1);
            w   = min(max((xp - xG(idx))./(xG(idx+1)-xG(idx)), 0), 1);
            pm  = pe.Pi(ie, jep);
            Om2(:, jep) = Om2(:, jep) ...
                + accumarray(idx,   col.*(1-w)*pm, [nx 1]) ...
                + accumarray(idx+1, col.*w*pm,     [nx 1]);
        end
    end
end
