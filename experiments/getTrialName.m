function trialName = getTrialName(seriesName, trialNumber, trialType,...
                                  startingLength, nameId, extensionStr)

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end

lengthStr = int2str(floor(startingLength*10));
if(startingLength < 1)
    lengthStr = ['0',lengthStr];
end

trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                  '_',lengthStr,'Lo_',nameId,extensionStr];