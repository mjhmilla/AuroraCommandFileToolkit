function [endTime, lineCount] = ...
    writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig)

bathOptions = getCommandFunctionOptions600A('Bath',auroraConfig);

%Move to the pre-activation bath
bathOptions(1).value = auroraConfig.bath.passive;
bathOptions(2).value = 0;

startTime=startTime+auroraConfig.bath.changeTime;

endTime = writeControlFunction600A(fid,...
            startTime,auroraConfig.defaultTimeUnit,...
            'Bath',bathOptions,auroraConfig);

lineCount =  lineCount+1;
