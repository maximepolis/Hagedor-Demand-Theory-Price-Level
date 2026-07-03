function [irf,tc] = optdynamics_iid(ec,z0,lam0,zet0,varsig0,T)



gr = ec.gambar*ec.rhobar;
OS =  ec.OMEGA/(1-ec.btil+ec.OMEGA);
LS = (1+ec.LAM)/(1-ec.LAM);
bb = ec.btil/ec.bet;
inv_gambar = 1/ec.gambar;

dr_z      = 1 - ec.btil*ec.rhoz*(1-ec.LAM);
dr_zeta   = 1 - ec.btil*ec.rhozeta*(1-ec.LAM);
dr_varsig = 1 - ec.btil*ec.rhovarsig*(1-ec.LAM);
dr        = 1 - bb*(1 - ec.LAM);


%% Target Criterion

mathbbG = gr*dr*( 1 + ec.OMEGA )*(ec.alphaomu)*(ec.alphaomu)*(ec.theta/(1-ec.theta))*ec.LAM;
mathbbG = mathbbG/( (1-bb)*(1-ec.LAM)*(1-ec.btil+ec.OMEGA) );

if ec.LAM==0
    tc.Upsilon  = 1;
else
    tc. Upsilon = 1 + gr*OS*( ec.OMEGA*( 2/( ec.LAM*(1-ec.LAM)  ) - 1)  - 1);
end
tc.del      = (1/tc.Upsilon)*( 1 + LS*gr*ec.OMEGA/(dr_z*(1+ec.rhobar)) );
tc.chi      = (1/tc.Upsilon)*OS*LS*ec.btil*ec.rhobar/dr_zeta;
tc.XI       = (1/tc.Upsilon)*ec.rhobar*OS*( 2*(1-ec.btil*ec.rhovarsig) + ec.btil*ec.rhovarsig*ec.LAM*(1-ec.LAM) )/( (1-ec.LAM)*dr_varsig );
tc.Upsilon0 = tc.Upsilon + ( 1 + ec.OMEGA )*mathbbG;
tc.del0     = (tc.Upsilon/tc.Upsilon0)*tc.del + (1/tc.Upsilon0)*(1-ec.btil+ec.OMEGA)*mathbbG/( dr_z*(1+ec.rhobar)  );
tc.chi0     = (tc.Upsilon/tc.Upsilon0)*tc.chi + (1/tc.Upsilon0)*ec.btil*mathbbG/( ec.gambar*dr_zeta );
tc.XI0      = (tc.Upsilon/tc.Upsilon0)*tc.XI  - (1/tc.Upsilon0)*ec.btil*ec.rhovarsig*ec.LAM*mathbbG/( ec.gambar*dr_varsig );
tc.varkappa = ((1-ec.btil+ec.OMEGA)/ec.OMEGA)*(ec.LAM/dr_z)/(1+ec.rhobar);

%% Define log-linear equations

syms y  ii  pii  muu  z  zet  varsig  ytilde  lam  SIG p r rstar yn
syms yp iip piip muup zzp zetp varsigp ytildep lamp SIGp LSIGp pp rp rstarp ynp
syms LSIG Lp

x       = y - tc.del*ytilde + tc.chi*zet - tc.XI*varsig;

x0      = y - tc.del0*ytilde + tc.chi0*zet - tc.XI0*varsig;

GAMz        = ec.gambar*(1-ec.btil+ec.OMEGA)/( (1+gr)*dr_z );
GAMzet      = -ec.btil/dr_zeta;
GAMvarsig   = -ec.btil*ec.rhovarsig*ec.LAM/dr_varsig;

GAMtp        = GAMz*zzp + GAMzet*zetp + GAMvarsig*varsigp;
mup_flexp    = GAMtp - ec.gambar*(1 + ec.OMEGA )*ytildep;


fIS     = -y + ec.THETA*yp - inv_gambar*(ii - piip + zet) - ec.LAM*inv_gambar*muup - ec.LAM*inv_gambar*varsigp;

fmu     = -muu -ec.gambar*(1-ec.btil)*( (1+gr)*ec.w/(1+gr*ec.w) )*( y - (1/(1+gr))*z  ) + ec.btil*(muup + ii - piip);

fytilde = ytilde - (1+ec.rhobar)*z/(1+gr);

fPC     = -pii + ec.kap*(y - ytilde) + ( ec.kap*ec.rhobar/(1+gr) )*lam + ec.bet*piip;

fSIG    = -SIG + ec.LAM*(muu  + ec.varphi*ec.y*y + varsig) + bb*LSIG;

fp      = p - Lp - pii;

fz      = zzp - ec.rhoz*z;

fzeta   = zetp - ec.rhozeta*zet;

fvsig   = varsigp - ec.rhovarsig*varsig;

flam    = lamp - ec.rholam*lam;

fTC     = tc.Upsilon*x + ( ec.lam/(ec.lam-1) )*p;

fTC0    = tc.Upsilon0*x0 + ( ec.lam/(ec.lam-1) )*p;

fLSIG   = LSIGp - SIG;

fR      = -r + ii -piip;

fRstar  = -ytilde + ec.THETA*ytildep - inv_gambar*(rstar + zet) - ec.LAM*inv_gambar*mup_flexp - ec.LAM*inv_gambar*varsigp;

fy_n    = yn - ytilde +  ( ec.rhobar/(1+gr) )*lam; 

f = [fIS fmu fytilde fPC fSIG fp fz fzeta fvsig flam fTC fLSIG fR fRstar fy_n];

%Declare X and Y vectors
X  = [LSIG  Lp z  lam  zet  varsig  ];
Xp = [LSIGp p  zzp lamp zetp varsigp ];

Y  = [y  pii  ii  muu  SIG  ytilde r rstar yn];
Yp = [yp piip iip muup SIGp ytildep rp rstarp ynp];

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

f0 = [fIS fmu fytilde fPC fSIG fp fz fzeta fvsig flam fTC0 fLSIG fR fRstar fy_n];

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
X0 = [0 0 z0 lam0 zet0 varsig0];

Xt = zeros(NK,T);
Yt = zeros(N-NK,T);

Xt(:,1) = X0;
Yt(:,1) = gx0*Xt(:,1);
Xt(:,2) = hx0*Xt(:,1); %date 0 to date 1 transition of states

for t=2:T-1
    Xt(:,t+1) = hx*Xt(:,t);
end

Yt(:,2:end) = gx*Xt(:,2:end);

zt     = Xt(3,:);
lamt   = Xt(4,:);
zett   = Xt(5,:);
varsigt= Xt(6,:);


yt      = Yt(1,:);
pit     = Yt(2,:);
it      = Yt(3,:);
mut     = Yt(4,:);
SIGt    = Yt(5,:);
ytildet = Yt(6,:);
rt      = Yt(7,:);
rstart  = Yt(8,:);
ynt     = Yt(9,:);

irf.yt      = yt;
irf.gapt    = yt - ytildet; 
irf.pit     = pit;
irf.it      = it;
irf.mut     = mut;
irf.SIGt    = SIGt;
irf.zt      = zt;
irf.lamt    = lamt;
irf.zett    = zett;
irf.varsigt = varsigt;
irf.ytildet = ytildet;
irf.rt      = rt;
irf.rstart  = rstart;
irf.ynt     = ynt;











