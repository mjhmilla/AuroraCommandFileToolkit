function trials = createFiberInjuryExperiments(configExperiment,...
                                            perturbationWave,nameId)

n = 2;

trials(2) = struct('number',0,'type','','takePhoto','','active',0,...
                   'startLength',0,'endLength',0,'endForce',0,...
                   'time',0,'lengthChange',0,'comment','',...
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
    trials(i).time        = [0,configExperiment.isometric.holdTime];
    trials(i).lengthChange= [0,0];
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
% 1
%%
idx = 1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,configExperiment.isometric.holdTime];
trials(idx).lengthChange= [0,0];
trials(idx).block       = 'Pre-injury';
trials(idx).comment     = '';

lengthStr = int2str(floor(trials(idx).startLength*10));
trials(idx).name = [trials(idx).name,'_',trials(idx).type,...
                  '_',lengthStr,'Lo_',nameId,'.pro'];

%%
% 2
%%
idx=idx+1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,configExperiment.isometric.holdTime];
trials(idx).lengthChange= [0,0];
trials(idx).block       = 'Pre-injury';
trials(idx).comment     = '';

lengthStr = int2str(floor(trials(idx).startLength*10));
trials(idx).name = [trials(idx).name,'_',trials(idx).type,...
                  '_',lengthStr,'Lo_',nameId,'.pro'];
