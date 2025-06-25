function [endTime, lineCount] = ...
    writeClosingBlock610A(fid, startTime, waitTime, lineCount, auroraConfig)

disableOptions = getCommandFunctionOptions610A('Stop','',auroraConfig);


[smallestNextWaitTime, commandDuration]...
     = writeControlFunction610A(fid,...
       waitTime,'Stop',disableOptions,auroraConfig);


endTime = startTime + commandDuration;

lineCount=lineCount+1;