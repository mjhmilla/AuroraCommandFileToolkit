function success = createRubberTestingExperiments600A(...
                        settingsRubber,...
                        stochasticWaveSet,...
                        projectFolders,...                                                                                                            
                        auroraConfig)

[codeDir, codeLabelDir,dateId] = ...
    getTrialDirectories(projectFolders,['_',settingsRubber.rubberType]);

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

idxStart = 0;
writeProtocolHeader=1;

if(writeProtocolHeader==1)
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
end

%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');

%%
%Experiment configuration
%%
lengthRampOptions=getCommandFunctionOptions600A('Length-Ramp',auroraConfig);

scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

assert(strcmp(auroraConfig.defaultLengthUnit,'Lo'),...
      'Error: Assumed length unit is Lo');


%%
% File setup
%%
idx     = 1;
idxStr  = getTrialIndexString(idx);

seriesName  = '';
startLength = settingsRubber.normLength;
typeName        = [settingsRubber.rubberType,'_',settingsRubber.startingForceFileLabel];
takePhoto   = '';
blockName   = '';
fname       = getTrialName(seriesName,idx,typeName,startLength,dateId,'.pro');
fnameLabels = getTrialName(seriesName,idx,typeName,startLength,[dateId,'_labels'],'.csv');


fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
    idxStr,typeName,startLength,takePhoto, blockName,fname,...
    'Manually set length to start at 0.20mN. Set this length to be Lo');


fid = fopen(fullfile(codeDir, fname),'w');
fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');

%%
% 0. Write the preamble
%%

lineCount=0;
[startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);

%%
% 1. Move to Lo less the passive sine amplitude
%%


auroraConfigLengthRamp = auroraConfig;
auroraConfigLengthRamp.useRelativeUnits=0;

absLengthRampOptions = ...
    getCommandFunctionOptions600A('Length-Ramp',auroraConfigLengthRamp);

absLengthRampOptions(1).value=settingsRubber.normLength...
                             -settingsRubber.passiveCycleMagnitude;
absLengthRampOptions(2).value=1*scaleTime;


endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',absLengthRampOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Length-Ramp',startTime,endTime); 

startTime=endTime;

%%
% 1. Passive cycles
%%

%
%Choose a frequency that has a period that is a multiple of 0.1 ms
%
period = (1/settingsRubber.passiveCycleFrequencyHz)*scaleTime;
frequencyTmp = round( ((period.*(1/scaleTime)).^(-1)), 4);
frequencyErr = abs(settingsRubber.passiveCycleFrequencyHz-frequencyTmp);
periodA      = (frequencyTmp.^(-1)).*scaleTime;
periodB      = round((periodA),1);
cycleErr    = abs(periodA-periodB)./periodB;

assert(max(cycleErr) < 1e-4,...
    ['Error: the cycle error in the sinusoid perturbation ',...
     'function may accumulate at a rate greater than 1% per 100 cycles']);

assert(auroraConfig.useRelativeUnits==1,...
        'Error: this function assumes that useRelativeUnits is 1');

lengthSineOptions = ...
    getCommandFunctionOptions600A('Length-Sine',auroraConfig);

lengthSineOptions(1).value = frequencyTmp;
lengthSineOptions(2).value = settingsRubber.passiveCycleMagnitude;
lengthSineOptions(3).value = ...
    round((scaleTime/frequencyTmp)*settingsRubber.passiveCycles,1);


endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Sine',lengthSineOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Passive-Length-Sine',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;



%%
%2. Move to Lo
%%

absLengthRampOptions(1).value=settingsRubber.normLength;
absLengthRampOptions(2).value=1*scaleTime;

endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',absLengthRampOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Length-Ramp',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;

%%
% 3. Perturbation
%%

