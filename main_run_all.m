% MAIN_RUN_ALL  Master script for the replication of Hagedorn (2026),
% "A Demand Theory of the Price Level" (IER).
%
% It clears the workspace, sets the random seed, adds paths, runs all model
% sections, saves the figures and a log, and prints a concise replication
% summary. Individual sections can also be run standalone (each creates params
% if needed).
%
% USAGE
%   >> main_run_all            % baseline: na = 500 (accurate, slower)
%   Set FAST = true below (or in the workspace) for na = 100 (quick test).
%
% OUTPUTS
%   output/figures/*.{fig,png,pdf}   figures 1-5
%   output/tables/*.txt              summary tables
%   output/logs/run_log.txt          full console log (diary)
%   output/results.mat               all results struct RES

clear; close all; clc;
rng(20260101, 'twister');            % reproducible seed

t_start = tic;

% ----- paths -----
thisdir = fileparts(mfilename('fullpath'));
if isempty(thisdir), thisdir = pwd; end
cd(thisdir);
addpath(genpath(fullfile(thisdir, 'src')));

% ----- path hygiene: fail fast if stale copies shadow the src/ functions -----
% Older prototypes of this package shipped flat root-level .m files (e.g. a
% 2-argument stationary_distribution.m). If such stale files linger in the
% current folder or elsewhere on the MATLAB path, they SHADOW the src/ versions
% and produce wrong signatures ("Too many input arguments"). Detect and report.
srcdir   = fullfile(thisdir, 'src');
srcfiles = dir(fullfile(srcdir, '*.m'));
shadowed = {};
for k = 1:numel(srcfiles)
    fname    = srcfiles(k).name(1:end-2);
    resolved = which(fname);
    expected = fullfile(srcdir, srcfiles(k).name);
    if ~isempty(resolved) && ~strcmpi(resolved, expected)
        shadowed{end+1} = sprintf('    %-34s resolves to: %s', fname, resolved); %#ok<SAGROW>
    end
end
if ~isempty(shadowed)
    error('main_run_all:shadowed', ...
        ['Stale files shadow this package''s src/ functions:\n%s\n' ...
         'Delete or rename these files (leftovers from an older version of the\n' ...
         'package), or remove their folders from the MATLAB path, then rerun.'], ...
        strjoin(shadowed, '\n'));
end

% ----- params (baseline; optionally fast) -----
if ~exist('FAST','var'), FAST = false; end
params = setup_params();
if FAST
    params.na    = params.na_fast;
    params.aGrid = params.abar*(-1) + (params.amax + params.abar) * ...
                   (linspace(0,1,params.na)'.^params.acurv);
    params.aGrid(1) = -params.abar; params.aGrid(end) = params.amax;
    params.nr = 20; params.nP = 200;
    fprintf('*** FAST mode: na=%d ***\n', params.na);
end

% ----- logging -----
if ~isfolder(params.logdir), mkdir(params.logdir); end
logfile = fullfile(params.logdir, 'run_log.txt');
diary off; if exist(logfile,'file'), delete(logfile); end
diary(logfile); diary on;

fprintf('==========================================================\n');
fprintf(' Replication: Hagedorn (2026) - A Demand Theory of the\n');
fprintf('              Price Level (IER)\n');
fprintf(' Date: run under seed 20260101,  method = %s,  na = %d\n', ...
        params.hh_method, params.na);
fprintf('==========================================================\n');

RES = struct();

% ----- run all sections (scripts share this workspace) -----
main_baseline_DTPL;
main_figures;
main_policy_rules;
main_extensions_money_capital_G;
main_counterexamples;
main_empirical_figure5_optional;

% ----- save results -----
save(fullfile('output','results.mat'), 'RES', 'params');

% ----- concise replication summary -----
ss = RES.baseline.ss;
fprintf('\n================ REPLICATION SUMMARY ================\n');
fprintf(' BASELINE DTPL steady state (incomplete markets):\n');
fprintf('   beta=%.3f  sigma=%.2f  abar=%.2f\n', params.beta, params.sigma, params.abar);
fprintf('   i_ss=%.3f  pi_ss=%.3f  r_ss=%.4f  beta*(1+r)=%.3f\n', ...
        ss.i_ss, ss.pi_ss, ss.r_ss, ss.betaR);
fprintf('   Bnom=%.3f  S(1+r_ss)=%.4f  P*=%.4f  tau_ss=%.4f\n', ...
        ss.Bnom, ss.S_assets, ss.Pstar, ss.tau_ss);
fprintf('   existence conditions satisfied: %d\n', ss.exists);
if isfield(RES,'counter') && isfield(RES.counter,'complete')
    fprintf(' COMPLETE MARKETS: P indeterminate (unique=%d)\n', RES.counter.complete.unique);
end
if isfield(RES,'counter') && isfield(RES.counter,'ftpl')
    fprintf(' DTPL vs FTPL price gap: %.4f\n', RES.counter.ftpl.gap);
end
if isfield(RES,'fig5')
    if RES.fig5.ok
        fprintf(' Figure 5 (empirical): correlation=%.3f\n', RES.fig5.rho);
    else
        fprintf(' Figure 5 (empirical): SKIPPED (no data).\n');
    end
end
fprintf('   Interpretation: with policy pinning r_ss, private asset demand\n');
fprintf('   and asset-market clearing pin the unique price level P*=B/S(1+r).\n');
fprintf(' Elapsed: %.1f s\n', toc(t_start));
fprintf('====================================================\n');

diary off;
fprintf('Log saved to %s\n', logfile);
