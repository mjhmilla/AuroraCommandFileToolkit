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

useMinimalDataRecording=1;

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
  
  programMetaData=getEmptyProgramMetaDataStruct600A(...
                    fullfile(codeLabelDir,fnameLabels));

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
  


  %%
  % 0. Write the preamble
  %%
  enableDataRecording=0;
  [programMetaData, enableSegmentMetaDataArray] = ...
    writePreamble600AUpd(fid,lineCount,auroraConfig,programMetaData,...
                         enableDataRecording);

  %%
  % 1. Activate 
  %%
  [programMetaData, activationSegmentMetaDataArray] = ...
    writeActivationBlock600AUpd(fid, auroraConfig, programMetaData,...
                                useMinimalDataRecording);  

  %%
  % 2. SL Trigger 
  %%
  slTriggerStartTime = programMetaData.nextStartTime ...
                     + auroraConfig.bath.minimumActivationDuration;

  %%
  % Data enable
  %%
  if(programMetaData.dataEnabled==0)
    dataEnableOptions = ...
        getCommandFunctionOptions600A('Data-Enable',auroraConfig);
  
    isActive=1;
    startTime=slTriggerStartTime;

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(...
            fid,...
            isActive,...
            startTime,...
            auroraConfig.defaultTimeUnit,...
            'Data-Enable',...
            dataEnableOptions,...
            [],...
            auroraConfig,...
            programMetaData,...
            0);
    slTriggerStartTime=slTriggerStartTime+programMetaData.nextStartTime;
  end

  %%
  % SL Trigger
  %%

  slTriggerOptions = ...
    getCommandFunctionOptions600A('SL-Trigger',auroraConfig);

  slTriggerOptions(1).value=10;
  
  isActive=1;
  startTime=slTriggerStartTime;

  [programMetaData,slTriggerMetaData] =  ...
      writeControlFunction600AUpd(...
          fid,...
          isActive,...
          startTime,...
          auroraConfig.defaultTimeUnit,...
          'SL-Trigger',...
          slTriggerOptions,...
          [],...
          auroraConfig,...
          programMetaData,...
          1);
  

  if(programMetaData.dataEnabled==1 && useMinimalDataRecording==1)

  end

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
  % Update and Write the meta data
  %%
  if(exist('segmentMetaDataArray','var'))
    clear('segmentMetaDataArray');
  end

  segmentMetaDataArray(1) = ...
      struct('type','','duration',[0,0],'meta_data',[]);

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

