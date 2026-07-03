histograms=figure();
set(histograms,'Units','Pixels','Position',[0 0 800 400]);
hold on;
n=0;

%% Conditioned on the Climate Tipping State
tax_conditional=NaN(simulation.number, time.number+1, 4);
tax_conditional_mean=NaN(4, 4);
tax_conditional_median=NaN(4, 4);
tax_conditional_sigma=NaN(4, 4);
tax_conditional_q95=NaN(4, 4);
tax_conditional_q05=NaN(4, 4);
tax_conditional_no=NaN(4, 4);
tax_conditional_skew=NaN(4, 4);
for cond_index=1:4

    simulation.tax_temp=simulation.tax;
    if cond_index==1     % conditioned on Y>1
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    elseif cond_index==2 % conditioned on X=1, Y>1
        simulation.tax_temp(simulation.X~=1)=NaN;
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    elseif cond_index==3 % conditioned on X=2, Y>1
        simulation.tax_temp(simulation.X~=2)=NaN;
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    elseif cond_index==4 % conditioned on X=3, Y>1
        simulation.tax_temp(simulation.X~=3)=NaN;
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    end
    tax_conditional(:,:,cond_index)=simulation.tax_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;
        nbins=[10 40 40];

        tax_conditional_mean(cond_index,time_index)=round(nanmean(tax_conditional(:,year(time_index),cond_index)));
        tax_conditional_median(cond_index,time_index)=round(nanmedian(tax_conditional(:,year(time_index),cond_index)));
        tax_conditional_sigma(cond_index,time_index)=round(nanstd(tax_conditional(:,year(time_index),cond_index)));
        tax_conditional_q95(cond_index,time_index)=round(quantile(tax_conditional(:,year(time_index),cond_index), 0.95,1));
        tax_conditional_q05(cond_index,time_index)=round(quantile(tax_conditional(:,year(time_index),cond_index), 0.05,1));
        tax_conditional_skew(cond_index,time_index)=round(skewness(tax_conditional(:,year(time_index),cond_index)),2);
        tax_conditional_no(cond_index,time_index)=nnz(~isnan(tax_conditional(:,year(time_index),cond_index)));

        n=n+1;
        if n<=4
            subplot(2,2,n)
            data_temp=tax_conditional(:,year(time_index),cond_index);
            histogram(data_temp(~isnan(data_temp)),60,'Normalization','probability', 'FaceColor', [0.5 0.5 0.5])
            ytix = get(gca, 'YTick');
            set(gca, 'YTick',ytix, 'YTickLabel',ytix*100);
            xlabel('Carbon Tax [$/tC]')
            if n==1
                title('a) Relative Frequency in 2025 [%]', 'FontWeight', 'normal')
            elseif n==2
                title('b) Relative Frequency in 2050 [%]', 'FontWeight', 'normal')
            elseif n==3
                title('c) Relative Frequency in 2075 [%]', 'FontWeight', 'normal')
            elseif n==4
                title('d) Relative Frequency in 2100 [%]', 'FontWeight', 'normal')
            end
        end
    end
end


%% Conditioned on the Political State
tax_conditional_pol=NaN(simulation.number, time.number+1, 3);
tax_conditional_pol_mean=NaN(3, 4);
tax_conditional_pol_median=NaN(3, 4);
tax_conditional_pol_sigma=NaN(3, 4);
tax_conditional_pol_q95=NaN(3, 4);
tax_conditional_pol_q05=NaN(3, 4);
tax_conditional_pol_no=NaN(3, 4);
tax_conditional_pol_skew=NaN(3, 4);

for cond_index=1:3
    simulation.tax_temp=simulation.tax;
    if cond_index==1     % unconditioned
    elseif cond_index==2 % conditioned on OPT
        simulation.tax_temp(simulation.Y~=2)=NaN;
    elseif cond_index==3 % conditioned on LIM
        simulation.tax_temp(simulation.Y~=3)=NaN;
    end
    tax_conditional_pol(:,:,cond_index)=simulation.tax_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;

        tax_conditional_pol_mean(cond_index,time_index)=round(nanmean(tax_conditional_pol(:,year(time_index),cond_index)));
        tax_conditional_pol_median(cond_index,time_index)=round(nanmedian(tax_conditional_pol(:,year(time_index),cond_index)));
        tax_conditional_pol_sigma(cond_index,time_index)=round(nanstd(tax_conditional_pol(:,year(time_index),cond_index)));
        tax_conditional_pol_q95(cond_index,time_index)=round(quantile(tax_conditional_pol(:,year(time_index),cond_index), 0.95,1));
        tax_conditional_pol_q05(cond_index,time_index)=round(quantile(tax_conditional_pol(:,year(time_index),cond_index), 0.05,1));
        tax_conditional_pol_skew(cond_index,time_index)=round(skewness(tax_conditional_pol(:,year(time_index),cond_index)),2);
        tax_conditional_pol_no(cond_index,time_index)=nnz(~isnan(tax_conditional_pol(:,year(time_index),cond_index)));
    end
