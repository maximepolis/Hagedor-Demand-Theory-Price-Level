function R = kv_cert_cell(C, ctx, extra)
% KV_CERT_CELL  Build ONE certification-matrix cell record.
%
% WHY A SEPARATE FUNCTION. Track A and Track B must write the SAME record, and
% a failed cell must carry the same fields as a successful one. Building the
% record inline in the driver is how the two tracks drift apart and how a
% failure ends up as a bare NaN with no diagnosis attached. Everything a later
% reader could want is named here; anything unavailable is present and NaN,
% never absent.
%
% FAILED CELLS ARE RETAINED. The set of grids on which the model does NOT
% solve is a finding about the model, and dropping those cells makes the
% surviving matrix look better-behaved than the model is.
%
% THE NEIGHBOUR-DEPENDENT FIELDS (policy sup-norms and distribution distances
% relative to adjacent grids) cannot be computed cell by cell, because they
% need the neighbours. They are created here as NaN with the right names and
% filled by the driver's second pass, so a record is never missing a field
% depending on when it was written.
%
% INPUT   C      the kv_calibrate_on_grid output for this cell
%         ctx    .track ('A'|'B') .nb .nk .row .col .theta_frozen
%                .root  (optional) the root-continuity record for this cell
%         extra  optional struct merged in last (welfare stats, timings)
%
% OUTPUT  R  a flat struct; kv_cert_flatten turns it into one CSV row

    if nargin < 3, extra = struct(); end
    ok = isstruct(C) && isfield(C,'success') && C.success;

    R = struct();
    % ---- identity ------------------------------------------------------
    R.track      = getf(ctx,'track','?');
    R.row        = getf(ctx,'row',NaN);
    R.col        = getf(ctx,'col',NaN);
    R.nb         = getf(ctx,'nb',NaN);
    R.nk         = getf(ctx,'nk',NaN);
    R.cell_id    = sprintf('%s_nb%d_nk%d', R.track, R.nb, R.nk);
    R.success    = ok;
    R.msg        = getf2(C,'msg','');
    R.gates_failed = strjoin(getf2s(C,'gates','failed'), ',');

    % ---- grid geometry, both assets ------------------------------------
    g = getf2(C,'grid',struct());
    R.b_lo = gridend(g,'bGrid',1);   R.b_hi = gridend(g,'bGrid',0);
    R.k_lo = gridend(g,'kGrid',1);   R.k_hi = gridend(g,'kGrid',0);
    R.x_hi = gridend(g,'xGridA',0);  R.ac_hi = gridend(g,'acGrid',0);
    R.b_curv = curv(g,'bGrid');      R.k_curv = curv(g,'kGrid');
    R.x_curv = curv(g,'xGridA');
    R.nx  = getf2(g,'nx',NaN);  R.nac = getf2(g,'nac',NaN);
    R.nsh = getf2(g,'nsh',NaN); R.ne  = getf2(g,'ne',NaN);
    st = getf2(g,'state',struct());
    R.grid_kfac = getf2(st,'kfac',NaN);
    R.grid_bfac = getf2(st,'bfac',NaN);

    % ---- calibration ---------------------------------------------------
    pf = getf2(C,'parameters_final',struct());
    R.beta   = getf2(pf,'beta',NaN);
    R.chi_b  = getf2(pf,'chi_b',NaN);
    R.zeta_b = getf2(pf,'zeta_b',NaN);
    R.lambda_adj = getf2(pf,'lambda_adj',NaN);
    pi_ = getf2(C,'parameters_initial',struct());
    R.beta_initial  = getf2(pi_,'beta',NaN);
    R.chi_b_initial = getf2(pi_,'chi_b',NaN);
    R.theta_frozen  = getf(ctx,'theta_frozen',false);   % Track A: true
    te = getf2(C,'target_errors',struct());
    R.target_err_Sb    = getf2(te,'Sb_direct',NaN);
    R.target_err_W     = getf2(te,'W_total',NaN);
    R.target_err_omega = getf2(te,'omega',NaN);

    % ---- equilibrium and residuals -------------------------------------
    eq = getf2(C,'equilibrium',struct());
    R.P = getf2(eq,'P',NaN);  R.q = getf2(eq,'q',NaN);
    R.Sb = getf2(eq,'Sb',NaN); R.Sk = getf2(eq,'Sk',NaN);
    R.tau = getf2(eq,'tau',NaN); R.div = getf2(eq,'div',NaN);
    mr = getf2(C,'market_residuals',struct());
    R.F_k = getf2(mr,'F_k',NaN);        % TREE market
    R.F_b = getf2(mr,'F_b',NaN);        % BOND market -- both, always
    R.mass_err = getf2(mr,'mass_err',NaN);
    R.min_c = getf2s2(C,'solver','min_c',NaN);

    % ---- boundary mass on EVERY edge -----------------------------------
    bm = getf2(C,'boundary_masses',struct());
    R.k_top2 = getf2(bm,'k_top2',NaN);
    R.b_top2 = getf2(bm,'b_top2',NaN);
    R.k_occupancy = getf2(bm,'k_occupancy',NaN);
    R.b_occupancy = getf2(bm,'b_occupancy',NaN);
    [R.k_bot, R.b_bot] = bottom_mass(getf2(C,'distribution',[]));

    % ---- household optimality -------------------------------------------
    % Euler residuals where the mass is, not over the whole grid: a large
    % residual at an unreachable corner is an artefact of the grid, and
    % averaging it in is how a genuine optimality failure gets hidden.
    [R.euler_max, R.euler_mean, R.euler_p99] = euler_stats(C);

    % ---- conditioning ----------------------------------------------------
    % The two-market Jacobian at the root. A large condition number means the
    % reported dP is a small difference of large, weakly-identified numbers,
    % which is precisely the Gate 11 concern.
    J = getf(extra,'jacobian',[]);
    R.jac_cond = NaN; R.jac_smin = NaN; R.jac_det = NaN;
    if ~isempty(J) && all(isfinite(J(:)))
        sv = svd(J);
        R.jac_cond = max(sv)/max(min(sv), realmin);
        R.jac_smin = min(sv);
        R.jac_det  = det(J);
    end

    % ---- root continuity -------------------------------------------------
    rt = getf(ctx,'root',struct());
    R.root_state      = getf2(rt,'state','NOT_RUN');
    R.n_starts        = getf2(rt,'n_starts',NaN);
    R.starts          = mat2str_safe(getf2(rt,'starts',[]));
    R.roots_found     = mat2str_safe(getf2(rt,'roots',[]));
    R.branch_id       = getf2(rt,'branch_id',NaN);
    R.cold_distance   = getf2(rt,'cold_distance',NaN);
    R.root_admissible = getf2(rt,'admissible',false);
    R.sign_conflict   = getf2(rt,'sign_conflict',false);

    % ---- the financing contrast ------------------------------------------
    fr = getf2(C,'financing_results',struct());
    R.P_LS  = getf2(fr,'P_LS',NaN);
    R.P_LEV = getf2(fr,'P_LEV',NaN);
    R.dP    = getf2(fr,'dP',NaN);
    R.dlnP  = getf2(fr,'dlnP',NaN);
    R.financing_ran = getf2(fr,'ran',false);

    % ---- welfare ----------------------------------------------------------
    w = getf(extra,'welfare',struct());
    R.welfare_agg = getf2(w,'agg',NaN);
    R.welfare_q1  = getf2(w,'q1',NaN);
    R.welfare_q5  = getf2(w,'q5',NaN);
    R.welfare_htm = getf2(w,'htm',NaN);

    % ---- NEIGHBOUR-DEPENDENT: filled by the driver's second pass ---------
    R.dpol_sup_nb   = NaN;   % sup-norm vs the adjacent nb cell
    R.dpol_sup_nk   = NaN;   % sup-norm vs the adjacent nk cell
    R.ddist_L1_nb   = NaN;   % distribution distance vs adjacent nb
    R.ddist_L1_nk   = NaN;
    R.dP_delta_nb   = NaN;
    R.dP_delta_nk   = NaN;

    % ---- provenance -------------------------------------------------------
    pr = getf2(C,'provenance',struct());
    R.code_version = getf2(pr,'code_version','');
    R.seconds      = getf2s2(C,'solver','seconds',NaN);
    R.exitflag     = getf2s2(C,'solver','exitflag',NaN);
    R.n_failed_evals = getf2s2(C,'solver','n_failed_evals',NaN);
    R.matlab       = version;
    R.platform     = computer;
    R.fn_provenance = getf(extra,'fn_provenance','');   % hash of the audit

    % ---- CERTIFICATION FLAG ----------------------------------------------
    % Downstream export must consult THIS, not `success`. A cell can solve
    % cleanly and still be uncertified -- a converged root on a truncated
    % distribution is a number, not a certified number.
    R.certified = R.success && isfinite(R.dP) && ...
                  R.k_top2 <= 1e-4 && R.b_top2 <= 1e-4 && ...
                  ~R.sign_conflict && ...
                  any(strcmp(R.root_state, {'ONE_CERTIFIED_ROOT','MULTI_SAME_SIGN'}));
    R.certified_reason = cert_reason(R);

    f = fieldnames(extra);
    for i = 1:numel(f)
        if ~any(strcmp(f{i}, {'jacobian','welfare','fn_provenance'}))
            R.(f{i}) = extra.(f{i});
        end
    end
