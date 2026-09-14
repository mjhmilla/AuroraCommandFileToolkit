function [programMetaData, segmentMetaDataArray] = ...
    writeActivationBlock600AUpd(fid, auroraConfig, programMetaData)


flag_printMetaDataToCsv=1;

assert(programMetaData.bathNumber == auroraConfig.bath.passive,...
       'Error: this function assumes that the fiber starts in the passive well');

%%
% Execute the bath change
%%
bathOptions = getCommandFunctionOptions600A('Bath',auroraConfig);

bathOptions(1).value = auroraConfig.bath.preActivation;
bathOptions(2).value = 0;


preActStartTime = programMetaData.nextStartTime;

[programMetaData,fcnMetaData] =  ...
    writeControlFunction600AUpd(fid, preActStartTime,...
    'Bath',bathOptions,{},...
    [], auroraConfig, programMetaData, flag_printMetaDataToCsv);

segmentMetaDataArray=fcnMetaData;

%%
% Move to the activation bath
%%

activationStartTime = programMetaData.nextStartTime ...
                    + auroraConfig.bath.preActivationDuration;

bathOptions(1).value = auroraConfig.bath.active;
bathOptions(2).value = 0;

[programMetaData,fcnMetaData] =  ...
    writeControlFunction600AUpd(fid, activationStartTime,...
    'Bath',bathOptions,{},...
    [],auroraConfig, programMetaData,flag_printMetaDataToCsv);

segmentMetaDataArray=[segmentMetaDataArray,fcnMetaData];

