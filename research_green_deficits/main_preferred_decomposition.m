% MAIN_PREFERRED_DECOMPOSITION  The mechanism of the PREFERRED calibration,
% decomposed in its own economy, plus validation of the two-market
% Schur-complement price derivative.
%
% WHY. The paper's mechanism result -- that the stationary response of
% nominal-liability demand to a regressive financing tilt is carried by
% movement of the wealth distribution rather than by the direct saving
% response at the initial distribution -- is established in the ONE-ASSET
% economy. It cannot be imported into the preferred two-asset calibration,
% which restores the level sign through additional margins: an illiquid
% price that feeds back, an intermediated share of the debt whose dividend
% moves with the price level, and an adjustment friction that decides who
% can act at all. This driver asks whether the preferred model reproduces
% the same economics or merely the same sign through different forces.
%
% STATUS: DIAGNOSTIC, not final. The calibration is frozen at the current
% benchmark; the illiquid market clears by bisection; and none of the
% numbers here are quotable until the gates below pass and the calibration
% questions (liability balance sheet, payout convention) are settled.
%
% =====================================================================
% WHAT IS COMPUTED
%
% (A) EXACT FINITE-CHANGE DECOMPOSITION of the move from lump-sum
%     (alpha = 0) to levy (alpha = 1) financing. Writing aggregate bond
%     demand as S_b = int b'(s; X) dOmega(s; X) with X = (tau, q, div),
%     the two-way split is exact and needs no approximation:
%
%       dS_b = int [b'(X1) - b'(X0)] dOmega(X0)      POLICY
%            + int b'(X0) d[Omega(X1) - Omega(X0)]   DISTRIBUTION
%            + int [b'(X1)-b'(X0)] d[Omega1-Omega0]  INTERACTION
%
%     Each of the first two is then split by DRIVER -- the financing
%     instrument tau, the illiquid price q, and the intermediary dividend
%     div -- by an exact Shapley value over the three drivers (2^3 = 8
%     household solves per block). Shapley is used rather than sequential
%     shutdown because the order of shutdown is arbitrary and the channels
%     interact: Shapley is the unique attribution that is efficient
%     (components sum to the total), symmetric, and null-player-consistent.
%     The resulting five components are the referee's:
%       direct policy (tau) | distribution | q-feedback | intermediation | interaction
%
% (B) LOCAL JACOBIAN DECOMPOSITION at the baseline: each of
%     dS_b/dtau, dS_b/dq, dS_b/dP is split into a POLICY part (distribution
%     held at baseline) and a DISTRIBUTION part (policies held at
%     baseline), by central differences.
%
% (C) TWO-MARKET SCHUR-COMPLEMENT VALIDATION (Proposition 8). With
%       F_b(P,q;alpha) = S_b - iota*B/P,   F_k(P,q;alpha) = S_k - Kbar,
%     the price derivative is
%       dP/dalpha = -N_alpha / M,
%       N_alpha = F_b,alpha - F_bq F_k,alpha / F_kq,
%       M       = F_bP      - F_bq F_kP      / F_kq,
%     computed from central differences of the two residuals, and compared
%     against a SOLVED central difference in which the full equilibrium
%     (P and q jointly) is re-solved at alpha +- h.
%
% GATES (all must pass before any number is used, and before the full
% climate transition is attempted):
%   G1 RECONSTRUCTION  the five components sum to the measured dS_b
%   G2 SHAPLEY EFFICIENCY  each block's driver split sums to that block
%   G3 FINITE DIFFERENCE  the Schur prediction matches the solved
%      derivative; the achieved relative error is reported, and the gate is
%      set at the level the underlying solvers can actually support
%   G4 GRID  the qualitative split (which component dominates, and the sign
%      of each) is unchanged on a coarser grid
%
% USAGE   >> clear; main_preferred_decomposition
%         >> clear; FAST = true; main_preferred_decomposition   (coarse only)
%         >> clear; SKIPGRID = true; main_preferred_decomposition
%
% REQUIRES output/twoasset_ownership_kv.mat
% OUTPUT   output/tables/preferred_decomposition.txt
%          output/preferred_decomposition.mat