%Perturb
for i=1:1:length(stochasticWaveSet)
    switch stochasticWaveSet(i).controlFunction
        case 'Length-Ramp'
            [endTime, lineCount] = ...
                writeLengthRampBlock600A(fid, startTime,...
                            stochasticWaveSet(i).waitDuration,...
                            stochasticWaveSet(i).optionValues(:,1),...
                            stochasticWaveSet(i).optionValues(:,2),...
                            stochasticWaveSet(i).options,...
                            lineCount,...
                            auroraConfig);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
                stochasticWaveSet(i).type,startTime,endTime);
            startTime = endTime + auroraConfig.minimumWaitTime;

        case 'Length-Sine'
            [endTime,lineCount] = ...
                writeLengthSineBlock600A(fid, startTime,...
                    stochasticWaveSet(i).waitDuration,...
                    stochasticWaveSet(i).optionValues(:,1),...
                    stochasticWaveSet(i).optionValues(:,2),...
                    stochasticWaveSet(i).optionValues(:,3),...
                    stochasticWaveSet(i).options,...
                    lineCount,...
                    auroraConfig);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
                stochasticWaveSet(i).type,startTime,endTime);            
            startTime = endTime + auroraConfig.minimumWaitTime;
        case 'Length-Arb'
            disp('Here');
            assert(0,'Error: still need to write this');
        otherwise
            assert(0,'Error: Unrecognized controlFunction in the stochasticWaveSet');
    end
end



%%
% 4. Bath changes as usual, as if it is being activated
%%

[endTime, lineCount] = ...
    writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);

endActivation = endTime + auroraConfig.bath.activationDuration;

fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);

startTime = endActivation;
lineCount = lineCount+1;
%%
%5. Move to Lo less the passive sine magnitude
%%

absLengthRampOptions(1).value=settingsRubber.normLength...
                             -settingsRubber.passiveCycleMagnitude;
absLengthRampOptions(2).value=1*scaleTime;

endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',absLengthRampOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Length-Ramp',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;
%%
% 6. Passive cycles
%%

endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Sine',lengthSineOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Passive-Length-Sine',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;
%%
%7. Move to Lo
%%

absLengthRampOptions(1).value=settingsRubber.normLength;
absLengthRampOptions(2).value=1*scaleTime;

endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',absLengthRampOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Length-Ramp',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;
%%
% 8. Perturbations
%%


%Perturb
for i=1:1:length(stochasticWaveSet)
    switch stochasticWaveSet(i).controlFunction
        case 'Length-Ramp'
            [endTime, lineCount] = ...
                writeLengthRampBlock600A(fid, startTime,...
                            stochasticWaveSet(i).waitDuration,...
                            stochasticWaveSet(i).optionValues(:,1),...
                            stochasticWaveSet(i).optionValues(:,2),...
                            stochasticWaveSet(i).options,...
                            lineCount,...
                            auroraConfig);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
                stochasticWaveSet(i).type,startTime,endTime);
            startTime = endTime + auroraConfig.minimumWaitTime;

        case 'Length-Sine'
            [endTime,lineCount] = ...
                writeLengthSineBlock600A(fid, startTime,...
                    stochasticWaveSet(i).waitDuration,...
                    stochasticWaveSet(i).optionValues(:,1),...
                    stochasticWaveSet(i).optionValues(:,2),...
                    stochasticWaveSet(i).optionValues(:,3),...
                    stochasticWaveSet(i).options,...
                    lineCount,...
                    auroraConfig);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
                stochasticWaveSet(i).type,startTime,endTime);            
            startTime = endTime + auroraConfig.minimumWaitTime;
        case 'Length-Arb'
            disp('Here');
                assert(0,'Error: still need to write this');

        otherwise
            assert(0,'Error: Unrecognized controlFunction in the stochasticWaveSet');
    end
end

%%
%9. Move to Lo
%%

absLengthRampOptions(1).value=settingsRubber.normLength;
absLengthRampOptions(2).value=1*scaleTime;

endTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',absLengthRampOptions,auroraConfig);

fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
    'Length-Ramp',startTime,endTime); 

startTime=endTime;
lineCount = lineCount+1;
%%
%10. De-activate
%%

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


