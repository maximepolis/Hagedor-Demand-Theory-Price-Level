% RUN_GREEN_TRANSITIONS  U6 driver: runs green_rank_nk.mod under the FOUR
% monetary regimes required by the research-program specification, collects
% the perfect-foresight transition paths, and produces the regime-comparison
% figure PFig13 plus a summary table.
%
%   WEAK         weakly active rule (RHOI=0.5, PHIPI=1.1): the closest
%                numerically regular stand-in for a peg -- a pure peg
%                (and even PHIPI=1.01) leaves the stacked perfect-
%                foresight Newton system singular or near-singular
%   TAYLOR       standard inertial Taylor rule   (RHOI=0.8, PHIPI=1.5)
%   AGGRESSIVE   strict inflation targeting      (RHOI=0.0, PHIPI=3.0)
%   GREENACCOM   Taylor + temporary green accommodation tied to the
%                green-capital gap (PSIG=0.03; with a peak kg-gap of 0.6
%                this is a LARGE experiment: ~1.8pp quarterly = ~7.2pp
%                annualized rate cut at the program start, fading with
%                the gap -- deliberately sized to make the accommodation
%                channel visible in the figure)
%
% REQUIREMENTS: Dynare (5.x/6.x) on the MATLAB path; run from this folder.
% HONEST SCOPE: these are RANK/NK transition DIAGNOSTICS -- they carry the
% real/nominal transition shapes, not the paper's DTPL price-level mechanism
% (see dynare/README.md and appendix/HANK_TRANSITION_PLAN.md).
%
% USAGE:  >> cd research_green_deficits/dynare
%         >> run_green_transitions
%
% OUTPUT: PFig13_rank_transitions.{fig,png,pdf} in ../output/figures,
%         dynare_transitions.mat, ../output/tables/transitions_summary.txt.

clear; close all;
t0 = tic;

dyndir = fileparts(mfilename('fullpath'));
if isempty(dyndir), dyndir = pwd; end
cd(dyndir);
projdir = fileparts(dyndir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));
pg = setup_params_green();          % for figdir/tabdir only

if exist('dynare', 'file') ~= 2
    error(['Dynare not found on the MATLAB path. Install Dynare and ' ...
           'addpath <dynare>/matlab, then rerun.']);
end

% Regime notes (post-diagnosis of the first run):
% * QUASIPEG replaces the pure peg: phi_pi = 1.01 barely satisfies the
%   Taylor principle, approximating a peg while keeping the stacked
%   perfect-foresight system regular (a pure peg made Newton fail and the
%   driver silently accepted the unconverged path -- both fixed below).
% * GREENACCOM uses psi_g = 0.05: with a peak kg-gap of 0.6 this delivers
%   roughly a 120bp ANNUALIZED accommodation at the start of the program,
%   fading with the gap. The first run's psi_g = 0.5 implied an absurd
%   ~30pp annualized cut and never converged.
% Post-second-failure design: WEAK (phi_pi=1.1) replaces the quasi-peg
% (phi_pi=1.01 is numerically near-singular); psi_g=0.03; and the .mod now
% RAMPS the program in over 12 quarters with chained solver fallbacks.
regimes = struct( ...
    'name',  {'WEAK', 'TAYLOR', 'AGGRESSIVE', 'GREENACCOM'}, ...
    'defs',  {'-DRHOI=0.5 -DPHIPI=1.1 -DPSIG=0.0', ...
              '-DRHOI=0.8 -DPHIPI=1.5 -DPSIG=0.0', ...
              '-DRHOI=0.0 -DPHIPI=3.0 -DPSIG=0.0', ...
              '-DRHOI=0.8 -DPHIPI=1.5 -DPSIG=0.03'});

vars_keep = {'y','ppi','b','kg','d','tau','c','i','gg'};
RES = struct();
ok  = false(1, numel(regimes));
VAL = struct('name', {regimes.name}, 'converged', num2cell(false(1,numel(regimes))), ...
             'kgres', num2cell(nan(1,numel(regimes))), ...
             'included', num2cell(false(1,numel(regimes))), ...
             'note', repmat({''}, 1, numel(regimes)));

