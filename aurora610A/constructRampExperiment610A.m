function trialId = constructRampExperiment610A(...
                        dateId,...
                        trialId,...
                        sequenceId,...
                        sequenceName,...
                        auroraConfig,...
                        expConfig,...
                        expFolders,...
                        projectFolders)

auroraConfigRecovery = getDefaultAuroraConfiguration610A(...
                        expConfig.muscleName,...
                        expConfig.unitSystem,...
                        expConfig.sineWave.sampleFrequency,...    
                        expConfig.lceOptMM,...
                        expConfig.vceMaxLPS); 



%%
% Create the sequence
%%
jsonSequenceMetaData = struct('sequence',[],'experiment',[]);
jsonSequenceSeriesMetaData = struct('sequence_file',[],...
  'meta_data',[],'protocols',[],'data',[]);

sequenceMetaDataFiles = struct('folder',[],'files',[]);
sequenceProtocolFiles = struct('folder',[],'files',[]);
sequenceDataFiles = struct('folder',[],'files',[],'sha256',[]);

%%
% Set up the folders
%%
sequenceIdStr ='';

assert(~isempty(sequenceId),'Error: sequenceId cannot be empty');

sequenceIdStr = num2str(sequenceId);
if(length(sequenceIdStr)<2)
  sequenceIdStr = ['0',sequenceIdStr];
end

rampFolderName         = [sequenceIdStr,'_',sequenceName];