end

%% Conditioned on the Breakthrough State
tax_conditional_break=NaN(simulation.number, time.number+1, 2);
tax_conditional_break_mean=NaN(2, 4);
tax_conditional_break_median=NaN(2, 4);
tax_conditional_break_sigma=NaN(2, 4);
tax_conditional_break_q95=NaN(2, 4);
tax_conditional_break_q05=NaN(2, 4);
tax_conditional_break_no=NaN(2, 4);
tax_conditional_break_skew=NaN(2, 4);

for cond_index=1:2
    simulation.tax_temp=simulation.tax;
    if cond_index==1 % conditioned on Xt=1
        simulation.tax_temp(simulation.B~=1)=NaN;
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    elseif cond_index==2 % conditioned on LIM
        simulation.tax_temp(simulation.B~=2)=NaN;
        simulation.tax_temp(simulation.tax_temp==0)=NaN;
    end
    tax_conditional_break(:,:,cond_index)=simulation.tax_temp;

    for time_index=1:4
        year=[2025 2050 2075 2100]-2020+1;

        tax_conditional_break_mean(cond_index,time_index)=round(nanmean(tax_conditional_break(:,year(time_index),cond_index)));
        tax_conditional_break_median(cond_index,time_index)=round(nanmedian(tax_conditional_break(:,year(time_index),cond_index)));
        tax_conditional_break_sigma(cond_index,time_index)=round(nanstd(tax_conditional_break(:,year(time_index),cond_index)));
        tax_conditional_break_q95(cond_index,time_index)=round(quantile(tax_conditional_break(:,year(time_index),cond_index), 0.95,1));
        tax_conditional_break_q05(cond_index,time_index)=round(quantile(tax_conditional_break(:,year(time_index),cond_index), 0.05,1));
        tax_conditional_break_skew(cond_index,time_index)=round(skewness(tax_conditional_break(:,year(time_index),cond_index)),2);
        tax_conditional_break_no(cond_index,time_index)=nnz(~isnan(tax_conditional_break(:,year(time_index),cond_index)));
    end
end

%% Two sample t-tests
% 2025:
[h25,p25,ci25,stats25] = ttest2(tax_conditional_pol(:,year(1),2), tax_conditional_pol(:,year(1),3),'Vartype','unequal');

% 2050:
[h50,p50,ci50,stats50] = ttest2(tax_conditional_pol(:,year(2),2), tax_conditional_pol(:,year(2),3),'Vartype','unequal');

% 2075:
[h75,p75,ci75,stats75] = ttest2(tax_conditional_pol(:,year(3),2), tax_conditional_pol(:,year(3),3),'Vartype','unequal');

% 2100:
[h100,p100,ci100,stats100] = ttest2(tax_conditional_pol(:,year(4),2), tax_conditional_pol(:,year(4),3),'Vartype','unequal');


%% Make a table
% year & $\mathbb E[\tau]$ & $\mathrm{Med}(\tau)$ & $\sigma(\tau)$ & $\mathrm{Skew}(\tau)$ & $q_{5\%}(\tau)$ & $q_{95\%}(\tau)$
% 2025
% 2050
% 2075
% 2100

Year=year+2020-1;

% Unconditioned
TableD3=[...
Year(1)    tax_conditional_pol_mean(1,1) tax_conditional_pol_median(1,1) tax_conditional_pol_sigma(1,1)  tax_conditional_pol_q05(1,1) tax_conditional_pol_q95(1,1) tax_conditional_pol_skew(1,1);
Year(2)    tax_conditional_pol_mean(1,2) tax_conditional_pol_median(1,2) tax_conditional_pol_sigma(1,2)  tax_conditional_pol_q05(1,2) tax_conditional_pol_q95(1,2) tax_conditional_pol_skew(1,2);
Year(3)    tax_conditional_pol_mean(1,3) tax_conditional_pol_median(1,3) tax_conditional_pol_sigma(1,3)  tax_conditional_pol_q05(1,3) tax_conditional_pol_q95(1,3) tax_conditional_pol_skew(1,3);
Year(4)    tax_conditional_pol_mean(1,4) tax_conditional_pol_median(1,4) tax_conditional_pol_sigma(1,4)  tax_conditional_pol_q05(1,4) tax_conditional_pol_q95(1,4) tax_conditional_pol_skew(1,4);
    ];