for rgm = 1:numel(regimes)
    fprintf('\n===== regime %s =====\n', regimes(rgm).name);
    try
        % run each regime as its OWN model file: repeated dynare calls on one
        % .mod with different -D defines can collide with stale generated
        % artifacts on Windows; fresh copies guarantee a clean preprocess.
        nm = sprintf('grnk_%s', lower(regimes(rgm).name));
        copyfile('green_rank_nk.mod', [nm '.mod']);
        copyfile('green_rank_nk_steadystate.m', [nm '_steadystate.m']);
        if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
        if exist(nm, 'dir'), rmdir(nm, 's'); end
        eval(sprintf('dynare %s %s noclearall nolog', nm, regimes(rgm).defs));
        % HARD convergence check: perfect_foresight_solver signals failure
        % via a status flag WITHOUT throwing (first run accepted garbage).
        if isfield(oo_, 'deterministic_simulation') && ...
           isfield(oo_.deterministic_simulation, 'status') && ...
           ~oo_.deterministic_simulation.status                   %#ok<NODEF>
            warning('run_green_transitions:noconv', ...
                'Regime %s: perfect-foresight solver DID NOT CONVERGE; path discarded.', ...
                regimes(rgm).name);
            VAL(rgm).note = 'solver did not converge';
            continue;
        end
        VAL(rgm).converged = true;
        % collect paths by variable name (rows of oo_.endo_simul follow M_.endo_names)
        sim = oo_.endo_simul;
        paths = struct();
        for v = 1:numel(vars_keep)
            idx = find(strcmp(cellstr(M_.endo_names), vars_keep{v}), 1); %#ok<NODEF>
            if ~isempty(idx), paths.(vars_keep{v}) = sim(idx, :); end
        end
        % mechanical validation: kg_t = (1-delta_g)*kg_{t-1} + gg_t must hold
        % on any converged path, REGARDLESS of the monetary regime.
        % EXCLUDE the last column: it is the terminal steady state appended
        % after the horizon, not a point determined by the dynamics, so it
        % sits a truncation gap (~kg_gap*0.975^T ~ 3e-4) away from the law.
        if isfield(paths,'kg') && isfield(paths,'gg')
            kgres = max(abs(paths.kg(2:end-1) - ...
                (1-M_.params(strcmp(cellstr(M_.param_names),'delta_g'))) ...
                * paths.kg(1:end-2) - paths.gg(2:end-1)));
            VAL(rgm).kgres = kgres;
            if kgres > 1e-6
                warning('run_green_transitions:kglaw', ...
                    'Regime %s: kg accumulation law violated (%.2e); path discarded.', ...
                    regimes(rgm).name, kgres);
                VAL(rgm).note = sprintf('kg law violated (%.2e)', kgres);
                continue;
            end
        end
        RES.(regimes(rgm).name) = paths;
        ok(rgm) = true;
        VAL(rgm).included = true;
        fprintf('  [%s solved: %d periods]\n', regimes(rgm).name, size(sim,2));
    catch ME
        warning('run_green_transitions:fail', ...
            'Regime %s failed: %s (Dynare version differences are the usual cause).', ...
            regimes(rgm).name, ME.message);
    end
end

if ~any(ok)
    error('No regime solved; inspect the Dynare error messages above.');
end

% ---- PFig13: regime comparison ----
% Descriptive legend labels: the interest-rate rule each scenario runs under.
% The green-investment PROGRAM (a permanent rise in real green spending) is
% identical across scenarios; what differs is the monetary rule reacting to
% the induced inflation, so the spread across curves IS the rule's influence.
lblmap = containers.Map( ...
    {'WEAK','TAYLOR','AGGRESSIVE','GREENACCOM'}, ...
    {'Weakly active rule (\phi_\pi=1.1)', 'Taylor rule (\phi_\pi=1.5)', ...
     'Aggressive targeting (\phi_\pi=3.0)', 'Green accommodation'});
cols = [0.10 0.30 0.75; 0.85 0.20 0.15; 0.85 0.55 0.10; 0.20 0.55 0.25];
panels = {'y','output'; 'ppi','inflation (net, qtr)'; 'b','real debt'; ...
          'kg','green capital'; 'd','damages'; 'tau','taxes'};
fh = figure('Name','PFig13: RANK transition diagnostics','Color','w', ...
            'Position',[60 60 1100 680]);
