% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

% Computes the HJB with optimal inflation

function results = f2_HJB_Inflation(parameters)

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


%%%%%%%%%%%%
%% VARIABLES

a_1D  = linspace(amin,amax,I)';   % wealth vector
z_1D  = linspace(zmin,zmax,J);    % productivity vector
a_2D  = a_1D*ones(1,J);           % 2D version of the a grid
z_2D  = ones(I,1)*z_1D;           % 2D version of the z grid

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

% Finite difference approximation of the partial derivatives
dVda_f = zeros(I,J);
dVda_b = zeros(I,J);

% Construct matrix Aswitch summarizing the evolution of z
yy    = - s2/dz2 - mu/dz;
chi_1 = s2/(2*dz2);
zeta  = mu/dz + s2/(2*dz2) ;

% This will be the upperdiagonal of the matrix Aswitch
updiag=zeros(I,1); % This is necessary because of the peculiar way spdiags is defined.
for j=1:J
    updiag=[updiag;repmat(zeta(j),I,1)];
end

% This will be the center diagonal of the matrix Aswitch
centdiag=repmat(chi_1(1)+yy(1),I,1);
for j=2:J-1
    centdiag=[centdiag;repmat(yy(j),I,1)];
end
centdiag=[centdiag;repmat(yy(J)+zeta(J),I,1)];

% This will be the lower diagonal of the matrix Aswitch
lowdiag=repmat(chi_1(2),I,1);
for j=3:J
    lowdiag=[lowdiag;repmat(chi_1(j),I,1)];
end

% Add up the upper, center, and lower diagonal into a sparse matrix
Aswitch = spdiags(centdiag,0,I*J,I*J) + spdiags(lowdiag,-I,I*J,I*J) + spdiags(updiag,I,I*J,I*J);


%%%%%%%%%%%%%%%%
%% INITIAL GUESS

w       = 1; % Constant

V       = ((w*exp(z_2D) + delta.*a_2D).^(1-ga)-1)/(1-ga)/rho;
V_def   = ((1 -d0 -d1).^(1-ga)-1)/(1-ga)/(rho + chi) + chi * ones(I,1)*V(I,:)/(rho + chi);
Q       = (lambda + delta) / (lambda +r_bar) *ones(I,J);
Q_def   = theta*ones(I,J);
d       = zeros(I,J);

% override that guess
if phi>0.2
    load guess V V_def Q Q_def d;
end

dist1 = zeros(maxitD*maxit,1);
dist2 = zeros(maxitD*maxit,1);
dist3 = zeros(maxitD*maxit,1);
dist4 = zeros(maxitD*maxit,1);
distd = zeros(maxitD,1);

format long;

%%%%%%%%%%%%%%%%%%%%%%%%%%
%% HAMILTON-JACOBI-BELLMAN

error_innerloop=0;
log_=pad(' ',175); % save the log in this variable, in case we call this function using the parallel toolbox

results.d_0=d;

