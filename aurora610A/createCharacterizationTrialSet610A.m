function idx = createCharacterizationTrialSet610A(...
                    startingIndex,...
                    isometricConfig,...
                    passiveLengthRampConfig,...
                    activeLengthRampConfig,...
                    stochasticWaveSet,...
                    perturbationConfig,...    
                    auroraConfig,...
                    projectFolders,...
                    characterizationMetaData)


codeDir      = characterizationMetaData.codeDir      ;
codeLabelDir = characterizationMetaData.codeLabelDir ;
fidProtocol  = characterizationMetaData.fidProtocol  ;
seriesName   = characterizationMetaData.seriesName   ;
dateId       = characterizationMetaData.dateId       ;

indexOptimalLength = nan;
for i=1:1:length(isometricConfig)
    if(abs(isometricConfig(i).normLengths)<1e-6)
        indexOptimalLength = i;
    end
end
assert(isnan(indexOptimalLength)==0,...
       'Error: isometricConfig does not contain a test at a length of 0');

%%
% Starting isometric trial to see if the fiber is viable
%%
idx = startingIndex;
idxStr = getTrialIndexString(idx);

startLength = 1;
type        = 'isometric';
blockName   = 'Pre-injury';
fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');


fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
    idxStr,type,startLength, blockName,fname,'');

success = createIsometricImpedanceTrial610A(...
                    isometricConfig(indexOptimalLength),...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    perturbationConfig,...
                    auroraConfig);
  

%%
% Block of passive trials
%%
for i=1:1:length(passiveLengthRampConfig)
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = passiveLengthRampConfig(i).normLengths(1,1)+1;
    type        = 'passiveLengthening';
    blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength, blockName,fname,'');
    
           
    success = createPassiveLengthRampImpedanceTrial610A(...
                    passiveLengthRampConfig(i),...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    perturbationConfig,...
                    auroraConfig);
      
end

%%
% Block of isometric trials
%%
for i=1:1:length(isometricConfig)
    idx = idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = isometricConfig(i).normLengths(1,1)+1;
    type        = 'isometric';
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength, blockName,fname,'');
    
    success = createIsometricImpedanceTrial610A(...
                        isometricConfig(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        perturbationConfig,...
                        auroraConfig);
end

%%
% Block of active ramp trials
%%
for i=1:1:length(activeLengthRampConfig)
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    if(idx==15)
        here=1;
    end

    startLength = activeLengthRampConfig(i).normLengths(1,1)+1;
    if(activeLengthRampConfig(i).velocity > 0)
        type        = 'activeLengthening';
    else
        type        = 'activeShortening';
    end
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength,blockName,fname,'');
    
       

    success = createActiveLengthRampImpedanceTrial610A(...
                        activeLengthRampConfig(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        perturbationConfig,...
                        auroraConfig);
      
end  

idx=idx+1;