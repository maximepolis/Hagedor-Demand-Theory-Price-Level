X = 40;                  %# A4 paper size
Y = 55;                  %# A4 paper size
xMargin = 1;               %# left/right margins from page borders
yMargin = 1;               %# bottom/top margins from page borders
xSize = X - 2*xMargin;     %# figure size on paper (widht & hieght)
ySize = Y - 2*yMargin;     %# figure size on paper (widht & hieght)

%# create figure/axis
fig_ap = figure('Menubar','none');

%# figure size displayed on screen (50% scaled, but same aspect ratio)
set(fig_ap, 'Units','centimeters', 'Position',[0 0 xSize ySize]/2)
movegui(fig_ap, 'center')

%# figure size printed on paper
set(fig_ap, 'PaperUnits','centimeters')
set(fig_ap, 'PaperSize',[X Y])
set(fig_ap, 'PaperPosition',[xMargin yMargin xSize ySize])
set(fig_ap, 'PaperOrientation','portrait')

Tmax=temperature.plot/temperature.max*temperature.number;
X_t=1;
X_p=1;

subplot(4,3,1)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr1_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a1) pdr_1 (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 200])
view(-10,30)

subplot(4,3,2)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr1_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b1) pdr_1 (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 200])
view(-10,30)
subplot(4,3,3)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr1_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c1) pdr_1 (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 200])
view(-10,30)
subplot(4,3,4)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr2_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a2) pdr_2 (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 15])
view(-10,30)
subplot(4,3,5)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr2_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b2) pdr_2 (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 15])
view(-10,30)
subplot(4,3,6)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), pdr2_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c2) pdr_2 (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 15])
view(-10,30)

subplot(4,3,7)
z= ep1_s1(:,1:Tmax,1,X_t,X_p)*100;
z(1:10,:)=NaN;
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('a3) rp_1 [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)
subplot(4,3,8)
z= ep1_s1(:,1:Tmax,2,X_t,X_p)*100;
z(1:10,:)=NaN;
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('b3) rp_1 [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)
%%%%%%%%%%%%
z= ep1_s1(:,1:Tmax,3,X_t,X_p)*100;
z(1:10,:)=NaN;
subplot(4,3,9)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('c3) rp_1 [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)
%%%%%%%%%%%%%%%%
subplot(4,3,10)
z= ep2_s1(:,1:Tmax,1,X_t,X_p)*100;
z(1:10,:)=NaN;
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('a4) rp_2 [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)
subplot(4,3,11)
z= ep2_s1(:,1:Tmax,2,X_t,X_p)*100;
z(1:10,:)=NaN;
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('b4) rp_2 [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)
subplot(4,3,12)
z= ep2_s1(:,1:Tmax,3,X_t,X_p)*100;
z(1:10,:)=NaN;
z(:,temperature.number*2/temperature.max+1)=0.5*(z(:,temperature.number*2/temperature.max)+z(:,temperature.number*2/temperature.max+2));
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), z,'FaceColor','interp','EdgeColor','none');
title('c4) rp_2 [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([5 15])
view(-10,30)

%%%%%%%%%%%%%%%%%%%%%%
X = 40;                  %# A4 paper size
Y = 30;                  %# A4 paper size
xMargin = 1;               %# left/right margins from page borders
yMargin = 1;               %# bottom/top margins from page borders
xSize = X - 2*xMargin;     %# figure size on paper (widht & hieght)
ySize = Y - 2*yMargin;     %# figure size on paper (widht & hieght)

%# create figure/axis
fig_g = figure('Menubar','none');

%# figure size displayed on screen (50% scaled, but same aspect ratio)
set(fig_g, 'Units','centimeters', 'Position',[0 0 xSize ySize]/2)
movegui(fig_g, 'center')

%# figure size printed on paper
set(fig_g, 'PaperUnits','centimeters')
set(fig_g, 'PaperSize',[X Y])
set(fig_g, 'PaperPosition',[xMargin yMargin xSize ySize])
set(fig_g, 'PaperOrientation','portrait')

subplot(2,3,1)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), tax_s1(:,1:Tmax,1,X_t,X_p)*sum(production.K0)*10^12,'FaceColor','interp','EdgeColor','none');
title('a1) \tau [$/tC] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 4000])
view(-10,30)
subplot(2,3,2)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), tax_s1(:,1:Tmax,2,X_t,X_p)*sum(production.K0)*10^12,'FaceColor','interp','EdgeColor','none');
title('b1) \tau [$/tC] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 4000])
view(-10,30)
subplot(2,3,3)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), tax_s1(:,1:Tmax,3,X_t,X_p)*sum(production.K0)*10^12,'FaceColor','interp','EdgeColor','none');
title('c1) \tau [$/tC] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 4000])
view(-10,30)


subplot(2,3,4)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*rf_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a2) r_f [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([-1 3])
view(-10,30)
subplot(2,3,5)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*rf_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b2) r_f [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([-1 3])
view(-10,30)
subplot(2,3,6)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*rf_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c2) r_f [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([-1 3])
view(-10,30)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%
X = 40;                  %# A4 paper size
Y = 30;                  %# A4 paper size
xMargin = 1;               %# left/right margins from page borders
yMargin = 1;               %# bottom/top margins from page borders
xSize = X - 2*xMargin;     %# figure size on paper (widht & hieght)
ySize = Y - 2*yMargin;     %# figure size on paper (widht & hieght)

%# create figure/axis
fig_i = figure('Menubar','none');

%# figure size displayed on screen (50% scaled, but same aspect ratio)
set(fig_i, 'Units','centimeters', 'Position',[0 0 xSize ySize]/2)
movegui(fig_i, 'center')

%# figure size printed on paper
set(fig_i, 'PaperUnits','centimeters')
set(fig_i, 'PaperSize',[X Y])
set(fig_i, 'PaperPosition',[xMargin yMargin xSize ySize])
set(fig_i, 'PaperOrientation','portrait')

subplot(3,3,1)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*r_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a1) r [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 50])
view(-10,30)
subplot(3,3,2)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*r_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b1) r [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 50])
view(-10,30)
subplot(3,3,3)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*r_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c1) r [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 50])
view(-10,30)


