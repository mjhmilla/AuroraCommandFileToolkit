function metaData = getProjectMimeSpecimenMetaDataExperiments610A(specimenNumber)

metaData = struct('lceOptMM',0,'vceMaxMMPS',0,'fmaxMN',0,'muscleName','',...
                  'date','','muscleCount',0,'animal','','sex','');

switch specimenNumber
    case 1
        metaData.lceOptMM       = [];
        metaData.vceMaxMMPS     = [];
        metaData.fmaxMN         = [];
        metaData.temperature    = [];

        metaData.muscleName     = '';% 'SOL' or 'EDL'
        metaData.date           = '';%YYYYMMDD;
        metaData.muscleCount    = []; %1, or of 2 EDL's are done in one day, 2

        metaData.animal         = 'rat';
        metaData.sex            = '?';
        metaData.muscleMassG    = [];
        metaData.muscleLengthMM = [];

    otherwise
        assert(0,sprintf('%s%i%s\n',...
            'Error: specimenNumber ', specimenNumber,...
            ' has not yet been entered'));

end