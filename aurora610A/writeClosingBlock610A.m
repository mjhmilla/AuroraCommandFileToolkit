function [endTime, lineCount] = ...
    writeClosingBlock610A(fid, startTime, lineCount, auroraConfig)

disableOptions = getCommandFunctionOptions600A('Stop',auroraConfig);

waitTime = 1;

[smallestNextWaitTime, commandDuration]...
     = writeControlFunction610A(fid,...
       waitTime,'Stop',disableOptions,auroraConfig);


endTime = startTime + commandDuration;

lineCount=lineCount+1;