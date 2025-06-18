function success = createFiberInjuryExperiments600A(preconditioningWave,...
                                                      stochasticWave,...
                                                      dateId,...
                                                      projectFolders,...
                                                      auroraConfig)
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');

s2ms = 1000;
experimentConfig.timeToActivate = 20*s2ms;

fidProtocol = fopen(fullfile(projectFolders.output_code,...
                   ['protocol_',dateId,'.csv']),'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo',...
    'Take_Photo','Block','FileName','Comment');


%%
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = 1;

startLength = 1;
type        = 'isometric';
fname       = getTrialNameUpd(idx,type,startLength,dateId);
fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_BlockLabels']);

%Experimental spread sheet update
fprintf(fidProtocol, '%i,%s,%1.1f,%s,%s,%s,%s\n',...
        idx,type,startLength,'Yes','Pre-injury',fname,'');

%Write the trial and block sequence
fidTrial  = fopen(fullfile(projectFolders.output_code,fname),       'w');
fidLabels = fopen(fullfile(projectFolders.output_code,fnameLabels), 'w');

lineCount=0;
[activationStart,lineCount] = writePreamble600A(fidTrial,lineCount,auroraConfig);
[activationBathChange, lineCount] = ...
    writeActivationBlock600A(fidTrial, activationStart, lineCount, auroraConfig);

activationComplete = activationBathChange + experimentConfig.timeToActivate;

[endTime, lineCount] = ...
    writeDeactivationBlock600A(fidTrial, activationComplete, lineCount, auroraConfig);

startTime=endTime+auroraConfig.postCommandPauseTime;

[endTime, lineCount] = ...
    writeClosingBlock600A(fidTrial, startTime, lineCount, auroraConfig);

fprintf(fidLabels,'%s,%1.1f,%1.1f',...
        'Activation',activationStart,activationComplete);
fclose(fidLabels);


success=0;
