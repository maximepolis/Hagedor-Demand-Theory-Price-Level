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

clearvars -except TRACK FAST PARALLEL NWORKERS NB_LIST NK_LIST WIDEN NB_SCALED RESUME; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));

if ~exist('TRACK','var') || isempty(TRACK), TRACK = 'A'; end
if ~exist('FAST','var'), FAST = false; end
if ~exist('PARALLEL','var') || isempty(PARALLEL), PARALLEL = false; end
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

% ---- WIDEN THE FROZEN FAMILY (authorised 2026-08-04) --------------------
% Gates 7-9 measure distance from the grid CEILING and the calibration grid
% fails them before any refinement, so the matrix was certifying nothing.
% Widening the extent is the fix that keeps Track A's meaning: parameters
% stay frozen, only the discretization moves, which is what discretization
% error means. The factors are the ones the residual scan verified, read
% from that scan so the widening and the diagnosis share one source.
%
% WHAT THIS COSTS, STATED PLAINLY. The frozen (beta, chi_b) were calibrated
% on the NARROW family to S_b = 0.30. Widening moves the wealth moments, so
% on the wide family the frozen economy will NOT sit at its targets. That is
% not a defect of Track A -- Track A asks how much the answer moves when only
% the grid moves, and re-fitting parameters at each grid would let a
% calibration movement offset a discretization error. But it does mean the
% widened Track A economy is not the calibrated economy, and its dP may
% differ from the paper's for a reason that is not discretization. The
% distance is measured and reported below rather than assumed small.
if ~exist('WIDEN','var') || isempty(WIDEN), WIDEN = true; end
KFACC = []; BFACC = [];
if WIDEN
    scf = fullfile(projdir,'output','kv_residual_scan.mat');
    if exist(scf,'file') == 2
        Sc = load(scf, 'kfac', 'bfac');
        if isfield(Sc,'kfac'), KFACC = Sc.kfac; end
        if isfield(Sc,'bfac'), BFACC = Sc.bfac; end
    end
    if isempty(KFACC), KFACC = 6; end        % the ownership driver's defaults
    if isempty(BFACC), BFACC = 8; end
    bhi0 = bhi; khi0 = khi;
    bhi = bhi * BFACC; khi = khi * KFACC;
    tee('*** FAMILY WIDENED for Track A: bmax %.4g -> %.4g (x%g), ', ...
        bhi0, bhi, BFACC);
    tee('kmax %.4g -> %.4g (x%g)\n', khi0, khi, KFACC);
    tee('*** Parameters stay FROZEN, so this remains a discretization\n');
    tee('*** measurement -- but the frozen calibration was fitted on the\n');
    tee('*** NARROW family and will not sit at its targets here. The\n');
    tee('*** distance is reported per cell as target_drift, not assumed.\n');
    tee('*** Set WIDEN = false to reproduce the pre-widening matrix.\n');

    % NODE COUNTS MUST SCALE WITH THE EXTENT, or widening is a downgrade.
    % On a curvature-g grid, node i sits at (i/n)^g * xmax, so the count of
    % nodes below a FIXED level x* is n*(x*/xmax)^(1/g). Multiplying xmax by
    % F therefore divides the density below x* by F^(1/g). Keeping the same
    % resolution where the mass actually lives -- near the constraint, which
    % is the whole reason for the curvature -- requires multiplying n by
    % F^(1/g). At bfac 8 and curvature 2.4 that is 8^(1/2.4) = 2.4x; at kfac
    % 6 it is 2.1x.
    %
    % Not doing this would widen the grid and coarsen it at the same time,
    % then report the combination as a discretization study. The counts are
    % scaled by default. An explicit NB_LIST/NK_LIST in the workspace is
    % respected and left alone, so the scaling can be overridden knowingly.
    sb_ = BFACC^(1/max(gb,1e-6));
    sk_ = KFACC^(1/max(gk,1e-6));
    if exist('NB_SCALED','var') && ~isempty(NB_SCALED) && ~NB_SCALED
        tee('*** node counts NOT scaled (NB_SCALED = false). The widened\n');
        tee('*** family is COARSER than the narrow one near the constraint.\n');
    else
        NB0 = NB_LIST; NK0 = NK_LIST;
        NB_LIST = unique(ceil(NB_LIST * sb_));
        NK_LIST = unique(ceil(NK_LIST * sk_));
        tee('*** node counts scaled to hold density below a fixed level:\n');
        tee('***   nb %s -> %s  (x%.2f)\n', mat2str(NB0), mat2str(NB_LIST), sb_);
        tee('***   nk %s -> %s  (x%.2f)\n', mat2str(NK0), mat2str(NK_LIST), sk_);
        tee('*** This is why a widened FAST run is not fast. Set\n');
        tee('*** NB_SCALED = false to keep the small counts, knowing what it\n');
        tee('*** costs, or pass NB_LIST / NK_LIST explicitly.\n');
    end
    tee('\n');
