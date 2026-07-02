function [u, mu, muinv] = utility(c, sigma)
% UTILITY  CRRA period utility and its marginal utility.
%
%   u(c)  = (c^(1-sigma) - 1)/(1-sigma)   for sigma ~= 1
%   u(c)  = log(c)                        for sigma == 1
%
% INPUTS
%   c     : consumption (scalar / vector / matrix). Non-positive entries are
%           treated as infeasible and returned as -Inf utility.
%   sigma : CRRA coefficient.
%
% OUTPUTS
%   u     : period utility, same size as c (-Inf where c <= 0).
%   mu    : marginal utility u'(c) = c^(-sigma) (Inf where c <= 0).
%   muinv : inverse marginal utility, i.e. c such that u'(c) = m, evaluated at
%           m = c (handy for EGM): muinv(m) = m^(-1/sigma). NOTE: here it maps
%           the INPUT argument c through m^(-1/sigma), see solve_household_egm.
%
% PAPER SECTION: Section 2.1 preferences.

    pos = c > 0;

    % ----- period utility -----
    u = -Inf(size(c));
    if abs(sigma - 1) < 1e-12
        u(pos) = log(c(pos));
    else
        u(pos) = (c(pos).^(1 - sigma) - 1) / (1 - sigma);
    end

    % ----- marginal utility -----
    if nargout >= 2
        mu = Inf(size(c));
        mu(pos) = c(pos).^(-sigma);
    end

    % ----- inverse marginal utility (c = m^(-1/sigma)) -----
    if nargout >= 3
        muinv = c.^(-1/sigma);   % interpret input c as marginal-utility value m
    end
end
