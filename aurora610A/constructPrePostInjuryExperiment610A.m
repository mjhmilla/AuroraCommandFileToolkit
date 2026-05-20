function [trialId, expFoldersUpd] = ...
  constructPrePostInjuryExperiment610A(...
                        dateId,...
                        trialId,...
                        sequenceId,...
                        sequenceName,...
                        stochasticWaves,...                        
                        auroraConfig,...
                        expConfig,...
                        expFolders,...
                        projectFolders)

auroraConfigRecovery = getDefaultAuroraConfiguration610A(...
                        expConfig.muscleName,...
                        expConfig.unitSystem,...
                        expConfig.recovery.sampleFrequency,...    
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

prePostFolderName         = [sequenceIdStr,'_',sequenceName];

expFoldersUpd = expFolders;

assert(contains(expFoldersUpd.sequenceMetaData,'/')==0);
assert(contains(expFoldersUpd.sequenceMetaData,'\')==0);
assert(contains(expFoldersUpd.protocolFolderName,'/')==0);
assert(contains(expFoldersUpd.protocolFolderName,'\')==0);
assert(contains(expFoldersUpd.dataFolderName,'/')==0);
assert(contains(expFoldersUpd.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFoldersUpd.sequenceMetaData},{prePostFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFoldersUpd.protocolFolderName},{prePostFolderName}];
sequenceDataFiles.folder      = ...
  [{expFoldersUpd.dataFolderName},{prePostFolderName}];

prePostDataDir         = fullfile(expFoldersUpd.dataFolderName,prePostFolderName); 
prePostProtocolDir     = fullfile(expFoldersUpd.protocolFolderName,prePostFolderName); 
prePostLabelDir        = fullfile(expFoldersUpd.blockLabelsFolderName,prePostFolderName); 
prePostMetaDataDir     = fullfile(expFoldersUpd.sequenceMetaData,prePostFolderName); 

expFoldersUpd.dataFolderName         = prePostDataDir;
expFoldersUpd.protocolFolderName     = prePostProtocolDir;
expFoldersUpd.blockLabelsFolderName  = prePostLabelDir;
expFoldersUpd.sequenceMetaData       = prePostMetaDataDir;

if(~exist(fullfile(expFoldersUpd.rootFolderPath,prePostDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,prePostDataDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,prePostProtocolDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,prePostProtocolDir));
end  
if(~exist(fullfile(expFoldersUpd.rootFolderPath,prePostLabelDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,prePostLabelDir));
end
if(~exist(fullfile(expFoldersUpd.rootFolderPath,prePostMetaDataDir),'dir'))
  mkdir(fullfile(expFoldersUpd.rootFolderPath,prePostMetaDataDir));
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

%%
% Passive ramp trials
%%

for idxPR = 1:1:length(expConfig.passive.ramp.length)
  sequenceTrialCount = sequenceTrialCount+1;

  seriesName = sequenceIdStr;
  typeName = 'passiveRamp';
  
  lengthChange = expConfig.passive.ramp.length(idxPR);
  velocityMMPS = expConfig.passive.ramp.velocity(idxPR);

  velocityMMPSStr = sprintf('%1.1f',velocityMMPS);
  velocityMMPSStr = strrep(velocityMMPSStr,'.','p');
  velocityMMPSStr = ['_',velocityMMPSStr,'mmps'];

  typeName = [typeName,velocityMMPSStr];

  trialFileNameNoExt  = ...
    getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
                 auroraConfig.defaultLengthUnit, dateId,'');
  
  %
  % Populate the sequence meta data
  %
  sequenceMetaDataFiles.files  = ...
    [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
  sequenceProtocolFiles.files  = ...
    [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
  sequenceDataFiles.files      = ...
    [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
  sequenceDataFiles.sha256 = ...
    [sequenceDataFiles.sha256,{''}];
  
  %
  % Generate the trial
  %
  expConfigTrial = [];
  expConfigTrial.tetanus = expConfig.tetanus;  
  rampFields = fields(expConfig.passive.ramp);
  for idxField=1:1:length(rampFields)
    if(length(expConfig.passive.ramp.(rampFields{idxField}))>1)
      expConfigTrial.ramp.(rampFields{idxField}) ...
        = expConfig.passive.ramp.(rampFields{idxField})(idxPR);
    else
      expConfigTrial.ramp.(rampFields{idxField}) ...
        = expConfig.passive.ramp.(rampFields{idxField});
    end
  end
  assert(expConfigTrial.ramp.isActive==0);
  expConfigTrial.stopWaitTime=expConfig.stopWaitTime;
  nominalLength = 0;
  success = createStretchShortenTrial610A(...  
                    nominalLength,...
                    trialFileNameNoExt,...                                     
                    auroraConfig,...
                    expConfigTrial,...
                    expFoldersUpd,...
                    flag_isASequence);    
  trialId=trialId+1;

end

%%
% Passive impedance trials 
%%
for idxPI = 1:1:length(expConfig.passive.impedance.length)
  % Ramp recovery name
  sequenceTrialCount = sequenceTrialCount+1;

  seriesName = sequenceIdStr;
  typeName = 'rampRecovery';
  
  lengthChange = expConfig.passive.impedance.length(idxPI);

  trialFileNameNoExt  = ...
    getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
                 auroraConfig.defaultLengthUnit, dateId,'');  

  %
  % Populate the sequence meta data
  %
  sequenceMetaDataFiles.files  = ...
    [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
  sequenceProtocolFiles.files  = ...
    [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
  sequenceDataFiles.files      = ...
    [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
  sequenceDataFiles.sha256 = ...
    [sequenceDataFiles.sha256,{''}];

  %%
  % Ramp Recovery sine wave
  %%
  lengthRampOptions = ...
    getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
     
  lengthRampOptions(1).value = lengthChange;
  lengthRampOptions(2).value = 1;
  
  expConfigTrial = [];
  expConfigTrial = expConfig.recovery;

  flag_isASequence=1;
  success = createRampRecoveryTrial610A(...
                      lengthRampOptions,...
                      trialFileNameNoExt,...                                     
                      auroraConfigRecovery,...
                      expConfigTrial,...
                      expFoldersUpd,...
                      flag_isASequence);  
  trialId=trialId + 1;

  %%
  % Passive impedance trial
  %%
  sequenceTrialCount = sequenceTrialCount+1;

  seriesName = sequenceIdStr;
  typeName = 'passiveImpedance';
  
  lengthChange = expConfig.passive.impedance.length(idxPI);

  trialFileNameNoExt  = ...
    getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
                 auroraConfig.defaultLengthUnit, dateId,'');  

  %
  % Populate the sequence meta data
  %
  sequenceMetaDataFiles.files  = ...
    [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
  sequenceProtocolFiles.files  = ...
    [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
  sequenceDataFiles.files      = ...
    [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
  sequenceDataFiles.sha256 = ...
    [sequenceDataFiles.sha256,{''}];

  %
  % Create the trial
  %
  flag_isASequence=1;
  expConfigTrial = [];
  expConfigTrial.impedance = expConfig.passive.impedance;
  expConfigTrial.stopWaitTime=expConfig.stopWaitTime;

  nominalLength=expConfig.passive.impedance.length(idxPI);

  success = createPassiveImpedanceTrial610A(...
                    nominalLength,...
                    trialFileNameNoExt,...
                    stochasticWaves(2),...                                        
                    auroraConfig,...
                    expConfigTrial,...
                    expFoldersUpd,...
                    flag_isASequence);
  
  trialId=trialId+1;
end

%%
% Ramp recovery to 0mm
%%
sequenceTrialCount = sequenceTrialCount+1;

seriesName = sequenceIdStr;
typeName = 'rampRecovery';

lengthChange = 0;

trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
               auroraConfig.defaultLengthUnit, dateId,'');  

%
% Populate the sequence meta data
%
sequenceMetaDataFiles.files  = ...
  [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
sequenceProtocolFiles.files  = ...
  [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
sequenceDataFiles.files      = ...
  [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
sequenceDataFiles.sha256 = ...
  [sequenceDataFiles.sha256,{''}];

%
% Ramp Recovery sine wave
%
lengthRampOptions = ...
  getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
   
lengthRampOptions(1).value = lengthChange;
lengthRampOptions(2).value = 1;

expConfigTrial = [];
expConfigTrial = expConfig.recovery;

flag_isASequence=1;
success = createRampRecoveryTrial610A(...
                    lengthRampOptions,...
                    trialFileNameNoExt,...                                     
                    auroraConfigRecovery,...
                    expConfigTrial,...
                    expFoldersUpd,...
                    flag_isASequence);  
trialId=trialId + 1;

%%
% Active trials
%%

%
% Plateau
%
sequenceTrialCount = sequenceTrialCount+1;

seriesName = sequenceIdStr;
typeName = 'plateauSearch';

lengthChange = max(expConfig.plateau.ramp.lengths);

trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
               auroraConfig.defaultLengthUnit, dateId,''); 

expConfigPlateau = expConfig.plateau;
flag_isASequence = 1;
trialId = createPlateauSearchTrail610A(...
                      trialFileNameNoExt,...
                      dateId,...
                      trialId,...
                      sequenceId,...
                      auroraConfig,...
                      expConfigPlateau,...
                      expFoldersUpd,...
                      projectFolders,...
                      flag_isASequence);  

%
% Isometric impedance at 0mm
%

sequenceTrialCount = sequenceTrialCount+1;

seriesName = sequenceIdStr;
typeName = 'isometricImpedance';

nominalLength = 0;

trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,typeName,nominalLength,...
               auroraConfig.defaultLengthUnit, dateId,''); 

expConfigUpd.impedance = expConfig.active.impedance;
expConfigUpd.tetanus   = expConfig.tetanus;
expConfigUpd.timeToReachMaxActivation = expConfig.timeToReachMaxActivation;
expConfigUpd.waitTime=expConfig.waitTime;

flag_isASequence=1;
success = createIsometricImpedanceTrial610A(...
                    nominalLength,...
                    stochasticWaves(1),...
                    trialFileNameNoExt,...                    
                    auroraConfig,...
                    expConfigUpd,...
                    expFoldersUpd, ...
                    flag_isASequence);

for idxRamp = 1:1:size(expConfig.activeRamp.lengths,2)

  for idxActive=1:1:2
      isActive = nan;
      switch idxActive
        case 1
          isActive=1;
        case 2
          isActive=0;
      end
      %%
      % Ramp recovery to starting length
      %%
      sequenceTrialCount = sequenceTrialCount+1;
      
      seriesName = sequenceIdStr;
      typeName = 'rampRecovery';
      
    
      lengthChange =  expConfig.activeRamp.lengths(idxRamp,1);
      
      trialFileNameNoExt  = ...
      getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
                   auroraConfig.defaultLengthUnit, dateId,'');  
      
      %
      % Populate the sequence meta data
      %
      sequenceMetaDataFiles.files  = ...
      [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
      sequenceProtocolFiles.files  = ...
      [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
      sequenceDataFiles.files      = ...
      [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
      sequenceDataFiles.sha256 = ...
      [sequenceDataFiles.sha256,{''}];
      
      %
      % Ramp Recovery sine wave
      %
      lengthRampOptions = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
       
      lengthRampOptions(1).value = lengthChange;
      lengthRampOptions(2).value = 1;
      
      expConfigTrial = [];
      expConfigTrial = expConfig.recovery;
      
      flag_isASequence=1;
      success = createRampRecoveryTrial610A(...
                        lengthRampOptions,...
                        trialFileNameNoExt,...                                     
                        auroraConfigRecovery,...
                        expConfigTrial,...
                        expFoldersUpd,...
                        flag_isASequence);  
      trialId=trialId + 1;
      
      
      
      
      %%
      % Active ramp trials
      %%
      sequenceTrialCount = sequenceTrialCount+1;
    
      seriesName = sequenceIdStr;
      if(isActive==1)
        typeName = 'activeRamp';
      else
        typeName = 'passiveRamp';
      end

      lengthChange = expConfig.activeRamp.lengths(idxRamp,2) ...
                    -expConfig.activeRamp.lengths(idxRamp,1);
      
      trialFileNameNoExt  = ...
      getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
                   auroraConfig.defaultLengthUnit, dateId,'');
      
      
      sequenceMetaDataFiles.files  = ...
      [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
      sequenceProtocolFiles.files  = ...
      [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
      sequenceDataFiles.files      = ...
      [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
      sequenceDataFiles.sha256 = ...
      [sequenceDataFiles.sha256,{''}];
      
      rampVelocity = expConfig.activeRamp.velocity(idxRamp);
      duration =   (expConfig.activeRamp.lengths(idxRamp,2) ...
                  -expConfig.activeRamp.lengths(idxRamp,1)) ...
                  ./rampVelocity;
      duration  = round(duration*auroraConfig.analogToDigitalSampleRateHz)...
                      /auroraConfig.analogToDigitalSampleRateHz;
      
      expConfigTrial = [];
      expConfigTrial.timeToReachMaxActivation=expConfig.timeToReachMaxActivation;
      expConfigTrial.tetanus = expConfig.tetanus;
      expConfigTrial.waitTime= expConfig.waitTime;
      expConfigTrial.stopWaitTime= expConfig.stopWaitTime;      
      expConfigTrial.ramp.length   = expConfig.activeRamp.lengths(idxRamp,2);
      expConfigTrial.ramp.duration = duration;
      expConfigTrial.ramp.isActive = isActive;
      expConfigTrial.ramp.holdDuration = 0;
      
      success = createRampTrial610A(...    
                      expConfig.activeRamp.lengths(idxRamp,1),...
                      trialFileNameNoExt,...                                     
                      auroraConfig,...
                      expConfigTrial,...
                      expFoldersUpd,...
                      flag_isASequence);
      trialId=trialId + 1;
  end
end

%%
% Isometric tetanus at different lengths
%%
for idxIso = 1:1:length(expConfig.isometric.lengths)
  %%
  % Ramp recovery to nominal length
  %%
  sequenceTrialCount = sequenceTrialCount+1;
  
  seriesName = sequenceIdStr;
  typeName = 'rampRecovery';
  

  lengthChange =  expConfig.isometric.lengths(idxIso);
  
  trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
               auroraConfig.defaultLengthUnit, dateId,'');  
  
  %
  % Populate the sequence meta data
  %
  sequenceMetaDataFiles.files  = ...
  [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
  sequenceProtocolFiles.files  = ...
  [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
  sequenceDataFiles.files      = ...
  [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
  sequenceDataFiles.sha256 = ...
  [sequenceDataFiles.sha256,{''}];
  
  %
  % Ramp Recovery sine wave
  %
  lengthRampOptions = ...
  getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
   
  lengthRampOptions(1).value = lengthChange;
  lengthRampOptions(2).value = 1;
  
  expConfigTrial = [];
  expConfigTrial = expConfig.recovery;
  
  flag_isASequence=1;
  success = createRampRecoveryTrial610A(...
                    lengthRampOptions,...
                    trialFileNameNoExt,...                                     
                    auroraConfigRecovery,...
                    expConfigTrial,...
                    expFoldersUpd,...
                    flag_isASequence);  
  trialId=trialId + 1;
      
  %%
  % Isometric trial
  %%
  sequenceTrialCount = sequenceTrialCount+1;

  seriesName = sequenceIdStr;
  typeName = 'activeIsometric';
  
  lengthChange = expConfig.isometric.lengths(idxIso);
  
  trialFileNameNoExt  = ...
  getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
               auroraConfig.defaultLengthUnit, dateId,'');
  
  
  sequenceMetaDataFiles.files  = ...
  [sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
  sequenceProtocolFiles.files  = ...
  [sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
  sequenceDataFiles.files      = ...
  [sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
  sequenceDataFiles.sha256 = ...
  [sequenceDataFiles.sha256,{''}];
  
  
  expConfigTrial = [];
  expConfigTrial.waitTime= expConfig.waitTime;
  expConfigTrial.stopWaitTime= expConfig.stopWaitTime;
  expConfigTrial.tetanus = expConfig.tetanus;  
  expConfigTrial.timeToReachMaxActivation=expConfig.timeToReachMaxActivation;
  
  expConfigTrial.ramp.length   = expConfig.isometric.lengths(idxIso);
  expConfigTrial.ramp.duration = duration;
  expConfigTrial.ramp.isActive = isActive;
  expConfigTrial.ramp.holdDuration = 0;


  success = createActiveIsometricTrial610A(...
                      expConfig.isometric.lengths(idxIso),...
                      trialFileNameNoExt,...                                     
                      auroraConfig,...
                      expConfig,...
                      expFoldersUpd,...
                      flag_isASequence);
      
end

%%
% Ramp recovery to nominal length
%%
sequenceTrialCount = sequenceTrialCount+1;

seriesName = sequenceIdStr;
typeName = 'rampRecovery';


lengthChange =  0;

trialFileNameNoExt  = ...
getTrialName(seriesName,sequenceTrialCount,typeName,lengthChange,...
             auroraConfig.defaultLengthUnit, dateId,'');  

%
% Populate the sequence meta data
%
sequenceMetaDataFiles.files  = ...
[sequenceMetaDataFiles.files,{[trialFileNameNoExt,'.json']}];
sequenceProtocolFiles.files  = ...
[sequenceProtocolFiles.files,{[trialFileNameNoExt,'.dpf']}];
sequenceDataFiles.files      = ...
[sequenceDataFiles.files,{[trialFileNameNoExt,'.ddf']}];
sequenceDataFiles.sha256 = ...
[sequenceDataFiles.sha256,{''}];

%
% Ramp Recovery sine wave
%
lengthRampOptions = ...
getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig); 
 
lengthRampOptions(1).value = 0;
lengthRampOptions(2).value = 1;

expConfigTrial = [];
expConfigTrial = expConfig.recovery;

flag_isASequence=1;
success = createRampRecoveryTrial610A(...
                  lengthRampOptions,...
                  trialFileNameNoExt,...                                     
                  auroraConfigRecovery,...
                  expConfigTrial,...
                  expFoldersUpd,...
                  flag_isASequence);  
trialId=trialId + 1;

%%
% Write meta data
%%
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

