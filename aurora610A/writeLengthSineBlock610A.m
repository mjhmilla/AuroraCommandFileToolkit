function [endTime, smallestNextWaitTime, lineCount] ...
    = writeLengthSineBlock610A( ...
        fid,startTime,...
        waitTimeVector,frequencyVector,lengthVector, durationVector,...
        lengthSineOptions,lineCount,auroraConfig)


endTime=startTime;

for i=1:1:length(waitTimeVector)


    lengthSineOptions(1).value = frequencyVector(i,1);
    lengthSineOptions(2).value = lengthVector(i,1);
    lengthSineOptions(3).value = durationVector(i,1);

    waitTime = waitTimeVector(i,1);

    if(i > 1 && smallestNextWaitTime > waitTime)
        waitTime = smallestNextWaitTime;
    end

    
    [smallestNextWaitTime, commandDuration] ...
        = writeControlFunction610A(fid,waitTime,...
                'Sine Wave',lengthSineOptions,auroraConfig);
    
    if(lengthSineOptions(1).isParallelCommand == 0)
        endTime = endTime + commandDuration;
    end

    lineCount = lineCount+1;
    
end


