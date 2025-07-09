function success = constructCharacterizationExperiments610A( ...
                    stochasticWaveSet,...
                    perturbationConfig,...    
                    auroraConfig,...
                    expConfig,...
                    projectFolders)

seriesName = 'characterization';
disp('constructCharacterizationExperiments610A running');


%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
       'Error: printed time values configured for s only.');

assert(   strcmp(auroraConfig.defaultLengthUnit,'mm') ...
       || strcmp(auroraConfig.defaultLengthUnit,'Ref'),...
      'Error: Assumed length unit is mm or Ref');

%%
%Experiment configuration
%%
lengthRampOptions=getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

passiveLengthRampConfig(2) =      ...
    struct( 'wait',0,'waitPostRamp',0,...
            'normLengths',[0,0],'normLengthChange',0, 'endNormLength', 0, ...    
            'lengths',[0,0],'lengthChange',0, 'endLength',0,...
            'velocity',0,'duration',0,'options',[],...
            'type','');%,'port','');

isometricConfig(9) =  ...            
    struct( 'normLengths',[0],...        
            'endNormLength',0,...
            'lengths',[0],...
            'endLength',0,...
            'options',[],...
            'type','');%,'port','');

activeLengthRampConfig(12) =  ...
    struct( 'wait',0,'waitPostRamp',0,...
            'normLengths',[0,0],'normLengthChange',0, 'endNormLength', 0, ...    
            'lengths',[0,0],'lengthChange',0, 'endLength',0,...
            'velocity',0,'duration',0,'options',[],...
            'type','');%,'port','');


stretchShorteningCycle(12) = ...
    struct( 'wait',0,'waitPostRamp',0,...
            'normLengths',[0,0],'normLengthChange',0, 'endNormLength', 0, ...    
            'lengths',[0,0],'lengthChange',0, 'endLength',0,...
            'velocity',0,'duration',0,'options',[],...
            'type','');%,'port','');

% If the amount of activation time needs to be reduced then adjust
% 1. Remove the square wave perturbations
% 2. Reduce the active post-ramp wait time
% 

%
% Passive-lengthening injury
%


assert(length(passiveLengthRampConfig) ...
        == length(expConfig.passive.normVelocityRange),...
        ['Error: Length of passiveLengthRampConfig and ',...
         'expConfig.passive.normVelocityRange do not match']);

for i=1:1:length(passiveLengthRampConfig)

    passiveLengthRampConfig(i).wait         = 1;
    passiveLengthRampConfig(i).waitPostRamp = 5; 
    passiveLengthRampConfig(i).normLengths  = expConfig.passive.normLengths;
    passiveLengthRampConfig(i).normLengthChange = ...
        diff(passiveLengthRampConfig(i).normLengths);


    passiveLengthRampConfig(i).lengths      = ...
        passiveLengthRampConfig(i).normLengths...
        .*auroraConfig.approximateSampleLengthInDefaultUnits;

    passiveLengthRampConfig(i).lengthChange = ...
        diff(passiveLengthRampConfig(i).lengths);


    passiveLengthRampConfig(i).velocity     = ...
                expConfig.passive.normVelocityRange(1,i)...
                *auroraConfig.maximumRampSpeedInDefaultUnits;        

    passiveLengthRampConfig(i).duration     = ...
        passiveLengthRampConfig(i).lengthChange ...
        ./ passiveLengthRampConfig(i).velocity;


    passiveLengthRampConfig(i).endNormLength = expConfig.endNormLength;
    passiveLengthRampConfig(i).endLength     = ...
        passiveLengthRampConfig(i).endNormLength ...
        .*auroraConfig.approximateSampleLengthInDefaultUnits;

    passiveLengthRampConfig(i).options      = lengthRampOptions;  
    passiveLengthRampConfig(i).type         = 'Passive-Length-Ramp';

end




%%
% Isometric
%%

n=length(isometricConfig);
n01 = [0:(1/(n-1)):1]';

