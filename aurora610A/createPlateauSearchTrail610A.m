function trialId = createPlateauSearchTrail610A(...
                      dateId,...
                      trialId,...
                      auroraConfig,...
                      expConfig,...   
                      expFolders,...
                      projectFolders)

success = 0;

%%
% Set up the folders
%%

if(isempty(expFolders))

  plateauFolderName     = 'plateau';
  dataFolderName        = 'data';
  protocolFolderName    = 'protocols';
  blockLabelsFolderName = 'segmentLabels';

  codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
  if(~exist(codeDir,'dir'))
    mkdir(codeDir);
  end

  plateauDir         = fullfile(codeDir,plateauFolderName); 
  if(~exist(plateauDir,'dir'))
    mkdir(plateauDir);
  end
  
  plateauDataDir         = fullfile(plateauDir,dataFolderName); 
  if(~exist(plateauDataDir,'dir'))
    mkdir(plateauDataDir);
  end
  
  plateauProtocolDir         = fullfile(plateauDir,protocolFolderName); 
  if(~exist(plateauProtocolDir,'dir'))
    mkdir(plateauProtocolDir);
  end
  
  plateauLabelDir         = fullfile(plateauDir,blockLabelsFolderName); 
  if(~exist(plateauLabelDir,'dir'))
    mkdir(plateauLabelDir);
  end
  
  expFolders.rootFolderPath         = plateauDir;
  expFolders.dataFolderName         = dataFolderName;
  expFolders.protocolFolderName     = 'protocols';
  expFolders.blockLabelsFolderName  = 'segmentLabels';
end

%%
% Create the file name
%%

lengthRange = [expConfig.ramp.lengths(1),...
               expConfig.ramp.lengths(end)];

lengthRangeStr = {'',''};

for i=1:1:length(lengthRange)
  lengthRounded  = round(100*lengthRange(i));
  lengthRangeStr{i} = sprintf('%i',lengthRounded);
  lengthRangeStr{i} = strrep(lengthRangeStr{i},'-','m');
  if(abs(lengthRange(i))<1)
    while(length(lengthRangeStr{i})<2)
      lengthRangeStr{i} = ['0',lengthRangeStr{i}];
    end
  end
end

type = ['plateau_search_',lengthRangeStr{1},'_',lengthRangeStr{2}];

seriesName = '';
idxP=0;
if(~isempty(trialId))
  idxP=trialId;
end

trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
                auroraConfig.defaultLengthUnit, dateId,'');

%%
% Set up the files and metadata structures
%%

fid = fopen(fullfile(expFolders.rootFolderPath,...
                     expFolders.protocolFolderName,...
                     [trialFileNameNoExt,'.dpf']),'w');

trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                  expFolders.blockLabelsFolderName,...
                                  [trialFileNameNoExt,'.csv']);

programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);

jsonMetaData = struct('data',[],'protocol',[],...
                      'segments',[],'experiment',[]);

jsonMetaData.data.file = {expFolders.dataFolderName, ...
                          [trialFileNameNoExt,'.ddf']};
jsonMetaData.data.sha256 = "";

jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
                              [trialFileNameNoExt,'.dpf']};
jsonMetaData.protocol.sha256 = "";


mdFieldNames = getMetaDataFieldNames610A(auroraConfig);

timeFieldName = mdFieldNames.time;
cyclesFieldName =mdFieldNames.cycles;
frequencyFieldName = mdFieldNames.frequency;
amplitudeFieldName = mdFieldNames.amplitude; 
lengthFieldName    = mdFieldNames.length;

initialDelayFieldName = mdFieldNames.initialDelay;
pulseWidthFieldName   = mdFieldNames.pulseWidth;


numberOfSegments = length(expConfig.ramp.lengths)*3+1;
segmentMetaDataArray(numberOfSegments) = ...
    struct('type','',timeFieldName,[0,0],'meta_data',[]);


