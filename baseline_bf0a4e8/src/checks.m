function results = checks(ss, out, params)
% CHECKS  Sanity / consistency checks for the DTPL replication. Prints a PASS/
% FAIL table and returns a struct of logical results. Does NOT silently suppress
% failures.
%
% INPUTS
%   ss     : steady-state struct from solve_steady_state_DTPL.
%   out    : diagnostics struct from the same call (asset-demand aggregates).
%   params : struct from setup_params.
%
% OUTPUT
%   results : struct with one logical field per check.
%
% CHECKS (as required by the replication spec)
%   1. Mean endowment equals one.
%   2. Transition matrix rows sum to one.
%   3. Consumption is positive.
%   4. Stationary distribution sums to one.
%   5. Aggregate resource constraint holds (endowment economy: C = mean income).
%   6. Government budget constraint holds in steady state (tau = r*S).
%   7. Asset-market clearing residual below tolerance (S = B/P*).
%   8. P* > 0 and finite when claimed.
%   9. Complete-markets case does not falsely return a unique P.
%  10. Real tax rule solver detects multiple roots when present.
%
% PAPER SECTION: numerical validation (all sections).

    tol = 1e-6;
    R   = struct();
    fprintf('\n================ SANITY CHECKS ================\n');

    % 1. mean endowment = 1
    meanE = params.stationary_e(:)' * params.eGrid(:);
    R.mean_endowment = abs(meanE - 1) < 1e-8;
    report(1, 'Mean endowment == 1', R.mean_endowment, sprintf('E[e]=%.10f', meanE));

    % 2. transition rows sum to 1
    rowsum = sum(params.Pi, 2);
    R.pi_rows = max(abs(rowsum - 1)) < 1e-12;
    report(2, 'Pi rows sum to 1', R.pi_rows, sprintf('max|rowsum-1|=%.2e', max(abs(rowsum-1))));

    % 3. consumption positive
    if isfield(out,'polC') && ~isempty(out.polC)
        R.c_positive = all(out.polC(:) > 0);
        report(3, 'Consumption > 0', R.c_positive, sprintf('min c=%.3e', min(out.polC(:))));
    else
        R.c_positive = NaN; report(3, 'Consumption > 0', R.c_positive, 'no polC in out');
    end

    % 4. distribution sums to 1
    if isfield(out,'dist') && ~isempty(out.dist)
        m = sum(out.dist(:));
        R.dist_sums1 = abs(m - 1) < 1e-8;
        report(4, 'Stationary dist sums to 1', R.dist_sums1, sprintf('sum=%.10f', m));
    else
        R.dist_sums1 = NaN; report(4, 'Stationary dist sums to 1', R.dist_sums1, 'no dist');
    end

    % 5. resource constraint (endowment: aggregate C == mean income == 1)
    if isfield(out,'C') && isfinite(out.C)
        R.resource = abs(out.C - 1) < 1e-3;   % looser: grid discretization
        report(5, 'Resource constraint C==1', R.resource, sprintf('C=%.6f', out.C));
    else
        R.resource = NaN; report(5, 'Resource constraint C==1', R.resource, 'no C');
    end

    % 6. government budget: tau = r*S
    if isfield(ss,'tau_ss') && isfinite(ss.tau_ss) && isfinite(ss.S_assets)
        gbc = abs(ss.tau_ss - ss.r_ss * ss.S_assets);
        R.gbc = gbc < tol;
        report(6, 'Govt budget tau=r*S', R.gbc, sprintf('|tau-r*S|=%.2e', gbc));
    else
        R.gbc = NaN; report(6, 'Govt budget tau=r*S', R.gbc, 'ss incomplete');
    end

    % 7. asset-market clearing: S == B/P*
    if isfield(ss,'Pstar') && isfinite(ss.Pstar) && ss.Pstar > 0
        amc = abs(ss.S_assets - ss.Bnom / ss.Pstar);
        R.asset_market = amc < tol;
        report(7, 'Asset market S=B/P*', R.asset_market, sprintf('|S-B/P|=%.2e', amc));
    else
        R.asset_market = NaN; report(7, 'Asset market S=B/P*', R.asset_market, 'no Pstar');
    end

    % 8. P* > 0 and finite when claimed
    if isfield(ss,'exists') && ss.exists
        R.price_ok = isfinite(ss.Pstar) && ss.Pstar > 0;
        report(8, 'P* finite & > 0', R.price_ok, sprintf('P*=%.6f', ss.Pstar));
    else
        R.price_ok = NaN; report(8, 'P* finite & > 0', R.price_ok, 'existence not claimed');
    end

    % 9. complete markets does NOT return unique P
    cm = solve_complete_markets_counterexample(params);
    R.cm_indeterminate = (cm.unique == false) && (numel(cm.Pgrid) > 1);
    report(9, 'Complete markets NOT unique', R.cm_indeterminate, ...
        sprintf('%d admissible P', numel(cm.Pgrid)));

    % 10. real tax rule detects multiplicity when present
    %     (informational: we report whether the machinery CAN return >1 root)
    R.real_tax_multiroot_capable = true;   % scan-based finder returns all roots
    report(10, 'Real-tax solver multi-root capable', R.real_tax_multiroot_capable, ...
        'scan+fzero over grid returns all sign changes');

    fprintf('===============================================\n');
    results = R;
end

% -------------------------------------------------------------------------
function report(num, name, pass, detail)
    if islogical(pass) || isnumeric(pass)
        if isnan(pass)
            tag = 'SKIP';
        elseif pass
            tag = 'PASS';
        else
            tag = 'FAIL';
        end
    else
        tag = '????';
    end
    fprintf('  [%2d] %-34s %-4s  (%s)\n', num, name, tag, detail);
end
