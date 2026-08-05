function out = kv_welfare_channels(base, prog, opts)
% KV_WELFARE_CHANNELS  Channel-by-group welfare decomposition (referee R13,
% Major Comment 1 / Experiment 4).
%
% For each financing regime and each household group i, this function reports
%
%   dW_i = dW_i^tax + dW_i^rebate + dW_i^direct_reval + dW_i^indirect_reval
%          + dW_i^damage + dW_i^GE_income + dW_i^portfolio + dW_i^interaction
%
% where the LAST term is not a channel but the INTERACTION RESIDUAL,
%
%   dW_i^interaction := dW_i^total - sum_over_channels dW_i^channel,
%
% reported on its own line, in the same units, with its own sign. The
% referee's caveat is the binding design constraint here: "The decomposition
% need not be algebraically additive if interactions exist; interactions
% should be reported rather than hidden." A decomposition that forces
% additivity by rescaling channels, or by folding the residual into whichever
% channel is least inspected, is worse than one that shows the residual --
% because the reader cannot tell the difference between a clean decomposition
% and a dirty one that has been tidied. So nothing here is rescaled. The
% residual is computed, named, printed on every row, and (see RECONSTRUCTION
% below) is the only thing standing between the channel sum and the total.
%
% PROVENANCE OF THE REFEREE TEXT (project rule 3). There is no R13 report file
% in this repository: `find . -iname "*r13*"` returns only CLAIM_STATUS_R13.md
% and PAPER_ARCHITECTURE_R13.md, neither of which is the report, and the
% sentence "The decomposition need not be algebraically additive if
% interactions exist; interactions should be reported rather than hidden" does
% NOT APPEAR anywhere in the tree. It is recorded here as transcribed from the
% task brief, NOT as a quotation verified against a source, and nothing here
% may be cited as "the referee wrote". This is the same warning already
% carried by main_sign_map.m:8-16 and by CLAIM_STATUS_R13.md, which were
% commissioned the same way. (The "R13" in referee_memo/REFEREE_MEMO.md:125 is
% a differently numbered internal point about the high-damage column and is
% unrelated.) The nearest demand that IS in the repository is the interaction
% term of decompose_safe_asset_channel.m:22-24 -- "with each bracket = ln P_cf
% - ln P0 and the interaction reported as the residual -- an exact accounting,
% no approximation hidden" -- which this file implements in welfare units.
%
% ---------------------------------------------------------------------------
% THE TWO-ASSET APPLICATION IS BLOCKED.
% ---------------------------------------------------------------------------
% This file is machinery only. It is written so that BOTH the one-asset and
% the two-asset (Kaplan-Violante infrequent-adjustment) transitions can call
% it, and it is deliberately shipped WITHOUT a driver that runs it on the
% two-asset economy. The two-asset block has not cleared Gate 11 (grid-induced
% uncertainty in the financing response, normalised by that response, below
% 0.10) -- the same stamp carried by main_identification_ledger.m:38-44.
% CLAIM_STATUS_R13.md line 57 (register item 15) puts two-asset welfare
% incidence at status WP, withdrawn pending validation, and names TWO
% conditions for lifting it, "Gate 11, and a two-asset transition with damages
% moving", recording that "Neither is available now". A channel decomposition
% inherits both conditions: it is a finer cut of exactly that object.
%
% Until they are met, no number produced by this function on two-asset inputs
% may be quoted, tabulated, or described as established. Running it on
% two-asset inputs for internal diagnosis is fine; publishing the output is
% not. The one-asset application is not blocked by this stamp, but this file
% ships no driver for it either: the caller supplies the counterfactual nodes.
%
% ---------------------------------------------------------------------------
% WHAT A "CHANNEL" IS HERE
% ---------------------------------------------------------------------------
% Exactly the convention of decompose_safe_asset_channel.m (lines 89-96 of
% that file): each channel is a COUNTERFACTUAL NODE -- a separately solved
% object in which only that one margin is switched from its baseline to its
% program value -- and the channel's contribution is the node minus the
% baseline. The residual is whatever the nodes fail to span. The difference
% from that file is only the metric and the resolution: there, log price
% levels in aggregate; here, consumption-equivalent welfare, state by state,
% aggregated to groups.
%
% This function does NOT solve the nodes. It cannot: what "tax only" or
% "direct revaluation only" means is a modelling decision that belongs to the
% economy being decomposed, not to an accounting routine, and a routine that
% guessed would silently produce a different decomposition for each caller.
% The caller passes the solved node value functions in. This function owns the
% CE transform, the group construction, the aggregation weights, and the
% residual -- the four places where a decomposition usually goes wrong
% quietly.
%
% ---------------------------------------------------------------------------
% CONSUMPTION-EQUIVALENT UNITS (matched to the existing welfare files)
% ---------------------------------------------------------------------------
% Every dW is a permanent consumption-equivalent transfer lambda, a fraction
% of consumption (so 0.01 = 1%), exactly the object of welfare_by_group.m,
% welfare_by_decile.m and welfare_groups_extended.m. Two transforms are
% supported, selected automatically:
%
%   'shift'      (one-asset; welfare_by_group.m:52-66, welfare_by_decile.m:47-59)
%                  sigma == 1 : lam = exp((V1 - V0)*(1 - beta)) - 1
%                  sigma ~= 1 : Vt = V + 1/((1-sigma)(1-beta)),
%                               lam = (Vt1./Vt0)^(1/(1-sigma)) - 1
%                with the sigma > 1 validity guard (tilde-V must be negative)
%                copied from those files, including its refusal to return.
%
%   'components' (two-asset separable u(c) + chi*v(b); main_twoasset_welfare.m
%                ce_lambda, lines 248-257)
%                  sigma == 1 : lam = exp((V1 - V0)*(1 - beta)) - 1
%                  sigma ~= 1 : lam = ((V1 - Ub0)./Uc0)^(1/(1-sigma)) - 1
%                selected iff base.Uc and base.Ub are supplied.
%
% EXACTNESS GUARD. Wherever a node value equals the baseline value at a state,
% lambda is set to exactly 0 rather than passed through the transform. That is
% an identity, not an approximation: a household whose value is unchanged
% requires a zero transfer. It exists so that a structurally inactive channel
% reports a clean 0 instead of 1e-17, and so that the zero-program self-test
% below can assert bitwise zero rather than a tolerance.
%
% ---------------------------------------------------------------------------
% GROUPS
% ---------------------------------------------------------------------------
% All cuts are on the BASELINE distribution, as in every welfare file in this
% project. Three kinds:
%
%   quantile   : liquid_wealth, total_wealth, income, bond_direct,
%                bond_indirect. Ranked continuously with FRACTIONAL MASS-POINT
%                SPLITTING, generalising welfare_by_decile.m:61-81 from the
%                asset grid to an arbitrary ranking variable. States sharing a
%                ranking value form one tie block (in the one-asset case with
%                x = a this block is exactly one asset-grid point, so the
%                generalisation reproduces welfare_by_decile exactly); a block
%                straddling a quantile boundary has its mass apportioned to
%                both sides in proportion to the overlap, and within the block
%                the split is proportional to baseline mass. Every quantile
%                therefore holds exactly its share of baseline mass even when
%                a large mass sits at the borrowing limit.
%   binary     : constrained vs unconstrained (mask supplied by the caller,
%                because "at the limit" is index 1 of the asset grid in the
%                one-asset economy and index 1 of the LIQUID grid in the
%                two-asset one -- welfare_groups_extended.m:90).
%   fractional : adjuster vs non-adjuster. In the KV household adjustment is
%                stochastic with probability lambda_adj, so no state is an
%                adjuster: every state is a lambda/(1-lambda) MIXTURE, exactly
%                as kv_agg.m:25-26 mixes the policies. Membership weights are
%                therefore fractional. In the one-asset economy there is no
%                adjustment margin at all, and the grouping is reported
%                INACTIVE rather than as a degenerate single group.
%
% Tail cuts (top10 / top5 / top1 / bot50) are reported alongside each quantile
% grouping and are flagged as NON-partition columns, so no check ever treats
% them as if they summed to the aggregate.
%
% ONE SET OF WEIGHTS. For a given group, the identical state-level weight
% vector aggregates the total AND every channel. This matters: if the total
% and the channels were aggregated under even slightly different weights, part
% of the reported "interaction" would be a weighting artefact, and the reader
% would have no way to see it. Here the residual can only be a channel
% additivity failure.
%
% ---------------------------------------------------------------------------
% RECONSTRUCTION, AND EXACTLY WHERE FLOATING POINT LIMITS IT
% ---------------------------------------------------------------------------
% .residual is total - sum(channels), computed once, in the same left-to-right
% order in which the printed table adds up. It is NOT adjusted, smoothed,
% compensated or rounded afterwards. An earlier draft carried an iterative
% floating-point compensation loop to force the reported numbers to add up
% bit-exactly; it was removed, because machinery that cannot make a wrong
% decomposition right but CAN move a reported number is worse than no
% machinery.
%
% .recon_err = total - (sum(channels) + residual) is reported alongside, and
% .additive_ok is recon_err == 0. What can be said about it without running
% anything:
%   * By Sterbenz's lemma, total - sum(channels) is exactly representable
%     whenever the channel sum lies within a factor of two of the total --
%     i.e. whenever the decomposition is doing its job at all -- so recon_err
%     is exactly zero in that regime. This is a theorem about binary floating
%     point, not a measurement.
%   * Outside that regime (a channel sum orders of magnitude larger than the
%     total) no single double can close the gap. The shortfall is then
%     REPORTED -- recon_err nonzero, additive_ok false, and a warning line in
%     the table -- never absorbed into a channel.
%
% NO NUMERICAL CLAIM IS MADE HERE THAT THIS REPOSITORY CANNOT CHECK. An
% earlier version of this header quoted draw counts and hit rates from a
% double-precision mirror of this arithmetic written in another language
% because no MATLAB interpreter was available. Those figures are removed: the
% mirror is not in the repository, so nothing here could reproduce them, and
% an unreproducible number in a header is the same defect as an
% unreproducible number in a table. What IS shipped is the self-test below.
%
% THE MATLAB SELF-TEST HAS NOT BEEN EXECUTED. Run
%   >> kv_welfare_channels('selftest')
% once before this function is relied on, and treat a failure as a defect in
% this file rather than in the caller.
%
% ---------------------------------------------------------------------------
% USAGE
% ---------------------------------------------------------------------------
%   out = kv_welfare_channels(base, prog)
%   out = kv_welfare_channels(base, prog, opts)
%   rep = kv_welfare_channels('selftest')        % see SELF-TEST below
%
% INPUT  base : baseline (no-program) solved object.
%   .V        numeric array, baseline value on the household state grid. Any
%             shape: (na x ne) one-asset, (nb x nk x ne) two-asset.
%   .dist     baseline invariant distribution, same size as .V. Normalised
%             internally; must be nonnegative with positive sum.
%   .sigma    CRRA curvature   (or supply base.p.sigma)
%   .beta     discount factor  (or supply base.p.beta)
%   .Uc,.Ub   OPTIONAL separable value components, same size as .V. Supplying
%             both selects the 'components' CE transform.
%   .groups   struct of ranking variables / masks, each same size as .V:
%               .liquid_wealth  .total_wealth  .income
%               .bond_direct    .bond_indirect     (numeric rankings)
%               .constrained                       (logical mask)
%               .adjust_prob                       (numeric in [0,1], or
%                                                   logical for a hard split)
%             Any field omitted or empty makes that grouping INACTIVE, with a
%             stated reason. Nothing is imputed.
%
% INPUT  prog : 1 x R struct array, one element per FINANCING REGIME.
%   .name     char label for the regime.
%   .V        program value, same size as base.V.
%   .nodes    struct with one field per channel, each a value array the size
%             of base.V, being the value in the counterfactual economy where
%             only that margin is switched on. Field names must be drawn from
%               tax, rebate, direct_reval, indirect_reval, damage,
%               GE_income, portfolio
%   .inactive OPTIONAL cellstr of channel names that are STRUCTURALLY zero in
%             this regime (e.g. no rebate under lump-sum finance). These are
%             set to exactly 0 and DO enter the residual. A channel that is
%             neither supplied nor declared inactive is reported as NaN, is
%             listed in .channel_missing, and poisons the residual to NaN --
%             deliberately, so a missing node can never be mistaken for a zero
%             one.
%
% INPUT  opts (all optional)
%   .quantiles  edges in [0,1] for the quantile groupings. Default 0:0.1:1
%               (deciles, matching welfare_by_decile).
%   .tails      n x 3 cell {label, lo, hi}. Default top10/top5/top1/bot50.
%   .ce         'auto' (default) | 'shift' | 'components'.
%   .tie_tol    ranking values within this absolute distance are one tie
%               block. Default 0 (exact equality, as on a shared grid point).
%   .verbose    print the table (default false). The table is always returned
%               in out.table whether or not it is printed.
%
% OUTPUT out
%   .ok .msg .ce .channels .quantile_edges
%   .regime(r).name .channel_missing .channel_inactive
%   .regime(r).aggregate                 -- whole population, one group
%   .regime(r).grouping.<name>           -- per grouping:
%        .kind .active .reason .labels .is_partition .mass
%        .rank_mean   group mean of the ranking variable for quantile
%                     groupings; NaN for binary and fractional ones, which
%                     have no ranking variable to average.
%        .total       1 x G  dW_i (CE units)
%        .channel     nCH x G, rows in out.channels order
%        .ch.<name>   1 x G  same numbers, named
%        .residual    1 x G  INTERACTION RESIDUAL, total - sum(channels),
%                            unadjusted
%        .chan_sum    1 x G  sum(channels) in the table's own order
%        .recon_err   1 x G  total - (chan_sum + residual); 0 in every regime
%                            where a double can represent it (see above)
%        .additive_ok 1 x G  logical, recon_err == 0
%   .table   formatted char report
%
% ---------------------------------------------------------------------------
% SELF-TEST
% ---------------------------------------------------------------------------
%   kv_welfare_channels('selftest')  runs, on synthetic inputs only:
%     (a) RECONSTRUCTION. Deterministic pseudo-random values with a program
%         value chosen so the channels do NOT span it (a materially nonzero
%         interaction): channels + residual must reproduce the total exactly,
%         bitwise, in every group of every grouping, under both CE transforms
%         and on both a 2-D (one-asset shaped) and a 3-D (two-asset shaped)
%         state space. The test asserts the residual is materially nonzero
%         FIRST, so it cannot pass by decomposing a trivially additive case,
%         and it also asserts the one-rounding-unit bound on recon_err.
%     (b) ZERO PROGRAM. Program value and every node equal to the baseline:
%         every channel, the residual, and the total must be identically zero
%         (bitwise, not to tolerance) in every group.
%   plus: quantile masses equal their exact shares; the mass-weighted average
%   of partition-group totals equals the aggregate; a declared-inactive
%   channel is exactly 0 and still adds up; an undeclared missing node
%   poisons its channel AND the residual to NaN rather than passing as zero;
%   and an HONESTY PROBE in the regime where bit-exactness is arithmetically
%   unattainable, checking that the shortfall is reported and bounded rather
%   than faked. No solved economy is touched; the self-test needs no .mat, no
%   solver and no calibration.
%
% STATUS: machinery IMPLEMENTED; self-test WRITTEN BUT NOT YET EXECUTED IN
% MATLAB (see "where those numbers come from" above) -- run it first. The
% two-asset application is BLOCKED on Gate 11 certification. Numbers are
% results only once a certified economy is run through it.

    CH = {'tax','rebate','direct_reval','indirect_reval','damage', ...
          'GE_income','portfolio'};

    if nargin >= 1 && (ischar(base) || (isstring(base) && isscalar(base)))
        tag = lower(char(base));
        if any(strcmp(tag, {'selftest','--selftest','test','--test'}))
            vb = true;
            if nargin >= 2 && ~isempty(prog), vb = logical(prog); end
            out = kvwc_selftest(vb, CH);
            return;
        end
        error('kv_welfare_channels:badcall', ...
              'Unknown string argument "%s" (did you mean ''selftest''?).', tag);
    end

    if nargin < 3 || isempty(opts), opts = struct(); end
    opts = kvwc_defaults(opts);

    out = struct('ok', false, 'msg', '', 'channels', {CH}, ...
                 'ce', '', 'quantile_edges', opts.quantiles, ...
                 'regime', [], 'table', '');

    % ---------------------------------------------------------------- inputs
    [okb, why] = kvwc_check_base(base);
    if ~okb
        out.msg = ['kv_welfare_channels: ' why];
        warning('kv_welfare_channels:base', '%s', out.msg);
        return;
    end
    sz  = size(base.V);
    n   = numel(base.V);
    nCH = numel(CH);
    V0  = base.V(:);
    w   = base.dist(:);
    w   = w / sum(w);
    sigma = kvwc_param(base, 'sigma');
    beta  = kvwc_param(base, 'beta');

    ce = opts.ce;
    if strcmp(ce, 'auto')
        if isfield(base, 'Uc') && isfield(base, 'Ub') && ...
                ~isempty(base.Uc) && ~isempty(base.Ub)
            ce = 'components';
        else
            ce = 'shift';
        end
    end
    out.ce = ce;

    cec = struct('kind', ce, 'sigma', sigma, 'beta', beta, 'V0', V0);
    if strcmp(ce, 'components')
        if ~isfield(base, 'Uc') || ~isfield(base, 'Ub') || ...
                ~isequal(size(base.Uc), sz) || ~isequal(size(base.Ub), sz)
            out.msg = ['kv_welfare_channels: ce = ''components'' needs ' ...
                       'base.Uc and base.Ub sized like base.V.'];
            warning('kv_welfare_channels:components', '%s', out.msg);
            return;
        end
        cec.Uc0 = base.Uc(:);
        cec.Ub0 = base.Ub(:);
    else
        if abs(sigma - 1) >= 1e-12
            cshift = 1 / ((1 - sigma) * (1 - beta));
            Vt0 = V0 + cshift;
            if sigma > 1 && max(Vt0) >= 0
                out.msg = ['kv_welfare_channels: CE transform invalid ' ...
                           '(sigma > 1 and baseline tilde-V >= 0) -- check ' ...
                           'beta/sigma fields.'];
                warning('kv_welfare_channels:transform', '%s', out.msg);
                return;
            end
            cec.cshift = cshift;
            cec.Vt0 = Vt0;
        end
    end

    if nargin < 2 || ~isstruct(prog) || isempty(prog)
        out.msg = ['kv_welfare_channels: prog must be a nonempty struct ' ...
                   'array, one element per financing regime.'];
        warning('kv_welfare_channels:prog', '%s', out.msg);
        return;
    end

    % ------------------------------------------------------------- groupings
    [GRP, gorder] = kvwc_build_groups(base, w, sz, opts);

    % --------------------------------------------------------------- regimes
    nR = numel(prog);
    R  = repmat(kvwc_empty_regime(CH, GRP, gorder), 1, nR);
    for r = 1:nR
        pr = prog(r);
        if isfield(pr, 'name') && ~isempty(pr.name)
            R(r).name = char(pr.name);
        else
            R(r).name = sprintf('regime%d', r);
        end
        if ~isfield(pr, 'V') || ~isequal(size(pr.V), sz)
            out.msg = sprintf(['kv_welfare_channels: regime %s has no .V ' ...
                'sized like base.V.'], R(r).name);
            warning('kv_welfare_channels:progV', '%s', out.msg);
            return;
        end

        % lambda maps: column 1 = total, columns 2..nCH+1 = channels
        Lam = nan(n, nCH + 1);
        [Lam(:,1), lmsg] = kvwc_ce(pr.V(:), cec);
        if ~isempty(lmsg)
            out.msg = sprintf('kv_welfare_channels: regime %s total: %s', ...
                              R(r).name, lmsg);
            warning('kv_welfare_channels:cetotal', '%s', out.msg);
            return;
        end

        inact = {};
        if isfield(pr, 'inactive') && ~isempty(pr.inactive)
            inact = cellstr(pr.inactive);
        end
        nodes = struct();
        if isfield(pr, 'nodes') && ~isempty(pr.nodes), nodes = pr.nodes; end
        missing = {};
        for c = 1:nCH
            nm = CH{c};
            if any(strcmp(nm, inact))
                Lam(:, c+1) = 0;
                continue;
            end
            if ~isfield(nodes, nm) || isempty(nodes.(nm))
                missing{end+1} = nm; %#ok<AGROW>
                Lam(:, c+1) = NaN;
                continue;
            end
            Vc = nodes.(nm);
            if ~isequal(size(Vc), sz)
                out.msg = sprintf(['kv_welfare_channels: regime %s node ' ...
                    '%s is not sized like base.V.'], R(r).name, nm);
                warning('kv_welfare_channels:nodesize', '%s', out.msg);
                return;
            end
            [Lam(:, c+1), lmsg] = kvwc_ce(Vc(:), cec);
            if ~isempty(lmsg)
                out.msg = sprintf('kv_welfare_channels: regime %s node %s: %s', ...
                                  R(r).name, nm, lmsg);
                warning('kv_welfare_channels:cenode', '%s', out.msg);
                return;
            end
        end
        R(r).channel_missing  = missing;
        R(r).channel_inactive = inact;
        if ~isempty(missing)
            warning('kv_welfare_channels:missingnode', ...
                ['Regime %s: no node for %s and not declared inactive -- ' ...
                 'those channels and the interaction residual are returned ' ...
                 'as NaN.'], R(r).name, strjoin(missing, ', '));
        end

        % aggregate (whole population as one group)
        R(r).aggregate = kvwc_aggregate(Lam, w, {'all'}, true, [], CH);

        % groupings
        for k = 1:numel(gorder)
            gn = gorder{k};
            G  = GRP.(gn);
            if ~G.active
                R(r).grouping.(gn) = G;
                continue;
            end
            A = kvwc_aggregate(Lam, G.W, G.labels, G.is_partition, ...
                               G.rank_mean, CH);
            A.kind = G.kind; A.active = true; A.reason = G.reason;
            R(r).grouping.(gn) = A;
        end
    end

    out.regime = R;
    out.ok = true;
    out.msg = sprintf(['%d regime(s), %d channels + interaction residual, ' ...
        'CE transform ''%s'', %d quantile groups.'], nR, numel(CH), ce, ...
        numel(opts.quantiles) - 1);
    out.table = kvwc_table(out, gorder, CH);
    if opts.verbose, fprintf('%s', out.table); end
