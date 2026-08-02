function [eG2, Pi2, stat2] = add_superstar_state(eG, Pi, ss)
% ADD_SUPERSTAR_STATE  Append a rare high-endowment state to a finite income
% chain (the Castaneda--Diaz-Gimenez--Rios-Rull 2003 device for matching top
% wealth concentration in Aiyagari-class models).
%
% The augmented chain: from every regular state, enter the superstar state
% with probability ss.p_in (regular rows rescaled by 1 - p_in); from the
% superstar state, exit to the MEDIAN regular state with probability
% ss.p_out. The superstar endowment is ss.mult times the top regular state.
% The grid is renormalized so E[e] = 1 under the new stationary
% distribution, preserving the model's mean-endowment convention.
%
% INPUTS   eG (ne x 1), Pi (ne x ne), ss struct with .mult .p_in .p_out
% OUTPUTS  eG2 ((ne+1) x 1, renormalized), Pi2, stat2 (stationary dist)

    eG = eG(:); ne = numel(eG);
    eG2 = [eG; ss.mult * max(eG)];

    Pi2 = zeros(ne + 1);
    Pi2(1:ne, 1:ne) = (1 - ss.p_in) * Pi;
    Pi2(1:ne, end)  = ss.p_in;
    jmid = ceil(ne / 2);
    Pi2(end, end)  = 1 - ss.p_out;
    Pi2(end, jmid) = ss.p_out;

    % stationary distribution by power iteration
    stat2 = ones(ne + 1, 1) / (ne + 1);
    for it = 1:200000
        snew = Pi2' * stat2;
        if max(abs(snew - stat2)) < 1e-14, stat2 = snew; break; end
        stat2 = snew;
    end
    stat2 = stat2 / sum(stat2);

    % renormalize the mean endowment to one
    eG2 = eG2 / (stat2' * eG2);
end
