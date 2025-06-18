function trialName = getTrialNameUpd(trialNumber, trialType,...
                                  startingLength, nameId)

trialNumberStr = num2str(trialNumber);
if(length(trialNumberStr)<2)
    trialNumberStr = ['0',trialNumberStr];
end

lengthStr = int2str(floor(startingLength*10));
trialName = [trialNumberStr,'_',trialType,...
                  '_',lengthStr,'Lo_',nameId,'.pro'];