function indexEnd = createCalibrationExperiments600A(...
                      indexStart,...
                      seriesName,...
                      settingsCalibration,...
                      stochasticWaveSet,...
                      sinSeries,...
                      writeProtocolHeader,...
                      projectFolders,...
                      auroraConfigWaveSet,...
                      auroraConfigLowRes,...
                      settingsExperiment)

nIsometricTrials = 2;
nPassiveImpedanceTrials = 2;
nActiveImpedanceTrials  = 1;
nRigorImpedanceTrials   = 1;
nFixedImpedanceTrials   = 1;

%%
% Basic input checking
%%

assert(strcmp(auroraConfigWaveSet.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');
assert(strcmp(auroraConfigWaveSet.defaultLengthUnit,'Lo'),...
       'Error: printed length values configured for Lo only.');
assert(strcmp(auroraConfigWaveSet.defaultFrequencyUnit,'Hz'),...
       'Error: printed frequency values configured for Hz only.');


assert(strcmp(auroraConfigWaveSet.defaultTimeUnit,...
              auroraConfigLowRes.defaultTimeUnit),...
  'Error: both auroraConfig structs need the same time units');
assert(strcmp(auroraConfigWaveSet.defaultLengthUnit,...
               auroraConfigLowRes.defaultLengthUnit),...
  'Error: both auroraConfig structs need the same length units');
assert(strcmp(auroraConfigWaveSet.defaultFrequencyUnit,...
               auroraConfigLowRes.defaultFrequencyUnit),...
  'Error: both auroraConfig structs need the same frequency units');



%%
% Setup files
%%

timeFieldName = ['time_',auroraConfigWaveSet.defaultTimeUnit];

bandwidthFieldName = ...
    ['bandwidth_',auroraConfigWaveSet.defaultFrequencyUnit];
amplitudeFieldName = ...
    ['amplitude_',auroraConfigWaveSet.defaultLengthUnit];        


assert(~isempty(seriesName),...
    'Error: series name must have a meaningful keyword in it');

nameMod='';
nameAppend = ['_',seriesName,'_impedance_cal'];

[codeDir, codeProtocolDir, codeWavesDir, codeLabelDir,dateId] = ...
    getTrialDirectories600A(projectFolders,nameAppend,settingsExperiment);

waveDir = fullfile(codeDir,'wave');


trialFileFolderSettings.codeDir        = codeDir;
trialFileFolderSettings.codeWavesDir   = codeWavesDir;
trialFileFolderSettings.codeProtocolDir= codeProtocolDir;
trialFileFolderSettings.codeLabelDir   = codeLabelDir;
trialFileFolderSettings.dateId         = dateId;

fidProtocol = [];

if(writeProtocolHeader==1)
    fidProtocol = fopen(fullfile(codeProtocolDir,...
                          ['protocol_',dateId,'.csv']),'w');
    
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
else
    fidProtocol = fopen(fullfile(codeProtocolDir,...
                          ['protocol_',dateId,'.csv']),'a');
end

assert(length(stochasticWaveSet)==1,...
    'Error: stochasticWaveSet should only have one element');


%%
% Isometric trials
%%


jsonFileNameArray = [];
fileCount=indexStart;


for idxIso=1:1:nIsometricTrials
  blockName='screen';
  startingLength = settingsCalibration.defaultLength;
  startingBathId = auroraConfigLowRes.bath.passive;

  jsonFileNames=createActivePassiveScreeningTrial600A(...    
                  fileCount,...                    
                  seriesName,...
                  blockName,...
                  startingLength,...
                  startingBathId,...
                  fidProtocol,...
                  auroraConfigLowRes,...
                  trialFileFolderSettings,...
                  settingsExperiment);
  jsonFileNameArray = [jsonFileNameArray,jsonFileNames];
  fileCount=fileCount+1;
end

%%
% Impedance trials
%%
zTrialSettingsDefault.useMinimalData    = 1;

zTrialSettingsDefault.start.bathNumber  = nan;
zTrialSettingsDefault.start.length      = nan;
zTrialSettingsDefault.target.bathNumber = nan;
zTrialSettingsDefault.target.length     = nan;
zTrialSettingsDefault.length.isRelative = 0;
zTrialSettingsDefault.length.ratePerSecond = 0.1;
zTrialSettingsDefault.passiveRelaxationTime = 5*60*auroraConfigWaveSet.oneSecond; %5 min.

zTrialSettingsDefault.sineSeries.amplitude = 0.002;
zTrialSettingsDefault.Larb.amplitude    = 0.002;

bwStr = ['',num2str(round(stochasticWaveSet(1).metadata.bandwidth_Hz)),'Hz'];
ampStr= sprintf('%1.3f%s',zTrialSettingsDefault.Larb.amplitude,...
                          auroraConfigWaveSet.defaultLengthUnit);
id=strfind(ampStr,'.');
ampStr(id)='p';

zTrialSettingsDefault.Larb.fileName = ['larb_',dateId,'_',bwStr,'_',ampStr];
zTrialSettingsDefault.Larb.id = nan;
zTrialSettingsDefault.Larb.writeFile=0;

stepSeries.steps  = [-0.12,0.12,0.12,-0.12];
stepSeries.isRelative=1;


for idxZ = 1:1:6

  zTrialSettings=zTrialSettingsDefault;
  switch idxZ
    case 1
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.passive;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.passive;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.4;

      zTrialSettings.Larb.id=1;
      zTrialSettings.Larb.writeFile = 1;
      blockName='zPassive';

    case 2
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.passive;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.passive;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.5;

      zTrialSettings.Larb.id=2;
      zTrialSettings.Larb.writeFile = 1;
      blockName='zPassive';

    case 3
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.passive;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.passive;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.6;

      zTrialSettings.Larb.id=3;
      zTrialSettings.Larb.writeFile = 1;
      blockName='zPassive';

    case 4
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.passive;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.active;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.0;

      zTrialSettings.Larb.id=4;
      zTrialSettings.Larb.writeFile = 1;
      blockName='zActive';

    case 5
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.rigor;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.rigor;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.0;

      zTrialSettings.Larb.id=4;
      zTrialSettings.Larb.writeFile = 0;
      blockName='zRigor';

    case 6
      zTrialSettings.start.bathNumber  = auroraConfigWaveSet.bath.Karnovsky;
      zTrialSettings.target.bathNumber = auroraConfigWaveSet.bath.Karnovsky;
      zTrialSettings.start.length = 1.0;
      zTrialSettings.target.length= 1.0;

      zTrialSettings.Larb.id=4;
      zTrialSettings.Larb.writeFile = 0;
      blockName='zKarnovsky';
    otherwise 
        assert(0,'Error: exceeded the number of impedance cases');
  end

  lenStr= sprintf('%1.2f%s',zTrialSettings.target.length,...
                            auroraConfigWaveSet.defaultLengthUnit);
  id=strfind(lenStr,'.');
  lenStr(id)='p';

  idStr = num2str(zTrialSettings.Larb.id);

  zTrialSettings.Larb.fileName = ...
    [zTrialSettings.Larb.fileName,'_',lenStr,'_',idStr,'.dat'];

  jsonFileNames = createImpedanceCalibrationTrial600A(...    
                                fileCount,...                    
                                seriesName,...
                                blockName,...
                                stochasticWaveSet,...
                                sinSeries,...
                                stepSeries,...
                                zTrialSettings,...
                                fidProtocol,... 
                                auroraConfigWaveSet,...
                                trialFileFolderSettings,...
                                settingsExperiment);
  jsonFileNameArray = [jsonFileNameArray,jsonFileNames];
  fileCount=fileCount+1; 
end



%%
% Write the experiment-level meta data files
%%
fclose(fidProtocol);


protocolMetaData.trials = jsonFileNameArray;

protocolMetaData.experiment.date = 'YYYY/MM/DD';
protocolMetaData.experiment.location = 'University of Stuttgart';
protocolMetaData.experiment.experimenter='Sven Weidner';
protocolMetaData.experiment.apparatus = 'Aurora 1400A';
protocolMetaData.experiment.specimen = 'animal-muscle-name';
protocolMetaData.experiment.temperature_C = nan;
protocolMetaData.experiment.temperatureControl = nan;
protocolMetaData.experiment.length_mm = nan;
protocolMetaData.experiment.width_mm = nan;
protocolMetaData.experiment.height_mm = nan;
protocolMetaData.experiment.maximum_isometric_stress_kPa = nan;
protocolMetaData.experiment.comment = nan;

protocolMetaData.funding.agency = 'Deutsche Forschungsgemeinschaft';
protocolMetaData.funding.number = {'540349998','405834662'};
protocolMetaData.funding.authors = 'Matthew Millard, André Tomalka';
protocolMetaData.funding.institution = 'Institute of Sport and Movement Science, University of Stuttgart, Stuttgart, Germany';

protocolMetaData.ethics.board = 'Regierungspräsidium Stuttgart, Referat 35';
protocolMetaData.ethics.number = 'RPS35-9185-99/411';
protocolMetaData.ethics.dates = 'January 1, 2024 to December 31, 2028';

jsonProtocolMetaData = jsonencode(protocolMetaData);

if(~isempty(settingsExperiment))
    fnameJsonProtocol = fullfile(codeDir,[settingsExperiment.folderName,'.json']);
else
    fnameJsonProtocol = fullfile(codeDir,...
        [dateId,'_',seriesName,'_impedance','_600A.json']);
end
fidJsonProtocol = fopen(fnameJsonProtocol,'w');
fprintf(fidJsonProtocol,jsonProtocolMetaData);
fclose(fidJsonProtocol);

indexEnd=indexStart+fileCount;



