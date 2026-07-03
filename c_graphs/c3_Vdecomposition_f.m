% Computes the HJB with optimal inflation

function results = c3_Vdecomposition_f(parameters, res_in)

% UNPACK PARAMETERS

ga     = parameters.ga;          % CRRA utility with parameter gamma
zmean  = parameters.zmean;       % mean O-U process (in levels). This parameter has to be adjusted to ensure that the mean of z (truncated gaussian) is 1.
sig    = parameters.sig;         % sigma^2 O-U
mu1    = parameters.mu;          % persistence O-U
rho    = parameters.rho;         % discount rate + death prob
r_bar  = parameters.r_bar;       % interest rates

lambda = parameters.lambda;      % debt duration 1/lambda
delta  = parameters.delta;       % Such that price of riskless bond = 1

I      = parameters.I;           % number of a points
J      = parameters.J;           % number of z points
zmin   = parameters.zmin;        % Range z
zmax   = parameters.zmax;
amin   = parameters.amin;        % borrowing constraint
amax   = parameters.amax;        % range a

%simulation parameters
maxit  = parameters.maxit;       % maximum number of iterations in the HJB loop
maxitD = parameters.maxitD;      % maximum number of iterations in the HJB loop
crit   = parameters.crit;        % criterion HJB loop
critD  = parameters.critD;       % criterion outer loop
Delta  = parameters.Delta;       % delta in HJB algorithm
relaxV = parameters.relaxV;      % relaxation parameter for V
relaxQ = parameters.relaxQ;      % relaxation parameter for Q

% Default parameters
d0     = parameters.d0;          % Cost of default
d1     = parameters.d1;
chi    = parameters.chi;         % Exclusion parameter
phi    = parameters.phi;         % Default option arrival rate
theta  = parameters.theta;       % Surviving share of debt after a partial default episode
kappa  = parameters.kappa;       % Cost of default, proportional to the amount of debt
psi    = parameters.psi;         % sensitivity to inflation

maxit=maxit*10;

%%%%%%%%%%%%
%% VARIABLES

a_1D  = linspace(amin,amax,I)';   % wealth vector
z_1D  = linspace(zmin,zmax,J);    % productivity vector
a_2D  = a_1D*ones(1,J);           % 2D version of the a grid
z_2D  = ones(I,1)*z_1D;           % 2D version of the z grid
pi_2D = zeros(size(a_2D));        % inflation

da   = (amax-amin)/(I-1);
dz   = (zmax-zmin)/(J-1);
dz2  = dz^2;

mu = mu1*(zmean - z_1D);         % Drift    (from Ito's lemma)
s2 = sig^2.*ones(1,J);           % Variance (from Ito's lemma)

eps = max((d0 *exp(z_2D) + d1* exp(2*z_2D)),0);

psizeta_2D     = psi * exp(parameters.zeta*z_2D);
psizeta_def_2D = psi *(exp(parameters.zeta*z_2D) - eps);

% interpolation (to find the correct a spot after partial default)

a_1D_theta = a_1D*theta;
Interpol_Lpos = zeros(I,1); % low  position for interpolation
Interpol_Hpos = zeros(I,1); % high position for interpolation
Interpol_Lval = zeros(I,1); % weight of Lpos in interpolation
Interpol_Hval = zeros(I,1); % weight of Hpos in interpolation

for m=1:I % for each input a, use its theta*a value
    for n=2:I % for each possible output a, see if the input a*theta lands just below here
        if and(a_1D_theta(m)<=a_1D(n), a_1D_theta(m)>a_1D(n-1))
            weight = (a_1D_theta(m)-a_1D(n-1))/(a_1D(n)-a_1D(n-1)) ; % weight of upper point
            Interpol_Lpos(m,1) = n-1;                            % if assets are a_1D(n) before partial default, assets are slightly above a_1D(o-1) after default
            Interpol_Hpos(m,1) = n;
            Interpol_Lval(m,1) = 1-weight;
            Interpol_Hval(m,1) = weight;
        end
    end
end


dist1 = zeros(maxitD,maxit);
dist2 = zeros(maxitD,maxit);
dist3 = zeros(maxitD,maxit);
dist4 = zeros(maxitD,maxit);
distd = zeros(1,maxitD);
m=1;


%%%%%%%%%%%%
%% Equilibrium objects

d       = res_in.d;
V       = res_in.V;
V_def   = res_in.V_def;
Q       = res_in.Q;
Q_def   = res_in.Q_def;
s       = res_in.s;
s_def   = res_in.s_def;
c       = res_in.c;
c_def   = res_in.c_def;
pi      = res_in.pi;
pi_def  = res_in.pi_def;
A       = res_in.A;
A_def   = res_in.A_def;


%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Consumption component

V       = res_in.V;
V_def   = res_in.V_def;
for n=1:maxit
        
    % IN REPAYMENT PERIODS

  % u = (c.^(1-ga)-1)/(1-ga) + phi*d.*V_def - psizeta_2D/2 .* pi.^2;
    u = (c.^(1-ga)-1)/(1-ga) + phi*d.*V_def;
    
    B = (1/Delta + rho)*speye(I*J) - A;

    u_stacked = reshape(u,I*J,1);
    V_stacked = reshape(V,I*J,1);

    b = u_stacked + V_stacked/Delta;

    V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS

    V_new    = reshape(V_stacked,I,J);        
    V_change = V_new - V;
    V        = (1-relaxV) * V + relaxV*V_new; 

    % IN EXCLUSION PERIODS

    V_entry=zeros(I,J);     % value function after reentry into the market
    for o=1:J               % we fill it column by column
        V_col = V_new(:,o); % we use the new V before relaxation, and apply relaxation here also but at the end
        V_entry_col = V_col(Interpol_Lpos).*Interpol_Lval + V_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of V
        V_entry(:,o)= V_entry_col;
    end

  % u_def = (c_def.^(1-ga)-1)/(1-ga) + chi*V_entry - psizeta_def_2D/2 .* pi_def.^2;  % utility of consumption during the exclusion period, plus V after re-entry when the exclusion period is over
    u_def = (c_def.^(1-ga)-1)/(1-ga) + chi*V_entry;                                  % utility of consumption during the exclusion period, plus V after re-entry when the exclusion period is over

    B = (1/Delta + rho)*speye(I*J) - A_def;

    u_stacked = reshape(u_def,I*J,1);
    V_stacked = reshape(V_def,I*J,1);

    b = u_stacked + V_stacked/Delta;

    V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS

    V_def_new    = reshape(V_stacked,I,J);        
    V_def_change = V_def_new - V_def;
    V_def        = (1-relaxV) * V_def + relaxV*V_def_new; 

    % Continuation
    dist1(m,n) = max(max(abs(V_change)));
    dist3(m,n) = max(max(abs(V_def_change)));
    if mod(n,100)==0
        disp([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(m,n)) '     dist Q: ' num2str(dist2(m,n)) '     dist V_def: ' num2str(dist3(m,n)) '     dist Q_def: ' num2str(dist4(m,n))])
    end
    if (dist1(m,n)<crit) && (dist2(m,n)<crit)
        disp([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(m,n)) '     dist Q: ' num2str(dist2(m,n)) '     dist V_def: ' num2str(dist3(m,n)) '     dist Q_def: ' num2str(dist4(m,n))]);
        break
    end