idxSeg =0;
for i=1:1:length(expConfig.ramp.lengths)
  % Ramp metadata structure
  idxSeg =idxSeg + 1;
  segmentMetaDataArray(idxSeg).type = 'Ramp';
  segmentMetaDataArray(idxSeg).(timeFieldName) = [0,0];
  segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
  segmentMetaDataArray(idxSeg).meta_data.channel='';
  segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)=[];
  segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)=[];

  % Sine Wave metadata structure
  idxSeg = idxSeg + 1;
  segmentMetaDataArray(idxSeg).type = 'Ramp';
  segmentMetaDataArray(idxSeg).(timeFieldName) = [0,0];
  segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
  segmentMetaDataArray(idxSeg).meta_data.channel='';
  segmentMetaDataArray(idxSeg).meta_data.(frequencyFieldName)=[];
  segmentMetaDataArray(idxSeg).meta_data.(amplitudeFieldName)=[];
  segmentMetaDataArray(idxSeg).meta_data.(cyclesFieldName)=[];
  
  %Twitch structure
  idxSeg = idxSeg + 1;
  segmentMetaDataArray(idxSeg).type = 'Stimulus-Twitch';
  segmentMetaDataArray(idxSeg).(timeFieldName) = [0,0];
  segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
  segmentMetaDataArray(idxSeg).meta_data.channel='';
  segmentMetaDataArray(idxSeg).meta_data.(initialDelayFieldName)=[];
  segmentMetaDataArray(idxSeg).meta_data.(pulseWidthFieldName)=[];

end

%Return to the reference length
idxSeg =idxSeg + 1;
segmentMetaDataArray(idxSeg).type = 'Ramp';
segmentMetaDataArray(idxSeg).(timeFieldName) = [0,0];
segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
segmentMetaDataArray(idxSeg).meta_data.channel='';
segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)=[];
segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)=[];

%%
% Get the command options
%%
lengthSineOptions = getCommandFunctionOptions610A(...
                      'Sine Wave','Length Out',auroraConfig);
lengthSineOptions(1).value = expConfig.sineWave.frequency;
lengthSineOptions(2).value = expConfig.sineWave.amplitude;
lengthSineOptions(3).value = expConfig.sineWave.cycles;

lengthRampOptions = ...
  getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

stimulusTwitchOptions = ...
  getCommandFunctionOptions610A('Stimulus-Twitch','Stimulator',auroraConfig);
  

%%
% Create the trial
%%

