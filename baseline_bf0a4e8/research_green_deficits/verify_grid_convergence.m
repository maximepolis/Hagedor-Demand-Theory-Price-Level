% VERIFY_GRID_CONVERGENCE  Grid-convergence audit of the headline steady-state
% objects on three asset grids (coarse / medium / research), under both
% household solvers.
%
% WHAT IT CHECKS. Everything quantitative in the paper is computed on the
% research grid (na = 500). This driver holds ALL parameters fixed
% (including the calibrated beta) and re-solves the medium-column objects on
% na = 125, 250, 500, reporting how each headline moment moves between
% grids. Final reported outcomes should change negligibly between the medium
% and research grids; the driver prints relative changes and a verdict
% against the tolerances below.
%
% OBJECTS PER GRID (medium damage column, both VFI and EGM):
%   S_base, S_prog     asset demand at the stored (tau, D) equilibrium points
%   b0                 no-program real-debt fixed point b = S(r, r*b, D_base)
%                      (a genuine equilibrium object, so P0 = B/b0)
%   eps_tau            tax semi-elasticity dlnS/dtau at the base point (2-sided FD)
%   W_base             utilitarian welfare at the base point
%   gini_base          wealth Gini at the base point
%   constrained        mass at the borrowing limit
%
% TOLERANCES (medium -> research, relative):
%   aggregates (S, b0)      < 1e-3
%   eps_tau                 < 5e-2   (a derivative; grid-noisier by nature)
%   gini / constrained mass < 1e-2
%
% READS   output/calibrated_results.mat
% WRITES  output/grid_convergence_results.mat, output/tables/grid_convergence.txt
%
% USAGE   >> cd research_green_deficits; verify_grid_convergence

clearvars -except FORCE_RERUN; close all; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

calf = fullfile(projdir, 'output', 'calibrated_results.mat');
assert(exist(calf, 'file') == 2, 'verify_grid_convergence: run main_project_calibrated first.');
L = load(calf, 'RCAL', 'pgc');
RCAL = L.RCAL; pgc = L.pgc;
r_cal = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;
cmed  = 2;
assert(~isempty(RCAL.dec{cmed}) && RCAL.dec{cmed}.ok, 'medium column missing.');
tau_b = RCAL.dec{cmed}.base.tau;  D_b = RCAL.dec{cmed}.base.D;
tau_p = RCAL.dec{cmed}.prog.tau;  D_p = RCAL.dec{cmed}.prog.D;

GRIDS   = [125, 250, 500];
GNAMES  = {'coarse', 'medium', 'research'};
SOLVERS = {'vfi', 'egm'};
acurv   = 2.5; if isfield(pgc, 'acurv'), acurv = pgc.acurv; end

G = struct('name',{},'na',{},'solver',{},'S_base',{},'S_prog',{},'b0',{}, ...
           'eps_tau',{},'W_base',{},'gini_base',{},'constrained',{},'t_solve',{});
fprintf('=== GRID CONVERGENCE: na = %s, solvers = {vfi, egm} ===\n', mat2str(GRIDS));
for gi = 1:numel(GRIDS)
    for si = 1:numel(SOLVERS)
        pgg = pgc; pgg.climate_version = 1; pgg.D0 = RCAL.cols(cmed).D0;
        pgg.na = GRIDS(gi);
        pgg.aGrid = local_grid(-pgg.abar, pgg.amax, pgg.na, acurv);
        pgg.hh_solver = SOLVERS{si};
        tic;
        [Sb, ob] = S_green(r_cal, tau_b, D_b, pgg);
        [Sp, ~ ] = S_green(r_cal, tau_p, D_p, pgg);
        % two-sided FD semi-elasticity at the base point
        h = 1e-3;
        Sh = S_green(r_cal, tau_b + h, D_b, pgg);
        Sl = S_green(r_cal, tau_b - h, D_b, pgg);
        et = (log(Sh) - log(Sl)) / (2*h);
        % no-program real-debt fixed point (damped iteration; genuine root)
        b0 = 1.0;
        for it = 1:80
            Sfp = S_green(r_cal, r_cal * b0, D_b, pgg);
            if ~isfinite(Sfp), b0 = NaN; break; end
            bn = 0.5*b0 + 0.5*Sfp;
            if abs(bn - b0) < 1e-8, b0 = bn; break; end
            b0 = bn;
        end
        ts = toc;
        G(end+1) = struct('name', GNAMES{gi}, 'na', GRIDS(gi), ...
            'solver', SOLVERS{si}, 'S_base', Sb, 'S_prog', Sp, 'b0', b0, ...
            'eps_tau', et, 'W_base', ob.W, 'gini_base', ob.gini_a, ...
            'constrained', sum(ob.dist(1,:))/sum(ob.dist(:)), 't_solve', ts); %#ok<SAGROW>
        fprintf('  na=%3d %-4s  S_base %.6f  b0 %.5f  eps_tau %+.3f  gini %.4f  con %.3f  (%.1fs)\n', ...
            GRIDS(gi), SOLVERS{si}, Sb, b0, et, ob.gini_a, G(end).constrained, ts);
    end
