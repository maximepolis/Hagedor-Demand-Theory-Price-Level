% MAIN_PREFERRED_SIGNAL_NOISE  Is the preferred economy's financing result a
% MEASUREMENT yet, or is it inside the solver's own noise?
%
% WHY THIS EXISTS. The gates elsewhere in this project ask whether residuals
% are small in absolute terms -- |F_k| < 1e-7, and so on. Those thresholds
% came from the SCHUR DERIVATIVE check, where they belong: a difference
% quotient divides by a small step, so it amplifies whatever noise is in the
% level. But the paper's substantive claim about this economy is not a
% derivative. It is a FINITE move from lump-sum financing (alpha = 0) to levy
% financing (alpha = 1), and the sign of what that does to the price level.
%
% A finite change needs something weaker and more honest than an absolute
% tolerance: the solver's noise must be small relative to the CHANGE BEING
% MEASURED. dlnP = 2% with 0.1% of noise is a result. dlnP = 0.2% with 0.1%
% of noise is not, whatever the residual reads. Chasing 1e-7 without ever
% forming that ratio is how a project ends up polishing a number it cannot
% yet interpret -- and the last scan gave direct cause for concern: a pure
% grid change (bmax 12 -> 96) moved q* by 7.7% and broke its monotonicity in
% alpha, while the spread of q ACROSS alpha is only 0.6%.
%
% So this driver measures both sides of the ratio.
%
% SIGNAL: dlnP, dS_b, dq between the alpha = 0 and alpha = 1 equilibria,
% solved by continuation, exactly as the decomposition solves them.
%
% NOISE, from three channels that must not change the answer but might:
%   N1 RESIDUAL FLOOR. The root leaves |F_k| = eps > 0 because S_k(q) is a
%      step function. Every q whose residual is no worse than the root's is,
%      as far as this discretization can tell, equally an equilibrium. The
%      spread of lnP across that indifference band is the price level's
%      genuine indeterminacy at this resolution.
%   N2 CONTINUATION SEED. Re-solve alpha = 1 cold instead of continued. Same
%      economy, different path to it; any difference is solver noise.
%   N3 GRID. Re-solve both ends on a coarser node count at the same
%      curvature and bounds. This is the channel that has actually been
%      biting.
%
% VERDICT. The finite-change claim is reportable when the SIGN of dlnP is the
% same in every channel and the smallest signal-to-noise ratio clears SNRMIN.
% Sign stability is the binding condition: the paper claims a direction, and
% a direction that flips under a grid refinement is not a finding.
%
% This is DIAGNOSTIC. beta and chi_b were calibrated at kmax = 60; run
% main_twoasset_ownership_kv with REGRID = true before treating any number
% here as final.
%
% USAGE   >> clear; FAST = true; main_preferred_signal_noise
%         >> clear; main_preferred_signal_noise            (benchmark grid)
%         >> clear; SKIPGRID = true; main_preferred_signal_noise   (skip N3)
%
% REQUIRES output/twoasset_ownership_kv.mat  (and, ideally,
%          output/kv_residual_scan.mat for the verified grid factors)
% OUTPUT   output/tables/preferred_signal_noise.txt
%          output/preferred_signal_noise.mat

