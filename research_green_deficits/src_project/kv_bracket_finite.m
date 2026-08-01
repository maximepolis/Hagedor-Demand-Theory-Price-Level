function B = kv_bracket_finite(fev, qc, opts)
% KV_BRACKET_FINITE  Bracket the tree-market root inside the region where the
% stationary equilibrium is actually DEFINED.
%
% WHAT THIS REPLACES, AND WHY. The previous bracket expanded the q window
% geometrically until the endpoint residuals had opposite signs. Two things
% were wrong with that once the k-grid was widened. First, sign(NaN) is NaN
% and NaN ~= anything is true, so a NaN endpoint READ AS a sign change: the
% search reported "(brackets)" over an interval whose lower end was a solver
% failure. Second, even read correctly, expanding is the wrong response to a
% NaN. A NaN says the model stops being defined below some q; the answer is
% to stop there, not to step further past it.
%
% THE PROCEDURE
%   1. evaluate a COARSE, FIXED q window around qc -- no expansion;
%   2. classify every node admissible / failed, with a reason;
%   3. take the largest CONTIGUOUS admissible run containing (or nearest to)
%      qc -- contiguity matters because a bracket that jumps a hole in the
%      domain is not a bracket;
%   4. look for a sign change inside that run and return the tightest
%      adjacent pair that straddles;
%   5. if the run has no sign change, say "no admissible root in this
%      domain" and return the run anyway, flagged, so a diagnostic scan can
%      still map the residual over feasible territory.
%
% Widening the window is offered only when the ADMISSIBLE region reaches the
% window edge -- i.e. when the domain was cut by the window rather than by
% the model. That is the only case where expanding can help, and it expands
% on the finite side only.
%
% INPUT   fev   function handle q -> [F, code], where code is 'OK' or
%               'BOUNDARY_HIT' for admissible points (see KV_NODE_STATUS)
%         qc    centre of the search (the continuation guess)
%         opts  .span (0.25) .n (13) .maxgrow (3) .allow_boundary_hit (true)
%
% OUTPUT  B.ok        a usable root bracket was found
%         B.lo/.hi    that bracket, and B.flo/.fhi its residuals
%         B.qlo/.qhi  the largest contiguous admissible interval
%         B.q/.F/.code  the coarse map, for reporting
%         B.first_bad first q (ascending) whose code is not admissible
%         B.first_sign first q where F changes sign inside the admissible run
%         B.status    'OK' | 'NO_SIGN_CHANGE' | 'NO_FEASIBLE_POINT'
%                     | 'DOMAIN_TRUNCATED_BY_WINDOW'

    if nargin < 3, opts = struct(); end
    span   = getdef(opts,'span',0.25);
    n      = getdef(opts,'n',13);
    maxg   = getdef(opts,'maxgrow',3);
    allowB = getdef(opts,'allow_boundary_hit',true);

    B = struct('ok',false,'lo',NaN,'hi',NaN,'flo',NaN,'fhi',NaN, ...
               'qlo',NaN,'qhi',NaN,'q',[],'F',[],'code',{{}}, ...
               'first_bad',NaN,'first_sign',NaN,'status','NO_FEASIBLE_POINT', ...
               'nev',0,'grew',0,'pattern','NONE');

    for g = 0:maxg
        q = linspace(qc*(1-span), qc*(1+span), n);
        [F, C] = evalmap(fev, q);
        B.nev = B.nev + n; B.grew = g;
        adm = admissible(C, allowB);
        B.pattern = fail_pattern(adm);
        [i0, i1] = longest_run(adm, q, qc);
        B.q = q; B.F = F; B.code = C;
        bad = find(~adm, 1, 'first');
        if ~isempty(bad), B.first_bad = q(bad); else, B.first_bad = NaN; end
        if isempty(i0), B.status = 'NO_FEASIBLE_POINT'; return; end
        B.qlo = q(i0); B.qhi = q(i1);

        s = sign(F(i0:i1));
        j = find(s(1:end-1) ~= s(2:end) & s(1:end-1) ~= 0, 1, 'first');
        if ~isempty(j)
            B.lo = q(i0+j-1); B.hi = q(i0+j);
            B.flo = F(i0+j-1); B.fhi = F(i0+j);
            B.first_sign = B.lo; B.ok = true; B.status = 'OK';
            return;
        end

        % No sign change inside the admissible run. Expanding is defensible
        % ONLY if the run reaches a window edge -- then the domain was cut by
        % the window, not by the model. If the run is strictly interior, the
        % model itself bounds the region and a wider window would only add
        % more failures.
        at_lo = (i0 == 1); at_hi = (i1 == n);
        if strcmp(B.pattern, 'SCATTERED')
            % Interleaved failures. Growing the window cannot help and the
            % "the model bounds the domain" reading is not available: a
            % domain does not alternate. Stop and say so.
            B.status = 'SOLVER_SCATTERED';
            return;
        end
        if ~(at_lo || at_hi) || g == maxg
            B.status = 'NO_SIGN_CHANGE';
            if at_lo || at_hi, B.status = 'DOMAIN_TRUNCATED_BY_WINDOW'; end
            return;
        end
        span = span * 1.6;                    % modest, and only on this branch
    end