end

save(fullfile(projdir, 'output', 'grid_convergence_results.mat'), 'G', 'r_cal');

% ---- table + verdict ----
tabdir = fullfile(projdir, 'output', 'tables');
if ~isfolder(tabdir), mkdir(tabdir); end
fid = fopen(fullfile(tabdir, 'grid_convergence.txt'), 'w');
fprintf(fid, 'GRID CONVERGENCE (medium column; all parameters incl. beta held fixed)\n');
fprintf(fid, 'Grids: na = %s; both household solvers.\n\n', mat2str(GRIDS));
fprintf(fid, '%-9s %-5s %10s %10s %9s %9s %9s %9s %7s\n', 'grid', 'solver', ...
    'S_base', 'S_prog', 'b0', 'eps_tau', 'gini', 'constr', 't(s)');
for k = 1:numel(G)
    fprintf(fid, '%-9s %-5s %10.6f %10.6f %9.5f %+9.3f %9.4f %9.4f %7.1f\n', ...
        G(k).name, G(k).solver, G(k).S_base, G(k).S_prog, G(k).b0, ...
        G(k).eps_tau, G(k).gini_base, G(k).constrained, G(k).t_solve);
end
fprintf(fid, '\nRelative change, medium -> research grid:\n');
ok_all = true;
for si = 1:numel(SOLVERS)
    m = G(strcmp({G.name},'medium')   & strcmp({G.solver},SOLVERS{si}));
    r = G(strcmp({G.name},'research') & strcmp({G.solver},SOLVERS{si}));
    dS  = abs(r.S_base/m.S_base - 1);
    db  = abs(r.b0/m.b0 - 1);
    det_ = abs(r.eps_tau/m.eps_tau - 1);
    dg  = abs(r.gini_base/m.gini_base - 1);
    dc  = abs(r.constrained/m.constrained - 1);
    ok  = dS < 1e-3 && db < 1e-3 && det_ < 5e-2 && dg < 1e-2 && dc < 1e-2;
    ok_all = ok_all && ok;
    fprintf(fid, '  %-4s  |dS| %.2e  |db0| %.2e  |deps| %.2e  |dgini| %.2e  |dcon| %.2e  -> %s\n', ...
        SOLVERS{si}, dS, db, det_, dg, dc, local_tern(ok, 'PASS', 'FAIL'));
end
fprintf(fid, ['\nVERDICT: %s -- reported research-grid (na=500) outcomes %s stable ' ...
    'to grid refinement\nat the stated tolerances (aggregates 1e-3; derivative ' ...
    '5e-2; distribution stats 1e-2).\n'], ...
    local_tern(ok_all, 'PASS', 'CHECK'), local_tern(ok_all, 'are', 'are NOT'));
fclose(fid);
fprintf('Wrote output/tables/grid_convergence.txt. Elapsed %.1f s\n', toc(t0));

% -------------------------------------------------------------------------
function g = local_grid(amin, amax, n, curv)
% Same construction as the root package's make_asset_grid (duplicated so the
% driver does not depend on a private helper being on the path).
    u = linspace(0, 1, n).';
    g = amin + (amax - amin) * (u.^curv);
    g(1) = amin; g(end) = amax;
end

function s = local_tern(c, a, b)
    if c, s = a; else, s = b; end
end
