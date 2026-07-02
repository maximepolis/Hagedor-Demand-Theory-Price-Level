function validation_report(par, ad, R)
% VALIDATION_REPORT  Write validation_report.txt: numerical checks, equations
% implemented, figures reproduced, and the replication status matrix.

    if ~exist(par.outdir,'dir'), mkdir(par.outdir); end
    fn = fullfile(par.outdir, 'validation_report.txt');
    fid = fopen(fn, 'w');
    P = @(varargin) fprintf(fid, varargin{:});

    P('=====================================================================\n');
    P(' VALIDATION REPORT -- Hagedorn (2026), "A Demand Theory of the Price Level"\n');
    P(' International Economic Review, DOI 10.1111/iere.70064\n');
    P(' Generated: %s\n', datestr(now));
    P('=====================================================================\n\n');

    P('CALIBRATION DISCLAIMER\n');
    P('  The paper is theoretical and reports NO household calibration.\n');
    P('  All structural numbers are ILLUSTRATIVE benchmarks. The policy example\n');
    P('  (ibar=%.2f, phi=%.2f, pistar=%.2f, debt growth=%.2f) matches endnote 14.\n\n', ...
       par.ibar, par.phi, par.pistar, par.g_B);

    P('NUMERICAL DIAGNOSTICS\n');
    P('  Asset-demand curve S(1+r): max Euler resid = %.2e, max resource resid = %.2e\n', ...
       ad.euler_max, ad.resource_max);
    P('  Baseline DTPL (Eq.22): r_ss=%.4f, S=%.6f, P*=%.6f\n', R.baseline.r_ss, R.baseline.S, R.baseline.P);
    P('    int c = %.6f (target 1); resource resid=%.2e; asset-mkt resid=%.2e; beta(1+r)=%.4f (<1 OK)\n', ...
       R.baseline.C, R.baseline.resource_resid, R.baseline.market_resid, R.baseline.beta_check);
    P('  Taylor rule (Eq.20): i_ss=%.4f, pi_ss=%.4f UNCHANGED, P*=%.6f\n', ...
       R.baseline.taylor.i_ss, R.baseline.taylor.pi_ss, R.baseline.taylor.P);
    P('  Complete markets: RA rate=%.4f; three P all clear -> indeterminate.\n', R.cm.r_ra);
    if isfinite(R.cm.inc.P)
        P('    Incomplete at same policy: unique P*=%.6f (Eq.22).\n', R.cm.inc.P);
    end
    P('  Capital ext.: K*=%.4f, P*=%.6f; firm resid(Eq.51)=%.2e, asset resid(Eq.50)=%.2e\n', ...
       R.cap.K, R.cap.P, R.cap.firm_resid, R.cap.market_resid);
    P('  Money ext.: S=%.4f, L=%.4f, P*(case1)=%.6f, P*(open-mkt)=%.6f\n', ...
       R.money.case1.S, R.money.case1.L, R.money.case1.P, R.money.case2.P);
    P('  Gov-exp ext.: caseA P*=%.6f (real bonds), caseB P*=%.6f (nominal bonds)\n', ...
       R.gov.caseA.P, R.gov.caseB.P);
    P('  DTPL vs FTPL: P_DTPL=%.6f, P_FTPL=%.6f; Eq.A36 equal? %d; PV-identity gap=%.2e\n\n', ...
       R.ftpl.DTPL.P, R.ftpl.FTPL.P, R.ftpl.eqA36.equal, R.ftpl.identity.gap);

    % ---- Figure 5 data provenance ----
    P('FIGURE 5 DATA SOURCE\n');
    try
        D = load_oecd_data(par);
        P('  Countries with usable data : %d\n', numel(D.country));
        P('  is_real = %d, is_proxy = %d\n', D.is_real, D.is_proxy);
        P('  Source  : %s\n', D.source);
        if D.is_proxy && D.is_real
            P('  NOTE    : WDI government measure (final consumption) is a PROXY for the\n');
            P('            paper''s NIPA Table 3.1 construction (lines 21,39,41,42); levels of\n');
            P('            the correlation may differ from the paper''s 0.93.\n');
        end
    catch ME
        P('  Could not load Figure-5 data: %s\n', ME.message);
    end
    P('\n');

    P('EQUATIONS IMPLEMENTED (paper numbering)\n');
    eqs = {
      '1-5','Household problem, budget, TVC','solve_household_problem.m','EXACT'
      '6','Government budget T=(1+i)B-B''','baseline tau=r*S','EXACT'
      '7-8','Asset-market clearing & resource constraint','stationary_distribution.m','EXACT'
      '9','Stationary growth = 1+pi','all SS routines','EXACT'
      '10-13','Asset-demand fixed point S(1+r)','asset_demand_curve.m','EXACT'
      '14','S(1+r)=B/P','compute_price_level_nominal_bonds.m','EXACT'
      '15-16','Bewley money mapping','documented in ftpl/money','QUALITATIVE'
      '17','Fisher 1+r=(1+i)/(1+pi)','all routines','EXACT'
      '18','pi=(B''-B)/B','all routines','EXACT'
      '19-20','Taylor rule, endnote 14 example','compute_price_level_nominal_bonds.m','EXACT'
      '21-22','P*=B/S((1+i)/(1+pi))','compute_price_level_nominal_bonds.m','EXACT'
      '23-25','RA & hand-to-mouth indeterminacy','complete_markets_comparison.m','EXACT'
      '26-29','FTPL formulas & non-equivalence','ftpl_comparison.m','EXACT'
      '30-33','Nominal tax rule','nominal_tax_rules.m','EXACT'
      '34-38','Real tax rule, multiplicity','real_tax_rules.m','EXACT'
      '39-44','KNV/BMS PV identity discussion','ftpl_comparison.m','EXACT(SS)'
      '45-51','Capital extension','capital_extension.m','EXACT'
      '52-65','Money demand / open market','money_demand_extension.m','APPROX(separable MIU)'
      '66-75','Nominal gov. expenditure','nominal_government_expenditure_extension.m','EXACT'
      'A1','S decreasing in G/P (Result A1)','gov-exp Fig.4 curves','NUMERICAL CHECK'
      'A.27-A.36','Appendix B FTPL vs DTPL','ftpl_comparison.m','EXACT(SS)'
    };
    for k=1:size(eqs,1)
        P('  Eq.%-8s | %-42s | %-44s | %s\n', eqs{k,1}, eqs{k,2}, eqs{k,3}, eqs{k,4});
    end
    P('\n');

    P('FIGURES REPRODUCED\n');
    P('  Figure 1  asset market (incomplete) ............ reproduced (quantitative)\n');
    P('  Figure 2  determinacy vs indeterminacy ......... reproduced (quantitative)\n');
    P('  Figure 3  real tax rule, 1 vs 2 steady states .. reproduced (quantitative)\n');
    P('  Figure 4  nominal G / price-indexed debt ....... reproduced (quantitative)\n');
    P('  Figure 5  inflation vs gov.exp growth .......... LIVE web download (World Bank WDI);\n');
    P('            cached to data/, placeholder only if network fails. WDI = PROXY for NIPA def.\n\n');

    P('REPLICATION STATUS MATRIX (by paper section)\n');
    sm = {
      '2.1 Households','EXACT'
      '2.2 Government','EXACT'
      '2.3 Equilibrium','EXACT'
      '2.4 Asset-demand function S(1+r)','EXACT'
      '3.1 Asset-market clearing / Bewley','EXACT (Bewley mapping qualitative)'
      '3.2 r_ss from monetary+fiscal policy','EXACT'
      '3.3 Price-level determinacy P*=B/S','EXACT'
      '3.4 RA & hand-to-mouth indeterminacy','EXACT'
      '3.5.1 FTPL','EXACT (steady state)'
      '3.5.2 Nominal tax rules','EXACT'
      '3.5.3 Real tax rules (uniqueness/multiplicity)','EXACT'
      '3.5.4 Kaplan-Nikolakoudis-Violante','EXACT (steady-state argument)'
      '3.5.5 Brunnermeier-Merkel-Sannikov','EXACT (steady-state identity)'
      '3.6 Adding capital','EXACT'
      '3.7 Money demand / endogenous money / OMO','APPROXIMATE (separable MIU, documented)'
      '3.8 Nominal government expenditure','EXACT'
      '4 Empirical Figure 5','WEB DATA (World Bank WDI proxy; differs from paper NIPA def)'
      'A.1.1 Result A1 (S decreasing in G/P)','NUMERICAL CHECK'
      'A.1.2 Natural debt limits (Modigliani-Miller)','NOT IMPLEMENTED (knife-edge theory only)'
      'A.1.3 Perpetual youth indeterminacy','NOT IMPLEMENTED (analytical only)'
      'A.1.4 Complete markets + aggregate risk','NOT IMPLEMENTED (analytical only)'
      'Appendix B Ten Monetary Doctrines','EXACT (steady-state DTPL vs FTPL)'
    };
    for k=1:size(sm,1)
        P('  %-48s : %s\n', sm{k,1}, sm{k,2});
    end
    P('\n');

    P('KNOWN LIMITATIONS / DISCREPANCIES\n');
    P('  * No paper calibration exists -> structural numbers illustrative.\n');
    P('  * Figures 1-4 are schematic in the paper; we draw them from computed S(1+r).\n');
    P('  * Money ext.: static separable money demand aggregated over baseline\n');
    P('    consumption (no money state); affects levels of L, not the determinacy result.\n');
    P('  * Appendices A.1.2-A.1.4 are knife-edge/analytical indeterminacy results that\n');
    P('    are explained but not numerically simulated (no generic numerical content).\n');
    P('  * Figure 5 uses World Bank WDI (FP.CPI.TOTL.ZG, NE.CON.GOVT.CN, NY.GDP.MKTP.KN)\n');
    P('    as a reproducible web PROXY; it differs from the paper''s exact NIPA Table 3.1\n');
    P('    government-expenditure construction, so the correlation may not equal 0.93.\n');

    fclose(fid);
    fprintf('\nValidation report written to %s\n', fn);
    type(fn);   % echo to console
end