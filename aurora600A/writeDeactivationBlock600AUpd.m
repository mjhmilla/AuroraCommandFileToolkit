function [programMetaData, segmentMetaData] = ...
    writeDeactivationBlock600AUpd(fid, auroraConfig, programMetaData)


bathOptions = getCommandFunctionOptions600AUpd('Bath',auroraConfig,[]);

%Move to the pre-activation bath
bathOptions(1).value = auroraConfig.bath.passive;
bathOptions(2).value = 0;

startTime= programMetaData.nextStartTime;

flag_printMetaDataToCsv=1;

[programMetaData,fcnMetaData] = ...
    writeControlFunction600AUpd(fid,startTime,'Bath',bathOptions,...
            [], auroraConfig, programMetaData, flag_printMetaDataToCsv);

segmentMetaData=fcnMetaData;