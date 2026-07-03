% MAIN_PROJECT_EXTENDED  Extended experiments for the journal-article draft
% (paper/green_deficits_price_level.tex). Runs the CARBON-STOCK climate
% sector (climate version 2) with the DAMAGE-INCIDENCE gradient, maps the
% multiplicity (climate-sunspot) frontier, re-computes self-financing under
% the extended sector, and runs the empirical anchor regression (E1).
%
% Sections (mapping to the paper):
%   X1. Extended benchmark: version-2 climate + incidence psi=1  (Sec. 3-4)
%   X2. Sunspot frontier: root counts and min eps_S over (psi, Gg) (Prop. 3)
%       nominal budget vs real mandate at each point            (Prop. 4)
%   X3. Self-financing under the extended sector                (Prop. 2)
%   X4. Empirical anchor regression E1 + optional E2 data check (Sec. 6)
%
% USAGE
%   >> main_project_extended            % full (na=500)
%   >> FAST = true; main_project_extended
%
% OUTPUTS: output/figures/PFig5-6, output/tables/extended_summary.txt,
%          output/logs/extended_run_log.txt, output/extended_results.mat

clearvars -except FAST; close all; clc;
rng(20260103, 'twister');
t0 = tic;

% ----- paths -----
projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

% ----- params -----
if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
if FAST
    pg.na    = pg.fast.na;
    u        = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
    pg.nP_scan = pg.fast.nP_scan;
    fprintf('*** FAST mode: na=%d ***\n', pg.na);
end

% extended configuration: carbon-stock sector
pg.climate_version = 2;

% ----- logging -----
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'extended_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' EXTENDED EXPERIMENTS: carbon-stock sector + damage incidence\n');
fprintf(' climate_version=2, na=%d\n', pg.na);
fprintf('==============================================================\n');

REX = struct();

% Extended experiments run at the ACCOMMODATIVE stance mu_ext (~ near the
% welfare optimum mu* = 0.045 of the baseline run). At mu = 0.02 the
% incidence gradient amplifies precautionary asset demand so much (S ~ 6)
% that P* = B/S would force real taxes past the lump-sum feasibility cliff:
% no stationary equilibrium exists -- a genuine fiscal-space-collapse
% result, recorded below, but not a useful laboratory.
mu_ext = pg.mu_ext;
r_ext  = (1 + pg.i_ss)/(1 + mu_ext) - 1;
fprintf('extended stance: mu_ext=%.3f (r_ss=%+.4f)\n', mu_ext, r_ext);

% no-abatement damages under version 2 (calibration check ~ 0.10)
D_noab = climate_block2(0, pg);
fprintf('version-2 no-abatement damages D(0) = %.4f (target ~ %.2f)\n', ...
        D_noab, pg.D0);
Dtop = max(D_noab, pg.D0);

% =====================================================================
% X1. Extended benchmark: psi = 1
% =====================================================================
fprintf('\n===== [X1] Extended benchmark (psi_inc=1, carbon stock) =====\n');
pg1 = pg; pg1.psi_inc = 1; pg1.mu = mu_ext;
pg1.Dgrid_S = linspace(0, Dtop, numel(pg.Dgrid_S));
ad2_x = build_S_interp_green(r_ext, pg1);
pol_x = struct('regime','nominal','i_ss',pg.i_ss,'mu',mu_ext, ...
               'Bnom',pg.Bnom,'Gg_nom',pg.Gg_nom);
[eqs_x, out_x] = solve_green_steady_state(pg1, pol_x, ad2_x);
fprintf('  %s\n', out_x.msg);
REX.x1 = struct('eqs',eqs_x,'out',out_x);

% =====================================================================
% X2. Sunspot frontier over (psi, Gg): nominal budget vs real mandate
% =====================================================================
fprintf('\n===== [X2] Sunspot frontier over (psi, Gg) =====\n');
psis = pg.psi_sweep;
Ggs  = [pg.Gg_nom, pg.Gg_big];
front = struct('psi',[],'Gg',[],'n_roots_nom',[],'n_roots_real',[], ...
               'min_epsS_nom',[],'P_roots',{{}});
row = 0; epsS_curves = cell(numel(psis), numel(Ggs));
for a = 1:numel(psis)
    pga = pg; pga.psi_inc = psis(a); pga.mu = mu_ext;
    pga.taugrid_S = pg.taugrid_mu;             % small grids for the sweep
    pga.Dgrid_S   = linspace(0, Dtop, 3);
    ad2a = build_S_interp_green(r_ext, pga);
    for b = 1:numel(Ggs)
        pol_n = struct('regime','nominal','i_ss',pg.i_ss,'mu',mu_ext, ...
                       'Bnom',pg.Bnom,'Gg_nom',Ggs(b));
        [eqn, outn] = solve_green_steady_state(pga, pol_n, ad2a);
        % comparable real mandate: index at the (first) nominal root's g_g
        if ~isempty(eqn), gfix = eqn(1).g_real; else, gfix = Ggs(b)/0.25; end
        pol_r = struct('regime','real','i_ss',pg.i_ss,'mu',mu_ext, ...
                       'Bnom',pg.Bnom,'g_real',gfix);
        [~, outr] = solve_green_steady_state(pga, pol_r, ad2a);

        row = row + 1;
        front.psi(row)          = psis(a);
        front.Gg(row)           = Ggs(b);
        front.n_roots_nom(row)  = outn.n_roots;
        front.n_roots_real(row) = outr.n_roots;
        mn = min(outn.eps_S(isfinite(outn.eps_S)));
        if isempty(mn), mn = NaN; end          % all-NaN elasticity: no crash
        front.min_epsS_nom(row) = mn;
        front.P_roots{row}      = [eqn.P];
        epsS_curves{a,b} = outn;
        fprintf(['  psi=%.1f Gg=%.3f: nominal roots=%d (min epsS=%+.2f), ' ...
                 'mandate roots=%d\n'], psis(a), Ggs(b), outn.n_roots, ...
                front.min_epsS_nom(row), outr.n_roots);
    end
