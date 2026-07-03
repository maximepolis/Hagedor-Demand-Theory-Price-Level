function MAC=MAC(S,D,a,K)

global opt_run

if opt_run==1
    MAC=a(1)+a(2)*a(3)*S^a(4)*exp(a(3)*D/K);
else
    MAC=K*a(1)*S^a(2)+K*a(3)*a(4)*S^a(5)*exp(a(3)*S^a(6)*D);
end

end
