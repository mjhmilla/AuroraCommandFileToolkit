function [trialId, expFoldersUpd] = constructForceLengthRelationshipExperiment610A(...
                                        dateId,...
                                        trialId,...
                                        sequenceId,...
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

flrFolderName         = [sequenceIdStr,'_flr'];

expFoldersUpd = expFolders;

assert(contains(expFoldersUpd.sequenceMetaData,'/')==0);
assert(contains(expFoldersUpd.sequenceMetaData,'\')==0);
assert(contains(expFoldersUpd.protocolFolderName,'/')==0);
assert(contains(expFoldersUpd.protocolFolderName,'\')==0);
assert(contains(expFoldersUpd.dataFolderName,'/')==0);
assert(contains(expFoldersUpd.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFoldersUpd.sequenceMetaData},{flrFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFoldersUpd.protocolFolderName},{flrFolderName}];
sequenceDataFiles.folder      = ...
  [{expFoldersUpd.dataFolderName},{flrFolderName}];

flrDataDir         = fullfile(expFoldersUpd.dataFolderName,flrFolderName); 
flrProtocolDir     = fullfile(expFoldersUpd.protocolFolderName,flrFolderName); 
flrLabelDir        = fullfile(expFoldersUpd.blockLabelsFolderName,flrFolderName); 
flrMetaDataDir     = fullfile(expFoldersUpd.sequenceMetaData,flrFolderName); 

expFoldersUpd.dataFolderName         = flrDataDir;
expFoldersUpd.protocolFolderName     = flrProtocolDir;
expFoldersUpd.blockLabelsFolderName  = flrLabelDir;
expFoldersUpd.sequenceMetaData       = flrMetaDataDir;

if(~exist(fullfile(expFoldersUpd.rootFolderPath,flrDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,flrDataDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,flrProtocolDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,flrProtocolDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,flrLabelDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,flrLabelDir));
end
if(~exist(fullfile(expFoldersUpd.rootFolderPath,flrMetaDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,flrMetaDataDir));
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
        type = 'rampSineWave';
        endingLength = expConfig.ramp.length(idxTrial);

        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,endingLength,...
                        auroraConfig.defaultLengthUnit, dateId,'');         
      case 2
  
        seriesName = sequenceIdStr;
        type = 'FLR';
        endingLength = expConfig.ramp.length(idxTrial);

        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,endingLength,...
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
  
        %
        % Ramp Recovery sine wave
        %
        lengthRampOptions = ...
          getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
           
        lengthRampOptions(1).value = expConfig.ramp.length(idxTrial);
        lengthRampOptions(2).value = expConfig.ramp.duration(idxTrial);

        flag_isASequence=1;
        success = createRampRecoveryTrial610A(...
                            lengthRampOptions,...
                            trialFileNameNoExt,...                                     
                            auroraConfigRecovery,...
                            expConfig,...
                            expFoldersUpd,...
                            flag_isASequence);   
       
      case 2
  
        fid = fopen(fullfile(expFoldersUpd.rootFolderPath,...
                             expFoldersUpd.protocolFolderName,...
                             [trialFileNameNoExt,'.dpf']),'w');
       
        
        trialBlockLabelFilePath = fullfile(expFoldersUpd.rootFolderPath,...
                                          expFoldersUpd.blockLabelsFolderName,...
                                          [trialFileNameNoExt,'.csv']);
        
        programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
        programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);
        
        jsonMetaData = struct('segments',[],'experiment',[]);  
        
        numberOfSegments= 1; 
        
        segmentMetaDataArray(numberOfSegments) = ...
            struct('type','',mdfn.time,[0,0],'meta_data',[]);

        idxSeg=1;        

        tetanusDuration  =expConfig.timeToReachMaxActivation ...
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
  

        jsonMetaData.segments = segmentMetaDataArray;        

        jsonMetaData.experiment.title = ...
          sprintf('Isometric activation: %1.1f mm',...
                  expConfig.ramp.length(idxTrial));
          jsonMetaData.experiment.tags = {'force-length-relation'};
 

        jsonMetaDataEncoded = jsonencode(jsonMetaData);
        fidJson = fopen(fullfile(expFoldersUpd.rootFolderPath,...
                                  expFoldersUpd.sequenceMetaData,...
                                 [trialFileNameNoExt,'.json']),'w');
        fprintf(fidJson,jsonMetaDataEncoded);
        fclose(fidJson);
        
        fclose(fid);
        fclose(programMetaData.labelFileHandle);
                
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


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],'flr',[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFoldersUpd.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);