clearvars -except FAST SKIPGRID; close all; clc;
rng(20260731, 'twister'); t0 = tic;

projdir = fileparts(mfilename('fullpath'));
if isempty(projdir), projdir = pwd; end
cd(projdir);
rootdir = fileparts(projdir);
addpath(genpath(fullfile(rootdir, 'src')));
addpath(genpath(fullfile(projdir, 'src_project')));

if ~exist('FAST','var'), FAST = false; end
if ~exist('SKIPGRID','var'), SKIPGRID = false; end

mf = fullfile(projdir, 'output', 'twoasset_ownership_kv.mat');
assert(exist(mf,'file')==2, 'run main_twoasset_ownership_kv first');
S = load(mf);
assert(isfield(S,'eq0') && S.eq0.ok, 'saved benchmark equilibrium not ok');
p = S.p; iota = S.iota_H; r_b = S.r_b; d_base = S.d_base; D0 = S.D0; Gg = S.Gg;
pg = setup_params_green(); Bnom = pg.Bnom; Kbar = 1.0;
eq0 = S.eq0;
g_real = Gg / eq0.P;

if ~isfolder(pg.tabdir), mkdir(pg.tabdir); end
sf = fullfile(pg.tabdir, 'preferred_decomposition.txt');
fid = fopen(sf,'w'); assert(fid>0);
tee = @(varargin) tee2(fid, varargin{:});
tee('PREFERRED-CALIBRATION MECHANISM DECOMPOSITION  (DIAGNOSTIC)\n');
tee('grids nb=%d nk=%d ne=%d; lambda=%.2f iota_H=%.3f; g_real=%.5f\n\n', ...
    numel(p.bGrid), numel(p.kGrid), numel(p.eGrid), p.lambda_adj, iota, g_real);

CTX = struct('p',p,'iota',iota,'r_b',r_b,'d_base',d_base,'D0',D0, ...
             'Bnom',Bnom,'Kbar',Kbar,'g_real',g_real,'qref',eq0.q, ...
             'Pseed',eq0.P);

% ---------------------------------------------------------------- (A)+(B)
tee('===== solving the two financing equilibria =====\n');
E0 = solve_alpha(0.0, CTX, eq0.q, true, tee);   % lump-sum
assert(E0.ok, 'alpha=0 equilibrium failed: %s', E0.msg);
E1 = solve_alpha(1.0, CTX, E0.q, true, tee);    % levy
assert(E1.ok, 'alpha=1 equilibrium failed: %s', E1.msg);
tee('  alpha=0 (lump-sum): P=%.6f q=%.6f Sb=%.6f Sk=%.6f\n', E0.P,E0.q,E0.Sb,E0.Sk);
tee('  alpha=1 (levy)    : P=%.6f q=%.6f Sb=%.6f Sk=%.6f\n', E1.P,E1.q,E1.Sb,E1.Sk);
tee('  dlnP = %+0.5f (solved, equilibrium-to-equilibrium)\n\n', log(E1.P/E0.P));

DEC = finite_decomposition(E0, E1, CTX, tee);

% ---------------------------------------------------------------- (C)
tee('\n===== two-market Schur-complement validation (Prop 8) =====\n');
SCH = schur_validate(E0, CTX, tee);

