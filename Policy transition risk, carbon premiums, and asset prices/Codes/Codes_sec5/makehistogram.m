function makehistogram(var, cond, year, data, conditions, plot)

% var=1   2    3    4   5      6
%     rf  rp1  rp2  cp  pdr1   pdr2

% cond = [x y z T S]
% conditiones the histogram on X^c = x, X^p = y, X^t = z, T<2

% e.g., makehistogram(1, [1 2 2 T], 6, data, conditions) makes a histogram
% for rf in 2025 conditional on pre-tipping state, OPT, and NET available
% if T=0, unconditional, if T=1, cond on T<2 degrees, if T=2: cond
% on T>2 degrees.

variable = data(:,:,var);
subplot(plot(1),plot(2),plot(3))

    for i=1:3
        if cond(i)~=0
            variable(conditions(:,:,i)~=cond(i))=NaN;
        end
    end
    % Temperature Range
    if cond(4)==1
        variable(conditions(:,:,4)>=2)=NaN;
    elseif cond(4)==2
        variable(conditions(:,:,4)<2)=NaN;
    elseif cond(4)==3
        variable(conditions(:,:,4)>=2)=NaN;
        variable(conditions(:,:,4)<1.8)=NaN;
    end

    % Share Range
    if cond(5)==1
        variable(conditions(:,:,5)>=0.1)=NaN;
    elseif cond(5)==2
        variable(conditions(:,:,5)<0.1)=NaN;
    end



    data_temp=variable(:,year);
    histogram(data_temp(~isnan(data_temp)),60,'Normalization','probability', 'FaceColor', [0.5 0.5 0.5])

end