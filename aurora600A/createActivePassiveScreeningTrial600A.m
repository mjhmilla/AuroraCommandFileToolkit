function jsonFileNameArray = createActivePassiveScreeningTrial600A(...    
                                fileCount,...                    
                                seriesName,...
                                blockName,...
                                startingLength,...
                                startingBathId,...
                                fidProtocol,...
                                auroraConfig,...
                                trialFileFolderSettings,...
                                settingsExperiment)


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
startLength  = startingLength;
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
%2. Move to desired length and test passive force: step-down and step-up.
%%
isRelativeOverride=0;
lengthRampOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Ramp',auroraConfig,isRelativeOverride);

lengthRampOptions(1).value = startingLength;
lengthRampOptions(2).value = 1*s2ms;

startTime = programMetaData.nextStartTime;
flag_printMetaDataLabelsToCsv=1;

[programMetaData,rampMetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Ramp',lengthRampOptions,{},...
        [],auroraConfig,programMetaData, flag_printMetaDataLabelsToCsv);

segmentMetaDataArray=rampMetaData;


% Step down
lengthStepOptions = getCommandFunctionOptions600AUpd(...
                      'Length-Step',auroraConfig,isRelativeOverride);

lengthStepOptions(1).value = startingLength-0.2;

startTime = programMetaData.nextStartTime+auroraConfig.oneSecond;
flag_printMetaDataLabelsToCsv=1;

[programMetaData,step1MetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Step',lengthStepOptions,{},...
        [],auroraConfig,programMetaData, 1);

segmentMetaDataArray=[segmentMetaDataArray,step1MetaData];


% Step back

lengthStepOptions(1).value = startingLength;

startTime = programMetaData.nextStartTime+auroraConfig.oneSecond;
flag_printMetaDataLabelsToCsv=1;

[programMetaData,step2MetaData] =  ...
    writeControlFunction600AUpd(...
      fid,startTime,'Length-Step',lengthStepOptions,{},...
        [],auroraConfig,programMetaData, 1);

segmentMetaDataArray=[segmentMetaDataArray,step2MetaData];

programMetaData.nextStartTime = ...
    programMetaData.nextStartTime+auroraConfig.oneSecond;
%%
% 3. Activate 
%%
[programMetaData, actSegMetaDataArray]= ...
  writeActivationBlock600AUpd(fid, auroraConfig, programMetaData);  

segmentMetaDataArray=[segmentMetaDataArray,actSegMetaDataArray];


%%
% 4. SL Trigger 
%%

slTriggerOptions = getCommandFunctionOptions600AUpd(...
                        'SL-Trigger',auroraConfig,[]);

  slTriggerOptions(1).value=10;

  startTime=  programMetaData.nextStartTime ...
            + auroraConfig.bath.minimumActivationDuration;
  flag_printMetaDataLabelsToCsv=1;

[programMetaData,slTriggerMetaData] =  ...
    writeControlFunction600AUpd(fid,startTime,...
        'SL-Trigger',slTriggerOptions,{},...
        [],auroraConfig,programMetaData, 1);


segmentMetaDataArray=[segmentMetaDataArray,slTriggerMetaData];

%%
% 5. Deactivate 
%%
startTime=programMetaData.nextStartTime;

[programMetaData, deActMetaData] = ...
    writeDeactivationBlock600AUpd(fid, auroraConfig, programMetaData);

segmentMetaDataArray=[segmentMetaDataArray,deActMetaData];

%%
% 5. Stop
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
jsonMetaData.experiment.title = 'Fiber Screening Test';
jsonMetaData.experiment.keywords={};

jsonMetaDataEncoded = jsonencode(jsonMetaData);
fidJson = fopen(fullfile(codeDir,fnameMetaData),'w');
fprintf(fidJson,jsonMetaDataEncoded);        
fclose(fidJson);

fclose(fid);
fclose(fidLabel);    
  