for m=1:maxitD
    
    d_saved=d;
    
    for n=1:maxit
        
        V_old=V;
        Q_old=Q;
        V_def_old=V_def;
        Q_def_old=Q_def;
        
        %% A,V,Q IN REPAYMENT PERIODS
        
        for repeat=1:4 % running this part several times in a row, with low relaxation parameters, works better than once with faster adjustment

            r = (lambda+delta)./Q -lambda;

            % forward difference
            dVda_f(1:I-1,:) = (V(2:I,:)-V(1:I-1,:))/da;
            dVda_f(I,:) = Q(I,:) .* (w*exp(z_1D) + Q(I,:) .*r(I,:).*amax).^(-ga);  % will never be used, but impose state constraint a<=amax just in case
            % backward difference
            dVda_b(2:I,:) = (V(2:I,:)-V(1:I-1,:))/da;
            dVda_b(1,:) = Q(1,:) .* (w*exp(z_1D) + Q(1,:) .*r(1,:).*amin).^(-ga);  % state constraint boundary condition

            % consumption and savings with forward difference
            cf  = (dVda_f ./Q).^(-1/ga) ;
            pif = Q.*cf.^(-ga) .* (-a_2D./psizeta_2D);
            sf  = (r-pif).*a_2D + (w*exp(z_2D) - cf)./Q;
            sf(end,:)=min(sf(end,:),0); % needed in order to prevent numerical issues (there were some 1e-17 values here creating trouble)
            % consumption and savings with backward difference
            cb  = (dVda_b ./Q).^(-1/ga);
            pib = Q.*cb.^(-ga) .* (-a_2D./psizeta_2D);
            sb  = (r-pib).*a_2D + (w*exp(z_2D) - cb)./Q;
            sb(1,:)=max(sb(1,:),0); % needed in order to prevent numerical issues (there were some 1e-17 values here creating trouble)
            % consumption and derivative of value function at steady state
            pi0 = (pif + pib)/2;
            c0  = w*exp(z_2D) +  Q.* (r-pi0).*a_2D;
            dVda_0 = Q.* c0.^(-ga);

            % dVda_upwind makes a choice of forward or backward differences based on the sign of the drift
            I_f = sf > 0; % positive drift --> forward difference
            I_b = sb < 0; % negative drift --> backward difference
            I_0 = (1-I_f-I_b);  % zero drift

            I_ff=I_f;
            I_bb=I_b;
            I_00=I_0;

            dVda_upwind = dVda_f.*I_f + dVda_b.*I_b + dVda_0.*I_0; % important to include third term

            % now that we have dVda_upwind, we can continue

            c = (dVda_upwind./Q).^(-1/ga);
            pi = Q.* c.^(-ga) .* (-a_2D./psizeta_2D);
            u = (c.^(1-ga)-1)/(1-ga) + phi*d.*V_def - psizeta_2D/2 .* pi.^2;

            % construct matrix A
            elem_X = - min(sb,0)/da;
            elem_Y = - max(sf,0)/da + min(sb,0)/da - phi*d ;
            elem_Z =   max(sf,0)/da;

            updiag=0; % this is needed because of the peculiarity of spdiags.
            for j=1:J
                updiag=[updiag;elem_Z(1:I-1,j);0];
            end

            centdiag=reshape(elem_Y,I*J,1);

            lowdiag=elem_X(2:I,1);
            for j=2:J
                lowdiag=[lowdiag;0;elem_X(2:I,j)];
            end

            A = spdiags(centdiag,0,I*J,I*J) + spdiags([updiag;0],1,I*J,I*J) + spdiags([lowdiag;0],-1,I*J,I*J) + Aswitch;

            % now construct the other objects and solve the system of equations
            B = (1/Delta + rho)*speye(I*J) - A;

            u_stacked = reshape(u,I*J,1);
            V_stacked = reshape(V,I*J,1);

            b = u_stacked + V_stacked/Delta;

            V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS

            V_new    = reshape(V_stacked,I,J);        
            V_change = V_new - V;
            V        = V + relaxV*(V_change); 

            % BOND PRICES IN REPAYMENT PERIODS

            B_Q         = (1/Delta + r_bar + lambda)*speye(I*J) - A;
            pi_q        = reshape(pi,I*J,1);
            B_Q         = B_Q + spdiags(pi_q,0,I*J,I*J);  
            u_Q         = (lambda+delta)*ones(I,J) + phi*d.*Q_def;
            u_stacked_Q = reshape(u_Q,I*J,1);
            Q_stacked   = reshape(Q,I*J,1);
            b_Q         = u_stacked_Q + Q_stacked/Delta;
            Q_stacked   = B_Q\b_Q; % SOLVE SYSTEM OF EQUATIONS
            Q_new       = reshape(Q_stacked,I,J);
            Q_change    = Q_new - Q; 
            Q           = Q + relaxQ*(Q_change);

        end
        
        
        
        %% A,V,Q IN EXCLUSION PERIODS

        % forward difference
        dVda_f(1:I-1,:) = (V_def(2:I,:)-V_def(1:I-1,:))/da;
        dVda_f(I,:) = 0;  % will never be used, but impose state constraint a<=amax just in case
        % backward difference
        dVda_b(2:I,:) = (V_def(2:I,:)-V_def(1:I-1,:))/da;
        dVda_b(1,:) = 0;  % state constraint boundary condition
        
        % savings with forward and backward difference
        sf  = (a_2D.^2)./psizeta_def_2D .* dVda_f;
        sb  = (a_2D.^2)./psizeta_def_2D .* dVda_b;
        
        % dVda_upwind makes a choice of forward or backward differences based on the sign of the drift
        I_f = sf > 0; % positive drift --> forward difference
        I_b = sb < 0; % negative drift --> backward difference
        I_0 = (1-I_f-I_b);  % zero drift

        dVda_upwind = dVda_f.*I_f + dVda_b.*I_b ; % no need to include third term here
        
        pi_def = -a_2D./psizeta_def_2D .* dVda_upwind;

        % construct matrix A
        elem_X = - min(sb,0)/da;
        elem_Y = - max(sf,0)/da + min(sb,0)/da - chi ;
        elem_Z =   max(sf,0)/da;
        
        updiag=0; % this is needed because of the peculiarity of spdiags.
        for j=1:J
            updiag=[updiag;elem_Z(1:I-1,j);0];
        end
        
        centdiag=reshape(elem_Y,I*J,1);
        
        lowdiag=elem_X(2:I,1);
        for j=2:J
            lowdiag=[lowdiag;0;elem_X(2:I,j)];
        end
        
        A_def = spdiags(centdiag,0,I*J,I*J) + spdiags([updiag;0],1,I*J,I*J) + spdiags([lowdiag;0],-1,I*J,I*J) + Aswitch;
        
        % then calculate u for the case with default
        
        c_def = exp(z_2D) - max((d0 *exp(z_2D) + d1* exp(2*z_2D)).*((1-a_2D).^kappa),0);

        V_eff =(1-d).*V + d.*V_def;
        V_entry=zeros(I,J);     % value function after reentry into the market
        for o=1:J               % we fill it column by column
            V_col = V_eff(:,o);
            V_entry_col = V_col(Interpol_Lpos).*Interpol_Lval + V_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of V
            V_entry(:,o)= V_entry_col;
        end
        
        u_def = (c_def.^(1-ga)-1)/(1-ga) + chi*V_entry - psizeta_def_2D/2 .* pi_def.^2;  % utility of consumption during the exclusion period, plus V after re-entry when the exclusion period is over

        % finally solve the system of equations
        
        B = (1/Delta + rho)*speye(I*J) - A_def;
        
        u_stacked = reshape(u_def,I*J,1);
        V_stacked = reshape(V_def,I*J,1);
        
        b = u_stacked + V_stacked/Delta;
        
        V_stacked = B\b; % SOLVE SYSTEM OF EQUATIONS
        
        V_def_new    = reshape(V_stacked,I,J);        
        V_def_change = V_def_new - V_def;
        V_def        = V_def + relaxV*(V_def_change); 
        
       
        % BOND PRICES IN EXCLUSION PERIODS

        
        B_Q         = (1/Delta + r_bar)*speye(I*J) - A_def;
        pi_q        = reshape(pi_def,I*J,1);
        B_Q         = B_Q + spdiags(pi_q,0,I*J,I*J);  

        Q_eff =(1-d).*Q + d.*Q_def;
        Q_entry=zeros(I,J);     % value of bond at reentry into the market
        for o=1:J               % we fill it column by column
            Q_col = Q_eff(:,o);
            Q_entry_col = Q_col(Interpol_Lpos).*Interpol_Lval + Q_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of Q
            Q_entry(:,o)= Q_entry_col;
        end
        
        u_Q         =  chi * theta .*Q_entry;
        
        
        u_stacked_Q = reshape(u_Q,I*J,1);
        Q_stacked   = reshape(Q_def,I*J,1);
        b_Q         = u_stacked_Q + Q_stacked/Delta;
        Q_stacked   = B_Q\b_Q; % SOLVE SYSTEM OF EQUATIONS
        Q_def_new   = reshape(Q_stacked,I,J);
        Q_def_change= Q_def_new - Q_def; 
        Q_def       = Q_def + relaxQ*(Q_def_change);
        


        %% Continuation
        mn=(m-1)*maxit+n;
        dist1(mn) = max(max(abs(V_change)));
        dist2(mn) = max(max(abs(Q_change)));
        dist3(mn) = max(max(abs(V_def_change)));
        dist4(mn) = max(max(abs(Q_def_change)));
        if mod(n,100)==0
            log__=pad([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(mn)) '     dist Q: ' num2str(dist2(mn)) '     dist V_def: ' num2str(dist3(mn)) '     dist Q_def: ' num2str(dist4(mn))],175);
            disp(log__)
            log_=[log_;log__];
        end
        if ((dist1(mn)<crit) && (dist2(mn)<crit) && (dist3(mn)<crit) && (dist4(mn)<crit))
            log__=pad([ num2str(m) '-inf  d_it: ' num2str(m) '  HJB_it: ' num2str(n) '     dist V: ' num2str(dist1(mn)) '     dist Q: ' num2str(dist2(mn)) '     dist V_def: ' num2str(dist3(mn)) '     dist Q_def: ' num2str(dist4(mn))],175);
            disp(log__);
            log_=[log_;log__];
            break
        end
        
    end
    
    if n >= maxit
        log__=pad('ERROR: Value Function NOT Converged',175);
        disp(log__);
        log_=[log_;log__];
        relaxV=relaxV*0.75+parameters.relaxV/12;
        relaxQ=relaxQ*0.75+parameters.relaxV/72;
    else
        relaxV=parameters.relaxV;
        relaxQ=parameters.relaxQ;
    end
    
    d_new = V_def > V;
    distd(m) = sum(sum(abs(d_new-d)));
    d=d_new;
    
    eval(['results.d_' num2str(m) '=d;']);

    log__=pad(['OUTER LOOP iteration: ' num2str(m) '        d_change: ' num2str(distd(m))],175);
    disp(log__);
    log_=[log_;log__];
    if and(m>1,distd(m)<critD)
        if n >= maxit
            error_innerloop = error_innerloop +1;
            if error_innerloop<30
                log__=pad(['not stopping yet: retry ' num2str(error_innerloop)],175);
                disp(log__);
                log_=[log_;log__];
            else
                error_innerloop = 0;
                relaxV=parameters.relaxV;
                relaxQ=parameters.relaxQ;
                break
            end
        else
            error_innerloop = 0;
            relaxV=parameters.relaxV;
            relaxQ=parameters.relaxQ;
            break
        end
    end
    
