MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
SAMUEL HURTADO GALO NUNO AND CARLOS THOMAS 2022



The subfolders are:

a_inf      the model with    inflation
a_noi      the model without inflation
c_graphs   the nice graphs



a_inf and a_noi are almost identical, the only difference is in the options selected in the a2_launch file, and the guess.mat used as starting point
the rest of the files are common to both of them
it's two folders because after running each, there will be a lot of files, graphs, etc, generated, and it's good to have them both separated


files:
a2_launch           is where we set options and launch the code
b0_parameters       is where we set the parameters of the model and of the algorithm
b4_plot             plots diagnostics
b5_sim              does simulations to find the SSS, calculate IRFs, and plot a phase diagram
b6_episode          simulates the Brazil episode
f0_solve            function that calls the functions that solve the model
f1_HJB_NoInflation  function that computes the HJB to find V,Q without inflation (it's the one called in the a_noi subfolder)
f2_HJB_Inflation    function that computes the HJB to find V,Q with    inflation (it's the one called in the a_inf subfolder)
f3_KFE              function that computes the KFE to find the distribution g
f5_sim              function that simulates the model




the graphs inside a_inf and a_noi were made for diagnostics during the development
the nice graphs are created afterwards, in the c_graphs subfolder

files:
c1_moments          calculates the moments reported in the paper (after running they are reported in the log file)
c2_graphs           plots most of the graphs
c3_Vdecomposition   computes the V decomposition, calling the function inside c3_Vdecomposition_f
c5_phase            plots the phase diagram with    inflation
c5_phase_noi        plots the phase diagram without inflation