idxSeg = 0;
flag_printMetaDataToFile = 1;
for idxL = 1:1:length(expConfig.ramp.lengths)

  %%
  %Ramp
  %%

  lengthRampOptions(1).value = expConfig.ramp.lengths(idxL); 
  lengthRampOptions(2).value = expConfig.ramp.duration;

  %Record the meta data
  idxSeg=idxSeg+1;

  startTime = programMetaData.nextStartTime ...
            + expConfig.ramp.waitTime;
  endTime = startTime+expConfig.ramp.duration;

  segmentMetaDataArray(idxSeg).type = ...
      'Ramp';                
  segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];  

  segmentMetaDataArray(idxSeg).meta_data.is_active          ...
    = 0;
  segmentMetaDataArray(idxSeg).meta_data.channel            ...
    = lengthRampOptions(1).port;
  segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)  ...
    =lengthRampOptions(2).value;
  segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)    ...
    =lengthRampOptions(2).value;

  %Write the ramp
  programMetaData ...
      = writeControlFunction610A(...
              fid,...
              expConfig.ramp.waitTime,...
              'Ramp',...
              lengthRampOptions,...
              auroraConfig,...
              programMetaData,...
              flag_printMetaDataToFile);

  endTimeError = endTime - programMetaData.controlFunction.endTime;
  assert(abs(endTimeError)<1e-3,...
      'Error: end time differs from the meta data');

  %%
  %Sine Wave
  %%

  %Record the meta data
  sineTime = (expConfig.sineWave.cycles ...
             /expConfig.sineWave.frequency);

  idxSeg=idxSeg+1;  
  
  startTime = programMetaData.nextStartTime ...
             +expConfig.sineWave.waitTime;
  endTime = startTime + sineTime;

  segmentMetaDataArray(idxSeg).(timeFieldName) =  [startTime,endTime];   
  segmentMetaDataArray(idxSeg).type = ['Sine Wave'];
  segmentMetaDataArray(idxSeg).meta_data.is_active = 0;
  
  segmentMetaDataArray(idxSeg).meta_data.channel            ...
      = lengthSineOptions(1).port;
  segmentMetaDataArray(idxSeg).meta_data.(frequencyFieldName) = ...
    lengthSineOptions(1).value;
  segmentMetaDataArray(idxSeg).meta_data.(amplitudeFieldName) = ...
    lengthSineOptions(2).value;    
  segmentMetaDataArray(idxSeg).meta_data.(cyclesFieldName) = ...
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
  
  %%
  %Twitch
  %%

  stimulusTwitchOptions(1).value = expConfig.twitch.initialDelayS;
  stimulusTwitchOptions(2).value = expConfig.twitch.pulseWidthMS;

  s2ms = 0.001;

  idxSeg = idxSeg + 1;
  segmentMetaDataArray(idxSeg).type = 'Stimulus-Twitch';

  startTime = programMetaData.nextStartTime ...
          +expConfig.twitch.waitTime ...
          +expConfig.twitch.initialDelayS;
  endTime = startTime + expConfig.twitch.pulseWidthMS*s2ms;

  segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime]; 
  segmentMetaDataArray(idxSeg).meta_data.is_active = 1;
  segmentMetaDataArray(idxSeg).meta_data.channel= ...
      stimulusTwitchOptions(1).port;
  segmentMetaDataArray(idxSeg).meta_data.(initialDelayFieldName)=...
      expConfig.twitch.initialDelayS;
  segmentMetaDataArray(idxSeg).meta_data.(pulseWidthFieldName)=...
      expConfig.twitch.pulseWidthMS;

  %Write the twitch
  programMetaData = writeControlFunction610A(...
                      fid,...
                      expConfig.twitch.waitTime,...
                      'Stimulus-Twitch',...
                      stimulusTwitchOptions,...
                      auroraConfig,...                
                      programMetaData,...
                      flag_printMetaDataToFile); 

  endTimeError = endTime - programMetaData.controlFunction.endTime;
  assert(abs(endTimeError)<1e-3,...
      'Error: end time differs from the meta data');
  
end

%%
% Bring the muscle back to its reference length
%%

lengthRampOptions(1).value = 0; 
lengthRampOptions(2).value = expConfig.ramp.duration;

%Record the meta data
idxSeg=idxSeg+1;

startTime = programMetaData.nextStartTime ...
          + expConfig.ramp.waitTime;
endTime = startTime+expConfig.ramp.duration;

segmentMetaDataArray(idxSeg).type = ...
    'Ramp';                
segmentMetaDataArray(idxSeg).(timeFieldName) = [startTime,endTime];  

segmentMetaDataArray(idxSeg).meta_data.is_active          ...
  = 0;
segmentMetaDataArray(idxSeg).meta_data.channel            ...
  = lengthRampOptions(1).port;
segmentMetaDataArray(idxSeg).meta_data.(lengthFieldName)  ...
  =lengthRampOptions(2).value;
segmentMetaDataArray(idxSeg).meta_data.(timeFieldName)    ...
  =lengthRampOptions(2).value;

%Write the ramp
programMetaData ...
    = writeControlFunction610A(...
            fid,...
            expConfig.ramp.waitTime,...
            'Ramp',...
            lengthRampOptions,...
            auroraConfig,...
            programMetaData,...
            flag_printMetaDataToFile);

endTimeError = endTime - programMetaData.controlFunction.endTime;
assert(abs(endTimeError)<1e-3,...
    'Error: end time differs from the meta data');

%%
% End the program
%%
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
  sprintf('Plateau Search %1.1f to %1.1f %s',...
          expConfig.ramp.lengths(1), ...
          expConfig.ramp.lengths(end),...
          auroraConfig.defaultLengthUnit);
jsonMetaData.experiment.tags = {'twitch-plateau-search'};

jsonMetaDataEncoded = jsonencode(jsonMetaData);
fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                         [trialFileNameNoExt,'.json']),'w');
fprintf(fidJson,jsonMetaDataEncoded);
fclose(fidJson);

fclose(fid);
fclose(programMetaData.labelFileHandle);


trialId = trialId+1;


