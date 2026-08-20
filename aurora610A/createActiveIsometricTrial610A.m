function success = createActiveIsometricTrial610A(...
                    nominalLength,...
                    trialFileNameNoExt,...                                     
                    auroraConfig,...
                    expConfig,...
                    expFolders,...
                    flag_isASequence)


    flag_printMetaDataToFile=1;

    fid = fopen(fullfile(expFolders.rootFolderPath,...
                         expFolders.protocolFolderName,...
                         [trialFileNameNoExt,'.dpf']),'w');
   
    
    trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                      expFolders.blockLabelsFolderName,...
                                      [trialFileNameNoExt,'.csv']);
    
    programMetaData = getEmptyProgramMetaDataStruct610A(trialBlockLabelFilePath);
    programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);
    
    mdfn = getMetaDataFieldNames610A(auroraConfig);

    if(flag_isASequence==0)
      jsonMetaData = struct('data',[],'protocol',[],...
                            'segments',[],'experiment',[]);
        
      jsonMetaData.data.file = {expFolders.dataFolderName, ...
                                [trialFileNameNoExt,'.ddf']};
      jsonMetaData.data.sha256 = "";
      
      jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
                                [trialFileNameNoExt,'.dpf']};
      jsonMetaData.protocol.sha256 = "";
    else
      jsonMetaData = struct('segments',[],'experiment',[]); 
    end    

    numberOfSegments= 3; 
    
    segmentMetaDataArray(numberOfSegments) = ...
        struct('type','',mdfn.time,[0,0],'meta_data',[]);

    idxSeg=1;  
    %
    % Ramp to nominalLength
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    positioningDuration = abs(nominalLength)...
                          /expConfig.positioning.rampSpeedInMMPS;
    positioningDuration = max(positioningDuration,...
                              expConfig.positioning.minimumRampTime);

    lengthRampOptions(1).value = nominalLength; 
    lengthRampOptions(2).value = positioningDuration;
    
    startTime = programMetaData.nextStartTime+expConfig.timing.waitTime;
    endTime = startTime+positioningDuration;

    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
    segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=lengthRampOptions(2).value;
    
    programMetaData ...
        = writeControlFunction610A(...
                fid,...
                expConfig.timing.waitTime,...
                'Ramp',...
                lengthRampOptions,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile);
  
    endTimeError = endTime - programMetaData.controlFunction.endTime;
    assert(abs(endTimeError)<1e-3,...
        'Error: end time differs from the meta data');        

    %
    % Meta data
    %
    waitTime = expConfig.timing.waitTime;
    if(abs(nominalLength)>1e-6)
      waitTime=expConfig.positioning.recoveryWaitTime;
    end

    stimulusTetanusOptions = getCommandFunctionOptions610A(...
                              'Stimulus-Tetanus','Stimulator',auroraConfig);
    
    stimulusTetanusOptions(1).value=expConfig.tetanus.initialDelay;
    stimulusTetanusOptions(2).value=expConfig.tetanus.pulseFrequency;
    stimulusTetanusOptions(3).value=expConfig.tetanus.pulseWidth;
    stimulusTetanusOptions(4).value=expConfig.tetanus.timeToReachMaxActivation;

    startTime = programMetaData.nextStartTime+waitTime;
    endTime   = startTime ...
                +expConfig.tetanus.initialDelay ...
                +stimulusTetanusOptions(4).value;
    
    idxSeg=idxSeg+1;
    segmentMetaDataArray(idxSeg).type = 'Stimulus-Tetanus';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
    segmentMetaDataArray(idxSeg).meta_data.channel= ...
      stimulusTetanusOptions(1).port;
    
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.initialDelay)  = ...
      stimulusTetanusOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseFrequency)= ...
      stimulusTetanusOptions(2).value;  
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseWidth)    = ...
      stimulusTetanusOptions(3).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.duration)      = ...
      stimulusTetanusOptions(4).value;


    tetanusDuration = stimulusTetanusOptions(4).value;
    %
    % Command
    %
       
    programMetaData = writeControlFunction610A(...
                        fid,...
                        waitTime,...
                        'Stimulus-Tetanus',...
                        stimulusTetanusOptions,...
                        auroraConfig,...                
                        programMetaData,...
                        flag_printMetaDataToFile); 
    
    endTimeError = endTime - programMetaData.controlFunction.endTime;
    assert(abs(endTimeError)<1e-3,...
        'Error: end time differs from the meta data'); 


    %
    % Ramp to nominal length
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    positioningDuration = abs(nominalLength)...
                          /expConfig.positioning.rampSpeedInMMPS;
    positioningDuration = max(positioningDuration,...
                              expConfig.positioning.minimumRampTime);

    lengthRampOptions(1).value = 0; 
    lengthRampOptions(2).value = positioningDuration;
    
    waitTime  = expConfig.tetanus.recoveryTime+tetanusDuration;
    startTime = programMetaData.nextStartTime+waitTime;
    endTime   = startTime+positioningDuration;

    idxSeg=idxSeg+1;
    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
    segmentMetaDataArray(idxSeg).meta_data.channel= ...
      lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=...
      lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=...
      lengthRampOptions(2).value;

    programMetaData ...
        = writeControlFunction610A(...
                fid,...
                waitTime,...
                'Ramp',...
                lengthRampOptions,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile);
  
    endTimeError = endTime - programMetaData.controlFunction.endTime;
    assert(abs(endTimeError)<1e-3,...
        'Error: end time differs from the meta data');

       

    %
    % Close the trial
    %
    stopWaitTime=expConfig.timing.stopWaitTime;
    if(abs(nominalLength)>1e-6)
      stopWaitTime=max(stopWaitTime,expConfig.positioning.recoveryWaitTime);
    end

    programMetaData = ...
        writeClosingBlock610A(...
            fid,...
            stopWaitTime,...
            auroraConfig,...
            programMetaData,...
            flag_printMetaDataToFile);
    
    success = 1;
    assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
        'Error: maximumNumberOfCommandsExceeded');      

    %
    % Write the json files
    %
    jsonMetaData.segments = segmentMetaDataArray;


    jsonMetaData.experiment.title = ...
      sprintf('Isometric Tetanus: %1.1f mm',...
              nominalLength);
      jsonMetaData.experiment.tags = {'isometric-tetanus'};

    
    jsonMetaDataEncoded = jsonencode(jsonMetaData);
    fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                              expFolders.sequenceMetaData,...
                             [trialFileNameNoExt,'.json']),'w');
    fprintf(fidJson,jsonMetaDataEncoded);
    fclose(fidJson);
    
    fclose(fid);
    fclose(programMetaData.labelFileHandle);