end
tee('frozen calibration: beta=%.6f chi_b=%.6f lambda=%.3f iota_H=%.4f\n', ...
    p0.beta, p0.chi_b, p0.lambda_adj, iota);
tee('grid family: b in [%.4g, %.4g] curvature %.3f; k in [%.4g, %.4g] curvature %.3f\n', ...
    blo, bhi, gb, klo, khi, gk);
tee('matrix: nb %s x nk %s\n\n', mat2str(NB_LIST), mat2str(NK_LIST));

% ---- PRE-FLIGHT: can this grid FAMILY clear the boundary gates at all? ----
% Gates 7-9 measure where the distribution sits relative to the grid CEILING:
% top-two-node mass, and the highest occupied node as a fraction of the top.
% Track A varies only the NODE COUNTS nb and nk; the extent [blo,bhi] x
% [klo,khi] is frozen with the calibration. Refining a grid whose ceiling is
% too low moves neither diagnostic -- the mass is at the wall either way --
% so if the frozen benchmark fails these, every cell in the matrix will fail
% them identically, for a reason that has nothing to do with the
% discretization error Track A exists to measure.
%
% That is worth knowing in the first second rather than after nine cells.
% This costs nothing: the benchmark distribution is already in the .mat.
% It does NOT change any threshold or any pass rule -- it reports.
if isfield(eq0, 'dist') && ~isempty(eq0.dist)
    [ks0, bs0, ko0, bo0] = kv_boundary_mass(eq0.dist, p0.kGrid, p0.bGrid);
    Tf = struct('boundary', 1e-4, 'occupancy', 0.90);
    famfail = (bs0 >= Tf.boundary) || (ks0 >= Tf.boundary) || ...
              (bo0 >= Tf.occupancy) || (ko0 >= Tf.occupancy);
    tee('pre-flight, FAMILY gates on the frozen benchmark distribution.\n');
    tee('These are measured on the NARROW family the benchmark was solved on;\n');
    tee('they are what motivated the widening above, and they cannot be\n');
    tee('re-evaluated on the wide family without solving it, which the cells\n');
    tee('below do. Read them as the reason for widening, not as its result.\n');
    tee('  gate 7  liquid top-two-node mass   %.5f  (need <%.0e)\n', bs0, Tf.boundary);
    tee('  gate 8  illiquid top-two-node mass %.5f  (need <%.0e)\n', ks0, Tf.boundary);
    tee('  gate 9  occupied support, liquid   %.4f  (need <%.2f)\n', bo0, Tf.occupancy);
    tee('  gate 9.1 occupied support, illiquid %.4f  (need <%.2f)\n', ko0, Tf.occupancy);
    if famfail
        tee('  *** THE GRID FAMILY FAILS THESE BEFORE ANY REFINEMENT.\n');
        tee('  *** Gates 7-9 are properties of the grid EXTENT (bhi, khi), which\n');
        tee('  *** Track A holds FIXED. Every cell below will fail them with the\n');
        tee('  *** same values, and no cell can be certified, so Gate 11 will\n');
        tee('  *** report "fewer than two certified cells" regardless of how\n');
        tee('  *** well the residuals and the convergence norms behave.\n');
        tee('  *** This is a PROTOCOL question, not a solver failure: either the\n');
        tee('  *** frozen family is widened (and the calibration re-validated on\n');
        tee('  *** it, which is Track B), or gates 7-9 are scored once for the\n');
        tee('  *** family rather than per cell. Neither is decided here, and no\n');
        tee('  *** threshold is changed here.\n');
    else
        tee('  family clears the boundary gates; per-cell failures are genuine.\n');
    end
    tee('\n');
end

% NO POOL FOR TRACK A. Nothing in this driver's call chain contains a parfor:
% the cell loop is serial by protocol (each cell continues from its coarser
% neighbour), kv_solve_alpha states in its own header that it is serial and
% stays serial, and the household solver relies on MATLAB's implicit
% multithreading rather than on workers. A pool therefore starts four
% processes that sit idle for the whole run and then announce "IdleTimeout has
% been reached" in the middle of a cell, which reads like a fault and is not
% one. Track B's recalibration path may use workers, so the pool is kept
% there and PARALLEL = true still forces one.
if TRACK == 'A' && (~exist('PARALLEL','var') || isempty(PARALLEL) || ~PARALLEL)
    nw = 0;
    tee(['no parallel pool: nothing in the Track A chain uses parfor, so a ' ...
         'pool\nwould idle for the whole run. Implicit multithreading is ' ...
         'unaffected.\n\n']);
