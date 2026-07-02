function out = optwPERS(xin,ec)

w  = xin;

gr = ec.gambar*ec.rhobar;

y = (1+gr)/(1+gr - ec.rhobar*log(w));

mu = (1-ec.btil)/(1 + gr*w);

gam = ec.gambar/y;

sig = ec.sigbar*exp(ec.varphi*(y-1)); 

sigh = w*sig/(1-ec.btil*ec.rhoxi);

LAM = ( gam*mu*w*sig/(1-ec.btil*ec.rhoxi) )^2;

bet = (1/ec.R)*exp(-LAM/2);

DR       = 1 - (ec.btil/bet)*(1-LAM);  
bb       = ec.btil/bet;

LAMoversigh = (gam*gam*mu*mu*w*sig/(1-ec.btil*ec.rhoxi));

m5       = (1-bb)*LAMoversigh/( (1-ec.btil)*( DR*(1-ec.rhoxi) + ec.rhoxi*(1-bb)^2 ) );
m1       = sigh*m5*ec.btil*(1-ec.rhoxi)/(1-bb);
m4       = gam*( 1 + (1-(1/bet))*m1 - ec.varphi*m5*w*sig/gam   );

%FOC w
out = (1+gr)*w/(1+gr*w)  - m1*(1+gr)*w/( (1/mu) - (1+gr*w) ) - m4/gam - (1+gr)*m5*ec.rhoxi*mu*w*sigh;
 
  
   
   
   
      
  
  
  