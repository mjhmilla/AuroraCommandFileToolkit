function [stimulationEndTime, smallestNextWaitTime, lineCount] = ...
    writeTwitchProbeBlock610A(fid, startTime, waitTime, lineCount, auroraConfig)

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
    'Error: auroraConfig.defaultTimeUnit must be s');

stimOptions = getCommandFunctionOptions610A(...
                'Stimulus-Tetanus','Stimulator',auroraConfig);

stimOptions(1).value = 0;
stimOptions(2).value = auroraConfig.twitch.frequencyHz;
stimOptions(3).value = auroraConfig.twitch.pulseWidthMs;
stimOptions(4).value = auroraConfig.twitch.duration;


[smallestNextWaitTime, commandDuration] ...
    = writeControlFunction610A(fid,waitTime,...
                'Stimulus-Tetanus',stimOptions,auroraConfig);

stimulationEndTime = startTime + commandDuration;
smallestNextWaitTime = auroraConfig.twitch.restTimeAfterTwitch;

lineCount =  lineCount+2;
