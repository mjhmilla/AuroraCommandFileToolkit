function trialName = getTrialName600A(seriesName, trialNumber, trialType,...
                                  startingBathName,startingLength, lengthUnit, ...
                                  nameId, extensionStr)

assert(length(startingBathName)>0,'Error: startingBathName must be set');

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end


if(isempty(startingLength)==0)
    lengthStr = '';
    if(abs(startingLength) < 1 )
      if(startingLength >= 0)
        lengthStr = int2str(round(startingLength,2)*100);      
        lengthStr = ['0',lengthStr];
      else
        lengthStr = int2str(round(abs(startingLength),2)*100);      
        lengthStr = ['m0',lengthStr];
      end
    else
      if(startingLength >= 0)
        lengthStr = sprintf('%i',round(startingLength*100));
      else
        lengthStr = sprintf('m%i',round(abs(startingLength)*100));
      end
    end

    if(isempty(seriesName))
        trialName = [trialNumberStr,'_',trialType,...
                     '_initBath_', startingBathName,'_initLength_',lengthStr,lengthUnit,'_',nameId,extensionStr];
    else
        trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                     '_initBath_', startingBathName,'_initLength_',lengthStr,lengthUnit,'_',nameId,extensionStr];
    end

else
    if(isempty(seriesName))
        trialName = [trialNumberStr,'_',trialType,...
                     '_initBath_', startingBathName,'_',nameId,extensionStr];
    else
        trialName = [seriesName,'_',trialNumberStr,'_',trialType,...
                     '_initBath_', startingBathName,'_',nameId,extensionStr];
    end
end