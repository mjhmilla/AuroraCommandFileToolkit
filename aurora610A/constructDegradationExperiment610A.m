function [trialId,expFolders]= constructDegradationExperiment610A(...
                        dateId,...
                        trialId,...
                        sequenceId,...
                        auroraConfig,...
                        degradationConfig,...
                        expFolders,...
                        projectFolders)

fprintf('\nconstructDegradationExperiments610A');

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

degFolderName         = [sequenceIdStr,'_degradation'];

assert(contains(expFolders.sequenceMetaData,'/')==0);
assert(contains(expFolders.sequenceMetaData,'\')==0);
assert(contains(expFolders.protocolFolderName,'/')==0);
assert(contains(expFolders.protocolFolderName,'\')==0);
assert(contains(expFolders.dataFolderName,'/')==0);
assert(contains(expFolders.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFolders.sequenceMetaData},{degFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFolders.protocolFolderName},{degFolderName}];
sequenceDataFiles.folder      = ...
  [{expFolders.dataFolderName},{degFolderName}];

degDataDir         = fullfile(expFolders.dataFolderName,degFolderName); 
degProtocolDir     = fullfile(expFolders.protocolFolderName,degFolderName); 
degLabelDir        = fullfile(expFolders.blockLabelsFolderName,degFolderName); 
degMetaDataDir     = fullfile(expFolders.sequenceMetaData,degFolderName); 

expFolders.dataFolderName         = degDataDir;
expFolders.protocolFolderName     = degProtocolDir;
expFolders.blockLabelsFolderName  = degLabelDir;
expFolders.sequenceMetaData       = degMetaDataDir;

if(~exist(fullfile(expFolders.rootFolderPath,degDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,degDataDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,degProtocolDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,degProtocolDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,degLabelDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,degLabelDir));
end
if(~exist(fullfile(expFolders.rootFolderPath,degMetaDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,degMetaDataDir));
end


%%
% Create the files
%%

flag_printMetaDataToFile = 1;


sequenceTrialCount = 0;

for idxTrialType = 1:1:length(degradationConfig.exp.numberOfTrials)

  for idxTrial = 1:1:degradationConfig.exp.numberOfTrials(idxTrialType)
  
    for idxFile=1:1:2
    
      sequenceTrialCount = sequenceTrialCount+1;
  
      switch idxFile
        case 1
    
          auroraConfigLocal = auroraConfig.default;
    
          seriesName = sequenceIdStr;
          idxP = sequenceTrialCount;
          type = 'tetanus';
          
          trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
                          auroraConfigLocal.defaultLengthUnit, dateId,'');
        case 2
          
          auroraConfigLocal = auroraConfig.recovery;
          seriesName = sequenceIdStr;
          idxP = sequenceTrialCount;
          type = 'sine_wave';
          
          trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
                          auroraConfigLocal.defaultLengthUnit, dateId,'');      
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
  
      fid = fopen(fullfile(expFolders.rootFolderPath,...
                           expFolders.protocolFolderName,...
                           [trialFileNameNoExt,'.dpf']),'w');
     
      
      trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                        expFolders.blockLabelsFolderName,...
                                        [trialFileNameNoExt,'.csv']);
      
      programMetaData = getEmptyProgramMetaDataStruct610A(trialBlockLabelFilePath);
      programMetaData = writePreamble610A(fid,auroraConfigLocal,programMetaData);
      
      jsonMetaData = struct('segments',[],'experiment',[]);
      
  %     jsonMetaData.data.file = {expFolders.dataFolderName, ...
  %                               [trialFileNameNoExt,'.ddf']};
  %     jsonMetaData.data.sha256 = "";
  %     
  %     jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
  %                               [trialFileNameNoExt,'.dpf']};
  %     jsonMetaData.protocol.sha256 = "";
      
      %
      % Meta data 
      %
      
      mdfn = getMetaDataFieldNames610A(auroraConfigLocal);
      numberOfSegments=1;
      
      segmentMetaDataArray(numberOfSegments) = ...
          struct('type','',mdfn.time,[0,0],'meta_data',[]);
      
      switch idxFile
        case 1
    
          %
          % Meta data
          %
          stimulusTetanusOptions = ...
            getCommandFunctionOptions610A(...
                'Stimulus-Tetanus','Stimulator',auroraConfigLocal);
          
          stimulusTetanusOptions(1).value=...
            degradationConfig.tetanus.initialDelay;
          stimulusTetanusOptions(2).value=...
            degradationConfig.tetanus.pulseFrequency;
          stimulusTetanusOptions(3).value=...
            degradationConfig.tetanus.pulseWidth;
          stimulusTetanusOptions(4).value=...
            degradationConfig.exp.stimulationDuration(idxTrialType);
    
          startTime = degradationConfig.timing.waitTime;
          endTime   = startTime ...
                      +degradationConfig.tetanus.initialDelay ...
                      +degradationConfig.exp.stimulationDuration(idxTrialType);
          
          idxSeg=1;
          segmentMetaDataArray(idxSeg).type = 'Stimulus-Tetanus';
          segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime];
          segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
          segmentMetaDataArray(idxSeg).meta_data.channel= ...
            stimulusTetanusOptions(1).port;
          
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.initialDelay)  = ...
            degradationConfig.tetanus.initialDelay;
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseFrequency)= ...
            degradationConfig.tetanus.pulseFrequency;  
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.pulseWidth)    = ...
            degradationConfig.tetanus.pulseWidth;
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.duration)      = ...
            degradationConfig.exp.stimulationDuration(idxTrialType);
    
          %
          % Command
          %
             
          
          programMetaData = writeControlFunction610A(...
                              fid,...
                              degradationConfig.timing.waitTime,...
                              'Stimulus-Tetanus',...
                              stimulusTetanusOptions,...
                              auroraConfigLocal,...                
                              programMetaData,...
                              flag_printMetaDataToFile); 
          
          endTimeError = endTime - programMetaData.controlFunction.endTime;
          assert(abs(endTimeError)<1e-3,...
              'Error: end time differs from the meta data');  
    
          waitTime = degradationConfig.timing.waitTime ...
                    + degradationConfig.exp.stimulationDuration(idxTrialType);
    
          programMetaData = ...
              writeClosingBlock610A(...
                  fid,...
                  waitTime,...
                  auroraConfigLocal,...
                  programMetaData,...
                  flag_printMetaDataToFile);
          
          success = 1;
          assert(programMetaData.lineCount ...
                  < auroraConfigLocal.maximumNumberOfCommands,...
              'Error: maximumNumberOfCommandsExceeded');      
    
        case 2
    
          %
          % Meta data
          %
          sineTime =  degradationConfig.recovery.sineWave.cycles ...
                     /degradationConfig.recovery.sineWave.frequency;

          sineTimeRounded = ...
            roundTimeToNearestSampleTime(sineTime,auroraConfigLocal);
          
          assert(abs(sineTime-sineTimeRounded) < 10*eps,...
                 ['Error: the combination of the a/d sample rate and the ' ...
                  'sine frequency will not yield the desired number of cycles']);
    
          lengthSineOptions = getCommandFunctionOptions610A(...
                                'Sine Wave','Length Out',auroraConfigLocal);
          lengthSineOptions(1).value = ...
              degradationConfig.recovery.sineWave.frequency;
          lengthSineOptions(2).value = ...
              degradationConfig.recovery.sineWave.amplitude;
          lengthSineOptions(3).value = ...
              degradationConfig.recovery.sineWave.cycles;
          
    
          startTime = degradationConfig.timing.waitTime;
          endTime   = startTime ...
                      +sineTime;
          
          
          segmentMetaDataArray(idxSeg).(mdfn.time) = [startTime,endTime]; 
          
          segmentMetaDataArray(idxSeg).type = ['Sine Wave'];
          segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
          
          segmentMetaDataArray(idxSeg).meta_data.channel            ...
              = lengthSineOptions(1).port;
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.frequency) = ...
            lengthSineOptions(1).value;
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.amplitude) = ...
            lengthSineOptions(2).value;    
          segmentMetaDataArray(idxSeg).meta_data.(mdfn.cycles) = ...
            lengthSineOptions(3).value;    
          
          %
          % Write the protocol
          %
          programMetaData ...
                  = writeControlFunction610A(...
                          fid,...
                          degradationConfig.timing.waitTime,...
                          'Sine Wave',...
                          lengthSineOptions,...
                          auroraConfigLocal,...                
                          programMetaData,...
                          flag_printMetaDataToFile);  
    
          endTimeError = endTime - programMetaData.controlFunction.endTime;
          assert(abs(endTimeError)<1e-3,...
              'Error: end time differs from the meta data');  
    
      
          programMetaData = ...
              writeClosingBlock610A(...
                  fid,...
                  degradationConfig.recovery.sineWave.waitTime,...
                  auroraConfigLocal,...
                  programMetaData,...
                  flag_printMetaDataToFile);
          
          success = 1;
          assert(programMetaData.lineCount < auroraConfigLocal.maximumNumberOfCommands,...
              'Error: maximumNumberOfCommandsExceeded');      
    
        otherwise
          assert(0,'Error: this file is only configured for 2 files');
      end
    
    
      %
      % Write the json files
      %
      jsonMetaData.segments = segmentMetaDataArray;
    
      switch idxFile
        case 1
          jsonMetaData.experiment.title = ...
            sprintf('Tetanus: %1.1f%s %1.1f%s %1.1f%s',...
                    degradationConfig.tetanus.pulseFrequency, ...
                    auroraConfigLocal.defaultFrequencyUnit,...
                    degradationConfig.tetanus.pulseWidth,...
                    auroraConfigLocal.defaultPulseWidthTimeUnit,...
                    degradationConfig.exp.stimulationDuration(idxTrialType),...
                    auroraConfigLocal.defaultTimeUnit);
            jsonMetaData.experiment.tags = {'degradation'};
        case 2
          jsonMetaData.experiment.title = ...
            sprintf('Passive Sine Wave: %1.1f%s %1.1f%s %1.1f %s',...
                    degradationConfig.recovery.sineWave.frequency, ...
                    auroraConfigLocal.defaultFrequencyUnit,...
                    degradationConfig.recovery.sineWave.amplitude,...
                    auroraConfigLocal.defaultLengthUnit,...
                    degradationConfig.recovery.sineWave.cycles,...
                    'cycles');
            jsonMetaData.experiment.tags = {'recovery'};
        otherwise
          assert(0,'Error: this file is only configured for 2 files');      
      end
    
      
      jsonMetaDataEncoded = jsonencode(jsonMetaData);
      fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                                expFolders.sequenceMetaData,...
                               [trialFileNameNoExt,'.json']),'w');
      fprintf(fidJson,jsonMetaDataEncoded);
      fclose(fidJson);
      
      fclose(fid);
      fclose(programMetaData.labelFileHandle);
    
    
      trialId=trialId+1;
    end
  end
end

jsonSequenceSeriesMetaData.sequence_file = [];
jsonSequenceSeriesMetaData.meta_data = sequenceMetaDataFiles;
jsonSequenceSeriesMetaData.protocols = sequenceProtocolFiles;
jsonSequenceSeriesMetaData.data      = sequenceDataFiles;

jsonSequenceMetaData.experiment.comment = "";
jsonSequenceMetaData.experiment.manually_measured_temperature_C ...
  = degradationConfig.muscle.temperatureC;
jsonSequenceMetaData.sequence = jsonSequenceSeriesMetaData;


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],'degradation',[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);


