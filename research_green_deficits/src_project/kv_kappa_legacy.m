function K = kv_kappa_legacy(pgc, T, rho_bar, verbose)
% KV_KAPPA_LEGACY  Recover the terminal dilution produced by the LEGACY
% delayed-tax run, once, as a REFERENCE VALUE.
%
% ================= ITS ROLE CHANGED IN ROUND 11 =================
% It used to supply kappa_bar as a TARGET, imposed identically on C3 and C4 so
% that the 2x2's ratchet treatment would be assigned independently of the
% timing treatment. That design is withdrawn, because C3 is infeasible: under
% the contemporaneous service rule the primary balance is zero at every date,
% detrended nominal debt is constant, and no terminal ratchet can coexist with
% it (the derivation is in kv_fiscal_spec's header). With C3 gone there is no
% second case on which to impose a common ratchet, and imposing one on C4
% alone would replace C4's own outcome with a number measured elsewhere.
%
% THE TWO SURVIVING PURPOSES, and no others:
%
%   1. RECORD the pre-refactor legacy terminal dilution, so there is a fixed
%      number to compare against.
%   2. VALIDATE that the refactored unconsolidated path (C4) reproduces it.
%      This is a PARITY check on the refactor, not an experimental result.
%
% IT MUST NOT be used to manufacture a separate equilibrium by targeting. Any
% caller that passes K.kappa_bar into a solver as a terminal condition has
% reintroduced the withdrawn design.
%
%     kappa^legacy = B_inf^legacy / B_inf^baseline
%
% where the baseline is the balanced path, whose terminal detrended stock is
% B_0 by construction, so the ratio reduces to the legacy run's own kappa_inf.
% The ratio is formed explicitly anyway, so the definition is visible.
%
% OUTPUT K.kappa_legacy      the dilution (also .kappa_bar, deprecated alias)
%        K.B_inf_legacy, .B_inf_baseline
%        K.cum_tax_shortfall      sum_t (1 - phi_t) g_t, undiscounted
%        K.pv_primary_gap         sum_t (1 - phi_t) g_t / (1+rbar)^t
%        K.dlnP0                  impact price response, log points vs baseline
%        K.P0_legacy, .P0_baseline
%        K.TR_legacy, .TR_baseline    full paths, for the parity comparison
%        K.provenance             formula, role, and the prohibition above

    if nargin < 4, verbose = false; end

    % THE SETUP MUST BE THE LEGACY ONE. This function previously took whatever
    % pgc the caller happened to build -- typically a bare
    % setup_params_green() -- and passed it straight to the solver. With the
    % DEFAULT beta the baseline steady state does not exist: asset demand
    % exceeds debt supply at every price in the solver's [0.5, 1.3] bracket,
    % and the solve fails with "regime TR-BASE: no sign change". Any kappa it
    % had returned would not have been the manuscript's legacy dilution.
    %
    % kv_legacy_transition_setup reproduces main_transition_deficit's
    % construction: calibrated beta, climate_version, D0, Gg_nom, and the FAST
    % asset grid. The pgc ARGUMENT is now used only for its FAST flag and for
    % fields the caller may legitimately override.
    FASTFLAG = isfield(pgc, 'na') && isfield(pgc, 'na_fast') && pgc.na == pgc.na_fast;
    [pgc, opts, calinfo] = kv_legacy_transition_setup(FASTFLAG);
    opts.T = T; opts.verbose = verbose;

    o = opts; o.regime = 'indexed'; o.financing = 'deficit'; o.rho_d = rho_bar;
    TRd = solve_hank_dtpl_transition(pgc, o);
    assert(isstruct(TRd) && isfield(TRd,'phat') && ~isempty(TRd.phat), ...
        'kv_kappa_legacy: the deficit transition produced no path (%s)', msgof(TRd));

    ob = opts; ob.regime = 'indexed'; ob.financing = 'lumpsum'; ob.rho_d = 0;
    TRb = solve_hank_dtpl_transition(pgc, ob);
    assert(isstruct(TRb) && isfield(TRb,'phat') && ~isempty(TRb.phat), ...
        'kv_kappa_legacy: the baseline transition produced no path (%s)', msgof(TRb));

    Binf_l = kappa_terminal(TRd);
    Binf_b = kappa_terminal(TRb);
    kap    = Binf_l / Binf_b;

    % Fiscal size of the delay, in two normalisations. The undiscounted sum is
    % what accumulates onto the stock; the present value is what a household
    % facing the path actually trades off, and the two differ by enough at
    % rho = 0.90 that quoting one for the other would misstate the experiment.
    rbar = (1 + pgc.i_ss) / (1 + pgc.mu) - 1;
    gap  = zeros(1, 0); pvg = NaN; cum = NaN;
    if isfield(TRd,'primary_gap') && ~isempty(TRd.primary_gap)
        gap = TRd.primary_gap(:)';
        tt  = 1:numel(gap);
        cum = sum(gap);
        pvg = sum(gap ./ (1 + rbar).^tt);
    end

    K = struct( ...
        'kappa_legacy',    kap, ...
        'kappa_bar',       kap, ...   % deprecated alias; see the header
        'B_inf_legacy',    Binf_l, ...
        'B_inf_baseline',  Binf_b, ...
        'rho_bar',         rho_bar, ...
        'T',               T, ...
        'kappa_inf_reported', TRd.kappa_inf, ...
        'cum_tax_shortfall',  cum, ...
        'pv_primary_gap',     pvg, ...
        'primary_gap_path',   gap, ...
        'P0_legacy',       TRd.P0, ...
        'P0_baseline',     TRb.P0, ...
        'dlnP0',           log(TRd.phat(1) / TRb.phat(1)), ...
        'TR_legacy',       TRd, ...
        'TR_baseline',     TRb, ...
        'provenance', struct( ...
            'formula', 'B_inf^legacy / B_inf^baseline', ...
            'role',    'REFERENCE VALUE for parity validation of C4', ...
            'prohibited', ['must not be passed to a solver as a terminal ' ...
                           'condition; that was the withdrawn C3/C4 target ' ...
                           'design, and C3 is infeasible'], ...
            'rho_bar', rho_bar, 'T', T, 'calinfo', calinfo));
end

function s = msgof(TR)
    s = '(no message)';
    if isstruct(TR) && isfield(TR,'msg') && ~isempty(TR.msg), s = TR.msg; end
end

function k = kappa_terminal(TR)
% Terminal detrended nominal stock relative to B_0.
    if isfield(TR,'kappa_path') && ~isempty(TR.kappa_path)
        k = TR.kappa_path(end);
    elseif isfield(TR,'kappa_inf')
        k = TR.kappa_inf;
    else
        error('kv_kappa_legacy: the solver returned no terminal stock');
    end
end
