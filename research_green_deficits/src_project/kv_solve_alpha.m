function E = kv_solve_alpha(alpha, CTX, q_guess, verbose, tee)
% KV_SOLVE_ALPHA  Stationary equilibrium at financing intensity alpha:
% bisect q on the tree market; for each q run an inner fixed point on
% (P, tau, div) with P = iota*B/S_b. Tolerances are TIGHTER than the
% calibration driver's because this feeds finite differences.
%
% THIS SOLVER IS SERIAL AND STAYS SERIAL. The bisection is a sequential
% search -- each bracket depends on the previous evaluation -- and the inner
% (P, tau, div) fixed point and the household VFI inside it are contraction
% iterations whose whole content is that iterate k+1 reads iterate k. There
% is no independent work to spread. Parallelism in this project belongs at
% the level of INDEPENDENT equilibria (scan nodes, Shapley coalitions,
% alternative grids), each of which calls this function serially.
%
% Lifted out of main_preferred_decomposition so that a parallel worker
% solving one grid or one coalition can call it; a parfor body cannot see a
% script's local functions.
    E = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
               'sol',[],'dist',[],'alpha',alpha,'tau',NaN,'dvd',NaN);
    if nargin < 4, verbose = false; end
    if nargin < 5, tee = []; end
    pe = kv_prices_to_pe(alpha, CTX);
    lo = 0.80*q_guess; hi = 1.25*q_guess;
    fq = @(qq) tree_gap(qq, alpha, CTX, pe);
    [flo, ~] = fq(lo); [fhi, ~] = fq(hi);
    ex = 0;
    while ~(isfinite(flo) && isfinite(fhi) && sign(flo)~=sign(fhi)) && ex < 4
        lo = 0.75*lo; hi = 1.35*hi; [flo,~] = fq(lo); [fhi,~] = fq(hi); ex = ex+1;
    end
    if ~(isfinite(flo) && isfinite(fhi) && sign(flo)~=sign(fhi))
        E.msg = 'no tree bracket'; return;
    end
    a = lo; b = hi; fa = flo; st = [];
    for it = 1:45
        m = 0.5*(a+b);
        [fm, st] = fq(m);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 1e-9 || (b-a) < 1e-7*max(1,q_guess), break; end
        if sign(fm)==sign(fa), a = m; fa = fm; else, b = m; end
    end
    % POLISH. S_k(q) is a step function at fine scales, because the
    % adjuster's portfolio choice is an argmax over a discrete candidate
    % set. Bisection on a step function converges to the JUMP, where the
    % residual can remain large -- which is exactly what happened at
    % alpha = 1 (a 1.3e-3 gap after the bracket had collapsed to 1e-11).
    % Bisection cannot fix that, because there may be no exact zero. Golden
    % section on |gap| over the final bracket instead returns the closest
    % approach the discretization admits, and the achieved value is gated
    % (G0) rather than assumed.
    gr = (sqrt(5)-1)/2;
    aa = max(a - 4*(b-a), lo); bb = min(b + 4*(b-a), hi);
    c1 = bb - gr*(bb-aa); c2 = aa + gr*(bb-aa);
    [f1,s1] = fq(c1); [f2,s2] = fq(c2);
    v1 = abs(f1); v2 = abs(f2);
    if ~isfinite(v1), v1 = Inf; end
    if ~isfinite(v2), v2 = Inf; end
    for it2 = 1:40
        if v1 < v2
            bb = c2; c2 = c1; v2 = v1; s2 = s1;
            c1 = bb - gr*(bb-aa); [f1,s1] = fq(c1); v1 = abs(f1);
            if ~isfinite(v1), v1 = Inf; end
        else
            aa = c1; c1 = c2; v1 = v2; s1 = s2;
            c2 = aa + gr*(bb-aa); [f2,s2] = fq(c2); v2 = abs(f2);
            if ~isfinite(v2), v2 = Inf; end
        end
        if (bb-aa) < 1e-10*max(1,q_guess), break; end
    end
    if v1 <= v2, m = c1; else, m = c2; end
    % SINGLE FINAL-EQUILIBRIUM STRUCTURE. Everything displayed or gated is
    % recomputed HERE, once, from the chosen q. The previous version carried
    % f1/f2 alongside c1/c2 but shifted only the c and s variables inside the
    % golden-section loop, so the printed residual could belong to a
    % different q than the returned state -- which is exactly why the
    % alpha = 0 tree gap printed 8.07e-04 at solve time and 1.97e-04 when
    % recomputed in the summary. No residual is ever carried forward from an
    % intermediate evaluation again.
    [fm, st] = fq(m);
    if isempty(st) || ~st.ok || ~isfinite(fm)
        E.msg = 'tree solve failed at the finalized q'; return;
    end
    E.ok = true; E.q = m; E.P = st.P; E.Sb = st.Sb; E.Sk = st.Sk;
    E.sol = st.sol; E.dist = st.dist; E.tau = st.tau; E.dvd = st.dvd; E.pe = pe;
    % canonical residuals, computed from THIS state and nothing else
    E.Fk = st.Sk - CTX.Kbar;                       % tree market
    E.Fb = st.Sb - CTX.iota*CTX.Bnom/st.P;         % bond market
    E.mass_err = abs(1 - sum(st.dist(:)));
    kmass = squeeze(sum(sum(st.dist,1),3)); kmass = kmass(:);
    bmass = squeeze(sum(sum(st.dist,2),3)); bmass = bmass(:);
    E.ksat = sum(kmass(max(1,end-1):end))/max(sum(kmass),eps);
    E.bsat = sum(bmass(max(1,end-1):end))/max(sum(bmass),eps);
    if verbose && ~isempty(tee)
        tee(['  alpha=%.2f: q=%.8f  |Fk|=%.2e |Fb|=%.2e  mass err %.1e  ' ...
             'k-sat %.1e b-sat %.1e  (%d bisect + %d polish)\n'], ...
            alpha, m, abs(E.Fk), abs(E.Fb), E.mass_err, E.ksat, E.bsat, it, it2);
    end
end

function [gap, st] = tree_gap(qq, alpha, CTX, pe)
% inner fixed point on (P, tau, div) at a trial tree price
    st = struct('ok',false);
    P = CTX.iota * CTX.Bnom / max(1e-9, 0.30);      % harmless seed
    if isfield(CTX,'Pseed') && ~isempty(CTX.Pseed), P = CTX.Pseed; end
    Vc = []; gap = NaN;
    for it = 1:60
        tau = kv_tau_of(alpha, P, CTX);
        dvd = kv_div_of(P, CTX);
        out = kv_stationary_block(CTX.r_b, qq, dvd, tau, pe, Vc);
        if ~out.ok, gap = NaN; return; end
        Vc = out.sol.V;
        Pn = CTX.iota * CTX.Bnom / max(out.Sb, 1e-12);
        if abs(Pn - P) < 1e-12 * max(1,abs(P)), P = Pn; break; end
        P = 0.5*P + 0.5*Pn;                        % damped, monotone here
    end
    tau = kv_tau_of(alpha, P, CTX); dvd = kv_div_of(P, CTX);
    out = kv_stationary_block(CTX.r_b, qq, dvd, tau, pe, Vc);
    if ~out.ok, gap = NaN; return; end
    gap = out.Sk - CTX.Kbar;
    st = struct('ok',true,'P',P,'Sb',out.Sb,'Sk',out.Sk,'sol',out.sol, ...
                'dist',out.dist,'tau',tau,'dvd',dvd);
end