end
REX.x2 = front; REX.x2_curves = epsS_curves;

% PFig6: eps_S(P) by incidence gradient (largest program)
fh6 = figure('Name','PFig6: Incidence and the demand elasticity', ...
             'Color','w','Position',[80 80 640 500]); hold on; box on;
cols = [0.10 0.30 0.75; 0.85 0.55 0.10; 0.85 0.20 0.15];
labs = {};
for a = 1:numel(psis)
    oc = epsS_curves{a, numel(Ggs)};
    if isempty(oc) || all(~isfinite(oc.eps_S)), continue; end   % skip empty
    plot(oc.Pgrid, oc.eps_S, '-', 'LineWidth', 2, 'Color', cols(min(a,3),:));
    labs{end+1} = sprintf('\\psi = %.0f', psis(a)); %#ok<SAGROW>
end
plot([pg.P_scan_min pg.P_scan_max], [-1 -1], 'k--', 'LineWidth', 1.3);
xlabel('price level  P'); ylabel('demand elasticity  \epsilon_S(P)');
title(sprintf('Incidence steepens the climate feedback (Gg=%.3f, nominal budget)', ...
      Ggs(end)));
legend([labs, {'\epsilon_S = -1'}], 'Location', 'southeast');
save_all_figs(fh6, 'PFig6_incidence_epsS', pg);
fprintf('  [saved] PFig6_incidence_epsS\n');

% =====================================================================
% X3. Self-financing under the extended sector (psi=1, version 2)
% =====================================================================
fprintf('\n===== [X3] Self-financing, extended sector =====\n');
% version-2 D(0) replaces D0 in the no-program state automatically (Gg=0).
dec_x = self_financing_decomposition(pg1, ad2_x);
REX.x3 = dec_x;

% =====================================================================
% X4. Empirics: E1 anchor regression; E2 data availability check
% =====================================================================
fprintf('\n===== [X4] Empirics =====\n');
emp = empirical_anchor(pg);
REX.emp = emp;
gd = load_green_budget_data(pg.green_csv);
if gd.ok
    fprintf('  E2 data found: %s (analysis to be specified with the data).\n', gd.msg);
else
    fprintf('  E2: %s\n', gd.msg);
end
REX.green_data = gd;

% =====================================================================
% Save + summary
% =====================================================================
save(fullfile(projdir, 'output', 'extended_results.mat'), 'REX', 'pg');
sf = fullfile(pg.tabdir, 'extended_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'EXTENDED RUN SUMMARY (climate version 2 + incidence)\n');
    fprintf(fid, 'D_noabatement=%.4f\n', D_noab);
    if ~isempty(eqs_x)
        fprintf(fid, 'X1 benchmark (psi=1): P*=%.4f D=%.4f tau=%.4f W=%.4f roots=%d\n', ...
            eqs_x(1).P, eqs_x(1).D, eqs_x(1).tau, eqs_x(1).W, out_x.n_roots);
    end
    for rr = 1:numel(front.psi)
        fprintf(fid, 'X2 psi=%.1f Gg=%.3f: nom roots=%d minEpsS=%+.3f mandate roots=%d P=%s\n', ...
            front.psi(rr), front.Gg(rr), front.n_roots_nom(rr), ...
            front.min_epsS_nom(rr), front.n_roots_real(rr), ...
            mat2str(front.P_roots{rr}, 4));
    end
    fprintf(fid, 'X3 nu=%.3f (reval %.3f + damage %.3f)\n', ...
            dec_x.nu, dec_x.nu_reval, dec_x.nu_damage);
    if emp.ok, fprintf(fid, 'X4 %s\n', emp.msg); end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

fprintf('\n================ EXTENDED SUMMARY ================\n');
if ~isempty(eqs_x)
    fprintf(' X1: P*=%.4f D=%.4f (D_noab=%.3f) tau=%.4f\n', ...
        eqs_x(1).P, eqs_x(1).D, D_noab, eqs_x(1).tau);
end
fprintf(' X2: max nominal-budget roots over frontier = %d; mandate always %d\n', ...
        max(front.n_roots_nom), max(front.n_roots_real));
fprintf(' X3: nu=%.3f (reval %.3f + damage %.3f)\n', dec_x.nu, dec_x.nu_reval, dec_x.nu_damage);
if emp.ok, fprintf(' X4: %s\n', emp.msg); end
fprintf(' Elapsed: %.1f s\n', toc(t0));
fprintf('==================================================\n');
diary off;
fprintf('Log saved to %s\n', logfile);
