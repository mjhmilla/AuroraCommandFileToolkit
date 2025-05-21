function trials = createFiberInjuryExperiments(configExperiment,...
                                            preconditioningWave,...
                                            stochasticWave,...
                                            nameId)

nI0 = 1;
nP  = size(configExperiment.passive.holdTime,1);
nFL = size(configExperiment.isometric.holdTime,1);
nFV = size(configExperiment.ramp.holdTime,1);
nI1 = 1;

n = nI0+nP+nFL+nFV+nI1;

trials(3) = struct('number',0,'type','','takePhoto','','active',0,...
                   'startLength',0,'endLength',0,'endForce',0,...
                   'time',0,'length',0,'comment','',...
                   'block','',...
                   'timeAurora',[],'lengthAurora',[],...
                   'name','');

for i=1:1:n
    trials(i).number      = i;
    trials(i).type        = 'isometric';
    trials(i).takePhoto   = 'Yes';
    trials(i).active      = 1;
    trials(i).startLength = 1.0;
    trials(i).endLength   = 1.0;
    trials(i).endForce    = 0;
    trials(i).time        = [0,0];
    trials(i).length= [0,0];
    trials(i).block       = '';

    trials(i).timeAurora = [];
    trials(i).lengthAurora=[];

    numStr = int2str(trials(i).number);
    if(length(numStr)<2)
        numStr = ['0',numStr];
    end
    trials(i).name = [numStr];

end

%%
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = 1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,configExperiment.isometric.holdTime(1)];
trials(idx).length      = [0,0];
trials(idx).block       = 'Pre-injury';
trials(idx).comment     = '';

trials(idx).name = getTrialName(trials(idx).name, trials(idx).type,...
                                trials(idx).startLength,nameId);


%%
% 2. Block of passive trials
%%

for i=1:1:nP

    rampTime = ( configExperiment.passive.lengths(i,2) ...
                -configExperiment.passive.lengths(i,1)) ...
                / ( configExperiment.passive.velocity(i,1) );

    t0=0;
    t1=configExperiment.passive.holdTime(i,1);
    t2=t1+rampTime;
    t3=t2+configExperiment.passive.holdTime(i,2);

    l0=0;
    l1=0;
    l2= l1 ...
        + ( configExperiment.passive.lengths(i,2) ...
          - configExperiment.passive.lengths(i,1));
    l3 = l2;

    waveTime = [];
    waveLength = [];
    if(configExperiment.passive.appendVibration(i,1)==1)
        dt=1;
        waveTime = [(preconditioningWave.time'+t3+dt),...
                   (stochasticWave.time'+max(preconditioningWave.time)+t3+2*dt)];
        waveLength=[(preconditioningWave.length'+l3),...
                    (stochasticWave.length+l3)'];
    end

    idx=idx+1;
    trials(idx).number      = idx;
    trials(idx).type        = 'passive';
    trials(idx).takePhoto   = '';
    trials(idx).active      = 0;
    trials(idx).startLength = configExperiment.passive.lengths(i,1);
    trials(idx).endLength   = configExperiment.passive.lengths(i,2);
    trials(idx).endForce    = 0;
    trials(idx).time        = [t0,t1,t2,t3,waveTime];
    trials(idx).length= [l0,l1,l2,l3,waveLength];
    trials(idx).block       = 'Pre-injury';
    trials(idx).comment     = '';
    
    trials(idx).name = getTrialName(trials(idx).name, trials(idx).type,...
                                    trials(idx).startLength,nameId);
end

%%
% 3. Block of isometric trials
%%


for i=1:1:nFL

    t0=0;
    t1=configExperiment.isometric.holdTime(i,1);

    l0=0;
    l1=0;

    waveTime = [];
    waveLength = [];
    if(configExperiment.isometric.appendVibration(i,1)==1)
        dt=1;
        waveTime = [(preconditioningWave.time'+t3+dt),...
                   (stochasticWave.time'+max(preconditioningWave.time)+t3+2*dt)];
        waveLength=[(preconditioningWave.length'),...
                    (stochasticWave.length)'];
    end

    idx=idx+1;
    trials(idx).number      = idx;
    trials(idx).type        = 'isometric';
    trials(idx).takePhoto   = '';
    trials(idx).active      = 1;
    trials(idx).startLength = configExperiment.isometric.lengths(i,1);
    trials(idx).endLength   = configExperiment.isometric.lengths(i,1);
    trials(idx).endForce    = 0;
    trials(idx).time        = [t0,t1,waveTime];
    trials(idx).length      = [l0,l1,waveLength];
    trials(idx).block       = 'Pre-injury';
    trials(idx).comment     = '';
    
    trials(idx).name = getTrialName(trials(idx).name, trials(idx).type,...
                                    trials(idx).startLength,nameId);
end

%%
% 4. Block of ramp trials
%%

for i=1:1:nFV

    rampTime = ( configExperiment.ramp.lengths(i,2) ...
                    -configExperiment.ramp.lengths(i,1)) ...
                    / ( configExperiment.ramp.velocity(i,1) );

    t0=0;
    t1=configExperiment.ramp.holdTime(i,1);
    t2=t1+rampTime;
    t3=t2+configExperiment.ramp.holdTime(i,2);

    l0=0;
    l1=0;
    l2= l1 ...
        + ( configExperiment.ramp.lengths(i,2) ...
          - configExperiment.ramp.lengths(i,1));
    l3 = l2;

    waveTime = [];
    waveLength = [];
    if(configExperiment.ramp.appendVibration(i,1)==1)
        dt=1;
        waveTime = [(preconditioningWave.time'+t3+dt),...
                   (stochasticWave.time'+max(preconditioningWave.time)+t3+2*dt)];
        waveLength=[(preconditioningWave.length'+l3),...
                    (stochasticWave.length+l3)'];
    end

    idx=idx+1;
    trials(idx).number      = idx;
    trials(idx).type        = 'ramp';
    trials(idx).takePhoto   = '';
    trials(idx).active      = 1;
    trials(idx).startLength = configExperiment.ramp.lengths(i,1);
    trials(idx).endLength   = configExperiment.ramp.lengths(i,2);
    trials(idx).endForce    = 0;
    trials(idx).time        = [t0,t1,t2,t3,waveTime];
    trials(idx).length= [l0,l1,l2,l3,waveLength];
    trials(idx).block       = 'Pre-injury';
    trials(idx).comment     = '';
    
    trials(idx).name = getTrialName(trials(idx).name, trials(idx).type,...
                                    trials(idx).startLength,nameId);

end

%%
% 5. Isometric trial to see if the fiber is viable before injury
%%
idx = idx+1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,configExperiment.isometric.holdTime(1)];
trials(idx).length      = [0,0];
trials(idx).block       = 'Pre-injury';
trials(idx).comment     = '';

trials(idx).name = getTrialName(trials(idx).name, trials(idx).type,...
                                trials(idx).startLength,nameId);



%%
% 6. Injury ramp
%   a. Force-ramp to ff
%   b. Isometric
%
% Increase ff until Isometric < 0.8 previous isometric

%%