end

disp(' ');
if n >= maxit
    disp('ERROR: Value Function NOT Converged');
end
disp(' ');

Vc     = V;
Vc_def = V_def;

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Inflation component

V       = res_in.V;
V_def   = res_in.V_def;

for n=1:maxit
        
    % IN REPAYMENT PERIODS

  % u = (c.^(1-ga)-1)/(1-ga) + phi*d.*V_def - psizeta_2D/2 .* pi.^2;
    u =                      + phi*d.*V_def - psizeta_2D/2 .* pi.^2;
    
    B = (1/Delta + rho)*speye(I*J) - A;

    u_stacked = reshape(u,I*J,1);
    V_stacked = reshape(V,I*J,1);

    b = u_stacked + V_stacked/Delta;

    V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS

    V_new    = reshape(V_stacked,I,J);        
    V_change = V_new - V;
    V        = (1-relaxV) * V + relaxV*V_new; 

    % IN EXCLUSION PERIODS

    V_entry=zeros(I,J);     % value function after reentry into the market
    for o=1:J               % we fill it column by column
        V_col = V_new(:,o); % we use the new V before relaxation, and apply relaxation here also but at the end
        V_entry_col = V_col(Interpol_Lpos).*Interpol_Lval + V_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of V
        V_entry(:,o)= V_entry_col;
    end
    
  % u_def = (c_def.^(1-ga)-1)/(1-ga) + chi*V_entry - psizeta_def_2D/2 .* pi_def.^2;  % utility of consumption during the exclusion period, plus V after re-entry when the exclusion period is over
    u_def =                          + chi*V_entry - psizeta_def_2D/2 .* pi_def.^2;  % utility of consumption during the exclusion period, plus V after re-entry when the exclusion period is over

    B = (1/Delta + rho)*speye(I*J) - A_def;

    u_stacked = reshape(u_def,I*J,1);
    V_stacked = reshape(V_def,I*J,1);

    b = u_stacked + V_stacked/Delta;

    V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS

    V_def_new    = reshape(V_stacked,I,J);        
    V_def_change = V_def_new - V_def;
    V_def        = (1-relaxV) * V_def + relaxV*V_def_new; 

    % Continuation
    dist1(m,n) = max(max(abs(V_change)));
    dist3(m,n) = max(max(abs(V_def_change)));
    if mod(n,100)==0
        disp([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(m,n)) '     dist Q: ' num2str(dist2(m,n)) '     dist V_def: ' num2str(dist3(m,n)) '     dist Q_def: ' num2str(dist4(m,n))])
    end
    if (dist1(m,n)<crit) && (dist2(m,n)<crit)
        disp([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(m,n)) '     dist Q: ' num2str(dist2(m,n)) '     dist V_def: ' num2str(dist3(m,n)) '     dist Q_def: ' num2str(dist4(m,n))]);
        break
    end

end

disp(' ');
if n >= maxit
    disp('ERROR: Value Function NOT Converged');
end
disp(' ');

Vpi     = V;
Vpi_def = V_def;



% RESULTS

Vrest    =res_in.V    -Vc    -Vpi;
Vrest_def=res_in.V_def-Vc_def-Vpi_def;

results.Vc         = Vc;
results.Vpi        = Vpi;
results.Vrest      = Vrest;

results.Vc_def     = Vc_def;
results.Vpi_def    = Vpi_def;
results.Vrest_def  = Vrest_def;

results.Vc_eff     = max(Vc   ,Vc_def);
results.Vpi_eff    = max(Vpi  ,Vpi_def);
results.Vrest_eff  = max(Vrest,Vrest_def);