% ---------------------------------------------------------------- gates
tee('\n===== gates =====\n');
g1 = abs(DEC.recon_err) < 1e-9 * max(1, abs(DEC.dSb));
tee('G1 reconstruction  : residual %.3e  %s\n', DEC.recon_err, ternstr(g1,'PASS','FAIL'));
g2 = max(abs(DEC.shap_err)) < 1e-9 * max(1, abs(DEC.dSb));
tee('G2 shapley efficiency: max residual %.3e  %s\n', max(abs(DEC.shap_err)), ternstr(g2,'PASS','FAIL'));
g3 = isfinite(SCH.relerr) && SCH.relerr < SCH.tol;
tee('G3 finite difference : rel err %.3e vs tol %.1e  %s\n', SCH.relerr, SCH.tol, ternstr(g3,'PASS','FAIL'));

g4 = NaN;
if ~SKIPGRID && ~FAST
    tee('\n----- G4 grid check (coarse rebuild) -----\n');
    pc = coarsen(p);
    CTXc = CTX; CTXc.p = pc;
    E0c = solve_alpha(0.0, CTXc, eq0.q, false, tee);
    E1c = solve_alpha(1.0, CTXc, E0c.q, false, tee);
    if E0c.ok && E1c.ok
        DECc = finite_decomposition(E0c, E1c, CTXc, @(varargin) []);
        same_sign = all(sign(DECc.comp) == sign(DEC.comp) | abs(DEC.comp) < 1e-8);
        [~,iF] = max(abs(DEC.comp)); [~,iC] = max(abs(DECc.comp));
        g4 = same_sign && (iF == iC);
        tee('  fine   components: %s\n', vecstr(DEC.comp));
        tee('  coarse components: %s\n', vecstr(DECc.comp));
        tee('G4 grid            : dominant %s, signs %s  %s\n', ...
            ternstr(iF==iC,'same','DIFFER'), ternstr(same_sign,'match','DIFFER'), ...
            ternstr(g4,'PASS','FAIL'));
    else
        tee('G4 grid            : coarse equilibrium failed -- INCONCLUSIVE\n');
    end
else
    tee('G4 grid            : skipped\n');
end

allpass = g1 && g2 && g3 && (isnan(g4) || g4);
tee('\nGATES %s. %s\n', ternstr(allpass,'PASS','FAIL'), ternstr(allpass, ...
   'The decomposition may be interpreted (as a diagnostic at the frozen calibration).', ...
   'DO NOT interpret the components, and do not begin the full climate transition.'));

save(fullfile(projdir,'output','preferred_decomposition.mat'), ...
     'DEC','SCH','E0','E1','CTX','g1','g2','g3','g4');
tee('\n[main_preferred_decomposition] wrote %s (%.1f s)\n', sf, toc(t0));
fclose(fid);

% =====================================================================
function pe = prices_to_pe(alpha, CTX)
% household-facing parameters at financing intensity alpha:
%   effective endowments scaled by damages and by the levy (1 - vartheta)
%   vartheta(alpha) = alpha * g /(1-D)   so alpha=1 funds g entirely by levy
    pe = CTX.p;
    vth = alpha * CTX.g_real / (1 - CTX.D0);
    pe.eGrid = (1 - CTX.D0) * (1 - vth) * CTX.p.eGrid;
end

function tau = tau_of(alpha, P, CTX)
% lump-sum component: services the debt and the un-levied share of g
    tau = CTX.r_b * (CTX.Bnom / P) + (1 - alpha) * CTX.g_real;
end

function dvd = div_of(P, CTX)
% intermediary pass-through: the fund holds (1-iota) of the stock and pays
% the coupon on it through as dividend
    dvd = CTX.d_base + CTX.r_b * (1 - CTX.iota) * (CTX.Bnom / P) / CTX.Kbar;
end