end

% =========================================================================
% defaults / validation
% =========================================================================
function opts = kvwc_defaults(opts)
    if ~isfield(opts, 'quantiles') || isempty(opts.quantiles)
        opts.quantiles = 0:0.1:1;
    end
    opts.quantiles = sort(opts.quantiles(:))';
    if opts.quantiles(1) ~= 0 || abs(opts.quantiles(end) - 1) > 0
        error('kv_welfare_channels:edges', ...
              'opts.quantiles must start at exactly 0 and end at exactly 1.');
    end
    if ~isfield(opts, 'tails') || isempty(opts.tails)
        opts.tails = { 'top10', 0.90, 1.00;
                       'top5',  0.95, 1.00;
                       'top1',  0.99, 1.00;
                       'bot50', 0.00, 0.50 };
    end
    if ~isfield(opts, 'ce') || isempty(opts.ce), opts.ce = 'auto'; end
    opts.ce = lower(char(opts.ce));
    if ~any(strcmp(opts.ce, {'auto','shift','components'}))
        error('kv_welfare_channels:ce', ...
              'opts.ce must be ''auto'', ''shift'' or ''components''.');
    end
    if ~isfield(opts, 'tie_tol') || isempty(opts.tie_tol), opts.tie_tol = 0; end
    if ~isfield(opts, 'verbose') || isempty(opts.verbose), opts.verbose = false; end
