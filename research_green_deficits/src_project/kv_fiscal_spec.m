function fs = kv_fiscal_spec(caseid, opts)
% KV_FISCAL_SPEC  Build the fiscal specification for one case of the
% tax-timing / terminal-debt decomposition. The EXPERIMENT BUILDER,
% deliberately separate from the solver.
%
% THE TAX RULE, WRITTEN OUT IN FULL:
%
%       tau_t = r^ss * b_t + phi_t * g_{g,t} + xi_t,
%
%   phi_t     contemporaneously financed share of green spending
%   1 - phi_t initially debt-financed share
%   xi_t      consolidation surcharge, xi_t = a_xi * h_t
%
% The surcharge SHAPE h_t is pre-specified here; only the scalar amplitude
% a_xi is solved for, by kv_solve_consolidation, and only in the case that
% needs it. Solving for a whole path would let the matched-terminal-debt case
% differ from its comparators in the SHAPE of the tax path as well as in its
% level, which is the confound the decomposition exists to remove.
%
% ================= WHY C3 NO LONGER EXISTS =================
% The earlier design had a 2x2 whose fourth cell C3 was "contemporaneous tax
% AND a ratcheted terminal debt". That cell is INFEASIBLE under this model's
% own government budget. It is not a hard cell to compute; it is an empty one.
%
% Under the contemporaneous service rule phi_t = 1, xi_t = 0,
%
%       tau_t = r^ss b_t + g_{g,t},
%
% so the PRIMARY BALANCE is exactly zero at every date. The flow identity
%
%       B_t = (1 + i^ss) B_{t-1} + P_t ( g_{g,t} - tau_t )
%
% then collapses to B_t = (1 + i^ss) B_{t-1}, which is the paper's own
% Section 7.1 result B_t = (1 + mu) B_{t-1} once the steady-state Fisher
% relation is imposed. Detrended nominal debt is therefore CONSTANT:
%
%       \hat B_t = \hat B_0    for all t.
%
% Starting from the same initial stock and holding the real program fixed,
% contemporaneous service-rule taxation PINS \hat B_T = \hat B_0. A
% permanently higher terminal stock requires cumulative primary deficits
% somewhere in the path, and this rule permits none at any date. The two
% conditions cannot hold together.
%
% The previous implementation reached C3 by bisecting an unexplained
% `phi1_C3` -- a single unfunded issuance at t = 1. That IS a cumulative
% primary deficit, so the case was not the contemporaneous service rule at
% all: it produced a number attached to no stated fiscal experiment.
%
% C3 may return only if an ADDITIONAL instrument is modelled explicitly (a
% one-time debt-financed transfer, or a government acquisition of an
% offsetting asset). It would then have to be NAMED for that operation and
% could not be described as a pure terminal-debt treatment.
%
% ================= THE THREE FEASIBLE CASES =================
%   C1  phi_t = 1,          xi_t = 0          contemporaneous service rule
%   C2  phi_t = 1 - rho^t,  xi_t = a_xi h_t   delayed tax, CONSOLIDATED so
%                                             terminal debt returns to C1's
%   C4  phi_t = 1 - rho^t,  xi_t = 0          delayed tax, no recovery
%                                             (the manuscript's experiment)
%
% ESTIMANDS
%   tax timing at MATCHED terminal debt          = C2 - C1
%   failure to consolidate, given the same delay = C4 - C2
%   total legacy joint effect                    = C4 - C1
%
% A fully independent factorial INTERACTION is not identified with this
% instrument set, because the missing cell is infeasible rather than merely
% unrun. Do not report one.
%
% KAPPA IS NEVER AN INPUT TO THE PRICE PATH. C4's terminal dilution is an
% OUTCOME, to be compared against the pre-refactor legacy value rather than
% imposed on it; C2's target is reached through a_xi in the TAX RULE, never by
% overriding the terminal price. See the terminal-pin comment in
% solve_hank_dtpl_transition for what that override used to do.
%
% INPUT   caseid  'C1' | 'C2' | 'C4'
%         opts    .T                       horizon in years (required)
%                 .rho_bar                 phase-in speed, delayed cases (0.90)
%                 .consolidation_start     T_c, years  (C2; default 10)
%                 .consolidation_half_life H_c, years  (C2; default 10)
%                 .consolidation_scale     a_xi (C2; default 0, set by solver)
%                 .kappa_target            C2 only; default 1 (match C1)
%                 .kappa_tol               default 1e-8
%
% OUTPUT  fs  .phi_path .consolidation_shape .consolidation_scale
%             .consolidation_path .kappa_mode .kappa_target .kappa_tol
%             .experiment_id .case_id .timing .debt_target .meta

    assert(nargin >= 2 && isstruct(opts), 'kv_fiscal_spec: opts required');
    T   = req(opts, 'T');
    rho = getdef(opts, 'rho_bar', 0.90);
    Tc  = getdef(opts, 'consolidation_start', 10);       % START DATE
    Hc  = getdef(opts, 'consolidation_half_life', 10);   % HALF-LIFE
    ktol= getdef(opts, 'kappa_tol', 1e-8);
    axi = getdef(opts, 'consolidation_scale', 0);
    t   = 1:T;

    assert(Tc >= 1 && Tc <= T, 'consolidation_start out of range');
    assert(Hc > 0, 'consolidation_half_life must be positive');
    % T_c and H_c are DIFFERENT parameters. The baseline sets both to 10 by
    % coincidence, not by identity, and this assertion exists so that a later
    % robustness setting cannot collapse them by accident.

    % CONSOLIDATION SHAPE h_t: zero until T_c, then geometric decay with
    % half-life H_c. Normalised so h(T_c) = 1, which makes a_xi readable as
    % the surcharge at its start date in the same units as g.
    shape = zeros(1, T);
    on = t >= Tc;
    shape(on) = (2^(-1/Hc)) .^ (t(on) - Tc);

    switch upper(caseid)
        case 'C1'
            phi = ones(1, T);
            shp = zeros(1, T); a = 0;
            mode = 'free'; ktgt = 1;
            timing = 'contemporaneous'; dtgt = 'baseline (pinned by the rule)';

        case 'C2'
            phi = 1 - rho.^t;
            shp = shape; a = axi;
            % The target is on REALIZED terminal debt relative to C1, reached
            % by solving for `a`. kappa_mode = 'target' is a REPORTING flag:
            % it changes nothing the transition solver does.
            mode = 'target'; ktgt = getdef(opts, 'kappa_target', 1);
            timing = 'delayed'; dtgt = 'matched to C1 via a_xi';

        case 'C4'
            phi = 1 - rho.^t;                      % no consolidation
            shp = zeros(1, T); a = 0;
            % FREE. C4's dilution is MEASURED. Verifying that it reproduces
            % the pre-refactor legacy value is a parity check on the
            % refactor; making it a target would make the ratchet endogenous
            % to the timing treatment and destroy the contrast.
            mode = 'free'; ktgt = NaN;
            timing = 'delayed'; dtgt = 'ratcheted (outcome, not imposed)';

        case 'C3'
            error('kv_fiscal_spec:C3withdrawn', ...
                ['C3 is INFEASIBLE and has been withdrawn. Under the ' ...
                 'contemporaneous service rule tau_t = r^ss b_t + g_t the ' ...
                 'primary balance is zero at every date, so detrended ' ...
                 'nominal debt is constant and the terminal stock cannot be ' ...
                 'ratcheted (see the derivation in the header of this file). ' ...
                 'The feasible design is C1, C2, C4.']);

        otherwise
            error('kv_fiscal_spec: unknown case %s', caseid);
    end

    fs = struct( ...
        'phi_path', phi, ...
        'consolidation_shape', shp, ...
        'consolidation_scale', a, ...
        'consolidation_path', a * shp, ...
        'kappa_mode', mode, ...
        'kappa_target', ktgt, ...
        'kappa_tol', ktol, ...
        'experiment_id', sprintf('%s_rho%.3f_Tc%d_Hc%d_a%.6g', ...
                                 upper(caseid), rho, Tc, Hc, a), ...
        'case_id', upper(caseid), ...
        'caseid', upper(caseid), ...
        'timing', timing, ...
        'debt_target', dtgt, ...
        'meta', struct('T', T, 'rho_bar', rho, ...
                       'consolidation_start', Tc, ...
                       'consolidation_half_life', Hc, ...
                       'kappa_tol', ktol));
end

function v = req(s, f)
    assert(isfield(s, f) && ~isempty(s.(f)), 'kv_fiscal_spec: %s is required', f);
    v = s.(f);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end
