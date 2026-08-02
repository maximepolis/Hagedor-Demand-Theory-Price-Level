function G = kv_gate_report(E, CTX, opts)
% KV_GATE_REPORT  Evaluate the per-equilibrium gates of the round-10 two-asset
% acceptance protocol against one solved equilibrium.
%
% ONE PLACE, ONE SET OF THRESHOLDS. Every driver that reports a two-asset
% equilibrium calls this and reports what it returns. No driver re-implements
% a tolerance, because a tolerance that exists in two places is a tolerance
% that will eventually differ in two places -- and the failure mode is silent:
% a table passes under a threshold no one remembers loosening.
%
% The thresholds here are the ones written into
% NUMERICAL_ACCEPTANCE_TWO_ASSET_R10.md before any certification run. Changing
% one is a separate commit, made before the run that uses it, with its reason.
% Do not add an options field that overrides a threshold.
%
% Gates 1-10 and 20 are per-equilibrium and evaluated here. Gates 11-19 are
% ACROSS runs (grid matrix, curvature, bounds, dispersed starts, independent
% method) and belong to the certification driver, which is why they are absent
% from this function rather than stubbed inside it.
%
% INPUT  E    a solved equilibrium from kv_solve_alpha (needs .P .q .Sb .Sk
%             .Fb .Fk .dist .sol, and optionally .dV .ddist .dist_loose)
%        CTX  the economy (p, iota, r_b, d_base, D0, Bnom, Kbar, g_real)
%        opts .Trev  total real tax revenue        (for gate 3)
%             .DS    real debt service r*b         (for gate 3)
%             .polstable  fraction of adjuster candidates that moved between
%                         the last two outer iterations (gate 6); NaN if the
%                         solver did not record it
%
% OUTPUT G.pass       all per-equilibrium gates pass
%        G.rows       one row per gate: name, value, threshold, pass
%        G.metric     struct of the raw normalized metrics

    if nargin < 3, opts = struct(); end
    T = thresholds();
    m = struct();

    % ---- normalizations -------------------------------------------------
    Y    = 1 - CTX.D0;                       % mean effective endowment
    Sb   = E.Sb;  Kbar = CTX.Kbar;
    Trev = getdef(opts, 'Trev', NaN);
    DS   = getdef(opts, 'DS',   NaN);

    % ---- gates 1-3: market residuals, three normalizations ---------------
    m.res_b_rel   = abs(E.Fb) / max(abs(Sb),   eps);
    m.res_k_rel   = abs(E.Fk) / max(abs(Kbar), eps);
    m.res_b_rev   = abs(E.Fb) / max(abs(Trev), eps);
    m.res_k_rev   = abs(E.Fk) / max(abs(Trev), eps);
    m.res_b_ds    = abs(E.Fb) / max(abs(DS),   eps);
    m.res_k_ds    = abs(E.Fk) / max(abs(DS),   eps);
    m.res_b_y     = abs(E.Fb) / max(abs(Y),    eps);
    m.res_k_y     = abs(E.Fk) / max(abs(Y),    eps);

    % ---- gates 4-6: solver convergence -----------------------------------
    m.dV        = getf(E, 'dV',    NaN);
    m.ddist     = getf(E, 'ddist', NaN);
    m.distloose = getf(E, 'dist_loose', false);
    m.polstable = getdef(opts, 'polstable', NaN);

    % ---- gates 7-10: distribution health ---------------------------------
    [m.ksat, m.bsat, m.kocc, m.bocc] = ...
        kv_boundary_mass(E.dist, CTX.p.kGrid, CTX.p.bGrid);
    m.mass_err = abs(1 - sum(E.dist(:)));

    % ---- gate 20: economic admissibility ---------------------------------
    occ = E.dist > 0;
    cn  = E.sol.polCn;
    if any(occ(:)), m.min_c = min(cn(occ)); else, m.min_c = min(cn(:)); end
    m.min_c = min(m.min_c, min(E.sol.polCa(:)));
    pol = {E.sol.polBa, E.sol.polKa, E.sol.polCa, E.sol.polBn, E.sol.polCn};
    m.pol_finite = all(cellfun(@(x) all(isfinite(x(:))), pol));

    % ---- assemble --------------------------------------------------------
    R = {};
    R = add(R, 1,  'bond residual / S_b',        m.res_b_rel,  T.res_rel, '<');
    R = add(R, 2,  'tree residual / Kbar',       m.res_k_rel,  T.res_rel, '<');
    R = add(R, 3,  'max residual / tax revenue', max(m.res_b_rev, m.res_k_rev), T.res_fiscal, '<');
    R = add(R, 3.1,'max residual / debt service',max(m.res_b_ds,  m.res_k_ds),  T.res_fiscal, '<');
    R = add(R, 4,  'VFI sup-norm',               m.dV,         T.dV,        '<');
    R = add(R, 5,  'distribution sup-norm',      m.ddist,      T.ddist,     '<');
    R = add(R, 5.1,'distribution not loose',     double(~m.distloose), 0.5, '>');
    R = add(R, 6,  'adjuster policy churn',      m.polstable,  T.polstable, '<=');
    R = add(R, 7,  'liquid top-two-node mass',   m.bsat,       T.boundary,  '<');
    R = add(R, 8,  'illiquid top-two-node mass', m.ksat,       T.boundary,  '<');
    R = add(R, 9,  'occupied support, liquid',   m.bocc,       T.occupancy, '<');
    R = add(R, 9.1,'occupied support, illiquid', m.kocc,       T.occupancy, '<');
    R = add(R, 10, 'mass conservation',          m.mass_err,   T.mass,      '<');
    R = add(R, 20, 'min consumption on support', m.min_c,      T.min_c,     '>');
    R = add(R, 20.1,'policies finite',           double(m.pol_finite), 0.5, '>');

    G = struct('rows', {R}, 'metric', m, 'thresholds', T);
    ok = true;
    for i = 1:numel(R)
        if ~R{i}.pass && ~isnan(R{i}.value), ok = false; end
        if isnan(R{i}.value), ok = false; end   % unmeasured is not passed
    end
    G.pass = ok;
end

% =====================================================================
function T = thresholds()
% The round-10 protocol, written once. NaN is never a pass.
    T = struct( ...
        'res_rel',    1e-6, ...   % gates 1-2
        'res_fiscal', 1e-5, ...   % gate 3
        'dV',         1e-8, ...   % gate 4
        'ddist',      1e-11, ...  % gate 5
        'polstable',  0, ...      % gate 6, exact
        'boundary',   1e-4, ...   % gates 7-8
        'occupancy',  0.90, ...   % gate 9
        'mass',       1e-12, ...  % gate 10
        'min_c',      1e-8);      % gate 20
end

function R = add(R, id, name, val, thr, rel)
    switch rel
        case '<',  p = isfinite(val) && val <  thr;
        case '<=', p = isfinite(val) && val <= thr;
        case '>',  p = isfinite(val) && val >  thr;
        otherwise, error('kv_gate_report: unknown relation %s', rel);
    end
    R{end+1} = struct('id', id, 'name', name, 'value', val, ...
                      'threshold', thr, 'rel', rel, 'pass', p);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end

function v = getf(S, f, dv)
    if isstruct(S) && isfield(S, f), v = S.(f); else, v = dv; end
end
