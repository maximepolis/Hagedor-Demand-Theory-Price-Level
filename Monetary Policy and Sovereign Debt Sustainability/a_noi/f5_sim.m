% MONETARY POLICY AND SOVEREIGN DEBT SUSTAINABILITY
% GALO NUNO 2018, based on codes from GALO NUNO AND BENJAMIN MOLL

function sim = f5_sim(parameters,results,sim)

dt = sim.dt;
dz = results.dz;
da = results.da;

sim.z     = zeros(sim.total,1);
sim.zposD = zeros(sim.total,1);
sim.zposU = zeros(sim.total,1);
sim.wz    = zeros(sim.total,1);

sim.sdte_shocks = parameters.sig*(dt^0.5)*sim.e_shocks;

for t=1:sim.total

    if t>1
        sim.z(t) = (1-parameters.mu*dt)*sim.z(t-1) + sim.sdte_shocks(t);
    else
        sim.z(t) = sim.z0 + sim.sdte_shocks(t);
    end

    sim.z(t)     =   max([sim.z(t) parameters.zmin+0.000001]);
    sim.z(t)     =   min([sim.z(t) parameters.zmax-0.000001]);
    sim.zposD(t) = floor((sim.z(t)-parameters.zmin)/dz)+1;
    sim.zposU(t) =  ceil((sim.z(t)-parameters.zmin)/dz)+1;
    sim.wz(t)=(results.z(sim.zposU(t))-sim.z(t))/dz; % weight of posD in the interpolation

end

sim.a     = zeros(sim.total,1);
sim.aposD = zeros(sim.total,1);
sim.aposU = zeros(sim.total,1);
sim.wa    = zeros(sim.total,1);

sim.Q = zeros(sim.total,1);
sim.d = zeros(sim.total,1);
sim.c = zeros(sim.total,1);
sim.V = zeros(sim.total,1);
sim.r = zeros(sim.total,1);
sim.r_real = zeros(sim.total,1);
sim.pi= zeros(sim.total,1);
sim.s = zeros(sim.total,1);
sim.s_def = zeros(sim.total,1);

sim.d_state = zeros(sim.total,1);

% for simulation: each time period, several things need to happen, and can't happen all at once, so we set a within-period order of events
% we arrive at t with a state d_in, and use that state to derive a(t), which we then use to derive everything else, and then we calculate d_out

d_out=sim.d0; % this is the d_state we will have when arriving at t=1

