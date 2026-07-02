function fh = plot_real_tax_rule(res_unique, res_multi, params)
% PLOT_REAL_TAX_RULE  Figure 3 replication: asset-market equilibrium under a
% REAL tax rule, tau_t = tau* + gamma(r_t b_t - tau*), drawn in PRICE-ASSET
% space exactly as in the paper ("It is convenient to operate in the price-
% asset space, since the inflation rate depends on the price level").
%
% For each price level P, inflation is 1+pi(P) = 1+i^ss - (P/B) tau*, so the
% transformed asset-demand curve is
%       S( (1+i^ss)/(1+pi(P)) )   as a function of P,
% and real bond supply is B/P. Equilibria are their intersections.
%   Panel (a): tau* > 0  => demand increasing in P, supply decreasing => UNIQUE.
%   Panel (b): tau* < 0  => demand decreasing in P as well => possibly TWO
%              steady-state price levels (the paper's non-uniqueness case).
%
% INPUTS (each a struct with fields .Pgrid, .S_curve, .BoverP, .roots,
%         .tau_star)
%   res_unique : the tau* > 0 case.
%   res_multi  : the tau* < 0 case.
%   params     : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure3_real_tax_rule.{fig,png,pdf}).
%
% PAPER SECTION: Section 3.5.3, Figure 3.

    fh = figure('Name','Figure 3: Real tax rule (price-asset space)', ...
                'Color','w','Position',[100 100 1000 420]);

    panels = {res_unique, res_multi};
    for pnl = 1:2
        res = panels{pnl};
        subplot(1,2,pnl); hold on; box on;

        good = isfinite(res.S_curve);
        plot(res.Pgrid(good), res.S_curve(good), '-', 'LineWidth',2, ...
             'Color',[0.10 0.30 0.75]);
        plot(res.Pgrid, res.BoverP, '-', 'LineWidth',2, 'Color',[0.85 0.20 0.15]);

        rts = res.roots;
        for k = 1:numel(rts)
            Sk = interp1(res.Pgrid(good), res.S_curve(good), rts(k), 'linear');
            plot(rts(k), Sk, 'o', 'MarkerFaceColor','k', ...
                 'MarkerEdgeColor','k', 'MarkerSize',8);
            text(rts(k), Sk, sprintf('  P^*_%d=%.3f', k, rts(k)), 'FontSize',9);
        end

        % keep the B/P hyperbola from dwarfing the demand curve
        Smax = max(res.S_curve(good));
        if isfinite(Smax) && Smax > 0
            ylim([0, 1.6*Smax]);
        end

        xlabel('price level  P');
        ylabel('real assets');
        if isfield(res, 'tau_star'), ts = res.tau_star; else, ts = NaN; end
        if pnl == 1
            title(sprintf('(a) \\tau^*=%.2f>0: unique equilibrium (%d root)', ...
                  ts, numel(rts)));
        else
            title(sprintf('(b) \\tau^*=%.2f<0: non-uniqueness possible (%d root(s))', ...
                  ts, numel(rts)));
        end
        legend({'asset demand  S(r(P))','bond supply  B/P'}, 'Location','northeast');
    end

    save_all_figs(fh, 'Figure3_real_tax_rule', params);
end