Tshow = 120;
names_ok = {regimes(ok).name};
leg_labels = cellfun(@(n) lblmap(n), names_ok, 'UniformOutput', false);
leg_handles = gobjects(1, numel(names_ok));
for pp = 1:size(panels,1)
    subplot(2,3,pp); hold on; box on;
    ii = 0;
    for rgm = 1:numel(regimes)
        if ~ok(rgm), continue; end
        ii = ii + 1;
        s = RES.(regimes(rgm).name);
        if isfield(s, panels{pp,1})
            v = s.(panels{pp,1});
            h = plot(0:min(Tshow,numel(v))-1, v(1:min(Tshow,numel(v))), ...
                 'LineWidth', 1.8, 'Color', cols(rgm,:));
            if pp == 1, leg_handles(ii) = h; end
        end
    end
    yline(0, ':', 'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
    xlabel('quarters'); title(panels{pp,2});
end
% One shared horizontal legend across the bottom, declaring every scenario.
valid = isgraphics(leg_handles);
lg = legend(leg_handles(valid), leg_labels(valid), 'Orientation', 'horizontal', ...
            'NumColumns', min(4, sum(valid)));
lg.Position = [0.5 - lg.Position(3)/2, 0.005, lg.Position(3), lg.Position(4)];
sgtitle('RANK transitions to a permanent green-investment program (deviations from initial steady state)');
save_all_figs(fh, 'PFig13_rank_transitions', pg);
fprintf('\n  [saved] PFig13_rank_transitions\n');

save(fullfile(projdir, 'output', 'dynare_transitions.mat'), 'RES', 'regimes', 'ok');

sf = fullfile(pg.tabdir, 'transitions_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'U6 RANK/NK TRANSITIONS (perfect foresight, permanent program)\n');
    fprintf(fid, 'HONEST SCOPE: RANK diagnostics, not the DTPL price-level mechanism.\n');
    for rgm = 1:numel(regimes)
        if ~ok(rgm), fprintf(fid, '%-11s FAILED (not converged; discarded)\n', regimes(rgm).name); continue; end
        s = RES.(regimes(rgm).name);
        fprintf(fid, ['%-11s CONVERGED  pi impact %+.4f (annualized %+.2f%%), ' ...
            'pi peak %+.4f, debt peak %.3f, kg(40q) %.3f, d(40q) %.4f\n'], ...
            regimes(rgm).name, s.ppi(2), 400*s.ppi(2), max(s.ppi), max(s.b), ...
            s.kg(min(41,end)), s.d(min(41,end)));
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

% ---- validation table (audit requirement: rank_transition_validation.txt) ----
vf = fullfile(pg.tabdir, 'rank_transition_validation.txt');
fid = fopen(vf, 'w');
if fid > 0
    fprintf(fid, 'U6 RANK/NK TRANSITION VALIDATION\n');
    fprintf(fid, 'Scope label: RANK/NK TRANSITION DIAGNOSTIC (not the DTPL price-level mechanism).\n');
    fprintf(fid, 'Fiscal note: the .mod tax rule finances gg CONTEMPORANEOUSLY (tau includes +gg),\n');
    fprintf(fid, 'so this experiment is tax-financed by design; deficit financing on impact is the\n');
    fprintf(fid, 'HANK tier (run_green_hank) and the steady-state MATLAB block.\n');
    fprintf(fid, 'Program: GSIZE ramped in linearly over 12 quarters; horizon 300 quarters.\n\n');
    fprintf(fid, '%-11s %-10s %-12s %-9s %-10s %-10s %-9s %-9s %-9s\n', ...
        'regime', 'converged', 'kg-law res', 'included', 'pi impact', 'pi peak', ...
        'b peak', 'kg(40q)', 'd(40q)');
    for rgm = 1:numel(regimes)
        if VAL(rgm).included
            s = RES.(regimes(rgm).name);
            fprintf(fid, '%-11s %-10s %-12.2e %-9s %+-10.4f %+-10.4f %-9.4f %-9.4f %-9.4f\n', ...
                VAL(rgm).name, 'yes', VAL(rgm).kgres, 'yes', ...
                s.ppi(2), max(s.ppi), max(s.b), s.kg(min(41,end)), s.d(min(41,end)));
        else
            fprintf(fid, '%-11s %-10s %-12s %-9s (%s)\n', VAL(rgm).name, ...
                ternary_str(VAL(rgm).converged,'yes','NO'), '-', 'NO', VAL(rgm).note);
        end
    end
    fprintf(fid, '\nInterpretation guide: pi is NET QUARTERLY inflation (x400 for annualized pp);\n');
    fprintf(fid, 'kg-law residual is max|kg_t-(1-delta_g)kg_{t-1}-gg_t| over interior columns\n');
    fprintf(fid, '(terminal steady-state column excluded: it is appended, not simulated).\n');
    fprintf(fid, 'GREENACCOM is a deliberately LARGE accommodation experiment: psi_g=0.03 with a\n');
    fprintf(fid, 'peak kg-gap of 0.6 implies ~1.8pp quarterly (~7.2pp annualized) initial rate cut.\n');
    fclose(fid);
    fprintf('  [saved] %s\n', vf);
end
fprintf('Elapsed: %.1f s\n', toc(t0));

function s = ternary_str(cond, a, b)
    if cond, s = a; else, s = b; end
end