clearvars -except FAST SKIPGRID SNRMIN PARALLEL NWORKERS; close all; clc;
rng(20260731,'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('SKIPGRID','var'), SKIPGRID = false; end
if ~exist('SNRMIN','var') || isempty(SNRMIN), SNRMIN = 10; end
if ~exist('PARALLEL','var') || isempty(PARALLEL), PARALLEL = true; end
if ~exist('NWORKERS','var'), NWORKERS = []; end

mf = fullfile(projdir,'output','twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2, 'run main_twoasset_ownership_kv first');
S = load(mf); assert(S.eq0.ok, 'saved benchmark equilibrium not ok');
p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base; D0 = S.D0; Gg = S.Gg;
eq0 = S.eq0;
pg = setup_params_green(); Bnom = pg.Bnom; Kbar = 1.0;
g_real = Gg / eq0.P;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'preferred_signal_noise.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid,varargin{:});
tee('IS THE FINANCING RESULT A MEASUREMENT YET?  signal vs solver noise\n\n');

if FAST
    nbF = max(28, round(numel(p.bGrid)*0.5));
    nkF = max(16, round(numel(p.kGrid)*0.5));
    [blo,bhi,gb] = kv_grid_curv(p.bGrid); p.bGrid = kv_grid_build(blo,bhi,gb,nbF);
    [klo,khi,gk] = kv_grid_curv(p.kGrid); p.kGrid = kv_grid_build(klo,khi,gk,nkF);
    tee('*** FAST: nb=%d nk=%d (DEBUG) ***\n', nbF, nkF);
end

% same widening the scan verified, read from the scan
kfac = 1; bfac = 1;
scf = fullfile(projdir,'output','kv_residual_scan.mat');
if exist(scf,'file')==2
    Sc = load(scf,'kfac','bfac'); kfac = Sc.kfac; bfac = Sc.bfac;
else
    kfac = 6; bfac = 8;
    tee('*** no kv_residual_scan.mat: using kfac=%.0f bfac=%.0f UNVERIFIED ***\n', kfac, bfac);
end
if kfac > 1 || bfac > 1
    [p, WID] = kv_widen_grids(p, kfac, struct('r_b',r_b,'q',eq0.q,'d',d_base, ...
                                              'kref',5,'bref',3,'bfac',bfac));
    tee('grids: kmax %.1f, bmax %.2f, xmax %.1f (kfac=%.0f bfac=%.0f)\n', ...
        WID.kmax, WID.bmax, WID.xmax, kfac, bfac);
end
tee('nb=%d nk=%d ne=%d\n\n', numel(p.bGrid), numel(p.kGrid), numel(p.eGrid));

CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
             'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real,'Pseed',eq0.P);

% ===================================================================== SIGNAL
tee('===== SIGNAL: the alpha = 0 -> alpha = 1 move =====\n');
[BASE, ok] = solve_pair(CTX, eq0.q, tee, 'continuation');
assert(ok, 'the baseline pair did not solve; nothing to measure');
sig = struct('dlnP', log(BASE.E1.P/BASE.E0.P), ...
             'dSb',  BASE.E1.Sb - BASE.E0.Sb, ...
             'dq',   BASE.E1.q  - BASE.E0.q);
tee('  dlnP = %+0.6f  (%.3f%%)\n', sig.dlnP, 100*sig.dlnP);
tee('  dS_b = %+0.6f    dq = %+0.6f\n', sig.dSb, sig.dq);
tee('  root residuals: |F_k| %.2e / %.2e, |F_b| %.2e / %.2e\n\n', ...
    abs(BASE.E0.Fk), abs(BASE.E1.Fk), abs(BASE.E0.Fb), abs(BASE.E1.Fb));

% ============================================== N1  RESIDUAL-FLOOR BAND
tee('===== N1: what the residual floor leaves undetermined =====\n');
N1 = floor_band(CTX, BASE, tee);

% ============================================== N2  CONTINUATION SEED
tee('===== N2: cold solve instead of continued =====\n');
[ALT, ok2] = solve_pair(CTX, eq0.q, tee, 'cold');
N2 = NaN;
if ok2
    N2 = abs(log(ALT.E1.P/ALT.E0.P) - sig.dlnP);
    tee('  dlnP cold = %+0.6f vs continued %+0.6f  -> |difference| %.2e\n\n', ...
        log(ALT.E1.P/ALT.E0.P), sig.dlnP, N2);
else
    tee('  cold solve failed; N2 not measured\n\n');
end

% ============================================== N3  GRID
N3 = NaN; dlnP_c = NaN;
if ~SKIPGRID
    tee('===== N3: coarser node count, same curvature and bounds =====\n');
    CTXc = CTX; CTXc.p = coarsen(p, 0.8);
    [CRS, ok3] = solve_pair(CTXc, eq0.q, tee, 'continuation');
    if ok3
        dlnP_c = log(CRS.E1.P/CRS.E0.P);
        N3 = abs(dlnP_c - sig.dlnP);
        tee('  dlnP coarse = %+0.6f vs fine %+0.6f  -> |difference| %.2e\n\n', ...
            dlnP_c, sig.dlnP, N3);
    else
        tee('  coarse solve failed; N3 not measured\n\n');
    end
else
    tee('===== N3: skipped =====\n\n');
end

% ===================================================================== VERDICT
tee('===== SIGNAL TO NOISE =====\n');
nz = [N1.spread, N2, N3];
nm = {'floor band', 'seed', 'grid'};
snr = abs(sig.dlnP) ./ nz;
for i = 1:3
    if isfinite(nz(i))
        tee('  %-12s noise %.2e   SNR %8.1f   %s\n', nm{i}, nz(i), snr(i), ...
            ternstr(snr(i) >= SNRMIN, 'ok', 'TOO NOISY'));
    else
        tee('  %-12s not measured\n', nm{i});
    end
end
% Sign stability is the binding condition: the paper claims a direction.
signs = sign([sig.dlnP, N1.lo_dlnP, N1.hi_dlnP]);
if isfinite(N2) && ok2, signs(end+1) = sign(log(ALT.E1.P/ALT.E0.P)); end
if isfinite(N3), signs(end+1) = sign(dlnP_c); end
signs = signs(isfinite(signs) & signs ~= 0);
sign_stable = ~isempty(signs) && all(signs == signs(1));
worst = min(snr(isfinite(snr)));
if isempty(worst), worst = NaN; end

tee('\n  sign of dlnP stable across every channel : %s\n', ternstr(sign_stable,'YES','NO'));
tee('  worst signal-to-noise ratio              : %.1f (need %.0f)\n', worst, SNRMIN);
pass = sign_stable && isfinite(worst) && worst >= SNRMIN;
tee('\n  VERDICT: ');
if pass
    tee('THE FINITE-CHANGE RESULT IS REPORTABLE at this resolution.\n');
    tee('  The sign holds in every channel and the move is %.0fx the worst noise.\n', worst);
    tee('  This does NOT license the Schur derivative, which divides by a small\n');
    tee('  step and needs the absolute residual gates instead.\n');
elseif ~sign_stable
    tee('NOT YET A MEASUREMENT -- THE SIGN ITSELF MOVES.\n');
    tee('  A direction that flips under a grid refinement or a reseeding is not a\n');
    tee('  finding, whatever the residual reads. Fix the resolution before any\n');
    tee('  interpretation: this is the one failure that cannot be caveated around.\n');
else
    tee('SIGN IS STABLE BUT THE MARGIN IS THIN (worst SNR %.1f).\n', worst);
    tee('  The direction can be reported with the noise stated alongside it; the\n');
    tee('  MAGNITUDE cannot be quoted until the worst channel improves.\n');
end

save(fullfile(projdir,'output','preferred_signal_noise.mat'), ...
     'sig','N1','N2','N3','BASE','CTX','snr','sign_stable','pass','SNRMIN');
tee('\n[main_preferred_signal_noise] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function [PR, ok] = solve_pair(CTX, q0, tee, mode)
% alpha = 0 then alpha = 1. 'continuation' steps through alpha = 0.5 and
% seeds each solve with the previous one; 'cold' solves alpha = 1 from the
% baseline guess with no inherited value function. The two must agree.
    PR = struct('E0',[],'E1',[]); ok = false;
    C = CTX;
    E0 = kv_solve_alpha(0.0, C, q0, false, []);
    if ~E0.ok, tee('  alpha=0 failed: %s\n', E0.msg); return; end
    if strcmp(mode,'continuation')
        C.Wseed = E0.sol.V; C.Pseed = E0.P;
        Eh = kv_solve_alpha(0.5, C, E0.q, false, []);
        qg = E0.q;
        if Eh.ok, C.Wseed = Eh.sol.V; C.Pseed = Eh.P; qg = Eh.q; end
    else
        qg = q0;                                  % cold: no inherited state
    end
    E1 = kv_solve_alpha(1.0, C, qg, false, []);
    if ~E1.ok, tee('  alpha=1 failed: %s\n', E1.msg); return; end
    PR.E0 = E0; PR.E1 = E1; ok = true;
end

function N1 = floor_band(CTX, BASE, tee)
% The set of tree prices this discretization cannot tell apart from the root,
% and what that does to the price level.
%
% The root leaves |F_k| = eps because S_k(q) steps. Any q with |F_k| <= eps is
% an equally good equilibrium as far as the solver can see, so the spread of
% lnP over that band is the price level's honest indeterminacy -- a number
% that no amount of tightening the bisection removes, because it is set by
% the discretization and not by the search.
    N1 = struct('spread',NaN,'width',NaN,'n',0,'lo_dlnP',NaN,'hi_dlnP',NaN);
    lnP = nan(2,2);
    for e = 1:2
        if e == 1, E = BASE.E0; al = 0.0; else, E = BASE.E1; al = 1.0; end
        eps_k = max(abs(E.Fk), 1e-12);
        qs = E.q * (1 + linspace(-2e-3, 2e-3, 21));
        keep = false(1,numel(qs)); Pv = nan(1,numel(qs));
        for i = 1:numel(qs)
            st = kv_solve_bond_given_q(qs(i), al, CTX, [], [], E.P);
            if st.ok && abs(st.Sk - CTX.Kbar) <= 3*eps_k
                keep(i) = true; Pv(i) = st.P;
            end
        end
        if ~any(keep)
            tee('  alpha=%.1f: band empty (the root is isolated at this step)\n', al);
            lnP(e,:) = log(E.P);
            continue;
        end
        lnP(e,1) = log(min(Pv(keep))); lnP(e,2) = log(max(Pv(keep)));
        N1.n = N1.n + sum(keep);
        tee(['  alpha=%.1f: |F_k| at the root %.2e; %d of 21 nearby q within 3x of it;\n' ...
             '             lnP varies by %.2e across them\n'], ...
            al, eps_k, sum(keep), lnP(e,2)-lnP(e,1));
    end
    % worst case for dlnP = lnP1 - lnP0
    N1.lo_dlnP = lnP(2,1) - lnP(1,2);
    N1.hi_dlnP = lnP(2,2) - lnP(1,1);
    N1.spread  = abs(N1.hi_dlnP - N1.lo_dlnP);
    tee('  dlnP is pinned only to [%+0.6f, %+0.6f], a spread of %.2e\n\n', ...
        N1.lo_dlnP, N1.hi_dlnP, N1.spread);
end

function pc = coarsen(p, fac)
% Vary ONLY the node count: take both endpoints and the curvature from the
% grid being coarsened, so this is a resolution test and not a shape test.
    pc = p;
    nb = max(24, round(numel(p.bGrid)*fac));
    nk = max(14, round(numel(p.kGrid)*fac));
    [blo,bhi,gb] = kv_grid_curv(p.bGrid); pc.bGrid = kv_grid_build(blo,bhi,gb,nb);
    [klo,khi,gk] = kv_grid_curv(p.kGrid); pc.kGrid = kv_grid_build(klo,khi,gk,nk);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
