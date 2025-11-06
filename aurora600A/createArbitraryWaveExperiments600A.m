function success = createArbitraryWaveExperiments600A(...
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

idLarb = 1;

%%
% Generate the trials
%%
nominalLength = 1;
nWaves = length(stochasticWaveSet);
trialCount =0;
for idxActivation = 1:1:2
    isActive=0;
    if(idxActivation==1)
        isActive=1;
    end
    for idxWave = 1:1:nWaves

        trialCount = trialCount+1;
        idx     = trialCount;
        idxStr  = getTrialIndexString(idx);

        seriesName  = 'Passive';
        if(isActive==1) 
            seriesName  = 'Active';
        end

        startLength = settingsRubber.normLength;
        typeName    = [settingsRubber.rubberType,'_',settingsRubber.startingForceFileLabel];
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
        % 1. Activate if necessary
        %%
        if(isActive==1)
            [endTime, lineCount] = ...
                writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
            
            endActivation = endTime + auroraConfig.bath.activationDuration;
            
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
            
            startTime = endActivation;
            lineCount = lineCount+1;

        end
        %%
        % 2. Write the wave 
        %%
    
        waveDir = fullfile(codeDir, 'wave');
        if(exist(waveDir)==0)
            mkdir(waveDir);
        end   

        waveMetaDataDir = fullfile(codeDir, 'waveMetaData');
        if(exist(waveMetaDataDir)==0)
            mkdir(waveMetaDataDir);
        end        
        [endTime, lineCount] =  writeLarbBlock600A(...
                                  fid,...                                      
                                  startTime,...
                                  nominalLength,...
                                  stochasticWaveSet(idxWave).fileData,...
                                  stochasticWaveSet(idxWave).options,...   
                                  stochasticWaveSet(idxWave).metadata,...
                                  stochasticWaveSet(idxWave).fileName,...
                                  waveDir,...
                                  waveMetaDataDir,...                                                      
                                  lineCount,...
                                  auroraConfig);
        fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
            stochasticWaveSet(idxWave).type,startTime,endTime);            
        startTime = endTime + auroraConfig.minimumWaitTime;    

        %%
        % 3. Deactivate if necessary
        %%
        if(isActive==1)

            [endTime, lineCount] = ...
                writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);
            
            startTime=endTime+auroraConfig.minimumWaitTime;            
        end
        
        %%
        % End the trial
        %%
        [endTime, lineCount] = ...
            writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);
        
        success = 1;
        assert(lineCount < auroraConfig.maximumNumberOfCommands,...
            'Error: maximumNumberOfCommandsExceeded');
        
        
        fclose(fid);
        fclose(fidLabel);        
    end
end
fclose(fidProtocol);










