function fh = plot_real_tax_rule(res_unique, res_multi, params)
% PLOT_REAL_TAX_RULE  Figure 3 replication: asset-market equilibrium under a
% REAL tax rule, tau_t = tau* + gamma(r_t b_t - tau*), drawn in price-asset
% space with the requested orientation:
%   x-axis: real assets / bonds,  y-axis: price level P.
%   BLUE  = government bond supply B/P (traced over P),
%   RED   = transformed household asset demand S(r(P)) (traced over P),
% where 1+pi(P) = 1+i^ss - (P/B) tau* and r(P) = (1+i^ss)/(1+pi(P)) - 1.
%
% Panel (a): tau* > 0  =>  demand increases with P while supply falls: ONE
%            intersection, a unique steady-state price level.
% Panel (b): tau* < 0  =>  demand also falls with P: TWO intersections are
%            possible. Each equilibrium P*_j carries its own steady-state
%            inflation rate = nominal debt growth rate,
%            pi_j = i^ss - tau* P*_j / B, annotated at the intersection.
%
% INPUTS (each a struct with fields .Pgrid, .S_curve, .BoverP, .roots,
%         .pi_at_root, .tau_star)
%   res_unique : the tau* > 0 case.
%   res_multi  : the tau* < 0 case.
%   params     : setup_params struct.
%
% OUTPUT
%   fh : figure handle (saved as Figure3_real_tax_rule.{fig,png,pdf}).
%
% PAPER SECTION: Section 3.5.3, Figure 3 (Eq. 34-38).

    BLUE = [0.10 0.30 0.75];
    RED  = [0.85 0.20 0.15];

    fh = figure('Name','Figure 3: Real tax rule (price-asset space)', ...
                'Color','w','Position',[100 100 1000 420]);

    panels = {res_unique, res_multi};
    for pnl = 1:2
        res = panels{pnl};
        subplot(1,2,pnl); hold on; box on;

        good = isfinite(res.S_curve);
        % demand: assets on x, price level on y
        plot(res.S_curve(good), res.Pgrid(good), '-', 'LineWidth',2, 'Color',RED);
        % supply: B/P on x, P on y (hyperbola)
        plot(res.BoverP, res.Pgrid, '-', 'LineWidth',2, 'Color',BLUE);

        rts = res.roots;
        if isfield(res,'pi_at_root'), piv = res.pi_at_root; else, piv = nan(size(rts)); end
        for k = 1:numel(rts)
            Sk = interp1(res.Pgrid(good), res.S_curve(good), rts(k), 'linear');
            plot(Sk, rts(k), 'o', 'MarkerFaceColor','k', ...
                 'MarkerEdgeColor','k', 'MarkerSize',8);
            if isfinite(piv(min(k,numel(piv))))
                lbl = sprintf('  P^*_%d=%.2f, \\pi_%d=%.1f%%', ...
                              k, rts(k), k, 100*piv(min(k,numel(piv))));
            else
                lbl = sprintf('  P^*_%d=%.2f', k, rts(k));
            end
            text(Sk, rts(k), lbl, 'FontSize',9);
        end

        % axis limits: keep the supply hyperbola from dwarfing the demand curve
        Smax = max(res.S_curve(good));
        if isfinite(Smax) && Smax > 0
            xlim([0, 1.5*Smax]);
        end
        if isempty(rts)
            ymax = min(params.P_max, 8);
        else
            ymax = min(params.P_max, max(2, 1.4*max(rts)));
        end
        ylim([0, ymax]);

        xlabel('real assets / bonds');
        ylabel('price level  P');
        if isfield(res, 'tau_star'), ts = res.tau_star; else, ts = NaN; end
        if pnl == 1
            title(sprintf('(a) \\tau^*=%+.3f: unique equilibrium (%d root)', ...
                  ts, numel(rts)));
        else
            title(sprintf('(b) \\tau^*=%+.3f: two steady states possible (%d root(s))', ...
                  ts, numel(rts)));
        end
        legend({'asset demand  S(r(P))','bond supply  B/P'}, 'Location','northeast');
    end

    save_all_figs(fh, 'Figure3_real_tax_rule', params);
end
