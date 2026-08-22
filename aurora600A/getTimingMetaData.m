function segmentMetaData=getTimingMetaData(programMetaData,auroraConfig)

fcnMetaDataA=getEmptySegmentMetaDataStruct600A(...
              'Time-Recorded',auroraConfig);

fcnMetaDataA.(auroraConfig.labels.time)...
    =[0,programMetaData.totalRecordedTime];
fcnMetaDataA.is_recorded=1;

segmentMetaData=fcnMetaDataA;

fcnMetaDataB=getEmptySegmentMetaDataStruct600A(...
              'Time-Ignored',auroraConfig);

fcnMetaDataB.(auroraConfig.labels.time)...
    =[0,programMetaData.totalIgnoredTime];
fcnMetaDataB.is_recorded=0;

segmentMetaData=[segmentMetaData,fcnMetaDataB];


