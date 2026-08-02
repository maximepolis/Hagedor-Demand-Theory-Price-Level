% MAIN_PROJECT_RUN_ALL  Master script for the research project
%   "Can Green Deficits Finance Themselves? Climate Investment, Asset Demand,
%    and Self-Fulfilling Price Levels in Incomplete-Markets Economies"
% built on the Hagedorn (2026) DTPL replication package in the repo root.
%
% Sections (mapping to MODEL_AND_THEORY.md):
%   1. S(tau,D) interpolant at the baseline real rate   (Lemma 1 object)
%   2. Benchmark green steady state                     (Proposition 1, PFig1)
%   3. Self-financing decomposition + theta_g sweep     (Proposition 2, PFig2)
%   4. Climate sunspots vs real mandate                 (Prop. 3-4, PFig3)
%   5. Optimal accommodation W(mu)                      (Proposition 5, PFig4)
%
% USAGE
%   >> main_project_run_all          % full run (na = 500; ~30-45 min)
%   >> FAST = true; main_project_run_all   % quick pass (na = 100; ~5 min)
%
% OUTPUTS (inside research_green_deficits/output/)
%   figures/PFig1..PFig4.{fig,png,pdf}, tables/project_summary.txt,
%   logs/project_run_log.txt, project_results.mat

clearvars -except FAST; close all; clc;
rng(20260102, 'twister');
t0 = tic;

% ----- paths: repo-root src + project src_project -----
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

% ----- params (+ FAST mode) -----
if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    pg.taugrid_S   = pg.fast.taugrid_S;
    pg.Dgrid_S     = pg.fast.Dgrid_S;
    pg.nP_scan     = pg.fast.nP_scan;
    pg.theta_sweep = pg.fast.theta_sweep;
    pg.mu_grid     = pg.fast.mu_grid;
    fprintf('*** FAST mode: na=%d ***\n', pg.na);
end