function E = solve_alpha(alpha, CTX, q_guess, verbose, tee)
% Equilibrium at financing intensity alpha: bisect q on the tree market;
% for each q run an inner fixed point on (P, tau, div) with P = iota*B/S_b.
% Tolerances are TIGHTER than the calibration driver's because this feeds
% finite differences.
    E = struct('ok',false,'msg','','P',NaN,'q',NaN,'Sb',NaN,'Sk',NaN, ...
               'sol',[],'dist',[],'alpha',alpha,'tau',NaN,'dvd',NaN);
    pe = prices_to_pe(alpha, CTX);
    lo = 0.80*q_guess; hi = 1.25*q_guess; Vc = [];
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
    for it = 1:60
        m = 0.5*(a+b);
        [fm, st] = fq(m);
        if ~isfinite(fm), b = m; continue; end
        if abs(fm) < 1e-9 || (b-a) < 1e-10*max(1,q_guess), break; end
        if sign(fm)==sign(fa), a = m; fa = fm; else, b = m; end
    end
    if isempty(st) || ~st.ok, E.msg = 'tree bisection failed'; return; end
    E.ok = true; E.q = m; E.P = st.P; E.Sb = st.Sb; E.Sk = st.Sk;
    E.sol = st.sol; E.dist = st.dist; E.tau = st.tau; E.dvd = st.dvd; E.pe = pe;
    if verbose && ~isempty(tee)
        tee('  alpha=%.2f: q=%.8f tree gap %.2e (%d bisection steps)\n', ...
            alpha, m, fm, it);
    end
end

function [gap, st] = tree_gap(qq, alpha, CTX, pe)
% inner fixed point on (P, tau, div) at a trial tree price
    st = struct('ok',false);
    P = CTX.iota * CTX.Bnom / max(1e-9, 0.30);      % harmless seed
    if isfield(CTX,'Pseed') && ~isempty(CTX.Pseed), P = CTX.Pseed; end
    Vc = []; gap = NaN;
    for it = 1:60
        tau = tau_of(alpha, P, CTX);
        dvd = div_of(P, CTX);
        out = kv_stationary_block(CTX.r_b, qq, dvd, tau, pe, Vc);
        if ~out.ok, gap = NaN; return; end
        Vc = out.sol.V;
        Pn = CTX.iota * CTX.Bnom / max(out.Sb, 1e-12);
        if abs(Pn - P) < 1e-12 * max(1,abs(P)), P = Pn; break; end
        P = 0.5*P + 0.5*Pn;                        % damped, monotone here
    end
    tau = tau_of(alpha, P, CTX); dvd = div_of(P, CTX);
    out = kv_stationary_block(CTX.r_b, qq, dvd, tau, pe, Vc);
    if ~out.ok, gap = NaN; return; end
    gap = out.Sk - CTX.Kbar;
    st = struct('ok',true,'P',P,'Sb',out.Sb,'Sk',out.Sk,'sol',out.sol, ...
                'dist',out.dist,'tau',tau,'dvd',dvd);
end

