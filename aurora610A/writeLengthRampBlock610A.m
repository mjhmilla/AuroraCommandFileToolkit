function [endTime, smallestNextWaitTime, lineCount] ...
    = writeLengthRampBlock610A( ...
        fid,startTime,...
        waitTimeVector,lengthVector,durationVector,...
        lengthRampOptions, lineCount,auroraConfig)


endTime = startTime;

for i=1:1:length(waitTimeVector)

    lengthRampOptions(1).value = lengthVector(i,1);
    lengthRampOptions(2).value = durationVector(i,1);
    waitTime = waitTimeVector(i,1);
    
    if(i > 1 && smallestNextWaitTime > waitTime)
        waitTime = smallestNextWaitTime;
    end

    [smallestNextWaitTime, commandDuration] ...
        = writeControlFunction610A(fid,waitTime,...
                'Ramp',lengthRampOptions,auroraConfig);

    if(lengthRampOptions(1).isParallelCommand == 0)
        endTime = endTime + commandDuration;
    end

    lineCount = lineCount+1;    
end

