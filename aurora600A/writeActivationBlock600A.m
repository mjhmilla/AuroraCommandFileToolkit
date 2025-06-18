function [nextStartTime, lineCount] = ...
    writeActivationBlock600A(fid, startTime, lineCount, auroraConfig)

bathOptions = getCommandFunctionOptions600A('Bath',auroraConfig);

%Move to the pre-activation bath
bathOptions(1).value = auroraConfig.bath.preActivation;
bathOptions(2).value = 0;

startTime=startTime+auroraConfig.bath.changeTime;

nextStartTime = writeControlFunction600A(fid,...
            startTime,auroraConfig.defaultTimeUnit,...
            'Bath',bathOptions,auroraConfig);


%Move to the activation bath
nextStartTime = nextStartTime + auroraConfig.bath.preActivationDuration;
bathOptions(1).value = auroraConfig.bath.active;
bathOptions(2).value = 0;

nextStartTime = writeControlFunction600A(fid,...
                nextStartTime,auroraConfig.defaultTimeUnit,...
                'Bath',bathOptions,auroraConfig);

lineCount =  lineCount+2;
