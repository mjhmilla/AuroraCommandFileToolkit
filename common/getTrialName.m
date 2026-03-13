function trialName = getTrialName(seriesName, trialNumber, trialType,...
                                  startingLength, lengthUnit, nameId, extensionStr)

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end

if(isempty(startingLength)==0)
    lengthStr = '';
    if(startingLength < 1)
        lengthStr = int2str(round(startingLength,2)*100);      
        lengthStr = ['0',lengthStr];
    else
        lengthStr = sprintf('%1.2f',startingLength);
        idxDp = strfind(lengthStr,'.');
        lengthStr(idxDp)='_';
    end

    if(isempty(seriesName))
        trialName = [trialNumberStr,'_',trialType,...
                          '_',lengthStr,lengthUnit,'_',nameId,extensionStr];
    else
        trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                          '_',lengthStr,lengthUnit,'_',nameId,extensionStr];
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