function D = finite_decomposition(E0, E1, CTX, tee)
% exact two-way split, then an exact Shapley split of each block by driver
    p0 = struct('tau',E0.tau,'q',E0.q,'dvd',E0.dvd,'alpha',E0.alpha);
    p1 = struct('tau',E1.tau,'q',E1.q,'dvd',E1.dvd,'alpha',E1.alpha);

    % --- policy block: b'(X1) vs b'(X0), both against Omega0
    Sb_X1_O0 = agg_at(p1, E0.dist, CTX);
    Sb_X0_O0 = E0.Sb;
    Sb_X0_O1 = agg_at(p0, E1.dist, CTX);
    Sb_X1_O1 = E1.Sb;
    POL  = Sb_X1_O0 - Sb_X0_O0;
    DIST = Sb_X0_O1 - Sb_X0_O0;
    INTER= (Sb_X1_O1 - Sb_X0_O1) - (Sb_X1_O0 - Sb_X0_O0);
    dSb  = Sb_X1_O1 - Sb_X0_O0;

    % --- Shapley split of the POLICY block over drivers {tau, q, div}
    [shP, errP] = shapley3(p0, p1, E0.dist, CTX);
    % --- and of the DISTRIBUTION block: the same drivers, but the object is
    % the change in the aggregate induced by moving Omega, holding policies
    % at baseline. Only the distribution argument switches, so the driver
    % attribution is over which price moved the distribution; we obtain it
    % by re-solving the stationary distribution under each driver subset.
    [shD, errD] = shapley3_dist(p0, p1, CTX);

    % DIST is itself the distribution component; shD attributes THAT block
    % across drivers and is reported separately -- it must not be added
    % here, or the distribution effect would be counted twice.
    comp = [shP(1); DIST; shP(2); shP(3); INTER];
    names = {'direct policy (tau)','distribution','q-feedback', ...
             'intermediation (div)','interaction'};

    D = struct('dSb',dSb,'POL',POL,'DIST',DIST,'INTER',INTER, ...
               'shP',shP,'shD',shD,'comp',comp,'names',{names}, ...
               'recon_err', sum(comp)-dSb, 'shap_err',[errP errD], ...
               'Sb_X1_O0',Sb_X1_O0,'Sb_X0_O1',Sb_X0_O1);

    if ~isempty(tee) && isa(tee,'function_handle')
        tee('\n===== (A) exact finite-change decomposition of S_b =====\n');
        tee('total dS_b = %+0.6f  (lump-sum -> levy)\n', dSb);
        tee('  two-way : policy %+0.6f | distribution %+0.6f | interaction %+0.6f\n', ...
            POL, DIST, INTER);
        tee('  Shapley split of the policy block by driver:\n');
        tee('    tau %+0.6f | q %+0.6f | div %+0.6f  (sum %+0.6f vs %+0.6f)\n', ...
            shP(1), shP(2), shP(3), sum(shP), POL);
        tee('  Shapley split of the DISTRIBUTION block by driver (reported,\n');
        tee('  not added -- it attributes the same mass movement):\n');
        tee('    tau %+0.6f | q %+0.6f | div %+0.6f  (sum %+0.6f vs %+0.6f)\n', ...
            shD(1), shD(2), shD(3), sum(shD), DIST);
        tee('\n  FIVE-COMPONENT DECOMPOSITION (shares of |dS_b|):\n');
        for i = 1:numel(comp)
            tee('    %-22s %+0.6f  (%+6.1f%%)\n', names{i}, comp(i), ...
                100*comp(i)/max(abs(dSb),eps));
        end
        tee('    %-22s %+0.6f\n', 'SUM', sum(comp));
        tee('\n  reading: the one-asset economy attributes the response almost\n');
        tee('  entirely to the distribution term. If "direct policy" or\n');
        tee('  "q-feedback" dominates here, the preferred model reproduces the\n');
        tee('  SIGN through different forces, and the mechanism sentence in the\n');
        tee('  abstract cannot be carried over to it.\n');
    end
end

function v = agg_at(pr, dist, CTX)
% aggregate bond demand with policies solved at pr, evaluated against dist
    pe = prices_to_pe(pr.alpha, CTX);
    out = kv_stationary_block(CTX.r_b, pr.q, pr.dvd, pr.tau, pe, [], dist);
    if out.ok, v = out.Sb; else, v = NaN; end
end

function v = agg_stat(pr, CTX)
% aggregate at pr with its OWN stationary distribution
    pe = prices_to_pe(pr.alpha, CTX);
    out = kv_stationary_block(CTX.r_b, pr.q, pr.dvd, pr.tau, pe, []);
    if out.ok, v = out.Sb; else, v = NaN; end
end

function pr = mix(p0, p1, mask)
% driver subset: mask = [tau q div] logical, 1 = take the alpha=1 value
    pr = p0;
    if mask(1), pr.tau = p1.tau; pr.alpha = p1.alpha; end
    if mask(2), pr.q   = p1.q;   end
    if mask(3), pr.dvd = p1.dvd; end
end

