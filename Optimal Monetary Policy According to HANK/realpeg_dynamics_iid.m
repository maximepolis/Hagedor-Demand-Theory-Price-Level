function irf = realpeg_dynamics_iid(ec,r0,T)

gr         = ec.gambar*ec.rhobar;
bb         = ec.btil/ec.bet;
inv_gambar = 1/ec.gambar;


%% Define log-linear equations

syms y  muu muur  r  w
syms yp muup muurp rp wp

fIS     = -y + ec.THETA*yp - inv_gambar*r - ec.LAM*inv_gambar*muup;

fmu     = -muu -ec.gambar*(1-ec.btil)*( (1+gr)*ec.w/(1+gr*ec.w) )*y  + ec.btil*(muup + r);

fmur    = -muur + ec.btil*(muurp+ r);

fw      = (1+gr)*y/ec.rhobar - w;

frealpeg= rp - ec.rhor*r;

f = [fIS fmu fw fmur frealpeg];

%Declare X and Y vectors
X  = r;
Xp = rp;

Y  = [y  muu  w  muur];
Yp = [yp muup wp muurp];

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

n = size(fxn,1);

A11 = fypn(1:n-1,:);
A12 = fxpn(1:n-1,:);
B11 = -fyn(1:n-1,:);
B12 = -fxn(1:n-1,:);

gx = (ec.rhor*A11 - B11)\(B12 - ec.rhor*A12);

%% Make IRF

rt = zeros(1,T);
SIGt = zeros(1,T+1);
SIGrt = zeros(1,T+1);
SIGact = zeros(1,T+1);

rt(1) = r0;
for t=1:T-1
    rt(t+1) = ec.rhor*rt(t);
end

Yt = gx*rt;
yt      = Yt(1,:);
mut     = Yt(2,:);
wt      = Yt(3,:);
murt    = Yt(4,:);


SIGt(1) = 0;
SIGrt(1) = 0;
for t=2:T+1
    SIGt(t)   = ec.LAM*mut(t-1)   - (ec.THETA-1)*ec.gambar*yt(t-1) + bb*SIGt(t-1);
    SIGact(t) = ec.LAM*mut(t-1)   + bb*SIGact(t-1);
    SIGrt(t)  = ec.LAM*murt(t-1)  + bb*SIGrt(t-1);  
end
   


irf.yt      = yt;
irf.mut     = mut;
irf.murt    = murt;
irf.SIGt    = SIGt(2:end);
irf.rt      = rt;
irf.wt      = wt;
irf.SIGrt   = SIGrt(2:end);
irf.SIGact  = SIGact(2:end);











