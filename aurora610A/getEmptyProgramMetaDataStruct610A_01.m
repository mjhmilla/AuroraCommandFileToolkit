function programMetaData = ...
  getEmptyProgramMetaDataStruct610A_01(startingLength,...
                                       fullFilePathSegmentDataFile)


programMetaData.controlFunction.startTime   = nan;
programMetaData.controlFunction.endTime     = nan;
programMetaData.controlFunction.duration    = nan;

programMetaData.startTime                   = nan;
programMetaData.nextStartTime               = nan;
programMetaData.smallestNextWaitTime        = nan;
programMetaData.lineCount                   = nan;

programMetaData.length              = startingLength;
programMetaData.Stimulus_time       = [];
%Stimulus_time will be a start and end time for Stimulus-Tetanus (e.g. [0,1])
%Stimulus_time will be a series of start and end times for Stimulus-Train
%(e.g. [0,1; 2,3; 4,5]);

programMetaData.labelFileHandle = fopen(fullFilePathSegmentDataFile,'w');

programMetaData.dataColumns ={'time_ms','length_mm','stimulation_trigger'};
programMetaData.data = [];