% Conditioned on X^p >1 (OPT or LIM)
Table3a=[...
Year(1)    tax_conditional_mean(1,1) tax_conditional_median(1,1) tax_conditional_sigma(1,1)  tax_conditional_q05(1,1) tax_conditional_q95(1,1) tax_conditional_skew(1,1);
Year(2)    tax_conditional_mean(1,2) tax_conditional_median(1,2) tax_conditional_sigma(1,2)  tax_conditional_q05(1,2) tax_conditional_q95(1,2) tax_conditional_skew(1,2);
Year(3)    tax_conditional_mean(1,3) tax_conditional_median(1,3) tax_conditional_sigma(1,3)  tax_conditional_q05(1,3) tax_conditional_q95(1,3) tax_conditional_skew(1,3);
Year(4)    tax_conditional_mean(1,4) tax_conditional_median(1,4) tax_conditional_sigma(1,4)  tax_conditional_q05(1,4) tax_conditional_q95(1,4) tax_conditional_skew(1,4);
    ];

% Conditioned on X^p =2 (OPT)
Table3b=[...
Year(1)    tax_conditional_pol_mean(2,1) tax_conditional_pol_median(2,1) tax_conditional_pol_sigma(2,1)  tax_conditional_pol_q05(2,1) tax_conditional_pol_q95(2,1) tax_conditional_pol_skew(2,1);
Year(2)    tax_conditional_pol_mean(2,2) tax_conditional_pol_median(2,2) tax_conditional_pol_sigma(2,2)  tax_conditional_pol_q05(2,2) tax_conditional_pol_q95(2,2) tax_conditional_pol_skew(2,2);
Year(3)    tax_conditional_pol_mean(2,3) tax_conditional_pol_median(2,3) tax_conditional_pol_sigma(2,3)  tax_conditional_pol_q05(2,3) tax_conditional_pol_q95(2,3) tax_conditional_pol_skew(2,3);
Year(4)    tax_conditional_pol_mean(2,4) tax_conditional_pol_median(2,4) tax_conditional_pol_sigma(2,4)  tax_conditional_pol_q05(2,4) tax_conditional_pol_q95(2,4) tax_conditional_pol_skew(2,4);
    ];

% Conditioned on X^p =3 (LIM)
Table3c=[...
Year(1)     tax_conditional_pol_mean(3,1) tax_conditional_pol_median(3,1) tax_conditional_pol_sigma(3,1)  tax_conditional_pol_q05(3,1) tax_conditional_pol_q95(3,1) tax_conditional_pol_skew(3,1);
Year(2)    tax_conditional_pol_mean(3,2) tax_conditional_pol_median(3,2) tax_conditional_pol_sigma(3,2)  tax_conditional_pol_q05(3,2) tax_conditional_pol_q95(3,2) tax_conditional_pol_skew(3,2);
Year(3)    tax_conditional_pol_mean(3,3) tax_conditional_pol_median(3,3) tax_conditional_pol_sigma(3,3)  tax_conditional_pol_q05(3,3) tax_conditional_pol_q95(3,3) tax_conditional_pol_skew(3,3);
Year(4)    tax_conditional_pol_mean(3,4) tax_conditional_pol_median(3,4) tax_conditional_pol_sigma(3,4)  tax_conditional_pol_q05(3,4) tax_conditional_pol_q95(3,4) tax_conditional_pol_skew(3,4);
    ];


% Conditioned on X^c =1 (pre-tip)
Table3d=[...
Year(1)     tax_conditional_mean(2,1) tax_conditional_median(2,1) tax_conditional_sigma(2,1)  tax_conditional_q05(2,1) tax_conditional_q95(2,1) tax_conditional_skew(2,1);
Year(2)    tax_conditional_mean(2,2) tax_conditional_median(2,2) tax_conditional_sigma(2,2)  tax_conditional_q05(2,2) tax_conditional_q95(2,2) tax_conditional_skew(2,2);
Year(3)    tax_conditional_mean(2,3) tax_conditional_median(2,3) tax_conditional_sigma(2,3)  tax_conditional_q05(2,3) tax_conditional_q95(2,3) tax_conditional_skew(2,3);
Year(4)    tax_conditional_mean(2,4) tax_conditional_median(2,4) tax_conditional_sigma(2,4)  tax_conditional_q05(2,4) tax_conditional_q95(2,4) tax_conditional_skew(2,4);
    ];

