function trialId = constructRampImpedanceExperiments610A(...                        
                        dateId,...
                        trialId,...
                        sequenceId,...
                        stochasticWaves,...             
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

sequenceIdStr ='';
assert(~isempty(sequenceId),'Error: sequenceId cannot be empty');
sequenceIdStr = num2str(sequenceId);
if(length(sequenceIdStr)<2)
  sequenceIdStr = ['0',sequenceIdStr];
end


%%
% Set up the experimental folders
%%
rampImpedanceFolderName         = [sequenceIdStr,'_rampImpedance'];

assert(contains(expFolders.sequenceMetaData,'/')==0);
assert(contains(expFolders.sequenceMetaData,'\')==0);
assert(contains(expFolders.protocolFolderName,'/')==0);
assert(contains(expFolders.protocolFolderName,'\')==0);
assert(contains(expFolders.dataFolderName,'/')==0);
assert(contains(expFolders.dataFolderName,'\')==0);

sequenceMetaDataFiles.folder  = ...
  [{expFolders.sequenceMetaData},{rampImpedanceFolderName}];
sequenceProtocolFiles.folder  = ...
  [{expFolders.protocolFolderName},{rampImpedanceFolderName}];
sequenceDataFiles.folder      = ...
  [{expFolders.dataFolderName},{rampImpedanceFolderName}];

rampImpedanceDataDir         = ...
  fullfile(expFolders.dataFolderName,rampImpedanceFolderName); 
rampImpedanceProtocolDir     = ...
  fullfile(expFolders.protocolFolderName,rampImpedanceFolderName); 
rampImpedanceLabelDir        = ...
  fullfile(expFolders.blockLabelsFolderName,rampImpedanceFolderName); 
rampImpedanceMetaDataDir     = ...
  fullfile(expFolders.sequenceMetaData,rampImpedanceFolderName); 

expFolders.dataFolderName         = rampImpedanceDataDir;
expFolders.protocolFolderName     = rampImpedanceProtocolDir;
expFolders.blockLabelsFolderName  = rampImpedanceLabelDir;
expFolders.sequenceMetaData       = rampImpedanceMetaDataDir;

if(~exist(fullfile(expFolders.rootFolderPath,rampImpedanceDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampImpedanceDataDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,rampImpedanceProtocolDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampImpedanceProtocolDir));
end  
if(~exist(fullfile(expFolders.rootFolderPath,rampImpedanceLabelDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampImpedanceLabelDir));
end
if(~exist(fullfile(expFolders.rootFolderPath,rampImpedanceMetaDataDir),'dir'))
  mkdir(fullfile(expFolders.rootFolderPath,rampImpedanceMetaDataDir));
end

%%
% Block of ramp trials
%%

seriesName = '';
idxP=0;
%if(~isempty(trialId))
%  idxP=trialId-1;
%end



for i=1:1:length(expConfig.ramp.length)


  if(isempty(expConfig.stochasticWaves.amplitudeSet))
    
    type = ['ramp_impedance'];

    idxP=idxP+1;
    idxStr = getTrialIndexString(idxP);
    
    endLength   = expConfig.ramp.length(i);

    blockName   = 'RampImpedanceLength';

    fnameNoExt  = getTrialName(sequenceIdStr,idxP,type,endLength,...
                    auroraConfig.defaultLengthUnit, dateId,'');

    expTrialConfig = expConfig;

    expTrialConfig.ramp.length = expConfig.ramp.length(i);      
    flag_isASequence =1;
    success = createRampImpedanceTrial610A(...                    
                    fnameNoExt,...  
                    stochasticWaves,...
                    auroraConfig,...
                    expTrialConfig,...                
                    expFolders,...
                    flag_isASequence);
    sequenceMetaDataFiles.files  = ...
      [sequenceMetaDataFiles.files,{[fnameNoExt,'.json']}];
    sequenceProtocolFiles.files  = ...
      [sequenceProtocolFiles.files,{[fnameNoExt,'.dpf']}];
    sequenceDataFiles.files      = ...
      [sequenceDataFiles.files,{[fnameNoExt,'.ddf']}];
    sequenceDataFiles.sha256 = ...
      [sequenceDataFiles.sha256,{''}];     

    trialId=trialId+1;

    idxP=idxP+1;
    type='sineRamp';
    fnameNoExt  = getTrialName(sequenceIdStr,idxP,type,...
                    expConfig.sineWave.amplitude,...
                    auroraConfig.defaultLengthUnit, dateId,'');    

    success = createRecoveryTrial610A(...
                        fnameNoExt,...                                     
                        auroraConfigRecovery,...
                        expConfig,...
                        expFolders,...
                        flag_isASequence,...
                        flag_printMetaDataToFile);  

    sequenceMetaDataFiles.files  = ...
      [sequenceMetaDataFiles.files,{[fnameNoExt,'.json']}];
    sequenceProtocolFiles.files  = ...
      [sequenceProtocolFiles.files,{[fnameNoExt,'.dpf']}];
    sequenceDataFiles.files      = ...
      [sequenceDataFiles.files,{[fnameNoExt,'.ddf']}];
    sequenceDataFiles.sha256 = ...
      [sequenceDataFiles.sha256,{''}];

    trialId=trialId+1;    
  else

    ampScaleFields = {'overridePassiveAmplitude',...
                      'overrideActiveAmplitude',...
                      'scalePassiveAmplitude',...
                      'scaleActiveAmplitude'};     

    for j=1:1:length(expConfig.stochasticWaves.amplitudeSet)
      idxP=idxP+1;
      idxStr = getTrialIndexString(idxP);
      
      endLength   = expConfig.ramp.length(i);
      ampScale    = expConfig.stochasticWaves.amplitudeSet(j);
  
      ampStr = sprintf('%1.2f',ampScale*100);
      k = strfind(ampStr,'.');
      ampStr(k)='p';
      type = sprintf('%s_%s_amp','ramp_impedance',ampStr);

      fnameNoExt  = getTrialName(sequenceIdStr,idxP,type,endLength,...
                      auroraConfig.defaultLengthUnit, dateId,'');
  
      expTrialConfig = expConfig;
      
      for k=1:1:length(ampScaleFields)
        expTrialConfig.stochasticWaves.(ampScaleFields{k}) = ...
          expConfig.stochasticWaves.(ampScaleFields{k})*ampScale;
      end

      expTrialConfig.ramp.length = expConfig.ramp.length(i);      
      
      flag_isASequence = 1;

      success = createRampImpedanceTrial610A(...                    
                      fnameNoExt,...  
                      stochasticWaves,...
                      auroraConfig,...
                      expTrialConfig,...                
                      expFolders,...
                      flag_isASequence);

      sequenceMetaDataFiles.files  = ...
        [sequenceMetaDataFiles.files,{[fnameNoExt,'.json']}];
      sequenceProtocolFiles.files  = ...
        [sequenceProtocolFiles.files,{[fnameNoExt,'.dpf']}];
      sequenceDataFiles.files      = ...
        [sequenceDataFiles.files,{[fnameNoExt,'.ddf']}];
      sequenceDataFiles.sha256 = ...
        [sequenceDataFiles.sha256,{''}];        

      trialId=trialId+1;
      
      %
      % Recovery sine wave
      %
      idxP=idxP+1;
      type='sineRamp';
      fnameNoExt  = getTrialName(sequenceIdStr,idxP,type,...
                      expConfig.sineWave.amplitude,...
                      auroraConfig.defaultLengthUnit, dateId,'');    
  
      success = createRecoveryTrial610A(...
                          fnameNoExt,...                                     
                          auroraConfigRecovery,...
                          expConfig,...
                          expFolders,...
                          flag_isASequence);   

      sequenceMetaDataFiles.files  = ...
        [sequenceMetaDataFiles.files,{[fnameNoExt,'.json']}];
      sequenceProtocolFiles.files  = ...
        [sequenceProtocolFiles.files,{[fnameNoExt,'.dpf']}];
      sequenceDataFiles.files      = ...
        [sequenceDataFiles.files,{[fnameNoExt,'.ddf']}];
      sequenceDataFiles.sha256 = ...
        [sequenceDataFiles.sha256,{''}];

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
  = expConfig.temperature;
jsonSequenceMetaData.sequence = jsonSequenceSeriesMetaData;


trialFileNameNoExt  = getTrialName(sequenceIdStr,[],'rampImpedance',[],...
                                    '', dateId,'');

fidSeqJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.seq.json']),'w');

jsonMetaDataEncoded = jsonencode(jsonSequenceMetaData);
fprintf(fidSeqJson,jsonMetaDataEncoded);
fclose(fidSeqJson);

trialId = idxP;