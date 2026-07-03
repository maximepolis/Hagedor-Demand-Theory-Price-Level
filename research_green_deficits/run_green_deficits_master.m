% RUN_GREEN_DEFICITS_MASTER  One-command master script for the project
% "Can Green Deficits Finance Themselves?" -- reproduces the baseline
% benchmark, runs the extended experiments (carbon-stock sector, incidence
% gradient, sunspot frontier, empirical anchor), and writes a consolidated
% model-status summary with parameter record.
%
% USAGE
%   >> run_green_deficits_master            % full (na = 500)
%   >> FAST = true; run_green_deficits_master
%
% WHAT RUNS (in order)
%   1. main_project_run_all       baseline: Props 1-5, PFig1-4  [IMPLEMENTED]
%   2. main_project_extended      carbon stock + incidence + empirics,
%                                 PFig5-6                        [IMPLEMENTED]
%   3. consolidated status summary -> output/tables/master_status.txt
%
% NOT RUN HERE (see MODEL_STATUS.md):
%   - transition dynamics (Dynare RANK-NK skeleton in dynare/;
%     HANK transitions NOT YET IMPLEMENTED)
%   - distortionary-tax and debt-maturity regimes (PROPOSED)
%
% Every figure/table is produced by code; nothing is manually edited.

clearvars -except FAST; close all; clc;
master_t0 = tic;
if ~exist('FAST','var'), FAST = false; end

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);

% ---- 1. baseline package ----
fprintf('\n############ MASTER 1/3: baseline (main_project_run_all) ############\n');
main_project_run_all;                       % leaves RESP, pg in workspace
RESP_base = RESP; pg_base = pg;

% ---- 2. extended package ----
fprintf('\n############ MASTER 2/3: extended (main_project_extended) ############\n');
FAST_saved = FAST;   % main scripts clearvars-except-FAST; keep flag alive
FAST = FAST_saved; %#ok<NASGU>
main_project_extended;                      % leaves REX, pg in workspace
REX_ext = REX; pg_ext = pg;

% ---- 3. consolidated status summary + parameter record ----
fprintf('\n############ MASTER 3/3: status summary ############\n');
sf = fullfile(pg_ext.tabdir, 'master_status.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'GREEN DEFICITS MASTER RUN -- consolidated status\n');
    fprintf(fid, 'date: (see log timestamps)  na=%d  FAST=%d\n\n', pg_ext.na, FAST_saved);

    fprintf(fid, '--- PARAMETER RECORD (benchmark; all climate values ILLUSTRATIVE) ---\n');
    plist = {'beta','sigma','abar','na','ne','rho','sig_eps0','Bnom','i_ss', ...
             'mu','mu_ext','Gg_nom','Gg_big','D0','theta_g','delta_g','phi_D', ...
             'psi_inc','Dmax','eps0','delta_x','gamma_x','alpha_A'};
    for k = 1:numel(plist)
        if isfield(pg_ext, plist{k})
            v = pg_ext.(plist{k});
            if isscalar(v), fprintf(fid, '  %-10s = %g\n', plist{k}, v); end
        end
    end

    fprintf(fid, '\n--- BASELINE RESULTS (steady state only) ---\n');
    if isfield(RESP_base,'bench_eqs') && ~isempty(RESP_base.bench_eqs)
        e = RESP_base.bench_eqs(1);
        fprintf(fid, '  green SS: P*=%.4f D=%.4f tau=%.4f\n', e.P, e.D, e.tau);
    end
    if isfield(RESP_base,'dec')
        d = RESP_base.dec;
        fprintf(fid, '  nu=%.3f (reval %.3f + damage %.3f)\n', d.nu, d.nu_reval, d.nu_damage);
    end
    if isfield(RESP_base,'opt')
        fprintf(fid, '  mu*=%.3f\n', RESP_base.opt.mu_star);
    end

    fprintf(fid, '\n--- EXTENDED RESULTS (steady state only) ---\n');
    if isfield(REX_ext,'x2')
        fprintf(fid, '  sunspot frontier rows: %d; max nominal roots=%d\n', ...
            numel(REX_ext.x2.psi), max(REX_ext.x2.n_roots_nom));
    end
    if isfield(REX_ext,'emp') && REX_ext.emp.ok
        fprintf(fid, '  E1: %s\n', REX_ext.emp.msg);
    end

    fprintf(fid, '\n--- IMPLEMENTATION STATUS (see MODEL_STATUS.md for detail) ---\n');
    fprintf(fid, '  steady-state HA price-level block ........ IMPLEMENTED\n');
    fprintf(fid, '  climate v1/v2 + incidence gradient ....... IMPLEMENTED\n');
    fprintf(fid, '  self-financing decomposition (4 channels)  IMPLEMENTED\n');
    fprintf(fid, '  liquidity/maturity/sectoral channels ..... PROPOSED\n');
    fprintf(fid, '  transition dynamics (RANK-NK skeleton) ... PARTIALLY IMPLEMENTED (dynare/)\n');
    fprintf(fid, '  HANK transitions (sequence-space) ........ NOT YET IMPLEMENTED\n');
    fprintf(fid, '  distortionary taxes / debt maturity ...... PROPOSED\n');
    fprintf(fid, '  empirical anchor E1 ...................... IMPLEMENTED\n');
    fprintf(fid, '  green-budget panel E2 .................... SPECIFIED (data absent)\n');
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

fprintf('\nMASTER RUN COMPLETE in %.1f s. See MODEL_STATUS.md and ROADMAP.md.\n', ...
        toc(master_t0));
