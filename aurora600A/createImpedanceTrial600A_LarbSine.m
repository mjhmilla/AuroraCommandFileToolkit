function jsonFileNameArray = createImpedanceTrial600A_LarbSine(...    
                                fileCount,...                    
                                seriesName,...
                                blockName,...
                                stochasticWaveSet,...
                                sineSeries,...
                                stepSeries,...
                                zTrialSettings,...
                                fidProtocol,... 
                                auroraConfig,...
                                trialFileFolderSettings,...
                                settingsExperiment)
%
% Check the units
%
  assert(strcmp(auroraConfig.defaultLengthUnit,'Lo'),... 
         'Error: auroraConfig.defaultLengthUnit assumed to be Lo');

  assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),... 
         'Error: auroraConfig.defaultTimeUnit assumed to be ms');

  assert(strcmp(auroraConfig.defaultFrequencyUnit,'Hz'),... 
         'Error: auroraConfig.defaultFrequencyUnit assumed to be Hz');

  assert(length(stochasticWaveSet)==1,...
      'Error: stochasticWaveSet should only have one element');

  assert(zTrialSettings.length.isRelative==0,...
        ['Error: this script will only correctly',...
         ' handle absolute length changes']);
  s2ms=1000;

  flag_mergedStochasticWaveSet=0;
  numberOfStochasticWaves=1;
  if(length(stochasticWaveSet.metadata.(auroraConfig.labels.bandwidth))==1)
    flag_mergedStochasticWaveSet=0;
    numberOfStochasticWaves=1;
  else
    flag_mergedStochasticWaveSet=1;
    numberOfStochasticWaves = length(stochasticWaveSet.metadata.(auroraConfig.labels.bandwidth));
  end

%
% Check the trial configuration
  %
  trialType = '';
  trialTitle = '';
  commentStr='';
  lengthStr = sprintf('(%1.2f %s)',zTrialSettings.target.length,....
                                 auroraConfig.defaultLengthUnit);

  if(zTrialSettings.start.bathNumber ~= zTrialSettings.target.bathNumber)
    assert( zTrialSettings.start.bathNumber == auroraConfig.bath.passive ...
         && zTrialSettings.target.bathNumber == auroraConfig.bath.active);
    trialType='active';
    trialTitle=['Active Impedance ',lengthStr,': Step/Larb/Sine'];
    commentStr=['Active impedance measurement at ',lengthStr];
  else
    switch zTrialSettings.start.bathNumber
      case auroraConfig.bath.passive
          trialType='passive';
          trialTitle=['Passive Impedance' ,lengthStr,': Step/Larb/Sine'];
          commentStr=['Passive impedance measurement at ',lengthStr];
      case auroraConfig.bath.rigor
          trialType='rigor';
          trialTitle=['Rigor Impedance ',lengthStr,': Step/Larb/Sine'];
          commentStr=['Rigor impedance measurement at ',lengthStr];
      case auroraConfig.bath.Karnovsky
          trialType='Karnovsky';      
          trialTitle=['Karnovsky Impedance ',lengthStr,': Step/Larb/Sine'];
          commentStr=['Karnovsky impedance measurement at ',lengthStr];
      otherwise
        assert(0,'Error: invalid combination of starting and target baths');
    end
  end

