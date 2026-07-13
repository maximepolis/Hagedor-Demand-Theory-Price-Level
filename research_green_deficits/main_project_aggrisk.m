% MAIN_PROJECT_AGGRISK  Aggregate climate risk, Stage A
% (appendix/AGGREGATE_RISK_PLAN.md). Two recurrent aggregate climate states
% (Calm / Severe). The nominal government bond is nominally safe but REALLY
% risky: its real value B/P_s is state-contingent, so it loses real value
% exactly in the Severe climate state -- a genuine climate-risk premium. The
% DTPL becomes a vector fixed point over the two state-contingent price
% levels (P_C, P_S). The headline experiment: green public investment lowers
% the Severe-state damage (via the same climate block used everywhere else),
% which COMPRESSES the state price dispersion and shrinks the disaster loss on
% the safe asset -- i.e. green investment reduces the systematic climate risk
% the nominal safe asset carries. This makes the paper's "safe asset" language
% literal and answers the "no aggregate uncertainty" objection with a computed
% result.
%
% USAGE   >> main_project_aggrisk               % na=500 benchmark grid
%         >> NA = 250; main_project_aggrisk      % mid-resolution (faster)
%         >> FAST = true; main_project_aggrisk   % na=100 quick check
%
% OUTPUT  PFig19_aggrisk.{fig,png,pdf}, output/aggrisk_results.mat,
%         output/tables/aggrisk_summary.txt
%
% STATUS: IMPLEMENTED (Stage A). STOCHASTIC AGGREGATE RISK tier -- a
% stationary recurrent equilibrium with prices measurable in the current
% aggregate state (exact as aggregate-state persistence -> 1).

