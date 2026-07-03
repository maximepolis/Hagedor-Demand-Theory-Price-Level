function out = optwHTM(xin,ec)

w  = xin;

gr = ec.gambar*ec.rhobar;

y = (1+gr)/(1+gr - ec.rhobar*log(w));

mu = (1-ec.btil)/(1 + gr*w);

gam = ec.gambar/y;

rho = ec.rhobar*y;

sig = ec.sigbar*exp(ec.varphi*(y-1)); 

LAM = ( gam*mu*w*sig )^2;

SIGhss = exp(0.5*LAM/( (1-ec.btil)^2 ));

SIGnhss    = ( (1-ec.theta)*exp(LAM/2) )/( 1-ec.theta*exp(LAM/2) );

SIGss = (1 - ec.eta)*SIGnhss + ec.eta*SIGhss;

DR       = 1 - (ec.btil/ec.bet)*(1-LAM);  
U        = (-1/gam)*(1+gr*w)*exp(-gam*y)*SIGss;
M3       = U*(1-ec.eta)/(1-ec.btil);
M1       = M3*ec.btil*LAM/DR;
M4       = U*gam*(1 - ec.eta*SIGhss*LAM/( SIGss*(1-ec.btil)*(1-ec.btil)  ) - (M1/U)*(1-ec.btil)/ec.btil )*(1+gr)*w/(1+gr*w) ;

T1 = SIGhss*log(SIGhss)/SIGss;

%FOC w
f1 = U*(1-2*ec.eta*T1)*gr*w/(1+gr*w) - M1*gr*w/( (1/mu) - (1 + gr*w)  ) - M4*rho/(1+gr);
%FOC y
f2 = U*(-gam + 2*ec.eta*ec.varphi*T1) - gam*M1 + (1/ec.bet)*M1*(gam - ec.varphi*LAM) + M3*ec.varphi*LAM + M4;

%combined FOC y and FOC w  
f12 = (1+gr)*f1/rho + f2;
 
out =  f12;
   
  
   
   
   
      
  
  
  