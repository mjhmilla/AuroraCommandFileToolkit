function success = createStretchShortenTrial610A(...
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

    numberOfSegments= expConfig.ramp.isActive+3; 
    
    segmentMetaDataArray(numberOfSegments) = ...
        struct('type','',mdfn.time,[0,0],'meta_data',[]);

    idxSeg=1;  
    %
    % Ramp to nominalLength
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    lengthRampOptions(1).value = nominalLength; 
    lengthRampOptions(2).value = expConfig.ramp.duration;
    
    startTime = programMetaData.nextStartTime;
    endTime = startTime+expConfig.ramp.duration;

    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
    segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=lengthRampOptions(2).value;
    idxSeg=idxSeg+1;

    programMetaData ...
        = writeControlFunction610A(...
                fid,...
                0,...
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
    rampDuration = expConfig.ramp.duration;

    if(expConfig.ramp.isActive==1)

      tetanusDuration  =rampDuration*2 ...
                       +expConfig.tetanus.timeToReachMaxActivation ...
                       +expConfig.tetanus.durationExtension;

      stimulusTetanusOptions = getCommandFunctionOptions610A(...
                                'Stimulus-Tetanus','Stimulator',auroraConfig);
      
      stimulusTetanusOptions(1).value=expConfig.tetanus.initialDelay;
      stimulusTetanusOptions(2).value=expConfig.tetanus.pulseFrequency;
      stimulusTetanusOptions(3).value=expConfig.tetanus.pulseWidth;
      stimulusTetanusOptions(4).value=tetanusDuration;

      startTime = programMetaData.nextStartTime+expConfig.timing.waitTime;
      endTime   = startTime ...
                  +expConfig.tetanus.initialDelay ...
                  +tetanusDuration;
      

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

      idxSeg=idxSeg+1;

      %
      % Command
      %
         
      programMetaData = writeControlFunction610A(...
                          fid,...
                          expConfig.timing.waitTime,...
                          'Stimulus-Tetanus',...
                          stimulusTetanusOptions,...
                          auroraConfig,...                
                          programMetaData,...
                          flag_printMetaDataToFile); 
      
      endTimeError = endTime - programMetaData.controlFunction.endTime;
      assert(abs(endTimeError)<1e-3,...
          'Error: end time differs from the meta data'); 

      waitTime = expConfig.tetanus.timeToReachMaxActivation;
    end


    %
    % Ramp to some length
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    lengthRampOptions(1).value = expConfig.ramp.length; 
    lengthRampOptions(2).value = expConfig.ramp.duration;
    
    startTime = programMetaData.nextStartTime ...
              + waitTime;
    endTime = startTime+expConfig.ramp.duration;

    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = expConfig.ramp.isActive;
    segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=lengthRampOptions(2).value;
    idxSeg=idxSeg+1;

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
    % Ramp to 0
    %
    lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    lengthRampOptions(1).value = nominalLength; 
    lengthRampOptions(2).value = expConfig.ramp.duration;
    
    startTime = programMetaData.nextStartTime + expConfig.ramp.holdDuration;
    endTime = startTime+expConfig.ramp.duration;

    segmentMetaDataArray(idxSeg).type = 'Ramp';
    segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = expConfig.ramp.isActive;
    segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.length)=lengthRampOptions(1).value;
    segmentMetaDataArray(idxSeg).meta_data.(mdfn.time)=lengthRampOptions(2).value;
    idxSeg=idxSeg+1;

    programMetaData ...
        = writeControlFunction610A(...
                fid,...
                expConfig.ramp.holdDuration,...
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
            expConfig.timing.stopWaitTime,...
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

    if(expConfig.ramp.isActive==1)
      jsonMetaData.experiment.title = ...
        sprintf('Active Ramp: 0mm-%1.1f-0mm',...
                expConfig.ramp.length);
        jsonMetaData.experiment.tags = {'injury'};
    else
      jsonMetaData.experiment.title = ...
        sprintf('Passive Ramp: 0mm-%1.1f-0mm',...
                expConfig.ramp.length);
        jsonMetaData.experiment.tags = {'injury'};
    end      

    
    jsonMetaDataEncoded = jsonencode(jsonMetaData);
    fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                              expFolders.sequenceMetaData,...
                             [trialFileNameNoExt,'.json']),'w');
    fprintf(fidJson,jsonMetaDataEncoded);
    fclose(fidJson);
    
    fclose(fid);
    fclose(programMetaData.labelFileHandle);