end

d=d_saved; % undo the last update of d, so that V,Q,c,etc, are derived from the d we store in results

if m == maxitD
    log__=pad('ERROR: Outer Algorithm NOT Converged',175);
    disp(log__);
    log_=[log_;log__];
end


% calculate time-to-default
B_ttd = - A;
u_stacked = ones(I*J,1);
V_stacked = B_ttd\u_stacked; % SOLVE SYSTEM OF EQUATIONS
ttd    = reshape(V_stacked,I,J);        


% calculate real version of Q, for descomposition of rdif

log__=pad(' ',175);
disp(log__);
log_=[log_;log__];

Qr=Q;
Qr_def=Q_def;

for n=1:maxit

    B_Qr        = (1/Delta +  r_bar + lambda)*speye(I*J) - A;
    u_Qr        = (lambda+delta)*ones(I,J) + phi*d.*Qr_def;
    u_stacked_Qr= reshape(u_Qr,I*J,1);
    Qr_stacked  = reshape(Qr,I*J,1);
    b_Qr        = u_stacked_Qr + Qr_stacked/Delta;
    Qr_stacked  = B_Qr\b_Qr; %SOLVE SYSTEM OF EQUATIONS
    Qr_new      = reshape(Qr_stacked,I,J);
    Qr_change   = Qr_new - Qr; 
    Qr          = Qr + relaxQ*Qr_change;

    B_Qr        = (1/Delta + r_bar)*speye(I*J) - A_def;

    Qr_eff =(1-d).*Qr + d.*Qr_def;
    Qr_entry=zeros(I,J);     % value of bond at reentry into the market
    for o=1:J                % we fill it column by column
        Qr_col = Qr_eff(:,o); % we use the new Q before relaxation, and apply relaxation here also, but at the end
        Qr_entry_col = Qr_col(Interpol_Lpos).*Interpol_Lval + Qr_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of Q
        Qr_entry(:,o)= Qr_entry_col;
    end

    u_Qr         =  chi * theta .*Qr_entry;

    u_stacked_Qr = reshape(u_Qr,I*J,1);
    Qr_stacked   = reshape(Qr_def,I*J,1);
    b_Qr         = u_stacked_Qr + Qr_stacked/Delta;
    Qr_stacked   = B_Qr\b_Qr; % SOLVE SYSTEM OF EQUATIONS
    Qr_def_new   = reshape(Qr_stacked,I,J);
    Qr_def_change= Qr_def_new - Qr_def; 
    Qr_def       = Qr_def + relaxQ*Qr_def_change;

    % Continuation
    if mod(n,100)==0
        log__=pad([ num2str(n) ' - Qr crit: ' num2str(max(max(abs(Qr_change))))],175);
        disp(log__)
        log_=[log_;log__];
    end
    if (max(max(abs(Qr_change)))<crit)
        log__=pad([ num2str(n) ' - Qr crit: ' num2str(max(max(abs(Qr_change))))],175);
        disp(log__);
        log_=[log_;log__];
        break
    end

