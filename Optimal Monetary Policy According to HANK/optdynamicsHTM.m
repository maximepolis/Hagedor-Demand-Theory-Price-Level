function irf = optdynamicsHTM(ec,z0,lam0,T)

bb = ec.btil/ec.bet;
gr = ec.gambar*ec.rhobar;
cf = (1+ec.rhobar)/(1+gr);

DR       = 1 - bb*(1-ec.LAM);  
Uss      = (-1/ec.gam)*(1+gr*ec.w)*exp(-ec.gam*ec.y)*ec.SIG;
M3ss     = Uss*(1-ec.eta)/(1-ec.btil);
M2ss     = 0;
M1ss     = M3ss*ec.btil*ec.LAM/DR;
M4ss     = Uss*ec.gam*(1 - ec.eta*ec.SIGh*ec.LAM/( ec.SIG*(1-ec.btil)*(1-ec.btil)  ) - (M1ss/Uss)*(1-ec.btil)/ec.btil );
M4ss     = M4ss*(1+gr)*ec.w/(1+gr*ec.w);

PSII     = ec.lam*(1+gr)/( (ec.lam-1)*ec.kap*ec.rhobar );

syms y  w   pii SIGnh  SIGh  SIG    muu  z  lam  M1  M2  M3  M4
syms Ly Lw Lpii LSIGnh LSIGh LSIG   Lmu Lz LM1 LM2 LM3 LM4
syms Fy Fw Fpii FSIGnh FSIGh FSIG   Fmu Fz Flam FM1 FM2 FM3 FM4 FLSIGnh

U = (-1/ec.gam)*(1+gr*w)*exp(-ec.gam*y)*SIG;

T1 = SIGh*log(SIGh)/SIG;

AM  = exp( 2*ec.varphi*(y-ec.y));
FAM = exp( 2*ec.varphi*(Fy-ec.y));

%FOC w
f1 = U*(1-2*ec.eta*T1)*gr*w/(1+gr*w)...
     - M1*gr*w/( (1/muu) - (1 + gr*w)  ) - M4*ec.rho*z/(1+gr*z)...
     + M2*ec.rhobar*ec.kap/(1+gr);
f1 = f1/w;

%FOC y
f2 = U*(-ec.gam + 2*ec.eta*ec.varphi*T1) - ec.gam*M1...
      + (1/ec.bet)*LM1*(ec.gam - ec.varphi*(ec.LAM/(ec.mu^2))*(muu^2)*AM)...
      + M3*ec.varphi*(ec.LAM/(ec.mu^2))*(muu^2)*AM + M4;  
  
%FOC mu
f3 = - M1*( (1/muu)/( (1/muu) - (1+gr*w)  ) )...
     + (1/ec.bet)*LM1*( 1 - (ec.LAM/(ec.mu^2))*(muu^2)*AM )...
     + M3*(ec.LAM/(ec.mu^2))*(muu^2)*AM;
   
%FOC SIGnh
f4 = (1-ec.eta)*U - M3 + ec.bet*FM3*(ec.theta*SIGnh/(1-ec.theta + ec.theta*SIGnh) );
   
%FOC PI
f5 = LM2 - M2 + M4*PSII*(ec.y/(1+gr))*(pii - 1);
   
%IS eqn
f6 = ec.gam*(Fy - y) - log(ec.bet*ec.theta) + log(Fmu) + log( (1/muu) - (1+gr*w) )...
       - 0.5*(ec.LAM/(ec.mu^2))*(Fmu^2)*FAM;
% PC
f7 = -log(pii) + ec.kap*(log(y/ec.y) - cf*log(z)) + ( ec.kap*ec.rhobar/(1+gr) )*log(lam/ec.lam) + ec.bet*log(Fpii);
% rather than inputing the whole non-linear PC, we have written down an expression 
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
f12 = log(Flam/ec.lam) - ec.rholam*log(lam/ec.lam);

% defn of aggregate SIG
f13 = -SIG + (1 - ec.eta)*SIGnh + ec.eta*SIGh;

% definition of FLSIGnh
f14 = SIGnh - FLSIGnh;


%% Steady state

f = [f1; f2; f3; f4; f5; f6; f7; f8; f9; f10; f11; f12; f13; f14];
% var     = [y w pii SIGnh SIGh mu z  zet  vsig  lam  M1  M2  M3  M4];
% Lvar    = [Ly Lw Lpii LSIGnh LSIGh Lmu Lz  Lzet  Lvsig  Llamp  LM1  LM2  LM3  LM4];
% Fvar    = [Fy Fw Fpii FSIGnh FSIGh Fmu Fz  Fzet  Fvsig  Flam  FM1  FM2  FM3  FM4];
% varss  = [ec.y ec.w 1 ec.SIGnh ec.SIGh ec.mu 1  zetss  vec.SIGnh  lampss  M1ss  M2ss  M3ss  M4ss];
% 
% fss = subs(f,[var Lvar Fvar],[varss varss varss]);

%Define states
XX   = [ LSIGnh   LM1  LM2  z  lam ];
XXp  = [ FLSIGnh  M1   M2   Fz Flam];
XXss = [ ec.SIGnh M1ss M2ss 1  ec.lam];

YY    = [ y    w    pii  SIGh    SIGnh    SIG    muu    M3   M4];
YYp   = [ Fy   Fw   Fpii FSIGh   FSIGnh   FSIG   Fmu   FM3  FM4];
YYss  = [ ec.y ec.w 1    ec.SIGh ec.SIGnh ec.SIG ec.mu M3ss M4ss];

%Log-linear approx
log_var = [XX(1) XX(4:5) YY(1:7) XXp(1) XXp(4:5) YYp(1:7)]; 
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

% A = AA;
% B = BB;
% A(1:5,:) = AA(1:5,:)/Uss;
% A(:,2:3) = A(:,2:3)*Uss;
% A(:,14:15) = A(:,14:15)*Uss;
% 
% B(1:5,:) = BB(1:5,:)/Uss;
% B(:,2:3) = B(:,2:3)*Uss;
% B(:,14:15) = B(:,14:15)*Uss;

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
XX0 = [ 0 0 0 z0 lam0 ];

XXt = zeros(NK,T);
XXt(:,1) = XX0;

for t=1:T-1
    XXt(:,t+1) = hx*XXt(:,t);
end
YYt = gx*XXt;


zt     = XXt(4,:);
lamt   = XXt(5,:);
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
   
      
  
  
  