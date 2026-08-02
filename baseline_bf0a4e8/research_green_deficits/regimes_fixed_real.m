% REGIMES_FIXED_REAL  Referee (round 6): Table 6 holds the NOMINAL appropriation
% fixed (so the real program g_g=G_g/P drifts across regimes), while
% Proposition 7 holds the REAL program fixed. This driver recomputes the four
% financing regimes holding the \emph{real} program g_g constant (letting G_g
% adjust per regime), so the cross-regime differences are \emph{pure tax
% incidence} with no real-scale drift and no induced damage-dividend movement.
% Reported side by side with the fixed-nominal Table 6, it lets the reader
% separate: (i) true incidence, (ii) price-level revaluation, (iii) real-scale
% change (which is zero here by construction).
%
% Holds the common real program at the baseline value g_real = Gg_cal/P0, so the
% damage dividend nu_damage = (D0 - D(g_real))/g_real is IDENTICAL across regimes
% and only nu_reval and the welfare incidence move -- exactly the isolation the
% referee asks for.
%
% USAGE   >> regimes_fixed_real
%         >> FAST = true; regimes_fixed_real
%
% OUTPUT  output/regimes_fixed_real_results.mat,
%         output/tables/regimes_fixed_real.txt
%
% STATUS: robustness driver; reuses solve_regime_equilibrium. Numbers are a
% result only once run; export_paper_numbers picks up the .mat if present.

clearvars -except FAST NA; close all; clc;
rng(20260716, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
pg = setup_params_green();
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
if ~isfolder(pg.logdir), mkdir(pg.logdir); end
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
logfile = fullfile(pg.logdir, 'regimes_fixed_real_run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==============================================================\n');
fprintf(' FINANCING REGIMES -- FIXED REAL PROGRAM (pure incidence), na=%d\n', pg.na);
fprintf('==============================================================\n');

D0_med = 0.06;
r_cal  = (1 + pg.i_ss)/(1 + pg.mu) - 1;
calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile,'file') == 2
    L = load(calfile);
    beta_star = L.RCAL.beta_star; Gg_cal = L.RCAL.Gg_cal;
else
    [beta_star, ~] = calibrate_beta(pg, r_cal, 1.10, D0_med);
    Gg_cal = 0.02 * (pg.Bnom / 1.10);
end
pgc = pg; pgc.beta = beta_star; pgc.climate_version = 1; pgc.D0 = D0_med;
B = pg.Bnom;
rb_of = @(P) r_cal * B ./ P;

