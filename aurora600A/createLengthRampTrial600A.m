function success = createLengthRampTrial600A(...
                    isRampActive,...
                    lengthRamp,...               
                    trialFileFullPath,...
                    trialBlockLabelFullPath,...
                    auroraConfig)



fid = fopen(trialFileFullPath,'w');
fidLabel = fopen(trialBlockLabelFullPath,'w');

lineCount=0;
[startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);


if(isRampActive==1)

    %Activate
    [endTime, lineCount] = ...
        writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
    
    endActivation = endTime + auroraConfig.bath.activationDuration;
    
    fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
    fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
    
    startTime = endActivation;

end

[endTime, lineCount] = ...
        writeLengthRampBlock600A(fid, startTime,...
                    lengthRamp.wait,...
                    lengthRamp.lengthChange,...
                    lengthRamp.duration,...
                    lengthRamp.options,...
                    lineCount,...
                    auroraConfig);
endTime = endTime + lengthRamp.waitPostRamp(end);

    fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
        lengthRamp.type,startTime,endTime);
startTime = endTime + auroraConfig.minimumWaitTime;


[endTime, lineCount] = ...
    writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);

startTime=endTime+auroraConfig.minimumWaitTime;

[endTime, lineCount] = ...
    writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);

success = 1;
assert(lineCount < auroraConfig.maximumNumberOfCommands,...
    'Error: maximumNumberOfCommandsExceeded');


fclose(fid);
fclose(fidLabel);