else
    nw = kv_parpool(PARALLEL, NWORKERS, true, tee, ...
                    {fullfile(rootdir,'src'), fullfile(projdir,'src_project')});
end

% =====================================================================
% The cells. Solved in a deterministic order so continuation always has a
% coarser neighbour: ascending nb, then ascending nk.
% =====================================================================
nB = numel(NB_LIST); nK = numel(NK_LIST);
CELL = cell(nB, nK);
prev = [];                                   % the coarser neighbour's solution

% ---- CHECKPOINT / RESUME ------------------------------------------------
% A widened cell takes hours and the matrix has nine of them, so an
% interrupted run must not throw away the cells it finished. After every
% cell the partial CELL array is written to a checkpoint keyed by a SIGNATURE
% of everything that defines the experiment: the frozen parameters, the grid
% extents and curvatures, the node lists and the track. A resume is accepted
% only when that signature matches exactly.
%
% The signature is the point. Resuming across a changed threshold, a changed
% widening factor or a changed calibration would silently splice cells from
% two different experiments into one Gate 11 statistic, and the spread it
% reported would be part discretization and part whatever else moved. On a
% mismatch the checkpoint is ignored and the run starts clean, loudly.
sig = struct('track', TRACK, 'beta', p0.beta, 'chi_b', p0.chi_b, ...
             'lambda', p0.lambda_adj, 'iota', iota, 'div_payout', ...
             getfd(p0,'div_payout',NaN), 'bbar', getfd(p0,'bbar_liq',NaN), ...
             'zeta', getfd(p0,'zeta_b',NaN), ...
             'blo', blo, 'bhi', bhi, 'gb', gb, 'klo', klo, 'khi', khi, ...
             'gk', gk, 'nb_list', NB_LIST(:)', 'nk_list', NK_LIST(:)', ...
             'g_real', g_real, 'D0', D0, 'r_b', r_b, 'd_base', d_base);
ckf = fullfile(qdir, sprintf('cert_%s_checkpoint.mat', TRACK));
ndone0 = 0;
if ~exist('RESUME','var') || isempty(RESUME), RESUME = true; end
if RESUME && exist(ckf,'file') == 2
    CK = load(ckf);
    if isfield(CK,'sig') && isequaln(CK.sig, sig) && isfield(CK,'CELL') ...
            && isequal(size(CK.CELL), [nB nK])
        CELL = CK.CELL;
        if isfield(CK,'prev'), prev = CK.prev; end
        ndone0 = sum(cellfun(@(c) ~isempty(c), CELL(:)));
        tee('RESUMED from checkpoint: %d of %d cells already solved.\n', ...
            ndone0, nB*nK);
        tee('  signature matched (parameters, extents, curvatures, node lists).\n\n');
    else
        tee('checkpoint present but its SIGNATURE DOES NOT MATCH this run.\n');
        tee('  Ignoring it and starting clean. Splicing cells from two\n');
        tee('  different experiments would make Gate 11 a spread over\n');
        tee('  whatever else changed, not over the discretization.\n\n');
    end
end

