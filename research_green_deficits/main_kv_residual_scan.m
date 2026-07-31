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
% The scan runs ASCENDING and DESCENDING over the same q nodes so (C2) is
% testable, and never reuses a value function across nodes within a
% direction unless COLDSTART is false.
%
% ---------------------------------------------------------------------
% ROUND 2: THE BOUNDARY REPAIR.
%
% Round 1 answered the question. Hysteresis was exactly 0.00e+00 at every
% alpha, so the residual IS a function of q and (C2) is dead. VFI dV stayed
% below 1e-6 and the distribution residual below 1e-11, so (C1) is dead. What
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
% USAGE   >> clear; main_kv_residual_scan
%         >> clear; FAST = true; main_kv_residual_scan     (coarse grids)
%         >> clear; NQ = 121; main_kv_residual_scan        (finer scan)
%         >> clear; COLDSTART = false; main_kv_residual_scan
%         >> clear; NOWIDEN = true; main_kv_residual_scan  (round-1 grids)
%         >> clear; KFAC = 12; main_kv_residual_scan       (force a widening)
%
% OUTPUT  output/tables/kv_residual_scan.txt
%         output/kv_residual_scan.mat   (per-node record + chosen kfac/bfac)

clearvars -except FAST NQ COLDSTART NOWIDEN KFAC BFAC TOPTOL KFACMAX BFACMAX; close all; clc;
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
if ~exist('KFAC','var') || isempty(KFAC), KFAC = 6; end     % initial kmax x6
if ~exist('BFAC','var') || isempty(BFAC), BFAC = 1; end     % bond grid untouched
if ~exist('TOPTOL','var') || isempty(TOPTOL), TOPTOL = 1e-4; end
if ~exist('KFACMAX','var') || isempty(KFACMAX), KFACMAX = 48; end
if ~exist('BFACMAX','var') || isempty(BFACMAX), BFACMAX = 16; end
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

alphas = [0 0.5 1];
R = struct();
for ia = 1:numel(alphas)
    al = alphas(ia);
    qc = eq0.q * (1 - 0.02*al);                 % candidate root, drifts with alpha
    tee('===== alpha = %.2f =====\n', al);
    qs = bracket_q(qc, al, CTX, NQ, 0.02, tee);
    tee('  scanning %d nodes over q in [%.5f, %.5f]\n', NQ, qs(1), qs(end));
    up   = scan_dir(qs,        al, CTX, COLDSTART);
    down = scan_dir(fliplr(qs), al, CTX, COLDSTART);
    down = flip_struct(down);                    % back to ascending order
    R(ia).alpha = al; R(ia).q = qs; R(ia).up = up; R(ia).down = down;
    report_dir(tee, qs, up, down, al, TOPTOL);
end

% ---------------------------------------------------------------- verdict
tee('\n===== DIAGNOSIS =====\n');
V = classify(R, tee, TOPTOL);
V.kfac = kfac; V.bfac = bfac; V.widen = WID; V.toptol = TOPTOL;
save(fullfile(projdir,'output','kv_residual_scan.mat'), ...
     'R','V','CTX','alphas','kfac','bfac','WID','TOPTOL');
