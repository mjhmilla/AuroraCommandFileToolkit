function trialId = createPlateauSearchTrial610A(...
                      trialFileNameNoExt,...
                      dateId,...
                      trialId,...
                      sequenceId,...
                      auroraConfig,...
                      expConfig,...   
                      expFolders,...
                      projectFolders,...
                      flag_isASequence)

success = 0;

%fprintf('\ncreatePlateauSearchTrail610A');
%fprintf('\n Update writeControlFunction command to return the meta-data struct');
%fprintf('\n Append this struct into the array (perhaps write a function for this)');
%fprintf('\n Write a function to create the meta data struct');

%%
% Create the file name
%%
if(isempty(trialFileNameNoExt))
  sequenceIdStr = '';
  assert(~isempty(sequenceId),'Error: sequenceId cannot be empty');
  
  if(~isempty(sequenceId))
    sequenceIdStr = num2str(sequenceId);
    if(length(sequenceIdStr)<2)
      sequenceIdStr = ['0',sequenceIdStr];
    end
  
  
  end


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
  
  seriesName = sequenceIdStr;
  idxP = trialId;
  if(~isempty(sequenceIdStr))
    idxP = 0;
  end
  
  trialFileNameNoExt  = getTrialName(seriesName,idxP,type,[],...
                  auroraConfig.twitch.defaultLengthUnit, dateId,'');
end

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
programMetaData = writePreamble610A(fid,auroraConfig.twitch,programMetaData);



%%
% Get the command options
%%
lengthSineOptions = getCommandFunctionOptions610A(...
                      'Sine Wave','Length Out',auroraConfig.twitch);
lengthSineOptions(1).value = expConfig.relax.frequency;
lengthSineOptions(2).value = expConfig.relax.amplitude;
lengthSineOptions(3).value = expConfig.relax.cycles;

lengthRampOptions = ...
  getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig.twitch);

stimulusTwitchOptions = ...
  getCommandFunctionOptions610A('Stimulus-Twitch','Stimulator',auroraConfig.twitch);
  

%%
% Create the trial
%%

flag_printMetaDataToFile = 1;
numberOfSegments = length(expConfig.ramp.lengths)*2+1;
segmentMetaDataArray(numberOfSegments) = ...
  struct('type','',auroraConfig.twitch.labels.time,[],'meta_data',[]);
idxSeg=0;

previousLength = 0;
for idxL = 1:1:length(expConfig.ramp.lengths)

  %%
  %Ramp
  %%
  if(idxL > 1)
    previousLength = expConfig.ramp.lengths(idxL-1);
  end

  lengthChange = expConfig.ramp.lengths(idxL)-previousLength;
  rampDuration  = abs(lengthChange) ...
                  /expConfig.positioning.rampSpeedInMMPS;
  rampDuration  =max(rampDuration, expConfig.ramp.duration);

  lengthRampOptions(1).value = expConfig.ramp.lengths(idxL); 
  lengthRampOptions(2).value = rampDuration;

  %Write the ramp
  isActive=0;
  [programMetaData, fcnMetaDataUpd] ...
      = writeControlFunction610AUpd(...
              fid,...
              isActive,...
              expConfig.ramp.waitTime,...
              'Ramp',...
              lengthRampOptions,...              
              auroraConfig.twitch,...
              programMetaData,...
              flag_printMetaDataToFile);



  idxSeg=idxSeg+1;
  segmentMetaDataArray(idxSeg)=fcnMetaDataUpd;

  %%
  %Sine Wave
  %%

%   isActive=0;
%   [programMetaData, fcnMetaDataUpd] ...
%       = writeControlFunction610AUpd(...
%               fid,...
%               isActive,...
%               expConfig.relax.waitTime,...
%               'Sine Wave',...
%               lengthSineOptions,...              
%               auroraConfig.twitch,...
%               programMetaData,...
%               flag_printMetaDataToFile);
% 
% 
%   idxSeg=idxSeg+1;
%   segmentMetaDataArray(idxSeg)=fcnMetaDataUpd;
  
  %%
  %Twitch
  %%

  stimulusTwitchOptions(1).value = expConfig.twitch.initialDelay;
  stimulusTwitchOptions(2).value = expConfig.twitch.pulseWidth;

  isActive=0;
  [programMetaData, fcnMetaDataUpd] ...
      = writeControlFunction610AUpd(...
              fid,...
              isActive,...
              expConfig.positioning.recoveryWaitTime,...
              'Stimulus-Twitch',...
              stimulusTwitchOptions,...              
              auroraConfig.twitch,...
              programMetaData,...
              flag_printMetaDataToFile);


  idxSeg=idxSeg+1;
  segmentMetaDataArray(idxSeg)=fcnMetaDataUpd;
  
end

%%
% Bring the muscle back to its reference length
%%

  lengthChange = expConfig.ramp.lengths(end);
  rampDuration  = abs(lengthChange) ...
                  /expConfig.positioning.rampSpeedInMMPS;
  rampDuration  =max(rampDuration, expConfig.ramp.duration);

lengthRampOptions(1).value = 0; 
lengthRampOptions(2).value = rampDuration;

isActive=0;
[programMetaData, fcnMetaDataUpd] ...
    = writeControlFunction610AUpd(...
            fid,...
            isActive,...
            expConfig.ramp.waitTime,...
            'Ramp',...
            lengthRampOptions,...              
            auroraConfig.twitch,...
            programMetaData,...
            flag_printMetaDataToFile);


idxSeg=idxSeg+1;
segmentMetaDataArray(idxSeg)=fcnMetaDataUpd;

%%
% End the program
%%
disableOptions = getCommandFunctionOptions610A('Stop','',auroraConfig);

stopWaitTime=expConfig.timing.stopWaitTime;
stopWaitTime = max(stopWaitTime,expConfig.positioning.recoveryWaitTime);

isActive=0;
[programMetaData, fcnMetaDataUpd] ...
    = writeControlFunction610AUpd(...
            fid,...
            isActive,...
            stopWaitTime,...
            'Stop',...
            disableOptions,...              
            auroraConfig.twitch,...
            programMetaData,...
            flag_printMetaDataToFile);

fclose(fid);
fclose(programMetaData.labelFileHandle);

assert(programMetaData.lineCount < auroraConfig.twitch.maximumNumberOfCommands,...
    'Error: maximumNumberOfCommandsExceeded');

experimentTitle = ...
  sprintf('Plateau Search %1.1f to %1.1f %s',...
          expConfig.ramp.lengths(1), ...
          expConfig.ramp.lengths(end),...
          auroraConfig.twitch.defaultLengthUnit);

experimentTags = {'twitch-plateau-search'};

success = writeMetaDataStructure610A(...
                          segmentMetaDataArray,...
                          expConfig,...
                          experimentTitle,...
                          experimentTags,...
                          trialFileNameNoExt,...
                          expFolders,...                          
                          flag_isASequence);




trialId = trialId+1;