end

function [ok, why] = kvwc_check_base(base)
    ok = false; why = '';
    if ~isstruct(base) || ~isfield(base, 'V') || isempty(base.V)
        why = 'base.V missing or empty.'; return;
    end
    if ~isnumeric(base.V) || ~all(isfinite(base.V(:)))
        why = 'base.V must be numeric and finite.'; return;
    end
    if ~isfield(base, 'dist') || ~isequal(size(base.dist), size(base.V))
        why = 'base.dist missing or not sized like base.V.'; return;
    end
    if any(base.dist(:) < 0) || ~all(isfinite(base.dist(:)))
        why = 'base.dist must be nonnegative and finite.'; return;
    end
    if sum(base.dist(:)) <= 0
        why = 'base.dist has nonpositive total mass.'; return;
    end
    ok = true;
end

function v = kvwc_param(base, nm)
    if isfield(base, nm) && ~isempty(base.(nm))
        v = base.(nm);
    elseif isfield(base, 'p') && isstruct(base.p) && isfield(base.p, nm)
        v = base.p.(nm);
    elseif isfield(base, 'pg') && isstruct(base.pg) && isfield(base.pg, nm)
        v = base.pg.(nm);
    else
        error('kv_welfare_channels:param', ...
              'Parameter %s not found on base (or base.p / base.pg).', nm);
    end
    if ~isscalar(v) || ~isfinite(v)
        error('kv_welfare_channels:param', ...
              'Parameter %s must be a finite scalar.', nm);
    end
