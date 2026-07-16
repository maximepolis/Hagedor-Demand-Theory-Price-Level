% VERIFY_EGM_VS_VFI  Cross-validate the endogenous-grid household solver
% (solve_household_egm + Young-lottery distribution) against the package's
% grid-choice VFI (solve_household_vfi + exact on-grid distribution) on the
% calibrated steady states, and report the standard accuracy diagnostic.
%
% WHAT IT CHECKS
%   1. AGREEMENT: aggregate asset demand S, utilitarian welfare W, wealth
%      Gini, and constrained mass under both solvers at the calibrated
%      medium column's no-program and program steady states (the pair every
%      headline number is built from), plus the low/high columns.
%   2. ACCURACY: unit-free Euler-equation errors |1 - c_implied/c| evaluated
%      OFF-GRID (den Haan-style), reported as log10 max / mean over the
%      unconstrained region -- the same metric applied to BOTH solvers, so
%      the VFI's grid-snap error and the EGM's interpolation error are on
%      one scale.
%   3. SPEED: wall-clock per steady-state solve.
%
% READS   output/calibrated_results.mat  (main_project_calibrated)
% WRITES  output/egm_validation_results.mat, output/tables/egm_validation.txt
%
% INTERPRETATION RULE (stated before the run, so the numbers decide):
%   - If |S_egm/S_vfi - 1| and |W_egm - W_vfi| are within the paper's
%     reporting precision (third decimal of the published objects), the
%     published numbers are solver-robust and the EGM can become the
%     default for SPEED, with no result change.
%   - If they differ materially, the finer-Euler-error solver (expected:
%     EGM) is the more accurate benchmark, and affected tables should be
%     re-run under pg.hh_solver='egm' before the next submission.
%
% USAGE   >> cd research_green_deficits; verify_egm_vs_vfi

clearvars -except FORCE_RERUN; close all; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

calf = fullfile(projdir, 'output', 'calibrated_results.mat');
assert(exist(calf, 'file') == 2, 'verify_egm_vs_vfi: run main_project_calibrated first.');
L = load(calf, 'RCAL', 'pgc');
RCAL = L.RCAL; pgc = L.pgc;
r_cal = (1 + pgc.i_ss)/(1 + pgc.mu) - 1;

% evaluation points: (name, tau, D, D0-column) for base and program of each column
pts = {};
for c = 1:numel(RCAL.cols)
    if isempty(RCAL.dec{c}) || ~RCAL.dec{c}.ok, continue; end
    nm = RCAL.cols(c).name;
    pts{end+1} = struct('name', [nm ' base'], 'tau', RCAL.dec{c}.base.tau, ...
                        'D', RCAL.dec{c}.base.D, 'D0', RCAL.cols(c).D0);   %#ok<*SAGROW>
    pts{end+1} = struct('name', [nm ' prog'], 'tau', RCAL.dec{c}.prog.tau, ...
                        'D', RCAL.dec{c}.prog.D, 'D0', RCAL.cols(c).D0);
end
assert(~isempty(pts), 'verify_egm_vs_vfi: no valid calibrated points found.');

RES = struct('name', {}, 'S_vfi', {}, 'S_egm', {}, 'relS', {}, ...
             'W_vfi', {}, 'W_egm', {}, 'dW', {}, 'gini_vfi', {}, 'gini_egm', {}, ...
             't_vfi', {}, 't_egm', {}, 'ee_vfi', {}, 'ee_egm', {});

fprintf('=== EGM vs VFI cross-validation (%d points) ===\n', numel(pts));
for q = 1:numel(pts)
    pt = pts{q};
    pgq = pgc; pgq.climate_version = 1; pgq.D0 = pt.D0;

    pgq.hh_solver = 'vfi'; tic;
    [S_v, o_v] = S_green(r_cal, pt.tau, pt.D, pgq);
    t_v = toc;
    pgq.hh_solver = 'egm'; tic;
    [S_e, o_e] = S_green(r_cal, pt.tau, pt.D, pgq);
    t_e = toc;
    if ~o_v.feasible || ~o_e.feasible
        fprintf('  %-24s SKIPPED (infeasible under %s)\n', pt.name, ...
                ternchar(~o_v.feasible, 'vfi', 'egm'));
        continue;
    end

    ee_v = euler_errors_offgrid(o_v.polC, r_cal, pt.tau, o_v.eGrid_eff, o_v.Pi_eff, pgq);
    ee_e = euler_errors_offgrid(o_e.polC, r_cal, pt.tau, o_e.eGrid_eff, o_e.Pi_eff, pgq);

    RES(end+1) = struct('name', pt.name, 'S_vfi', S_v, 'S_egm', S_e, ...
        'relS', S_e/S_v - 1, 'W_vfi', o_v.W, 'W_egm', o_e.W, 'dW', o_e.W - o_v.W, ...
        'gini_vfi', o_v.gini_a, 'gini_egm', o_e.gini_a, ...
        't_vfi', t_v, 't_egm', t_e, 'ee_vfi', ee_v, 'ee_egm', ee_e);
    fprintf(['  %-24s relS %+9.2e  dW %+9.2e  EE(log10 max) vfi %5.2f egm %5.2f' ...
             '  time %5.2fs -> %5.2fs\n'], pt.name, RES(end).relS, RES(end).dW, ...
            ee_v.lmax, ee_e.lmax, t_v, t_e);
