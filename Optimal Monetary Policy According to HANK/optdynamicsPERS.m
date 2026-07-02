function irf = optdynamicsPERS(ec,z0,lam0,T)

binv = 1/ec.bet;
gr = ec.gambar*ec.rhobar;
cf = (1+ec.rhobar)/(1+gr);

PSII     = ec.lam*(1+gr)/( (ec.lam-1)*ec.kap*ec.rhobar );
Uss      = (-1/ec.gam)*(1+gr*ec.w)*exp(-ec.gam*ec.y)*ec.SIG;
M3ss     = Uss*ec.m3;
M2ss     = 0;
M1ss     = Uss*ec.m1;
M4ss     = Uss*ec.m4;
M5ss     = Uss*ec.m5;

syms y  w  pii  SIG  sigh  muu  z  lam  M1  M2  M3  M4   M5  ii
syms Ly Lw Lpii LSIG Lsigh Lmu Lz Llam LM1  LM2 LM3 LM4 FM5 Fii
syms Fy Fw Fpii FSIG Fsigh Fmu Fz Flam FM1 FM2 FM3 FM4  LM5 Lii FLw FLmu FLSIG

tauw = 1 - ec.w;
tau  = 1 - 1/ec.lam;

Ut        = -(1/ec.gam)*(1+gr*w)*exp(-ec.gam*y)*SIG;
AM        = exp(ec.varphi*(y-ec.y));

focyt     = Ut + M1 - binv*LM1 - M4/ec.gam - ec.varphi*M5*ec.w*ec.sig*AM/ec.gam;

focwt     = gr*w*Ut/(1+gr*w) - M1*gr*w/( (1/muu) - (1+gr*w) )...
            + M2*ec.rhobar*ec.kap/(1+gr)...
            - M4*ec.rho*z/(1+gr*z) - M5*ec.rhoxi*Fmu*gr*w*Fsigh;
        
focSIGt   = Ut + ec.bet*ec.theta*SIG*FM3/(1-ec.theta  +ec.theta*SIG) - M3; 

focmut    = - (M1/( 1 - muu*(1+gr*w))) + binv*LM1 - (binv*LM1 - M3)*( (ec.gam*muu*sigh)^2 )...
            - ec.rhoxi*(Fmu/muu)*M5*Fsigh + binv*ec.rhoxi*muu*( (1/Lmu) - 1-gr*Lw )*LM5*sigh;
        
focsight  =   - (binv*LM1 - M3)*( sigh*(ec.gam*muu)^2 ) - M5 ...
              + binv*ec.rhoxi*muu*( (1/Lmu) - 1-gr*Lw )*LM5;
          
focpit    = LM2 - M2 + M4*PSII*(ec.y/(1+gr))*(pii - 1);        

fIS       = ec.gam*(Fy - y) - log(ec.bet*ec.theta) + log(Fmu) + log( (1/muu) - (1+gr*w) )...
            - 0.5*( ( ec.gam*Fmu*Fsigh)^2 );
   
fPC        = -log(pii) + ec.kap*(log(y/ec.y) - cf*log(z)) + ( ec.kap*ec.rhobar/(1+gr) )*log(lam/ec.lam) + ec.bet*log(Fpii);

fSIG       = 0.5*( ( ec.gam*muu*sigh)^2) + log(1-ec.theta + ec.theta*LSIG) - log(SIG);

fGDP       = - y + z*(ec.rho*log(w) + ec.xibar)/(1+gr*z);

fsigh      = -sigh  + ec.w*ec.sig*AM + ec.rhoxi*Fmu*( (1/muu) - 1 - gr*w)*Fsigh;

fz         = log(Fz) - ec.rhoz*log(z);

flam       = log(Flam/ec.lam) - ec.rholam*log(lam/ec.lam);

fLwt       = w - FLw;

fLmut      = muu - FLmu;

fnomit     = -(1/muu) + 1+gr*w + (ec.theta*Fpii/ii)*(1/Fmu);

fLSIGt     = SIG - FLSIG;


f = [focyt ; focwt; focSIGt; focmut; focsight; focpit; fIS; fPC; fSIG; fGDP; fsigh; fz; flam; fLwt; fLmut; fnomit; fLSIGt];

%Define states
XX   = [ LSIG  LM1   LM2   LM5  Lw   Lmu   z  lam];
XXp  = [ FLSIG   M1    M2    M5   FLw  FLmu  Fz Flam];
XXss = [ ec.SIG M1ss  M2ss  M5ss ec.w ec.mu 1  ec.lam];

YY    = [ y    w    pii  muu    sigh    ii   SIG    M3   M4];
YYp   = [ Fy   Fw   Fpii Fmu   Fsigh   Fii  FSIG   FM3  FM4];
YYss  = [ ec.y ec.w 1    ec.mu ec.sigh ec.R ec.SIG M3ss M4ss];

%Log-linear approx
log_var = [XX(1) XX(end-1:end) YY(1:6) XXp(1) XXp(end-1:end) YYp(1:6)]; % linearize (rather than log-linearize) interest rate, tb/y, ca/y
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
if max(abs(fcheck))>1e-10
    warning('problem with ss')
end

%Numerical
fxn =  double(subs(fx, [YY XX YYp XXp], [YYss XXss YYss XXss]));
fyn =  double(subs(fy, [YY XX YYp XXp], [YYss XXss YYss XXss]));
fxpn = double(subs(fxp,[YY XX YYp XXp], [YYss XXss YYss XXss]));
fypn = double(subs(fyp,[YY XX YYp XXp], [YYss XXss YYss XXss]));

AA = [-fxpn -fypn];
BB = [fxn fyn];

NK = size(fx,2);
N = size(fx,1);

%Complex Schur Decomposition
[s,t,q,zz] = qz(AA,BB);   

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
       
XX0 = [ 0  0  0  0  0  0  z0  lam0];


XXt = zeros(NK,T);

XXt(:,1) = XX0;

for t=1:T-1
    XXt(:,t+1) = hx*XXt(:,t);
end

YYt = gx*XXt;

zt      = XXt(end-1,:);
lamt   = XXt(end,:);
ynt  = (1 + ec.rhobar)/(1+gr)*zt - (ec.rhobar)/(1+gr)*lamt;

yt      = YYt(1,:);
wt      = YYt(2,:);
pit     = YYt(3,:);
mut     = YYt(4,:);
sight   = YYt(5,:);
iit     = YYt(6,:);
SIGt    = YYt(7,:);

irf.yt      = yt(1:T);
irf.gapt    = yt(1:T) - ynt(1:T); 
irf.ynt     = ynt(1:T);
irf.pit     = pit;
irf.mut     = mut;
irf.SIGt    = SIGt;
irf.wt      = wt;
irf.zt      = zt;
irf.lamt    = lamt;
irf.sight   = sight;
irf.it     = iit;




