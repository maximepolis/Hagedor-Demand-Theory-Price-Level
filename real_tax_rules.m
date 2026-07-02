function out = real_tax_rules(curve, par, taustar, gamma_, B, label)
% Steady-state price level(s) solving  S(R(P)) = B/P, with
%   R(P) = 1 + gamma + taustar*(P/B).
% STEP 5: full residual scan + bracket EVERY sign change (Fig 3a vs 3b).

    Sint = griddedInterpolant(curve.R, curve.S, 'pchip', 'none'); % NaN outside grid
    Rmin = curve.R(1);  Rmax = curve.R(end);

    resid = @(P) safe_resid(P, Sint, Rmin, Rmax, taustar, gamma_, B);

    Pscan = linspace(par.P_min, par.P_max, par.nscan);
    F     = arrayfun(resid, Pscan);

    sgn = sign(F);
    idx = find( sgn(1:end-1).*sgn(2:end) < 0 & ~isnan(F(1:end-1)) & ~isnan(F(2:end)) );

    roots = [];
    for m = 1:numel(idx)
        try
            r0 = fzero(resid, [Pscan(idx(m)), Pscan(idx(m)+1)]);
            roots(end+1) = r0; %#ok<AGROW>
        catch
        end
    end

    fprintf('[%-8s] tau*=%+.3f gamma=%.3f : %d sign change(s) over P in [%.2f, %.2f] -> %d steady state(s)\n', ...
            label, taustar, gamma_, numel(idx), par.P_min, par.P_max, numel(roots));

    out.roots = roots;
    out.Pscan = Pscan;
    out.F     = F;
    out.resid = resid;
end

function F = safe_resid(P, Sint, Rmin, Rmax, taustar, gamma_, B)
    R = 1 + gamma_ + taustar*(P/B);
    if R < Rmin || R > Rmax || P <= 0
        F = NaN; return;          % R outside computable range -> no claim
    end
    F = Sint(R) - B/P;
end