function programMetaData = getEmptyProgramMetaDataStruct(fullFilePathSegmentDataFile)


programMetaData.controlFunction.startTime   = nan;
programMetaData.controlFunction.endTime     = nan;
programMetaData.controlFunction.duration    = nan;

programMetaData.startTime                   = nan;
programMetaData.nextStartTime               = nan;
programMetaData.smallestNextWaitTime        = nan;
programMetaData.lineCount                   = nan;


programMetaData.labelFileHandle = fopen(fullFilePathSegmentDataFile,'w');