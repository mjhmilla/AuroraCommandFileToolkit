function trialName = getTrialName(seriesName, trialNumber, trialType,...
                                  startingLength, nameId, extensionStr)

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end

if(isempty(startingLength)==0)
    lengthStr = int2str(round(startingLength,2)*100);
    if(startingLength < 1)
        lengthStr = ['0',lengthStr];
    end

    if(isempty(seriesName))
        trialName = [trialNumberStr,'_',trialType,...
                          '_',lengthStr,'Lo_',nameId,extensionStr];
    else
        trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                          '_',lengthStr,'Lo_',nameId,extensionStr];
    end

else
    if(isempty(seriesName))
        trialName = [trialNumberStr,'_',trialType,...
                     '_',nameId,extensionStr];
    else
        trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                     '_',nameId,extensionStr];
    end
end