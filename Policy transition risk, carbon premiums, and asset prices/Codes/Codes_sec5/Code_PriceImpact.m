% Current State
year=2094;
t=year-2020;

load([save_data_at, 'Solution_policy\Z1_solution_', num2str(t)]);
div1_s1=chi1_s1.^leverage.phi;
div2_s1=chi1_s1.^leverage.phi;

S=graph.S(5,t);
T=graph.T(4,t);
K=graph.brown_capital(4,t)+graph.green_capital(4,t);

X=graph.X(4,t);
Y=graph.Y(4,t);
B=graph.B(4,t);

% New Markovian State
x=graph.X(4,t+1);
y=graph.Y(4,t+1);
b=graph.B(4,t+1);




if x~=X
    disp('Climate Tipping')
end
if y~=Y
    disp('Policy Tipping')
end
if b~=B
    disp('Tech Tipping')
end



% Determine entry
%% optimal controls for start
temp_index_state    = find(S-state.vector <0 ,1);
temp_index_temperature     = find(T-temperature.vector <0 ,1);
%DeltaCHI1=chi1_s1(temp_index_state,temp_index_temperature,1,3,1)./chi1_s1(temp_index_state,temp_index_temperature,1,1,1)-1

DeltaPDR1=pdr1_s1(temp_index_state,temp_index_temperature,y,x,b)./pdr1_s1(temp_index_state,temp_index_temperature,Y,X,B)-1;
DeltaPDR2=pdr2_s1(temp_index_state,temp_index_temperature,y,x,b)./pdr2_s1(temp_index_state,temp_index_temperature,Y,X,B)-1;
DeltaP1=pdr1_s1(temp_index_state,temp_index_temperature,y,x,b).*div1_s1(temp_index_state,temp_index_temperature,y,x,b)./(pdr1_s1(temp_index_state,temp_index_temperature,Y,X,B).*div1_s1(temp_index_state,temp_index_temperature,Y,X,B))-1;
DeltaP2=pdr2_s1(temp_index_state,temp_index_temperature,y,x,b).*div2_s1(temp_index_state,temp_index_temperature,y,x,b)./(pdr2_s1(temp_index_state,temp_index_temperature,Y,X,B).*div2_s1(temp_index_state,temp_index_temperature,Y,X,B))-1;
DeltaTax=K*10^12*(tax_s1(temp_index_state,temp_index_temperature,y,x,b)-tax_s1(temp_index_state,temp_index_temperature,Y,X,B));


[T S]
[DeltaP1 DeltaP2 DeltaPDR1 DeltaPDR2 DeltaTax/3.6666]


DeltaTax