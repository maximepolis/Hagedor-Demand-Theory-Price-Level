% MAIN_TWOASSET_GRID_CERTIFICATION  The round-10 two-asset acceptance protocol.
%
% STATUS: scaffolded and static-checked. NOT YET RUN. No number it produces
% exists yet, and nothing in the manuscript may cite it until it has run and
% passed.
%
% WHAT IT DECIDES. Whether the two-asset economy can support a quantitative
% claim about the financing contrast. The decision object is not a price but
%
%       dP = P^LEV - P^LS
%
% and the binding question is whether the grid moves dP by less than a tenth
% of dP itself. A residual small relative to P says nothing about that: the
% diagnostic runs already show a pure grid change moving the tree price 7.7%
% while the spread across financing intensities is 0.6% of the same variable.
%
% TWO TRACKS, SEPARATELY BINDING (see NUMERICAL_ACCEPTANCE_TWO_ASSET_R10.md).
%
%   TRACK A  fixed parameters. One frozen calibration vector, evaluated over
%            the whole joint grid matrix. This and only this measures
%            DISCRETIZATION error.
%   TRACK B  recalibrated at every grid to the same declared targets. This
%            measures CALIBRATION ROBUSTNESS, which is weaker and different.
%
% Track A runs first and is reported first. If parameters were re-fitted while
% the grid was refined, a calibration movement could offset a discretization
% error and the pair would look stable while neither was: recalibration has a
% free parameter per target, and convergence must be measured with none. Track
% B's spread is never printed under the word "convergence".
%
% ROOT CONTINUITY. Every cell is solved three ways -- continued from the
% neighbouring coarser cell, and from two dispersed cold starts -- and every
% distinct equilibrium found is recorded. The reported solution is the
% continued one. A cell where a cold start finds a different admissible root
% is flagged MULTIPLE_ROOTS and reports the whole set. A cell whose branches
% disagree on the SIGN of dP fails. No root is ever selected because it
% preserves a desired sign; that rule binds even when one branch looks
% economically sensible, in which case the criterion must have been fixed in
% advance.
%
% USAGE   >> clear; TRACK = 'A'; FAST = true;  main_twoasset_grid_certification
%         >> clear; TRACK = 'A';               main_twoasset_grid_certification
%         >> clear; TRACK = 'B';               main_twoasset_grid_certification
%
% OUTPUT  output/quarantine/twoasset_certification_<TRACK>.mat
%         output/tables/twoasset_certification_<TRACK>.txt
%
% Everything it writes is QUARANTINED until the gate passes.

clearvars -except TRACK FAST PARALLEL NWORKERS NB_LIST NK_LIST; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));

if ~exist('TRACK','var') || isempty(TRACK), TRACK = 'A'; end
if ~exist('FAST','var'), FAST = false; end
if ~exist('PARALLEL','var') || isempty(PARALLEL), PARALLEL = true; end
if ~exist('NWORKERS','var'), NWORKERS = []; end
assert(any(strcmpi(TRACK,{'A','B'})), 'TRACK must be A (fixed) or B (recalibrated)');
TRACK = upper(TRACK);

% ---- the joint refinement matrix, fixed in the protocol -----------------
if ~exist('NB_LIST','var') || isempty(NB_LIST), NB_LIST = [60 78 100]; end
if ~exist('NK_LIST','var') || isempty(NK_LIST), NK_LIST = [34 44 56]; end
if FAST, NB_LIST = [30 38 48]; NK_LIST = [17 22 28]; end

qdir = fullfile(projdir,'output','quarantine');
if ~isfolder(qdir), mkdir(qdir); end
pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, sprintf('twoasset_certification_%s.txt', TRACK));
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});

tee('TWO-ASSET CERTIFICATION, TRACK %s  (%s)\n', TRACK, ...
    ternstr(TRACK=='A', 'fixed parameters: DISCRETIZATION error', ...
                        'recalibrated: CALIBRATION ROBUSTNESS, not convergence'));
