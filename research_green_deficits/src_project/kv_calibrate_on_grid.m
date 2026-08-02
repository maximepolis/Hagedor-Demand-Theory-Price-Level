function C = kv_calibrate_on_grid(gridspec, calopts)
% KV_CALIBRATE_ON_GRID  The calibration, callable (decision D10).
%
% NOT A SECOND IMPLEMENTATION. Every equation, target, tolerance and
% parameter update is in calib_beta / calib_beta_chi / solve_own_kv, which
% were MOVED out of main_twoasset_ownership_kv's local-function block into
% src_project so that both the production script and Track B of the
% certification protocol call the same code. This function is a typed
% interface around them and contains no calibration logic of its own.
%
% INPUT   gridspec  .nb .nk           node counts (required)
%                   .bGrid .kGrid     explicit grids, overriding nb/nk
%                   .xGridA .acGrid .sGrid   optional overrides
%                   .p_base           params carrying the curvature family
%         calopts   .r_b .d_base .D0 .Bnom .Kbar .iota_H .b_targ_H .q_ref
%                   .W_targ           [] = 1D (beta only); scalar = 2D
%                   .theta0           optional initial parameter vector
%                                     [beta] or [beta chi_b]
%                   .tag              string for the log
%
% OUTPUT  C .theta        calibrated [beta] or [beta chi_b]
%           .p            the full parameter struct as calibrated
%           .eq0          the calibrated equilibrium
%           .target_err   signed errors on the declared targets
%           .untargeted   moments NOT targeted (HtM, top1, top10, W, omega)
%           .diag         solver diagnostics and convergence status
%           .provenance   grid, targets, bounds, tolerances, code version
%
% Deterministic: no RNG use, no base-workspace reads.

    assert(nargin >= 2, 'kv_calibrate_on_grid(gridspec, calopts)');
    C = struct('ok', false, 'msg', '');

    % ---- grids ---------------------------------------------------------
    p = req(gridspec, 'p_base');
    if isfield(gridspec,'bGrid') && ~isempty(gridspec.bGrid)
        p.bGrid = gridspec.bGrid(:);
    else
        [lo,hi,g] = kv_grid_curv(p.bGrid);
        p.bGrid = kv_grid_build(lo, hi, g, req(gridspec,'nb'));
    end
    if isfield(gridspec,'kGrid') && ~isempty(gridspec.kGrid)
        p.kGrid = gridspec.kGrid(:);
    else
        [lo,hi,g] = kv_grid_curv(p.kGrid);
        p.kGrid = kv_grid_build(lo, hi, g, req(gridspec,'nk'));
    end
    for f = {'xGridA','acGrid','sGrid'}
        if isfield(gridspec, f{1}) && ~isempty(gridspec.(f{1}))
            p.(f{1}) = gridspec.(f{1});
        end
    end

    % ---- initial parameter vector --------------------------------------
    th0 = getdef(calopts, 'theta0', []);
    if ~isempty(th0)
        p.beta = th0(1);
        if numel(th0) > 1, p.chi_b = th0(2); end
    end

    r_b = req(calopts,'r_b');   d = req(calopts,'d_base');
    D0  = req(calopts,'D0');    Bnom = req(calopts,'Bnom');
    Kbar= req(calopts,'Kbar');  iota = req(calopts,'iota_H');
    btH = req(calopts,'b_targ_H'); qref = req(calopts,'q_ref');
    Wt  = getdef(calopts,'W_targ', []);
    t0  = tic;

    % ---- THE calibration, from the moved files -------------------------
    try
        if isempty(Wt)
            [bstar, eq0] = calib_beta(r_b, d, D0, 0, 0, Bnom, Kbar, btH, iota, p, qref, t0);
            p.beta = bstar; theta = bstar;
        else
            [bstar, cstar, eq0] = calib_beta_chi(r_b, d, D0, 0, 0, Bnom, Kbar, ...
                                       btH, Wt, iota, p, qref, t0);
            p.beta = bstar; p.chi_b = cstar; theta = [bstar cstar];
        end
    catch ME
        C.msg = sprintf('calibration errored: %s', ME.message);
        C.provenance = provenance(p, calopts, gridspec);
        return;
    end
    if isempty(eq0) || ~isstruct(eq0) || ~eq0.ok
        C.msg = 'calibration did not converge to an admissible equilibrium';
        C.theta = theta; C.p = p; C.eq0 = eq0;
        C.provenance = provenance(p, calopts, gridspec);
        return;
    end

    % ---- targets and untargeted moments --------------------------------
    Wtot  = eq0.Sb + eq0.q*Kbar;
    omega = eq0.Sb / max(Wtot, eps);
    C.target_err = struct('Sb_direct', eq0.Sb - btH);
    if ~isempty(Wt)
        C.target_err.W_total = Wtot - Wt;
        C.target_err.omega   = omega - btH/Wt;
    end
    H = htm_bk(eq0.dist, eq0.bch, eq0.kch, eq0.q, ...
               getdef(calopts,'htm_b',0.02), getdef(calopts,'whtm_k',0.50));
    C.untargeted = struct('W_total', Wtot, 'omega', omega, ...
                          'htm', H.htm, 'whtm', H.whtm, 'phtm', H.phtm, ...
                          'top10', H.top10, 'top1', H.top1, ...
                          'q', eq0.q, 'P', eq0.P, 'div', eq0.div, ...
                          'yield', d/max(eq0.q,eps));
    C.diag = struct('seconds', toc(t0), 'min_c', eq0.min_c, ...
                    'n_infeas', eq0.n_infeas, 'ksat', eq0.ksat);
    C.theta = theta; C.p = p; C.eq0 = eq0; C.ok = true;
    C.provenance = provenance(p, calopts, gridspec);