%
% Setup the files
%

  if(~isempty(settingsExperiment))
      idx = settingsExperiment.trialOrder(fileCount);
      idxStr = getTrialIndexString(idx);        
  else
      idx=fileCount;
      idxStr = getTrialIndexString(idx);
  end

  codeDir         = trialFileFolderSettings.codeDir;
  codeWavesDir    = trialFileFolderSettings.codeWavesDir;
  codeProtocolDir = trialFileFolderSettings.codeProtocolDir;
  codeLabelDir    = trialFileFolderSettings.codeLabelDir;
  dateId          = trialFileFolderSettings.dateId;

  startBathName= auroraConfig.labels.bathNames{zTrialSettings.start.bathNumber};
  startLength  = zTrialSettings.start.length;
  targetLength = zTrialSettings.target.length;
  
  lengthUnit   = auroraConfig.defaultLengthUnit;

  takePhoto   = '';
  fname       = getTrialName600A_startEndLength(seriesName,idx,blockName,...
                  startBathName,startLength,targetLength,...
                  lengthUnit,dateId,'.pro');
  fnameOutput = getTrialName600A_startEndLength(seriesName,idx,blockName,...
                  startBathName,startLength,targetLength,...
                  lengthUnit,dateId,'.dat');
  fnameMetaData = getTrialName600A_startEndLength(seriesName,idx,blockName,...
                  startBathName,startLength,targetLength,...
                  lengthUnit,dateId,'.json');
  fnameLabels = getTrialName600A_startEndLength(seriesName,idx,blockName,...
                  startBathName,startLength,targetLength,...
                  lengthUnit,[dateId,'_labels'],'.csv');

  larbFileName = zTrialSettings.Larb.fileName;

  if(isfield(zTrialSettings.Larb,'useProtocolFileName'))
    if(zTrialSettings.Larb.useProtocolFileName==1)
      larbFileName=fname;
      idxP=strfind(larbFileName,'.pro');
      larbFileName=larbFileName(1,1:idxP);
      larbFileName=[larbFileName,'csv'];
      zTrialSettings.Larb.fileName=['wave',{larbFileName}];
    end
  end

  %
  % Write the larb file if needed
  %
  if(zTrialSettings.Larb.writeFile)
    larbData= stochasticWaveSet.fileData;

    if(zTrialSettings.Larb.scaleAmplitude==1)
      assert(abs(stochasticWaveSet.metadata.amplitude_Lo-1)<1e-6,...
             ['Error: the stochastic wave should have an amplitude of 1',...
               ' so that it can be easily transformed to the desired signal']);
      avgVal = mean(larbData);
      assert(abs(avgVal)<1e-6,...
         ['Error: the average value of the stochastic wave ',...
          'should be close to zero']);
  
      larbData = larbData .* zTrialSettings.Larb.amplitude;
    end

    larbData = larbData + zTrialSettings.target.length;

    filePathLarb = fullfile(codeWavesDir,larbFileName);

    fidLarb=fopen(filePathLarb,'w');
    for i=1:1:length(larbData)
      fprintf(fidLarb,'%1.6f\n',larbData(i));
    end
    fclose(fidLarb);

  end

%
% Set up the meta data
%
  programMetaData=getEmptyProgramMetaDataStruct600AUpd(...
                    fullfile(codeLabelDir,fnameLabels),...
                    zTrialSettings.start.bathNumber);

  flag_printMetaDataLabelsToCsv=1; %This will write a list of all of the commands called
                             %along with the times that the commands are called
                             %to the '... _labels.csv' file. This is sometimes 
                             %helpful for debugging purposes.

  jsonFileNameArray = {fnameMetaData};

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
      commentStr);

  fid = fopen(fullfile(codeProtocolDir,fname),'w');
  fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');

%
% 0. Write the preamble
%
  programMetaData = writePreamble600AUpd(fid,auroraConfig,programMetaData);
  segmentMetaDataArray = [];
%
% Enable recording if we're recording everything
%
  if(zTrialSettings.useMinimalData==0)
    startTime=programMetaData.nextStartTime;
    [programMetaData,fcnMetaData] = ...
        dataEnable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
  end

