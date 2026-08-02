% MAIN_SHAKEOUT_TRACKA_FAST  Implementation shakeout for Track A.
%
% PURPOSE: to find out whether the certification machinery RUNS, on a grid
% matrix small enough to fail fast. It is NOT a certification and its numbers
% are not evidence about the economy. The FAST matrix is a debug artefact:
% nothing measured on it may be quoted, and Gate 11 measured on it does not
% certify anything.
%
% WHAT IT EXERCISES
%   kv_gate_report                per-equilibrium gates and their thresholds
%   kv_solve_alpha                continuation and dispersed cold starts
%   the root-continuity bookkeeping (distinct roots, branch identity, sign
%   agreement across branches)
%   the across-matrix Gate-11 arithmetic
%
% WHAT IT DOES NOT DO
%   certify anything; run Track B; touch the manuscript.
%
% USAGE   >> clear; main_shakeout_trackA_fast
%
% Equivalent to:
%   clear; TRACK = 'A'; FAST = true; main_twoasset_grid_certification
% and this file exists so the shakeout cannot be mistaken for the real run in
% a log or a shell history.

clear; TRACK = 'A'; FAST = true;   %#ok<NASGU>
fprintf(['\n*** SHAKEOUT ONLY. FAST grid matrix. Nothing measured here is\n' ...
         '*** evidence about the economy, and Gate 11 on this matrix does not\n' ...
         '*** certify anything.\n\n']);
main_twoasset_grid_certification