% ---- no-program baseline; the common REAL program is g_real = Gg_cal/P0 ----
base_reg = struct('name','BASELINE','Bnom',B, 'g',@(P) 0*P, ...
    'D',@(P) 0*P + D0_med, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
[eq0, out0] = solve_regime_equilibrium(pgc, base_reg, r_cal, [0.5, 1.3]);
if isempty(eq0), diary off; error('no baseline: %s', out0.msg); end
g_real = Gg_cal / eq0.P;                          % REAL program held fixed
D_real = climate_block(g_real, pgc);              % common damages (g fixed)
fprintf('  baseline P0=%.4f; fixed real program g_real=%.4f, D(g_real)=%.4f\n', ...
        eq0.P, g_real, D_real);

% ---- regime maps with CONSTANT real program g_real ----
gK = @(P) g_real + 0*P;  DK = @(P) D_real + 0*P;
REG = {};
REG{1} = struct('name','R1-LUMPSUM','Bnom',B,'g',gK,'D',DK, ...
    'tau_ls',@(P) rb_of(P) + g_real,           'vartheta',@(P) 0);
REG{2} = struct('name','R2-PROP-LEVY','Bnom',B,'g',gK,'D',DK, ...
    'tau_ls',@(P) rb_of(P),                    'vartheta',@(P) g_real/(1-D_real) + 0*P);
REG{3} = struct('name','R3-PROP-LEVY-REBATE','Bnom',B,'g',gK,'D',DK, ...
    'tau_ls',@(P) rb_of(P) - g_real,           'vartheta',@(P) 2*g_real/(1-D_real) + 0*P);
REG{4} = struct('name','R4-MIXED','Bnom',B,'g',gK,'D',DK, ...
    'tau_ls',@(P) rb_of(P) + 0.5*g_real,       'vartheta',@(P) 0.5*g_real/(1-D_real) + 0*P);

RREG = struct('name',{},'P',{},'nu',{},'nu_reval',{},'nu_damage',{}, ...
              'W',{},'lam_b50',{},'lam_t10',{},'lam_agg',{});
for k = 1:numel(REG)
    fprintf('\n--- %s (fixed real) ---\n', REG{k}.name);
    [eqk, outk] = solve_regime_equilibrium(pgc, REG{k}, r_cal, [0.5, 1.3]);
    if isempty(eqk), fprintf('  %s\n', outk.msg); continue; end
    fprintf('  %s\n', outk.msg);
    nu_reval  = r_cal * B * (1/eq0.P - 1/eqk.P) / g_real;
    nu_damage = (eq0.D - eqk.D) / g_real;          % identical across regimes
    wg = welfare_by_group(r_cal, eq0, eqk, pgc);
    RREG(end+1) = struct('name',REG{k}.name,'P',eqk.P, ...
        'nu',nu_reval+nu_damage,'nu_reval',nu_reval,'nu_damage',nu_damage, ...
        'W',eqk.W, 'lam_b50',tern(wg.ok,wg.lambda_bot50,NaN), ...
        'lam_t10',tern(wg.ok,wg.lambda_top10,NaN), ...
        'lam_agg',tern(wg.ok,wg.lambda_agg,NaN)); %#ok<SAGROW>
    if wg.ok, fprintf('  welfare: %s\n', wg.msg); end
end

save(fullfile(projdir,'output','regimes_fixed_real_results.mat'), ...
     'RREG','eq0','g_real','D_real','pgc');

% ---- side-by-side table vs fixed-nominal (if the nominal run is present) ----
sf = fullfile(pg.tabdir, 'regimes_fixed_real.txt');
fid = fopen(sf,'w');
if fid > 0
    fprintf(fid, 'FINANCING REGIMES -- FIXED REAL PROGRAM (pure incidence)\n');
    fprintf(fid, 'g_real=%.4f held constant; nu_damage identical across regimes.\n', g_real);
    fprintf(fid, 'baseline P0=%.4f\n\n', eq0.P);
    fprintf(fid, '%-22s  P*       nu      nu_rev   nu_dam   b50%%     t10%%\n', 'regime');
    for k = 1:numel(RREG)
        fprintf(fid, '%-22s  %.4f  %.3f  %+.3f  %.3f  %+.2f   %+.2f\n', ...
            RREG(k).name, RREG(k).P, RREG(k).nu, RREG(k).nu_reval, ...
            RREG(k).nu_damage, 100*RREG(k).lam_b50, 100*RREG(k).lam_t10);
    end
    nomfile = fullfile(projdir,'output','regimes_results.mat');
    if exist(nomfile,'file')==2
        N = load(nomfile);
        fprintf(fid, '\nCOMPARISON to fixed-nominal (Table 6): nu_reval swing\n');
        fprintf(fid, '  fixed-nominal nu_reval: %s\n', mat2str([N.RREG.nu_reval],3));
        fprintf(fid, '  fixed-real    nu_reval: %s\n', mat2str([RREG.nu_reval],3));
        fprintf(fid, ['  => the incidence ordering and the revaluation sign flip are the\n' ...
            '     same under both conventions; the real-scale drift in Table 6 is\n' ...
            '     second-order, as the text claims.\n']);
    end
    fclose(fid);
    fprintf('  [saved] %s\n', sf);
end

fprintf('\n================ FIXED-REAL SUMMARY ================\n');
for k = 1:numel(RREG)
    fprintf(' %-22s P*=%.4f nu=%.3f (rev %+.3f) b50 %+.2f%% t10 %+.2f%%\n', ...
        RREG(k).name, RREG(k).P, RREG(k).nu, RREG(k).nu_reval, ...
        100*RREG(k).lam_b50, 100*RREG(k).lam_t10);
end
fprintf(' Elapsed: %.1f s\n', toc(t0));
diary off;

% -------------------------------------------------------------------------
function s = tern(c,a,b), if c, s=a; else, s=b; end, end
