function [nextStartTime, lineCount] = ...
    writeActivationBlockWithLengthCycle600A(...
    fid, startTime, startTimeUnit, lineCount,...
    lengthCycle, lengthCycleWaitTime,bathPaddingTime,...
    auroraConfigInput)

auroraConfig=auroraConfigInput;
auroraConfig.useRelativeUnits=0;

assert(strcmp(startTimeUnit,auroraConfig.defaultTimeUnit)==1,...
       'Error: startTimeUnit and auroraConfig.defaultTimeUnit must match');

lengthStepOptions=...
  getCommandFunctionOptions600A('Length-Step',auroraConfig);

%%
%Apply the length ramp cycle
%%
startTime=startTime+bathPaddingTime;
for i=1:1:length(lengthCycle)
  lengthStepOptions(1).value = lengthCycle(i);
  endTime = writeControlFunction600A(fid,startTime,'ms',...
              'Length-Step',lengthStepOptions,auroraConfig);  
  lineCount = lineCount+1;  
  if(i<length(lengthCycle))
    startTime=endTime+lengthCycleWaitTime;
  else
    startTime=endTime+bathPaddingTime;
  end
end

%%
%Move to the pre-activation bath
%%
bathOptions = getCommandFunctionOptions600A('Bath',auroraConfig);


bathOptions(1).value = auroraConfig.bath.preActivation;
bathOptions(2).value = 0;

startTime=startTime+auroraConfig.bath.changeTime;

nextStartTime = writeControlFunction600A(fid,...
            startTime,auroraConfig.defaultTimeUnit,...
            'Bath',bathOptions,auroraConfig);

%Apply the length ramp cycle
startTime=nextStartTime+bathPaddingTime;
for i=1:1:length(lengthCycle)
  lengthStepOptions(1).value = lengthCycle(i);
  endTime = writeControlFunction600A(fid,startTime,'ms',...
              'Length-Step',lengthStepOptions,auroraConfig);  
  lineCount = lineCount+1;  
  if(i<length(lengthCycle))
    startTime=endTime+lengthCycleWaitTime;
  else
    startTime=endTime+bathPaddingTime;
  end
end

%Move to the activation bath
nextStartTime = nextStartTime + auroraConfig.bath.preActivationDuration;
bathOptions(1).value = auroraConfig.bath.active;
bathOptions(2).value = 0;

nextStartTime = writeControlFunction600A(fid,...
                nextStartTime,auroraConfig.defaultTimeUnit,...
                'Bath',bathOptions,auroraConfig);

lineCount =  lineCount+2;