flag_optimalLengthTested=0;


normLengths = zeros(length(isometricConfig),1);
for i=1:1:length(isometricConfig)
    normLength(i,1) = expConfig.isometric.normLengthRange(1,1).*(1-n01(i,1)) ...
                    + expConfig.isometric.normLengthRange(1,2).*(n01(i,1)); 
end

normLength = [normLength;0];
normLength = unique(sort(normLength));

if(length(normLength) > length(isometricConfig))
    n = length(normLength);
    isometricConfig(n) =  ...            
        struct( 'normLengths',[0],...        
                'endNormLength',0,...
                'lengths',[0],...
                'endLength',0,...
                'options',[],...
                'type','');%,'port','');    
end

flag_normLengthTested = 0;

for i=1:1:length(isometricConfig)

    isometricConfig(i).normLengths = normLength(i,1);
    isometricConfig(i).lengths = ...
        isometricConfig(i).normLengths...
            *auroraConfig.approximateSampleLengthInDefaultUnits;

    isometricConfig(i).endLength = 0;
    isometricConfig(i).endNormLength = ...
        isometricConfig(i).endLength...
        .*auroraConfig.approximateSampleLengthInDefaultUnits;

    isometricConfig(i).options = lengthRampOptions;
    isometricConfig(i).type = 'Isometric';

    if(abs(normLength(i,1))<1e-6)
        flag_normLengthTested=1;
    end
end

assert(flag_normLengthTested==1,'Error: the optimal length is not tested');
%%
% Active-shortening and lengthening ramps
%%

assert( 4 == length(expConfig.activeRamp.normVelocityRange),...
        ['Error: Number of trials in expConfig.activeRamp.normVelocityRange ',...
         'is not 4']);

assert(4 == size(expConfig.activeRamp.normLengthRange,1),...
        ['Error: Number of trials in expConfig.activeRamp.normLengthRange ',...
         'is not 4']);

assert(length(expConfig.activeRamp.lengthOffset)==3, ...
       'Error: expConfig.activeRamp.lengthOffset should have a length of 3');


k=1;
lengthOffset = expConfig.activeRamp.lengthOffset;


for i = 1:1:3

    for j=1:1:4

        normLengths = expConfig.activeRamp.normLengthRange(j,:) ...
                      + lengthOffset(1,i);
        velocity    = expConfig.activeRamp.normVelocityRange(j,1) ...
                      *auroraConfig.maximumSpeedInDefaultUnits;

        activeLengthRampConfig(k).wait              = ...
            auroraConfig.timeToReachMaxActivation;


        activeLengthRampConfig(k).normLengths       = normLengths;
        activeLengthRampConfig(k).normLengthChange  = ...
            diff(activeLengthRampConfig(k).normLengths);

        activeLengthRampConfig(k).lengths      = ...
            activeLengthRampConfig(k).normLengths ...
            .*auroraConfig.approximateSampleLengthInDefaultUnits;

        activeLengthRampConfig(k).lengthChange = ...
            diff(activeLengthRampConfig(k).lengths);
        activeLengthRampConfig(k).velocity     = velocity;
        activeLengthRampConfig(k).duration     = ...
            activeLengthRampConfig(k).lengthChange ...
            ./ activeLengthRampConfig(k).velocity;

        activeLengthRampConfig(k).endLength         = expConfig.endNormLength;
        activeLengthRampConfig(k).endNormLength     = ...
                activeLengthRampConfig(k).endLength ...
                .*auroraConfig.approximateSampleLengthInDefaultUnits;

        activeLengthRampConfig(k).options           = lengthRampOptions;  
        if(velocity > 0)
            activeLengthRampConfig(k).type = 'Active-Lengthening';
        else
            activeLengthRampConfig(k).type = 'Active-Shortening';
        end
        k=k+1;
    end

end


%%
% Stretch-shortening
%%

