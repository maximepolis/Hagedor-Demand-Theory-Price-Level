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

    addpath(dynpath);
    copyfile([basemod '.mod'], [nm '.mod']);
    if exist(['+' nm], 'dir'), rmdir(['+' nm], 's'); end
    if exist(nm, 'dir'), rmdir(nm, 's'); end

    eval(sprintf('dynare %s %s noclearall nolog', nm, defs));

    irfs = [];
    if exist('oo_', 'var') && isfield(oo_, 'irfs') && ~isempty(fieldnames(oo_.irfs))
        irfs = oo_.irfs;                                  %#ok<NODEF>
    elseif exist('oo_', 'var') && isfield(oo_, 'heterogeneity') ...
            && isfield(oo_.heterogeneity, 'irfs')
        irfs = oo_.heterogeneity.irfs;
    end
    if isempty(irfs)
        error('solve_hank_regime_batch:noirfs', ...
              'Regime %s solved but produced no IRFs.', nm);
    end
    param_names  = cellstr(M_.param_names);               %#ok<NODEF>
    param_values = M_.params;
    save(outmat, 'irfs', 'param_names', 'param_values');
    fprintf('[batch child] %s done -> %s\n', nm, outmat);
end
