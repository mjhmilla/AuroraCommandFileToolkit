function indexEnd = createImpedanceForceLengthExperiments600A_Sine(...
                        seriesName,...
                        blockName,...
                        settingsImpedance,...
                        stochasticWaveSet,...
                        projectFolders,...                                                                                                            
                        auroraConfig)

assert(~isempty(seriesName),...
    'Error: series name must have a meaningful keyword in it');

[codeDir, codeLabelDir,dateId] = ...
    getTrialDirectories(projectFolders,['_',seriesName,'_impedance']);

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

idxStart = 0;
writeProtocolHeader=1;

if(writeProtocolHeader==1)
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
end

%%
% Check (some) of the inputs
%%

assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');

%%
%Experiment configuration
%%

scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

assert(strcmp(auroraConfig.defaultLengthUnit,'Lo'),...
      'Error: Assumed length unit is Lo');

nIsometric = length(settingsImpedance.isometricNormLengths);
isometric(nIsometric)= struct('length',0,'activationDuration',0);

for idxIsometric = 1:1:nIsometric
    isometric(idxIsometric).length = ...
            settingsImpedance.isometricNormLengths(1,idxIsometric);
    isometric(idxIsometric).activationDuration = ...
        auroraConfig.bath.activationDuration ...
        * settingsImpedance.isometricActivationDurationMultiple(1,idxIsometric);
end

%%
% Block of isometric trials
%%
idx=idxStart;
for i=1:1:nIsometric
    idx = idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = isometric(i).length;
    typeName        = 'isometric';
    takePhoto   = '';
    %blockName   = '';
    fname       = getTrialName(seriesName,idx,typeName,startLength,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,typeName,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,typeName,startLength,takePhoto, blockName,fname,'');

    auroraConfigIso = auroraConfig;
    auroraConfigIso.bath.activationDuration = isometric(i).activationDuration;

    success = createIsometricImpedanceTrial600A(...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfigIso);
end

indexEnd = idx;