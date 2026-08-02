function SA = decompose_safe_asset_channel(pgc, r, B, Gg_nom, D0, Pspan)
% DECOMPOSE_SAFE_ASSET_CHANNEL  Why does the price level move when the green
% program is introduced? (Editorial-roadmap Step 4; paper Section "safe-asset
% channel".)
%
% The program changes THREE things households care about -- the tax burden,
% the damage level/incidence on endowments, and (if phi_D > 0) the level of
% idiosyncratic income risk -- plus the FINANCING INSTRUMENT. Each shifts
% aggregate asset demand S and hence the market-clearing price level
% P* = B/S(1+r). This function isolates them by solving COUNTERFACTUAL
% general-equilibrium price levels in which only one margin is switched on:
%
%   N0 BASELINE   g=0,        D=D0                              -> P0
%   N1 PROGRAM    g=Gg/P,     D=D1(g),   lump-sum tau=rb+g      -> P1
%   N2 TAX-ONLY   g=Gg/P,     D=D0 FIXED (cost, no benefits)    -> P_tax
%   N3 DAMAGE     g=0,        D=D1* level/incidence, risk at D0 -> P_dam
%   N4 RISK       g=0,        D=D0 level, risk at D1*           -> P_risk
%   N5 LEVY       g=Gg/P,     D=D1(g),   levy vartheta, tau=rb  -> P_levy
%
% (D1* is the damage level at the N1 equilibrium; the risk split uses the
% pg.D_risk override in S_green.) Log contributions:
%   ln P1 - ln P0 = [tax] + [damage level/incidence] + [risk] + interaction,
% with each bracket = ln P_cf - ln P0 and the interaction reported as the
% residual -- an exact accounting, no approximation hidden. The financing
% contribution is ln P_levy - ln P1 (instrument swap at the same program).
%
% Every node is a WELL-POSED economy (its own government budget identity
% holds; solve_regime_equilibrium checks it), so no node relies on
% off-equilibrium objects. Partial-equilibrium S values at fixed (tau, D)
% nodes are also reported for the referee who wants the raw asset-demand
% shifts.
%
% INPUTS: pgc (calibrated params, climate fields set), r, B (nominal debt),
%         Gg_nom (nominal program), D0 (no-program damages), Pspan.
% OUTPUT: SA struct with nodes, contributions, PE table, .ok, .msg.
%
% STATUS: machinery IMPLEMENTED; numbers are results only once run.

    SA = struct('ok', false, 'msg', '');
    g_of  = @(P) Gg_nom ./ P;
    rb_of = @(P) r * B ./ P;
    D1_of = @(P) climate_block(g_of(P), pgc);

    % ---- N0 baseline ----
    reg0 = struct('name','N0-BASELINE','Bnom',B, 'g',@(P) 0*P, ...
        'D',@(P) 0*P + D0, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
    [eq0, o0] = solve_regime_equilibrium(pgc, reg0, r, Pspan);
    if isempty(eq0), SA.msg = ['N0: ' o0.msg]; return; end
    fprintf('  %s\n', o0.msg);

    % ---- N1 full program (lump-sum / deficit benchmark) ----
    reg1 = struct('name','N1-PROGRAM','Bnom',B, 'g',g_of, ...
        'D',D1_of, 'tau_ls',@(P) rb_of(P) + g_of(P), 'vartheta',@(P) 0);
    [eq1, o1] = solve_regime_equilibrium(pgc, reg1, r, Pspan);
    if isempty(eq1), SA.msg = ['N1: ' o1.msg]; return; end
    fprintf('  %s\n', o1.msg);
    D1star = eq1.D;

    % ---- N2 tax burden only (program cost, no climate benefits) ----
    reg2 = struct('name','N2-TAX-ONLY','Bnom',B, 'g',g_of, ...
        'D',@(P) 0*P + D0, 'tau_ls',@(P) rb_of(P) + g_of(P), 'vartheta',@(P) 0);
    [eq2, o2] = solve_regime_equilibrium(pgc, reg2, r, Pspan);
    fprintf('  %s\n', o2.msg);

    % ---- N3 damage level/incidence only (risk held at D0) ----
    pg3 = pgc; pg3.D_risk = D0;
    reg3 = struct('name','N3-DAMAGE','Bnom',B, 'g',@(P) 0*P, ...
        'D',@(P) 0*P + D1star, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
    [eq3, o3] = solve_regime_equilibrium(pg3, reg3, r, Pspan);
    fprintf('  %s\n', o3.msg);

    % ---- N4 risk only (level/incidence held at D0) ----
    eq4 = []; o4 = struct('msg','N4-RISK: skipped (phi_D = 0, channel inactive)');
    if pgc.phi_D > 0
        pg4 = pgc; pg4.D_risk = D1star;
        reg4 = struct('name','N4-RISK','Bnom',B, 'g',@(P) 0*P, ...
            'D',@(P) 0*P + D0, 'tau_ls',@(P) rb_of(P), 'vartheta',@(P) 0);
        [eq4, o4] = solve_regime_equilibrium(pg4, reg4, r, Pspan);
    end
    fprintf('  %s\n', o4.msg);

    % ---- N5 same program, levy-financed (instrument swap) ----
    reg5 = struct('name','N5-LEVY','Bnom',B, 'g',g_of, ...
        'D',D1_of, 'tau_ls',@(P) rb_of(P), ...
        'vartheta',@(P) g_of(P) ./ (1 - D1_of(P)));
    [eq5, o5] = solve_regime_equilibrium(pgc, reg5, r, Pspan);
    fprintf('  %s\n', o5.msg);

    % ---- log contributions (exact accounting; interaction = residual) ----
    lp   = @(eq) log(eq.P);
    tot  = lp(eq1) - lp(eq0);
    ctax = iff(~isempty(eq2), @() lp(eq2)-lp(eq0), NaN);
    cdam = iff(~isempty(eq3), @() lp(eq3)-lp(eq0), NaN);
    crsk = iff(~isempty(eq4), @() lp(eq4)-lp(eq0), 0);   % 0 if channel off
    cint = tot - (ctax + cdam + crsk);
    cfin = iff(~isempty(eq5), @() lp(eq5)-lp(eq1), NaN);

    % ---- partial-equilibrium S at fixed (tau, D) nodes ----
    tau0 = eq0.tau_ls; g1 = eq1.g; tau1 = tau0 + g1;
    PE = struct();
    PE.S_tau0_D0 = S_green(r, tau0, D0, pgc);
    PE.S_tau1_D0 = S_green(r, tau1, D0, pgc);
    pgl = pgc; pgl.D_risk = D0;
    PE.S_tau0_D1level = S_green(r, tau0, D1star, pgl);
    if pgc.phi_D > 0
        pgr = pgc; pgr.D_risk = D1star;
        PE.S_tau0_D1risk = S_green(r, tau0, D0, pgr);
    else
        PE.S_tau0_D1risk = PE.S_tau0_D0;
    end
    PE.S_tau1_D1 = S_green(r, tau1, D1star, pgc);

    SA.ok   = true;
    SA.eq0 = eq0; SA.eq1 = eq1; SA.eq2 = eq2; SA.eq3 = eq3;
    SA.eq4 = eq4; SA.eq5 = eq5;
    SA.D1star = D1star;
    SA.dlnP_total    = tot;
    SA.c_tax         = ctax;
    SA.c_damage      = cdam;
    SA.c_risk        = crsk;
    SA.c_interaction = cint;
    SA.c_financing   = cfin;
    SA.PE = PE;
    SA.msg = sprintf(['dlnP = %+.4f = tax %+.4f + damage %+.4f + risk %+.4f ' ...
        '+ interaction %+.4f; financing swap (levy vs lump-sum) %+.4f'], ...
        tot, ctax, cdam, crsk, cint, cfin);
end

% -------------------------------------------------------------------------
function v = iff(cond, fthen, velse)
    if cond, v = fthen(); else, v = velse; end
end