subplot(3,3,4)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i1_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a2) i_1 [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([4 6])
view(-10,30)
subplot(3,3,5)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i1_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b2) i_1 [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([4 6])
view(-10,30)
subplot(3,3,6)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i1_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c2) i_1 [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([4 6])
view(-10,30)


subplot(3,3,7)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i2_s1(:,1:Tmax,1,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('a3) i_2 [%] (BAU)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 6])
view(-10,30)
subplot(3,3,8)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i2_s1(:,1:Tmax,2,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('b3) i_2 [%] (TAX)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 6])
view(-10,30)
subplot(3,3,9)
p1=surf(temperature.mesh(:,1:Tmax), state.mesh(:,1:Tmax), 100*i2_s1(:,1:Tmax,3,X_t,X_p),'FaceColor','interp','EdgeColor','none');
title('c3) i_2 [%] (CAP)', 'FontWeight', 'normal');
xlabel('T')
xlim([0 4])
xticks(0:1:4)
ylabel('S')
ylim([0 1])
yticks(0:0.25:1)
zlim([0 6])
view(-10,30)


saveas(fig_ap,[save_data_at, 'Policy_AssetPricing.fig'],'fig');
saveas(fig_g,[save_data_at, 'Policy_Tax.fig'],'fig');
saveas(fig_i,[save_data_at, 'Policy_Investment.fig'],'fig');
exportgraphics(fig_ap,[save_data_at, 'Policy_AssetPricing.pdf'],'Resolution',1000)
exportgraphics(fig_g,[save_data_at, 'Policy_Tax.pdf'],'Resolution',1000)
exportgraphics(fig_i,[save_data_at, 'Policy_Investment.pdf'],'Resolution',1000)