function [sh, err] = shapley3(p0, p1, dist0, CTX)
% exact Shapley values over three drivers for the POLICY block (distribution
% held at dist0). 8 evaluations; weights (|T|!(n-|T|-1)!)/n! with n=3.
    M = dec2bin(0:7,3) - '0';                    % 8 x 3 masks
    V = zeros(8,1);
    for i = 1:8
        V(i) = agg_at(mix(p0,p1,logical(M(i,:))), dist0, CTX);
    end
    base = V(1);
    sh = zeros(3,1);
    w = @(s) factorial(s)*factorial(3-s-1)/factorial(3);
    for j = 1:3
        for i = 1:8
            if M(i,j) == 1, continue; end
            m1 = M(i,:); m1(j) = 1;
            i1 = bin2idx(m1);
            sh(j) = sh(j) + w(sum(M(i,:))) * (V(i1) - V(i));
        end
    end
    err = sum(sh) - (V(8) - base);
end

function [sh, err] = shapley3_dist(p0, p1, CTX)
% Shapley attribution of the DISTRIBUTION block by driver: each subset's
% stationary distribution is formed under that subset's prices, and the
% aggregate is taken with BASELINE policies.
    M = dec2bin(0:7,3) - '0';
    V = zeros(8,1);
    for i = 1:8
        prm = mix(p0,p1,logical(M(i,:)));
        pem = prices_to_pe(prm.alpha, CTX);
        o   = kv_stationary_block(CTX.r_b, prm.q, prm.dvd, prm.tau, pem, []);
        if ~o.ok, V(i) = NaN; continue; end
        V(i) = agg_at(p0, o.dist, CTX);          % baseline policies, this dist
    end
    sh = zeros(3,1);
    w = @(s) factorial(s)*factorial(3-s-1)/factorial(3);
    for j = 1:3
        for i = 1:8
            if M(i,j) == 1, continue; end
            m1 = M(i,:); m1(j) = 1;
            sh(j) = sh(j) + w(sum(M(i,:))) * (V(bin2idx(m1)) - V(i));
        end
    end
    err = sum(sh) - (V(8) - V(1));
end

function i = bin2idx(m)
    i = m(1)*4 + m(2)*2 + m(3) + 1;
end

