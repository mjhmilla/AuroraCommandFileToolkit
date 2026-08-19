function indexEnd = createCalibrationExperiments600A(...
                      indexStart,...
                      seriesName,...
                      settingsCalibration,...
                      stochasticWaveSet,...
                      sinSeries,...
                      writeProtocolHeader,...
                      projectFolders,...
                      auroraConfigInput,...
                      settingsExperiment)


nIsometricTrials = 2;
nPassiveImpedanceTrials = 2;
nActiveImpedanceTrials  = 1;
nRigorImpedanceTrials   = 1;
nFixedImpedanceTrials   = 1;



%%
% Setup files
%%
timeFieldName = ['time_',auroraConfigInput.defaultTimeUnit];
bandwidthFieldName = ['bandwidth_',auroraConfigInput.defaultFrequencyUnit];
amplitudeFieldName = ['amplitude_',auroraConfigInput.defaultLengthUnit];        


assert(~isempty(seriesName),...
    'Error: series name must have a meaningful keyword in it');

nameMod='';
nameAppend = ['_',seriesName,'_impedance_cal'];

[codeDir, codeProtocolDir, codeLabelDir,dateId] = ...
    getTrialDirectories2026(projectFolders,nameAppend,settingsExperiment);

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
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfigInput.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');
assert(strcmp(auroraConfigInput.defaultLengthUnit,'Lo'),...
       'Error: printed length values configured for Lo only.');
assert(strcmp(auroraConfigInput.defaultFrequencyUnit,'Hz'),...
       'Error: printed frequency values configured for Hz only.');

%%
% Experiment configuration
%%

scaleTime=1;
switch auroraConfigInput.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end


auroraConfigIso=auroraConfigInput;
auroraConfigIso.useRelativeUnits=0;
auroraConfigIso.analogToDigitalSampleRateHz=100;

auroraConfigZ  = auroraConfigInput;

%%
% Isometric trials
%%
auroraConfig = auroraConfigIso;

jsonProtocolTrialArray = cell(nIsometricTrials,1);
fileCount=indexStart;

for idxIso=1:1:nIsometricTrials
  blockName='active';

  if(~isempty(settingsExperiment))
      idx = settingsExperiment.trialOrder(fileCount);
      idxStr = getTrialIndexString(idx);        
  else
      idx=fileCount;
      idxStr = getTrialIndexString(idx);
  end
      
  startLength = settingsCalibration.defaultLength;
  takePhoto   = '';
  fname       = getTrialName(seriesName,idx,blockName,startLength,...
                  auroraConfig.defaultLengthUnit,dateId,'.pro');
  fnameOutput = getTrialName(seriesName,idx,blockName,startLength,...
                  auroraConfig.defaultLengthUnit,dateId,'.dat');
  fnameMetaData = getTrialName(seriesName,idx,blockName,startLength,...
                  auroraConfig.defaultLengthUnit,dateId,'.json');
  fnameLabels = getTrialName(seriesName,idx,blockName,startLength,...
                  auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
  larbFileName = getTrialName(seriesName,idx,blockName,startLength,...
                  auroraConfig.defaultLengthUnit,[dateId,'_larb'],'.dat');
  
  jsonProtocolTrialArray(idx) = {fnameMetaData};

  jsonMetaData = struct('data',[],'protocol',[],...
                        'segments',[],'experiment',[]);

  jsonMetaData.data.file = {'data',fnameOutput};
  if(~isempty(settingsExperiment))
      measurementFolder=settingsExperiment.dataPathSha256;
      [status,cmdout] =  system(['sha256sum ',fullfile(measurementFolder,fnameOutput)]);
      i0 = strfind(cmdout,' ');        
      i0=i0-1;
      sha256Sum = cmdout;
      sha256Sum = sha256Sum(1,1:i0);            
      jsonMetaData.data.sha256 = sha256Sum;
  else
      jsonMetaData.data.sha256 = 'MANUALLY_UPDATE_AFTER_EXPERIMENT';
  end
  jsonMetaData.protocol.file = {'protocols',fname};
  fprintf(fidProtocol,'%s,%s,%1.2f,%s,%s,%s,%s\n',...
      idxStr,seriesName,startLength,takePhoto, blockName,fname,...
      ['Load arb wave 1 with: ',larbFileName]);

  fid = fopen(fullfile(codeProtocolDir,fname),'w');
  fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');
  
  if(exist('segmentMetaDataArray','var'))
    clear('segmentMetaDataArray');
  end

  segmentMetaDataArray(1) = ...
      struct('type','','duration',[0,0],'meta_data',[]);


  %%
  % 0. Write the preamble
  %%
  
  lineCount=0;
  [startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);

  %%
  % 1. Activate 
  %%
    [endTime, lineCount] = ...
        writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
    
    endActivation = endTime + auroraConfig.bath.activationDuration;
    
    fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
    fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
    
    startTime = endActivation;
    lineCount = lineCount+1;

  %%
  % 2. SL Trigger 
  %%
    slTriggerOptions = getCommandFunctionOptions600A('SL-Trigger',auroraConfig);
    slTriggerOptions(1).value=10;
    nextStartTime = writeControlFunction600A(fid,...
                      startTime,auroraConfig.defaultTimeUnit,...
                      'SL-Trigger',slTriggerOptions,auroraConfig);    

    endTime = nextStartTime + auroraConfig.bath.activationDuration;
    lineCount = lineCount+1;

    idxSeg=1;
    startTriggerTime = startTime+slTriggerOptions(1).value;
    endTriggerTime = startTriggerTime...
                    +settingsCalibration.defaultSLTriggerWaitTimeS*scaleTime;
    isActive=1;
    segmentMetaDataArray(idxSeg).type='SL-Trigger';
    segmentMetaDataArray(idxSeg).(timeFieldName) = [startTriggerTime,endTriggerTime];
    segmentMetaDataArray(idxSeg).meta_data.is_active = isActive;


  %%
  % 3. Deactivate 
  %%
    startTime=endTriggerTime;
    [endTime, lineCount] = ...
        writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);
    
    startTime=endTime+auroraConfig.minimumWaitTime;            

  %%
  % 4. Stop
  %%
  [endTime, lineCount] = ...
  writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);

  success = 1;
  assert(lineCount < auroraConfig.maximumNumberOfCommands,...
      'Error: maximumNumberOfCommandsExceeded');
  
  fileCount = fileCount+1;  

  %%
  % Write the meta data
  %%
  jsonMetaData.segments = segmentMetaDataArray;   
  jsonMetaData.experiment.title = '';
  
  jsonMetaDataEncoded = jsonencode(jsonMetaData);
  fidJson = fopen(fullfile(codeDir,fnameMetaData),'w');
  fprintf(fidJson,jsonMetaDataEncoded);        
  fclose(fidJson);
  
  fclose(fid);
  fclose(fidLabel);    
  
end

%%
% Write the experiment-level meta data files
%%
fclose(fidProtocol);


protocolMetaData.trials = jsonProtocolTrialArray;

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

indexEnd = idx;

