function [endTime, lineCount] = writeForceRampBlock600A(fid,startTime,...
                           waitTimeVector,forceVector,durationVector,...
                           forceRampOptions, lineCount,auroraConfig)



for i=1:1:length(waitTimeVector)

    if(i>1)
        startTime = endTime + waitTimeVector(i,1);        
        assert(waitTimeVector(i,1) >= auroraConfig.minimumWaitTime,...
               'Error: wait time is not long enough');
        
    end
    forceRampOptions(1).value = forceVector(i,1);
    forceRampOptions(2).value = durationVector(i,1);

    
    endTime = writeControlFunction600A(fid,startTime,'ms',...
                'Force-Ramp',forceRampOptions,auroraConfig);

    lineCount = lineCount+1;

    
end

