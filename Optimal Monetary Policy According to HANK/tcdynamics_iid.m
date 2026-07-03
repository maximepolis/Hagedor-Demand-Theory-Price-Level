function irf = tcdynamics_iid(ec,tc,z0,lam0,zet0,varsig0,T)

gr         = ec.gambar*ec.rhobar;
bb         = ec.btil/ec.bet;
inv_gambar = 1/ec.gambar;

dr_z      = 1 - ec.btil*ec.rhoz*(1-ec.LAM);
dr_zeta   = 1 - ec.btil*ec.rhozeta*(1-ec.LAM);
dr_varsig = 1 - ec.btil*ec.rhovarsig*(1-ec.LAM);


%% Define log-linear equations

syms y  ii  pii  muu  z  zet  varsig  ytilde  lam  SIG p r rstar yn
syms yp iip piip muup zzp zetp varsigp ytildep lamp SIGp LSIGp pp rp rstarp ynp
syms LSIG Lp

x       = y - tc.del*ytilde + tc.chi*zet - tc.XI*varsig;

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

fLSIG   = LSIGp - SIG;

fR      = -r + ii -piip;

fRstar  = -ytilde + ec.THETA*ytildep - inv_gambar*(rstar + zet) - ec.LAM*inv_gambar*mup_flexp - ec.LAM*inv_gambar*varsigp;

fyn    = ec.kap*(yn - ytilde) + ( ec.kap*ec.rhobar/(1+gr) )*lam; 

f = [fIS fmu fytilde fPC fSIG fp fz fzeta fvsig flam fTC fLSIG fR fRstar fyn];

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

%% Make IRF
X0 = [0 0 z0 lam0 zet0 varsig0];

Xt = zeros(NK,T);
Yt = zeros(N-NK,T);

Xt(:,1) = X0;
for t=1:T-1
    Xt(:,t+1) = hx*Xt(:,t);
end


Yt = gx*Xt;

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











