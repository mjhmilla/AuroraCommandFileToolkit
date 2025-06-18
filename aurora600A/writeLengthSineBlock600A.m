function [endTime, lineCount] = writeLengthSineBlock600A(fid,startTime,...
                           waitTimeVector,frequencyVector,lengthVector,...
                           durationVector, lengthSineOptions, ...
                           lineCount,auroraConfig)

assert(abs(timeVector(1,1))==0,'Error: timeVector must start from zero');

endTime=startTime;
for i=1:1:length(waitTimeVector)

    startTime = endTime + ...
             max([waitTimeVector(i,1),auroraConfig.postCommandPauseTime]);

    lengthSineOptions(1).value = frequencyVector(i,1);
    lengthSineOptions(2).value = lengthVector(i,1);
    lengthSineOptions(3).value = durationVector(i,1);

    
    endTime = writeControlFunction600A(fid,startTime,'ms',...
                'Length-Sine',lengthSineOptions,auroraConfig);
    
    lineCount = lineCount+1;
    
end


