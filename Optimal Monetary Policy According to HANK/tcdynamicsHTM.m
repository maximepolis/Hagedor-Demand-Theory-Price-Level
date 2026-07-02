function irf = tcdynamicsHTM(ec,tc,z0,lam0,T)

gr = ec.gambar*ec.rhobar;
cf = (1+ec.rhobar)/(1+gr);

syms y  w   pii SIGnh  SIGh  SIG    muu  z  lam  M1  M2  M3  M4 p
syms Ly Lw Lpii LSIGnh LSIGh LSIG   Lmu Lz LM1 LM2 LM3 LM4 Lp
syms Fy Fw Fpii FSIGnh FSIGh FSIG   Fmu Fz Flam FM1 FM2 FM3 FM4 FLSIGnh Fp

AM  = exp( 2*ec.varphi*(y-ec.y));
FAM = exp( 2*ec.varphi*(Fy-ec.y));

% TC
fTC = tc.Upsilon*(log(y/ec.y) - tc.del*cf*log(z)) + ( ec.lam/(ec.lam-1) )*log(p);

fp = -log(pii) + log(p) - log(Lp);
   
%IS eqn
f6 = ec.gam*(Fy - y) - log(ec.bet*ec.theta) + log(Fmu) + log( (1/muu) - (1+gr*w) )...
       - 0.5*(ec.LAM/(ec.mu^2))*(Fmu^2)*FAM;
% PC
f7 = -log(pii) + ec.kap*(log(y/ec.y) - log(z)*(1+ec.rhobar)/(1+gr)) + ( ec.kap*ec.rhobar/(1+gr) )*log(lam/ec.lam) + ec.bet*log(Fpii);
% rather than inputing the whole non-linerar PC, we have written down an expression 
% which when log-linearized, gives the correct log-linear PC

% gdp
f8 = - y + z*(ec.rho*log(w) + ec.xibar)/(1+gr*z);

% SIGnh rec
f9 = - log(SIGnh) + 0.5*(ec.LAM/(ec.mu^2))*(muu^2)*AM + log(1-ec.theta + ec.theta*LSIGnh);

% SIGh rec
f10 = -log(SIGh) + 0.5*ec.LAM/( (1-ec.btil)^2 )*( ( (1+gr*ec.w)/(1+gr*w) )^2 )*AM;

% z shock
f11 = log(Fz) - ec.rhoz*log(z);

% lam shock
f12 = Flam - ec.rholam*lam;

% defn of aggregate SIG
f13 = -SIG + (1 - ec.eta)*SIGnh + ec.eta*SIGh;

% definition of FLSIGnh
f14 = SIGnh - FLSIGnh;

%% Steady state

f = [fTC; fp; f6; f7; f8; f9; f10; f11; f12; f13; f14];

%Define states
XX   = [ LSIGnh   Lp z  lam ];
XXp  = [ FLSIGnh  p  Fz Flam];
XXss = [ ec.SIGnh 1  1  ec.lam];

YY    = [ y    w    pii  SIGh    SIGnh    SIG    muu];
YYp   = [ Fy   Fw   Fpii FSIGh   FSIGnh   FSIG   Fmu];
YYss  = [ ec.y ec.w 1    ec.SIGh ec.SIGnh ec.SIG ec.mu];

%Log-linear approx
log_var = [XX YY XXp YYp]; 
f = subs(f, log_var, exp(log_var)); 
   
%differentiate
fx = jacobian(f, XX);
fy= jacobian(f,YY);
fxp = jacobian(f,XXp);
fyp = jacobian(f,YYp);

%Plug back into levels
fx =  subs(fx, log_var, log(log_var));
fy =  subs(fy, log_var, log(log_var));
fxp = subs(fxp, log_var, log(log_var));
fyp = subs(fyp, log_var, log(log_var));

f = subs(f, log_var, log(log_var)); 
fcheck = double(subs(f, [YY XX YYp XXp], [YYss XXss YYss XXss]));


%Numerical
fxn =  double(subs(fx, [YY XX YYp XXp], [YYss XXss YYss XXss]));
fyn =  double(subs(fy, [YY XX YYp XXp], [YYss XXss YYss XXss]));
fxpn = double(subs(fxp,[YY XX YYp XXp], [YYss XXss YYss XXss]));
fypn = double(subs(fyp,[YY XX YYp XXp], [YYss XXss YYss XXss]));

A = [-fxpn -fypn];
B = [fxn fyn];

NK = size(fx,2);

%Complex Schur Decomposition
[s,t,q,zz] = qz(A,B);   

%Pick non-explosive (stable) eigenvalues
slt = (abs(diag(t))<abs(diag(s)));  
nk=sum(slt);

%Reorder the system with stable eigs in upper-left
[s,t,q,zz] = ordqz(s,t,q,zz,slt);   

%Split up the results appropriately
z21 = zz(nk+1:end,1:nk);
z11 = zz(1:nk,1:nk);

s11 = s(1:nk,1:nk);
t11 = t(1:nk,1:nk);

%Identify cases with no/multiple solutions
if nk>NK
    warning('The Equilibrium is Locally Indeterminate')
elseif nk<NK
    warning('No Local Equilibrium Exists')
end

if rank(z11)<nk
    warning('Invertibility condition violated')
end   

%Compute the Solution
z11i = z11\eye(nk);
gx = real(z21*z11i);  
hx = real(z11*(s11\t11)*z11i);

%% make IRF
XX0 = [ 0 0 z0 lam0 ];

XXt = zeros(NK,T);
XXt(:,1) = XX0;

for t=1:T-1
    XXt(:,t+1) = hx*XXt(:,t);
end
YYt = gx*XXt;


zt     = XXt(3,:);
lamt   = XXt(4,:);
yt     = YYt(1,:);
wt     = YYt(2,:);
pit    = YYt(3,:);
SIGht  = YYt(4,:);
SIGnht = YYt(5,:);
SIGt   = YYt(6,:);
mut    = YYt(7,:);
ynt    = ( (1+ec.rhobar)/(1+gr) )*zt - ( ec.rhobar/(1+gr) )*lamt;

irf.yt      = yt;
irf.pit     = pit;
irf.ynt     = ynt;
irf.gapt    = yt - ynt;
irf.mut     = mut;
irf.SIGt    = SIGt;
irf.SIGht   = SIGht;
irf.SIGnht  = SIGnht;
irf.wt      = wt;
irf.zt      = zt;
irf.lamt    = lamt;
   
      
  
  
  