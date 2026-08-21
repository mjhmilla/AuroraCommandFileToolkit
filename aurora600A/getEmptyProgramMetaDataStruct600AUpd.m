function programMetaData = getEmptyProgramMetaDataStruct600AUpd(...
                            fullFilePathSegmentDataFile,...
                            startingBathNumber)


programMetaData.controlFunction.startTime   = nan;
programMetaData.controlFunction.endTime     = nan;
programMetaData.controlFunction.duration    = nan;

programMetaData.startTime                   = nan;
programMetaData.nextStartTime               = nan;
programMetaData.lineCount                   = nan;

programMetaData.labelFileHandle = fopen(fullFilePathSegmentDataFile,'w');

programMetaData.dataEnable = nan;
programMetaData.bathNumber = startingBathNumber;

assert(~isnan(startingBathNumber),...
  'Error: the starting bath should be set');
assert(startingBathNumber >=1 && startingBathNumber <= 8,...
      'Error: startingBathNumber must be between 1-8');
assert(startingBathNumber-round(startingBathNumber)==0,...
       'Error: startingBathNumber must be an integer');