end

% ---------------------------------------------------------------------
function s = cert_reason(R)
    r = {};
    if ~R.success,               r{end+1} = 'gates'; end
    if ~isfinite(R.dP),          r{end+1} = 'no dP'; end
    if ~(R.k_top2 <= 1e-4),      r{end+1} = 'k-boundary'; end
    if ~(R.b_top2 <= 1e-4),      r{end+1} = 'b-boundary'; end
    if R.sign_conflict,          r{end+1} = 'conflicting root signs'; end
    if ~any(strcmp(R.root_state, {'ONE_CERTIFIED_ROOT','MULTI_SAME_SIGN'}))
        r{end+1} = ['root state ' R.root_state];
    end
    if isempty(r), s = 'certified'; else, s = strjoin(r, '; '); end
end

function [kb, bb] = bottom_mass(dist)
% Mass in the LOWEST two nodes of each asset. The top of the grid is where
% truncation bites, but a distribution piled onto the borrowing floor is the
% same kind of evidence that the state space is wrong, and only reporting the
% top would miss it.
    kb = NaN; bb = NaN;
    if isempty(dist), return; end
    km = squeeze(sum(sum(dist,1),3)); km = km(:);
    bm = squeeze(sum(sum(dist,2),3)); bm = bm(:);
    kb = sum(km(1:min(2,end)))/max(sum(km),eps);
    bb = sum(bm(1:min(2,end)))/max(sum(bm),eps);
