function [code, D] = kv_node_status(o, P, CTX, toptol)
% KV_NODE_STATUS  Classify a solved stationary block as admissible or not,
% and say WHY when it is not.
%
% A NaN residual is not a large residual -- it is a model failure at that
% price, and the two must never be mixed. A large residual is information
% about where the root is; a NaN is information about where the model stops
% being defined. Sign tests, interpolation and bracketing are valid on the
% first and meaningless on the second, so every evaluation carries a code and
% the callers filter on it rather than on isnan alone.
%
% CODES
%   OK               admissible: everything finite, consumption positive
%   POLICY_NONCONV   the household VFI did not converge
%   DIST_NONCONV     the stationary distribution did not converge
%   NEG_CONSUMPTION  a state carrying mass consumes <= 0
%   POLICY_NONFINITE a policy array contains NaN or Inf
%   BOND_NAN         P, or aggregate liquid demand, is non-finite or <= 0
%   TREE_NAN         aggregate tree demand is non-finite
%   DIST_LOOSE       the distribution settled to 1e-8 but not to 1e-11
%   BOUNDARY_HIT     top-of-grid mass above toptol (admissible but truncated)
%
% BOUNDARY_HIT is deliberately last: it is a WARNING about accuracy, not a
% failure of definition, so a caller may still bracket through it while a
% caller that needs clean derivatives may not.

    if nargin < 4 || isempty(toptol), toptol = 1e-4; end
    D = struct('min_c', NaN, 'ksat', NaN, 'bsat', NaN, 'dV', NaN, 'ddist', NaN);
    code = 'OK';

    if isempty(o) || ~isstruct(o) || ~isfield(o,'ok')
        code = 'POLICY_NONCONV'; return;
    end
    if ~o.ok
        % kv_stationary_block reports which stage failed in its message
        if contains(lower(o.msg), 'distribution'), code = 'DIST_NONCONV';
        else,                                      code = 'POLICY_NONCONV';
        end
        return;
    end
    D.dV = o.dV; D.ddist = o.ddist;

    pol = {o.sol.polBa, o.sol.polKa, o.sol.polCa, o.sol.polBn, o.sol.polCn};
    for i = 1:numel(pol)
        if ~all(isfinite(pol{i}(:))), code = 'POLICY_NONFINITE'; return; end
    end

    % Consumption is checked WHERE THE MASS IS. A negative consumption at an
    % unreachable corner of the grid is a harmless artefact of the grid; a
    % negative consumption at an occupied state is the model breaking down.
    occ = o.dist > 0;
    cn = o.sol.polCn;
    if any(occ(:)), D.min_c = min(cn(occ)); else, D.min_c = min(cn(:)); end
    D.min_c = min(D.min_c, min(o.sol.polCa(:)));
    if ~isfinite(D.min_c) || D.min_c <= 1e-8, code = 'NEG_CONSUMPTION'; return; end

    if ~isfinite(P) || P <= 0 || ~isfinite(o.Sb) || o.Sb <= 0
        code = 'BOND_NAN'; return;
    end
    if ~isfinite(o.Sk), code = 'TREE_NAN'; return; end

    [D.ksat, D.bsat] = kv_boundary_mass(o.dist, CTX.p.kGrid, CTX.p.bGrid);
    if D.ksat > toptol || D.bsat > toptol, code = 'BOUNDARY_HIT'; end
    if isfield(o,'dist_loose') && o.dist_loose && strcmp(code,'OK')
        code = 'DIST_LOOSE';
    end
end
