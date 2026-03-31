function [endTime, lineCount] = writeForceRampBlock600A(fid,startTime,...
                           waitTimeVector,forceVector,durationVector,...
                           forceRampOptions, lineCount,auroraConfig)



for i=1:1:length(waitTimeVector)

    if(i>1)
        startTime = endTime + waitTimeVector(i,1);        
        assert(waitTimeVector(i,1) >= auroraConfig.minimumWaitTime,...
               'Error: wait time is not long enough');        
    end

    %First we start with a force clamp
    if( i == 1)
        forceClampOptions=getCommandFunctionOptions600A('Force-Clamp',auroraConfig);
        
        forceClampOptions(1).value = forceVector(1,1);
        forceClampOptions(2).value = durationVector(1,1);
        forceClampOptions(3).value = durationVector(1,1);

        endTime = writeControlFunction600A(fid,startTime,'ms',...
                    'Force-Clamp',forceClampOptions,auroraConfig);
        lineCount = lineCount+1;
    else
        %Then we proceed with the force ramps
        forceRampOptions(1).value = forceVector(i,1);
        forceRampOptions(2).value = durationVector(i,1);
    
        
        endTime = writeControlFunction600A(fid,startTime,'ms',...
                    'Force-Ramp',forceRampOptions,auroraConfig);
    
        lineCount = lineCount+1;
    end
    
end

