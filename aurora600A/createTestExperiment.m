function [endTime,lineCount] = createTestExperiment(auroraConfig, projectFolders)


s2ms = 1000;
timeToActivate = 20*s2ms;

fid = fopen(fullfile(projectFolders.output_code,'test.pro'),'w');

lineCount=0;
[startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);

npts = 1000;
simSignal = struct('time',zeros(npts,1),...
                   'lengthAbs',zeros(npts,1),'lengthUnit',auroraConfig.defaultLengthUnit,...
                   'forceAbs',zeros(npts,1),'forceUnit'  ,auroraConfig.defaultForceUnit,...
                   'commandId',zeros(npts,1),...
                   'index',1);

[endTime, lineCount] = ...
    writeActivationBlock600A(fid, startTime, lineCount, auroraConfig);
startTime = endTime;

lengthRamp = getCommandFunctionOptions600A('Length-Ramp',auroraConfig);
lengthRamp(1).value=1.55;
lengthRamp(2).value = 15;

startTime=startTime+timeToActivate;

endTime = ...
    writeControlFunction600A(fid,startTime,'ms',...
        'Length-Ramp',lengthRamp,auroraConfig);
lineCount = lineCount+1;

lengthRamp(1).value = -1.55;
lengthRamp(2).value = 15;

startTime=endTime;

startTime = ...
        writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',lengthRamp,auroraConfig);
lineCount = lineCount+1;

[endTime, lineCount] = ...
    writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);

startTime=endTime+auroraConfig.postCommandPauseTime;

[endTime, lineCount] = ...
    writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);

here=1;