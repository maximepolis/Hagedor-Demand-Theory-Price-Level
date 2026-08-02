% MAIN_KV_RESIDUAL_SCAN  Diagnose the reduced tree-market residual of the
% preferred (ownership + illiquidity) economy.
%
% THE QUESTION. The stationary solver cannot clear the tree market: at
% alpha = 1 the bracket collapsed to 1e-11 while |S_k - Kbar| stayed at
% 1.3e-3, and the equilibrium map is therefore not differentiable enough to
% support the Schur validation or the decomposition. Before replacing the
% household policy we must know WHY. There are four candidate causes and
% they call for different repairs:
%
%   (C1) INCOMPLETE HOUSEHOLD CONVERGENCE. The VFI soft-accepts a
%        grid-limited fixed point. If the residual is noisy but not
%        systematic, and shrinks when the tolerance is tightened, the cure
%        is a tighter household solve, not a new policy.
%   (C2) PATH DEPENDENCE. If ascending and descending scans disagree, the
%        warm start is carrying state and the map is not a function of q at
%        all. Cure: cold-start, or a start independent of the scan order.
%   (C3) GRID BOUNDARIES. If mass piles at the top of the b- or k-grid the
%        aggregates stop responding to prices. Cure: widen the grids.
%   (C4) DISCRETE k-CHOICE. If the residual is a reproducible STAIRCASE
%        whose jumps line up with states changing their k grid index, the
%        cause is the argmax over a discrete candidate set. Cure: a
%        continuous adjuster policy (interpolated continuation value,
%        refined between neighbouring nodes) plus a bilinear lottery push.
%
% WHAT IS SAVED per (alpha, q) node: the reduced tree residual with the
% bond market solved conditional on q, the bond residual, the household
% and distribution convergence diagnostics, the boundary masses, and the
% fraction of household states whose k-policy grid index differs from the
% previous scan node. That last series is the direct test for (C4).
%
% ---------------------------------------------------------------------
% A CORRECTION TO THE ROUND-1 READING OF (C2).
%
% Round 1 reported hysteresis of exactly 0.00e+00 at every alpha and that was
% read as "path dependence ruled out". It is not evidence for that. Round 1
% ran with COLDSTART = true, under which the scan never assigned the warm
% start at all: W stayed empty at every node in BOTH directions, so the
% ascending and descending passes were bit-for-bit the same computation and
% the difference was zero by construction, not by finding. The test had no
% content -- the same shape of error as the terminal-dlnP "validation" that
% compared a pinned value against itself.
%
% What IS true, and is what actually licenses parallelising the scan, is the
% premise rather than the result: with no warm start, each node is by
% construction a pure function of (alpha, q, grids, calibration), so
% evaluating the nodes concurrently is the identical computation in a
% different order, not an approximation. That is a property of the cold-start
% design, and it needs no scan to establish.
%
% C2 is now tested where it can actually fail: a small WARM-STARTED probe
% (HPROBE nodes, ascending then descending, chained value functions) run
% serially after the main scan. If that probe shows hysteresis, the warm
% start carries state and the warm-started solvers elsewhere in the project
% are suspect -- while the cold scan itself remains unaffected.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 2: THE BOUNDARY REPAIR.
%
% Round 1's other findings stand. VFI dV stayed below 1e-6 and the
% distribution residual below 1e-11, so (C1) is dead. What
% round 1 did find is 2.8e-3 of mass in the top two nodes of BOTH the k- and
% the b-grid -- about 29 times the 1e-4 tolerance. With Kbar = 1 that is a
% sixth of aggregate tree demand pinned against a wall, and mass against a
% wall cannot respond to q: it is a mechanical reason for the reduced tree
% residual to refuse to cross zero.
%
% (C4), the discrete-k staircase, was ALSO flagged (index flips 0.006/step,
% jump ratio 6-14). It is not addressed here and must not be, because a
% staircase measured on a truncated grid is not evidence about the policy: a
% boundary that clips the argmax manufactures exactly the same signature.
% (C3) is repaired first and (C4) is re-measured afterwards on grids the
% distribution can actually cross.
%
% The repair widens kmax and, ONLY if the b-boundary is still bound after
% that, bmax -- holding both lower bounds, both node counts, and every
% calibrated parameter fixed (see KV_WIDEN_GRIDS for why the node count
% forces the curvature to absorb the widening, and for the ceilings that move
% with kmax). The widening factor is not guessed: a cheap probe at the
% interior alpha re-solves the bond market and measures the boundary masses,
% doubling the factor until both fall below TOPTOL or the cap is hit. The
% GATE, however, is evaluated on the full scan -- max over every q node and
% every alpha -- not on the probe.
%
% CAVEAT that has to travel with any result computed on the widened grid:
% beta and chi_b were calibrated on the OLD grids. Widening moves the wealth
% moments, so main_twoasset_ownership_kv must be recalibrated on the widened
% grid before any number here is treated as final rather than diagnostic.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 3: THE ADMISSIBLE q DOMAIN.
%
% The widening worked: k-top mass fell from 2.8e-3 to ~1e-31 at kfac = 12.
% What it exposed is a different bottleneck. With the tree grid no longer
% truncating, the root moved and the q window expanded 16x chasing it -- into
% prices where the household problem no longer solves. The run then reported
%
%   F_k(1.0319) = NaN, F_k(2.0030) = -1.82e-02  (brackets)
%
% which is wrong twice over. sign(NaN) is NaN and NaN ~= anything is true, so
% the NaN endpoint SATISFIED the sign test and was accepted as a bracket; and
% the expansion loop, whose guard required both endpoints finite, TERMINATED
% on the NaN and treated stopping as success. A NaN is not a large residual.
% A large residual says where the root is; a NaN says where the model stops
% being defined, and only the first may be used in a sign test.
%
% So: no more blind expansion. Each alpha now gets a coarse FEASIBILITY MAP,
% every node classified admissible or failed WITH A REASON (see
% KV_NODE_STATUS: NEG_CONSUMPTION, POLICY_NONCONV, BOND_NAN, TREE_NAN,
% BOUNDARY_HIT, ...). The largest CONTIGUOUS admissible interval is taken --
% contiguity matters, because a bracket spanning a hole in the domain is not
% a bracket -- the scan runs inside it, and the root is bracketed only there.
% Widening the window is offered only when the admissible run reaches a
% window edge, i.e. when the domain was cut by the window rather than by the
% model; otherwise the honest answer is "no admissible root in this domain".
%
% The centre of each alpha's window is the PREVIOUS alpha's converged tree
% price: continuation along 0 -> 0.5 -> 1, which is the best available prior
% about where the admissible region has moved to. The diagnostic scan stays
% cold-started; only the root path uses continuation.
%
% The bond grid is FROZEN for this round (BFACMAX = 1). The last ladder moved
% bmax from 12 to 192 while kmax was also moving, and two grids widening at
% once is not a controlled experiment. b-top mass is still measured and
% reported inside the admissible interval, which is the one condition under
% which it may move next.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 4: THE BOND FIXED POINT WAS THE FAILURE.
%
% Round 3 came back with the k-boundary repaired (top-two-node mass 2.8e-3 ->
% 9e-5 at kfac = 6, and the backtrack showed 12 was overkill), admissible
% roots at alpha = 0 and alpha = 1, and one thing that could not be a
% property of the model: at alpha = 0.5, four of thirteen q nodes failed with
% BOND_NAN / DIST_NONCONV, INTERLEAVED with successes, leaving a "largest
% admissible interval" of [1.83, 2.17] that sits ABOVE both neighbouring
% alphas' roots. A domain does not alternate, and alpha = 0.5's domain cannot
% lie outside the interval spanned by alpha = 0 and alpha = 1. The failure
% was in the solver.
%
% It was the inner bond fixed point: P <- 0.5*P + 0.5*iota*B/S_b(P), up to 80
% sweeps. That map is not a contraction away from equilibrium, so it
% oscillates, exhausts its budget and reports BOND_NAN -- at some q values and
% not their neighbours, which is exactly the scattered pattern. It is now a
% bracketed, safeguarded secant solve on a residual that is monotone in P (a
% higher P deflates the real debt burden, cuts the lump-sum tax and raises
% liquid demand, while cutting real supply). That is both more robust and
% several times cheaper: ~10-15 household solves per node instead of 80.
%
% Three diagnostics were also misreading their own evidence:
%   * the boundary gate took the WORST node of a +/-25% q sweep, which by
%     design visits prices far from equilibrium where the tail piles up. It
%     now gates AT THE ROOT and reports the sweep maximum as context only.
%   * the staircase rate is flips per q STEP, so widening the window from
%     +/-2% to +/-25% inflated it about tenfold on its own. It is now also
%     reported per 1% of q, which is comparable across scans.
%   * the distribution tolerance was binary at 1e-11, so a solve that reached
%     1e-9 was discarded as infeasible. It is graded now: DIST_LOOSE is
%     carried and reported, only worse than 1e-8 is a failure.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 5: THE BOND MARKET IS A STEP FUNCTION TOO.
%
% The secant rewrite cut the bond solve from 80 household solves per node to
% a median of 8 and the run from 46 minutes to 9. It did NOT remove the
% scattered failures: alpha = 0.5 and alpha = 1 still lost 2 of 13 nodes to
% BOND_NAN, interleaved. By elimination that could only be the final
% acceptance test, |g|/P < 1e-8 -- BOND_NOBRACKET and NEG_CONSUMPTION have
% their own codes and neither appeared.
%
% The reason is the same discreteness that afflicts the tree market. S_b(P)
% is a STEP function: the adjuster's portfolio choice is an argmax over a
% discrete candidate set, so liquid demand jumps as P moves the household
% problem across a candidate switch. When the clearing price falls inside
% such a jump there is no P at which the residual vanishes; the bracket
% collapses onto the discontinuity with |g| still finite. Calling that
% BOND_NAN reports "the model is undefined here" for a price at which the
% model is perfectly well defined and merely has no exact zero on a discrete
% grid -- and it happens at some q and not their neighbours, which is exactly
% the alternating pattern observed.
%
% The tree market has handled this from the start, by taking the closest
% approach the discretization admits and gating the achieved residual. The
% bond market now does the same: BOND_STEP, admissible, with the achieved
% relative residual reported and capped at 1e-3.
%
% THE STAIRCASE TEST WAS ALSO WRONG. It was max|dF_k| / median|dF_k| over the
% window, and F_k sweeps four orders of magnitude across a +/-25% window, so a
% smooth but steeply curved residual scores high with no discreteness
% anywhere. Round 3's "jump ratio 31.5 -> staircase PRESENT" rested on that.
% The test now compares median |dF_k| on steps where the adjuster's k index
% CHANGED against steps where it did not: curvature raises both, discreteness
% raises only the first. The old ratio is still printed, labelled as not
% separating the two.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 6: THE DOMAIN IS SOLVED; THE RESIDUAL FLOOR IS NOT.
%
% BOND_STEP fixed the feasibility problem. All three alphas now have a
% contiguous admissible interval with no failures in the coarse map, all
% three bracket a root, and the roots are ordered and tightly spaced
% (1.7071, 1.6979, 1.6887 for alpha = 0, 0.5, 1) -- which is what a
% continuation along alpha should look like and is the first time it has.
%
% Four things were still wrong with the reporting, three of them mine.
%
% BOND_STEP NEVER APPEARED IN THE STATUS HISTOGRAM. The override only fired
% when the code was exactly 'OK', but with the bond grid frozen every node is
% BOUNDARY_HIT, so the step information could never be reported. It now takes
% priority over BOUNDARY_HIT and the count is printed.
%
% THE SECANT STALLED. Plain false position retains one endpoint forever: |g|
% falls but the bracket width does not, so the nodes that hit 62 evaluations
% were running 60 steps without collapsing the bracket -- and the step test
% requires a collapsed bracket before it will call a residual a jump. Those
% nodes were therefore still discarded. Illinois (halve the retained
% endpoint's value when the same side updates twice) plus a forced bisection
% every eighth step restores two-sided convergence.
%
% THE SCAN REPORTED A WORSE ROOT THAN THE SOLVER ACHIEVES. refine_root
% bisected and stopped. S_k(q) is a step function, so bisection lands on a
% jump with the residual still at the jump's size -- hence tree residuals of
% ~3e-3 at the roots, against a production solver (kv_solve_alpha) that has
% always polished. The scan now polishes too, so the two report the same
% quantity.
%
% HYSTERESIS WAS JUDGED ON AN ABSOLUTE SCALE. 6.35e-08 was flagged as PATH
% DEPENDENCE on a residual whose steps between adjacent nodes are ~2.6e-02: a
% relative disagreement of 2e-06, which is the VFI tolerance showing through.
% The gate is now relative, at 1e-3.
%
% And the staircase test could not fire: about 7.5% of states change k index
% at EVERY q step at this window width, so the zero-flip group was empty. It
% now splits at the median flip rate, which always has both groups.
%
% WHAT REMAINS is a residual floor, not a feasibility problem. Both markets
% clear only to ~1e-3 relative because both aggregates are step functions of
% their own price. That is the C4 question, and it is now the binding
% constraint on every derivative downstream.
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% ROUND 7: FEASIBILITY IS DONE; GRID CONVERGENCE IS NOT.
%
% With bfac = 8 every alpha brackets, hysteresis is 1.8e-07 relative,
% VFI dV ~ 1e-06, and k-top mass at the root is 1e-07. C1, C2 and the
% k-boundary are settled. Two things are not.
%
% THE ROOTS MOVED 7.7% ON A PURE GRID CHANGE. bmax 12 -> 96, nothing else,
% and q* went 1.7071 -> 1.8399 at alpha = 0. Worse, the ORDERING in alpha
% broke: 1.8399, 1.8322, 1.8430 is not monotone, where the previous grid gave
% a clean 1.7071 > 1.6979 > 1.6887. The spread across alpha is 0.6% of q
% while the root residual is ~1e-2, so the comparative static the paper is
% about currently sits inside the solver's own noise. That is a statement
% about resolution, not economics, and the run now says it: the root path in
% alpha is reported with a monotonicity check.
%
% THE RESIDUAL FLOOR IS THE BINDING CONSTRAINT. The polished root reaches
% |F_k| ~ 1e-2, and every gate downstream needs orders of magnitude better.
% There are exactly two reasons a polish stops: F_k is steep but SMOOTH, in
% which case more bisection reaches any tolerance; or F_k JUMPS across the
% root, in which case no q attains zero and this is the true floor. The
% coarse scan cannot separate them, so there is now a FLOOR PROBE: 21 nodes
% across a window a thousandth as wide as the scan, reporting whether F_k is
% monotone there, whether it crosses zero, and whether the largest step is
% what the local slope implies or far larger.
%
% AND THE STAIRCASE DETECTOR WAS LOSSY. It counted changes in the k-GRID
% INDEX of the adjuster's choice. But the adjuster does not choose on kGrid:
% it picks an outlay a and a share s from acGrid x sGrid, so a switch between
% candidates that lands in the same kGrid cell moves S_k without moving the
% index. The test could miss the switching it exists to find -- and it is the
% gate on whether the continuous adjuster is ever built, so "NOT indicated"
% at 0.88 / 0.61 / 0.40 is provisional until re-measured. polBa = a*s is a
% pure function of the candidate indices with no q in it, so it changes if
% and only if the argmax moved: that is the exact detector, and it is now
% what the test uses.
%
% The b-tail also gets a direct truncation test: halve bmax and see whether
% the top-of-grid mass scales with the ceiling (truncation, widen further) or
% barely moves (a genuine tail, in which case the payout rule and the
% superstar state are the place to look, not the grid).
% ---------------------------------------------------------------------
%
% ---------------------------------------------------------------------
% PARALLELISM. The (alpha,q) nodes are the unit of work: independent by
% construction, one worker each, no state shared. Every node writes ONE
% result file named by kv_hash of (alpha, q, grids, calibration), and
% aggregation happens only after every worker has finished -- so the reported
% series are assembled from files on disk, in q order, never from whatever
% order the workers happened to complete in. Content addressing means a
% rerun after an unrelated edit is a cache hit and a rerun after a grid or
% parameter change is a miss, with no bookkeeping to get wrong.
%
% What is NOT parallelised, deliberately:
%   * the household VFI and the inner (P,tau,div) fixed point -- contraction
%     iterations, where iterate k+1 reads iterate k and there is no
%     independent work to spread;
%   * the final continuation solver kv_solve_alpha -- a sequential bisection
%     plus golden-section polish, likewise a chain;
%   * the warm-started hysteresis probe -- chaining is the entire point of it;
%   * the whole scan when COLDSTART = false, because warm starts chain the
%     nodes together and the parallel result would then NOT be the serial
%     one. The driver falls back to serial in that case and says so.
%
% PARCHECK re-runs a few nodes with the cache forced off and compares against
% the parallel values, so "same computation, different order" is verified
% rather than asserted.
% ---------------------------------------------------------------------
%
% USAGE   >> clear; main_kv_residual_scan
%         >> clear; FAST = true; main_kv_residual_scan     (coarse grids)
%         >> clear; NQ = 121; main_kv_residual_scan        (finer scan)
%         >> clear; COLDSTART = false; main_kv_residual_scan  (serial, warm)
%         >> clear; NOWIDEN = true; main_kv_residual_scan  (round-1 grids)
%         >> clear; KFAC = 24; main_kv_residual_scan       (force a widening)
%         >> clear; PARALLEL = false; main_kv_residual_scan
%         >> clear; NWORKERS = 8; main_kv_residual_scan
%         >> clear; RESCAN = true; main_kv_residual_scan   (ignore the cache)
%         >> clear; QSPAN = 0.4; main_kv_residual_scan     (wider feasibility map)
%         >> clear; BFAC = 8; main_kv_residual_scan        (deliberate b widening)
%
% OUTPUT  output/tables/kv_residual_scan.txt
%         output/kv_residual_scan.mat    (per-node record + chosen kfac/bfac)
%         output/scan_cache/<gridkey>/   (one .mat per (alpha,q) node)

clearvars -except FAST NQ COLDSTART NOWIDEN KFAC BFAC TOPTOL KFACMAX BFACMAX ...
                  PARALLEL NWORKERS RESCAN PARCHECK HPROBE ...
                  QSPAN NCOARSE QGROW; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('NQ','var') || isempty(NQ), NQ = 61; end
if ~exist('COLDSTART','var'), COLDSTART = true; end
if ~exist('NOWIDEN','var'), NOWIDEN = false; end
if ~exist('KFAC','var') || isempty(KFAC), KFAC = 12; end    % initial kmax x12
% BOND GRID FROZEN. The last ladder took bmax from 12 to 192 chasing the
% b-boundary mass while kmax was also moving. Two grids widening at once is
% not a controlled experiment: neither result is attributable. The b
% escalation is therefore OFF (BFACMAX = 1) and bmax is held at BFAC times
% its calibrated value. The b-top mass is still measured and reported inside
% the admissible q interval, which is the condition under which the bond grid
% may move next: persistent b-top mass above TOPTOL there, and nowhere else.
if ~exist('BFAC','var') || isempty(BFAC), BFAC = 1; end     % bond grid frozen
if ~exist('TOPTOL','var') || isempty(TOPTOL), TOPTOL = 1e-4; end
if ~exist('KFACMAX','var') || isempty(KFACMAX), KFACMAX = 192; end
if ~exist('BFACMAX','var') || isempty(BFACMAX), BFACMAX = 1; end   % no b escalation
if ~exist('PARALLEL','var') || isempty(PARALLEL), PARALLEL = true; end
if ~exist('NWORKERS','var'), NWORKERS = []; end
if ~exist('RESCAN','var') || isempty(RESCAN), RESCAN = false; end
if ~exist('PARCHECK','var') || isempty(PARCHECK), PARCHECK = true; end
if ~exist('HPROBE','var') || isempty(HPROBE), HPROBE = 9; end
if ~exist('QSPAN','var')   || isempty(QSPAN),   QSPAN = 0.25; end
if ~exist('NCOARSE','var') || isempty(NCOARSE), NCOARSE = 13; end
if ~exist('QGROW','var')   || isempty(QGROW),   QGROW = 3; end
assert(NQ >= 61, 'the diagnosis needs at least 61 nodes');
KREF = 5;      % k below which node placement is held fixed (5 x aggregate)
BREF = 3;      % b below which node placement is held fixed (10 x aggregate)

mf = fullfile(projdir,'output','twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2,'run main_twoasset_ownership_kv first');
S = load(mf); p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base;
D0 = S.D0; Gg = S.Gg; eq0 = S.eq0;
pg = setup_params_green(); Bnom = pg.Bnom; Kbar = 1.0;
g_real = Gg / eq0.P;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'kv_residual_scan.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid,varargin{:});
tee('REDUCED TREE-MARKET RESIDUAL SCAN  F_k(q;alpha) = S_k(P(q,alpha),q,alpha) - Kbar\n\n');

% FAST coarsens the state grids for a debug pass. It rebuilds them from the
% curvature the CALIBRATION actually used rather than from a literal 2.4, so
% a coarse run is a subsample of the benchmark grid and not a different one.
if FAST
    nbF = max(28, round(numel(p.bGrid)*0.5));
    nkF = max(16, round(numel(p.kGrid)*0.5));
    [blo,bhi,gbF] = kv_grid_curv(p.bGrid); p.bGrid = kv_grid_build(blo,bhi,gbF,nbF);
    [klo,khi,gkF] = kv_grid_curv(p.kGrid); p.kGrid = kv_grid_build(klo,khi,gkF,nkF);
    tee('*** FAST: state grids coarsened to nb=%d nk=%d (curvature %.2f / %.2f preserved) ***\n\n', ...
        nbF, nkF, gbF, gkF);
end

% The stationary distribution is cheap next to the VFI, and three nodes at
% alpha = 0 were being discarded as DIST_NONCONV at the default cap. Give it
% room before calling it a failure; the tolerance itself is unchanged.
if isfield(p,'maxit_dist'), p.maxit_dist = max(p.maxit_dist, 200000); end

CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
             'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real);

% ------------------------------------------------- boundary repair (C3)
kfac = KFAC; bfac = BFAC; WID = struct('changed',false);
if NOWIDEN
    tee('*** NOWIDEN: running on the round-1 grids (boundary NOT repaired) ***\n\n');
    kfac = 1; bfac = 1;
else
    REFW = struct('r_b',r_b,'q',eq0.q,'d',d_base,'kref',KREF,'bref',BREF);
    [CTX.p, kfac, bfac, WID] = widen_until_interior(CTX, REFW, kfac, bfac, ...
                                    KFACMAX, BFACMAX, TOPTOL, tee);
end
tee('grids nb=%d nk=%d ne=%d; kmax=%.1f bmax=%.2f xmax=%.1f; nq=%d; coldstart=%d\n\n', ...
    numel(CTX.p.bGrid), numel(CTX.p.kGrid), numel(CTX.p.eGrid), ...
    CTX.p.kGrid(end), CTX.p.bGrid(end), CTX.p.xGridA(end), NQ, COLDSTART);

% ------------------------------------------------- content-addressed cache
% The key covers the grids, the calibrated parameters and the economy-level
% constants, so the widening above -- or any parameter change -- lands in a
% different directory and cannot be served a stale result.
gridkey = kv_hash(CTX.p, CTX.iota, CTX.r_b, CTX.d_base, CTX.D0, ...
                  CTX.Bnom, CTX.Kbar, CTX.g_real);
% The first version of kv_hash produced '0000000000000000' for every input
% (a uint64 multiply that saturates instead of wrapping drove the state to
% zero), which quietly mapped every grid to ONE cache directory -- the exact
% failure content addressing exists to prevent. Check it here too: a
% degenerate key must stop the run, not be written into a path.
assert(numel(unique(gridkey)) > 2, ...
    'degenerate cache key "%s" -- kv_hash is broken; refusing to cache', gridkey);
cachedir = fullfile(projdir,'output','scan_cache', gridkey(1:16));
if ~isfolder(cachedir), mkdir(cachedir); end
tee('cache key %s  ->  %s\n\n', gridkey(1:16), cachedir);

% ================== FEASIBILITY DIAGNOSTIC AND ADMISSIBLE DOMAIN =========
% The previous version expanded the q window geometrically until the endpoint
% signs differed. Two things were wrong with it. sign(NaN) is NaN and
% NaN ~= anything is true, so a NaN endpoint READ AS a sign change: the run
% printed "(brackets)" over an interval whose lower end was a solver failure.
% And even read correctly, expansion is the wrong response -- a NaN says the
% model stops being defined below some q, so the answer is to stop there.
%
% Each alpha now gets a coarse feasibility map, from which the largest
% CONTIGUOUS admissible interval is taken; the scan runs inside that interval
% and the root is bracketed only there. The centre is the PREVIOUS alpha's
% converged tree price -- continuation along alpha, which is the best
% available prior about where the admissible region is.
alphas = [0 0.5 1];
QS = cell(1,numel(alphas)); BK = cell(1,numel(alphas)); ROOT = cell(1,numel(alphas));
qc = eq0.q;
tee('===== q-feasibility diagnostic (alpha-continuation, serial) =====\n');
for ia = 1:numel(alphas)
    al = alphas(ia);
    B = kv_bracket_finite(@(qq) fk_code(qq, al, CTX), qc, ...
                          struct('span',QSPAN,'n',NCOARSE,'maxgrow',QGROW));
    BK{ia} = B;
    report_feasibility(tee, al, qc, B);
    if isnan(B.qlo)
        tee('  alpha %.2f: NO admissible q in the window. Scan skipped.\n\n', al);
        QS{ia} = []; continue;
    end
    % the diagnostic scan runs over the ADMISSIBLE interval, never past it
    QS{ia} = linspace(B.qlo, B.qhi, NQ);
    tee('  scanning %d nodes over the admissible interval [%.5f, %.5f]\n\n', ...
        NQ, B.qlo, B.qhi);
    % continuation: solve this alpha's root, and centre the next alpha on it
    if B.ok
        fev = @(qq) fk_code(qq, al, CTX);
        R = refine_root(fev, B);
        R.floor = floor_probe(fev, R.q, tee);
        ROOT{ia} = R;
        if isfinite(R.q), qc = R.q; end
        tee('  root q = %.6f, |F_k| = %.3e (%s)\n\n', R.q, abs(R.F), R.code);
    end
end
JOB_A = []; JOB_Q = [];
for ia = 1:numel(alphas)
    if isempty(QS{ia}), continue; end
    JOB_A = [JOB_A; repmat(ia, numel(QS{ia}), 1)];   %#ok<AGROW>
    JOB_Q = [JOB_Q; QS{ia}(:)];                      %#ok<AGROW>
end
nJ = numel(JOB_Q);
assert(nJ > 0, 'no admissible (alpha,q) node: the model does not solve anywhere in the window');

% ------------------------------------------------------------- the scan
% One worker per node. Nothing is shared, nothing is accumulated inside the
% loop: each iteration writes its own file and returns its own record, and
% the series are assembled afterwards.
par_ok = PARALLEL && COLDSTART;
if PARALLEL && ~COLDSTART
    tee('\n*** COLDSTART=false: warm starts chain the nodes, so the scan runs\n');
    tee('*** SERIALLY. A parallel run would not be the same computation.\n');
end
nw = 0;
if par_ok
    nw = kv_parpool(true, NWORKERS, true, tee, ...
                    {fullfile(rootdir,'src'), fullfile(projdir,'src_project')});
end
tee('\nscanning %d nodes (%d alpha x %d q) on %s\n', nJ, numel(alphas), NQ, ...
    ternstr(nw>0, sprintf('%d workers', nw), 'one worker (serial)'));

RECS = cell(nJ,1);
if nw > 0
    ctxB = CTX;                                  % broadcast once
    parfor j = 1:nJ
        RECS{j} = kv_scan_node(JOB_Q(j), alphas(JOB_A(j)), ctxB, ...
                               cachedir, gridkey, RESCAN);
    end
else
    for j = 1:nJ
        RECS{j} = kv_scan_node(JOB_Q(j), alphas(JOB_A(j)), CTX, ...
                               cachedir, gridkey, RESCAN);
    end
end
ncached = sum(cellfun(@(r) r.cached, RECS));
tee('  %d/%d nodes served from cache, %d computed (%.1f s so far)\n\n', ...
    ncached, nJ, nJ-ncached, toc(t0));

% ---------------------------------------------------- aggregate, then report
% AFTER every worker has finished, and in q order rather than completion
% order. kflip -- the staircase diagnostic -- is a difference between
% ADJACENT q nodes, so it is computed here from the stored policy-index maps
% rather than inside the loop; that also makes it independent of evaluation
% order, which the serial version was not.
R = struct();
for ia = 1:numel(alphas)
    sel = find(JOB_A == ia);
    R(ia).alpha = alphas(ia); R(ia).q = QS{ia};
    R(ia).up = assemble(RECS(sel));
    report_dir(tee, QS{ia}, R(ia).up, alphas(ia), TOPTOL);
end

% ------------------------------------------ parallel-equals-serial check
PC = struct('ran',false,'maxrel',NaN,'n',0);
if PARCHECK && nw > 0
    idx = unique(round(linspace(1, nJ, min(3,nJ))));
    dmax = 0;
    for t = idx
        r2 = kv_scan_node(JOB_Q(t), alphas(JOB_A(t)), CTX, cachedir, gridkey, true);
        r1 = RECS{t};
        if r1.ok && r2.ok
            dmax = max(dmax, abs(r1.Fk - r2.Fk)/max(abs(r2.Fk), 1e-12));
        else
            dmax = Inf;
        end
    end
    PC.ran = true; PC.maxrel = dmax; PC.n = numel(idx);
    tee('PARCHECK: %d nodes re-solved on the client with the cache off;\n', numel(idx));
    tee('  max relative |dF_k| vs the worker values = %.2e  %s\n', dmax, ...
        ternstr(dmax < 1e-10, 'PASS', 'FAIL -- the parallel run is NOT the serial run'));
    tee('  (tolerance is 1e-10 rather than bitwise: multithreaded reductions\n');
    tee('   need not associate identically, and that is not a defect.)\n\n');
end

% ---------------------------------------- warm-start hysteresis probe (C2)
% The real C2 test, and the only one with content: chained warm starts, up
% then down, serial by design.
HY = hysteresis_probe(QS, alphas, CTX, HPROBE, tee);

% ------------------------------------------------- root ordering across alpha
% The roots are a comparative static, and the paper's claim is about its
% SIGN. If the ordering of q across alpha is not stable to a pure grid
% change, the sign is not measurable yet -- which is a finding about the
% resolution, not about the economics, and has to be said before any
% derivative is taken.
qr = nan(1,numel(alphas));
for ia = 1:numel(alphas)
    if ~isempty(ROOT{ia}) && isfinite(ROOT{ia}.q), qr(ia) = ROOT{ia}.q; end
end
tee('\n===== ROOT PATH IN ALPHA =====\n');
tee('  q(alpha) = %s\n', vecstr6(qr));
if all(isfinite(qr))
    dq = diff(qr);
    mono = all(dq < 0) || all(dq > 0);
    spread = (max(qr)-min(qr))/max(abs(mean(qr)),eps);
    tee('  monotone in alpha: %d;  total spread %.2e of q\n', mono, spread);
    if ~mono
        tee('  *** The tree price is NOT monotone in the financing mix. With a\n');
        tee('  *** spread of %.1e and a root residual of ~%.0e, the ordering is\n', ...
            spread, max(abs(cellfun(@(x) x.F, ROOT(cellfun(@(x) ~isempty(x), ROOT))))));
        tee('  *** inside the solver noise: it is not yet a measurement.\n');
    end
end

% ---------------------------------------------------------------- verdict
report_table(tee, alphas, BK, ROOT, R, TOPTOL);
tee('\n===== DIAGNOSIS =====\n');
V = classify(R, tee, TOPTOL, HY);
V.kfac = kfac; V.bfac = bfac; V.widen = WID; V.toptol = TOPTOL;
V.parcheck = PC; V.nworkers = nw; V.gridkey = gridkey;
V.root = ROOT; V.bracket = BK;
V.roots_found = sum(cellfun(@(x) ~isempty(x) && isfinite(x.q), ROOT));
save(fullfile(projdir,'output','kv_residual_scan.mat'), ...
     'R','V','CTX','alphas','kfac','bfac','WID','TOPTOL','HY','PC','gridkey', ...
     'BK','ROOT');
tee('\n[main_kv_residual_scan] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function out = assemble(recs)
% Turn the per-node records into the ascending-in-q series the report reads.
% Runs only after every worker has finished.
    n = numel(recs);
    out = struct('Fk',nan(1,n),'Fb',nan(1,n),'P',nan(1,n),'dV',nan(1,n), ...
                 'ddist',nan(1,n),'mass',nan(1,n),'ksat',nan(1,n), ...
                 'bsat',nan(1,n),'kocc',nan(1,n),'bocc',nan(1,n), ...
                 'kflip',nan(1,n),'cswitch',nan(1,n),'Pits',nan(1,n), ...
                 'ok',false(1,n));
    % NOT inside the struct() call: struct() given a cell value REPLICATES
    % into a struct ARRAY (a 1xn array of structs, every numeric field
    % scalar), which is not what any of this code then indexes.
    out.code = repmat({''}, 1, n);
    prevIdx = []; prevBa = single([]);
    for i = 1:n
        r = recs{i};
        if isempty(r), prevIdx = []; continue; end
        out.code{i} = r.code;
        if isfield(r,'Pits'), out.Pits(i) = r.Pits; end
        if ~r.ok, prevIdx = []; continue; end
        out.ok(i) = true;
        out.Fk(i) = r.Fk; out.Fb(i) = r.Fb; out.P(i) = r.P;
        out.dV(i) = r.dV; out.ddist(i) = r.ddist; out.mass(i) = r.mass;
        out.ksat(i) = r.ksat; out.bsat(i) = r.bsat;
        out.kocc(i) = r.kocc; out.bocc(i) = r.bocc;
        % fraction of states whose ADJUSTER k-choice moved a grid index
        % between this q node and the previous one -- the staircase test.
        idx = r.kidx;
        if ~isempty(prevIdx) && isequal(size(idx), size(prevIdx))
            out.kflip(i) = mean(idx(:) ~= prevIdx(:));
        end
        prevIdx = idx;
        % the exact detector: polBa moves only when the argmax moves
        if isfield(r,'bapol'), ba = r.bapol; else, ba = single([]); end
        if ~isempty(prevBa) && isequal(size(ba), size(prevBa))
            out.cswitch(i) = mean(abs(double(ba(:)) - double(prevBa(:))) > ...
                                  1e-9*max(1, abs(double(prevBa(:)))));
        end
        prevBa = ba;
    end
end

function HY = hysteresis_probe(QS, alphas, CTX, npr, tee)
% The genuine C2 test. The main scan is cold-started, so ascending and
% descending passes there are the SAME computation and cannot disagree --
% which is why the round-1 hysteresis of exactly 0.00e+00 was an identity,
% not a finding. Here the value function is CHAINED from node to node, up
% then down over the same few q values, which is the only configuration in
% which the warm start can carry state. Serial by construction.
    HY = struct('ran',false,'max',NaN,'n',npr);
    if npr < 3, return; end
    tee('--- warm-start hysteresis probe (%d nodes per alpha, chained) ---\n', npr);
    worst = 0;
    for ia = 1:numel(alphas)
        qs = linspace(QS{ia}(1), QS{ia}(end), npr);
        fu = chain(qs,        alphas(ia), CTX);
        fd = chain(fliplr(qs), alphas(ia), CTX); fd = fliplr(fd);
        ok = isfinite(fu) & isfinite(fd);
        d = 0; sc = NaN;
        if any(ok)
            d = max(abs(fu(ok) - fd(ok)));
            sc = median(abs(diff(fu(ok))));      % the residual's own step scale
        end
        rel = d/max(sc, eps);
        worst = max(worst, rel);
        tee('    alpha %.2f: max |F_k(up)-F_k(down)| = %.2e, median |dF_k| = %.2e, ratio %.1e\n', ...
            alphas(ia), d, sc, rel);
    end
    HY.ran = true; HY.max = worst;
    % RELATIVE, not absolute. The previous 1e-8 absolute threshold flagged a
    % 6.35e-08 discrepancy as PATH DEPENDENCE on a residual whose own steps
    % between adjacent nodes are ~2.6e-02 -- a relative disagreement of 2e-06,
    % which is the VFI tolerance showing through, not the map depending on
    % the order it was evaluated in. Hysteresis only means something measured
    % against the scale of the thing it is perturbing.
    tee('    worst RELATIVE hysteresis = %.2e (gate 1e-3)\n\n', worst);
end

function f = chain(qs, al, CTX)
    f = nan(1,numel(qs)); W = [];
    for i = 1:numel(qs)
        st = kv_solve_bond_given_q(qs(i), al, CTX, W);
        if ~st.ok, W = []; continue; end
        W = st.sol.V;                            % the chaining that matters
        f(i) = st.Sk - CTX.Kbar;
    end
end

function [F, code] = fk_code(q, al, CTX)
% The reduced tree residual AND why it is what it is. Never returns a bare
% NaN: a caller that cannot tell "the root is far away" from "the model does
% not solve here" will eventually treat the second as the first.
    st = kv_solve_bond_given_q(q, al, CTX, []);
    code = st.code;
    if st.ok, F = st.Sk - CTX.Kbar; else, F = NaN; end
end

function R = refine_root(fev, B)
% Bisect the straddling pair, then POLISH. Confined to [B.lo, B.hi], both
% admissible by construction, so no iterate can leave the domain.
%
% The polish is not optional and its absence was distorting the report. S_k(q)
% is a step function -- the same discrete portfolio choice that makes S_b(P)
% one -- so bisection drives the bracket onto a JUMP and stops with the
% residual still at the jump's size. That is why the reported tree residuals
% at the roots were ~3e-3 while kv_solve_alpha, which has always polished,
% reaches far less: the scan was reporting a worse number than the production
% solver achieves, on the same economy. Golden section on |F_k| over the
% collapsed bracket returns the closest approach the discretization admits,
% which is the honest quantity to report and to gate.
    R = struct('q',NaN,'F',NaN,'code','','its',0,'pol',0,'bracket',NaN);
    a = B.lo; b = B.hi; fa = B.flo;
    for it = 1:40
        m = 0.5*(a+b);
        [fm, cm] = fev(m);
        if ~isfinite(fm)
            % An interior failure inside an admissible bracket is a solver
            % problem, not a bracketing problem, and must be said so.
            R.code = ['INTERIOR_' cm]; R.its = it; return;
        end
        R.q = m; R.F = fm; R.code = cm; R.its = it;
        if abs(fm) < 1e-9 || (b-a) < 1e-9*max(1,abs(m)), break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    R.bracket = b - a;
    if abs(R.F) < 1e-9, return; end               % exact zero found; nothing to polish
    gr = (sqrt(5)-1)/2;
    aa = max(a - 4*(b-a), B.lo); bb = min(b + 4*(b-a), B.hi);
    c1 = bb - gr*(bb-aa); c2 = aa + gr*(bb-aa);
    [f1, k1] = fev(c1); [f2, k2] = fev(c2);
    v1 = abs(f1); v2 = abs(f2);
    if ~isfinite(v1), v1 = Inf; end
    if ~isfinite(v2), v2 = Inf; end
    for it2 = 1:40
        if v1 < v2
            bb = c2; c2 = c1; v2 = v1; k2 = k1;
            c1 = bb - gr*(bb-aa); [f1, k1] = fev(c1); v1 = abs(f1);
            if ~isfinite(v1), v1 = Inf; end
        else
            aa = c1; c1 = c2; v1 = v2; k1 = k2;
            c2 = aa + gr*(bb-aa); [f2, k2] = fev(c2); v2 = abs(f2);
            if ~isfinite(v2), v2 = Inf; end
        end
        if (bb-aa) < 1e-10*max(1,abs(c1)), break; end
    end
    R.pol = it2;
    if v1 <= v2 && isfinite(v1)
        [R.F, R.code] = fev(c1); R.q = c1;
    elseif isfinite(v2)
        [R.F, R.code] = fev(c2); R.q = c2;
    end
end

function FL = floor_probe(fev, qr, tee)
% THE decisive experiment on the residual floor.
%
% Every gate downstream -- the Schur derivative, the Shapley decomposition --
% needs |F_k| far below the ~1e-2 the polished root now achieves, and there
% are only two possible reasons it stops there. Either F_k is STEEP but
% smooth near the root, in which case the floor is just resolution and more
% bisection reaches any tolerance; or F_k JUMPS across the root, in which
% case no q attains zero and 1e-2 is the true floor of this discretization.
% Those call for opposite responses and no amount of staring at the coarse
% scan separates them.
%
% So: 21 nodes across a window one thousandth as wide as the scan's. If F_k
% is monotone there and changes sign, the floor is resolution. If it steps
% across zero with a jump comparable to the achieved |F_k|, the floor is
% discretization, and the jump size IS the floor.
    FL = struct('span',NaN,'minF',NaN,'jump',NaN,'monotone',false, ...
                'crosses',false,'slope',NaN,'ok',false);
    if ~isfinite(qr), return; end
    span = 1e-3;                       % relative half-width
    n = 21;
    q = linspace(qr*(1-span), qr*(1+span), n);
    F = nan(1,n);
    for i = 1:n
        [F(i), c] = fev(q(i));
        if ~kv_is_admissible(c), F(i) = NaN; end
    end
    g = isfinite(F);
    if sum(g) < 5, return; end
    FL.ok = true; FL.span = span;
    Fg = F(g); qg = q(g);
    FL.minF = min(abs(Fg));
    d = diff(Fg);
    FL.monotone = all(d > 0) || all(d < 0);
    FL.crosses = any(sign(Fg(1:end-1)) ~= sign(Fg(2:end)));
    FL.jump = max(abs(d));
    FL.slope = (Fg(end)-Fg(1))/(qg(end)-qg(1));
    % A smooth steep function has max|dF| ~ |slope|*dq; a jump has max|dF|
    % much larger than that.
    dq = mean(diff(qg));
    smoothstep = abs(FL.slope)*dq;
    FL.jumpratio = FL.jump/max(smoothstep, eps);
    tee('  FLOOR probe at q=%.6f (+/-%.1e relative, %d nodes)\n', qr, span, n);
    tee('    min |F_k| here %.3e; largest step %.3e vs %.3e implied by the slope\n', ...
        FL.minF, FL.jump, smoothstep);
    tee('    monotone %d, crosses zero %d, step/smooth ratio %.1f -> %s\n', ...
        FL.monotone, FL.crosses, FL.jumpratio, ...
        ternstr(FL.jumpratio > 3, 'DISCRETIZATION floor (no q attains zero)', ...
                                   'RESOLUTION only (bisect further)'));
end

function report_feasibility(tee, al, qc, B)
% The per-alpha feasibility record: admissible interval, first failure and
% why, first sign change, and the boundary masses inside the domain.
    tee('  alpha %.2f  (centred on q = %.5f, %d evaluations, %d window growths)\n', ...
        al, qc, B.nev, B.grew);
    bad = ~strcmp(B.code,'OK') & ~strcmp(B.code,'BOUNDARY_HIT');
    if any(bad)
        u = unique(B.code(bad));
        tee('    failures: %d of %d nodes  [%s]\n', sum(bad), numel(B.code), ...
            strjoin(u, ', '));
        tee('    first non-admissible q  : %.5f\n', B.first_bad);
    else
        tee('    failures: none in the window\n');
    end
    if ~strcmp(B.pattern,'NONE')
        tee('    failure pattern         : %s\n', B.pattern);
    end
    if isnan(B.qlo)
        tee('    admissible q interval   : EMPTY\n');
        return;
    end
    tee('    admissible q interval   : [%.5f, %.5f]  (%s)\n', B.qlo, B.qhi, B.status);
    if strcmp(B.pattern,'SCATTERED')
        tee('      *** Failures INTERLEAVED with successes. A domain boundary cannot\n');
        tee('      *** do that -- the model does not stop existing and start again --\n');
        tee('      *** so this indicts the SOLVER, not the calibration. Do not move the\n');
        tee('      *** bracket and do not widen anything until it is gone.\n');
    end
    if B.ok
        tee('    first sign change in F_k: %.5f  (F_k %.3e -> %.3e)\n', ...
            B.first_sign, B.flo, B.fhi);
    else
        tee('    first sign change in F_k: NONE inside the admissible interval\n');
        if strcmp(B.status,'DOMAIN_TRUNCATED_BY_WINDOW')
            tee('      the admissible run reaches a window edge, so the domain was\n');
            tee('      cut by the window; widen QSPAN and rerun this alpha.\n');
        elseif strcmp(B.status,'SOLVER_SCATTERED')
            tee('      and the failures are interleaved, so nothing about the DOMAIN\n');
            tee('      can be concluded here at all. Fix the solver first.\n');
        else
            tee('      the admissible run is strictly interior AND the failures form a\n');
            tee('      clean tail, so the MODEL bounds the domain. A wider window would\n');
            tee('      only add more failures -- there is no admissible root here.\n');
        end
    end
end

function report_table(tee, alphas, BK, ROOT, R, TOPTOL)
% The compact per-alpha status table.
    tee('\n===== PER-ALPHA STATUS =====\n');
    tee(['%5s %22s %11s %11s %12s %12s %10s %10s %10s  %s\n'], ...
        'alpha','finite q interval','first NaN','first sign','bond resid', ...
        'tree resid','hh dV','b-top','k-top','status');
    for ia = 1:numel(alphas)
        B = BK{ia};
        fb = NaN; ft = NaN; dv = NaN; bs = NaN; ks = NaN; stat = 'NO_DOMAIN';
        if ia <= numel(R) && ~isempty(R(ia).up.ok) && any(R(ia).up.ok)
            ok = R(ia).up.ok;
            fb = max(abs(R(ia).up.Fb(ok)));
            dv = max(R(ia).up.dV(ok));
            bs = max(R(ia).up.bsat(ok));
            ks = max(R(ia).up.ksat(ok));
        end
        if ~isempty(ROOT{ia}) && isfinite(ROOT{ia}.F)
            ft = ROOT{ia}.F; stat = ROOT{ia}.code;
        elseif ~isnan(B.qlo)
            stat = B.status;
        end
        if isnan(B.qlo), iv = 'EMPTY';
        else, iv = sprintf('[%.4f,%.4f]', B.qlo, B.qhi);
        end
        tee('%5.2f %22s %11s %11s %12.3e %12.3e %10.1e %10.2e %10.2e  %s\n', ...
            alphas(ia), iv, numstr(B.first_bad), numstr(B.first_sign), ...
            fb, ft, dv, bs, ks, stat);
    end
    tee('  (boundary tolerance %.0e; tree resid is at the SOLVED root, bond\n', TOPTOL);
    tee('   resid is the worst over the scanned admissible interval)\n');
end

function s = vecstr6(v)
    s = sprintf('%.6f ', v); s = strtrim(s);
end

function s = numstr(x)
    if isnan(x), s = '--'; else, s = sprintf('%.4f', x); end
end

function n = nsignchg(u)
% Sign changes counted only between ADJACENT ADMISSIBLE nodes. Compressing
% the failures out first (Fk(ok)) would splice the two sides of a hole in the
% domain together and manufacture a crossing that no continuous path takes.
    F = u.Fk; ok = u.ok;
    n = 0;
    for i = 1:numel(F)-1
        if ok(i) && ok(i+1) && isfinite(F(i)) && isfinite(F(i+1)) ...
                && sign(F(i)) ~= sign(F(i+1)) && sign(F(i)) ~= 0
            n = n + 1;
        end
    end
end

function [p, kfac, bfac, W] = widen_until_interior(CTX, REFW, kfac, bfac, kcap, bcap, tol, tee)
% Size the widening from the model rather than from a guess: re-solve the
% bond market at the interior alpha and measure the top-two-node masses,
% doubling kmax until the k-boundary is interior, then -- only if the
% b-boundary is STILL bound after the k repair, which is the condition under
% which the bond grid may be touched at all -- doubling bmax.
%
% The probe is one bond-market solve per rung. The full scan is 366 of them,
% so a handful of rungs is free by comparison, and it collapses what would
% otherwise be several human-in-the-loop rounds into one run.
    tee('--- boundary probe: target top-two-node mass < %.0e on BOTH grids ---\n', tol);
    [p, W, ks, bs, ko, bo] = probe_widen(CTX, REFW, kfac, bfac);
    rung(tee, kfac, bfac, W, ks, bs, ko, bo);
    while isfinite(ks) && ks > tol && kfac*2 <= kcap
        kfac = kfac*2;
        [p, W, ks, bs, ko, bo] = probe_widen(CTX, REFW, kfac, bfac);
        rung(tee, kfac, bfac, W, ks, bs, ko, bo);
    end
    % BACKTRACK. Doubling overshoots: the ladder stops at the first rung that
    % clears, but the rung BELOW it may clear too, and every doubling of kmax
    % costs resolution in the tail at a fixed node count. Walk back down while
    % the boundary stays interior, so the widening is the smallest on the
    % lattice that works rather than the first that works.
    while isfinite(ks) && ks < tol && kfac > 1
        [p2, W2, ks2, bs2, ko2, bo2] = probe_widen(CTX, REFW, kfac/2, bfac);
        if ~(isfinite(ks2) && ks2 < tol), break; end
        kfac = kfac/2; p = p2; W = W2; ks = ks2; bs = bs2; ko = ko2; bo = bo2;
        rung(tee, kfac, bfac, W, ks, bs, ko, bo);
    end
    % IS THE b-TAIL TRUNCATED OR JUST FAT? If the top-of-grid mass falls
    % roughly in proportion to bmax when bmax doubles, the tail is being cut
    % off and widening is the fix. If it barely moves, the mass is a genuine
    % feature of the calibration and no widening will remove it -- the payout
    % rule and the superstar state are then the place to look, not the grid.
    % One extra probe answers this and it is the difference between a numerics
    % problem and a modelling one.
    if bfac > 1 && isfinite(bs)
        [~, Wh, ksh, bsh] = probe_widen(CTX, REFW, kfac, bfac/2);
        if isfinite(bsh)
            ratio = bsh/max(bs, eps);
            tee('    b-TAIL TEST: halving bmax %.1f -> %.1f raises b-top mass %.2e -> %.2e\n', ...
                Wh.bmax*2, Wh.bmax, bs, bsh);
            tee('      ratio %.2f  -> %s\n', ratio, ternstr(ratio > 1.6, ...
                'TRUNCATION (mass scales with the ceiling; widen further)', ...
                'GENUINE TAIL (widening barely moves it; look at the payout rule)'));
            if abs(ksh - ks)/max(ks,eps) > 1, ...
                tee('      note: this also moved k-top mass %.2e -> %.2e; the grids are COUPLED\n', ks, ksh);
            end
        end
    end
    if isfinite(bs) && bs > tol
        if bcap <= 1
            tee('    b-boundary is still bound (%.2e) but the bond grid is FROZEN by\n', bs);
            tee('    BFACMAX=1: it moves only if the finite-domain scan confirms it,\n');
            tee('    and only with the k-grid held still.\n');
        else
            tee('    b-boundary still bound after the k repair: the bond grid may now move.\n');
            while isfinite(bs) && bs > tol && bfac*2 <= bcap
                bfac = bfac*2;
                [p, W, ks, bs, ko, bo] = probe_widen(CTX, REFW, kfac, bfac);
                rung(tee, kfac, bfac, W, ks, bs, ko, bo);
            end
        end
    end
    if ~isfinite(ks)
        tee('    PROBE FAILED to solve; falling back to kfac=%.1f bfac=%.1f unverified.\n', kfac, bfac);
    elseif ks > tol
        tee('    k-BOUNDARY CAP REACHED: ksat %.2e still above %.0e at kfac=%.0f.\n', ks, tol, kfac);
        tee('    The scan runs anyway so the gate reports the true masses, but a\n');
        tee('    k-boundary that will not go interior at any factor is not a grid\n');
        tee('    problem: re-examine the superstar state and the payout rule.\n');
    elseif bs > tol && bcap <= 1
        % NOT a cap failure. The k side cleared and the b side was held on
        % purpose, so saying "cap reached" here reads as a defeat when it is
        % the design.
        tee('    k-boundary CLEAR at kfac=%.0f (%.2e). b-boundary %.2e is above %.0e\n', ...
            kfac, ks, bs, tol);
        tee('    but the bond grid was held fixed on purpose, so this is the expected\n');
        tee('    state of the controlled experiment, not a failure of the ladder.\n');
    elseif bs > tol
        tee('    b-BOUNDARY CAP REACHED: bsat %.2e still above %.0e at bfac=%.0f.\n', bs, tol, bfac);
    end
    if W.changed
        tee('    kmax %.1f -> %.1f, bmax %.2f -> %.2f, xmax %.1f -> %.1f\n', ...
            W.kmax0, W.kmax, W.bmax0, W.bmax, W.xmax0, W.xmax);
        tee('    curvature k %.2f -> %.2f (nodes below k=%.1f: %d -> %d, held fixed)\n', ...
            W.gk0, W.gk, W.kref, W.n_below_kref0, W.n_below_kref);
        tee('    max attainable adjuster k'': %.1f -> %.1f (outlay ceiling)\n', ...
            W.kprime_max0, W.kprime_max);
        tee('    NOTE beta and chi_b were calibrated on the OLD grids; recalibrate\n');
        tee('    main_twoasset_ownership_kv before any of this is final.\n');
    end
    tee('\n');
end

function rung(tee, kfac, bfac, W, ks, bs, ko, bo)
    tee(['    kfac %5.1f bfac %5.1f | kmax %7.1f bmax %6.2f xmax %7.1f' ...
         ' -> ksat %.2e bsat %.2e (support %.2f/%.2f of the tops)\n'], ...
        kfac, bfac, W.kmax, W.bmax, W.xmax, ks, bs, ko, bo);
end

function [p, W, ks, bs, ko, bo] = probe_widen(CTX, REFW, kfac, bfac)
% ALWAYS widens from the ORIGINAL grids, never cumulatively, so a rung is a
% function of (kfac,bfac) alone and the ladder is reproducible.
    R = REFW; R.bfac = bfac;
    [p, W] = kv_widen_grids(CTX.p, kfac, R);
    C = CTX; C.p = p;
    st = kv_solve_bond_given_q(REFW.q*(1-0.02*0.5), 0.5, C, []);
    if ~st.ok, ks = NaN; bs = NaN; ko = NaN; bo = NaN; return; end
    [ks, bs, ko, bo] = kv_boundary_mass(st.dist, p.kGrid, p.bGrid);
end

function report_dir(tee, qs, up, al, tol)
    ok = up.ok;
    if ~any(ok), tee('  no node solved.\n\n'); return; end
    tee('  |Fk| range          : [%.2e, %.2e]\n', min(abs(up.Fk(ok))), max(abs(up.Fk(ok))));
    tee('  sign changes        : %d (adjacent admissible nodes only)\n', nsignchg(up));
    d1 = diff(up.Fk(ok));
    if numel(d1) > 3
        tee('  step structure      : median |dFk| %.2e, max |dFk| %.2e, ratio %.1f\n', ...
            median(abs(d1)), max(abs(d1)), max(abs(d1))/max(median(abs(d1)),eps));
    end
    tee('  household dV        : max %.2e   distribution dv: max %.2e\n', ...
        max(up.dV(ok)), max(up.ddist(ok)));
    tee('  mass error          : max %.2e\n', max(up.mass(ok)));
    pit = up.Pits(isfinite(up.Pits));
    if ~isempty(pit)
        tee('  bond-solve cost     : median %.0f, max %.0f household solves per node\n', ...
            median(pit), max(pit));
    end
    % BOUNDARY GATE AT THE ROOT, not over the whole sweep. The sweep spans
    % +/-25% of q by design and so deliberately visits prices far from
    % equilibrium, where trees are cheap and the k-tail naturally piles up.
    % Gating on the worst node of that sweep condemns grids that are perfectly
    % adequate AT the equilibrium, which is the only place the aggregates are
    % ever evaluated. The sweep maximum is still reported, as context.
    [ksR, bsR, koR, boR, qR] = at_root(up, qs);
    tee('  boundary mass AT ROOT (q=%.4f): k %.2e [%s], b %.2e [%s]  (tol %.0e)\n', ...
        qR, ksR, ternstr(ksR < tol,'PASS','FAIL'), bsR, ...
        ternstr(bsR < tol,'PASS','FAIL'), tol);
    tee('    over the whole sweep : k %.2e, b %.2e (context, NOT the gate)\n', ...
        max(up.ksat(ok)), max(up.bsat(ok)));
    tee('  occupied support at root: k %.2f of kmax, b %.2f of bmax\n', koR, boR);
    kf = up.kflip(~isnan(up.kflip));
    if ~isempty(kf)
        % Flips per q STEP are not comparable across scans: a wider window at
        % the same node count means bigger steps and mechanically more index
        % changes. Round 1 swept +/-2%, this one +/-25%, so the raw rate rose
        % about tenfold for that reason alone. Normalise by the relative step.
        rel = 100*mean(diff(qs))/max(mean(qs), eps);
        tee('  k-policy index flips: mean %.3f per q step = %.3f per 1%% of q\n', ...
            mean(kf), mean(kf)/max(rel, eps));
    end
    cs = up.cswitch(~isnan(up.cswitch));
    if ~isempty(cs)
        tee('  adjuster candidate switches: mean %.3f of states per q step\n', mean(cs));
    end
    [fr, nf, nn, src] = flip_ratio(up);
    if isfinite(fr)
        tee('  STAIRCASE test      : median |dFk| on HIGH- vs LOW-switch q steps\n');
        tee('                        = %.2f  (%d vs %d steps, detector: %s)\n', ...
            fr, nf, nn, src);
        tee('                        -> %s\n', ...
            ternstr(fr > 3, 'DISCRETE', 'curvature, not discreteness'));
    end
    cs = up.code(~cellfun(@isempty, up.code));
    if ~isempty(cs)
        u = unique(cs);
        cnt = cellfun(@(c) sum(strcmp(cs,c)), u);
        [~, o2] = sort(cnt, 'descend');
        parts = arrayfun(@(i) sprintf('%s x%d', u{o2(i)}, cnt(o2(i))), ...
                         1:numel(u), 'UniformOutput', false);
        tee('  status codes        : %s\n', strjoin(parts, ', '));
        nstep = sum(strcmp(cs,'BOND_STEP'));
        if nstep > 0
            tee('    of which %d cleared the BOND market only to within one jump of the\n', nstep);
            tee('    discrete portfolio choice (BOND_STEP): admissible, but the achieved\n');
            tee('    |F_b| is the floor on any derivative taken through P.\n');
        end
    end
    tee('\n');
end

function [r, nf, nn, src] = flip_ratio(up)
% THE staircase test. The old one was max|dF_k| / median|dF_k| over the
% window, and it does not measure what it claims: F_k sweeps four orders of
% magnitude across a +/-25% q window, so a smooth but steeply curved residual
% produces a large ratio with no discreteness anywhere. Round 3 reported
% "jump ratio 31.5 -> staircase PRESENT" on exactly that basis.
%
% A staircase has a signature curvature does not: the big steps in F_k are
% the ones where households actually CHANGE their k grid index. So compare
% the typical |dF_k| on steps where the adjuster policy moved against those
% where it did not. Curvature raises both; discreteness raises only the
% first. r >> 1 is a staircase; r ~ 1 says the jumps are curvature.
    r = NaN; nf = 0; nn = 0; src = 'candidate switch';
    F = up.Fk; ok = up.ok;
    kf = up.cswitch;
    if all(isnan(kf)), kf = up.kflip; src = 'k-grid index (lossy fallback)'; end
    n = numel(F); d = nan(1,n-1); f = nan(1,n-1);
    for j = 1:n-1
        if ok(j) && ok(j+1) && isfinite(F(j)) && isfinite(F(j+1))
            d(j) = abs(F(j+1) - F(j));
            f(j) = kf(j+1);            % flips BETWEEN node j and node j+1
        end
    end
    good = isfinite(d) & isfinite(f);
    if sum(good) < 8, return; end
    % MEDIAN SPLIT, not "flips vs no flips". About 7.5% of states change index
    % at EVERY q step at this window width, so the zero-flip group is empty
    % and the test could never fire -- which is why it reported "not enough
    % steps of each kind". Splitting at the median flip rate always has both
    % groups and asks the same question: do the steps where more households
    % switch move the residual more?
    fg = f(good); dg = d(good);
    m = median(fg);
    hi = fg > m; lo = fg <= m;
    nf = sum(hi); nn = sum(lo);
    if nf >= 3 && nn >= 3
        r = median(dg(hi))/max(median(dg(lo)), eps);
    end
end

function [ks, bs, ko, bo, qr] = at_root(up, qs)
% Diagnostics at the admissible node closest to clearing the tree market.
    ks = NaN; bs = NaN; ko = NaN; bo = NaN; qr = NaN;
    ok = up.ok & isfinite(up.Fk);
    if ~any(ok), return; end
    idx = find(ok);
    [~, j] = min(abs(up.Fk(idx)));
    i = idx(j);
    ks = up.ksat(i); bs = up.bsat(i); ko = up.kocc(i); bo = up.bocc(i);
    if numel(qs) >= i, qr = qs(i); end
end

function V = classify(R, tee, tol, HY)
    V = struct();
    kflip = 0; ksat = 0; bsat = 0; dV = 0; ratio = 0; nsign = 0; fliprat = NaN;
    kocc = 0; bocc = 0;
    hyst = NaN; if nargin >= 4 && HY.ran, hyst = HY.max; end   % RELATIVE
    for ia = 1:numel(R)
        ok = R(ia).up.ok;
        if ~any(ok), continue; end
        kf = R(ia).up.kflip(~isnan(R(ia).up.kflip));
        if ~isempty(kf), kflip = max(kflip, mean(kf)); end
        [ksR, bsR, koR, boR] = at_root(R(ia).up, R(ia).q);
        if isfinite(ksR), ksat = max(ksat, ksR); end
        if isfinite(bsR), bsat = max(bsat, bsR); end
        if isfinite(koR), kocc = max(kocc, koR); end
        if isfinite(boR), bocc = max(bocc, boR); end
        dV    = max(dV,    max(R(ia).up.dV(ok)));
        nsign = nsign + (nsignchg(R(ia).up) > 0);
        d1 = diff(R(ia).up.Fk(ok));
        if numel(d1) > 3
            ratio = max(ratio, max(abs(d1))/max(median(abs(d1)),eps));
        end
        fr = flip_ratio(R(ia).up);
        if isfinite(fr), fliprat = max(fliprat, fr); end
    end
    V.hysteresis = hyst; V.kflip = kflip; V.ksat = ksat; V.bsat = bsat;
    V.kocc = kocc; V.bocc = bocc;
    V.dV = dV; V.jumpratio = ratio; V.fliprat = fliprat;
    V.n_alpha_bracketed = nsign;
    V.kpass = ksat < tol; V.bpass = bsat < tol;
    V.boundary_pass = V.kpass && V.bpass;
    if isnan(hyst)
        tee('  C2 path dependence  : NOT TESTED (probe disabled)\n');
    else
        tee(['  C2 path dependence  : warm-start probe, hysteresis / median |dFk| = %.2e -> %s\n' ...
             '                        (the COLD scan is order-free by construction,\n' ...
             '                         so it cannot test this and is not used to)\n'], ...
            hyst, ternstr(hyst > 1e-3, 'PRESENT', 'absent'));
    end
    tee('  C3 grid boundaries  : AT THE ROOT, k %.2e [%s], b %.2e [%s]  (tol %.0e)\n', ...
        ksat, ternstr(V.kpass,'PASS','FAIL'), bsat, ternstr(V.bpass,'PASS','FAIL'), tol);
    tee('       occupied support: k %.2f, b %.2f of the grid tops at the root\n', kocc, bocc);
    tee('  C1 hh convergence   : max VFI dV = %.2e                -> %s\n', dV, ...
        ternstr(dV > 1e-5, 'SUSPECT', 'clear'));
    c4 = isfinite(fliprat) && fliprat > 3;
    if isfinite(fliprat)
        tee('  C4 discrete k-choice: |dFk| on high-flip vs low-flip q steps = %.2f -> %s\n', ...
            fliprat, ternstr(c4, 'PRESENT (staircase)', 'NOT indicated (jumps are curvature)'));
    else
        tee('  C4 discrete k-choice: not enough steps of each kind to test\n');
    end
    tee('       (raw max/median |dFk| = %.1f, reported only for continuity with\n', ratio);
    tee('        earlier rounds -- it cannot separate a staircase from curvature)\n');
    tee('  root bracketed      : %d of %d alphas show a sign change in F_k\n', nsign, numel(R));
    tee('\n  VERDICT: ');
    if ~V.kpass
        tee('THE k-BOUNDARY IS STILL BINDING AT THE ROOT (%.2e).\n', ksat);
        tee('  Raise KFAC and rerun. If it will not go interior at any factor the tail\n');
        tee('  is not a grid artefact: re-examine the superstar state and the payout rule.\n');
    elseif ~V.bpass
        tee('THE k-BOUNDARY IS CLEAR; the b-boundary is not (%.2e at the root).\n', bsat);
        tee('  That is exactly the condition under which the bond grid may move, and it\n');
        tee('  may now move with the k-grid HELD STILL -- the controlled experiment the\n');
        tee('  freeze was for. Rerun with BFAC = 8 and KFAC unchanged.\n');
    elseif dV > 1e-5
        tee('HOUSEHOLD CONVERGENCE. Tighten tol_vfi and rescan before changing the policy.\n');
    elseif c4
        tee('REPRODUCIBLE STAIRCASE from the discrete k-choice, now measured on grids\n');
        tee('  the distribution can cross -- so this is a statement about the POLICY,\n');
        tee('  which it was not while the boundary was binding.\n');
        tee('  Proceed to the continuous adjuster policy: interpolate the\n');
        tee('  continuation value, refine the optimum between neighbouring k\n');
        tee('  nodes, and push the distribution by bilinear lottery over (b,k).\n');
    else
        tee('BOUNDARY CLEAR and no other cause indicated. Re-solve the stationary\n');
        tee('  equilibrium on the widened grid and rebuild the Schur derivative.\n');
        tee('  Recalibrate main_twoasset_ownership_kv first: the widening moves the\n');
        tee('  wealth moments beta and chi_b were set to hit.\n');
    end
    % Warm-start hysteresis is reported separately because it does not bear on
    % the cold scan above -- that scan carries no state to be path dependent
    % about. It bears on the WARM-STARTED solvers used elsewhere: the
    % continuation in kv_solve_alpha, the transition kernels, the Shapley
    % evaluations that share CTX.W0.
    if ~isnan(hyst) && hyst > 1e-3
        tee('\n  SEPARATELY: the warm-start probe DOES show hysteresis (%.2e relative). The cold\n', hyst);
        tee('  scan is unaffected, but every warm-started solver in the project is\n');
        tee('  suspect until this is explained -- starting with kv_solve_alpha, whose\n');
        tee('  inner fixed point chains the value function across trial tree prices.\n');
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
