function [trialId, expFoldersUpd] = ...
  constructActiveLengtheningInjuryExperiment610A(...
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

flag_isASequence=1;
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

expFoldersUpd = expFolders;

assert(contains(expFoldersUpd.sequenceMetaData,'/')==0);
assert(contains(expFoldersUpd.sequenceMetaData,'\')==0);
assert(contains(expFoldersUpd.protocolFolderName,'/')==0);
assert(contains(expFoldersUpd.protocolFolderName,'\')==0);
assert(contains(expFoldersUpd.dataFolderName,'/')==0);
assert(contains(expFoldersUpd.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFoldersUpd.sequenceMetaData},{rampFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFoldersUpd.protocolFolderName},{rampFolderName}];
sequenceDataFiles.folder      = ...
  [{expFoldersUpd.dataFolderName},{rampFolderName}];

rampDataDir         = fullfile(expFoldersUpd.dataFolderName,rampFolderName); 
rampProtocolDir     = fullfile(expFoldersUpd.protocolFolderName,rampFolderName); 
rampLabelDir        = fullfile(expFoldersUpd.blockLabelsFolderName,rampFolderName); 
rampMetaDataDir     = fullfile(expFoldersUpd.sequenceMetaData,rampFolderName); 

expFoldersUpd.dataFolderName         = rampDataDir;
expFoldersUpd.protocolFolderName     = rampProtocolDir;
expFoldersUpd.blockLabelsFolderName  = rampLabelDir;
expFoldersUpd.sequenceMetaData       = rampMetaDataDir;

if(~exist(fullfile(expFoldersUpd.rootFolderPath,rampDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,rampDataDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,rampProtocolDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,rampProtocolDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,rampLabelDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,rampLabelDir));
end
if(~exist(fullfile(expFoldersUpd.rootFolderPath,rampMetaDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,rampMetaDataDir));
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

  for idxTrialType=1:1:4
  
    sequenceTrialCount = sequenceTrialCount+1;
    
    switch idxTrialType
      case 1
        seriesName = sequenceIdStr;
        type = 'probe';
        
        lengthChange = expConfig.probe.passiveLength;        
        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,lengthChange,...
                       auroraConfig.defaultLengthUnit, dateId,'');
      case 2
        seriesName = sequenceIdStr;
        type = 'sineWave';
        
        trialFileNameNoExt  = ...
          getTrialName(seriesName,sequenceTrialCount,type,0,...
                       auroraConfig.defaultLengthUnit, dateId,'');         
      case 3
  
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
      case 4
      
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
    
    
    switch idxTrialType
      case 1
        %
        % Probe trial
        %
        success = createActivePassiveProbeTrial610A(...
                                  trialFileNameNoExt,...                                     
                                  auroraConfig,...
                                  expConfig,...
                                  expFoldersUpd,...
                                  flag_isASequence);     
      case 2
  
        %
        % Recovery sine wave
        %
 
        success = createRecoveryTrial610A(...
                            trialFileNameNoExt,...                                     
                            auroraConfigRecovery,...
                            expConfig,...
                            expFoldersUpd,...
                            flag_isASequence);         
      case 3
        expConfigTrial = expConfig;
        expConfigTrial.ramp.length   = expConfig.ramp.length(idxTrial);
        expConfigTrial.ramp.duration = expConfig.ramp.duration(idxTrial);
        expConfigTrial.ramp.isActive = expConfig.ramp.isActive(idxTrial);

        success = createStretchShortenTrial610A(...                         
                          trialFileNameNoExt,...                                     
                          auroraConfig,...
                          expConfigTrial,...
                          expFoldersUpd,...
                          flag_isASequence);
      case 4
  
        %
        % Recovery sine wave
        %
 
        success = createRecoveryTrial610A(...
                            trialFileNameNoExt,...                                     
                            auroraConfigRecovery,...
                            expConfig,...
                            expFoldersUpd,...
                            flag_isASequence);   
 

      otherwise
        assert(0,'Error: this file is only configured for 2 files');
    end  
    trialId=trialId+1;
  end
end

%
% One final probe trial
%

sequenceTrialCount = sequenceTrialCount+1;

seriesName = sequenceIdStr;
type = 'probe';

lengthChange = expConfig.probe.passiveLength;        
trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,type,lengthChange,...
               auroraConfig.defaultLengthUnit, dateId,'');

sequenceMetaDataFiles.files  = ...
  [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
sequenceProtocolFiles.files  = ...
  [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
sequenceDataFiles.files      = ...
  [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
sequenceDataFiles.sha256 = ...
  [sequenceDataFiles.sha256,{''}];

success = createActivePassiveProbeTrial610A(...
                          trialFileNameNoExt,...                                     
                          auroraConfig,...
                          expConfig,...
                          expFoldersUpd,...
                          flag_isASequence);    

%
% Write meta data
%
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

fidSeqJson = fopen(fullfile(expFoldersUpd.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);

