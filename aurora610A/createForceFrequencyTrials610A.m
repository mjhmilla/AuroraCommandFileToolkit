function trialId = createForceFrequencyTrials610A(...
                      dateId,...
                      trialId,...
                      sequenceId,...
                      auroraConfig,...
                      expConfig,...   
                      expFolders,...
                      projectFolders)

success = 0;

auroraConfigDefault=auroraConfig;

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

ffrFolderName         = [sequenceIdStr,'_ffr'];

assert(contains(expFolders.sequenceMetaData,'/')==0);
assert(contains(expFolders.sequenceMetaData,'\')==0);
assert(contains(expFolders.protocolFolderName,'/')==0);
assert(contains(expFolders.protocolFolderName,'\')==0);
assert(contains(expFolders.dataFolderName,'/')==0);
assert(contains(expFolders.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFolders.sequenceMetaData},{ffrFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFolders.protocolFolderName},{ffrFolderName}];
sequenceDataFiles.folder      = ...
  [{expFolders.dataFolderName},{ffrFolderName}];

ffrDataDir         = fullfile(expFolders.dataFolderName,ffrFolderName); 
ffrProtocolDir     = fullfile(expFolders.protocolFolderName,ffrFolderName); 
ffrLabelDir        = fullfile(expFolders.blockLabelsFolderName,ffrFolderName); 
ffrMetaDataDir     = fullfile(expFolders.sequenceMetaData,ffrFolderName); 

expFolders.dataFolderName         = ffrDataDir;
expFolders.protocolFolderName     = ffrProtocolDir;
expFolders.blockLabelsFolderName  = ffrLabelDir;
expFolders.sequenceMetaData       = ffrMetaDataDir;

if(~exist(fullfile(expFolders.rootFolderPath,ffrDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,ffrDataDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,ffrProtocolDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,ffrProtocolDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,ffrLabelDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,ffrLabelDir));
end
if(~exist(fullfile(expFolders.rootFolderPath,ffrMetaDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,ffrMetaDataDir));
end




mdFieldNames = getMetaDataFieldNames610A(auroraConfig);

timeFieldName      = mdFieldNames.time;
cyclesFieldName    = mdFieldNames.cycles;
frequencyFieldName = mdFieldNames.frequency;
amplitudeFieldName = mdFieldNames.amplitude; 
lengthFieldName    = mdFieldNames.length;

initialDelayFieldName   = mdFieldNames.initialDelay;
pulseWidthFieldName     = mdFieldNames.pulseWidth;
pulseFrequencyFieldName = mdFieldNames.pulseFrequency;
durationFieldName       = mdFieldNames.duration;


 






%idxSeg = 0;
%idxP=0;
idxSequenceFile = 0;

flag_printMetaDataToFile = 1;
for idxS = 1:1:length(expConfig.tetanus.pulseFrequency)




  for idxTrialType = 1:1:2

    idxSequenceFile=idxSequenceFile + 1; 
    trialId=trialId+1;
    %%
    % Create the file name
    %%
    typeStr = '';
    switch idxTrialType
      case 1 
        typeStr = 'ffr';
        auroraConfig = auroraConfigDefault;
 

      case 2
        typeStr = 'sineWave';
        sampleFrequency = expConfig.sineWave.sampleFrequency;
  
        auroraConfig = getDefaultAuroraConfiguration610A(...
                            expConfig.muscleName,...
                            expConfig.unitSystem,...
                            sampleFrequency,...    
                            expConfig.lceOptMM,...
                            expConfig.vceMaxLPS);   

      otherwise
        assert(0,'Error: Unrecognized trial type');
    end


    seriesName = sequenceIdStr;

    operatingLength = 0;

    trialFileNameNoExt  = ...
      getTrialName(seriesName,idxSequenceFile,typeStr,operatingLength,...
                    auroraConfig.defaultLengthUnit, dateId,'');

    %%
    % Set up the files and metadata structures
    %%
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
% 
%     jsonMetaData.data.file = {expFolders.dataFolderName, ...
%                               [trialFileNameNoExt,'.ddf']};
%     jsonMetaData.data.sha256 = "";
% 
%     jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
%                                   [trialFileNameNoExt,'.dpf']};
%     jsonMetaData.protocol.sha256 = "";



    segmentMetaDataArray(1) = ...
        struct('type','',timeFieldName,[0,0],'meta_data',[]);

    idxSeg = 1;

    switch idxTrialType

      %
      % Tetanus
      %
      case 1
        stimulusTetanusOptions = ...
          getCommandFunctionOptions610A('Stimulus-Tetanus','Stimulator',auroraConfig);
        stimulusTetanusOptions(1).value=expConfig.tetanus.initialDelay;
        stimulusTetanusOptions(2).value=expConfig.tetanus.pulseFrequency(idxS);
        stimulusTetanusOptions(3).value=expConfig.tetanus.pulseWidth;
        stimulusTetanusOptions(4).value=expConfig.tetanus.duration;

        startTime = programMetaData.nextStartTime ...
                      + stimulusTetanusOptions(1).value;
        
        endTime = startTime ...
                  + stimulusTetanusOptions(4).value;


        %Tetanus structure
        segmentMetaDataArray(idxSeg).type = 'Stimulus-Tetanus';
        segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];
        segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
        segmentMetaDataArray(idxSeg).meta_data.channel= stimulusTetanusOptions(1).port;
        segmentMetaDataArray(idxSeg).meta_data.(initialDelayFieldName)= ...
          stimulusTetanusOptions(1).value;
        segmentMetaDataArray(idxSeg).meta_data.(pulseFrequencyFieldName)= ...
          stimulusTetanusOptions(2).value;          
        segmentMetaDataArray(idxSeg).meta_data.(pulseWidthFieldName)= ...
          stimulusTetanusOptions(3).value;
        segmentMetaDataArray(idxSeg).meta_data.(durationFieldName)=...
          stimulusTetanusOptions(4).value;

        %Write the twitch
        programMetaData = writeControlFunction610A(...
                            fid,...
                            0,...
                            'Stimulus-Tetanus',...
                            stimulusTetanusOptions,...
                            auroraConfig,...                
                            programMetaData,...
                            flag_printMetaDataToFile); 

        endTimeError = endTime - programMetaData.controlFunction.endTime;
        assert(abs(endTimeError)<1e-3,...
            'Error: end time differs from the meta data');        

      %
      % Sine wave
      %
      case 2 

        lengthSineOptions = getCommandFunctionOptions610A(...
                              'Sine Wave','Length Out',auroraConfig);
        lengthSineOptions(1).value = expConfig.sineWave.frequency;
        lengthSineOptions(2).value = expConfig.sineWave.amplitude;
        lengthSineOptions(3).value = expConfig.sineWave.cycles;


        sineTime = (expConfig.sineWave.cycles ...
                   /expConfig.sineWave.frequency);

        startTime = programMetaData.nextStartTime ...
                   +expConfig.sineWave.waitTime;
        
        endTime = startTime + sineTime;

        % Sine wave
        idxSeg =idxSeg + 1;
        segmentMetaDataArray(idxSeg).type = 'Sine Wave';
        segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];
        segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
          segmentMetaDataArray(idxSeg).meta_data.channel=lengthSineOptions(1).port;
        segmentMetaDataArray(idxSeg).meta_data.(frequencyFieldName)= ...
          lengthSineOptions(1).value;    
        segmentMetaDataArray(idxSeg).meta_data.(amplitudeFieldName)= ...
          lengthSineOptions(2).value;
        segmentMetaDataArray(idxSeg).meta_data.(cyclesFieldName)= ...
          lengthSineOptions(3).value;    

        %Write the wave
        programMetaData = writeControlFunction610A(...
                            fid,...
                            expConfig.sineWave.waitTime,...
                            'Sine Wave',...
                            lengthSineOptions,...
                            auroraConfig,...                
                            programMetaData,...
                            flag_printMetaDataToFile); 

        endTimeError = endTime - programMetaData.controlFunction.endTime;
        assert(abs(endTimeError)<1e-3,...
            'Error: end time differs from the meta data');
        

      otherwise assert(0,'Error: Unrecognized trial type');
    end

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

    trialTitleStr = '';
    tags = {''};
    switch idxTrialType
      case 1 
        trialTitleStr = ...
          sprintf('Force-frequency-relationship %1.1fHz', ...
                  expConfig.tetanus.pulseFrequency(idxS));
          tags = {'force-frequency-relationship'};
      case 2
        trialTitleStr = ...
          sprintf("Passive Sine Wave: %1.1fHz %1.1fmm %1.1f cycles",...
                           expConfig.sineWave.frequency,...
                           expConfig.sineWave.amplitude,...
                           expConfig.sineWave.cycles);
        tags = {'recovery'};          
      otherwise
        assert(0,'Error: Unrecognized trial type');
    end


    jsonMetaData.segments = segmentMetaDataArray;
    jsonMetaData.experiment.title = trialTitleStr;
    jsonMetaData.experiment.tags = tags;

    jsonMetaDataEncoded = jsonencode(jsonMetaData);
    fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                             expFolders.sequenceMetaData,...
                             [trialFileNameNoExt,'.json']),'w');
    fprintf(fidJson,jsonMetaDataEncoded);
    fclose(fidJson);

    fclose(fid);
    fclose(programMetaData.labelFileHandle);


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


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],'ffr',[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);










