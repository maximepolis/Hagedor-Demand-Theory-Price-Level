function foc_i1=foc_i1BAU(V,Vs,Vtau,s,tau,i1,time,policy_counter,tipping_counter,breakthrough_counter)

global pref production 

i2=(1-((1-pref.gamma).*V-Vs.*s)./((1-pref.gamma).*V+Vs.*(1-s)).*(1-production.phi(1).*i1))./production.phi(2);
z1=(pref.kappa(1,1).*production.b(2)./pref.kappa(2,1)./(production.b(1,time)*cost_scaling(breakthrough_counter,s)))^(1/(pref.rho(1)-1));
z2=(pref.kappa(1,2).*production.b(2)./pref.kappa(2,2)./(production.b(1,time)*cost_scaling(breakthrough_counter,s)))^(1/(pref.rho(2)-1));
g1=((production.b(1,time)*cost_scaling(breakthrough_counter,s))./(production.eta(1)*production.A(1).*(pref.kappa(1,1)+pref.kappa(2,1).*z1.^pref.rho(1)).^(production.eta(1)/pref.rho(1)-1).*D(tau,policy_counter,tipping_counter).*pref.kappa(1,1))).^(1/(production.eta(1)-1));
g2=((production.b(1,time)*cost_scaling(breakthrough_counter,s))./(production.eta(2)*production.A(2).*(pref.kappa(1,2)+pref.kappa(2,2).*z2.^pref.rho(2)).^(production.eta(2)/pref.rho(2)-1).*D(tau,policy_counter,tipping_counter).*pref.kappa(1,2))).^(1/(production.eta(2)-1));
f1=g1.*z1;
f2=g2.*z2;
c=(1-s).*(production.A(1).*(pref.kappa(1,1).*g1.^pref.rho(1)+pref.kappa(2,1).*f1.^pref.rho(1)).^(production.eta(1)/pref.rho(1)).*D(tau,policy_counter,tipping_counter)-i1-(production.b(1,time)*cost_scaling(breakthrough_counter,s)).*g1-production.b(2).*f1)...
     +s.*(production.A(2).*(pref.kappa(1,2).*g2.^pref.rho(2)+pref.kappa(2,2).*f2.^pref.rho(2)).^(production.eta(2)/pref.rho(2)).*D(tau,policy_counter,tipping_counter)-i2-(production.b(1,time)*cost_scaling(breakthrough_counter,s)).*g2-production.b(2).*f2);

foc_i1=((1-pref.gamma).*V-Vs.*s).*(1-production.phi(1).*i1)-pref.delta*(1-pref.gamma).*V.^(1-1./pref.theta).*c.^(-1./pref.psi);

end