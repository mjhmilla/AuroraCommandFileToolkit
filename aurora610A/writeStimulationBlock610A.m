function [nextStartTime, lineCount] = ...
    writeActivationBlock610A(fid, startTime, endTime,  lineCount, auroraConfig)



stimOptions = getCommandFunctionOptions600A('Bath',auroraConfig);

%Move to the pre-activation bath
bathOptions(1).value = auroraConfig.bath.preActivation;
bathOptions(2).value = 0;


nextStartTime = writeControlFunction600A(fid,...
                nextStartTime,auroraConfig.defaultTimeUnit,...
                'Bath',bathOptions,auroraConfig);

lineCount =  lineCount+2;
