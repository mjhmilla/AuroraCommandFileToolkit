function idxStr = getTrialIndexString(idx)

idxStr = num2str(idx);
if(length(idxStr)<2)
    idxStr = ['0',idxStr];
end