end

% ---------------------------------------------------------------------
function [F, C] = evalmap(fev, q)
    n = numel(q); F = nan(1,n); C = cell(1,n);
    for i = 1:n
        [F(i), C{i}] = fev(q(i));
    end
end

function a = admissible(C, allowB)
    a = kv_is_admissible(C);
    if ~allowB
        a = a & ~strcmp(C,'BOUNDARY_HIT');
    end
end

function pat = fail_pattern(adm)
% A domain boundary produces a CONTIGUOUS block of failures at one or both
% ends. Failures interleaved with successes cannot be a domain boundary --
% the model does not stop existing and start again -- so they indict the
% SOLVER. The two call for opposite responses (move the bracket vs fix the
% solver), so they must not share a label.
    if all(adm), pat = 'NONE'; return; end
    if ~any(adm), pat = 'ALL'; return; end
    f = find(~adm); a = find(adm);
    interleaved = any(f > min(a) & f < max(a));
    if interleaved, pat = 'SCATTERED';
    elseif all(f < min(a)), pat = 'TAIL_LOW';
    elseif all(f > max(a)), pat = 'TAIL_HIGH';
    else, pat = 'TAIL_BOTH';
    end
end

function [i0, i1] = longest_run(adm, q, qc)
% CONTAINING qc first, then longest, then nearest.
%
% Longest-first was wrong and produced visibly incoherent domains: at
% alpha = 0.5 it returned [1.78, 2.14] and at alpha = 1 it returned
% [1.28, 1.50] from the SAME window centred on 1.712 -- disjoint intervals on
% opposite sides of the continuation guess, one of which cannot contain an
% equilibrium that must lie between its neighbours'. When scattered failures
% chop the window, "the longest surviving piece" is an arbitrary choice among
% pieces; the piece straddling the continuation guess is not.
    i0 = []; i1 = [];
    d = diff([false adm false]);
    s = find(d == 1); e = find(d == -1) - 1;
    if isempty(s), return; end
    contains_qc = arrayfun(@(k) q(s(k)) <= qc && qc <= q(e(k)), 1:numel(s));
    if any(contains_qc)
        cand = find(contains_qc);
    else
        cand = 1:numel(s);
    end
    len = e(cand) - s(cand) + 1;
    keep = cand(len == max(len));
    if numel(keep) > 1
        dist = arrayfun(@(k) min(abs(q(s(k):e(k)) - qc)), keep);
        [~, w] = min(dist); keep = keep(w);
    end
    i0 = s(keep); i1 = e(keep);
end

function v = getdef(s, f, dv)
    if isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end
