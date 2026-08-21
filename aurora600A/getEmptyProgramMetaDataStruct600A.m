function programMetaData = getEmptyProgramMetaDataStruct600A(...
                            fullFilePathSegmentDataFile)


programMetaData.controlFunction.startTime   = nan;
programMetaData.controlFunction.endTime     = nan;
programMetaData.controlFunction.duration    = nan;

programMetaData.startTime                   = nan;
programMetaData.nextStartTime               = nan;
programMetaData.lineCount                   = nan;

programMetaData.labelFileHandle = fopen(fullFilePathSegmentDataFile,'w');

programMetaData.dataEnable = nan;
programMetaData.bathNumber = nan;
