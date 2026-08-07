function R = kv_solve_consolidation(pgc, base_opts, sopts, kappa_target, tee)
% KV_SOLVE_CONSOLIDATION  Find the consolidation amplitude a_xi that returns
% terminal detrended debt to its target, THROUGH THE TAX PATH.
%
% THE POINT. A terminal-debt target is not a fiscal instrument. The previous
% implementation reached one by setting phat(T) = kappa_target * eq1.P inside
% the transition solver -- moving the terminal price until the debt ratio came
% out right. The debt recursion was left intact, so nothing looked wrong, but
% the case had no fiscal counterpart: no tax was raised to retire the debt,
% and the government budget stopped being an identity at T. A "matched
% terminal debt" case obtained that way is an accounting override, and the
% difference C2 - C1 computed from it is not a tax-timing effect.
%
% Here the target is reached the only way it legitimately can be: by levying
% a surcharge. The shape h_t is fixed in kv_fiscal_spec (zero before T_c, then
% geometric with half-life H_c); this routine solves the SCALAR amplitude
%
%       xi_t = a_xi * h_t
%
% so that the realized terminal dilution kappa_inf equals the target. Every
% evaluation is a full transition solve with kappa left FREE, so kappa_inf is
% always an outcome of the tax path and the budget identity holds at every
% date by construction.
%
% MONOTONICITY, AND WHY BISECTION IS SAFE. A larger surcharge retires more
% debt at every date from T_c on, so terminal debt -- and hence kappa_inf --
% is decreasing in a_xi. The residual
%
%       R(a_xi) = kappa_inf(a_xi) - kappa_target
%
% is therefore decreasing, and a sign-changing pair brackets the root. The
% bracket is found by geometric expansion from a_xi = 0 (which gives C4's
% dilution, the largest kappa attainable) upward.
%
% A FAILED SOLVE IS NOT A LARGE RESIDUAL. If a transition does not converge at
% some a_xi, that amplitude is recorded as INFEASIBLE and the expansion stops
% on that side, exactly as kv_solve_bond_given_q treats an infeasible price.
% It is never fed to the sign test.
%
% INPUT   pgc           green parameter struct
%         base_opts     opts for solve_hank_dtpl_transition (regime, T, ...);
%                       .fiscal is overwritten here
%         sopts         opts for kv_fiscal_spec (T, rho_bar, Tc, Hc, ...)
%         kappa_target  the terminal dilution to hit (1 = match C1)
%         tee           optional printf-like handle
%
% OUTPUT  R .a_xi .kappa_inf .gap .hit .TR .iters .trace .status
%         R.status  'OK' | 'NO_BRACKET' | 'INFEASIBLE' | 'NOT_CONVERGED'

    if nargin < 5 || isempty(tee), tee = @(varargin) fprintf(varargin{:}); end
    tol   = getdef(sopts, 'kappa_tol', 1e-8);
    amax  = getdef(sopts, 'consolidation_amax', 4.0);   % surcharge cap, units of g
    maxit = getdef(sopts, 'consolidation_maxit', 60);

    % WHICH GAP COUNTS AS CLOSED. The default rule is a RELATIVE gap in kappa
    % against a tolerance of 1e-8, and that tolerance is not attainable: the
    % transition solver's own fixed point is looser than that, so the bisection
    % spends all sixty iterations chasing a target it cannot reach, then
    % returns NOT_CONVERGED with a perfectly usable answer. The decomposition
    % driver already learned this and judges the result by a DIFFERENT and
    % attainable statistic -- the residual dilution as a fraction of the
    % ratchet the delay opened, eta = |kappa - target| / |kappa_C4 - target|,
    % which is what "consolidated back to C1" actually means. Caller supplies
    % that ratchet in sopts.kappa_ratchet and the stopping rule becomes the
    % same statistic the caller will grade with, so the bisection stops when
    % it has succeeded instead of when it runs out of iterations.
    %
    % OPT-IN ON PURPOSE. Without kappa_ratchet the rule is unchanged, so every
    % existing caller -- main_deficit_decomposition above all -- reproduces
    % bit-for-bit. Do not make this the default without re-running that driver.
    ratch   = getdef(sopts, 'kappa_ratchet', NaN);
    eta_tol = getdef(sopts, 'eta_tol', 1e-3);
    use_eta = isscalar(ratch) && isfinite(ratch) && ratch > 0;
    if use_eta
        gapf = @(k) abs(k - kappa_target) / ratch;   acc = eta_tol;
        rule = sprintf('eta = |kappa-target|/ratchet(%.3e) < %.1e', ratch, eta_tol);
    else
        gapf = @(k) abs(k / kappa_target - 1);       acc = tol;
        rule = sprintf('relative |kappa/target - 1| < %.1e', tol);
    end

    R = struct('a_xi', NaN, 'kappa_inf', NaN, 'gap', NaN, 'hit', false, ...
               'TR', [], 'iters', 0, 'status', 'INFEASIBLE', ...
               'gap_rule', rule, ...
               'trace', struct('a', {{}}, 'kappa', {{}}, 'ok', {{}}));
    A = []; K = []; OKV = [];

    function [k, TR, ok] = ev(a)
        so = sopts; so.consolidation_scale = a;
        fs = kv_fiscal_spec('C2', so);
        o  = base_opts; o.fiscal = fs;
        TR = solve_hank_dtpl_transition(pgc, o);
        ok = isstruct(TR) && isfield(TR,'kappa_inf') && isfinite(TR.kappa_inf) ...
             && (~isfield(TR,'converged') || TR.converged);
        k  = NaN; if ok, k = TR.kappa_inf; end
        A(end+1) = a; K(end+1) = k; OKV(end+1) = ok; %#ok<AGROW>
        R.iters = R.iters + 1;
    end

    % ---- a = 0 is C4's dilution: the largest kappa the delay can produce --
    [k0, TR0, ok0] = ev(0);
    if ~ok0
        R.status = 'INFEASIBLE';
        tee('  consolidation: the a_xi = 0 solve failed; no bracket possible.\n');
        R = finish(R, A, K, OKV); return;
    end
    if k0 <= kappa_target
        % The delay alone already leaves terminal debt at or below target, so
        % no surcharge is called for. Report it rather than solving for a
        % negative amplitude, which would be a TAX CUT and a different
        % experiment from the one the case is named for.
        R.a_xi = 0; R.kappa_inf = k0; R.TR = TR0;
        R.gap = gapf(k0); R.hit = R.gap < acc;
        R.status = 'OK';
        tee(['  consolidation: kappa(a=0) = %.10f <= target %.10f; no surcharge\n' ...
             '    is required. NOT solving for a negative a_xi -- that would be a\n' ...
             '    tax CUT, a different experiment from the one C2 names.\n'], ...
            k0, kappa_target);
        R = finish(R, A, K, OKV); return;
    end

    % ---- expand upward for a sign change --------------------------------
    % AN INFEASIBLE AMPLITUDE IS NOT EVIDENCE ABOUT THE BRACKET. The timing
    % frontier's rho = 0.80 speed failed here after TWO transitions: the first
    % probe, a = 0.05, is 4x-28x larger than every root this project has
    % measured (0.0018 to 0.0132), the transition at that oversized surcharge
    % did not converge, and the expansion read "this amplitude failed" as "no
    % bracket exists" -- aborting a search whose root sat far below the point
    % that failed. Feasibility of these solves is not monotone in a (the same
    % 0.05 converges at rho = 0.90), so a failed probe says nothing about
    % amplitudes below it. On failure, SHRINK toward the feasible side alo
    % instead of giving up; while expanding, never jump past a known-bad
    % amplitude -- bisect toward it. Only two outcomes end the search early:
    % the feasible interval below the failure collapses onto alo (the root
    % sits at or beyond the feasibility edge -- genuinely NO_BRACKET), or the
    % shrink budget is spent.
    %
    % The starting probe is unchanged at 0.05 by default, so a run that never
    % hits an infeasible point -- the certified decomposition run included --
    % replays the identical evaluation sequence. Callers that know roughly
    % where the root is (the frontier sweep, whose neighbouring speed's a_xi
    % is a few bisections away from this one's) pass sopts.consolidation_a0
    % and skip most of the bracketing work.
    alo = 0; klo = k0; ahi = NaN; khi = NaN; TRhi = [];
    a0 = getdef(sopts, 'consolidation_a0', 0.05);
    a  = min(max(a0, 1e-6), amax);
    a_bad = Inf;                 % smallest amplitude known to fail
    shrinks = 0;
    max_shrink = getdef(sopts, 'consolidation_maxshrink', 8);
    found = false;
    while a <= amax
        [k, TR, ok] = ev(a);
        if ~ok
            a_bad = min(a_bad, a);
            shrinks = shrinks + 1;
            if shrinks > max_shrink
                tee(['  consolidation: %d infeasible amplitudes without finding a\n' ...
                     '    feasible one above a_xi = %.6g; giving up the expansion.\n'], ...
                    shrinks, alo);
                break;
            end
            if (a - alo) <= max(1e-10, 1e-6 * max(alo, 1))
                tee(['  consolidation: the feasible interval above a_xi = %.6g has\n' ...
                     '    collapsed against infeasibility at %.6g. The root sits at\n' ...
                     '    or beyond the feasibility edge.\n'], alo, a_bad);
                break;
            end
            a = 0.5 * (alo + a);            % toward the side known to solve
            continue;
        end
        if k <= kappa_target
            ahi = a; khi = k; TRhi = TR; found = true; break;
        end
        alo = a; klo = k;
        if isfinite(a_bad)
            if (a_bad - alo) <= max(1e-10, 1e-6 * max(alo, 1))
                tee(['  consolidation: kappa is still above target at a_xi = %.6g\n' ...
                     '    and amplitudes from %.6g up are infeasible. No feasible\n' ...
                     '    bracket exists.\n'], alo, a_bad);
                break;
            end
            a = 0.5 * (alo + a_bad);        % expand, but not past a known failure
        else
            a = a * 2;
        end
    end
    if ~found
        R.status = 'NO_BRACKET';
        tee(['  consolidation: no a_xi <= %.3g brings kappa down to %.10f\n' ...
             '    (best reached %.10f at a_xi = %.6g). The surcharge cap binds,\n' ...
             '    the shape starts too late to retire the accumulated stock, or\n' ...
             '    feasibility ends before the target is reached.\n'], ...
            amax, kappa_target, klo, alo);
        R = finish(R, A, K, OKV); return;
    end

    % ---- bisection on a decreasing residual ------------------------------
    % ahi is the SEARCH bound; ahi_rep is the amplitude that actually
    % produced (khi, TRhi). They separate at an infeasible interior point:
    % that shrinks the search bound but must not relabel the stored solution
    % with an amplitude that is known NOT to solve. Reporting R.a_xi = ahi
    % after such a step would hand the caller a triple whose a_xi does not
    % produce its own kappa_inf.
    ahi_rep = ahi;
    for i = 1:maxit
        am = 0.5*(alo + ahi);
        [km, TRm, okm] = ev(am);
        if ~okm
            % An infeasible interior point is not a sign; shrink toward the
            % side known to solve rather than treating NaN as a value.
            ahi = am; continue;
        end
        if gapf(km) < acc
            R.a_xi = am; R.kappa_inf = km; R.TR = TRm;
            R.gap = gapf(km); R.hit = true; R.status = 'OK';
            R = finish(R, A, K, OKV); return;
        end
        if km > kappa_target
            alo = am; klo = km;
        else
            ahi = am; khi = km; TRhi = TRm; ahi_rep = am;
        end
        if (ahi - alo) < 1e-12 * max(1, ahi), break; end
    end

    R.a_xi = ahi_rep; R.kappa_inf = khi; R.TR = TRhi;
    R.gap = gapf(khi); R.hit = R.gap < acc;
    R.status = ternstr(R.hit, 'OK', 'NOT_CONVERGED');
    tee('  consolidation: a_xi = %.10g, kappa_inf = %.10f, gap %.2e (%s)\n', ...
        R.a_xi, R.kappa_inf, R.gap, R.status);
    tee('    stopping rule: %s\n', R.gap_rule);
    R = finish(R, A, K, OKV);
end

% ---------------------------------------------------------------------
function R = finish(R, A, K, OKV)
% Keep EVERY evaluation, including the failed ones. A discarded infeasible
% amplitude is exactly the information needed to tell "the surcharge cannot
% reach the target" from "the solver fell over on the way".
    R.trace = struct('a', A, 'kappa', K, 'ok', logical(OKV));
end

function v = getdef(s, f, dv)
    if isstruct(s) && isfield(s, f) && ~isempty(s.(f)), v = s.(f); else, v = dv; end
end

function s = ternstr(c, a, b)
    if c, s = a; else, s = b; end
end