%
% 1. Move the fiber to the starting length (it should already be at)
%    this length
%
  isRelativeOverride= zTrialSettings.length.isRelative;
  lengthRampOptions = getCommandFunctionOptions600AUpd(...
                        'Length-Ramp',auroraConfig,isRelativeOverride);

    lengthRampOptions(1).value = zTrialSettings.start.length;
    lengthRampOptions(2).value = auroraConfig.oneSecond;

    startTime = programMetaData.nextStartTime;

  [programMetaData,fcnMetaData] =  ...
      writeControlFunction600AUpd(...
        fid,startTime,'Length-Ramp',lengthRampOptions,...
          [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

  segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];

%
% 2. Record the fiber as it is lengthened, and then shut off the recording
%
%
% 2a. Data-Enable
%
if(zTrialSettings.useMinimalData==1)
  startTime=programMetaData.nextStartTime;
  [programMetaData,fcnMetaData] = ...
      dataEnable600A(fid,startTime,auroraConfig,programMetaData);
  %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
end

%
% 2b. Lengthen
%

isRelativeOverride=zTrialSettings.length.isRelative;
lengthRampOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Ramp',auroraConfig,isRelativeOverride);

  dLength = abs(zTrialSettings.target.length-zTrialSettings.start.length);
  dLengthTime = dLength/zTrialSettings.length.ratePerSecond;

  lengthRampOptions(1).value = zTrialSettings.target.length;
  lengthRampOptions(2).value = ...
    max(dLengthTime*auroraConfig.oneSecond,...
        auroraConfig.minimumCommandDuration);

  startTime = programMetaData.nextStartTime;
  flag_printMetaDataLabelsToCsv=1;

[programMetaData,fcnMetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Ramp',lengthRampOptions,...
        [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];

%
% 2c. Data-Disable
%
if(zTrialSettings.useMinimalData==1)
  startTime=programMetaData.nextStartTime + auroraConfig.oneSecond;
  [programMetaData,fcnMetaData] = ...
      dataDisable600A(fid,startTime,auroraConfig,programMetaData);
  %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
end

programMetaData.nextStartTime= programMetaData.nextStartTime...
                              + zTrialSettings.passiveRelaxationTime;


%
% 3. If this is an active trial make brief a brief recording:
%      a. Beginning before the move to the active bath to the activation time
%    Then add a delay to make sure the fiber force has stabilized
%
  if(strcmp(trialType,'active'))

    %
    %3a. Move to the pre-activation bath
    %
    bathOptions = getCommandFunctionOptions600A('Bath',auroraConfig);
    bathOptions(1).value = auroraConfig.bath.preActivation;
    bathOptions(2).value = 0;

    startTime = programMetaData.nextStartTime;

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(fid, startTime,'Bath',bathOptions,...
            [], auroraConfig, programMetaData, flag_printMetaDataLabelsToCsv);
    segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];



    %%
    %3b. Move to the activation bath
    %%
    startTime = programMetaData.nextStartTime ...
                + auroraConfig.bath.preActivationDuration;

    %
    % Start recording, if we're using a minimal amount of data.
    %
    dataDisableTime=nan;
    if(zTrialSettings.useMinimalData==1)

      [programMetaData,fcnMetaData] = ...
          dataEnable600A(fid,startTime,auroraConfig,programMetaData);

      %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];

      dataDisableTime = startTime ...
                      + auroraConfig.bath.minimumActivationDuration;
      startTime       = programMetaData.nextStartTime;    
    end

    bathOptions(1).value = auroraConfig.bath.active;
    bathOptions(2).value = 0;

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(fid, startTime,'Bath',bathOptions,...
            [],auroraConfig, programMetaData,flag_printMetaDataLabelsToCsv);

    segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

    assert(dataDisableTime > programMetaData.nextStartTime,...
           ['Error: something went wrong, and Data-Disable cannot be',...
            ' called at the desired time']);

    %
    % 3c. Data-Disable
    %
    if(zTrialSettings.useMinimalData==1)
      startTime=programMetaData.nextStartTime;
      [programMetaData,fcnMetaData] = ...
          dataDisable600A(fid,startTime,auroraConfig,programMetaData);
      %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
    end

    %Wait at least 2 x minimalActivationDuration just to be sure that the
    %force has stablized

    assert(zTrialSettings.activationScaling>=1,...
      'Error: aTrialSettings.activationScaling should be at least 1.');

    programMetaData.nextStartTime= programMetaData.nextStartTime...
       + ((2*auroraConfig.bath.minimumActivationDuration) ...
            *zTrialSettings.activationScaling);

  end

%
% 4. Steps
%
%
% 4a. Data-Enable
%
  if(zTrialSettings.useMinimalData==1)
    startTime=programMetaData.nextStartTime;
    [programMetaData,fcnMetaData] = ...
        dataEnable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
  end