end

% =========================================================================
% CE transform
% =========================================================================
function [lam, msg] = kvwc_ce(V1, cec)
% Consumption-equivalent transfer against the baseline, in the convention of
% welfare_by_group.m ('shift') or main_twoasset_welfare.m ('components').
% Exactness guard: states whose value is unchanged get exactly 0.
    msg = '';
    V0 = cec.V0;
    same = (V1 == V0);
    if abs(cec.sigma - 1) < 1e-12
        lam = exp((V1 - V0) * (1 - cec.beta)) - 1;
    elseif strcmp(cec.kind, 'components')
        ratio = (V1 - cec.Ub0) ./ cec.Uc0;
        % A NON-POSITIVE RATIO IS AN INVALID CE TRANSFORM, NOT A SMALL ONE.
        % This previously read ratio = max(ratio, 1e-12), which silently
        % floored it. With sigma = 2 the exponent is 1/(1-sigma) = -1, so a
        % floored ratio of 1e-12 returns lam = 1e12 - 1: a huge FINITE number
        % that flows into total, channel and chan_sum, is mass-aggregated, and
        % is printed as a welfare figure with no warning and no entry in
        % channel_missing. A number that large is obvious in isolation and
        % invisible once averaged against a group of ordinary magnitude.
        % Refuse instead, by the same rule the 'shift' branch below already
        % uses: an invalid transform returns NaN with a message, so the caller
        % sees a missing channel rather than a fabricated one.
        bad = ~isfinite(ratio) | ratio <= 0;
        if all(bad(:))
            lam = nan(size(V1));
            msg = ['CE transform invalid (components): (V1 - Ub0)/Uc0 is ' ...
                   'non-positive everywhere.'];
            return;
        end
        lam = nan(size(ratio));
        lam(~bad) = ratio(~bad).^(1/(1 - cec.sigma)) - 1;
        if any(bad(:))
            msg = sprintf(['CE transform invalid (components) at %d of %d ' ...
                           'states; those states return NaN.'], ...
                          sum(bad(:)), numel(bad));
        end
    else
        Vt1 = V1 + cec.cshift;
        if cec.sigma > 1 && max(Vt1) >= 0
            lam = nan(size(V1));
            msg = 'CE transform invalid (sigma > 1, tilde-V >= 0).';
            return;
        end
        lam = (Vt1 ./ cec.Vt0).^(1/(1 - cec.sigma)) - 1;
    end
    lam(same) = 0;
