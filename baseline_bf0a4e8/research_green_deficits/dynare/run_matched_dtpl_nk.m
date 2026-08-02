% RUN_MATCHED_DTPL_NK  The matched DTPL-versus-NK announcement experiment.
%
% THE DESIGN. The paper's announcement contrast (Section 6.3) is a model-class
% diagnostic because the standard NK-HANK run differs from the nonlinear DTPL
% transition in five confounders. This driver removes every confounder the
% linearized framework can remove, so that only the PRICE-DETERMINATION block
% (Phillips curve + Taylor rule vs asset-market clearing) and the linearization
% differ:
%
%   margin              DTPL transition          matched NK run (this driver)
%   ------------------  -----------------------  -----------------------------
%   spending path       exactly permanent        RHOG = 0.9999 (near-permanent)
%   scale               2% of income             GSTD = 0.02 (2% of output)
%   financing           service rule (balanced)  PHIB = 0.75 ("balanced" speed)
%   household block     endowment, no labor      FRISCH = 0.01 (labor margin shut)
%   accommodation       none                     PSIG = 0 (pure Taylor)
%
% Remaining differences, stated rather than hidden: the NK side is LINEARIZED
% and QUARTERLY with a production/retail layer (whose labor margin is shut but
% whose price rigidity is the point), while the DTPL side is nonlinear and
% annual. The comparison object is the ANNOUNCEMENT-WINDOW INFLATION SIGN.
%
% OUTPUT  output/matched_dtpl_nk.mat, output/tables/matched_dtpl_nk.txt.
%         export_paper_numbers picks up \matchedNKimpact / \matchedDTPLimpact.
%
% USAGE   >> cd research_green_deficits/dynare
%         >> run_matched_dtpl_nk
% Requires the heterogeneity-framework Dynare (as run_green_hank). The DTPL
% side is read from output/transition_results.mat (run main_project_transition
% first); if absent, the NK side still runs and the table says so.