for t = 1:sim.total

    d_in           = d_out; % the d_state at the beginning of t is the one we calculated at the end of t-1
    sim.d_state(t) = d_in;  % in d_state(t) we store the value of d_state at the beginning of period t (not at the end of period t) (the continuous variable d will be different: it refers to end-of-period)

    % stage 1:  apply dynamics according to d_in, in two parts
    % stage 1A: update a (later, using that, in stage 1B we will update everything else)

    if t==1 % in the first period we use the value of a0 (no updating here)
        sim.a(t) = sim.a0;
    else
        if d_in==0   % if the current d_state is repayment, then apply repayment dynamics
            sim.a(t)     = sim.a(t-1) + sim.s(t-1)*dt;
        else         % if the current d_state is default, then apply default dynamics
            sim.a(t)     = sim.a(t-1) + sim.s_def(t-1)*dt;
        end
    end

    sim.a(t)     =   max([sim.a(t) parameters.amin+0.000001]);
    sim.a(t)     =   min([sim.a(t) parameters.amax-0.000001]);
    sim.aposD(t) = floor((sim.a(t)-parameters.amin)/da)+1;
    sim.aposU(t) =  ceil((sim.a(t)-parameters.amin)/da)+1;
    wa           = (results.a(sim.aposU(t))-sim.a(t))/da; % weight of posD in the interpolation
    wz           = sim.wz(t);

    % stage 1B: apply dynamics for everything else apart from a, using d_in, at the point (a,z) defined by the updated a

    if d_in==0 % if we enter t in repayment, then apply repayment dynamics (for s we prepare both s and s_def, the correct one will be used to update a in the next step)

        sim.s(t)     = wa*wz*results.s(sim.aposD(t),sim.zposD(t))     + (1-wa)*wz* results.s(sim.aposU(t),sim.zposD(t))     + wa*(1-wz)*results.s(sim.aposD(t),sim.zposU(t))     + (1-wa)*(1-wz)*results.s(sim.aposU(t),sim.zposU(t));
        sim.s_def(t) = wa*wz*results.s_def(sim.aposD(t),sim.zposD(t)) + (1-wa)*wz* results.s_def(sim.aposU(t),sim.zposD(t)) + wa*(1-wz)*results.s_def(sim.aposD(t),sim.zposU(t)) + (1-wa)*(1-wz)*results.s_def(sim.aposU(t),sim.zposU(t));
        sim.c(t)     = wa*wz*results.c(sim.aposD(t),sim.zposD(t))     + (1-wa)*wz* results.c(sim.aposU(t),sim.zposD(t))     + wa*(1-wz)*results.c(sim.aposD(t),sim.zposU(t))     + (1-wa)*(1-wz)*results.c(sim.aposU(t),sim.zposU(t));
        sim.pi(t)    = wa*wz*results.pi(sim.aposD(t),sim.zposD(t))    + (1-wa)*wz* results.pi(sim.aposU(t),sim.zposD(t))    + wa*(1-wz)*results.pi(sim.aposD(t),sim.zposU(t))    + (1-wa)*(1-wz)*results.pi(sim.aposU(t),sim.zposU(t));
        sim.r(t)     = wa*wz*results.r(sim.aposD(t),sim.zposD(t))     + (1-wa)*wz* results.r(sim.aposU(t),sim.zposD(t))     + wa*(1-wz)*results.r(sim.aposD(t),sim.zposU(t))     + (1-wa)*(1-wz)*results.r(sim.aposU(t),sim.zposU(t));
        sim.Q(t)     = wa*wz*results.Q(sim.aposD(t),sim.zposD(t))     + (1-wa)*wz* results.Q(sim.aposU(t),sim.zposD(t))     + wa*(1-wz)*results.Q(sim.aposD(t),sim.zposU(t))     + (1-wa)*(1-wz)*results.Q(sim.aposU(t),sim.zposU(t));
        sim.r_real(t)= wa*wz*results.r_real(sim.aposD(t),sim.zposD(t))+ (1-wa)*wz* results.r_real(sim.aposU(t),sim.zposD(t))+ wa*(1-wz)*results.r_real(sim.aposD(t),sim.zposU(t))+ (1-wa)*(1-wz)*results.r_real(sim.aposU(t),sim.zposU(t));
        sim.V(t)     = wa*wz*results.V(sim.aposD(t),sim.zposD(t))     + (1-wa)*wz* results.V(sim.aposU(t),sim.zposD(t))     + wa*(1-wz)*results.V(sim.aposD(t),sim.zposU(t))     + (1-wa)*(1-wz)*results.V(sim.aposU(t),sim.zposU(t));

    else       % if we enter t in default, then apply default dynamics (for s we prepare both s and s_def, the correct one will be used to update a in the next step)

        sim.s(t)     = wa*wz*results.s(sim.aposD(t),sim.zposD(t))      + (1-wa)*wz* results.s(sim.aposU(t),sim.zposD(t))      + wa*(1-wz)*results.s(sim.aposD(t),sim.zposU(t))      + (1-wa)*(1-wz)*results.s(sim.aposU(t),sim.zposU(t));
        sim.s_def(t) = wa*wz*results.s_def(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.s_def(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.s_def(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.s_def(sim.aposU(t),sim.zposU(t));
        sim.c(t)     = wa*wz*results.c_def(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.c_def(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.c_def(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.c_def(sim.aposU(t),sim.zposU(t));
        sim.pi(t)    = wa*wz*results.pi_def(sim.aposD(t),sim.zposD(t)) + (1-wa)*wz* results.pi_def(sim.aposU(t),sim.zposD(t)) + wa*(1-wz)*results.pi_def(sim.aposD(t),sim.zposU(t)) + (1-wa)*(1-wz)*results.pi_def(sim.aposU(t),sim.zposU(t));
        sim.r(t)     = wa*wz*results.r_def(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.r_def(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.r_def(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.r_def(sim.aposU(t),sim.zposU(t));
        sim.Q(t)     = wa*wz*results.Q_def(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.Q_def(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.Q_def(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.Q_def(sim.aposU(t),sim.zposU(t));
        sim.V(t)     = wa*wz*results.V_def(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.V_def(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.V_def(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.V_def(sim.aposU(t),sim.zposU(t));

    end

    % stage 2: calculate d_out

    % unlike d_state, which stores the value of d_state at the beginning of period t, d (the interpolated value that is continuous instead of binary) refers to the end of period t
    sim.d(t)  = wa*wz*results.d(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.d(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.d(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.d(sim.aposU(t),sim.zposU(t));

    if d_in==0 % if we were in repayment, then just look at current position to decide if we enter default now or not
        d_out = round(sim.d(t));
    else       % if we were in default...
        if rand < parameters.chi*dt % first, toss a coin to see if we come out of default - if so...
            sim.a(t) = parameters.theta * sim.a(t); % kill part of the debt (theta) at the moment we go out of default (but this happens right at the end of period t: don't re-run the dynamics at t)
                                                    % and then we need to make sure we are out of the default region before changing d_state to zero: if we are still in the region of default, we start a new default episode right away
            sim.a(t)       =   max([sim.a(t) parameters.amin+0.000001]);
            sim.a(t)       =   min([sim.a(t) parameters.amax-0.000001]);
            sim.aposD(t)   = floor((sim.a(t)-parameters.amin)/da)+1;
            sim.aposU(t)   =  ceil((sim.a(t)-parameters.amin)/da)+1;
            wa             = (results.a(sim.aposU(t))-sim.a(t))/da; % weight of posD in the interpolation
            sim.d(t)       = wa*wz*results.d(sim.aposD(t),sim.zposD(t))  + (1-wa)*wz* results.d(sim.aposU(t),sim.zposD(t))  + wa*(1-wz)*results.d(sim.aposD(t),sim.zposU(t))  + (1-wa)*(1-wz)*results.d(sim.aposU(t),sim.zposU(t));
            d_out          = round(sim.d(t));
        else
            d_out          = 1;
        end
    end

end

sim.aY   = sim.a ./ exp(sim.z);

sim.rdif = sim.r      - parameters.r_bar;
sim.rdef = sim.r_real - parameters.r_bar;
sim.rinf = sim.r      - sim.r_real;

