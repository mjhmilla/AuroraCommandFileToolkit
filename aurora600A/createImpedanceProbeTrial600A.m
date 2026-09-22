function jsonFileNameArray = createImpedanceProbeTrial600A(...    
                                fileCount,...                    
                                seriesName,...
                                blockName,...
                                startLength,...
                                startingBathId,...
                                sineProbeAmplitude,...
                                sinProbeSeries,...                                
                                fidProtocol,...
                                auroraConfig,...
                                trialFileFolderSettings,...
                                settingsExperiment,...
                                trialKeyWords)


assert(strcmp(auroraConfig.defaultLengthUnit,'Lo'),... 
       'Error: auroraConfig.defaultLengthUnit assumed to be Lo');

assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),... 
       'Error: auroraConfig.defaultTimeUnit assumed to be ms');
s2ms=1000;

if(~isempty(settingsExperiment))
    idx = settingsExperiment.trialOrder(fileCount);
    idxStr = getTrialIndexString(idx);        
else
    idx=fileCount;
    idxStr = getTrialIndexString(idx);
end

codeDir         = trialFileFolderSettings.codeDir;
codeProtocolDir = trialFileFolderSettings.codeProtocolDir;
codeLabelDir    = trialFileFolderSettings.codeLabelDir;
dateId          = trialFileFolderSettings.dateId;

startBathName= auroraConfig.labels.bathNames{startingBathId};
lengthUnit   = auroraConfig.defaultLengthUnit;
takePhoto   = '';
fname       = getTrialName600A(seriesName,idx,blockName,...
                startBathName,startLength,lengthUnit,dateId,'.pro');
fnameOutput = getTrialName600A(seriesName,idx,blockName,...
                startBathName,startLength,lengthUnit,dateId,'.dat');
fnameMetaData = getTrialName600A(seriesName,idx,blockName,...
                startBathName,startLength,lengthUnit,dateId,'.json');
fnameLabels = getTrialName600A(seriesName,idx,blockName,...
                startBathName,startLength,lengthUnit,[dateId,'_labels'],'.csv');
larbFileName = getTrialName600A(seriesName,idx,blockName,...
                startBathName,startLength,lengthUnit,[dateId,'_larb'],'.dat');


programMetaData=getEmptyProgramMetaDataStruct600AUpd(...
                  fullfile(codeLabelDir,fnameLabels),...
                  auroraConfig.bath.passive);

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
    ['Testing if fiber is viable']);

fid = fopen(fullfile(codeProtocolDir,fname),'w');
fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');




%%
% 0. Write the preamble
%%
programMetaData = writePreamble600AUpd(fid,auroraConfig,programMetaData);


%%
%1. Data-Enable
%%
startTime=programMetaData.nextStartTime;
[programMetaData,fcnMetaData] = ...
    dataEnable600A(fid,startTime,auroraConfig,programMetaData);


%%
%2. Move to desired length
%%
isRelativeOverride=0;
lengthRampOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Ramp',auroraConfig,isRelativeOverride);

lengthRampOptions(1).value = startLength;
lengthRampOptions(2).value = 1*s2ms;

startTime = programMetaData.nextStartTime;
flag_printMetaDataLabelsToCsv=1;

[programMetaData,rampMetaData] =  ...
    writeControlFunction600AUpd(...
      fid,...
      startTime,...
      'Length-Ramp',...
      lengthRampOptions,...
      {},...
       [],...
       auroraConfig,...
       programMetaData, ...
       flag_printMetaDataLabelsToCsv);

segmentMetaDataArray=rampMetaData;

%%
% 3. Activate 
%%
[programMetaData, actSegMetaDataArray]= ...
  writeActivationBlock600AUpd(fid, auroraConfig, programMetaData);  

timeInActivationBath=programMetaData.controlFunction.endTime;

segmentMetaDataArray=[segmentMetaDataArray,actSegMetaDataArray];

%%
% 4. Apply the probe sine series
%%

time100ms=round(auroraConfig.oneSecond*0.100);
time200ms=round(auroraConfig.oneSecond*0.200);
time500ms=round(auroraConfig.oneSecond*0.500);
  
for idxSine=1:1:length(sinProbeSeries.frequencyHz)


  %
  % 4a. Sine-Wave
  %
    lengthSineOptions = ...
      getCommandFunctionOptions600AUpd('Length-Sine',auroraConfig,[]);

    lengthSineOptions(1).value = sinProbeSeries.frequencyHz(idxSine);
    lengthSineOptions(2).value = sineProbeAmplitude;
    lengthSineOptions(3).value = sinProbeSeries.durationS(idxSine)*s2ms;

    if(idxSine==1)
      startTime = programMetaData.nextStartTime  ...
                  +(2*auroraConfig.bath.minimumActivationDuration);
    else
      startTime = programMetaData.nextStartTime + time500ms;
    end

    [programMetaData,fcnMetaData] =  ...
        writeControlFunction600AUpd(...
          fid,...
          startTime,...
          'Length-Sine',...
          lengthSineOptions,...
          {'Impedance-Individual-Length-Sine'},...
          [],...
          auroraConfig,...
          programMetaData, ...
          flag_printMetaDataLabelsToCsv);

    segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];


  %
  % 4b. Ramp back to the desired length
  %
  isRelativeOverride=0;
  lengthRampOptions = getCommandFunctionOptions600AUpd(...
                        'Length-Ramp',auroraConfig,isRelativeOverride);
  


  lengthRampOptions(1).value = startLength;
  lengthRampOptions(2).value = time100ms;
  
  startTime = programMetaData.nextStartTime;
  flag_printMetaDataLabelsToCsv=1;
  
  [programMetaData,fcnMetaData] =  ...
      writeControlFunction600AUpd(...
        fid,...
        startTime,...
        'Length-Ramp',...
        lengthRampOptions,...
        {},...
        [],...
        auroraConfig,...
        programMetaData, ...
        flag_printMetaDataLabelsToCsv);
  
  segmentMetaDataArray = [segmentMetaDataArray, fcnMetaData];  
end


%%
% 5. Deactivate 
%%
startTime =   programMetaData.nextStartTime+time200ms;

[programMetaData, deActMetaData] = ...
    writeDeactivationBlock600AUpd(fid, startTime, auroraConfig, programMetaData);

segmentMetaDataArray=[segmentMetaDataArray,deActMetaData];

%%
% 6. Stop
%%
startTime=programMetaData.nextStartTime;            

programMetaData = ...
  writeClosingBlock600AUpd(fid, startTime, auroraConfig, programMetaData);

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
jsonMetaData.experiment.title = sprintf('Isometric (%1.2f Lo)',startLength);
jsonMetaData.experiment.keywords=trialKeyWords;

jsonMetaDataEncoded = jsonencode(jsonMetaData);
fidJson = fopen(fullfile(codeDir,fnameMetaData),'w');
fprintf(fidJson,jsonMetaDataEncoded);        
fclose(fidJson);

fclose(fid);
fclose(fidLabel);    
  