% MAIN_BASELINE_DTPL  Baseline Demand-Theory-of-the-Price-Level steady state.
% Solves the incomplete-markets Huggett economy, computes the steady-state
% asset demand S(1+r^ss), the unique price level P* = B/S(1+r^ss), runs the
% sanity checks, and prints/saves the baseline summary.
%
% Runs standalone (creates params) or as part of main_run_all (uses existing
% params / RES). Paper: Section 2 (baseline determinacy result).

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## BASELINE DTPL ##########\n');
fprintf('Solving household block (method=%s), asset demand and steady state...\n', ...
        params.hh_method);

[ss, out] = solve_steady_state_DTPL(params, params.i_ss, params.pi_ss, params.Bnom);

% ---- sanity checks ----
chk = checks(ss, out, params);

% ---- console summary ----
fprintf('\n---------------- BASELINE SUMMARY ----------------\n');
fprintf('  beta            = %.4f\n', params.beta);
fprintf('  sigma           = %.4f\n', params.sigma);
fprintf('  abar (borrow)   = %.4f\n', params.abar);
fprintf('  i_ss (nominal)  = %.4f\n', ss.i_ss);
fprintf('  pi_ss (infl)    = %.4f\n', ss.pi_ss);
fprintf('  r_ss (real)     = %.4f\n', ss.r_ss);
fprintf('  1/beta - 1      = %.4f  (asymptote; need r_ss below this)\n', 1/params.beta-1);
fprintf('  beta*(1+r_ss)   = %.4f  (must be < 1)\n', ss.betaR);
fprintf('  Bnom            = %.4f\n', ss.Bnom);
fprintf('  S(1+r_ss)       = %.6f\n', ss.S_assets);
fprintf('  P*              = %.6f\n', ss.Pstar);
fprintf('  tau_ss (real)   = %.6f\n', ss.tau_ss);
if isfield(out,'C'),      fprintf('  aggregate C     = %.6f\n', out.C); end
if isfield(out,'hhdiag'), fprintf('  Euler err log10 = %.2f (max)\n', out.hhdiag.euler_max_log10); end
fprintf('  existence       = %d  (%s)\n', ss.exists, out.msg);
fprintf('--------------------------------------------------\n');

% ---- save a table ----
if ~isfolder(params.tabdir), mkdir(params.tabdir); end
tf = fullfile(params.tabdir, 'baseline_summary.txt');
fid = fopen(tf, 'w');
if fid > 0
    fprintf(fid, 'Hagedorn (2026) DTPL - baseline steady state\n');
    fprintf(fid, 'beta=%.4f sigma=%.4f abar=%.4f\n', params.beta, params.sigma, params.abar);
    fprintf(fid, 'i_ss=%.4f pi_ss=%.4f r_ss=%.4f betaR=%.4f\n', ...
            ss.i_ss, ss.pi_ss, ss.r_ss, ss.betaR);
    fprintf(fid, 'Bnom=%.4f S=%.6f Pstar=%.6f tau_ss=%.6f\n', ...
            ss.Bnom, ss.S_assets, ss.Pstar, ss.tau_ss);
    fprintf(fid, 'exists=%d : %s\n', ss.exists, out.msg);
    fclose(fid);
    fprintf('  [saved] %s\n', tf);
end

RES.baseline.ss  = ss;
RES.baseline.out = out;
RES.baseline.chk = chk;
