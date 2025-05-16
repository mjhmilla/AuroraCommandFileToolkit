function protocol = createFiberInjuryExperiments(experimentConfig)


timeIsometricHold = experimentConfig.timeIsometricHold;

trials(1) = struct('number',0,'type','','active',0,'takePhoto','',...
                    'startLength',0,'endLength',0,'endForce',0,...
                    'comment','','time',[],'lengthChange',[]);

for i=1:1:length(trials)
    trials(i).number=i;
    trials(i).type = '';
    trials(i).active=0;
    trials(i).startLength=1.0;
    trials(i).endLength = 1.0;
    trials(i).endForce = 0;
    trials(i).comment = '';
    trials(i).time = [];
    trials(i).lengthChange = [];
 end



 
idx = 1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,timeIsometricHold];
trials(idx).lengthChange= [0,0];
trials(idx).comment     = 'Pre-injury';
