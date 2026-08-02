function K = kv_kappa_legacy(pgc, T, rho_bar, verbose)
% KV_KAPPA_LEGACY  Recover the ratchet size from the legacy delayed-tax run,
% ONCE, before the factorial experiment.
%
% WHY THIS IS A SEPARATE STEP. In a 2x2 factorial the ratchet treatment must
% be assigned independently of the timing treatment. If C4 were allowed to
% define kappa_bar from its own realized terminal stock, the size of the
% ratchet would be endogenous to the timing treatment -- and it would differ
% across grids and initial conditions -- so C4 - C3 and the interaction term
% would not be contrasts of a common treatment. kappa_bar is therefore
% measured here, frozen, stored in metadata, and imposed identically on C3
% and C4.
%
% This is a CALIBRATION STEP FOR THE SIZE OF THE RATCHET. It is not one of the
% four factorial cases and its output is not an experimental result.
%
%     kappa_bar^legacy = B_inf^legacy / B_inf^baseline
%
% where the baseline is the balanced path, whose terminal detrended stock is
% B_0 by construction, so the ratio reduces to the legacy run's own
% kappa_inf -- which the solver already reports as the terminal value of
% kappa_path = b_t * phat_t / B_0. The ratio is formed explicitly anyway, so
% that the definition is visible rather than implied.
%
% OUTPUT K.kappa_bar .B_inf_legacy .B_inf_baseline .rho_bar .T .provenance

    if nargin < 4, verbose = false; end
    o = struct('T', T, 'regime', 'indexed', 'financing', 'deficit', ...
               'rho_d', rho_bar, 'verbose', verbose);
    TRd = solve_hank_dtpl_transition(pgc, o);

    ob = o; ob.financing = 'lumpsum'; ob.regime = 'indexed'; ob.rho_d = 0;
    TRb = solve_hank_dtpl_transition(pgc, ob);

    Binf_l = kappa_terminal(TRd);
    Binf_b = kappa_terminal(TRb);
    K = struct( ...
        'kappa_bar',       Binf_l / Binf_b, ...
        'B_inf_legacy',    Binf_l, ...
        'B_inf_baseline',  Binf_b, ...
        'rho_bar',         rho_bar, ...
        'T',               T, ...
        'kappa_inf_reported', TRd.kappa_inf, ...
        'provenance', struct('formula', 'B_inf^legacy / B_inf^baseline', ...
                             'frozen', true, ...
                             'note', ['measured once, before C1-C4; may not ' ...
                                      'be redefined by any factorial case']));
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
