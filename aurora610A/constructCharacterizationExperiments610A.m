function success = constructCharacterizationExperiments610A( ...
                    stochasticWaveSet,...
                    perturbationConfig,...    
                    auroraConfig,...
                    projectFolders)

seriesName = 'characterization';

%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
       'Error: printed time values configured for s only.');
assert(strcmp(auroraConfig.defaultLengthUnit,'mm'),...
      'Error: Assumed length unit is mm');
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


stretchShorteningCycle(6) = ...
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


for i=1:1:length(passiveLengthRampConfig)

    passiveLengthRampConfig(i).wait         = 1;
    passiveLengthRampConfig(i).waitPostRamp = 5; 
    passiveLengthRampConfig(i).normLengths  = [-0.35,0.35];
    passiveLengthRampConfig(i).normLengthChange = ...
        diff(passiveLengthRampConfig(i).normLengths);


    passiveLengthRampConfig(i).lengths      = ...
        passiveLengthRampConfig(i).normLengths...
        .*auroraConfig.approximateSampleLengthInDefaultUnits;

    passiveLengthRampConfig(i).lengthChange = ...
        diff(passiveLengthRampConfig(i).lengths);

    switch i
        case 1
            passiveLengthRampConfig(i).velocity     = ...
                (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
    
        case 2
            passiveLengthRampConfig(i).velocity     = ...
                (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
    
        otherwise
            assert(0,'Error: passiveLengthRampConfig missing case statement');
    end

    passiveLengthRampConfig(i).duration     = ...
        passiveLengthRampConfig(i).lengthChange ...
        ./ passiveLengthRampConfig(i).velocity;


    passiveLengthRampConfig(i).endNormLength = 0;
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

for i=1:1:length(isometricConfig)
    normLength = -0.4.*(1-n01(i,1)) + 0.4.*(n01(i,1)); 
    
    if(abs(normLength)<1e-6)
        flag_optimalLengthTested=1;
        indexIsometricOptimalLength = i;
    end

    isometricConfig(i).normLengths = normLength;
    isometricConfig(i).lengths = ...
        isometricConfig(i).normLengths...
            *auroraConfig.approximateSampleLengthInDefaultUnits;

    isometricConfig(i).endLength = 0;
    isometricConfig(i).endNormLength = ...
        isometricConfig(i).endLength...
        .*auroraConfig.approximateSampleLengthInDefaultUnits;

    isometricConfig(i).options = lengthRampOptions;
    isometricConfig(i).type = 'Isometric';

end

assert(flag_optimalLengthTested==1,...
       'Error: The optimal length is not tested');

%%
% Active-shortening and lengthening ramps
%%

k=1;
lengthOffset = [0,-0.4, 0.4];
for i = 1:1:3


    for j=1:1:4

        switch j 
            case 1
                normLengths = [0.1,-0.1]+lengthOffset(1,i);
                velocity = -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
            case 2
                normLengths = [0.1,-0.1]+lengthOffset(1,i);                
                velocity = -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;                
            case 3
                normLengths = [-0.1,0.1]+lengthOffset(1,i);                
                velocity =  (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;                
            case 4
                normLengths = [-0.1,0.1]+lengthOffset(1,i);                                
                velocity =  (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;                
            otherwise
                assert(0,'Error: missing a case in activeLengthRampConfig');
        end

        activeLengthRampConfig(k).wait              = auroraConfig.timeToReachMaxActivation;
        activeLengthRampConfig(k).normLengths       = normLengths;
        activeLengthRampConfig(k).normLengthChange  = diff(activeLengthRampConfig(k).normLengths);

        activeLengthRampConfig(k).lengths      = ...
            activeLengthRampConfig(k).normLengths ...
            .*auroraConfig.approximateSampleLengthInDefaultUnits;

        activeLengthRampConfig(k).lengthChange = ...
            diff(activeLengthRampConfig(k).lengths);
        activeLengthRampConfig(k).velocity     = velocity;
        activeLengthRampConfig(k).duration     = ...
            activeLengthRampConfig(k).lengthChange ...
            ./ activeLengthRampConfig(k).velocity;

        activeLengthRampConfig(k).endLength         = 0;
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

k=1;
lengthOffset = [-0.4, -0.1, 0.4];

for i = 1:1:3

    for j=1:1:2
        switch j
            case 1
                velocitySSC = [(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits,...
                              -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits];
            case 2
                velocitySSC = [(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits,...
                              -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits];                
            otherwise
                assert(0,'Error: missing case statement');
        end

        stretchShorteningCycle(k).wait         = [0,0,0];
        stretchShorteningCycle(k).normLengths  = [0.0, 0.1, 0.0] + lengthOffset(1,i);
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
        stretchShorteningCycle(k).type         = 'Stretch-Shortening';        
    k=k+1;
    end

end


%%
%Make the output folders, if necessary
%%
[y,m,d] = datevec(date());

yStr = int2str(y);
mStr = int2str(m);
dStr = int2str(d);
if(length(mStr)<2)
    mStr = ['0',mStr];
end
if(length(dStr)<2)
    dStr = ['0',dStr];
end
dateId = [yStr,mStr,dStr];

dateDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A'],seriesName);
codeLabelDir    = fullfile(projectFolders.output_code,[dateId,'_610A'],seriesName,'segmentLabels');


fileFolderList=dir(projectFolders.output_code);

dateDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
            && strcmp(fileFolderList(i).name,[dateId,'_610A']))
        dateDirExists=1;
    end
end

if(dateDirExists==0)
    mkdir(dateDir);
end

codeDirExists = 0;
fileFolderList=dir(dateDir);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
        && strcmp(fileFolderList(i).name,seriesName))
        codeDirExists=1;
    end
end

if(codeDirExists==0)
    mkdir(codeDir);
end

codeLabelDirExists=0;   
fileFolderList=dir(codeDir);
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
        && strcmp(fileFolderList(i).name,'segmentLabels'))
        codeLabelDirExists=1;
    end
end
if(codeLabelDirExists==0)
    mkdir(codeLabelDir);
end

%%
% 
%%

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

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
    type        = 'ssc';
    blockName   = 'ssc';
    fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');

    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength, blockName,fname,'');

    success = createActiveLengthRampSeriesTrial610A(...
                        stretchShorteningCycle(i),...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);

    idx=idx+1;

end


fclose(fidProtocol);
success=1;