% Conditioned on X^c =2 (intermeadiate)
Table3e=[...
Year(1)     tax_conditional_mean(3,1) tax_conditional_median(3,1) tax_conditional_sigma(3,1)  tax_conditional_q05(3,1) tax_conditional_q95(3,1) tax_conditional_skew(3,1);
Year(2)    tax_conditional_mean(3,2) tax_conditional_median(3,2) tax_conditional_sigma(3,2)  tax_conditional_q05(3,2) tax_conditional_q95(3,2) tax_conditional_skew(3,2);
Year(3)    tax_conditional_mean(3,3) tax_conditional_median(3,3) tax_conditional_sigma(3,3)  tax_conditional_q05(3,3) tax_conditional_q95(3,3) tax_conditional_skew(3,3);
Year(4)    tax_conditional_mean(3,4) tax_conditional_median(3,4) tax_conditional_sigma(3,4)  tax_conditional_q05(3,4) tax_conditional_q95(3,4) tax_conditional_skew(3,4);
    ];

% Conditioned on X^c =3 (post-tip)
Table3f=[...
Year(1)     tax_conditional_mean(4,1) tax_conditional_median(4,1) tax_conditional_sigma(4,1)  tax_conditional_q05(4,1) tax_conditional_q95(4,1) tax_conditional_skew(4,1);
Year(2)    tax_conditional_mean(4,2) tax_conditional_median(4,2) tax_conditional_sigma(4,2)  tax_conditional_q05(4,2) tax_conditional_q95(4,2) tax_conditional_skew(4,2);
Year(3)    tax_conditional_mean(4,3) tax_conditional_median(4,3) tax_conditional_sigma(4,3)  tax_conditional_q05(4,3) tax_conditional_q95(4,3) tax_conditional_skew(4,3);
Year(4)    tax_conditional_mean(4,4) tax_conditional_median(4,4) tax_conditional_sigma(4,4)  tax_conditional_q05(4,4) tax_conditional_q95(4,4) tax_conditional_skew(4,4);
    ];

% Conditioned on X^t =1 (post-tip)
Table3g=[...
Year(1)     tax_conditional_break_mean(1,1) tax_conditional_break_median(1,1) tax_conditional_break_sigma(1,1)  tax_conditional_break_q05(1,1) tax_conditional_break_q95(1,1) tax_conditional_break_skew(1,1);
Year(2)    tax_conditional_break_mean(1,2) tax_conditional_break_median(1,2) tax_conditional_break_sigma(1,2)  tax_conditional_break_q05(1,2) tax_conditional_break_q95(1,2) tax_conditional_break_skew(1,2);
Year(3)    tax_conditional_break_mean(1,3) tax_conditional_break_median(1,3) tax_conditional_break_sigma(1,3)  tax_conditional_break_q05(1,3) tax_conditional_break_q95(1,3) tax_conditional_break_skew(1,3);
Year(4)    tax_conditional_break_mean(1,4) tax_conditional_break_median(1,4) tax_conditional_break_sigma(1,4)  tax_conditional_break_q05(1,4) tax_conditional_break_q95(1,4) tax_conditional_break_skew(1,4);
    ];

% Conditioned on X^t =1 (post-tip)
Table3h=[...
Year(1)     tax_conditional_break_mean(2,1) tax_conditional_break_median(2,1) tax_conditional_break_sigma(2,1)  tax_conditional_break_q05(2,1) tax_conditional_break_q95(2,1) tax_conditional_break_skew(2,1);
Year(2)     tax_conditional_break_mean(2,2) tax_conditional_break_median(2,2) tax_conditional_break_sigma(2,2)  tax_conditional_break_q05(2,2) tax_conditional_break_q95(2,2) tax_conditional_break_skew(2,2);
Year(3)    tax_conditional_break_mean(2,3) tax_conditional_break_median(2,3) tax_conditional_break_sigma(2,3)  tax_conditional_break_q05(2,3) tax_conditional_break_q95(2,3) tax_conditional_break_skew(2,3);
Year(4)    tax_conditional_break_mean(2,4) tax_conditional_break_median(2,4) tax_conditional_break_sigma(2,4)  tax_conditional_break_q05(2,4) tax_conditional_break_q95(2,4) tax_conditional_break_skew(2,4);
    ];