tee('QUARANTINED OUTPUT. Nothing here may enter the manuscript until the\n');
tee('protocol passes in full.\n\n');
if TRACK == 'B'
    tee('*** Track B measures calibration robustness. Its spread must never be\n');
    tee('*** reported as numerical convergence and does not satisfy Gate 11.\n\n');
end

% ---- the frozen economy -------------------------------------------------
mf = fullfile(projdir,'output','twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2, 'run main_twoasset_ownership_kv first');
S = load(mf); assert(S.eq0.ok, 'saved benchmark equilibrium not ok');
p0 = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base;
D0 = S.D0; Gg = S.Gg; eq0 = S.eq0;
Bnom = pg.Bnom; Kbar = 1.0; g_real = Gg / eq0.P;

[blo,bhi,gb] = kv_grid_curv(p0.bGrid);
[klo,khi,gk] = kv_grid_curv(p0.kGrid);
tee('frozen calibration: beta=%.6f chi_b=%.6f lambda=%.3f iota_H=%.4f\n', ...
    p0.beta, p0.chi_b, p0.lambda_adj, iota);
tee('grid family: b in [%.4g, %.4g] curvature %.3f; k in [%.4g, %.4g] curvature %.3f\n', ...
    blo, bhi, gb, klo, khi, gk);
tee('matrix: nb %s x nk %s\n\n', mat2str(NB_LIST), mat2str(NK_LIST));

nw = kv_parpool(PARALLEL, NWORKERS, true, tee, ...
                {fullfile(rootdir,'src'), fullfile(projdir,'src_project')});

% =====================================================================
% The cells. Solved in a deterministic order so continuation always has a
% coarser neighbour: ascending nb, then ascending nk.
% =====================================================================
nB = numel(NB_LIST); nK = numel(NK_LIST);
CELL = cell(nB, nK);
prev = [];                                   % the coarser neighbour's solution

for ib = 1:nB
    for ik = 1:nK
        nb = NB_LIST(ib); nk = NK_LIST(ik);
        tee('--- cell nb=%d nk=%d ---\n', nb, nk);

        p = p0;
        p.bGrid = kv_grid_build(blo, bhi, gb, nb);
        p.kGrid = kv_grid_build(klo, khi, gk, nk);

        tgt = struct('ok', true, 'msg', 'track A: parameters frozen');
        if TRACK == 'B'
            % Track B re-fits beta and chi_b on THIS grid to the declared
            % targets. Deliberately not implemented inline: it must call the
            % same calibration routine the paper uses, or it is a different
            % calibration. See the decision list in R10_EXECUTION_PLAN.
            ctxo = struct('r_b',r_b,'d_base',d_base,'D0',D0,'Bnom',Bnom, ...
                          'Kbar',Kbar,'iota',iota,'b_targ_H',0.30, ...
                          'q_ref',eq0.q,'W_targ',[]);
            [p, tgt] = recalibrate_on_grid(p, ctxo, nb, nk, tee);
            if ~tgt.ok
                tee('    recalibration unavailable: %s\n', tgt.msg);
                tee('    Track B cannot run until this is wired. Cell skipped.\n\n');
                CELL{ib,ik} = struct('ok', false, 'msg', tgt.msg);
                continue;
            end
        end

        CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
                     'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real,'Pseed',eq0.P);

        C = solve_cell(CTX, eq0, prev, tee);
        C.nb = nb; C.nk = nk; C.targets = tgt;
        CELL{ib,ik} = C;
        if C.ok, prev = C; end               % continuation source for the next
        tee('\n');
    end
end

% =====================================================================
% Gate 11 and 12: the contrast, across the matrix
% =====================================================================
tee('===== ACROSS-MATRIX GATES =====\n');
[G11, tab] = contrast_gates(CELL, TRACK, tee);

save(fullfile(qdir, sprintf('twoasset_certification_%s.mat', TRACK)), ...
     'CELL','G11','tab','NB_LIST','NK_LIST','TRACK','p0');
tee('\n[main_twoasset_grid_certification] wrote %s (%.1f s)\n', sf, toc(t0));
tee('Output is QUARANTINED in %s\n', qdir);
fclose(fid);

% =====================================================================
function C = solve_cell(CTX, eq0, prev, tee)
% One cell: three solves (continued + two dispersed cold), per-equilibrium
% gates on the retained one, and the root-continuity record.
    C = struct('ok', false, 'msg', '', 'roots', [], 'multiple', false, ...
               'signdisagree', false, 'state', 'NO_CONVERGENCE', ...
               'branch_id', NaN, 'cold_distance', []);

    % --- starts ---------------------------------------------------------
    qc = eq0.q; Pc = eq0.P;
    if ~isempty(prev) && isfield(prev,'E0') && ~isempty(prev.E0)
        qc = prev.E0.q; Pc = prev.E0.P;      % continuation from the coarser cell
    end
    starts = struct('name', {'continued','cold_lo','cold_hi'}, ...
                    'q',    {qc, 0.80*qc, 1.20*qc}, ...
                    'P',    {Pc, 0.85*Pc, 1.15*Pc});

    R = struct('name',{},'alpha',{},'q',{},'P',{},'ok',{});
    E0 = []; E1 = [];
    for s = 1:numel(starts)
        Cx = CTX; Cx.Pseed = starts(s).P;
        if s == 1 && ~isempty(prev) && isfield(prev,'V0') && ~isempty(prev.V0)
            Cx.Wseed = prev.V0;              % continuation of the value function too
        end
        a0 = kv_solve_alpha(0.0, Cx, starts(s).q, false, []);
        if ~a0.ok
            tee('    start %-10s alpha=0 FAILED (%s)\n', starts(s).name, a0.msg);
            R(end+1) = struct('name',starts(s).name,'alpha',0,'q',NaN,'P',NaN,'ok',false); %#ok<AGROW>
            continue;
        end
        Cx.Wseed = a0.sol.V; Cx.Pseed = a0.P;
        a1 = kv_solve_alpha(1.0, Cx, a0.q, false, []);
        R(end+1) = struct('name',starts(s).name,'alpha',0,'q',a0.q,'P',a0.P,'ok',true); %#ok<AGROW>
        if a1.ok
            R(end+1) = struct('name',starts(s).name,'alpha',1,'q',a1.q,'P',a1.P,'ok',true); %#ok<AGROW>
        end
        if s == 1, E0 = a0; E1 = a1; end
    end
    C.roots = R;
    % distance of each cold-start root from the continuation root, and a
    % branch identifier propagated across neighbouring cells, so a refinement
    % that hops branches is visible as a change of identifier rather than as
    % an unexplained Gate-11 movement.
    C.cold_distance = struct('name',{},'dq',{},'dP',{});
    ref0 = R(find([R.ok] & [R.alpha]==0, 1, 'first'));
    if ~isempty(ref0)
        for rr = R([R.ok] & [R.alpha]==0)
            if strcmp(rr.name,'continued'), continue; end
            C.cold_distance(end+1) = struct('name', rr.name, ...
                'dq', abs(rr.q/ref0.q - 1), 'dP', abs(rr.P/ref0.P - 1)); %#ok<AGROW>
        end
    end
    C.branch_id = NaN;
    if ~isempty(prev) && isfield(prev,'branch_id') && ~isempty(ref0)
        moved = abs(ref0.q/prev.q0 - 1) > 5e-2;   % a branch hop, not a refinement
        if moved, C.branch_id = prev.branch_id + 1; else, C.branch_id = prev.branch_id; end
    else
        C.branch_id = 1;
    end
    if isempty(E0) || isempty(E1) || ~E0.ok || ~E1.ok
        C.msg = 'the continued solve did not deliver both financing equilibria';
        C.state = 'NO_CONVERGENCE';
        tee('    CELL FAILED: %s\n', C.msg); return;
    end

    % --- distinct roots and sign agreement -------------------------------
    okr = [R.ok];
    q0 = [R(okr & [R.alpha]==0).q];  P0 = [R(okr & [R.alpha]==0).P];
    q1 = [R(okr & [R.alpha]==1).q];  P1 = [R(okr & [R.alpha]==1).P];
    C.multiple = spread(q0) > 1e-6 || spread(P0) > 1e-6 || ...
                 spread(q1) > 1e-6 || spread(P1) > 1e-6;
    dP_all = P1 - P0(1:min(numel(P0),numel(P1)));
    C.signdisagree = numel(unique(sign(dP_all(isfinite(dP_all))))) > 1;
    if C.multiple
        tee('    MULTIPLE_ROOTS: q spread %.2e / %.2e, P spread %.2e / %.2e\n', ...
            spread(q0), spread(q1), spread(P0), spread(P1));
    end
    if C.signdisagree
        tee('    *** BRANCHES DISAGREE ON THE SIGN OF dP. Cell fails; no root is\n');
        tee('    *** selected on the basis of its sign.\n');
    end

    % --- per-equilibrium gates on the retained (continued) solve ---------
    Trev = CTX.r_b*(CTX.Bnom/E0.P) + CTX.g_real;      % real revenue, alpha=0
    DS   = CTX.r_b*(CTX.Bnom/E0.P);
    g0 = kv_gate_report(E0, CTX, struct('Trev',Trev,'DS',DS));
    g1 = kv_gate_report(E1, CTX, struct('Trev',Trev,'DS',DS));
    print_gates(tee, 'alpha=0', g0);
    print_gates(tee, 'alpha=1', g1);

    % Result classification, five states, never collapsed to pass/fail:
    %   NO_CONVERGENCE | ONE_CERTIFIED_ROOT | MULTI_SAME_SIGN
    %   MULTI_CONFLICTING_SIGN | CONVERGED_INADMISSIBLE
    if C.signdisagree
        C.state = 'MULTI_CONFLICTING_SIGN';
    elseif C.multiple
        C.state = 'MULTI_SAME_SIGN';
    elseif ~(g0.pass && g1.pass)
        C.state = 'CONVERGED_INADMISSIBLE';
    else
        C.state = 'ONE_CERTIFIED_ROOT';
    end
    % ONE_CERTIFIED_ROOT is a statement about the SEARCH, not about the
    % economy: it means no other root was found by the starts tried, which is
    % not the same as uniqueness and is never reported as such.
    C.ok  = g0.pass && g1.pass && ~C.signdisagree;
    C.E0  = E0; C.E1 = E1; C.g0 = g0; C.g1 = g1;
    C.V0  = E0.sol.V;
    C.P0  = E0.P; C.P1 = E1.P; C.q0 = E0.q; C.q1 = E1.q;
    C.dP  = E1.P - E0.P;
    C.dlnP = log(E1.P/E0.P);
    C.Sb0 = E0.Sb; C.Sb1 = E1.Sb; C.Sk0 = E0.Sk; C.Sk1 = E1.Sk;
    tee('    P^LS=%.6f  P^LEV=%.6f  dP=%+0.6f  dlnP=%+0.6f  cell %s\n', ...
        C.P0, C.P1, C.dP, C.dlnP, ternstr(C.ok,'PASS','FAIL'));
end

function [G, tab] = contrast_gates(CELL, TRACK, tee)
% Gate 11 (and 12's price leg) over the whole matrix.
    G = struct('ran', false, 'ratio', NaN, 'pass', false, 'n', 0);
    v = []; lab = {};
    nfail = 0;
    for i = 1:numel(CELL)
        c = CELL{i};
        if isempty(c) || ~isstruct(c) || ~isfield(c,'ok') || ~c.ok
            nfail = nfail + 1; continue;     % counted, never dropped silently
        end
        v(end+1) = c.dP; %#ok<AGROW>
        lab{end+1} = sprintf('nb%d,nk%d', c.nb, c.nk); %#ok<AGROW>
    end
    tab = struct('dP', v, 'label', {lab});
    G.n = numel(v);
    if G.n < 2
        tee('  fewer than two certified cells: Gate 11 not computable.\n');
        tee('  This is a FAILURE of the protocol, not an absence of evidence.\n');
        return;
    end
    med = median(v);
    G.ratio = (max(v) - min(v)) / max(abs(med), eps);
    G.ran = true;
    G.pass = G.ratio < 0.10;
    G.preferred = G.ratio < 0.05;
    nm = ternstr(TRACK=='A', 'GATE 11 grid uncertainty in dP / |dP|', ...
                             'calibration-robustness spread in dP / |dP|');
    tee('  cells certified            : %d of %d (%d failed, all retained in CELL)\n', ...
        G.n, numel(CELL), nfail);
    tee('  cell states                : ');
    for i = 1:numel(CELL)
        c = CELL{i};
        if isstruct(c) && isfield(c,'state'), tee('%s ', c.state); end
    end
    tee('\n');
    tee('  dP across cells            : [%+0.6f, %+0.6f], median %+0.6f\n', ...
        min(v), max(v), med);
    tee('  %-26s : %.4f  (required <0.10, preferred <0.05)  %s\n', ...
        nm, G.ratio, ternstr(G.pass,'PASS','FAIL'));
    if numel(unique(sign(v))) > 1
        tee('  *** dP CHANGES SIGN across the matrix. The financing contrast is\n');
        tee('  *** not measurable at this resolution and no ordering may be quoted.\n');
    end
    if TRACK == 'B'
        tee('  (Track B: this is calibration robustness. It does NOT satisfy\n');
        tee('   Gate 11 and must not be described as convergence.)\n');
    end
end

function [p, tgt] = recalibrate_on_grid(p, ctxo, nb, nk, tee)
% TRACK B. Re-fits beta (and chi_b under a 2D target) on THIS grid by calling
% kv_calibrate_on_grid, which is a typed interface around the SAME
% calib_beta / calib_beta_chi that the production script uses. There is no
% second calibration implementation anywhere in this project, and there must
% not be: two implementations of one object drift, and the drift is silent
% because both of them "work".
%
% Requires main_parity_d10_calibration to have PASSED. That test compares the
% legacy call against this one on the production grid; until it has run, this
% path is unverified and Track B must not be reported.
    tgt = struct('ok', false, 'msg', '');
    C = kv_calibrate_on_grid( ...
          struct('p_base', p, 'nb', nb, 'nk', nk), ...
          struct('r_b', ctxo.r_b, 'd_base', ctxo.d_base, 'D0', ctxo.D0, ...
                 'Bnom', ctxo.Bnom, 'Kbar', ctxo.Kbar, 'iota_H', ctxo.iota, ...
                 'b_targ_H', ctxo.b_targ_H, 'q_ref', ctxo.q_ref, ...
                 'W_targ', ctxo.W_targ, ...
                 'tag', sprintf('trackB_nb%d_nk%d', nb, nk)));
    if ~C.ok
        tgt.msg = C.msg; return;
    end
    p = C.p;
    tgt = struct('ok', true, 'msg', '', 'theta', C.theta, ...
                 'target_err', C.target_err, 'untargeted', C.untargeted, ...
                 'diag', C.diag, 'provenance', C.provenance);
    tee('    recalibrated: beta=%.8f', C.theta(1));
    if numel(C.theta) > 1, tee(' chi_b=%.8f', C.theta(2)); end
    tee('  S_b err %+0.3e\n', C.target_err.Sb_direct);
end

function print_gates(tee, tag, G)
    bad = {};
    for i = 1:numel(G.rows)
        r = G.rows{i};
        if ~r.pass || isnan(r.value)
            bad{end+1} = sprintf('%g %s=%.3g (need %s%.3g)', ...
                r.id, r.name, r.value, r.rel, r.threshold); %#ok<AGROW>
        end
    end
    if isempty(bad)
        tee('    gates %-8s ALL PASS\n', tag);
    else
        tee('    gates %-8s FAIL: %s\n', tag, strjoin(bad, '; '));
    end
end

function s = spread(x)
    x = x(isfinite(x));
    if numel(x) < 2, s = 0; else, s = (max(x)-min(x))/max(abs(median(x)),eps); end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
