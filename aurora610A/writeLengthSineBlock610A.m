function [endTime, lineCount] = writeLengthSineBlock610A(fid,startTime,...
                           waitTimeVector,frequencyVector,lengthVector,...
                           durationVector, lengthSineOptions, ...
                           lineCount,auroraConfig)



for i=1:1:length(waitTimeVector)


    if(i>1)
        startTime = endTime + waitTimeVector(i,1);  
        assert(waitTimeVector(i,1) >= auroraConfig.postCommandPauseTime,...
               'Error: wait time is not long enough');
    end
    
    lengthSineOptions(1).value = frequencyVector(i,1);
    lengthSineOptions(2).value = lengthVector(i,1);
    lengthSineOptions(3).value = durationVector(i,1);

    
    endTime = writeControlFunction600A(fid,startTime,'s',...
                'Sine Wave',lengthSineOptions,auroraConfig);
    
    lineCount = lineCount+1;
    
end


