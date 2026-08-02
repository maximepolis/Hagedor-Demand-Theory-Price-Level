function eq = solve_own_kv(rb, d, D, g, use_levy, Bnom, Kbar, iota, p, q_ref, verbose, qwin)
% MOVED, NOT COPIED, round 10 (decision D10).
%
% This function was a local function of main_twoasset_ownership_kv.m. Track B
% of the two-asset certification protocol must recalibrate on every grid, and
% a local function cannot be called from anywhere else -- so the alternative
% was a second calibration implementation. That is exactly the defect this
% round exists to prevent: two implementations of one object drift, and the
% drift is silent because both "work".
%
% The body below is the original, moved verbatim. The calling script now calls
% this file. Any change here changes the paper's calibration.
% (P, q, tau, div) equilibrium with the KV household + intermediation wedge.
% q-bracket anchored on q_ref (the known frictionless-ownership tree price);
% expands adaptively if the tree market does not bracket on the first pass.
    if nargin < 11 || isempty(q_ref), q_ref = d/max(rb,5e-3); end
    if nargin < 12 || isempty(verbose), verbose = false; end
    % qwin: relative [lo hi] multipliers on q_ref for the initial tree-price
    % bracket. The BASELINE searches wide (the level is unknown); a FINANCING
    % EXPERIMENT is a small perturbation of a known baseline, so it searches
    % tight. Searching wide there let the bisection settle on a DIFFERENT
    % root: the zeta=1 experiments returned q = 1.56 against a baseline of
    % 3.42, and the KMV/phi=0.25 experiments returned the SAME q for lump-sum
    % and levy -- both branch jumps, not economics.
    if nargin < 13 || isempty(qwin), qwin = [0.55 1.80]; end
    lastwhy = '';                                % last failure reason (nested)
    eq = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'tau',NaN, ...
                'div',NaN,'dist',[],'bch',[],'kch',[],'n_infeas',0,'min_c',NaN, ...
                'ksat',NaN);
    pe = p; pe.eGrid = (1 - D) * p.eGrid;
    if use_levy, pe.eGrid = (1 - g/(1-D)) * pe.eGrid; end
    tau = rb*1.10 + (~use_levy)*g;
    div = d + rb*(1-iota)*1.10/Kbar;
    Vc = [];
    lo = qwin(1)*q_ref; hi = qwin(2)*q_ref; qs = linspace(lo, hi, 6); fq = nan(size(qs));
    for i = 1:numel(qs), [fq(i), tau, div, ~, Vc] = evq(qs(i), tau, div, Vc); end
    kk = bracket_finite(fq);
    for expand = 1:3                             % adaptive bracket expansion
        if ~isempty(kk), break; end
        lo = 0.5*lo; hi = 1.6*hi; qs = linspace(lo, hi, 7); fq = nan(size(qs));
        for i = 1:numel(qs), [fq(i), tau, div, ~, Vc] = evq(qs(i), tau, div, Vc); end
        kk = bracket_finite(fq);
    end
    if verbose
        fprintf('    q-scan: q=%s\n              Sk-K=%s\n', ...
            mat2str(qs,3), mat2str(fq,3));
    end
    if isempty(kk)
        nfin = sum(isfinite(fq));
        eq.msg = sprintf('no q bracket (%d/%d finite; Sk-K in [%+.3f,%+.3f]; last fail: %s)', ...
            nfin, numel(fq), min(fq), max(fq), lastwhy);
        return;
    end
    a = qs(kk(1)); b = qs(kk(2)); fa = fq(kk(1)); m = a; Sb = NaN; ninf = 0; mc = NaN; ksat = NaN;
    for it = 1:26
        m = 0.5*(a+b);
        [fm, tau, div, Sb, Vc, dist, bch, kch, ninf, mc, ksat] = evq(m, tau, div, Vc);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 5e-4 || (b-a) < 2e-4*q_ref, break; end
        if sign(fm) == sign(fa), a = m; fa = fm; else, b = m; end
    end
    if ~isfinite(Sb) || Sb <= 0, eq.msg = 'non-finite end'; return; end
    eq.ok = true; eq.q = m; eq.Sb = Sb; eq.tau = tau; eq.div = div;
    eq.P = iota*Bnom/Sb; eq.dist = dist; eq.bch = bch; eq.kch = kch;
    eq.n_infeas = ninf; eq.min_c = mc; eq.ksat = ksat;

    function [f, tt, dv, Sb, Vc, dist, bch, kch, ninf, mc, ksat] = evq(qq, tinit, dvinit, Vc)
        tt = tinit; dv = dvinit; Sb = NaN; Sk = NaN; rprev = NaN;
        dist = []; bch = []; kch = []; ninf = 0; mc = NaN; ksat = NaN;
        pev = pe;                                % capped sweeps when warm
        if ~isempty(Vc), pev.maxit_vfi = 250; end
        for itt = 1:10
            [sol, dg] = solve_household_twoasset_kv(rb, qq, dv, tt, pev, Vc);
            if ~dg.converged && ~isempty(Vc)
                % the warm start may be poisoned by a distant trial q -- retry
                % ONCE from the analytic cold init before giving up.
                pcold = pev; pcold.maxit_vfi = max(pev.maxit_vfi, 400);
                [sol, dg] = solve_household_twoasset_kv(rb, qq, dv, tt, pcold, []);
            end
            Vc = sol.V;                          % KEEP progress even on failure
            if ~dg.converged
                f = NaN;
                lastwhy = sprintf('household dV=%.1e after %d sweeps', dg.supnorm, dg.iters);
                return;
            end
            [dist, dd] = stationary_distribution_twoasset_kv(sol, rb, qq, dv, tt, pev);
            if ~dd.converged
                f = NaN;
                lastwhy = sprintf('distribution dv=%.1e after %d iters', dd.supnorm, dd.iters);
                return;
            end
            if isfield(dg,'n_infeas'), ninf = dg.n_infeas; end
            msk = dist(:) > 1e-8;                 % min consumption on the support
            if any(msk), cc = sol.polCn(:); mc = min(cc(msk)); end
            % k-grid saturation: with retained dividends the non-adjuster's k
            % drifts UP, so mass can pile against kGrid(end) and make the
            % tree aggregate grid-dependent. Report the share at the top two
            % nodes; a non-trivial value means kmax must be raised.
            kmass = squeeze(sum(sum(dist, 1), 3)); kmass = kmass(:);
            ksat = sum(kmass(max(1,end-1):end)) / max(sum(kmass), eps);
            [Sb, Sk, bch, kch] = kv_agg(sol, dist, rb, qq, dv, tt, pe);
            P = iota*Bnom/max(Sb, 1e-9);
            tgt_tau = rb*(Bnom/P) + (~use_levy)*g;
            tgt_div = d + rb*(1-iota)*(Bnom/P)/Kbar;
            r1 = tgt_tau - tt;
            if abs(r1) < 1e-6 && abs(tgt_div - dv) < 1e-6, break; end
            if isfinite(rprev) && sign(r1)~=sign(rprev) && abs(r1)>abs(rprev)
                tt = 0.5*(tt + tgt_tau);
            else
                tt = tgt_tau;
            end
            dv = tgt_div; rprev = r1;
        end
        f = Sk - Kbar;
    end
end

