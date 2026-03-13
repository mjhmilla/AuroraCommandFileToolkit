function indexEnd = createCharacterizationExperiments600A( ...
                        seriesName,...
                        blockName,...
                        indexStart,...
                        settingsCharacterization,...
                        stochasticWaveSet,...
                        characterizationFolders,...
                        projectFolders,... 
                        auroraConfig,...
                        fidProtocol,...
                        writeProtocolHeader)



%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');
%%
%Experiment configuration
%%
lengthRampOptions=getCommandFunctionOptions600A('Length-Ramp',auroraConfig);

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

nPassive=length(settingsCharacterization.passive.normVelocities);

passiveLengthRamp(nPassive) = ...
         struct('wait',0,'waitPostRamp',0,...
                'lengths',[0,0],'lengthChange',0,...
                'velocity',0,'duration',0,'options',[],'type','');

i=0;

for idxPassive = 1:1:nPassive

    i=i+1;
    passiveLengthRamp(i).wait         = 1.*scaleTime;
    passiveLengthRamp(i).waitPostRamp = 15.*scaleTime;
    passiveLengthRamp(i).lengths      = settingsCharacterization.passive.normLengths;
    passiveLengthRamp(i).lengthChange = diff(passiveLengthRamp(i).lengths);
    passiveLengthRamp(i).velocity     = ...
        settingsCharacterization.passive.normVelocities(1,idxPassive)...
        *auroraConfig.maximumRampSpeedInDefaultUnits;
    
    passiveLengthRamp(i).duration     = passiveLengthRamp(i).lengthChange ...
                                     ./ passiveLengthRamp(i).velocity;
    passiveLengthRamp(i).options      = lengthRampOptions;  
    passiveLengthRamp(i).type         = 'passiveLengthRamp';

end

nIsometric = length(settingsCharacterization.isometricNormLengths);
isometric(nIsometric)= struct('length',0);

for idxIsometric = 1:1:nIsometric
    isometric(idxIsometric).length = ...
            settingsCharacterization.isometricNormLengths(1,idxIsometric);
    isometric(idxIsometric).activationDuration = ...
        auroraConfig.bath.activationDuration ...
        * settingsCharacterization.isometricActivationDurationMultiple(1,idxIsometric);
end



nActiveLengthening = ...
    length(settingsCharacterization.activeLengthening.normVelocity);
nActiveShortening = ...
    length(settingsCharacterization.activeShortening.normVelocity);

nActiveRamp = nActiveLengthening+nActiveShortening;

activeLengthRamp(nActiveRamp) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','');

i=0;
for idxRamp=1:1:nActiveShortening
    i=i+1;
    activeLengthRamp(i).wait         = 1.*scaleTime;
    activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
    activeLengthRamp(i).lengths      = ...
            settingsCharacterization.activeShortening.normLengths;
    activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
    activeLengthRamp(i).velocity     = ...
        settingsCharacterization.activeShortening.normVelocity(1,idxRamp)...
        *auroraConfig.maximumRampSpeedInDefaultUnits;
    activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange...
                                    ./ activeLengthRamp(i).velocity;
    activeLengthRamp(i).options      = lengthRampOptions;  
    activeLengthRamp(i).type         = 'activeShortening';
end

for idxRamp=1:1:nActiveLengthening
    i=i+1;
    activeLengthRamp(i).wait         = 1.*scaleTime;
    activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
    activeLengthRamp(i).lengths      = ...
            settingsCharacterization.activeLengthening.normLengths;
    activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
    activeLengthRamp(i).velocity     = ...
        settingsCharacterization.activeLengthening.normVelocity(1,idxRamp)...
        *auroraConfig.maximumRampSpeedInDefaultUnits;
    activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange...
                                    ./ activeLengthRamp(i).velocity;
    activeLengthRamp(i).options      = lengthRampOptions;  
    activeLengthRamp(i).type         = 'activeLengthening';
end

% 
% i=1;
% activeLengthRamp(i).wait         = 1.*scaleTime;
% activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
% activeLengthRamp(i).lengths      = [1.1,0.9];
% activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
% activeLengthRamp(i).velocity     = -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
% activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
% activeLengthRamp(i).options      = lengthRampOptions;  
% activeLengthRamp(i).type         = 'Active-Shortening';
% 
% i=i+1;
% activeLengthRamp(i).wait         = 1.*scaleTime;
% activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
% activeLengthRamp(i).lengths      = [1.1,0.9];
% activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
% activeLengthRamp(i).velocity     = -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
% activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
% activeLengthRamp(i).options      = lengthRampOptions;  
% activeLengthRamp(i).type         = 'Active-Shortening';
% 
% i=i+1;
% activeLengthRamp(i).wait         = 1.*scaleTime;
% activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
% activeLengthRamp(i).lengths      = [0.9,1.1];
% activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
% activeLengthRamp(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
% activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
% activeLengthRamp(i).options      = lengthRampOptions;  
% activeLengthRamp(i).type         = 'Active-Lengthening';
% 
% i=i+1;
% activeLengthRamp(i).wait         = 1.*scaleTime;
% activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
% activeLengthRamp(i).lengths      = [0.9,1.1];
% activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
% activeLengthRamp(i).velocity     = (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
% activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
% activeLengthRamp(i).options      = lengthRampOptions;  
% activeLengthRamp(i).type         = 'Active-Lengthening';





%%
%Make the output folders, if necessary
%%
%[codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders,'');
codeDir         = characterizationFolders.codeDir;
codeLabelDir    = characterizationFolders.codeLabelDir;
dateId          = characterizationFolders.dateId;


%%
% 
%%

if(writeProtocolHeader==1)
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
end
%%
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = indexStart;
idxStr = getTrialIndexString(idx);

startLength = 1;
typeName        = 'isometric';
takePhoto   = 'Yes';
%blockName   = 'Pre-injury';
fname       = getTrialName(seriesName,idx,typeName,startLength,...
                auroraConfig.defaultLengthUnit,dateId,'.pro');
fnameLabels = getTrialName(seriesName,idx,typeName,startLength,...
                auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');


fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
    idxStr,typeName,startLength,takePhoto, blockName,fname,'Set Fmax in the 600A Setup window');

success = createIsometricImpedanceTrial600A(...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    auroraConfig);
  

%%
% Block of passive trials
%%

for i=1:1:nPassive
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = passiveLengthRamp(i).lengths(1,1);
    typeName        = 'passiveLengthening';
    takePhoto   = '';
    %blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,typeName,startLength,takePhoto, blockName,fname,'');
    
       
    isRampActive=0;

    success = createLengthRampImpedanceTrial600A(...
                        isRampActive,...
                        passiveLengthRamp(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);
      
end

%%
% Block of isometric trials
%%
for i=1:1:nIsometric
    idx = idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = isometric(i).length;
    typeName        = 'isometric';
    takePhoto   = '';
    %blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
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

%%
% Block of active ramp trials
%%
for i=1:1:nActiveRamp
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = activeLengthRamp(i).lengths(1,1);

    typeName = activeLengthRamp(i).type;

    takePhoto   = '';
    %blockName   = 'Pre-injury';
    fname       = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,typeName,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,typeName,startLength,takePhoto, blockName,fname,'');
    
       
    isRampActive=1;

    success = createLengthRampImpedanceTrial600A(...
                        isRampActive,...
                        activeLengthRamp(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);
      
end  



%fclose(fidProtocol);
indexEnd = idx;