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
% USAGE   >> clear; main_kv_residual_scan
%         >> clear; FAST = true; main_kv_residual_scan     (coarse grids)
%         >> clear; NQ = 121; main_kv_residual_scan        (finer scan)
%         >> clear; COLDSTART = false; main_kv_residual_scan
%
% OUTPUT  output/tables/kv_residual_scan.txt
%         output/kv_residual_scan.mat   (full per-node record)

clearvars -except FAST NQ COLDSTART; close all; clc;
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
assert(NQ >= 61, 'the diagnosis needs at least 61 nodes');

mf = fullfile(projdir,'output','twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2,'run main_twoasset_ownership_kv first');
S = load(mf); p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base;
D0 = S.D0; Gg = S.Gg; eq0 = S.eq0;
pg = setup_params_green(); Bnom = pg.Bnom; Kbar = 1.0;
g_real = Gg / eq0.P;

if FAST
    nb = max(28, round(numel(p.bGrid)*0.5));
    nk = max(16, round(numel(p.kGrid)*0.5));
    ub = linspace(0,1,nb)'; p.bGrid = p.bGrid(1)+(p.bGrid(end)-p.bGrid(1))*(ub.^2.4);
    uk = linspace(0,1,nk)'; p.kGrid = p.kGrid(end)*(uk.^2.4);
end

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'kv_residual_scan.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid,varargin{:});
tee('REDUCED TREE-MARKET RESIDUAL SCAN  F_k(q;alpha) = S_k(P(q,alpha),q,alpha) - Kbar\n');
tee('grids nb=%d nk=%d ne=%d; nq=%d; coldstart=%d\n\n', ...
    numel(p.bGrid), numel(p.kGrid), numel(p.eGrid), NQ, COLDSTART);

CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
             'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real);

alphas = [0 0.5 1];
R = struct();
for ia = 1:numel(alphas)
    al = alphas(ia);
    qc = eq0.q * (1 - 0.02*al);                 % candidate root, drifts with alpha
    qs = linspace(qc*0.98, qc*1.02, NQ);
    tee('===== alpha = %.2f : scanning %d nodes over q in [%.5f, %.5f] =====\n', ...
        al, NQ, qs(1), qs(end));
    up   = scan_dir(qs,        al, CTX, COLDSTART);
    down = scan_dir(fliplr(qs), al, CTX, COLDSTART);
    down = flip_struct(down);                    % back to ascending order
    R(ia).alpha = al; R(ia).q = qs; R(ia).up = up; R(ia).down = down;
    report_dir(tee, qs, up, down, al);
end

% ---------------------------------------------------------------- verdict
tee('\n===== DIAGNOSIS =====\n');
V = classify(R, tee);
save(fullfile(projdir,'output','kv_residual_scan.mat'),'R','V','CTX','alphas');
tee('\n[main_kv_residual_scan] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function out = scan_dir(qs, al, CTX, cold)
    n = numel(qs);
    out = struct('Fk',nan(1,n),'Fb',nan(1,n),'P',nan(1,n),'dV',nan(1,n), ...
                 'ddist',nan(1,n),'mass',nan(1,n),'ksat',nan(1,n), ...
                 'bsat',nan(1,n),'kflip',nan(1,n),'ok',false(1,n));
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
        km = squeeze(sum(sum(st.dist,1),3)); km = km(:);
        bm = squeeze(sum(sum(st.dist,2),3)); bm = bm(:);
        out.ksat(i) = sum(km(max(1,end-1):end))/max(sum(km),eps);
        out.bsat(i) = sum(bm(max(1,end-1):end))/max(sum(bm),eps);
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

function s = flip_struct(s)
    f = fieldnames(s);
    for i = 1:numel(f), s.(f{i}) = fliplr(s.(f{i})); end
end

function report_dir(tee, qs, up, dn, al)
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
    tee('  boundary mass       : k-grid top %.2e, b-grid top %.2e\n', ...
        max(up.ksat(ok)), max(up.bsat(ok)));
    kf = up.kflip(~isnan(up.kflip));
    if ~isempty(kf)
        tee('  k-policy index flips: mean %.3f, max %.3f of states per q step\n', ...
            mean(kf), max(kf));
    end
    tee('\n');
end

function V = classify(R, tee)
    V = struct();
    hyst = 0; kflip = 0; ksat = 0; dV = 0; ratio = 0;
    for ia = 1:numel(R)
        ok = R(ia).up.ok & R(ia).down.ok;
        if ~any(ok), continue; end
        hyst  = max(hyst,  max(abs(R(ia).up.Fk(ok) - R(ia).down.Fk(ok))));
        kf = R(ia).up.kflip(~isnan(R(ia).up.kflip));
        if ~isempty(kf), kflip = max(kflip, mean(kf)); end
        ksat  = max(ksat,  max(R(ia).up.ksat(ok)));
        dV    = max(dV,    max(R(ia).up.dV(ok)));
        d1 = diff(R(ia).up.Fk(ok));
        if numel(d1) > 3
            ratio = max(ratio, max(abs(d1))/max(median(abs(d1)),eps));
        end
    end
    V.hysteresis = hyst; V.kflip = kflip; V.ksat = ksat; V.dV = dV; V.jumpratio = ratio;
    tee('  C2 path dependence  : max up-vs-down |dFk| = %.2e  -> %s\n', hyst, ...
        ternstr(hyst > 1e-8, 'PRESENT', 'absent'));
    tee('  C3 grid boundaries  : max k-grid top mass = %.2e     -> %s\n', ksat, ...
        ternstr(ksat > 1e-3, 'SUSPECT', 'clear'));
    tee('  C1 hh convergence   : max VFI dV = %.2e                -> %s\n', dV, ...
        ternstr(dV > 1e-5, 'SUSPECT', 'clear'));
    tee('  C4 discrete k-choice: mean index flips/step = %.3f, jump ratio %.1f -> %s\n', ...
        kflip, ratio, ternstr(kflip > 0.001 && ratio > 5, 'PRESENT (staircase)', 'not indicated'));
    tee('\n  VERDICT: ');
    if hyst > 1e-8
        tee('PATH DEPENDENCE dominates. Fix the warm start before anything else;\n');
        tee('  the residual is not yet a function of q.\n');
    elseif ksat > 1e-3
        tee('GRID BOUNDARY binding. Widen the k-grid and rescan.\n');
    elseif dV > 1e-5
        tee('HOUSEHOLD CONVERGENCE. Tighten tol_vfi and rescan before changing the policy.\n');
    elseif kflip > 0.001 && ratio > 5
        tee('REPRODUCIBLE STAIRCASE from the discrete k-choice.\n');
        tee('  Proceed to the continuous adjuster policy: interpolate the\n');
        tee('  continuation value, refine the optimum between neighbouring k\n');
        tee('  nodes, and push the distribution by bilinear lottery over (b,k).\n');
    else
        tee('no single cause indicated; inspect the saved per-node record.\n');
    end
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