for ib = 1:nB
    for ik = 1:nK
        nb = NB_LIST(ib); nk = NK_LIST(ik);
        if ~isempty(CELL{ib,ik})
            tee('--- cell nb=%d nk=%d : from checkpoint ---\n', nb, nk);
            continue;
        end
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
        % Checkpoint AFTER every cell, including failed ones: a cell that
        % failed is a result, and re-solving it on resume would cost the same
        % hours to learn the same thing. Written to a temporary file and
        % renamed, so an interrupt DURING the save cannot leave a truncated
        % checkpoint that the next run would then trust.
        try
            tmpck = [ckf '.tmp'];
            save(tmpck, 'CELL', 'prev', 'sig', '-v7.3');
            movefile(tmpck, ckf, 'f');
            tee('    [checkpoint] %d of %d cells stored\n', ...
                sum(cellfun(@(c) ~isempty(c), CELL(:))), nB*nK);
        catch cerr
            tee('    [checkpoint FAILED: %s -- the run continues]\n', cerr.message);
        end
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
    % Gate 6 reads opts.polstable -- the FRACTION of adjuster candidates that
    % moved between the last two sweeps. It was never supplied, so the gate
    % scored NaN and, by the report's own "unmeasured is never passed" rule,
    % failed every cell. kv_solve_alpha now carries E.churn up from the
    % household solver; pass it through under the name the gate expects.
    g0 = kv_gate_report(E0, CTX, struct('Trev',Trev,'DS',DS, ...
                                        'polstable', getfd(E0,'churn',NaN)));
    g1 = kv_gate_report(E1, CTX, struct('Trev',Trev,'DS',DS, ...
                                        'polstable', getfd(E1,'churn',NaN)));
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
    % TARGET DRIFT. The frozen (beta, chi_b) hit S_b = 0.30 on the narrow
    % family. On a widened family they will not, and the size of the miss
    % says how far the Track A economy has moved from the calibrated one.
    % Reported, never gated: Track A is entitled to be off its targets --
    % that is what holding parameters fixed MEANS -- but a reader comparing
    % this dP with the paper's is entitled to know how far apart the two
    % economies are.
    C.target_drift = E0.Sb - 0.30;
    tee('    S_b at alpha=0 = %.4f (calibration target 0.30, drift %+0.4f)\n', ...
        E0.Sb, C.target_drift);
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

    % ---- PROVISIONAL statistic over cells that SOLVED but did not certify --
    % Gate 11 proper is computed only over certified cells, and that rule
    % stands. But a cell that solved and produced a dP carries information
    % even when it fails a gate, and discarding it means a run that fails
    % certification reports nothing at all -- which is how the project could
    % spend a day of compute and learn only that it had spent a day.
    %
    % The two questions are genuinely different and are reported separately:
    %   MAGNITUDE  is the spread in dP small relative to dP? (Gate 11)
    %   ORDERING   does dP keep its SIGN across every discretization?
    % The ordering is the weaker claim and the more robust one: it compares
    % two solves on the SAME grid, so the common discretization error
    % differences out. A run can fail the first and pass the second, and that
    % combination is exactly the paper's decision point -- report the
    % financing ordering, decline the level.
    %
    % NOTHING HERE IS CERTIFIED. It is labelled provisional in every line and
    % may not enter the manuscript on the strength of this block alone.
    vp = []; labp = {};
    for i = 1:numel(CELL)
        c = CELL{i};
        if isempty(c) || ~isstruct(c) || ~isfield(c,'dP') || ~isfinite(c.dP)
            continue;
        end
        vp(end+1) = c.dP; %#ok<AGROW>
        labp{end+1} = sprintf('nb%d,nk%d', c.nb, c.nk); %#ok<AGROW>
    end
    G.provisional = struct('n', numel(vp), 'dP', vp, 'label', {labp}, ...
                           'ratio', NaN, 'sign_stable', false, 'sd_ratio', NaN);
    if numel(vp) >= 2
        medp = median(vp);
        G.provisional.ratio    = (max(vp) - min(vp)) / max(abs(medp), eps);
        G.provisional.sd_ratio = std(vp) / max(abs(mean(vp)), eps);
        G.provisional.sign_stable = numel(unique(sign(vp))) == 1;
        tee('\n  --- PROVISIONAL, over cells that SOLVED (certified or not) ---\n');
        tee('  cells with a finite dP     : %d of %d\n', numel(vp), numel(CELL));
        tee('  dP                         : [%+0.6f, %+0.6f], median %+0.6f\n', ...
            min(vp), max(vp), medp);
        tee('  spread / |median|          : %.4f   (Gate 11 would need <0.10)\n', ...
            G.provisional.ratio);
        tee('  s.d. / |mean|              : %.4f\n', G.provisional.sd_ratio);
        if G.provisional.sign_stable
            tee('  ORDERING                   : STABLE -- dP keeps one sign in\n');
            tee('                               all %d cells. The levy and the\n', numel(vp));
            tee('                               lump-sum tax are ranked the same\n');
            tee('                               way at every discretization.\n');
        else
            tee('  ORDERING                   : NOT STABLE -- dP changes sign\n');
            tee('                               across the matrix. Neither the\n');
            tee('                               level nor the ordering may be\n');
            tee('                               quoted at this resolution.\n');
        end
        tee('  These numbers are PROVISIONAL and uncertified. They bound what\n');
        tee('  the discretization can support; they do not license a claim.\n\n');
    end

    if G.n < 2
        tee('  fewer than two certified cells: Gate 11 not computable.\n');
        tee('  This is a FAILURE of the protocol, not an absence of evidence.\n');
        if numel(vp) >= 2
            tee('  The provisional block above is what the run DID establish.\n');
        end
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

function v = getfd(S, f, dv)
% Field with a default, so a worker running an older kv_solve_alpha yields an
% UNMEASURED gate rather than an error inside a parfor body.
    if isstruct(S) && isfield(S, f) && ~isempty(S.(f)), v = S.(f); else, v = dv; end
end