end

% =========================================================================
% group construction
% =========================================================================
function [GRP, gorder] = kvwc_build_groups(base, w, sz, opts)
% Every grouping is reduced to a matrix of STATE-LEVEL weight columns, one
% column per group. The same columns then aggregate the total and every
% channel, so the residual cannot be a weighting artefact.
    contnames = {'liquid_wealth','total_wealth','income', ...
                 'bond_direct','bond_indirect'};
    gorder = [contnames, {'constrained','adjustment'}];
    GRP = struct();
    G0 = base;
    if isfield(base, 'groups') && isstruct(base.groups), G0 = base.groups; end

    for k = 1:numel(contnames)
        gn = contnames{k};
        if ~isfield(G0, gn) || isempty(G0.(gn))
            GRP.(gn) = kvwc_inactive('quantile', sprintf( ...
                'groups.%s not supplied -- grouping not imputed.', gn));
            continue;
        end
        x = G0.(gn);
        if ~isequal(size(x), sz) || ~isnumeric(x) || ~all(isfinite(x(:)))
            GRP.(gn) = kvwc_inactive('quantile', sprintf( ...
                ['groups.%s must be numeric, finite and sized like ' ...
                 'base.V -- grouping skipped.'], gn));
            continue;
        end
        GRP.(gn) = kvwc_quantile_group(x(:), w, opts);
    end

    % ---- constrained vs unconstrained (hard mask) ----
    if isfield(G0, 'constrained') && ~isempty(G0.constrained) && ...
            isequal(size(G0.constrained), sz)
        m = logical(G0.constrained(:));
        GRP.constrained = struct('kind','binary','active',true,'reason','', ...
            'labels', {{'constrained','unconstrained'}}, ...
            'is_partition', [true true], 'rank_mean', [NaN NaN], ...
            'W', [w .* m, w .* (~m)]);
    else
        GRP.constrained = kvwc_inactive('binary', ...
            ['groups.constrained not supplied -- "at the borrowing limit" ' ...
             'is grid-specific (asset index 1 one-asset, liquid index 1 ' ...
             'two-asset) and is not imputed here.']);
    end

    % ---- adjuster vs non-adjuster (fractional membership) ----
    if isfield(G0, 'adjust_prob') && ~isempty(G0.adjust_prob) && ...
            isequal(size(G0.adjust_prob), sz)
        p = double(G0.adjust_prob(:));
        if any(~isfinite(p)) || any(p < 0) || any(p > 1)
            GRP.adjustment = kvwc_inactive('fractional', ...
                'groups.adjust_prob must lie in [0,1] -- grouping skipped.');
        else
            GRP.adjustment = struct('kind','fractional','active',true, ...
                'reason','', 'labels', {{'adjuster','non-adjuster'}}, ...
                'is_partition', [true true], 'rank_mean', [NaN NaN], ...
                'W', [w .* p, w .* (1 - p)]);
        end
    else
        GRP.adjustment = kvwc_inactive('fractional', ...
            ['groups.adjust_prob not supplied -- in the one-asset economy ' ...
             'there is no adjustment margin, so this grouping is inactive ' ...
             'rather than degenerate.']);
    end
end

function G = kvwc_inactive(kind, reason)
    G = struct('kind', kind, 'active', false, 'reason', reason, ...
               'labels', {{}}, 'is_partition', logical([]), ...
               'rank_mean', [], 'W', []);
end

function G = kvwc_quantile_group(x, w, opts)
% Fractional mass-point splitting on an arbitrary ranking variable,
% generalising welfare_by_decile.m:61-81. States sharing a ranking value form
% one tie block; a block straddling a boundary is split in proportion to the
% overlap, and within the block in proportion to baseline mass.
    n = numel(x);
    [xs, ord] = sort(x, 'ascend');
    ws = w(ord);
    if opts.tie_tol > 0
        newblk = [true; diff(xs) > opts.tie_tol];
    else
        newblk = [true; diff(xs) ~= 0];
    end
    blk = cumsum(newblk);
    nb  = blk(end);
    wB  = accumarray(blk, ws, [nb 1]);
    xB  = accumarray(blk, ws .* xs, [nb 1]) ./ max(wB, eps);
    cwHi = cumsum(wB);
    cwLo = [0; cwHi(1:end-1)];
    tot  = cwHi(end);

    edges = opts.quantiles;
    nq = numel(edges) - 1;
    ntl = size(opts.tails, 1);
    nG = nq + ntl;
    labels = cell(1, nG);
    is_part = false(1, nG);
    W = zeros(n, nG);
    rank_mean = nan(1, nG);

    if nq == 10, pfx = 'D'; else, pfx = 'Q'; end
    for g = 1:nq
        lo = edges(g) * tot;
        hi = edges(g+1) * tot;
        if g == 1,  lo = 0;   end
        if g == nq, hi = tot; end
        [W(:, g), rank_mean(g)] = kvwc_overlap_weights(lo, hi, cwLo, cwHi, ...
                                                       wB, xB, blk, ws, ord, n);
        labels{g} = sprintf('%s%d', pfx, g);
        is_part(g) = true;
    end
    for t = 1:ntl
        g = nq + t;
        lo = opts.tails{t,2} * tot;
        hi = opts.tails{t,3} * tot;
        if opts.tails{t,2} <= 0, lo = 0;   end
        if opts.tails{t,3} >= 1, hi = tot; end
        [W(:, g), rank_mean(g)] = kvwc_overlap_weights(lo, hi, cwLo, cwHi, ...
                                                       wB, xB, blk, ws, ord, n);
        labels{g} = opts.tails{t,1};
        is_part(g) = false;
    end

    G = struct('kind','quantile','active',true,'reason','', ...
               'labels', {labels}, 'is_partition', is_part, ...
               'rank_mean', rank_mean, 'W', W);
