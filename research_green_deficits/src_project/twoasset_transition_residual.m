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
%         .Cterm (terminal consumption policy)
%         .Psi0  pre-announcement distribution over cash-on-hand
%         .pB0 .pK0  pre-announcement portfolio policies, revalued at the
%                    date-1 prices to form the date-1 state
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
                 'tau_t', nan(1,T), 'tbad', 0, 'xsat', NaN, 'xsat_t', 0);
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
    % TIMING. A portfolio (b',k') chosen at date t earns its return at date
    % t+1, so the push from Omega_t to Omega_{t+1} must be evaluated at
    % DATE t+1 prices, not date t. Equivalently, cash-on-hand entering t+1 is
    %   x_{t+1} = y_{t+1} - tau_{t+1} + (1+r^b_{t+1}) b'_t + (q_{t+1}+d) k'_t.
    %
    % The date-1 state needs the same care and is where the economics lives.
    % Omega0 is the pre-announcement distribution over cash-on-hand, formed at
    % OLD prices. Households enter date 1 holding the pre-announcement
    % PORTFOLIOS (pB0, pK0); the announcement revalues them at the new date-1
    % prices. Starting the recursion from Omega0 directly would freeze that
    % revaluation, which is exactly the announcement-date effect the exercise
    % is about, and would leave the market-clearing system with no solution
    % (the state would be inconsistent with the prices at every date).
    % At constant prices this recursion reproduces the stationary
    % distribution, so the steady state is a fixed point of it by construction.
    pe1 = p; pe1.eGrid = (1 - ctx.Dpath(1)) * p.eGrid;
    Om  = push_forward_twoasset_x(ctx.Psi0, ctx.pB0, ctx.pK0, rb_t(1), qpath(1), ...
                          ctx.d_div, tau_t(1), pe1);
    Sb = zeros(1,T); Sk = zeros(1,T);
    % Cash-on-hand grid saturation. push_forward clamps x' to the grid, so if
    % the announcement revaluation drives mass onto the top node the
    % aggregates stop responding to prices there. That shows up as a
    % near-singular Jacobian and a residual stuck at the announcement dates,
    % which no amount of solver work can fix -- the grid has to be widened.
    xsat_max = 0; xsat_arg = 0;
    for t = 1:T
        Sb(t) = sum(sum(polB{t} .* Om));
        Sk(t) = sum(sum(polK{t} .* Om));
        stop_mass = sum(Om(end,:)) / max(sum(Om(:)), eps);
        if stop_mass > xsat_max, xsat_max = stop_mass; xsat_arg = t; end
        if t < T
            petp = p; petp.eGrid = (1 - ctx.Dpath(t+1)) * p.eGrid;
            Om = push_forward_twoasset_x(Om, polB{t}, polK{t}, rb_t(t+1), qpath(t+1), ...
                                 ctx.d_div, tau_t(t+1), petp);
        end
    end
    aux.Sb = Sb; aux.Sk = Sk; aux.feas = true;
    aux.xsat = xsat_max; aux.xsat_t = xsat_arg;

    % ---- residuals on the free dates ----
    resid(1:n)       = log(max(Sb(1:n), 1e-12) .* Ppath(1:n) / Bnom).';
    resid(n+1:2*n)   = log(max(Sk(1:n), 1e-12) / Kbar).';
end