clearvars -except FAST NA; close all; clc;
rng(20260109, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
% RESOLUTION CONTROL. Default is the 500-node benchmark grid (matches every
% other quantitative result in the paper -- this is the "dense-grid firming"
% of Result 7). FAST=true drops to 100 nodes (quick check). NA overrides both,
% so you can dial resolution vs. runtime, e.g. NA=250 for a mid-resolution run.
%   >> main_project_aggrisk               % na=500 (benchmark; slowest)
%   >> NA = 250;  main_project_aggrisk    % na=250 (faster, still fine)
%   >> FAST = true; main_project_aggrisk  % na=100 (quick)
% Runtime scales ~ na^2 (the household VFI does an na x na maximization per
% (e,s) state); the 500-node run is the heaviest but is pure MATLAB and cannot
% crash. Progress prints each fixed-point iteration.
if exist('NA','var') && ~isempty(NA)
    pg.na = NA;
elseif FAST
    pg.na = pg.fast.na;
end
if pg.na ~= numel(pg.aGrid)
    u = linspace(0,1,pg.na)';
    pg.aGrid = -pg.abar + (pg.amax + pg.abar) * (u.^pg.acurv);
    pg.aGrid(1) = -pg.abar; pg.aGrid(end) = pg.amax;
end
fprintf('*** aggregate-risk resolution: na=%d ***\n', pg.na);
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'aggrisk_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' AGGREGATE CLIMATE RISK (Stage A): two-regime DTPL, na=%d\n', pg.na);
fprintf('==============================================================\n');

% calibrated discount factor (reuse the calibrated pass if present)
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    if isfield(L,'RCAL') && isfield(L.RCAL,'beta_star')
        pg.beta = L.RCAL.beta_star;
        fprintf('loaded calibrated beta*=%.4f\n', pg.beta);
    end
end
i_nom = pg.i_ss;
opts  = struct('i_nom', i_nom, 'Bnom', pg.Bnom, 'verbose', true);

% ---- BASELINE: no green program, damages at the no-abatement state levels ----
D0s = pg.agg.D_states;                          % [Calm, Severe]
fprintf('\n--- BASELINE (no program): D = [%.3f, %.3f] ---\n', D0s);
TRb = solve_dtpl_aggrisk(pg, D0s, opts);
fprintf('  %s\n', TRb.msg);

% ---- GREEN: the SAME climate block used elsewhere, applied per state.
% A green program of ~2% of mean income builds Kg = g_g/delta_g, which lowers
% D_s = D0_s * exp(-theta_g*Kg) in BOTH states -- more in absolute terms in the
% high-damage Severe state, which is what compresses the gap. ----
g_share = 0.02;                                  % real green spending / income
g_g     = g_share * 1.0;                          % mean income normalized to 1
Kg      = g_g / pg.delta_g;
Dg      = D0s .* exp(-pg.theta_g * Kg);
fprintf('\n--- GREEN (g_g=%.3f, Kg=%.3f): D = [%.3f, %.3f] ---\n', g_g, Kg, Dg);
TRg = solve_dtpl_aggrisk(pg, Dg, opts);
fprintf('  %s\n', TRg.msg);

save(fullfile(projdir,'output','aggrisk_results.mat'), 'TRb','TRg','pg','opts','Kg','Dg');

% ---- PFig19 ----
if TRb.converged && TRg.converged
    fh = figure('Name','PFig19: aggregate climate risk','Color','w', ...
                'Position',[60 60 1250 470]);
    lab = {'Calm','Severe'};
    subplot(1,3,1); hold on; box on;
    bh = bar([TRb.P(:), TRg.P(:)]);
    set(bh(1),'FaceColor',[0.55 0.65 0.85]); set(bh(2),'FaceColor',[0.45 0.70 0.45]);
    set(gca,'XTick',1:2,'XTickLabel',lab);
    ylabel('price level P_s');
    ylim([0, 1.30*max([TRb.P(:); TRg.P(:)])]);   % headroom keeps legend clear
    legend({'baseline','green program'},'Location','northwest');
    title('(a) state price levels');
    subplot(1,3,2); hold on; box on;
    bar(1, TRb.price_disp, 0.55, 'FaceColor',[0.55 0.65 0.85]);
    bar(2, TRg.price_disp, 0.55, 'FaceColor',[0.45 0.70 0.45]);
    set(gca,'XTick',1:2,'XTickLabel',{'baseline','green'},'XLim',[0.4 2.6]);
    ylabel('P_S/P_C - 1');
    title('(b) price dispersion');
    subplot(1,3,3); hold on; box on;
    bar(1, 100*TRb.r_disaster, 0.55, 'FaceColor',[0.55 0.65 0.85]);
    bar(2, 100*TRg.r_disaster, 0.55, 'FaceColor',[0.45 0.70 0.45]);
    set(gca,'XTick',1:2,'XTickLabel',{'baseline','green'},'XLim',[0.4 2.6]);
    ylabel('disaster return (%)');
    title('(c) Calm\rightarrowSevere return');
    save_all_figs(fh, 'PFig19_aggrisk', pg);
    fprintf('\n  [saved] PFig19_aggrisk\n');
end

% ---- summary table ----
sf = fullfile(pg.tabdir, 'aggrisk_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'AGGREGATE CLIMATE RISK (Stage A) -- STOCHASTIC AGGREGATE RISK\n');
    fprintf(fid, 'Two recurrent aggregate states (Calm/Severe); nominal bond nominally\n');
    fprintf(fid, 'safe, really risky (B/P_s state-contingent). Stationary recurrent\n');
    fprintf(fid, 'equilibrium, prices measurable in the aggregate state. na=%d, i=%.3f.\n', pg.na, i_nom);
    fprintf(fid, 'Pi_agg = [%.2f %.2f; %.2f %.2f].\n\n', pg.Pi_agg');
    writeblock(fid, 'BASELINE (no program)', D0s, TRb);
    writeblock(fid, sprintf('GREEN (g_g=%.3f, Kg=%.3f)', g_g, Kg), Dg, TRg);
    if TRb.converged && TRg.converged
        fprintf(fid, 'GREEN EFFECT ON THE SAFE ASSET:\n');
        fprintf(fid, '  state price dispersion  %.4f -> %.4f  (%+.1f%%)\n', ...
            TRb.price_disp, TRg.price_disp, 100*(TRg.price_disp/TRb.price_disp-1));
        fprintf(fid, '  disaster real return    %+.4f -> %+.4f  (loss shrinks %.4f)\n', ...
            TRb.r_disaster, TRg.r_disaster, TRg.r_disaster - TRb.r_disaster);
        fprintf(fid, '  bond risk premium       %+.4f -> %+.4f\n', TRb.premium, TRg.premium);
        fprintf(fid, ['\n=> green public investment lowers a SYSTEMATIC climate risk: it\n' ...
            'compresses the state price dispersion and shrinks the real loss the\n' ...
            'nominal safe asset takes in the Severe climate state. The safe-asset\n' ...
            'language is literal here.\n']);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end
fprintf('\nElapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function writeblock(fid, name, Dvec, TR)
    fprintf(fid, '[%s]  D=[%.3f, %.3f]\n', name, Dvec);
    if ~TR.converged
        fprintf(fid, '  NOT CONVERGED: %s\n\n', TR.msg); return;
    end
    fprintf(fid, '  price levels  P=[%.4f, %.4f]  (Calm, Severe)\n', TR.P);
    fprintf(fid, '  asset demand  S=[%.4f, %.4f]\n', TR.S);
    fprintf(fid, '  price disp.   P_S/P_C-1 = %.4f\n', TR.price_disp);
    fprintf(fid, '  real returns  R(Calm->{Calm,Severe}) = [%.4f, %.4f]\n', TR.R(1,:));
    fprintf(fid, '  disaster ret. Calm->Severe = %+.4f;  E[real ret]=%+.4f;  premium=%+.4f\n\n', ...
        TR.r_disaster, TR.Er_bond, TR.premium);
end
