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
    
    programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
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

    lengthRampOptions(1).value = nominalLength; 
    lengthRampOptions(2).value = expConfig.waitTime;
    
    startTime = programMetaData.nextStartTime+expConfig.waitTime;
    endTime = startTime+expConfig.waitTime;

    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
    segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=lengthRampOptions(2).value;
    

    programMetaData ...
        = writeControlFunction610A(...
                fid,...
                expConfig.waitTime,...
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
    waitTime = 1;

    tetanusDuration  =expConfig.timeToReachMaxActivation;

    stimulusTetanusOptions = getCommandFunctionOptions610A(...
                              'Stimulus-Tetanus','Stimulator',auroraConfig);
    
    stimulusTetanusOptions(1).value=expConfig.tetanus.initialDelay;
    stimulusTetanusOptions(2).value=expConfig.tetanus.pulseFrequency;
    stimulusTetanusOptions(3).value=expConfig.tetanus.pulseWidth;
    stimulusTetanusOptions(4).value=tetanusDuration;

    startTime = programMetaData.nextStartTime+expConfig.waitTime;
    endTime   = startTime ...
                +expConfig.tetanus.initialDelay ...
                +tetanusDuration;
    
    idxSeg=idxSeg+1;
    segmentMetaDataArray(idxSeg).type = 'Stimulus-Tetanus';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
    segmentMetaDataArray(idxSeg).meta_data.channel= ...
      stimulusTetanusOptions(1).port;
    
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.initialDelay)  = ...
      expConfig.tetanus.initialDelay;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseFrequency)= ...
      expConfig.tetanus.pulseFrequency;  
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseWidth)    = ...
      expConfig.tetanus.pulseWidth;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.duration)      = ...
      tetanusDuration;



    %
    % Command
    %
       
    programMetaData = writeControlFunction610A(...
                        fid,...
                        expConfig.waitTime,...
                        'Stimulus-Tetanus',...
                        stimulusTetanusOptions,...
                        auroraConfig,...                
                        programMetaData,...
                        flag_printMetaDataToFile); 
    
    endTimeError = endTime - programMetaData.controlFunction.endTime;
    assert(abs(endTimeError)<1e-3,...
        'Error: end time differs from the meta data'); 

    waitTime = expConfig.timeToReachMaxActivation;


    %
    % Ramp to nominal length
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    lengthRampOptions(1).value = nominalLength; 
    lengthRampOptions(2).value = expConfig.waitTime;
    
    waitTime = expConfig.waitTime+tetanusDuration;
    startTime = programMetaData.nextStartTime+waitTime;
    endTime = startTime+expConfig.waitTime;

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
    programMetaData = ...
        writeClosingBlock610A(...
            fid,...
            expConfig.stopWaitTime,...
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