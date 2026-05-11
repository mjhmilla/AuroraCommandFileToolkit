function trialId = constructDegradationExperiment610A(...
                        dateId,...
                        trialId,...
                        sequenceId,...
                        degradationConfig,...
                        expFolders,...
                        projectFolders)

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

for idxTrial = 1:1:degradationConfig.numberOfTrials

  for idxFile=1:1:2
  
    sequenceTrialCount = sequenceTrialCount+1;

    switch idxFile
      case 1
        sampleFrequency = degradationConfig.tetanus.sampleFrequency;
  
        auroraConfig = getDefaultAuroraConfiguration610A(...
                            degradationConfig.muscleName,...
                            degradationConfig.unitSystem,...
                            sampleFrequency,...    
                            degradationConfig.lceOptMM,...
                            degradationConfig.vceMaxLPS);
  
        seriesName = sequenceIdStr;
        idxP = sequenceTrialCount;
        type = 'tetanus';
        
        trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
                        auroraConfig.defaultLengthUnit, dateId,'');
      case 2
  
        sampleFrequency = degradationConfig.sineWave.sampleFrequency;
  
        auroraConfig = getDefaultAuroraConfiguration610A(...
                            degradationConfig.muscleName,...
                            degradationConfig.unitSystem,...
                            sampleFrequency,...    
                            degradationConfig.lceOptMM,...
                            degradationConfig.vceMaxLPS);      
        seriesName = sequenceIdStr;
        idxP = sequenceTrialCount;
        type = 'sine_wave';
        
        trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
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

    fid = fopen(fullfile(expFolders.rootFolderPath,...
                         expFolders.protocolFolderName,...
                         [trialFileNameNoExt,'.dpf']),'w');
   
    
    trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                      expFolders.blockLabelsFolderName,...
                                      [trialFileNameNoExt,'.csv']);
    
    programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
    programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);
    
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
    
    mdfn = getMetaDataFieldNames610A(auroraConfig);
    numberOfSegments=1;
    
    segmentMetaDataArray(numberOfSegments) = ...
        struct('type','',mdfn.time,[0,0],'meta_data',[]);
    
    switch idxFile
      case 1
  
        %
        % Meta data
        %
        stimulusTetanusOptions = getCommandFunctionOptions610A(...
                                  'Stimulus-Tetanus','Stimulator',auroraConfig);
        
        stimulusTetanusOptions(1).value=degradationConfig.tetanus.initialDelay;
        stimulusTetanusOptions(2).value=degradationConfig.tetanus.pulseFrequency;
        stimulusTetanusOptions(3).value=degradationConfig.tetanus.pulseWidth;
        stimulusTetanusOptions(4).value=degradationConfig.tetanus.duration;
  
        startTime = degradationConfig.waitTime;
        endTime   = startTime ...
                    +degradationConfig.tetanus.initialDelay ...
                    +degradationConfig.tetanus.duration;
        
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
          degradationConfig.tetanus.duration;
  
        %
        % Command
        %
           
        
        programMetaData = writeControlFunction610A(...
                            fid,...
                            degradationConfig.waitTime,...
                            'Stimulus-Tetanus',...
                            stimulusTetanusOptions,...
                            auroraConfig,...                
                            programMetaData,...
                            flag_printMetaDataToFile); 
        
        endTimeError = endTime - programMetaData.controlFunction.endTime;
        assert(abs(endTimeError)<1e-3,...
            'Error: end time differs from the meta data');  
  
        waitTime = degradationConfig.waitTime ...
                  + degradationConfig.tetanus.duration;
  
        programMetaData = ...
            writeClosingBlock610A(...
                fid,...
                waitTime,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile);
        
        success = 1;
        assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
            'Error: maximumNumberOfCommandsExceeded');      
  
      case 2
  
        %
        % Meta data
        %
        sineTime =  degradationConfig.sineWave.cycles ...
                   /degradationConfig.sineWave.frequency;
        sineTimeRounded = ...
          round(sineTime*auroraConfig.analogToDigitalSampleRateHz) ...
          /auroraConfig.analogToDigitalSampleRateHz;
        
        assert(abs(sineTime-sineTimeRounded) < 10*eps,...
               ['Error: the combination of the a/d sample rate and the ' ...
                'sine frequency will not yield the desired number of cycles']);
  
        lengthSineOptions = getCommandFunctionOptions610A(...
                              'Sine Wave','Length Out',auroraConfig);
        lengthSineOptions(1).value = degradationConfig.sineWave.frequency;
        lengthSineOptions(2).value = degradationConfig.sineWave.amplitude;
        lengthSineOptions(3).value = degradationConfig.sineWave.cycles;
        
  
        startTime = degradationConfig.waitTime;
        endTime   = startTime ...
                    +degradationConfig.sineWave.waitTime ...
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
                        degradationConfig.waitTime,...
                        'Sine Wave',...
                        lengthSineOptions,...
                        auroraConfig,...                
                        programMetaData,...
                        flag_printMetaDataToFile);  
  
        endTimeError = endTime - programMetaData.controlFunction.endTime;
        assert(abs(endTimeError)<1e-3,...
            'Error: end time differs from the meta data');  
  
    
        programMetaData = ...
            writeClosingBlock610A(...
                fid,...
                degradationConfig.waitTime,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile);
        
        success = 1;
        assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
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
                  auroraConfig.defaultFrequencyUnit,...
                  degradationConfig.tetanus.pulseWidth,...
                  auroraConfig.defaultPulseWidthTimeUnit,...
                  degradationConfig.tetanus.duration,...
                  auroraConfig.defaultTimeUnit);
          jsonMetaData.experiment.tags = {'degradation'};
      case 2
        jsonMetaData.experiment.title = ...
          sprintf('Passive Sine Wave: %1.1f%s %1.1f%s %1.1f %s',...
                  degradationConfig.sineWave.frequency, ...
                  auroraConfig.defaultFrequencyUnit,...
                  degradationConfig.sineWave.amplitude,...
                  auroraConfig.defaultLengthUnit,...
                  degradationConfig.sineWave.cycles,...
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

jsonSequenceSeriesMetaData.sequence_file = [];
jsonSequenceSeriesMetaData.meta_data = sequenceMetaDataFiles;
jsonSequenceSeriesMetaData.protocols = sequenceProtocolFiles;
jsonSequenceSeriesMetaData.data      = sequenceDataFiles;

jsonSequenceMetaData.experiment.comment = "";
jsonSequenceMetaData.experiment.manually_measured_temperature_C ...
  = degradationConfig.temperature;
jsonSequenceMetaData.sequence = jsonSequenceSeriesMetaData;


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],'degradation',[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);