clearvars -except FORCE_RERUN; close all; t0 = tic;
dyndir = fileparts(mfilename('fullpath'));
if isempty(dyndir), dyndir = pwd; end
cd(dyndir);
projdir = fileparts(dyndir);
addpath(genpath(fullfile(fileparts(projdir), 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));
pg = setup_params_green();
if exist('dynare', 'file') ~= 2
    error('Dynare (heterogeneity framework) not on the path.');
end

fprintf('=== MATCHED DTPL-vs-NK announcement experiment ===\n');

% ---- (1) matched NK run: one regime, all confounders pinned ----
defs = '-DPHIPI=1.5 -DPSIG=0.0 -DPHIB=0.75 -DRHOG=0.9999 -DFRISCH=0.01 -DGSTD=0.02';
fprintf('dynare green_hank.mod %s\n', defs);
eval(sprintf('dynare green_hank.mod %s nostrict', defs));

% IRF extraction (same tolerant matching as run_green_hank)
if exist('oo_','var') && isfield(oo_,'irfs') && ~isempty(fieldnames(oo_.irfs))
    irfs = oo_.irfs;
elseif exist('oo_','var') && isfield(oo_,'heterogeneity') && isfield(oo_.heterogeneity,'irfs')
    irfs = oo_.heterogeneity.irfs;
else
    error('matched run solved but no IRFs found in oo_.');
end
fn = fieldnames(irfs);
pick = @(pat) fn(~cellfun(@isempty, regexp(fn, pat, 'once')));
pipf = pick('^pi(_e_g)?$|^pi_'); ggf = pick('^gg'); bf = pick('^b(_e_g)?$|^b_');
assert(~isempty(pipf), 'no inflation IRF field found: %s', strjoin(fn,', '));
pi_path = irfs.(pipf{1})(:).';
pi_impact_q   = pi_path(1);
pi_impact_ann = 4 * pi_impact_q;           % quarterly model, annualized
fprintf('matched NK impact inflation: %+0.4f quarterly (%+0.4f annualized)\n', ...
        pi_impact_q, pi_impact_ann);

% ---- (2) DTPL side: announcement-year inflation from the saved transition ----
dtpl_pi1 = NaN; dtpl_note = 'transition_results.mat NOT FOUND -- run main_project_transition';
trf = fullfile(projdir, 'output', 'transition_results.mat');
if exist(trf, 'file') == 2
    L = load(trf);
    cand = fieldnames(L);
    for k = 1:numel(cand)                   % find a struct with pi_path
        v = L.(cand{k});
        if isstruct(v) && isfield(v, 'pi_path') && isfield(v, 'reportable') && v.reportable
            dtpl_pi1 = v.pi_path(1) - pg.mu; % deviation from trend, annual
            dtpl_note = sprintf('from %s.pi_path(1) (deviation from the %.0f%% trend)', ...
                                cand{k}, 100*pg.mu);
            break;
        end
    end
end
fprintf('DTPL announcement-year inflation deviation: %+0.4f (%s)\n', dtpl_pi1, dtpl_note);

% ---- (3) verdict + outputs ----
save(fullfile(projdir,'output','matched_dtpl_nk.mat'), ...
     'pi_impact_q','pi_impact_ann','dtpl_pi1','defs','pi_path');
if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
fid = fopen(fullfile(pg.tabdir,'matched_dtpl_nk.txt'),'w');
fprintf(fid, 'MATCHED DTPL-vs-NK ANNOUNCEMENT EXPERIMENT\n');
fprintf(fid, 'Matched margins: permanent path (RHOG=0.9999), scale 2%% of output\n');
fprintf(fid, '(GSTD=0.02), balanced financing (PHIB=0.75), labor margin shut\n');
fprintf(fid, '(FRISCH=0.01), pure Taylor (PHIPI=1.5, PSIG=0).\n');
fprintf(fid, 'Remaining differences: linearization; quarterly production economy\n');
fprintf(fid, 'with sticky prices vs nonlinear annual endowment DTPL.\n\n');
fprintf(fid, 'NK   impact inflation (annualized): %+0.4f\n', pi_impact_ann);
fprintf(fid, 'DTPL announcement-year inflation (dev. from trend): %+0.4f  [%s]\n', ...
        dtpl_pi1, dtpl_note);
if isfinite(dtpl_pi1)
    if sign(pi_impact_ann) ~= sign(dtpl_pi1)
        fprintf(fid, ['\nSIGN VERDICT: OPPOSITE -- the announcement-window signs differ\n' ...
            'under the matched design, so the contrast IS attributable to the\n' ...
            'price-determination block (up to linearization and frequency).\n']);
    else
        fprintf(fid, ['\nSIGN VERDICT: SAME -- the signs agree under the matched design,\n' ...
            'so the earlier unmatched contrast was driven by the confounders,\n' ...
            'not by price determination.\n']);
    end
end
fclose(fid);

% ---- (4) 2x2 matched grid: {price determination} x {financing incidence} ----
% The referee's clean test controls the tax-incidence convention as a second
% difference. The row axis (DTPL vs NK) is price determination; the column
% axis (lump-sum vs proportional levy) is financing incidence. Two cells are
% computed above (both under lump-sum). The DTPL-levy cell reads a
% levy-financed announcement transition if one has been produced; the NK-levy
% cell requires a proportional-tax variant of green_hank.mod (the current .mod
% carries a lump-sum tax only) and is left PENDING rather than fabricated.
grid = struct('DTPL_ls', dtpl_pi1, 'NK_ls', pi_impact_ann, ...
              'DTPL_levy', NaN, 'NK_levy', NaN);
dtpl_levy_note = 'PENDING: run a levy-financed transition (transition_levy_results.mat)';
lvf = fullfile(projdir, 'output', 'transition_levy_results.mat');
if exist(lvf, 'file') == 2
    Lv = load(lvf); cand = fieldnames(Lv);
    for k = 1:numel(cand)
        v = Lv.(cand{k});
        if isstruct(v) && isfield(v,'pi_path') && isfield(v,'reportable') && v.reportable
            grid.DTPL_levy = v.pi_path(1) - pg.mu;
            dtpl_levy_note = sprintf('from %s.pi_path(1)', cand{k});
            break;
        end
    end
end
nk_levy_note = 'PENDING: needs a proportional-tax variant of green_hank.mod';
save(fullfile(projdir,'output','matched_dtpl_nk.mat'), ...
     'pi_impact_q','pi_impact_ann','dtpl_pi1','defs','pi_path','grid', '-append');
fid = fopen(fullfile(pg.tabdir,'matched_dtpl_nk_grid.txt'),'w');
fprintf(fid, 'MATCHED 2x2: announcement-window inflation sign\n');
fprintf(fid, 'rows = price determination; columns = financing incidence\n\n');
fmt = @(x) merge_cell(x);
fprintf(fid, '%-8s | %-14s | %-14s\n', '', 'lump-sum', 'prop. levy');
fprintf(fid, '%-8s | %-14s | %-14s\n', 'DTPL', fmt(grid.DTPL_ls), fmt(grid.DTPL_levy));
fprintf(fid, '%-8s | %-14s | %-14s\n', 'NK',   fmt(grid.NK_ls),   fmt(grid.NK_levy));
fprintf(fid, '\nDTPL-levy cell: %s\n', dtpl_levy_note);
fprintf(fid, 'NK-levy cell:   %s\n', nk_levy_note);
fprintf(fid, ['\nReading: the row contrast (holding financing fixed) isolates\n' ...
    'price determination; the column contrast (holding determination fixed)\n' ...
    'isolates financing incidence. The sign restriction the paper reports is\n' ...
    'the DTPL row; the NK row is the Phillips-curve comparison.\n']);
fclose(fid);
fprintf('[saved] matched_dtpl_nk_grid.txt (2x2 scaffold; pending cells flagged)\n');
fprintf('Elapsed %.1f s\n', toc(t0));

function s = merge_cell(x)
    if isnan(x), s = 'pending'; else, s = sprintf('%+0.4f', x); end
end