end

% =====================================================================
function pr = provenance(p, calopts, gridspec)
% Everything needed to reproduce this calibration, recorded whether it
% succeeded or not. A failed cell that cannot be reproduced is not a
% recoverable observation.
    [blo,bhi,gb] = kv_grid_curv(p.bGrid);
    [klo,khi,gk] = kv_grid_curv(p.kGrid);
    pr = struct( ...
      'nb', numel(p.bGrid), 'nk', numel(p.kGrid), ...
      'b_lo', blo, 'b_hi', bhi, 'b_curv', gb, ...
      'k_lo', klo, 'k_hi', khi, 'k_curv', gk, ...
      'nx', numel(p.xGridA), 'nac', numel(p.acGrid), 'nsh', numel(p.sGrid), ...
      'targets', struct('b_targ_H', getdef(calopts,'b_targ_H',NaN), ...
                        'W_targ',   getdef(calopts,'W_targ',[])), ...
      'tolerances', struct('tol_vfi', getf(p,'tol_vfi',NaN), ...
                           'tol_dist', getf(p,'tol_dist',NaN), ...
                           'maxit_vfi', getf(p,'maxit_vfi',NaN), ...
                           'maxit_dist', getf(p,'maxit_dist',NaN)), ...
      'fixed', struct('lambda_adj', getf(p,'lambda_adj',NaN), ...
                      'zeta_b', getf(p,'zeta_b',NaN), ...
                      'bbar_liq', getf(p,'bbar_liq',NaN), ...
                      'div_payout', getf(p,'div_payout',NaN), ...
                      'sigma', getf(p,'sigma',NaN)), ...
      'tag', getdef(calopts,'tag',''), ...
      'code_version', code_version(), ...
      'gridspec_fields', {fieldnames(gridspec)});
end

function v = code_version()
% Best-effort git description; '' when git is unavailable, never an error.
    v = '';
    try
        [st, out] = system('git rev-parse --short HEAD');
        if st == 0, v = strtrim(out); end
    catch
    end
end

function v = req(s, f)
    assert(isfield(s, f) && ~isempty(s.(f)), 'kv_calibrate_on_grid: %s required', f);
    v = s.(f);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end

function v = getf(s, f, dv)
    if isstruct(s) && isfield(s, f), v = s.(f); else, v = dv; end
end
