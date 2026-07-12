function [POL, feas, V1] = transition_backward(VT, r_path, tau_path, D_path, pgc)
% TRANSITION_BACKWARD  One Bellman step per date, backward from the terminal
% value function of the green steady state. Extracted verbatim from
% solve_hank_dtpl_transition so it can be re-run standalone on a SAVED
% converged price path (transition_results.mat) -- e.g. to recover the
% announcement-date value function V1 for transition-inclusive welfare --
% without re-solving the fixed point.
%
% INPUTS
%   VT       : terminal value function (green steady state), na x ne.
%   r_path   : realized real returns along the path (surprise at t=1).
%   tau_path : lump-sum taxes along the path.
%   D_path   : damages along the path.
%   pgc      : calibrated project params (grids, income process, sigma...).
%
% OUTPUTS
%   POL  : per-date policy closures (.push, .aGrid_dot_dist), as used by the
%          transition solver's forward pass.
%   feas : false if the household problem is infeasible at some date.
%   V1   : the DATE-1 value function (na x ne) -- the value of entering the
%          announced transition with assets a and state e, including the
%          announcement-date surprise revaluation through r_path(1).

    T = numel(r_path);
    POL = struct('push', cell(1, T), 'aGrid_dot_dist', cell(1, T));
    feas = true;
    V1 = [];
    Vnext = VT;
    aG = pgc.aGrid(:);
    na = numel(aG);
    for t = T:-1:1
        p = pgc;
        if pgc.phi_D > 0
            p.sig_eps = pgc.sig_eps0 * (1 + pgc.phi_D * D_path(t));
            [eG, PiD, statD] = make_income_process(p);
            p.eGrid = eG; p.Pi = PiD; p.stationary_e = statD;
        end
        % damage level/incidence channel on endowments (as in S_green)
        psi = 0;
        if isfield(pgc, 'psi_inc') && ~isempty(pgc.psi_inc), psi = pgc.psi_inc; end
        ev = p.eGrid(:); wst = p.stationary_e(:);
        if psi > 0
            cnorm = wst' * (ev.^(1 - psi));
            chi = (ev.^(-psi)) / cnorm;
            yv = max(1 - D_path(t) * chi, 0.05) .* ev;
        else
            yv = (1 - D_path(t)) * ev;
        end
        [V, polA_idx, ok] = hh_bellman_step(Vnext, r_path(t), tau_path(t), ...
                                            yv, p, aG);
        if ~ok, feas = false; return; end
        Vnext = V;
        Pi_t = p.Pi;
        idx  = polA_idx;                     % na x ne
        POL(t).push = @(dist) tb_push_dist(dist, idx, Pi_t, na);
        POL(t).aGrid_dot_dist = @(dist) sum(sum(aG(idx) .* dist));
    end
    V1 = Vnext;                              % value at the announcement date
end

function dist1 = tb_push_dist(dist, polA_idx, Pi, na)
% exact one-step distribution iteration: mass at (a,e) moves to
% (polA_idx(a,e), e') with probability Pi(e,e')
    ne = size(dist, 2);
    dist1 = zeros(na, ne);
    for e = 1:ne
        m = accumarray(polA_idx(:, e), dist(:, e), [na, 1]);
        dist1 = dist1 + m * Pi(e, :);
    end
end