tee('\n[main_kv_residual_scan] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function out = scan_dir(qs, al, CTX, cold)
    n = numel(qs);
    out = struct('Fk',nan(1,n),'Fb',nan(1,n),'P',nan(1,n),'dV',nan(1,n), ...
                 'ddist',nan(1,n),'mass',nan(1,n),'ksat',nan(1,n), ...
                 'bsat',nan(1,n),'kocc',nan(1,n),'bocc',nan(1,n), ...
                 'kflip',nan(1,n),'ok',false(1,n));
    W = []; prevIdx = [];
    for i = 1:n
        st = solve_bond_given_q(qs(i), al, CTX, W);
        if ~st.ok, continue; end
        if ~cold, W = st.sol.V; end
        out.ok(i) = true;
        out.Fk(i) = st.Sk - CTX.Kbar;
        out.Fb(i) = st.Sb - CTX.iota*CTX.Bnom/st.P;
        out.P(i)  = st.P;  out.dV(i) = st.dV;  out.ddist(i) = st.ddist;
        out.mass(i) = abs(1 - sum(st.dist(:)));
        [out.ksat(i), out.bsat(i), out.kocc(i), out.bocc(i)] = ...
            boundary_mass(st.dist, CTX.p.kGrid, CTX.p.bGrid);
        % fraction of states whose ADJUSTER k-choice moved a grid index
        kG = CTX.p.kGrid(:);
        kp = st.sol.polKa;                       % nx x ne
        idx = discretize(min(max(kp,kG(1)),kG(end)), kG);
        idx(isnan(idx)) = 1;
        if ~isempty(prevIdx) && isequal(size(idx),size(prevIdx))
            out.kflip(i) = mean(idx(:) ~= prevIdx(:));
        end
        prevIdx = idx;
    end
end

function st = solve_bond_given_q(q, al, CTX, W)
% solve ONLY the bond market conditional on q: P = iota*B/S_b with tau and
% div consistent with that P. The tree market is left as the residual.
    st = struct('ok',false);
    pe = CTX.p;
    vth = al * CTX.g_real / (1 - CTX.D0);
    pe.eGrid = (1 - CTX.D0) * (1 - vth) * CTX.p.eGrid;
    P = CTX.iota*CTX.Bnom/0.30; o = [];
    for it = 1:80
        tau = CTX.r_b*(CTX.Bnom/P) + (1-al)*CTX.g_real;
        dvd = CTX.d_base + CTX.r_b*(1-CTX.iota)*(CTX.Bnom/P)/CTX.Kbar;
        o = kv_stationary_block(CTX.r_b, q, dvd, tau, pe, W);
        if ~o.ok, return; end
        W = o.sol.V;
        Pn = CTX.iota*CTX.Bnom/max(o.Sb,1e-12);
        if abs(Pn-P) < 1e-13*max(1,abs(P)), P = Pn; break; end
        P = 0.5*P + 0.5*Pn;
    end
    st = struct('ok',true,'P',P,'Sb',o.Sb,'Sk',o.Sk,'sol',o.sol, ...
                'dist',o.dist,'dV',o.dV,'ddist',o.ddist);
end

function qs = bracket_q(qc, al, CTX, NQ, span, tee)
% The +/-2% window around the pre-widening q was calibrated to the OLD grids.
% Widening kmax changes S_k at every q, so the root moves and a fixed window
% can easily miss it -- a scan that never crosses zero says nothing about
% whether the market clears. Expand the window geometrically until the
% endpoints straddle, and say so when the expansion was needed: a root that
% has walked far from eq0.q is itself a finding about how much the truncation
% was distorting the equilibrium.
    lo = qc*(1-span); hi = qc*(1+span);
    flo = fk_at(lo, al, CTX); fhi = fk_at(hi, al, CTX);
    nexp = 0;
    while isfinite(flo) && isfinite(fhi) && sign(flo) == sign(fhi) && nexp < 6
        span = span*2; nexp = nexp + 1;
        lo = max(qc*(1-span), 0.05*qc); hi = qc*(1+span);
        flo = fk_at(lo, al, CTX); fhi = fk_at(hi, al, CTX);
    end
    if nexp > 0
        tee('  q window expanded %dx to +/-%.1f%%: F_k(%.4f)=%.2e, F_k(%.4f)=%.2e %s\n', ...
            2^nexp, 100*span, lo, flo, hi, fhi, ...
            ternstr(sign(flo)~=sign(fhi), '(brackets)', '(STILL NO SIGN CHANGE)'));
    end
    qs = linspace(lo, hi, NQ);
end

function v = fk_at(q, al, CTX)
    st = solve_bond_given_q(q, al, CTX, []);
    if st.ok, v = st.Sk - CTX.Kbar; else, v = NaN; end
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
    if isfinite(bs) && bs > tol
        tee('    b-boundary still bound after the k repair: the bond grid may now move.\n');
        while isfinite(bs) && bs > tol && bfac*2 <= bcap
            bfac = bfac*2;
            [p, W, ks, bs, ko, bo] = probe_widen(CTX, REFW, kfac, bfac);
            rung(tee, kfac, bfac, W, ks, bs, ko, bo);
        end
    end
    if ~isfinite(ks)
        tee('    PROBE FAILED to solve; falling back to kfac=%.1f bfac=%.1f unverified.\n', kfac, bfac);
    elseif ks > tol || bs > tol
        tee('    CAP REACHED with ksat %.2e bsat %.2e still above %.0e.\n', ks, bs, tol);
        tee('    The scan runs anyway so the gate reports the true masses, but a\n');
        tee('    boundary that will not go interior at kfac=%.0f is not a grid\n', kfac);
        tee('    problem: re-examine the superstar state and the payout rule.\n');
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
    st = solve_bond_given_q(REFW.q*(1-0.02*0.5), 0.5, C, []);
    if ~st.ok, ks = NaN; bs = NaN; ko = NaN; bo = NaN; return; end
    [ks, bs, ko, bo] = boundary_mass(st.dist, p.kGrid, p.bGrid);
end

function [ks, bs, ko, bo] = boundary_mass(dist, kG, bG)
% ks, bs : share of mass in the top TWO nodes -- the truncation gate.
% ko, bo : highest OCCUPIED node as a fraction of the grid top. This guards
%   the gate against being passed by stretching rather than by fixing: a top
%   mass that falls only because the top two nodes now sit far beyond any
%   household shows up here as ko well below 1, whereas a genuinely interior
%   distribution shows the same. ko ~ 1 with a small top mass means the
%   support still reaches the ceiling and the widening was cosmetic.
    km = squeeze(sum(sum(dist,1),3)); km = km(:);
    bm = squeeze(sum(sum(dist,2),3)); bm = bm(:);
    ks = sum(km(max(1,end-1):end))/max(sum(km),eps);
    bs = sum(bm(max(1,end-1):end))/max(sum(bm),eps);
    ko = NaN; bo = NaN;
    if nargin >= 3
        ik = find(km > 1e-8, 1, 'last'); ib = find(bm > 1e-8, 1, 'last');
        if ~isempty(ik), ko = kG(ik)/kG(end); end
        if ~isempty(ib), bo = bG(ib)/bG(end); end
    end
end

function s = flip_struct(s)
    f = fieldnames(s);
    for i = 1:numel(f), s.(f{i}) = fliplr(s.(f{i})); end
end

function report_dir(tee, qs, up, dn, al, tol)
    ok = up.ok & dn.ok;
    if ~any(ok), tee('  no node solved.\n\n'); return; end
    hyst = max(abs(up.Fk(ok) - dn.Fk(ok)));
    tee('  |Fk| range          : [%.2e, %.2e]\n', min(abs(up.Fk(ok))), max(abs(up.Fk(ok))));
    tee('  sign changes (up)   : %d\n', sum(diff(sign(up.Fk(ok)))~=0));
    tee('  HYSTERESIS up vs dn : max |dFk| = %.2e  %s\n', hyst, ...
        ternstr(hyst < 1e-8,'(none: the map is a function of q)', ...
                            '(PATH DEPENDENT -- warm start carries state)'));
    d1 = diff(up.Fk(ok));
    if numel(d1) > 3
        tee('  step structure      : median |dFk| %.2e, max |dFk| %.2e, ratio %.1f\n', ...
            median(abs(d1)), max(abs(d1)), max(abs(d1))/max(median(abs(d1)),eps));
    end
    tee('  household dV        : max %.2e   distribution dv: max %.2e\n', ...
        max(up.dV(ok)), max(up.ddist(ok)));
    tee('  mass error          : max %.2e\n', max(up.mass(ok)));
    ks = max(up.ksat(ok)); bs = max(up.bsat(ok));
    tee('  boundary mass       : k-grid top %.2e [%s], b-grid top %.2e [%s]  (tol %.0e)\n', ...
        ks, ternstr(ks < tol,'PASS','FAIL'), bs, ternstr(bs < tol,'PASS','FAIL'), tol);
    tee('  occupied support    : k up to %.2f of kmax, b up to %.2f of bmax\n', ...
        max(up.kocc(ok)), max(up.bocc(ok)));
    kf = up.kflip(~isnan(up.kflip));
    if ~isempty(kf)
        tee('  k-policy index flips: mean %.3f, max %.3f of states per q step\n', ...
            mean(kf), max(kf));
    end
    tee('\n');
end

function V = classify(R, tee, tol)
    V = struct();
    hyst = 0; kflip = 0; ksat = 0; bsat = 0; dV = 0; ratio = 0; nsign = 0;
    kocc = 0; bocc = 0;
    for ia = 1:numel(R)
        ok = R(ia).up.ok & R(ia).down.ok;
        if ~any(ok), continue; end
        hyst  = max(hyst,  max(abs(R(ia).up.Fk(ok) - R(ia).down.Fk(ok))));
        kf = R(ia).up.kflip(~isnan(R(ia).up.kflip));
        if ~isempty(kf), kflip = max(kflip, mean(kf)); end
        ksat  = max(ksat,  max(R(ia).up.ksat(ok)));
        bsat  = max(bsat,  max(R(ia).up.bsat(ok)));
        kocc  = max(kocc,  max(R(ia).up.kocc(ok)));
        bocc  = max(bocc,  max(R(ia).up.bocc(ok)));
        dV    = max(dV,    max(R(ia).up.dV(ok)));
        nsign = nsign + (sum(diff(sign(R(ia).up.Fk(ok)))~=0) > 0);
        d1 = diff(R(ia).up.Fk(ok));
        if numel(d1) > 3
            ratio = max(ratio, max(abs(d1))/max(median(abs(d1)),eps));
        end
    end
    V.hysteresis = hyst; V.kflip = kflip; V.ksat = ksat; V.bsat = bsat;
    V.kocc = kocc; V.bocc = bocc;
    V.dV = dV; V.jumpratio = ratio; V.n_alpha_bracketed = nsign;
    V.boundary_pass = (ksat < tol) && (bsat < tol);
    tee('  C2 path dependence  : max up-vs-down |dFk| = %.2e  -> %s\n', hyst, ...
        ternstr(hyst > 1e-8, 'PRESENT', 'absent'));
    tee('  C3 grid boundaries  : k top %.2e, b top %.2e (tol %.0e)  -> %s\n', ...
        ksat, bsat, tol, ternstr(~V.boundary_pass, 'BINDING', 'clear'));
    tee('       occupied support: k %.2f, b %.2f of the grid tops\n', kocc, bocc);
    tee('  C1 hh convergence   : max VFI dV = %.2e                -> %s\n', dV, ...
        ternstr(dV > 1e-5, 'SUSPECT', 'clear'));
    tee('  C4 discrete k-choice: mean index flips/step = %.3f, jump ratio %.1f -> %s\n', ...
        kflip, ratio, ternstr(kflip > 0.001 && ratio > 5, 'PRESENT (staircase)', 'not indicated'));
    tee('  root bracketed      : %d of %d alphas show a sign change in F_k\n', nsign, numel(R));
    tee('\n  VERDICT: ');
    if hyst > 1e-8
        tee('PATH DEPENDENCE dominates. Fix the warm start before anything else;\n');
        tee('  the residual is not yet a function of q.\n');
    elseif ~V.boundary_pass
        tee('GRID BOUNDARY STILL BINDING after the widening.\n');
        tee('  Raise KFAC (and BFAC if it is the b-grid that fails) and rerun. If the\n');
        tee('  mass will not go interior at any factor, the tail is not a grid artefact:\n');
        tee('  re-examine the superstar state and the dividend payout rule.\n');
    elseif dV > 1e-5
        tee('HOUSEHOLD CONVERGENCE. Tighten tol_vfi and rescan before changing the policy.\n');
    elseif kflip > 0.001 && ratio > 5
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
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
