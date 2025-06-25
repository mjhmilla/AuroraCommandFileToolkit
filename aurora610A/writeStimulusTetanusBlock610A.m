function [stimulationEndTime, smallestNextWaitTime, lineCount] = ...
    writeStimulusTetanusBlock610A(fid, startTime, waitTime,...
                                  durationInS, lineCount, auroraConfig)

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
    'Error: auroraConfig.defaultTimeUnit must be s');

stimOptions = getCommandFunctionOptions610A(...
                'Stimulus-Tetanus','Stimulator',auroraConfig);

stimOptions(1).value = 0;
stimOptions(2).value = auroraConfig.stimulation.frequencyHz;
stimOptions(3).value = auroraConfig.stimulation.pulseWidthMs;
stimOptions(4).value = durationInS;


[smallestNextWaitTime, commandDuration] ...
    = writeControlFunction610A(fid,waitTime,...
                'Stimulus-Tetanus',stimOptions,auroraConfig);

stimulationEndTime = startTime + commandDuration;

lineCount =  lineCount+2;