%
% 4b. Execute the step changes
%
  for idxS = 1:1:length(stepSeries.steps)
    lengthStepOptions = ...
      getCommandFunctionOptions600AUpd(...
        'Length-Step',auroraConfig,stepSeries.isRelative);

    lengthStepOptions(1).value = stepSeries.steps(idxS);

    startTime = programMetaData.nextStartTime+auroraConfig.oneSecond;

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(...
          fid,startTime,'Length-Step',lengthStepOptions,...
            [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

    segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

  end
  programMetaData.nextStartTime=programMetaData.nextStartTime...
                               +auroraConfig.oneSecond;
%
% 4c. Data-Disable
%
  if(zTrialSettings.useMinimalData==1)
    startTime=programMetaData.nextStartTime+auroraConfig.oneSecond;
    [programMetaData,fcnMetaData] = ...
        dataDisable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
    programMetaData.nextStartTime=programMetaData.nextStartTime ...
                                 +auroraConfig.oneSecond*2;
  end

%
% 5. Apply the larb signal
%
%
% 5a. Ramp to the desired length
%
isRelativeOverride=zTrialSettings.length.isRelative;
lengthRampOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Ramp',auroraConfig,isRelativeOverride);


  lengthRampOptions(1).value = zTrialSettings.target.length;
  lengthRampOptions(2).value = auroraConfig.oneSecond;

  startTime = programMetaData.nextStartTime;
  flag_printMetaDataLabelsToCsv=1;

[programMetaData,fcnMetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Ramp',lengthRampOptions,...
        [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];

%
% 5b. Data-Enable
%
  if(zTrialSettings.useMinimalData==1)
    startTime=programMetaData.nextStartTime;
    [programMetaData,fcnMetaData] = ...
        dataEnable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
  end
%
% 5b. Write the Larb command, and the Larb file
%
  lengthArbOptions = stochasticWaveSet.options;

  lengthArbOptions(1).value = zTrialSettings.Larb.id;
  lengthArbOptions(1).isRelative=0;
  lengthArbOptions(2).isRelative=0;

  larbFrequency = lengthArbOptions(2).value;
  larbDuration  = length(stochasticWaveSet.fileData)/larbFrequency;

  %Form the external meta data struct and update it.
  externalFileMetaData.duration_s = larbDuration;
  

  externalFileMetaData.meta_data      = stochasticWaveSet.metadata;  
  externalFileMetaData.meta_data.file = zTrialSettings.Larb.fileName;

  if(zTrialSettings.Larb.scaleAmplitude==1)
    for idxLarb=1:1:numberOfStochasticWaves
      externalFileMetaData.meta_data.(auroraConfig.labels.amplitude)(idxLarb)...
                                      = zTrialSettings.Larb.amplitude;
    end
  end

  startTime = programMetaData.nextStartTime;

  [programMetaData,fcnMetaData] =  ...
      writeControlFunction600AUpd(...
        fid,startTime,'Length-Arb',lengthArbOptions,...
          externalFileMetaData,auroraConfig,programMetaData, ...
          flag_printMetaDataLabelsToCsv);

  segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
%
% 5c. Data-Disable
%
  if(zTrialSettings.useMinimalData==1)
    startTime=programMetaData.nextStartTime + auroraConfig.oneSecond;
    [programMetaData,fcnMetaData] = ...
        dataDisable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
    programMetaData.nextStartTime=programMetaData.nextStartTime ...
                                 +auroraConfig.oneSecond*2;
  end

%
% 6. Apply the sine series
%
for idxSine=1:1:length(sineSeries.frequencyHz)
  %
  % 6a. Ramp back to the desired length
  %
  isRelativeOverride=zTrialSettings.length.isRelative;
  lengthRampOptions = getCommandFunctionOptions600AUpd(...
                        'Length-Ramp',auroraConfig,isRelativeOverride);
  
  
    lengthRampOptions(1).value = zTrialSettings.target.length;
    lengthRampOptions(2).value = auroraConfig.oneSecond;
  
    startTime = programMetaData.nextStartTime;
    flag_printMetaDataLabelsToCsv=1;
  
  [programMetaData,fcnMetaData] =  ...
      writeControlFunction600AUpd(...
        fid,startTime,'Length-Ramp',lengthRampOptions,...
          [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);
  
  segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];

  %
  % 6b. Data-Enable
  %
    if(zTrialSettings.useMinimalData==1)
      startTime=programMetaData.nextStartTime+auroraConfig.oneSecond*2;
      [programMetaData,fcnMetaData] = ...
          dataEnable600A(fid,startTime,auroraConfig,programMetaData);
      %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
    end

  %
  % 6c. Sine-Wave
  %
    lengthSineOptions = ...
      getCommandFunctionOptions600AUpd('Length-Sine',auroraConfig,[]);

    lengthSineOptions(1).value = sineSeries.frequencyHz(idxSine);
    lengthSineOptions(2).value = zTrialSettings.sineSeries.amplitude;
    lengthSineOptions(3).value = sineSeries.durationS(idxSine)*s2ms;

    startTime = programMetaData.nextStartTime+auroraConfig.oneSecond;

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(...
          fid,startTime,'Length-Sine',lengthSineOptions,...
            [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

    segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

  %
  % 6d. Data-Disable
  %
    if(zTrialSettings.useMinimalData==1)
      startTime=programMetaData.nextStartTime + auroraConfig.oneSecond;
      [programMetaData,fcnMetaData] = ...
          dataDisable600A(fid,startTime,auroraConfig,programMetaData);
      %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
    end
end


%
% 7. If this was an active trial, return the fiber to the passive bath
%

if(strcmp(trialType,'active'))
  startTime=programMetaData.nextStartTime;

  [programMetaData, fcnMetaData] = ...
      writeDeactivationBlock600AUpd(fid, auroraConfig, programMetaData);

  %segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

end


%
% 8. Move the fiber back to its starting length
%
%
% 8a. Data-Enable
%
if(zTrialSettings.useMinimalData==1)
  startTime=programMetaData.nextStartTime+auroraConfig.oneSecond;
  [programMetaData,fcnMetaData] = ...
      dataEnable600A(fid,startTime,auroraConfig,programMetaData);
  %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
end


isRelativeOverride=zTrialSettings.length.isRelative;
lengthRampOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Ramp',auroraConfig,isRelativeOverride);
  

dLength = abs(zTrialSettings.target.length-zTrialSettings.start.length);
dLengthTime = dLength/zTrialSettings.length.ratePerSecond;

lengthRampOptions(1).value = zTrialSettings.start.length;
lengthRampOptions(2).value = ...
  max(dLengthTime*auroraConfig.oneSecond,...
      auroraConfig.minimumCommandDuration);

startTime = programMetaData.nextStartTime;


[programMetaData,fcnMetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Ramp',lengthRampOptions,...
        [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

%
% 9c. Data-Disable
%
  if(zTrialSettings.useMinimalData==1)
    startTime=programMetaData.nextStartTime + auroraConfig.oneSecond;
    [programMetaData,fcnMetaData] = ...
        dataDisable600A(fid,startTime,auroraConfig,programMetaData);
    %segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];
  end



%%
% 10. Stop
%%
startTime=programMetaData.nextStartTime;            

programMetaData = ...
  writeClosingBlock600AUpd(fid, startTime, auroraConfig, programMetaData);

segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

success = 1;
assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
    'Error: maximumNumberOfCommandsExceeded');



fileCount = fileCount+1;  

%%
% Update and Write the meta data
%%

timingMetaDataArray=getTimingMetaData(programMetaData,auroraConfig);
segmentMetaDataArray=[segmentMetaDataArray,timingMetaDataArray];


jsonMetaData.segments = segmentMetaDataArray;   
jsonMetaData.experiment.title = trialTitle;
jsonMetaData.experiment.keywords = {'Impedance-Length-Arb','Impedance-Length-Sine'};
jsonMetaDataEncoded = jsonencode(jsonMetaData);
fidJson = fopen(fullfile(codeDir,fnameMetaData),'w');
fprintf(fidJson,jsonMetaDataEncoded);        
fclose(fidJson);

fclose(fid);
fclose(fidLabel);    


