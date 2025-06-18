function [endTime, lineCount] = ...
    writeClosingBlock600A(fid, startTime, lineCount, auroraConfig)

disableOptions = getCommandFunctionOptions600A('Data-Disable',auroraConfig);

endTime = writeControlFunction600A(fid,...
            startTime,auroraConfig.defaultTimeUnit,...
            'Data-Disable',disableOptions,auroraConfig);


stopOptions = getCommandFunctionOptions600A('Stop',auroraConfig);
startTime = endTime + auroraConfig.postCommandPauseTime;

endTime = writeControlFunction600A(fid,...
            startTime,auroraConfig.defaultTimeUnit,...
            'Stop',stopOptions,auroraConfig);

lineCount=lineCount+2;