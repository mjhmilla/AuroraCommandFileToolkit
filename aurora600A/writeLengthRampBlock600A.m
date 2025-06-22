function [endTime, lineCount] =writeLengthRampBlock600A(fid,startTime,...
                           waitTimeVector,lengthVector,durationVector,...
                           lengthRampOptions, lineCount,auroraConfig)



for i=1:1:length(waitTimeVector)

    if(i>1)
        startTime = endTime + waitTimeVector(i,1);        
        assert(waitTimeVector(i,1) >= auroraConfig.postCommandPauseTime,...
               'Error: wait time is not long enough');
        
    end
    lengthRampOptions(1).value = lengthVector(i,1);
    lengthRampOptions(2).value = durationVector(i,1);

    
    endTime = writeControlFunction600A(fid,startTime,'ms',...
                'Length-Ramp',lengthRampOptions,auroraConfig);

    lineCount = lineCount+1;

    
end