assert(contains(expFolders.sequenceMetaData,'/')==0);
assert(contains(expFolders.sequenceMetaData,'\')==0);
assert(contains(expFolders.protocolFolderName,'/')==0);
assert(contains(expFolders.protocolFolderName,'\')==0);
assert(contains(expFolders.dataFolderName,'/')==0);
assert(contains(expFolders.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFolders.sequenceMetaData},{rampFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFolders.protocolFolderName},{rampFolderName}];
sequenceDataFiles.folder      = ...
  [{expFolders.dataFolderName},{rampFolderName}];

rampDataDir         = fullfile(expFolders.dataFolderName,rampFolderName); 
rampProtocolDir     = fullfile(expFolders.protocolFolderName,rampFolderName); 
rampLabelDir        = fullfile(expFolders.blockLabelsFolderName,rampFolderName); 
rampMetaDataDir     = fullfile(expFolders.sequenceMetaData,rampFolderName); 

expFolders.dataFolderName         = rampDataDir;
expFolders.protocolFolderName     = rampProtocolDir;
expFolders.blockLabelsFolderName  = rampLabelDir;
expFolders.sequenceMetaData       = rampMetaDataDir;

if(~exist(fullfile(expFolders.rootFolderPath,rampDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampDataDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,rampProtocolDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampProtocolDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,rampLabelDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampLabelDir));
end
if(~exist(fullfile(expFolders.rootFolderPath,rampMetaDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampMetaDataDir));
end


%%
% Create the files
%%

mdFieldNames = getMetaDataFieldNames610A(auroraConfig);
timeFieldName = mdFieldNames.time;
cyclesFieldName =mdFieldNames.cycles;
frequencyFieldName = mdFieldNames.frequency;
amplitudeFieldName = mdFieldNames.amplitude; 
lengthFieldName    = mdFieldNames.length;

initialDelayFieldName = mdFieldNames.initialDelay;
pulseWidthFieldName   = mdFieldNames.pulseWidth;


flag_printMetaDataToFile = 1;
sequenceTrialCount = 0;

for idxTrial = 1:1:length(expConfig.ramp.length)

  for idxFile=1:1:2
  
    sequenceTrialCount = sequenceTrialCount+1;
    
    switch idxFile
      case 1
  
        seriesName = sequenceIdStr;
        if(expConfig.ramp.isActive(idxTrial)==1)
          type = 'activeRamp';
        else
          type = 'passiveRamp';          
        end
        
        lengthChange = expConfig.ramp.length(idxTrial);        
        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,lengthChange,...
                       auroraConfig.defaultLengthUnit, dateId,'');
      case 2
      
        seriesName = sequenceIdStr;
        type = 'sineWave';
        
        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,0,...
                       auroraConfig.defaultLengthUnit, dateId,'');      
      otherwise
        assert(0,'Error: this loop is only configured for 2 files')
    end
  
    sequenceMetaDataFiles.files  = ...
      [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
    sequenceProtocolFiles.files  = ...
      [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
    sequenceDataFiles.files      = ...
      [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
    sequenceDataFiles.sha256 = ...
      [sequenceDataFiles.sha256,{''}];


    

    
    %
    % Meta data 
    %
    
    mdfn = getMetaDataFieldNames610A(auroraConfig);

    
    switch idxFile
      case 1
  
        fid = fopen(fullfile(expFolders.rootFolderPath,...
                             expFolders.protocolFolderName,...
                             [trialFileNameNoExt,'.dpf']),'w');
       
        
        trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                          expFolders.blockLabelsFolderName,...
                                          [trialFileNameNoExt,'.csv']);
        
        programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
        programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);
        
        jsonMetaData = struct('segments',[],'experiment',[]);

        numberOfSegments= expConfig.ramp.isActive(idxTrial)+2; 
        
        segmentMetaDataArray(numberOfSegments) = ...
            struct('type','',mdfn.time,[0,0],'meta_data',[]);

        idxSeg=1;        
        %
        % Meta data
        %
        waitTime = 1;
        rampDuration = expConfig.ramp.duration(idxTrial);

        if(expConfig.ramp.isActive(idxTrial)==1)

          tetanusDuration  =rampDuration*2 ...
                           +expConfig.timeToReachMaxActivation ...
                           +expConfig.tetanus.durationExtension;

          stimulusTetanusOptions = getCommandFunctionOptions610A(...
                                    'Stimulus-Tetanus','Stimulator',auroraConfig);
          
          stimulusTetanusOptions(1).value=expConfig.tetanus.initialDelay;
          stimulusTetanusOptions(2).value=expConfig.tetanus.pulseFrequency;
          stimulusTetanusOptions(3).value=expConfig.tetanus.pulseWidth;
          stimulusTetanusOptions(4).value=tetanusDuration;
    
          startTime = expConfig.waitTime;
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
        end


        %
        % Ramp to some length
        %
        lengthRampOptions = ...
          getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

        lengthRampOptions(1).value = expConfig.ramp.length(idxTrial); 
        lengthRampOptions(2).value = expConfig.ramp.duration(idxTrial);
        
        startTime = programMetaData.nextStartTime ...
                  + waitTime;
        endTime = startTime+expConfig.ramp.duration(idxTrial);

        segmentMetaDataArray(idxSeg).type = 'Ramp';
        segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];
        segmentMetaDataArray(idxSeg).meta_data.is_active = expConfig.ramp.isActive(idxTrial);
        segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
        segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)=lengthRampOptions(1).value;
        segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)=lengthRampOptions(2).value;
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

        lengthRampOptions(1).value = 0; 
        lengthRampOptions(2).value = expConfig.ramp.duration(idxTrial);
        
        startTime = programMetaData.nextStartTime;
        endTime = startTime+expConfig.ramp.duration(idxTrial);

        segmentMetaDataArray(idxSeg).type = 'Ramp';
        segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];
        segmentMetaDataArray(idxSeg).meta_data.is_active = expConfig.ramp.isActive(idxTrial);
        segmentMetaDataArray(idxSeg).meta_data.channel=lengthRampOptions(1).port;
        segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)=lengthRampOptions(1).value;
        segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)=lengthRampOptions(2).value;
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
  
        if(expConfig.ramp.isActive(idxTrial)==1)
          jsonMetaData.experiment.title = ...
            sprintf('Active Ramp: 0mm-%1.1f-0mm',...
                    expConfig.ramp.length(idxTrial));
            jsonMetaData.experiment.tags = {'injury'};
        else
          jsonMetaData.experiment.title = ...
            sprintf('Passive Ramp: 0mm-%1.1f-0mm',...
                    expConfig.ramp.length(idxTrial));
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

      case 2
  
        %
        % Recovery sine wave
        %
 
    
        flag_isASequence=1;
        success = createRecoveryTrial610A(...
                            trialFileNameNoExt,...                                     
                            auroraConfigRecovery,...
                            expConfig,...
                            expFolders,...
                            flag_isASequence);   
 

      otherwise
        assert(0,'Error: this file is only configured for 2 files');
    end
  
  

  
    trialId=trialId+1;
  end
end

jsonSequenceSeriesMetaData.sequence_file = [];
jsonSequenceSeriesMetaData.meta_data = sequenceMetaDataFiles;
jsonSequenceSeriesMetaData.protocols = sequenceProtocolFiles;
jsonSequenceSeriesMetaData.data      = sequenceDataFiles;

jsonSequenceMetaData.experiment.comment = "";
jsonSequenceMetaData.experiment.manually_measured_temperature_C ...
  = expConfig.temperature;
jsonSequenceMetaData.sequence = jsonSequenceSeriesMetaData;


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],sequenceName,[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);