end

save(fullfile(projdir, 'output', 'egm_validation_results.mat'), 'RES', 'r_cal');
tabdir = fullfile(projdir, 'output', 'tables');
if ~isfolder(tabdir), mkdir(tabdir); end
fid = fopen(fullfile(tabdir, 'egm_validation.txt'), 'w');
fprintf(fid, 'EGM vs VFI CROSS-VALIDATION (calibrated steady states, r=%.4f)\n', r_cal);
fprintf(fid, ['Euler errors are log10 |1 - c_implied/c| off-grid over the ' ...
              'unconstrained region.\n\n']);
fprintf(fid, '%-24s %12s %12s %10s %8s %8s %8s %8s %7s %7s\n', 'point', ...
        'S_vfi', 'S_egm', 'relS', 'EEmax_v', 'EEmax_e', 'EEavg_v', 'EEavg_e', ...
        't_vfi', 't_egm');
for q = 1:numel(RES)
    fprintf(fid, '%-24s %12.6f %12.6f %+10.2e %8.2f %8.2f %8.2f %8.2f %7.2f %7.2f\n', ...
        RES(q).name, RES(q).S_vfi, RES(q).S_egm, RES(q).relS, ...
        RES(q).ee_vfi.lmax, RES(q).ee_egm.lmax, ...
        RES(q).ee_vfi.lavg, RES(q).ee_egm.lavg, RES(q).t_vfi, RES(q).t_egm);
end
if ~isempty(RES)
    worst = max(abs([RES.relS]));
    fprintf(fid, ['\nVERDICT: max |S_egm/S_vfi - 1| = %.2e across all points. ' ...
        'Reporting precision of the\npublished price levels is ~5e-4, so the ' ...
        'published numbers are %s.\n'], worst, ...
        ternchar(worst < 5e-4, ...
        'SOLVER-ROBUST (EGM can become the default for speed, no result change)', ...
        'SOLVER-SENSITIVE -- re-run affected tables under pg.hh_solver=''egm'''));
end
fclose(fid);
fprintf('Wrote output/tables/egm_validation.txt. Elapsed %.1f s\n', toc(t0));

% -------------------------------------------------------------------------
function ee = euler_errors_offgrid(polC, r, tau, yv, Pi, p)
% Unit-free Euler errors on off-grid asset points (grid midpoints), for a
% consumption policy given on p.aGrid. Constrained points (chosen a' at the
% grid floor) are excluded, as is standard.
    aG = p.aGrid(:); yv = yv(:)'; ne = numel(yv); sig = p.sigma;
    ad = (aG(1:end-1) + aG(2:end)) / 2;      % midpoints
    errs = [];
    for e = 1:ne
        cd = interp1(aG, polC(:, e), ad, 'linear');
        ap = (1 + r)*ad + yv(e) - tau - cd;
        unc = ap > aG(1) + 1e-8 & ap < aG(end);
        if ~any(unc), continue; end
        cp = zeros(sum(unc), ne);
        for ep = 1:ne
            cp(:, ep) = interp1(aG, polC(:, ep), ap(unc), 'linear');
        end
        rhs = p.beta * (1 + r) * (cp.^(-sig)) * Pi(e, :)';
        cimp = rhs.^(-1/sig);
        errs = [errs; abs(1 - cimp ./ cd(unc))]; %#ok<AGROW>
    end
    errs = max(errs, 1e-16);
    ee = struct('lmax', log10(max(errs)), 'lavg', log10(mean(errs)));
end

function s = ternchar(cond, a, b)
    if cond, s = a; else, s = b; end
end
