% MAIN_PARITY_D10_CALIBRATION  Does the refactored callable calibration
% reproduce the legacy path exactly?
%
% MUST BE RUN AND MUST PASS before kv_calibrate_on_grid is used in Track B.
% A clean static check establishes nothing about economic output; only this
% comparison does. Until it has run, no statement of parity may be made.
%
% WHAT IS COMPARED. The legacy path is main_twoasset_ownership_kv's own call
% into calib_beta / calib_beta_chi; the new path is kv_calibrate_on_grid with
% identical inputs. Because the round-10 refactor MOVED those functions rather
% than reimplementing them, the two paths execute the same lines and agreement
% should be at machine precision -- which is exactly why a discrepancy would be
% informative rather than expected.
%
% USAGE   >> clear; main_parity_d10_calibration
%         >> clear; FAST = true; main_parity_d10_calibration
%
% OUTPUT  output/tables/parity_d10_calibration.txt
%         output/parity_d10_calibration.mat

clearvars -except FAST; close all; clc;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir,'src')));
addpath(genpath(fullfile(projdir,'src_project')));
if ~exist('FAST','var'), FAST = false; end

pg = setup_params_green();
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir,'parity_d10_calibration.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('D10 PARITY: legacy calibration path vs kv_calibrate_on_grid\n\n');

% ---- tolerances, fixed here ---------------------------------------------
TOL = struct('theta', 1e-10, ...   % calibrated parameters, relative
             'price', 1e-10, ...   % P and q, relative
             'agg',   1e-10, ...   % S_b, S_k, relative
             'dist',  1e-12, ...   % invariant distribution, sup-norm
             'dP',    1e-10);      % the financing contrast, relative
tee('tolerances: theta %.0e  price %.0e  agg %.0e  dist %.0e  dP %.0e\n', ...
    TOL.theta, TOL.price, TOL.agg, TOL.dist, TOL.dP);
tee('(the refactor MOVED code rather than reimplementing it, so anything\n');
tee(' above these tolerances is a real defect, not a numerical difference)\n\n');

mf = fullfile(projdir,'output','twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2, 'run main_twoasset_ownership_kv first');
S = load(mf); p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base; D0 = S.D0;
Bnom = pg.Bnom; Kbar = 1.0; b_targ_H = 0.30; q_ref = S.eq0.q;

if FAST
    nbF = max(28, round(numel(p.bGrid)*0.5)); nkF = max(16, round(numel(p.kGrid)*0.5));
    [lo,hi,g] = kv_grid_curv(p.bGrid); p.bGrid = kv_grid_build(lo,hi,g,nbF);
    [lo,hi,g] = kv_grid_curv(p.kGrid); p.kGrid = kv_grid_build(lo,hi,g,nkF);
    tee('*** FAST: nb=%d nk=%d ***\n\n', nbF, nkF);
end

% ---- LEGACY path ---------------------------------------------------------
tee('--- legacy: calib_beta(...) as main_twoasset_ownership_kv calls it ---\n');
tL = tic;
[betaL, eqL] = calib_beta(r_b, d_base, D0, 0, 0, Bnom, Kbar, b_targ_H, iota, p, q_ref, tic);
tee('  beta=%.12f  ok=%d  (%.1f s)\n', betaL, eqL.ok, toc(tL));

% ---- NEW path ------------------------------------------------------------
tee('--- new: kv_calibrate_on_grid with identical inputs ---\n');
tN = tic;
C = kv_calibrate_on_grid( ...
      struct('p_base', p, 'bGrid', p.bGrid, 'kGrid', p.kGrid), ...
      struct('r_b', r_b, 'd_base', d_base, 'D0', D0, 'Bnom', Bnom, ...
             'Kbar', Kbar, 'iota_H', iota, 'b_targ_H', b_targ_H, ...
             'q_ref', q_ref, 'W_targ', [], 'tag', 'parity'));
tee('  beta=%.12f  ok=%d  (%.1f s)\n\n', C.theta(1), C.ok, toc(tN));

% ---- comparison ----------------------------------------------------------
R = {}; pass = true;
R = cmp(R, 'beta',  betaL,   C.theta(1),      TOL.theta, 'rel');
if eqL.ok && C.ok
    R = cmp(R, 'P',     eqL.P,   C.eq0.P,     TOL.price, 'rel');
    R = cmp(R, 'q',     eqL.q,   C.eq0.q,     TOL.price, 'rel');
    R = cmp(R, 'S_b',   eqL.Sb,  C.eq0.Sb,    TOL.agg,   'rel');
    R = cmp(R, 'tau',   eqL.tau, C.eq0.tau,   TOL.agg,   'rel');
    R = cmp(R, 'div',   eqL.div, C.eq0.div,   TOL.agg,   'rel');
    R = cmp(R, 'dist',  eqL.dist, C.eq0.dist, TOL.dist,  'sup');
else
    tee('*** one path failed to calibrate; parity cannot be established.\n');
    pass = false;
end

% ---- the financing contrast, which is what the paper reports -------------
if eqL.ok && C.ok
    g_real = S.Gg / eqL.P;
    eLS_L = solve_own_kv(r_b,d_base,D0,g_real,0,Bnom,Kbar,iota,p,   eqL.q,false,[0.85 1.20]);
    eLV_L = solve_own_kv(r_b,d_base,D0,g_real,1,Bnom,Kbar,iota,p,   eqL.q,false,[0.85 1.20]);
    eLS_N = solve_own_kv(r_b,d_base,D0,g_real,0,Bnom,Kbar,iota,C.p, C.eq0.q,false,[0.85 1.20]);
    eLV_N = solve_own_kv(r_b,d_base,D0,g_real,1,Bnom,Kbar,iota,C.p, C.eq0.q,false,[0.85 1.20]);
    if eLS_L.ok && eLV_L.ok && eLS_N.ok && eLV_N.ok
        dPL = eLV_L.P - eLS_L.P;  dPN = eLV_N.P - eLS_N.P;
        R = cmp(R, 'dP = P^LEV - P^LS', dPL, dPN, TOL.dP, 'rel');
    else
        tee('*** a financing solve failed; dP parity not established.\n'); pass = false;
    end
end

tee('\n%-22s %18s %18s %12s  %s\n','quantity','legacy','new','discrepancy','verdict');
for i = 1:numel(R)
    r = R{i};
    tee('%-22s %18.10g %18.10g %12.3e  %s\n', r.name, r.a, r.b, r.d, ...
        ternstr(r.pass,'PASS','FAIL'));
    if ~r.pass, pass = false; end
end
tee('\nD10 PARITY: %s\n', ternstr(pass,'PASS','FAIL'));
if ~pass
    tee('The refactor changed economic output. Do NOT use kv_calibrate_on_grid\n');
    tee('in Track B, and do NOT remove the legacy wrapper, until this passes.\n');
end

save(fullfile(projdir,'output','parity_d10_calibration.mat'), 'R','pass','TOL');
tee('\n[main_parity_d10_calibration] wrote %s\n', sf);
fclose(fid);

% =====================================================================
function R = cmp(R, name, a, b, tol, mode)
    switch mode
        case 'rel', d = abs(a-b)/max(abs(a), eps);
        case 'sup', d = max(abs(a(:)-b(:))); a = norm(a(:),1); b = norm(b(:),1);
        otherwise,  d = abs(a-b);
    end
    R{end+1} = struct('name',name,'a',a,'b',b,'d',d,'pass',isfinite(d) && d < tol);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
