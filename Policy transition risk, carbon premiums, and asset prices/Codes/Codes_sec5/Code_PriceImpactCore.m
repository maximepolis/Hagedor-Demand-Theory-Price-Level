% Current State
year=2042;
t=year-2020;

load([save_data_at, 'Solution_policy\Z1_solution_', num2str(t)]);
div1_s1=chi1_s1.^leverage.phi;
div2_s1=chi1_s1.^leverage.phi;

S=graph.S(5,t);
T=graph.T(4,t);

X=1;
Y=graph.Y(4,t);
B=1;

% New Markovian State
x=1;
y=3;graph.Y(4,t+1);
b=1;




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



[T S]
[DeltaP1 DeltaP2 DeltaPDR1 DeltaPDR2]*100