end

Q_real=Qr;
Q_real_def=Qr_def;

% RESULTS
results.u       = u;
results.a       = a_1D;
results.aa      = a_2D;
results.z       = z_1D;
results.zz      = z_2D;
results.V       = V;
results.V_def   = V_def;
results.A       = A;
results.A_def   = A_def;
results.c       = c;
results.c_def   = c_def;
results.pi      = pi;
results.pi_def  = pi_def;
results.w       = w;
results.da      = da;
results.dz      = dz;
results.s       = (r-pi).*a_2D + (w*exp(z_2D) - c)./Q;
results.s_def   =   -pi .*a_2D;
results.d       = d;
results.Q       = Q;
results.Q_def   = Q_def;
results.Q_real  = Q_real;
results.Q_real_def = Q_real_def;
results.r       = (lambda+delta)./Q      -lambda;
results.r_def   = (lambda+delta)./Q_def  -lambda;
results.r_real  = (lambda+delta)./Q_real -lambda;
results.r_real_def = (lambda+delta)./Q_real_def -lambda;
results.rinf    = results.r-results.r_real;
results.distQ   = dist2;
results.dist    = dist1;
results.distd   = distd;
results.I_b     = I_bb;
results.I_f     = I_ff;
results.I_0     = I_00;
results.log_    = log_;
results.diter   = m;
results.V_change = V_change;
results.Q_change = Q_change;
results.V_def_change = V_def_change;
results.Q_def_change = Q_def_change;
results.dist1=dist1(:);
results.dist2=dist2(:);
results.dist3=dist3(:);
results.dist4=dist4(:);
results.ttd  =ttd;

results.V_eff =(1-results.d).*results.V + results.d.*results.V_def;
results.Q_eff =(1-results.d).*results.Q + results.d.*results.Q_def;
results.c_eff =(1-results.d).*results.c + results.d.*results.c_def;
results.s_eff =(1-results.d).*results.s + results.d.*results.s_def;
results.r_eff =(1-results.d).*results.r + results.d.*results.r_def;
results.pi_eff=(1-results.d).*results.pi+ results.d.*results.pi_def;
results.r_real_eff =(1-results.d).*results.r_real + results.d.*results.r_real_def;