% ----- logging -----
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
if ~isfolder(pg.figdir), mkdir(pg.figdir); end
logfile = fullfile(pg.logdir, 'project_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' PROJECT: Can Green Deficits Finance Themselves?\n');
fprintf(' (climate investment, asset demand, self-fulfilling price levels)\n');
fprintf(' Built on the Hagedorn (2026) DTPL replication. na=%d\n', pg.na);
fprintf('==============================================================\n');

RESP = struct();

% =====================================================================
% 1. S(tau, D) interpolant at the baseline real rate
% =====================================================================
fprintf('\n===== [1/5] S(tau,D) interpolant (Lemma 1 object) =====\n');
r_base = (1 + pg.i_ss)/(1 + pg.mu) - 1;
ad2 = build_S_interp_green(r_base, pg);
RESP.ad2_nodes = struct('taugrid',ad2.taugrid,'Dgrid',ad2.Dgrid,'Smat',ad2.Smat);

% =====================================================================
% 2. Benchmark green steady state (Proposition 1)
% =====================================================================
fprintf('\n===== [2/5] Benchmark green steady state (Prop. 1) =====\n');
pol_bench = struct('regime','nominal','i_ss',pg.i_ss,'mu',pg.mu, ...
                   'Bnom',pg.Bnom,'Gg_nom',pg.Gg_nom);
[eqs_b, out_b] = solve_green_steady_state(pg, pol_bench, ad2);
fprintf('  %s\n', out_b.msg);
RESP.bench     = out_b;
RESP.bench_eqs = eqs_b;

% =====================================================================
% 3. Self-financing decomposition (Proposition 2)
% =====================================================================
fprintf('\n===== [3/5] Self-financing decomposition (Prop. 2) =====\n');
dec = self_financing_decomposition(pg, ad2);
RESP.dec = dec;

% =====================================================================
% 4. Climate sunspots vs anchor insulation (Propositions 3-4)
% =====================================================================
fprintf('\n===== [4/5] Sunspots vs mandate (Prop. 3-4) =====\n');
theta_hi = max(pg.theta_sweep);          % strongest feedback in the sweep
pol_hi   = struct('regime','nominal','i_ss',pg.i_ss,'mu',pg.mu, ...
                  'Bnom',pg.Bnom,'Gg_nom',pg.Gg_nom,'theta_g',theta_hi);
[eqs_hi, out_hi] = solve_green_steady_state(pg, pol_hi, ad2);
fprintf('  nominal budget: %s\n', out_hi.msg);

% real mandate at the same theta_g: index green spending at the benchmark
% equilibrium's real level (so the two regimes are comparable at the root)
if ~isempty(eqs_b), g_fix = eqs_b(1).g_real; else, g_fix = pg.Gg_nom/0.25; end
pol_rm = struct('regime','real','i_ss',pg.i_ss,'mu',pg.mu, ...
                'Bnom',pg.Bnom,'g_real',g_fix,'theta_g',theta_hi);
[eqs_rm, out_rm] = solve_green_steady_state(pg, pol_rm, ad2);
fprintf('  real mandate  : %s\n', out_rm.msg);

RESP.sun = struct('nominal_hi',out_hi,'real_hi',out_rm, ...
                  'nominal_eqs',eqs_hi,'real_eqs',eqs_rm,'theta_hi',theta_hi);
if out_hi.n_roots > 1 && out_rm.n_roots == 1
    fprintf(['  => Proposition 3-4 configuration realized: multiplicity under\n' ...
             '     the nominal green budget, uniqueness under the real mandate.\n']);
elseif out_hi.n_roots <= 1
    fprintf(['  => No multiplicity at theta_g=%.2f under this calibration;\n' ...
             '     raise theta_sweep or program size to probe Proposition 3.\n'], theta_hi);
end

% =====================================================================
% 5. Optimal accommodation (Proposition 5)
% =====================================================================
fprintf('\n===== [5/5] Optimal accommodation W(mu) (Prop. 5) =====\n');
opt = optimal_policy_green(pg);
RESP.opt = opt;

% =====================================================================
% Figures, results file, summary table
% =====================================================================
plot_green_figures(RESP, pg);
save(fullfile(projdir, 'output', 'project_results.mat'), 'RESP', 'pg');

sf = fullfile(pg.tabdir, 'project_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'Can Green Deficits Finance Themselves? -- generated summary\n');
    fprintf(fid, 'benchmark: theta_g=%.2f Gg=%.3f D0=%.2f phi_D=%.2f na=%d\n', ...
            pg.theta_g, pg.Gg_nom, pg.D0, pg.phi_D, pg.na);
    if ~isempty(eqs_b)
        fprintf(fid, 'green SS: P*=%.4f D=%.4f tau=%.4f W=%.4f (roots=%d)\n', ...
            eqs_b(1).P, eqs_b(1).D, eqs_b(1).tau, eqs_b(1).W, out_b.n_roots);
    end
    fprintf(fid, 'self-financing: nu=%.3f (reval %.3f + damage %.3f), levy=%.4f\n', ...
            dec.nu, dec.nu_reval, dec.nu_damage, dec.levy);
    fprintf(fid, 'sunspots at theta_g=%.2f: nominal roots=%d, mandate roots=%d\n', ...
            theta_hi, out_hi.n_roots, out_rm.n_roots);
    fprintf(fid, 'optimal accommodation: mu*=%.3f (W=%.4f)\n', opt.mu_star, opt.W_star);
    if ~isempty(eqs_b)
        fprintf(fid, 'wealth gini=%.3f income gini=%.3f (benchmark SS)\n', ...
                eqs_b(1).gini_a, eqs_b(1).gini_y);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ----- console summary -----
fprintf('\n================= PROJECT SUMMARY =================\n');
if ~isempty(eqs_b)
    fprintf(' Green steady state: P*=%.4f, D=%.4f (vs D0=%.2f), tau=%.4f\n', ...
        eqs_b(1).P, eqs_b(1).D, pg.D0, eqs_b(1).tau);
end
fprintf(' Self-financing share nu = %.3f (revaluation %.3f + damage %.3f)\n', ...
        dec.nu, dec.nu_reval, dec.nu_damage);
fprintf(' Sunspot check at theta_g=%.2f: nominal budget %d root(s), real mandate %d\n', ...
        theta_hi, out_hi.n_roots, out_rm.n_roots);
fprintf(' Optimal nominal growth mu* = %.3f\n', opt.mu_star);
fprintf(' Elapsed: %.1f s\n', toc(t0));
fprintf('===================================================\n');
diary off;
fprintf('Log saved to %s\n', logfile);