end

function [wg, xbar] = kvwc_overlap_weights(lo, hi, cwLo, cwHi, wB, xB, ...
                                           blk, ws, ord, n)
    ov = max(0, min(cwHi, hi) - max(cwLo, lo));
    frac = ov ./ max(wB, eps);
    wg_sorted = ws .* frac(blk);
    wg = zeros(n, 1);
    wg(ord) = wg_sorted;
    m = sum(ov);
    if m > 0
        xbar = sum(ov .* xB) / m;
    else
        xbar = NaN;
    end
end

% =========================================================================
% aggregation and the interaction residual
% =========================================================================
function A = kvwc_aggregate(Lam, W, labels, is_part, rank_mean, CH)
% Lam : n x (1 + nCH), column 1 the total, the rest the channels.
% W   : n x nG state-level weights (one column per group).
    nCH = numel(CH);
    nG  = size(W, 2);
    if isscalar(is_part), is_part = repmat(logical(is_part), 1, nG); end
    if isempty(rank_mean), rank_mean = nan(1, nG); end

    M = nan(nG, nCH + 1);
    mass = nan(1, nG);
    for g = 1:nG
        wg = W(:, g);
        mass(g) = sum(wg);
        if mass(g) > 0
            M(g, :) = (wg' * Lam) / mass(g);
        end
    end

    total = M(:, 1)';
    chan  = M(:, 2:end)';                 % nCH x nG

    resid = nan(1, nG); csum = nan(1, nG);
    rerr  = nan(1, nG); aok = false(1, nG);
    for g = 1:nG
        [resid(g), csum(g), rerr(g)] = kvwc_residual(total(g), chan(:, g));
        aok(g) = (rerr(g) == 0);
    end

    A = struct();
    A.kind = 'aggregate'; A.active = true; A.reason = '';
    A.labels = labels;
    A.is_partition = is_part;
    A.mass = mass;
    A.rank_mean = rank_mean;
    A.total = total;
    A.channel_names = CH;
    A.channel = chan;
    A.ch = struct();
    for c = 1:nCH
        A.ch.(CH{c}) = chan(c, :);
    end
    A.residual = resid;
    A.chan_sum = csum;
    A.recon_err = rerr;
    A.additive_ok = aok;
end

function [r, s, err] = kvwc_residual(total, chan)
% Interaction residual: total - sum(channels), summed left to right, exactly
% as the printed table adds up. Nothing here is adjusted after the fact -- see
% the RECONSTRUCTION section of the header for why the compensation loop that
% used to live here was removed, and for the bound on err.
    s = 0;
    for k = 1:numel(chan)
        s = s + chan(k);
    end
    r = total - s;
    recon = s;
    recon = recon + r;
    err = total - recon;
end

% =========================================================================
% report
% =========================================================================
function T = kvwc_table(out, gorder, CH)
    L = {};
    L{end+1} = 'CHANNEL-BY-GROUP WELFARE DECOMPOSITION (referee R13, MC1 / Exp. 4)';
    L{end+1} = sprintf(['Units: consumption-equivalent transfer, PERCENT of ' ...
        'permanent consumption. CE transform ''%s''.'], out.ce);
    L{end+1} = ['INTERACTION is a reported residual, not a channel: ' ...
                'total - sum(channels). It is never absorbed.'];
    L{end+1} = ['TWO-ASSET APPLICATION IS BLOCKED on Gate 11 certification; ' ...
                'no two-asset number here is established.'];
    L{end+1} = '';
    for r = 1:numel(out.regime)
        R = out.regime(r);
        L{end+1} = sprintf('=== regime: %s ===', R.name); %#ok<AGROW>
        if ~isempty(R.channel_inactive)
            L{end+1} = sprintf('  structurally inactive channels (set to 0): %s', ...
                strjoin(R.channel_inactive, ', ')); %#ok<AGROW>
        end
        if ~isempty(R.channel_missing)
            L{end+1} = sprintf(['  MISSING nodes (reported NaN, residual ' ...
                'NaN): %s'], strjoin(R.channel_missing, ', ')); %#ok<AGROW>
        end
        L = [L, kvwc_block('aggregate', R.aggregate, CH)]; %#ok<AGROW>
        for k = 1:numel(gorder)
            gn = gorder{k};
            G = R.grouping.(gn);
            if ~G.active
                L{end+1} = sprintf('  [%s] INACTIVE: %s', gn, G.reason); %#ok<AGROW>
                L{end+1} = ''; %#ok<AGROW>
                continue;
            end
            L = [L, kvwc_block(gn, G, CH)]; %#ok<AGROW>
        end
    end
    T = [strjoin(L, sprintf('\n')) sprintf('\n')];
end

function L = kvwc_block(name, A, CH)
    L = {};
    L{end+1} = sprintf('  [%s]', name);
    L{end+1} = ['    ' kvwc_srow('group', A.labels)];
    L{end+1} = ['    ' kvwc_nrow('mass', 100*A.mass)];
    L{end+1} = ['    ' kvwc_nrow('dW total', 100*A.total)];
    for c = 1:numel(CH)
        L{end+1} = ['    ' kvwc_nrow(CH{c}, 100*A.channel(c, :))]; %#ok<AGROW>
    end
    L{end+1} = ['    ' kvwc_nrow('sum channels', 100*A.chan_sum)];
    L{end+1} = ['    ' kvwc_nrow('INTERACTION', 100*A.residual)];
    L{end+1} = ['    ' kvwc_nrow('recon err', 100*A.recon_err)];
    if ~all(A.additive_ok)
        L{end+1} = '    WARNING: reconstruction not bit-exact in some groups.';
    end
    if ~all(A.is_partition)
        L{end+1} = sprintf('    (non-partition columns: %s)', ...
            strjoin(A.labels(~A.is_partition), ', '));
    end
    L{end+1} = '';
end

function s = kvwc_srow(lab, items)
    s = sprintf('%-14s', lab);
    for k = 1:numel(items)
        s = [s sprintf('%9s', items{k})]; %#ok<AGROW>
    end
end

function s = kvwc_nrow(lab, v)
    s = sprintf('%-14s', lab);
    for k = 1:numel(v)
        s = [s sprintf('%9.3f', v(k))]; %#ok<AGROW>
    end
end

function R = kvwc_empty_regime(CH, GRP, gorder)
    R = struct('name', '', 'channel_missing', {{}}, 'channel_inactive', {{}}, ...
               'aggregate', [], 'grouping', struct());
    for k = 1:numel(gorder)
        R.grouping.(gorder{k}) = GRP.(gorder{k});
    end
    R.aggregate = kvwc_aggregate(zeros(1, numel(CH)+1), 1, {'all'}, true, [], CH);
end

% =========================================================================
% SELF-TEST (synthetic inputs only; no solver, no .mat, no economy)
% =========================================================================
function rep = kvwc_selftest(verbose, CH)
    rep = struct('ok', true, 'ncase', 0, 'nfail', 0, 'cases', {{}});
    if verbose
        fprintf('kv_welfare_channels self-test\n');
        fprintf(['  (a) channels + interaction residual reconstruct the ' ...
                 'total BITWISE\n']);
        fprintf('  (b) a zero program gives identically zero in every channel\n\n');
    end

    cases = { ...
        struct('name','2-D state space, shift CE (one-asset shaped)', ...
               'sz', [40 5], 'ce', 'shift',      'sigma', 2.0), ...
        struct('name','2-D state space, log utility (sigma = 1)', ...
               'sz', [40 5], 'ce', 'shift',      'sigma', 1.0), ...
        struct('name','3-D state space, components CE (two-asset shaped)', ...
               'sz', [12 9 5], 'ce', 'components','sigma', 2.0) };

    for ic = 1:numel(cases)
        C = cases{ic};
        [base, prog] = kvwc_synth(C, false, CH);
        opts = struct('verbose', false, 'ce', C.ce);
        A = kv_welfare_channels(base, prog, opts);
        [okA, mA] = kvwc_check_recon(A, true);
        rep = kvwc_log(rep, [C.name ' :: (a) reconstruction'], okA, mA, verbose);

        [okS, mS] = kvwc_check_structure(A);
        rep = kvwc_log(rep, [C.name ' :: (a) group structure'], okS, mS, verbose);

        [base0, prog0] = kvwc_synth(C, true, CH);
        Z = kv_welfare_channels(base0, prog0, opts);
        [okZ, mZ] = kvwc_check_zero(Z);
        rep = kvwc_log(rep, [C.name ' :: (b) zero program'], okZ, mZ, verbose);
    end

    % inactive-channel and missing-node handling
    C = cases{1};
    [base, prog] = kvwc_synth(C, false, CH);
    prog(1).nodes = rmfield(prog(1).nodes, 'rebate');
    prog(1).inactive = {'rebate'};
    A = kv_welfare_channels(base, prog, struct('verbose', false, 'ce', C.ce));
    okI = A.ok && all(A.regime(1).aggregate.ch.rebate == 0) && ...
          isempty(A.regime(1).channel_missing) && ...
          all(A.regime(1).aggregate.recon_err == 0);
    rep = kvwc_log(rep, 'declared-inactive channel is exactly 0 and still adds up', ...
                   okI, '', verbose);

    prog(1).inactive = {};
    ws = warning('off', 'kv_welfare_channels:missingnode');
    A = kv_welfare_channels(base, prog, struct('verbose', false, 'ce', C.ce));
    warning(ws);
    okM = A.ok && any(strcmp('rebate', A.regime(1).channel_missing)) && ...
          all(isnan(A.regime(1).aggregate.ch.rebate)) && ...
          all(isnan(A.regime(1).aggregate.residual));
    rep = kvwc_log(rep, 'undeclared missing node poisons channel AND residual to NaN', ...
                   okM, '', verbose);

    % HONESTY PROBE. Where a channel sum is many orders of magnitude larger
    % than the total, no single double can close the gap (see the header). The
    % point of this check is not that the arithmetic is exact -- it cannot be
    % -- but that the failure is REPORTED: recon_err nonzero, additive_ok
    % false, and bounded by one rounding unit. A decomposition routine that
    % quietly returned recon_err = 0 here would be lying.
    tot_p = 1e-14;
    chan_p = [1e6; 0; 0; 0; 0; 0; 0];
    [rp, sp, ep] = kvwc_residual(tot_p, chan_p);
    okP = (ep ~= 0) && (abs(ep) <= eps * (abs(tot_p) + abs(sp))) && isfinite(rp);
    rep = kvwc_log(rep, ['unattainable exactness is reported, not faked ' ...
        '(|err| within one rounding unit)'], okP, ...
        sprintf('recon_err = %.3e, bound = %.3e', ep, ...
                eps*(abs(tot_p) + abs(sp))), verbose);

    rep.ok = (rep.nfail == 0);
    if verbose
        fprintf('\n  %d checks, %d failed -- %s\n', rep.ncase, rep.nfail, ...
                kvwc_yn(rep.ok, 'PASS', 'FAIL'));
        fprintf(['  NOTE: the two-asset APPLICATION remains BLOCKED on ' ...
                 'Gate 11; this test\n        exercises machinery on ' ...
                 'synthetic arrays only.\n']);
    end
end

function [base, prog] = kvwc_synth(C, zero_program, names)
% Deterministic synthetic inputs. Values are negative and bounded away from
% zero so the sigma > 1 transforms are valid, as they are in the real model.
    rng(20260805, 'twister');
    sz = C.sz;
    n  = prod(sz);
    beta = 0.96; sigma = C.sigma;

    V0 = -8 - 4*reshape(rand(n,1), sz);
    d  = reshape(rand(n,1), sz) + 0.05;
    d  = d / sum(d(:));

    base = struct('V', V0, 'dist', d, 'sigma', sigma, 'beta', beta);
    if strcmp(C.ce, 'components')
        Ub = -1 - reshape(rand(n,1), sz);
        base.Uc = V0 - Ub;
        base.Ub = Ub;
    end

    % ranking variables: deliberately full of TIES and of a mass point at the
    % bottom, which is where a decile cut on this model actually breaks.
    a1 = repmat((0:sz(1)-1)', [1 sz(2:end)]);
    a1(1:3, :) = 0;                        % borrowing-limit style mass point
    g = struct();
    g.liquid_wealth = a1;
    g.total_wealth  = a1 + 0.5*reshape(rand(n,1), sz);
    if numel(sz) == 2
        inc = repmat(1:sz(2), sz(1), 1);
    else
        inc = repmat(reshape(1:sz(3), [1 1 sz(3)]), [sz(1) sz(2) 1]);
    end
    g.income        = inc;
    g.bond_direct   = a1;
    g.bond_indirect = a1(end:-1:1, :, :);
    cons = false(sz); cons(1, :) = true;
    g.constrained   = cons;
    g.adjust_prob   = 0.25 * ones(sz);
    base.groups = g;

    nodes = struct();
    if zero_program
        for k = 1:numel(names), nodes.(names{k}) = V0; end
        prog = struct('name','zero-program','V', V0, 'nodes', nodes, ...
                      'inactive', {{}});
        return;
    end
    pert = zeros(sz);
    for k = 1:numel(names)
        dk = 0.02 * (k/4) * reshape(rand(n,1), sz);
        nodes.(names{k}) = V0 + dk;
        pert = pert + dk;
    end
    % the program value is NOT the sum of the node perturbations: the channels
    % must fail to span it, so the residual is materially nonzero and the
    % reconstruction test cannot pass on a trivially additive case.
    V1 = V0 + 0.7*pert + 0.35*abs(V0).*0.01;
    prog = struct('name', {'lump-sum','levy-plus-rebate'}, ...
                  'V', {V1, V0 + 1.3*pert}, ...
                  'nodes', {nodes, nodes}, 'inactive', {{}, {}});
end

function [ok, msg] = kvwc_check_recon(A, need_material)
    ok = A.ok; msg = '';
    if ~ok, msg = A.msg; return; end
    maxres = 0;
    for r = 1:numel(A.regime)
        blocks = {A.regime(r).aggregate};
        fn = fieldnames(A.regime(r).grouping);
        for k = 1:numel(fn)
            G = A.regime(r).grouping.(fn{k});
            if G.active, blocks{end+1} = G; end %#ok<AGROW>
        end
        for b = 1:numel(blocks)
            B = blocks{b};
            % universal invariant first (holds in every regime, exact or not),
            % so it is not made vacuous by the exactness check that follows
            bound = eps * (abs(B.total) + abs(B.chan_sum));
            if any(abs(B.recon_err) > bound)
                ok = false;
                msg = 'recon_err exceeds the one-rounding-unit bound';
                return;
            end
            % exactness: guaranteed in this regime (channel sum within a
            % factor of two of the total), so demand it bitwise
            if ~all(B.recon_err(:) == 0)
                ok = false;
                msg = sprintf('recon_err ~= 0 (max |err| = %.3e)', ...
                              max(abs(B.recon_err(:))));
                return;
            end
            if ~all(B.additive_ok)
                ok = false; msg = 'additive_ok false somewhere'; return;
            end
            maxres = max(maxres, max(abs(B.residual(:))));
        end
    end
    if need_material && ~(maxres > 1e-6)
        ok = false;
        msg = sprintf(['residual is trivially small (max %.3e): the test ' ...
                       'would pass on an additive case'], maxres);
        return;
    end
    msg = sprintf('exact; max |interaction| = %.4f%%', 100*maxres);
end

function [ok, msg] = kvwc_check_structure(A)
% quantile masses must equal their exact shares, and the mass-weighted mean of
% partition-group totals must equal the aggregate.
    ok = true; msg = ''; worst = 0;
    e = A.quantile_edges;
    for r = 1:numel(A.regime)
        agg = A.regime(r).aggregate.total;
        fn = fieldnames(A.regime(r).grouping);
        for k = 1:numel(fn)
            G = A.regime(r).grouping.(fn{k});
            if ~G.active, continue; end
            ip = G.is_partition;
            if strcmp(G.kind, 'quantile')
                want = diff(e);
                got  = G.mass(1:numel(want));
                if max(abs(got - want)) > 1e-12
                    ok = false;
                    msg = sprintf('%s: quantile mass off by %.3e', fn{k}, ...
                                  max(abs(got - want)));
                    return;
                end
            end
            if abs(sum(G.mass(ip)) - 1) > 1e-12
                ok = false;
                msg = sprintf('%s: partition mass sums to %.12f', fn{k}, ...
                              sum(G.mass(ip)));
                return;
            end
            wm = sum(G.mass(ip) .* G.total(ip));
            worst = max(worst, abs(wm - agg));
            if abs(wm - agg) > 1e-10 * max(1, abs(agg))
                ok = false;
                msg = sprintf('%s: mass-weighted total %.12f vs aggregate %.12f', ...
                              fn{k}, wm, agg);
                return;
            end
        end
    end
    msg = sprintf('masses exact; max |group-avg - aggregate| = %.2e', worst);
end

function [ok, msg] = kvwc_check_zero(A)
    ok = A.ok; msg = '';
    if ~ok, msg = A.msg; return; end
    for r = 1:numel(A.regime)
        blocks = {A.regime(r).aggregate};
        fn = fieldnames(A.regime(r).grouping);
        for k = 1:numel(fn)
            G = A.regime(r).grouping.(fn{k});
            if G.active, blocks{end+1} = G; end %#ok<AGROW>
        end
        for b = 1:numel(blocks)
            B = blocks{b};
            vals = [B.total(:); B.channel(:); B.residual(:); ...
                    B.chan_sum(:); B.recon_err(:)];
            vals = vals(~isnan(vals));
            if ~all(vals == 0)
                ok = false;
                msg = sprintf('nonzero entry under a zero program (max %.3e)', ...
                              max(abs(vals)));
                return;
            end
        end
    end
    msg = 'all channels, residual and total identically zero (bitwise)';
end

function rep = kvwc_log(rep, name, ok, msg, verbose)
    rep.ncase = rep.ncase + 1;
    rep.nfail = rep.nfail + ~ok;
    rep.cases{end+1} = struct('name', name, 'ok', ok, 'msg', msg);
    if verbose
        if isempty(msg)
            fprintf('  [%s] %s\n', kvwc_yn(ok, 'ok  ', 'FAIL'), name);
        else
            fprintf('  [%s] %s -- %s\n', kvwc_yn(ok, 'ok  ', 'FAIL'), name, msg);
        end
    end
end

function s = kvwc_yn(c, a, b)
    if c, s = a; else, s = b; end
end
