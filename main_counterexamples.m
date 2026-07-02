% MAIN_COUNTEREXAMPLES  Cases where the price level is INDETERMINATE, and the
% DTPL-vs-FTPL contrast:
%   * Complete markets / representative agent: r = 1/beta pins nothing about P.
%   * Hand-to-mouth + PIH: PIH Euler pins r; asset demand perfectly elastic.
%   * FTPL comparison: DTPL (passive fiscal, asset-market clearing) is NOT FTPL
%     (active fiscal, present-value condition); prices generically differ.
% Paper: complete-markets counterexample, TANK counterexample, FTPL discussion.

if ~exist('params','var') || isempty(params)
    addpath(genpath('src'));
    params = setup_params();
end
if ~exist('RES','var'), RES = struct(); end

fprintf('\n########## COUNTEREXAMPLES & FTPL CONTRAST ##########\n');

% complete markets
cm = solve_complete_markets_counterexample(params);
RES.counter.complete = cm;

% hand-to-mouth + PIH
htm = solve_hand_to_mouth_counterexample(params);
RES.counter.htm = htm;

% FTPL comparison (needs a DTPL steady state)
if ~isfield(RES,'baseline')
    [ss, ~] = solve_steady_state_DTPL(params, params.i_ss, params.pi_ss, params.Bnom);
else
    ss = RES.baseline.ss;
end
ftpl = ftpl_comparison(params, ss);
RES.counter.ftpl = ftpl;

fprintf('\nSummary: incomplete markets => unique P*; complete markets & TANK => P indeterminate.\n');
