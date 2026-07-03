% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022, based on codes from GALO NUNO AND BENJAMIN MOLL

% Computes the KFE

function results = f3_KFE(parameters,results)

% UNPACK PARAMETERS

I      = parameters.I;           % number of a points
J      = parameters.J;           % number of z points
amin   = parameters.amin;        % borrowing constraint
amax   = parameters.amax;        % range a

maxit  = parameters.maxit;       % maximum number of iterations in the HJB loop
crit   = parameters.crit;        % criterion HJB loop
chi    = parameters.chi;         % Exclusion parameter
phi    = parameters.phi;         % Default option arrival rate
theta  = parameters.theta;       % Surviving share of debt after a partial default episode

d      = results.d;

da       = results.da;
dz       = results.dz;
AT       = (results.A)';
A_def_T  = (results.A_def)';

log_     = results.log_;         % save the log in this variable, in case we call this function using the parallel toolbox
                                 % (here we add to the previous log)

% interpolation (to find the correct a spot after partial default)

a_1D  = linspace(amin,amax,I)';   % wealth vector
a_1D_theta = a_1D/theta;
Interpol_Lpos = ones(I,1); % low  position for interpolation - if not found, value will be one but weight will be zero
Interpol_Hpos = ones(I,1); % high position for interpolation - if not found, value will be one but weight will be zero
Interpol_Lval = zeros(I,1); % weight of Lpos in interpolation
Interpol_Hval = zeros(I,1); % weight of Hpos in interpolation

for m=1:I % for each output value a
    for n=2:I % look for the corresponding value a/theta
        if and(a_1D_theta(m)<=a_1D(n), a_1D_theta(m)>a_1D(n-1))
            weight = (a_1D_theta(m)-a_1D(n-1))/(a_1D(n)-a_1D(n-1)) ; % weight of upper point
            Interpol_Lpos(m,1) = n-1;                            % if assets are a_1D(n) before partial default, assets are slightly above a_1D(o-1) after default
            Interpol_Hpos(m,1) = n;
            Interpol_Lval(m,1) = 1-weight;
            Interpol_Hval(m,1) = weight;
        end
    end
end


% VARIABLES

g      = zeros(I,J) ;
g_def  = ones(I,J)/(sum(sum(d))*da*dz);
distg  = zeros(maxit,1);

d_stacked        = d(:);

% Solve linear system

for n=1:maxit
    
    g_old = g;

    % interpolate g_def to get g_entry
    
    g_entry=zeros(I,J);     % g_def transformed for reentry into the market
    for o=1:J               % we fill it column by column
        g_col = g_def(:,o);
        g_entry_col = g_col(Interpol_Lpos).*Interpol_Lval + g_col(Interpol_Hpos).*Interpol_Hval; % interpolate from the closest places of g_def
        g_entry(:,o)= g_entry_col;
    end
    g_entry = g_entry * ( sum(sum(g_def)) / sum(sum(g_entry)) );

    % now calculate g and g_def
    
    g_entry_stacked  = g_entry(:);
    
    g_stacked     = AT \ (-chi * g_entry_stacked);
    g_def_stacked = A_def_T \ (-phi .*d_stacked .*g_stacked);
    
    g_stacked     = max(g_stacked,0);     % To avoid numerical errors
    g_def_stacked = max(g_def_stacked,0); % To avoid numerical errors
    
    g_sum  = sum(sum((g_stacked + g_def_stacked)*da*dz));
    g_stacked     = g_stacked    ./g_sum;
    g_def_stacked = g_def_stacked./g_sum;
    
    g = reshape(g_stacked,I,J);
    g_def = reshape(g_def_stacked,I,J);
    
    % check convergence

    distg(n) = sum(sum(abs(g-g_old)));

    log_=[log_;pad(['KFE iter: ' num2str(n) ' - dist g: ' num2str(distg(n))],175)];

    if (distg(n)<crit)
        break
    end
end

results.g     = reshape(g,I,J);
results.g_def = reshape(g_def,I,J);
results.log_  = log_;