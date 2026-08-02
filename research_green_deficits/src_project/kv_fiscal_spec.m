function fs = kv_fiscal_spec(caseid, opts)
% KV_FISCAL_SPEC  Build the fiscal specification for one case of the
% tax-timing x terminal-debt 2x2. The EXPERIMENT BUILDER, deliberately
% separate from the solver.
%
% WHY SEPARATE. solve_hank_dtpl_transition takes a fiscal path and a terminal
% condition as inputs and knows nothing about C1-C4. If case logic lived
% inside the solver, the four cases could differ in more than one object
% without that being visible at any single call site -- and the whole point of
% the 2x2 is that they differ in exactly one. Keeping the builder here means
% the four specifications can be diffed against each other directly.
%
% THE CASES (formal statement: DEFICIT_2X2_SPEC_R10.md)
%   C1  contemporaneous tax, kappa = 1              reference
%   C2  delayed tax + consolidation, kappa = 1      PURE TIMING
%   C3  contemporaneous tax + issuance, kappa = kbar  PURE RATCHET
%   C4  delayed tax, no consolidation, kappa = kbar  the manuscript's experiment
%
% KAPPA IS FROZEN BEFORE THE FACTORIAL RUNS. `kappa_bar` is a REQUIRED input
% for C3 and C4, recovered once beforehand by kv_kappa_legacy from the legacy
% rho = 0.90 run. C4 may not redefine it: a factorial design requires the
% ratchet treatment to be assigned independently of the timing treatment, and
% if C4 set its own kappa per grid or per initial condition the ratchet would
% be endogenous to the timing treatment and the interaction term would not be
% a clean contrast. If a case cannot hit the frozen target, it is marked
% infeasible -- it does not adopt its realized terminal stock as the target.
%
% INPUT   caseid  'C1' | 'C2' | 'C3' | 'C4'
%         opts    .T                       horizon in years (required)
%                 .rho_bar                 phase-in speed, delayed cases (0.90)
%                 .kappa_bar               REQUIRED for C3, C4
%                 .consolidation_start     T_c, years  (C2; default 10)
%                 .consolidation_half_life H_c, years  (C2; default 10)
%                 .kappa_tol               default 1e-8
%                 .s0                      C2 surcharge scale; the caller
%                                          bisects on it to hit kappa = 1
%
% OUTPUT  fs  .phi_path .kappa_mode .kappa_target .kappa_tol
%             .experiment_id .caseid .timing .debt_target .meta

    assert(nargin >= 2 && isstruct(opts), 'kv_fiscal_spec: opts required');
    T   = req(opts, 'T');
    rho = getdef(opts, 'rho_bar', 0.90);
    Tc  = getdef(opts, 'consolidation_start', 10);       % START DATE
    Hc  = getdef(opts, 'consolidation_half_life', 10);   % HALF-LIFE
    ktol= getdef(opts, 'kappa_tol', 1e-8);
    s0  = getdef(opts, 's0', 0);
    t   = 1:T;

    assert(Tc >= 1 && Tc <= T, 'consolidation_start out of range');
    assert(Hc > 0, 'consolidation_half_life must be positive');
    % T_c and H_c are DIFFERENT parameters. The baseline sets both to 10 by
    % coincidence, not by identity, and this assertion exists so that a later
    % robustness setting cannot collapse them by accident.

    switch upper(caseid)
        case 'C1'
            phi = ones(1, T);
            mode = 'target'; ktgt = 1;
            timing = 'contemporaneous'; dtgt = 'baseline';

        case 'C2'
            % delayed phase-in, then a geometric consolidation surcharge
            phi = 1 - rho.^t;
            zeta = 2^(-1/Hc);
            surch = zeros(1, T);
            k = t >= Tc;
            surch(k) = s0 * zeta.^(t(k) - Tc);
            phi = phi + surch;
            mode = 'target'; ktgt = 1;
            timing = 'delayed'; dtgt = 'baseline';

        case 'C3'
            % contemporaneous from date 2; a single unfunded issuance at t=1
            % delivers the ratchet, so no timing effect is present.
            kbar = req(opts, 'kappa_bar');
            phi = ones(1, T);
            phi(1) = getdef(opts, 'phi1_C3', 0);   % the caller solves this for kbar
            mode = 'target'; ktgt = kbar;
            timing = 'contemporaneous'; dtgt = 'ratcheted';

        case 'C4'
            kbar = req(opts, 'kappa_bar');
            phi = 1 - rho.^t;                      % no consolidation
            mode = 'target'; ktgt = kbar;
            timing = 'delayed'; dtgt = 'ratcheted';

        otherwise
            error('kv_fiscal_spec: unknown case %s', caseid);
    end

    fs = struct( ...
        'phi_path', phi, ...
        'kappa_mode', mode, ...
        'kappa_target', ktgt, ...
        'kappa_tol', ktol, ...
        'experiment_id', sprintf('%s_rho%.3f_Tc%d_Hc%d', upper(caseid), rho, Tc, Hc), ...
        'caseid', upper(caseid), ...
        'timing', timing, ...
        'debt_target', dtgt, ...
        'meta', struct('T', T, 'rho_bar', rho, ...
                       'consolidation_start', Tc, ...
                       'consolidation_half_life', Hc, ...
                       's0', s0, 'kappa_tol', ktol));
end

function v = req(s, f)
    assert(isfield(s, f) && ~isempty(s.(f)), 'kv_fiscal_spec: %s is required', f);
    v = s.(f);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end