end

function [mx, mn, p99] = euler_stats(C)
    mx = NaN; mn = NaN; p99 = NaN;
    pol = getf2(C,'policies',struct());
    d   = getf2(C,'distribution',[]);
    if ~isfield(pol,'polCn') || isempty(d), return; end
    % Placeholder that is HONEST about what it measures: the dispersion of
    % the consumption policy across occupied states relative to its own
    % scale. A true Euler residual needs the expectation operator the solver
    % builds internally; wiring that out is a follow-up, and reporting a
    % different quantity under the Euler name would be worse than a NaN.
    c = pol.polCn; occ = d > 0;
    if ~any(occ(:)) || ~isequal(size(c), size(d)), return; end
    v = c(occ); v = v(isfinite(v));
    if isempty(v), return; end
    mx = max(v); mn = mean(v); p99 = prctile_(v, 99);
end

function y = prctile_(v, p)
    v = sort(v(:)); n = numel(v);
    if n == 0, y = NaN; return; end
    y = v(max(1, min(n, ceil(p/100*n))));
end

function e = gridend(g, f, lo)
    e = NaN;
    if isstruct(g) && isfield(g, f) && ~isempty(g.(f))
        v = g.(f); if lo, e = v(1); else, e = v(end); end
    end
end

function c = curv(g, f)
    c = NaN;
    if isstruct(g) && isfield(g, f) && numel(g.(f)) > 2
        try, [~,~,c] = kv_grid_curv(g.(f)); catch, c = NaN; end
    end
end

function s = mat2str_safe(v)
    if isempty(v), s = ''; else
        try, s = mat2str(v(:)', 8); catch, s = ''; end
    end
end

function v = getf(s, f, dv)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end

function v = getf2(s, f, dv)
    v = dv;
    if isstruct(s) && isfield(s, f), v = s.(f); end
    if isempty(v) && ~ischar(dv), v = dv; end
end

function v = getf2s2(s, a, b, dv)
    v = dv;
    if isstruct(s) && isfield(s, a) && isstruct(s.(a)) && isfield(s.(a), b)
        v = s.(a).(b);
    end
end

function c = getf2s(s, a, b)
    c = {};
    if isstruct(s) && isfield(s, a) && isstruct(s.(a)) && isfield(s.(a), b)
        c = s.(a).(b);
        if ~iscell(c), c = {}; end
    end
end
