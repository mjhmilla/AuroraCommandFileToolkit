function trialName = getTrialName600A_startEndLength(...
                      seriesName, trialNumber, trialType,...
                      startingBathName,startingLength,...
                      endingLength, lengthUnit, nameId, extensionStr)

assert(~isempty(startingBathName),'Error: startingBathName must be set');
assert(~isempty(startingLength),'Error: startingLength must be set');
assert(~isempty(endingLength),'Error: endingLength must be set');

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end


startEndLength=[startingLength;endingLength];
startEndLengthStr=  {'',''};

for i=1:1:length(startEndLength)
  lengthStr = '';
  if(abs(startEndLength(i)) < 1 )
    if(startEndLength(i) >= 0)
      lengthStr = int2str(round(startEndLength(i),2)*100);      
      lengthStr = ['0',lengthStr];
    else
      lengthStr = int2str(round(abs(startEndLength(i)),2)*100);      
      lengthStr = ['m0',lengthStr];
    end
  else
    if(startEndLength(i) >= 0)
      lengthStr = sprintf('%i',round(startEndLength(i)*100));
    else
      lengthStr = sprintf('m%i',round(abs(startEndLength(i))*100));
    end
  end
  startEndLengthStr(i)={lengthStr};
end

if(isempty(seriesName))
    trialName = [trialNumberStr,'_',trialType,...
                 '_initBath_', startingBathName,...
                 '_initLength_',startEndLengthStr{1},lengthUnit,...
                 '_targetLength_',startEndLengthStr{2},lengthUnit,'_',...
                 nameId,extensionStr];
else
    trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                 '_initBath_', startingBathName,...
                 '_initLength_',startEndLengthStr{1},lengthUnit,...
                 '_targetLength_',startEndLengthStr{2},lengthUnit,'_',...
                 nameId,extensionStr];
end

