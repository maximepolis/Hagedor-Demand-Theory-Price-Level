function [irf,tc] = optdynamics_profits(ec,z0,lam0,zet0,varsig0,T)

gr = ec.gambar*ec.rhobar;
OS =  ec.OMEGA/(1-ec.btil+ec.OMEGA);
LS = (1+ec.LAM)/(1-ec.LAM);
bb = ec.btil/ec.bet;
inv_gambar = 1/ec.gambar;
dddy = (ec.lam-1)/ec.lam - (1/ec.lam)*(1+gr)/ec.rhobar;

dr_z      = 1 - ec.btil*ec.rhoz*(1-ec.LAM);
dr        = 1 - bb*(1 - ec.LAM);


%% Target Criterion

if ec.LAM==0
    tc.Upsilon  = 1;
else
    tc. Upsilon = 1 + gr*OS*( ec.OMEGA*( 2/( ec.LAM*(1-ec.LAM)  ) - 1)  - 1);
end
tc.del      = (1/tc.Upsilon)*( 1 + LS*gr*ec.OMEGA/(dr_z*(1+ec.rhobar)) );
tc.K        = (gr/(1-ec.btil))*(dr/( (1-bb)*(1-ec.LAM)*(1+ec.OMEGA/(1-ec.btil))) )*(1-ec.etad)*ec.mu*ec.mu/ec.etad;


%% Define log-linear equations

syms x y  ii  pii  muu  z  zet  varsig  ytilde  lam  SIG p yn V dC 
syms xp yp iip piip muup zzp zetp varsigp ytildep lamp SIGp LSIGp pp ynp Vp dCp
syms Lx LSIG Lp

fex       = -x + y - tc.del*ytilde;

fIS     = -y + ec.THETA*yp - inv_gambar*(ii - piip + zet) - ec.LAM*inv_gambar*muup - ec.LAM*inv_gambar*varsigp;

fmu     = -muu -ec.gambar*(1-ec.btil)*( (1+gr)*ec.w/(1+gr*ec.w) )*( y - (1/(1+gr))*z  ) + ec.btil*(muup + ii - piip);

fytilde = ytilde - (1+ec.rhobar)*z/(1+gr);

fPC     = -pii + ec.kap*(y - ytilde) + ( ec.kap*ec.rhobar/(1+gr) )*lam + ec.bet*piip;

fSIG    = -SIG + ec.LAM*(muu  + ec.varphi*ec.y*y + varsig) + bb*LSIG;

fp      = p - Lp - pii;

fz      = zzp - ec.rhoz*z;

flam    = lamp - ec.rholam*lam;

fTC     = tc.Upsilon*(x - bb*Lx) + ( ec.lam/(ec.lam-1) )*(p - bb*Lp) + tc.K*dddy*(1-bb)*V;

fTC0    = tc.Upsilon*x + ( ec.lam/(ec.lam-1) )*p + tc.K*dddy*V;

fLSIG   = LSIGp - SIG;

fy_n    = yn - ytilde +  ( ec.rhobar/(1+gr) )*lam; 

fVtilde = -V + dddy*y +(1+ec.rhobar)*z/(ec.rhobar*ec.lam) + ec.btil*Vp;

fdC    = (1/ec.etad)*ec.mu*V - dC; %=(Cd - Cnd)/y

f = [fex fIS fmu fytilde fPC fSIG fp fz flam fTC fLSIG fy_n fVtilde fdC];

%Declare X and Y vectors
X  = [LSIG  Lp Lx z  lam];
Xp = [LSIGp p  x  zzp lamp];

Y  = [y  pii  ii  muu  SIG  ytilde  yn  V dC];
Yp = [yp piip iip muup SIGp ytildep ynp Vp dCp];

%differentiate
fx  = jacobian(f,X);
fy  = jacobian(f,Y);
fxp = jacobian(f,Xp);
fyp = jacobian(f,Yp);

%Numerical
fxn =  double(fx);
fyn =  double(fy);
fxpn = double(fxp);
fypn = double(fyp);

A = [-fxpn -fypn];
B = [fxn fyn];

N = size(fx,1);
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

f0 = [fex fIS fmu fytilde fPC fSIG fp fz flam fTC0 fLSIG fy_n fVtilde fdC];

%differentiate
f0x  = jacobian(f0,X);
f0y  = jacobian(f0,Y);
f0xp = jacobian(f0,Xp);
f0yp = jacobian(f0,Yp);

%Numerical
f0xn =  double(f0x);
f0yn =  double(f0y);
f0xpn = double(f0xp);
f0ypn = double(f0yp);

A0x = -f0xpn;
A0y = -f0ypn;
B0x = f0xn;
B0y = f0yn;
C0 = [A0x + A0y*gx,  - B0y];

hg = C0\B0x;
hx0 = hg(1:NK,1:NK);
gx0 = hg(NK+1:end,1:NK);

%% Make IRF
X0 = [0 0 0 z0 lam0];

Xt = zeros(NK,T);
Yt = zeros(N-NK,T);

Xt(:,1) = X0;
Yt(:,1) = gx0*Xt(:,1);
Xt(:,2) = hx0*Xt(:,1); %date 0 to date 1 transition of states

for t=2:T-1
    Xt(:,t+1) = hx*Xt(:,t);
end

Yt(:,2:end) = gx*Xt(:,2:end);

zt     = Xt(4,:);
lamt   = Xt(5,:);

yt      = Yt(1,:);
pit     = Yt(2,:);
it      = Yt(3,:);
mut     = Yt(4,:);
SIGt    = Yt(5,:);
ytildet = Yt(6,:);
ynt     = Yt(7,:);
Vt      = Yt(8,:);
dCt     = Yt(9,:);

irf.yt      = yt;
irf.gapt    = yt - ytildet; 
irf.pit     = pit;
irf.it      = it;
irf.mut     = mut;
irf.SIGt    = SIGt;
irf.zt      = zt;
irf.lamt    = lamt;
irf.ytildet = ytildet;
irf.ynt     = ynt;
irf.Vt      = Vt;
irf.dCt     = dCt;











