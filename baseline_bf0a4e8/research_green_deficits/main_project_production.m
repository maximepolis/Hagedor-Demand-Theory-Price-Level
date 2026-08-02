% MAIN_PROJECT_PRODUCTION  Stage-1 production/tax-base robustness at the
% calibrated MEDIUM column: how much self-financing does the endowment
% economy leave on the table by having no output margin?
%
% The endowment economy cannot distinguish "avoided damages raise
% endowments" from "avoided damages raise the tax base": there is no
% produced output and no revenue instrument on it. This driver runs the
% Stage-1 aggregate production layer (src_project/production_block_green)
%
%     Y = (1 - D(Kg)) * A(Kg) * N,   A = 1 + aY (1 - e^{-thA Kg}),  N = 1,
%
% on the SAME calibrated program (beta*, Gg_cal, medium damages) and reports
% the ADDITIVE piece the endowment economy omits: the productivity margin
% dY_product = (1-D0)(A-1), whose fiscal take at an average effective tax
% rate trb is
%
%     nu_taxbase = trb * dY_product / g_g1 .
%
% The damage component of the output gain is NOT added: the endowment
% economy's damage dividend nu_dam already counts it (with production and an
% output tax, a share trb of that dividend is collected by the fisc instead
% of accruing to households -- a recomposition of nu_dam, not an addition).
% The augmented share reported is
%
%     nu_plus = nu_endowment + nu_taxbase ,
%
% a LOWER BOUND on the production-economy share in the empirically relevant
% region (labor fixed at N=1; no behavioral base response, no boom).
%
% Discipline: aY is swept and the implied output elasticity of green public
% capital eta_Y = dlnY/dlnKg is reported next to the Bom-Ligthart (2014)
% meta-range for core public capital (0.08-0.12), so the reader can pick the
% row they believe; trb in {0.25, 0.34} (0.34 = OECD average tax/GDP).
%
% REQUIREMENTS: output/calibrated_results.mat (run main_project_calibrated
% first). Runtime: < 1 s (no household solves -- the aggregate layer only).
%
% OUTPUT: output/tables/production_summary.txt, output/production_results.mat
%
% USAGE:  >> cd research_green_deficits; main_project_production

clear; clc; t0 = tic;
projdir = fileparts(mfilename('fullpath'));
rootdir = fileparts(projdir);
addpath(fullfile(rootdir, 'src'));
addpath(fullfile(projdir, 'src_project'));

calfile = fullfile(projdir, 'output', 'calibrated_results.mat');
if exist(calfile, 'file') ~= 2
    error('main_project_production:nocal', ...
        'output/calibrated_results.mat not found -- run main_project_calibrated first.');
end
L   = load(calfile, 'RCAL', 'pgc');
dec = L.RCAL.dec{2};                      % MEDIUM (DJO-BHM) column
if isempty(dec) || ~dec.ok
    error('main_project_production:badcol', 'medium-column decomposition not available.');
end
pgm         = L.pgc;
pgm.D0      = 0.06;
g1          = dec.prog.g_real;            % real program spending, program SS
nu_endow    = dec.nu;
nu_reval    = dec.nu_reval;
nu_dam      = dec.nu_damage;

fprintf('==============================================================\n');
fprintf(' PRODUCTION STAGE 1 (tax-base margin), calibrated MEDIUM column\n');
fprintf(' beta*=%.4f  g_g1=%.5f  nu_endow=%.3f (reval %+.3f, dam %.3f)\n', ...
        L.RCAL.beta_star, g1, nu_endow, nu_reval, nu_dam);
fprintf('==============================================================\n\n');

aY_grid  = [0, 0.10, 0.20, 0.30];
trb_grid = [0.25, 0.34];

RP = struct('aY_grid', aY_grid, 'trb_grid', trb_grid, 'g1', g1, ...
            'nu_endow', nu_endow, 'rows', []);
rows = struct('aY',{},'eta_Y',{},'dY_damage',{},'dY_product',{}, ...
              'dY_interact',{},'nu_tb',{},'nu_plus',{});
for a = 1:numel(aY_grid)
    pgm.aY = aY_grid(a);
    PB = production_block_green(g1, pgm);
    nu_tb   = trb_grid .* PB.dY_product ./ g1;   % additive piece only
    nu_plus = nu_endow + nu_tb;
    rows(a) = struct('aY', aY_grid(a), 'eta_Y', PB.eta_Y, ...
        'dY_damage', PB.dY_damage, 'dY_product', PB.dY_product, ...
        'dY_interact', PB.dY_interact, 'nu_tb', nu_tb, 'nu_plus', nu_plus);
    fprintf(['aY=%.2f: eta_Y=%.3f  dY_dam=%.4f  dY_prod=%.4f  ' ...
             'nu_tb(25%%)=%.3f nu_tb(34%%)=%.3f  nu+=%.3f/%.3f\n'], ...
        aY_grid(a), PB.eta_Y, PB.dY_damage, PB.dY_product, ...
        nu_tb(1), nu_tb(2), nu_plus(1), nu_plus(2));
end
RP.rows = rows;

save(fullfile(projdir, 'output', 'production_results.mat'), 'RP');

sf  = fullfile(projdir, 'output', 'tables', 'production_summary.txt');
fid = fopen(sf, 'w');
if fid > 0
    fprintf(fid, 'PRODUCTION STAGE 1 -- TAX-BASE MARGIN (calibrated MEDIUM column)\n');
    fprintf(fid, ['Y=(1-D(Kg))*A(Kg), A=1+aY(1-exp(-thA*Kg)), N=1 fixed. ' ...
                  'Additive piece only:\n' ...
                  'nu_taxbase = trb*dY_product/g_g1 (damage component already ' ...
                  'in nu_dam; recomposed, not added).\n']);
    fprintf(fid, 'Endowment benchmark: nu=%.3f (reval %+.3f, dam %.3f), g_g1=%.5f\n\n', ...
            nu_endow, nu_reval, nu_dam, g1);
    fprintf(fid, '%-6s %-7s %-9s %-9s %-9s | %-12s %-12s\n', ...
        'aY', 'eta_Y', 'dY_dam', 'dY_prod', 'interact', ...
        'nu+ (trb=.25)', 'nu+ (trb=.34)');
    for a = 1:numel(rows)
        fprintf(fid, '%-6.2f %-7.3f %-9.4f %-9.4f %-9.4f | %-12.3f %-12.3f\n', ...
            rows(a).aY, rows(a).eta_Y, rows(a).dY_damage, rows(a).dY_product, ...
            rows(a).dY_interact, rows(a).nu_plus(1), rows(a).nu_plus(2));
    end
    fprintf(fid, ['\nDiscipline: eta_Y = dlnY/dlnKg at the program Kg; ' ...
        'Bom-Ligthart (2014) meta-range for core public capital: 0.08-0.12.\n' ...
        'trb = average effective tax take on output (0.34 = OECD tax/GDP).\n' ...
        'HONEST SCOPE: N fixed (no behavioral base response, no boom); the\n' ...
        'household problem is unchanged (aggregate layer only), so nu_plus is\n' ...
        'a lower bound on the production-economy share, not a GE result.\n']);
    fclose(fid);
    fprintf('\n  [saved] %s\n', sf);
end
fprintf('Elapsed: %.2f s\n', toc(t0));