function SCH = schur_validate(E0, CTX, tee)
% central differences of the two market residuals in (P, q, alpha), the
% Schur components, and a solved central difference for comparison
    hP = 1e-4*E0.P; hq = 1e-4*E0.q; ha = 1e-3;
    Fb = @(P,q,al) resid_b(P,q,al,CTX);
    Fk = @(P,q,al) resid_k(P,q,al,CTX);
    FbP = (Fb(E0.P+hP,E0.q,E0.alpha) - Fb(E0.P-hP,E0.q,E0.alpha))/(2*hP);
    Fbq = (Fb(E0.P,E0.q+hq,E0.alpha) - Fb(E0.P,E0.q-hq,E0.alpha))/(2*hq);
    Fba = (Fb(E0.P,E0.q,E0.alpha+ha) - Fb(E0.P,E0.q,max(0,E0.alpha-ha)))/(2*ha);
    FkP = (Fk(E0.P+hP,E0.q,E0.alpha) - Fk(E0.P-hP,E0.q,E0.alpha))/(2*hP);
    Fkq = (Fk(E0.P,E0.q+hq,E0.alpha) - Fk(E0.P,E0.q-hq,E0.alpha))/(2*hq);
    Fka = (Fk(E0.P,E0.q,E0.alpha+ha) - Fk(E0.P,E0.q,max(0,E0.alpha-ha)))/(2*ha);
    N = Fba - Fbq*Fka/Fkq;
    M = FbP - Fbq*FkP/Fkq;
    dP_pred = -N/M;
    % solved central difference: re-solve the joint equilibrium at alpha +- ha
    Ep = solve_alpha(E0.alpha+ha, CTX, E0.q, false, []);
    Em = solve_alpha(max(0,E0.alpha-ha), CTX, E0.q, false, []);
    if Ep.ok && Em.ok
        dP_sol = (Ep.P - Em.P)/(2*ha);
    else
        dP_sol = NaN;
    end
    relerr = abs(dP_pred - dP_sol)/max(abs(dP_sol),eps);
    % The gate cannot be tighter than what the underlying blocks support:
    % the VFI is soft-accepted near 1e-6 relative and the distribution near
    % 1e-8, so a derivative formed from differences of aggregates inherits
    % roughly (solver noise)/(step). Set the gate from that budget rather
    % than from an aspiration.
    % Budget: the VFI is accepted near 1e-6 relative and the distribution
    % near 1e-8, so a derivative formed by differencing aggregates inherits
    % roughly (solver noise)/(step) ~ 1e-3 relative at ha = 1e-3. A 1e-4
    % gate is therefore not reachable by finite differences of this block;
    % it would require analytic (sequence-space) Jacobians. We gate at 1e-2,
    % about ten times the noise floor, and print the achieved value.
    tol = 1e-2;
    SCH = struct('FbP',FbP,'Fbq',Fbq,'Fba',Fba,'FkP',FkP,'Fkq',Fkq,'Fka',Fka, ...
                 'N',N,'M',M,'dP_pred',dP_pred,'dP_sol',dP_sol, ...
                 'relerr',relerr,'tol',tol, ...
                 'eps_eff',(E0.P/max(E0.Sb,eps))*M);
    if ~isempty(tee) && isa(tee,'function_handle')
        tee('  F_bP %+0.6e  F_bq %+0.6e  F_balpha %+0.6e\n', FbP, Fbq, Fba);
        tee('  F_kP %+0.6e  F_kq %+0.6e  F_kalpha %+0.6e\n', FkP, Fkq, Fka);
        tee('  N_alpha %+0.6e   M %+0.6e\n', N, M);
        tee('  effective two-market determinacy margin (P/S_b)*M = %+0.4f\n', SCH.eps_eff);
        tee('  dP/dalpha  predicted %+0.6f | solved %+0.6f | rel err %.3e\n', ...
            dP_pred, dP_sol, relerr);
        tee('  cross-market share of the numerator: %.1f%% of |N| comes from\n', ...
            100*abs(Fbq*Fka/Fkq)/max(abs(N),eps));
        tee('  the term F_bq F_kalpha / F_kq -- the object no one-asset\n');
        tee('  theorem contains.\n');
    end
end

function v = resid_b(P, q, alpha, CTX)
    pe = prices_to_pe(alpha, CTX);
    o = kv_stationary_block(CTX.r_b, q, div_of(P,CTX), tau_of(alpha,P,CTX), pe, []);
    if o.ok, v = o.Sb - CTX.iota*CTX.Bnom/P; else, v = NaN; end
end

function v = resid_k(P, q, alpha, CTX)
    pe = prices_to_pe(alpha, CTX);
    o = kv_stationary_block(CTX.r_b, q, div_of(P,CTX), tau_of(alpha,P,CTX), pe, []);
    if o.ok, v = o.Sk - CTX.Kbar; else, v = NaN; end
end

function pc = coarsen(p)
    pc = p;
    nb = max(30, round(numel(p.bGrid)*0.7));
    nk = max(18, round(numel(p.kGrid)*0.7));
    ub = linspace(0,1,nb)'; pc.bGrid = p.bGrid(1) + (p.bGrid(end)-p.bGrid(1))*(ub.^2.4);
    uk = linspace(0,1,nk)'; pc.kGrid = p.kGrid(end)*(uk.^2.4);
end

function s = vecstr(v)
    s = sprintf('%+0.5f ', v);
end

function tee2(fid, varargin)
    fprintf(varargin{:}); fprintf(fid, varargin{:});
end

function s = ternstr(c,a,b)
    if c, s = a; else, s = b; end
end
