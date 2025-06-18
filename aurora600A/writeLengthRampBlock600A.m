function [endTime, lineCount] =writeLengthRampBlock600A(fid,startTime,...
                           waitTimeVector,lengthVector,durationVector,...
                           lengthRampOptions, lineCount,auroraConfig)

assert(abs(timeVector(1,1))==0,'Error: timeVector must start from zero');

endTime=startTime;
for i=1:1:length(waitTimeVector)

    startTime = endTime + ...
             max([waitTimeVector(i,1),auroraConfig.postCommandPauseTime]);

    lengthRampOptions(1).value = lengthVector(i,1);
    lengthRampOptions(2).value = durationVector(i,1);

    
    endTime = writeControlFunction600A(fid,startTime,'ms',...
                'Length-Ramp',lengthRampOptions,auroraConfig);

    lineCount = lineCount+1;
    
end

