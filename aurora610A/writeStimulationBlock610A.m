function [stimulationEndTime, smallestNextWaitTime, lineCount] = ...
    writeStimulationBlock610A(fid, startTime, durationInS,  lineCount, auroraConfig)

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
    'Error: auroraConfig.defaultTimeUnit must be s');

stimOptions = getCommandFunctionOptions610A(...
                'Stimulus-Tetanus','Stimulator',auroraConfig);

%Move to the pre-activation bath
stimOptions(1).value = 0;
stimOptions(2).value = auroraConfig.stimulation.frequencyHz;
stimOptions(3).value = auroraConfig.stimulation.pulseWidthMs;
stimOptions(4).value = durationInS;

waitTime = stimOptions(1).value;

[smallestNextWaitTime, commandDuration] ...
    = writeControlFunction610A(fid,waitTime,...
                'Stimulus-Tetanus',stimOptions,auroraConfig);

stimulationEndTime = startTime + commandDuration;

lineCount =  lineCount+2;
