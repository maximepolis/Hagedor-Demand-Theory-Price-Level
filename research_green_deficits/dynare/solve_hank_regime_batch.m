function solve_hank_regime_batch(basemod, nm, defs, dynpath, outmat)
% SOLVE_HANK_REGIME_BATCH  Run ONE Dynare heterogeneity solve in a FRESH
% MATLAB process (crash isolation for the HANK tiers).
%
% The Dynare 8-unstable heterogeneity framework has hard-crashed MATLAB
% when several heavy solves run in one session. This helper is invoked by
% the drivers via
%     matlab -batch "cd('<dyndir>'); solve_hank_regime_batch(...)"
% so each regime gets a clean process: if Dynare dies, only the child
% dies -- the parent session records the failure and continues.
%
% INPUTS
%   basemod : base .mod name without extension ('green_hank'/'green_hank2')
%   nm      : per-regime copy name (e.g. 'grn2_taylor')
%   defs    : -D define string for the regime
%   dynpath : <dynare>/matlab path of the PARENT session (children inherit
%             no path state; the parent passes fileparts(which('dynare')))
%   outmat  : .mat file to write {irfs, param_names, param_values} to
%
% The child writes outmat ONLY on success; the parent treats a missing
% file (or nonzero exit status) as a failed regime.
%
% ERROR MARKER: on a CATCHABLE failure (e.g. "bad allocation" OOM in the
% steady-state tensor) the message is written to <outmat>.err before the
% error is rethrown, so the parent can distinguish a DETERMINISTIC OOM (back
% the illiquid grid off and retry smaller) from the INTERMITTENT uncatchable
% hard crash (0xc0000409, which leaves NO .err and should be retried on the
% same grid). Live console output is preserved (the solve is not captured),
% so the user still sees the time-iteration progress stream.

    errfile = [outmat '.err'];
    if exist(errfile, 'file'), delete(errfile); end
    try
        addpath(dynpath);
        copyfile([basemod '.mod'], [nm '.mod']);
        if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
        if exist(nm, 'dir'), rmdir(nm, 's'); end

        eval(sprintf('dynare %s %s noclearall nolog', nm, defs));

        % SCOPING FIX: dynare executes its generated driver in the BASE
        % workspace (that is the workspace 'noclearall' protects), so M_ and
        % oo_ do NOT appear in this FUNCTION's workspace after the call. The
        % original harvest checked exist('oo_','var') locally, found nothing,
        % and reported "solved but produced no IRFs" even after a perfectly
        % clean solve -- the drivers' in-session paths never hit this because
        % they are scripts (= base workspace). Fetch explicitly, checking the
        % local workspace first in case a future Dynare changes the contract.
        if ~exist('oo_', 'var')
            try, oo_ = evalin('base', 'oo_'); catch, oo_ = struct(); end
        end
        if ~exist('M_', 'var')
            try, M_ = evalin('base', 'M_'); catch, M_ = struct(); end
        end

        irfs = [];
        if isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
            irfs = oo_.irfs;
        elseif isfield(oo_, 'heterogeneity') && isfield(oo_.heterogeneity, 'irfs') ...
                && ~isempty(fieldnames(oo_.heterogeneity.irfs))
            irfs = oo_.heterogeneity.irfs;
        end
        if isempty(irfs)
            % self-diagnosing failure: show where things actually are, so the
            % parent log carries the true oo_ layout of this Dynare build
            fprintf('[batch child] no IRFs found; oo_ top-level fields are:\n');
            disp(fieldnames(oo_));
            if isfield(oo_, 'heterogeneity')
                fprintf('[batch child] oo_.heterogeneity fields are:\n');
                disp(fieldnames(oo_.heterogeneity));
            end
            error('solve_hank_regime_batch:noirfs', ...
                  ['Regime %s solved but no IRFs found in oo_.irfs or ' ...
                   'oo_.heterogeneity.irfs -- the field dump above shows the ' ...
                   'actual layout of this build.'], nm);
        end
        param_names = {}; param_values = [];
        if isfield(M_, 'param_names')
            param_names  = cellstr(M_.param_names);
            param_values = M_.params;
        end
        save(outmat, 'irfs', 'param_names', 'param_values');
        fprintf('[batch child] %s done -> %s\n', nm, outmat);
    catch ME
        % record the (catchable) error for the parent, then rethrow so the
        % child still exits nonzero
        try
            fid = fopen(errfile, 'w');
            if fid > 0
                fprintf(fid, '%s\n%s\n', ME.identifier, ME.message);
                fclose(fid);
            end
        catch
        end
        rethrow(ME);
    end
end
