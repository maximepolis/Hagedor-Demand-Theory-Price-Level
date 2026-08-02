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
    C = struct('ok', false, 'success', false, 'msg', '');

    % FAILED PARAMETER EVALUATIONS ARE KEPT, NOT DISCARDED. A cell that failed
    % is an observation about where the model stops being solvable, and
    % throwing it away is how a grid sweep comes to look better than it is.
    %
    % SCOPE, STATED HONESTLY: the inner search lives inside calib_beta /
    % calib_beta_chi, which are under the D10 parity freeze -- they were MOVED
    % verbatim, and adding a trace hook to them now would destroy exactly the
    % property the parity test is checking. So this container currently records
    % the failures VISIBLE AT THIS LEVEL (an errored call, a non-convergent
    % equilibrium, a gate failure), not every interior theta the search tried.
    % Instrumenting the inner search is a follow-up change, to be made AFTER
    % D10 parity passes and re-verified against the same baseline.
    C.failed_evals = struct('theta', {}, 'stage', {}, 'reason', {});

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
        C.failed_evals(end+1) = struct('theta', th0, 'stage', 'search', ...
                                       'reason', ME.message);
        C.provenance = provenance(p, calopts, gridspec);
        C.grid = struct('nb', numel(p.bGrid), 'nk', numel(p.kGrid), ...
                        'bGrid', p.bGrid, 'kGrid', p.kGrid, ...
                        'state', kv_grid_state(p));
        C.solver = struct('seconds', toc(t0), 'exitflag', -1, ...
                          'failed_evals', C.failed_evals, ...
                          'n_failed_evals', numel(C.failed_evals), 'msg', C.msg);
        return;
    end
    if isempty(eq0) || ~isstruct(eq0) || ~eq0.ok
        C.msg = 'calibration did not converge to an admissible equilibrium';
        C.failed_evals(end+1) = struct('theta', theta, 'stage', 'equilibrium', ...
                                       'reason', getf2(eq0, 'msg', 'eq0.ok false'));
        C.theta = theta; C.p = p; C.eq0 = eq0;
        C.provenance = provenance(p, calopts, gridspec);
        C.grid = struct('nb', numel(p.bGrid), 'nk', numel(p.kGrid), ...
                        'bGrid', p.bGrid, 'kGrid', p.kGrid, ...
                        'state', kv_grid_state(p));
        C.solver = struct('seconds', toc(t0), 'exitflag', 0, ...
                          'failed_evals', C.failed_evals, ...
                          'n_failed_evals', numel(C.failed_evals), 'msg', C.msg);
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
    C.theta = theta; C.p = p; C.eq0 = eq0;
    C.provenance = provenance(p, calopts, gridspec);

    % =================================================================
    % THE OUTPUT CONTRACT (R11). Track A and Track B must be able to write a
    % cell record without reading the base workspace or re-deriving anything,
    % so everything they need is named here rather than left implicit in eq0.
    % Legacy fields above are retained so existing callers keep working.
    % =================================================================
    C.inputs  = struct('r_b', r_b, 'd_base', d, 'D0', D0, 'Bnom', Bnom, ...
                       'Kbar', Kbar, 'iota_H', iota, 'b_targ_H', btH, ...
                       'q_ref', qref, 'W_targ', Wt, ...
                       'htm_b', getdef(calopts,'htm_b',0.02), ...
                       'whtm_k', getdef(calopts,'whtm_k',0.50));
    C.grid    = struct('bGrid', p.bGrid, 'kGrid', p.kGrid, ...
                       'xGridA', p.xGridA, 'acGrid', p.acGrid, ...
                       'sGrid', p.sGrid, 'eGrid', p.eGrid, ...
                       'nb', numel(p.bGrid), 'nk', numel(p.kGrid), ...
                       'nx', numel(p.xGridA), 'nac', numel(p.acGrid), ...
                       'nsh', numel(p.sGrid), 'ne', numel(p.eGrid), ...
                       'state', kv_grid_state(p));
    C.options = calopts;
    C.parameters_initial = th_struct(th0, p);
    C.parameters_final   = struct('beta', p.beta, 'chi_b', p.chi_b, ...
                       'zeta_b', getf(p,'zeta_b',NaN), ...
                       'bbar_liq', getf(p,'bbar_liq',NaN), ...
                       'lambda_adj', getf(p,'lambda_adj',NaN), ...
                       'div_payout', getf(p,'div_payout',NaN), ...
                       'sigma', getf(p,'sigma',NaN));
    C.bounds  = getdef(calopts, 'bounds', ...
                       struct('beta', [0.85 0.995], 'chi_b', [0 0.05], ...
                              'source', 'default; override via calopts.bounds'));
    C.targets = struct('b_targ_H', btH, 'W_targ', Wt);
    C.target_errors = C.target_err;
    C.untargeted_moments = C.untargeted;
    C.equilibrium = eq0;
    C.policies = struct();
    if isfield(eq0,'sol') && isstruct(eq0.sol)
        for f = {'V','polBa','polKa','polCa','polBn','polCn'}
            if isfield(eq0.sol, f{1}), C.policies.(f{1}) = eq0.sol.(f{1}); end
        end
    end
    C.distribution = getf(eq0, 'dist', []);
    C.market_residuals = struct( ...
        'F_k', getf(eq0,'Sk',NaN) - Kbar, ...
        'F_b', getf(eq0,'Sb',NaN) - iota*Bnom/max(getf(eq0,'P',NaN),eps), ...
        'mass_err', abs(1 - sum(getf(eq0,'dist',0), 'all')));
    [ks, bs, ko, bo] = kv_boundary_mass(eq0.dist, p.kGrid, p.bGrid);
    C.boundary_masses = struct('k_top2', ks, 'b_top2', bs, ...
                               'k_occupancy', ko, 'b_occupancy', bo);

    % FINANCING RESULTS. dP = P^LEV - P^LS is the object the paper reports and
    % the object Gate 11 normalises by, so a calibration record without it
    % forces every downstream consumer to re-solve two equilibria itself.
    C.financing_results = struct('ran', false, 'P_LS', NaN, 'P_LEV', NaN, ...
        'dP', NaN, 'dlnP', NaN, 'ok_LS', false, 'ok_LEV', false, 'msg', '');
    if getdef(calopts, 'do_financing', true)
        try
            g_real = getdef(calopts, 'g_real', NaN);
            if ~isfinite(g_real) && isfield(calopts,'Gg')
                g_real = calopts.Gg / eq0.P;
            end
            if isfinite(g_real)
                qw = getdef(calopts, 'qwin', [0.85 1.20]);
                eLS = solve_own_kv(r_b,d,D0,g_real,0,Bnom,Kbar,iota,p,eq0.q,false,qw);
                eLV = solve_own_kv(r_b,d,D0,g_real,1,Bnom,Kbar,iota,p,eq0.q,false,qw);
                C.financing_results.ran = true;
                C.financing_results.ok_LS  = eLS.ok;
                C.financing_results.ok_LEV = eLV.ok;
                if eLS.ok && eLV.ok
                    C.financing_results.P_LS  = eLS.P;
                    C.financing_results.P_LEV = eLV.P;
                    C.financing_results.dP    = eLV.P - eLS.P;
                    C.financing_results.dlnP  = log(eLV.P/eLS.P);
                end
                C.financing_results.eq_LS = eLS;
                C.financing_results.eq_LEV = eLV;
            else
                C.financing_results.msg = 'no g_real or Gg supplied';
            end
        catch ME
            C.financing_results.msg = ME.message;
        end
    end

    C.solver = struct('seconds', toc(t0), ...
                      'min_c', getf(eq0,'min_c',NaN), ...
                      'n_infeas', getf(eq0,'n_infeas',NaN), ...
                      'exitflag', 1, ...
                      'code', getf(eq0,'code',''), ...
                      'msg', getf(eq0,'msg',''), ...
                      'failed_evals', C.failed_evals, ...
                      'n_failed_evals', numel(C.failed_evals));

    % SUCCESS IS NOT THE OPTIMIZER'S EXIT FLAG. A calibration that converged
    % onto a boundary-truncated distribution, or left a market residual the
    % financing signal cannot be measured against, is not a valid calibration
    % however cleanly the search terminated. The gates are named individually
    % so a failure says which one bit.
    gt = getdef(calopts, 'gates', struct());
    tol_b   = getdef(gt, 'boundary',  1e-4);
    tol_Fk  = getdef(gt, 'F_k',       1e-3);
    tol_tgt = getdef(gt, 'target',    1e-4);
    tol_m   = getdef(gt, 'mass',      1e-8);
    C.gates = struct( ...
      'equilibrium_ok', logical(eq0.ok), ...
      'target_met',     abs(C.target_err.Sb_direct) <= tol_tgt, ...
      'k_boundary',     C.boundary_masses.k_top2 <= tol_b, ...
      'b_boundary',     C.boundary_masses.b_top2 <= tol_b, ...
      'tree_residual',  abs(C.market_residuals.F_k) <= tol_Fk, ...
      'mass_conserved', C.market_residuals.mass_err <= tol_m, ...
      'consumption_positive', getf(eq0,'min_c',-Inf) > 0, ...
      'tolerances', struct('boundary',tol_b,'F_k',tol_Fk,'target',tol_tgt,'mass',tol_m));
    gn = {'equilibrium_ok','target_met','k_boundary','b_boundary', ...
          'tree_residual','mass_conserved','consumption_positive'};
    fail = gn(~cellfun(@(n) C.gates.(n), gn));
    C.gates.failed = fail;
    C.success = isempty(fail);
    C.ok = C.success;                    % legacy alias, now gate-aware
    if ~C.success
        C.msg = sprintf('calibration gates failed: %s', strjoin(fail, ', '));
    end
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

function T = th_struct(th0, p)
% The STARTING parameter vector, distinguished from the calibrated one. When
% no theta0 was supplied the search started from whatever p carried, so that
% is what is recorded -- an empty field here would misreport the run as having
% had no starting point.
    if ~isempty(th0)
        T = struct('beta', th0(1), 'source', 'calopts.theta0');
        if numel(th0) > 1, T.chi_b = th0(2); else, T.chi_b = getf(p,'chi_b',NaN); end
    else
        T = struct('beta', getf(p,'beta',NaN), 'chi_b', getf(p,'chi_b',NaN), ...
                   'source', 'p_base (no theta0 supplied)');
    end
end

function v = getf2(s, f, dv)
    v = dv;
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); end
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