assert(length(expConfig.stretchShortening.lengthOffset),...
      ['Error: expConfig.stretchShortening.lengthOffset',...
       ' does not have a length of 3']);

assert(size(expConfig.stretchShortening.normLengthRange,1),...
      ['Error: expConfig.stretchShortening.normLengthRange',...
       ' does not have a length of 4']);

assert(size(expConfig.stretchShortening.normVelocityRange,1),...
      ['Error: expConfig.stretchShortening.normVelocityRange',...
       ' does not have a length of 4']);


k=1;
lengthOffset = expConfig.stretchShortening.lengthOffset;

for i = 1:1:3

    for j=1:1:4

        normLengths = expConfig.stretchShortening.normLengthRange(j,:) ...
                     +lengthOffset(1,i);

        velocitySSC = expConfig.stretchShortening.normVelocityRange(j,:)...
                       .* auroraConfig.maximumRampSpeedInDefaultUnits;


        stretchShorteningCycle(k).wait         = [0,0,0];
        stretchShorteningCycle(k).normLengths  = normLengths;
        stretchShorteningCycle(k).normLengthChange = diff(stretchShorteningCycle(k).normLengths);

        stretchShorteningCycle(k).lengths      = ...
            stretchShorteningCycle(k).normLengths ...
            .*auroraConfig.approximateSampleLengthInDefaultUnits;
        stretchShorteningCycle(k).lengthChange = diff(stretchShorteningCycle(k).lengths);

        stretchShorteningCycle(k).velocity     = ...
            velocitySSC;

        stretchShorteningCycle(k).duration     = ...
            stretchShorteningCycle(k).lengthChange ...
            ./ stretchShorteningCycle(k).velocity;

        stretchShorteningCycle(k).endLength = 0;
        stretchShorteningCycle(k).endNormLength = ...
                stretchShorteningCycle(k).endLength ...
                .*auroraConfig.approximateSampleLengthInDefaultUnits;

        stretchShorteningCycle(k).options      = lengthRampOptions;  

        if(velocitySSC(1,1)>0)
            stretchShorteningCycle(k).type         = 'Stretch-Shorten';        
        else
            stretchShorteningCycle(k).type         = 'Shorten-Stretch';   
        end
        k=k+1;
    end

end


%%
%Make the output folders, if necessary
%%

[dateId, dateDir, codeDir, codeLabelDir] = ...
    makeExperimentSeriesFolders(seriesName, projectFolders);

%%
% Protocol data
%%

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s\n',...
    'unit_system',auroraConfig.unitSystem,'',...
    '','','');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo',...
    'Block','FileName','Comment');

%%
%
% Characterization Block Round 1
%
%%
characterizationMetaData.codeDir        = codeDir;
characterizationMetaData.codeLabelDir   = codeLabelDir;
characterizationMetaData.fidProtocol    = fidProtocol;
characterizationMetaData.seriesName     = seriesName;
characterizationMetaData.dateId         = dateId;

startingIndex=1;
idx = createCharacterizationTrialSet610A( ...
        startingIndex,...
        isometricConfig,...
        passiveLengthRampConfig,...
        activeLengthRampConfig,...
        stochasticWaveSet,...
        perturbationConfig,...        
        auroraConfig,...
        projectFolders,...
        characterizationMetaData);


for i=1:1:length(stretchShorteningCycle)

    idxStr = getTrialIndexString(idx);

    startLength = stretchShorteningCycle(i).normLengths(1,1)+1;
    typeOfTrial = 'ssc';
    blockName   = 'ssc';
    fname       = getTrialName(seriesName,idx,typeOfTrial,startLength,dateId,'.dpf');
    fnameLabels = getTrialName(seriesName,idx,typeOfTrial,startLength,[dateId,'_labels'],'.csv');

    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,typeOfTrial,startLength, blockName,fname,'');

    success = createStretchShortenSeriesTrial610A(...
                        stretchShorteningCycle(i),...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);

    idx=idx+1;

end


fclose(fidProtocol);
success=1;