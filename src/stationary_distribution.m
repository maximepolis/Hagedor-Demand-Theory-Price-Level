function [dist, distdiag] = stationary_distribution(polA_idx, Pi, params)
% STATIONARY_DISTRIBUTION  Invariant distribution over joint states (a,e).
%
% Public entry point with the signature required by the replication spec:
%   [dist, distdiag] = stationary_distribution(polA_idx, Pi, params)
%
% This is a thin wrapper around compute_stationary_distribution.m, which holds
% the actual implementation under a unique name. Rationale: older prototypes of
% this package shipped a ROOT-LEVEL stationary_distribution.m with a different
% 2-argument signature. If such a stale file lingers in the current folder or on
% the MATLAB path, it shadows this one and every internal solver call breaks
% with "Too many input arguments". Internal solvers therefore call the uniquely
% named implementation directly, and this wrapper exists only to preserve the
% documented public API. main_run_all additionally runs a path-hygiene check
% that detects and reports any such shadowing.
%
% See compute_stationary_distribution.m for inputs, outputs, method, and the
% relevant paper section (Section 2.1, stationary equilibrium Omega).

    [dist, distdiag] = compute_stationary_distribution(polA_idx, Pi, params);
end
