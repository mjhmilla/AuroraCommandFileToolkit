function success = createMuscleCharacterizationExperiments610A( ...
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

passiveLengthRampConfigConfig(2) = struct( 'wait',0,'waitPostRamp',0,...
                                    'normLengths',[0,0],'normLengthChange',0,...    
                                    'lengths',[0,0],'lengthChange',0,...
                                    'velocity',0,'duration',0,'options',[],...
                                    'type','');%,'port','');

isometricConfig(8) =              struct( 'normLengths',[0],...        
                                    'lengths',[0],...
                                    'options',[],...
                                    'type','');%,'port','');

activeLengthRampConfig(8) =       struct( 'wait',0,'waitPostRamp',0,...
                                    'normLengths',[0,0],'normLengthChange',0,...        
                                    'lengths',[0,0],'lengthChange',0,...
                                    'velocity',0,'duration',0,'options',[],...
                                    'type','');%,'port','');



% If the amount of activation time needs to be reduced then adjust
% 1. Remove the square wave perturbations
% 2. Reduce the active post-ramp wait time
% 

%
% Passive-lengthening injury
%


i=1;
passiveLengthRampConfig(i).wait         = 1;
passiveLengthRampConfig(i).waitPostRamp = 5; 
passiveLengthRampConfig(i).normLengths  = [-0.35,0.35];
passiveLengthRampConfig(i).normLengthChange = diff(passiveLengthRampConfig(i).normLengths);

passiveLengthRampConfig(i).lengths      = ...
    passiveLengthRampConfig(i).normLengths...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
passiveLengthRampConfig(i).lengthChange = diff(passiveLengthRampConfig(i).lengths);

passiveLengthRampConfig(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRampConfig(i).duration     = passiveLengthRampConfig(i).lengthChange ./ passiveLengthRampConfig(i).velocity;
passiveLengthRampConfig(i).options      = lengthRampOptions;  
passiveLengthRampConfig(i).type         = 'Passive-Length-Ramp';

i=2;
passiveLengthRampConfig(i).wait         = 1;
passiveLengthRampConfig(i).waitPostRamp = 5;
passiveLengthRampConfig(i).normLengths  = [-0.35,0.35];
passiveLengthRampConfig(i).normLengthChange = diff(passiveLengthRampConfig(i).normLengths);

passiveLengthRampConfig(i).lengths      = ...
    passiveLengthRampConfig(i).normLengths...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
passiveLengthRampConfig(i).lengthChange = diff(passiveLengthRampConfig(i).lengths);

passiveLengthRampConfig(i).velocity     = (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRampConfig(i).duration     = passiveLengthRampConfig(i).lengthChange ./ passiveLengthRampConfig(i).velocity;
passiveLengthRampConfig(i).options      = lengthRampOptions;  
passiveLengthRampConfig(i).type         = 'Passive-Length-Ramp';


indexIsometricOptimalLength = 2;


normLengthStart = -0.4;
normLengthDelta = (0.4-(normLengthStart))/(length(isometricConfig)-1);

for i=1:1:length(isometricConfig)
    normLength = normLengthStart + normLengthDelta*(i-1);

    isometricConfig(i).normLengths = normLength;
    isometricConfig(i).lengths = ...
    isometricConfig(i).normLengths*auroraConfig.approximateSampleLengthInDefaultUnits;
    isometricConfig(i).options = lengthRampOptions;
    isometricConfig(i).type = 'Isometric';

end

%
% Active-lengthening ramp
%


i=1;
activeLengthRampConfig(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRampConfig(i).normLengths  = [0.1,-0.1];
activeLengthRampConfig(i).normLengthChange = diff(activeLengthRampConfig(i).normLengths);

activeLengthRampConfig(i).lengths      = ...
    activeLengthRampConfig(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;

activeLengthRampConfig(i).lengthChange = diff(activeLengthRampConfig(i).lengths);
activeLengthRampConfig(i).velocity     = -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRampConfig(i).duration     = activeLengthRampConfig(i).lengthChange ./ activeLengthRampConfig(i).velocity;
activeLengthRampConfig(i).options      = lengthRampOptions;  
activeLengthRampConfig(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRampConfig(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRampConfig(i).normLengths  = [0.1,-0.1];
activeLengthRampConfig(i).normLengthChange = diff(activeLengthRampConfig(i).normLengths);

activeLengthRampConfig(i).lengths      = ...
    activeLengthRampConfig(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRampConfig(i).lengthChange = diff(activeLengthRampConfig(i).lengths);

activeLengthRampConfig(i).velocity     = -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRampConfig(i).duration     = activeLengthRampConfig(i).lengthChange ./ activeLengthRampConfig(i).velocity;
activeLengthRampConfig(i).options      = lengthRampOptions;  
activeLengthRampConfig(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRampConfig(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRampConfig(i).normLengths  = [-0.1,0.1];
activeLengthRampConfig(i).normLengthChange = diff(activeLengthRampConfig(i).normLengths);

activeLengthRampConfig(i).lengths      = ...
    activeLengthRampConfig(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRampConfig(i).lengthChange = diff(activeLengthRampConfig(i).lengths);

activeLengthRampConfig(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRampConfig(i).duration     = activeLengthRampConfig(i).lengthChange ./ activeLengthRampConfig(i).velocity;
activeLengthRampConfig(i).options      = lengthRampOptions;  
activeLengthRampConfig(i).type         = 'Active-Lengthening';

i=i+1;
activeLengthRampConfig(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRampConfig(i).normLengths  = [-0.1,0.1];
activeLengthRampConfig(i).normLengthChange = diff(activeLengthRampConfig(i).normLengths);

activeLengthRampConfig(i).lengths      = ...
    activeLengthRampConfig(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRampConfig(i).lengthChange = diff(activeLengthRampConfig(i).lengths);

activeLengthRampConfig(i).velocity     = (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRampConfig(i).duration     = activeLengthRampConfig(i).lengthChange ./ activeLengthRampConfig(i).velocity;
activeLengthRampConfig(i).options      = lengthRampOptions;  
activeLengthRampConfig(i).type         = 'Active-Lengthening';

%
% Active-lengthening injury
%

i=1;
activeLengtheningInjury(i).wait         = 0;
activeLengtheningInjury(i).normLengths  = [-0.1,0.5];
activeLengtheningInjury(i).normLengthChange = diff(activeLengtheningInjury(i).normLengths);

activeLengtheningInjury(i).lengths      = ...
    activeLengtheningInjury(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengtheningInjury(i).lengthChange = diff(activeLengtheningInjury(i).lengths);

activeLengtheningInjury(i).velocity     = (1/2)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengtheningInjury(i).duration     = activeLengtheningInjury(i).lengthChange ./ activeLengtheningInjury(i).velocity;
activeLengtheningInjury(i).options      = lengthRampOptions;  
activeLengtheningInjury(i).type         = 'Active-Lengthening-Injury';

i=2;
activeLengtheningInjury(i).wait         = 0;
activeLengtheningInjury(i).normLengths  = [0.5,-0.1];
activeLengtheningInjury(i).normLengthChange = diff(activeLengtheningInjury(i).normLengths);

activeLengtheningInjury(i).lengths      = ...
    activeLengtheningInjury(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengtheningInjury(i).lengthChange = ...
    diff(activeLengtheningInjury(i).lengths) ...
    +activeLengtheningInjury(i-1).lengthChange;

activeLengtheningInjury(i).velocity     = -(1/2)*activeLengtheningInjury(i-1).velocity;
activeLengtheningInjury(i).duration     = activeLengtheningInjury(i-1).duration;
activeLengtheningInjury(i).options      = lengthRampOptions;  
activeLengtheningInjury(i).type         = 'Active-Lengthening-Injury';


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

codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A']);
codeLabelDir    = fullfile(projectFolders.output_code,[dateId,'_610A'],'segmentLabels');

fileFolderList=dir(projectFolders.output_code);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,[dateId,'_610A']))
        codeDirExists=1;
    end
end

if(codeDirExists==1)
    codeLabelDirExists=0;   
    fileFolderList=dir(codeDir);
    for i=1:1:length(fileFolderList)
        if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,'segmentLabels'))
            codeLabelDirExists=1;
        end
    end
    if(codeLabelDirExists==0)
        mkdir(codeLabelDir);
    end
else
    mkdir(codeDir);
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
idx = createCharacterizationExperiments610A( ...
        startingIndex,...
        isometricConfig,...
        passiveLengthRampConfig,...
        activeLengthRampConfig,...
        stochasticWaveSet,...
        perturbationConfig,...        
        auroraConfig,...
        projectFolders,...
        characterizationMetaData);


%%
%
% Injury Trial
%
%%

idxStr = getTrialIndexString(idx);

startLength = activeLengtheningInjury(1).normLengths(1,1)+1;
type        = 'injury';
blockName   = 'Injury';
fname       = getTrialName(seriesName,idx,type,startLength,dateId,'.dpf');
fnameLabels = getTrialName(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');

fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
    idxStr,type,startLength, blockName,fname,'');

success = createActiveLengthRampSeriesTrial610A(...
                    activeLengtheningInjury,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    auroraConfig);

%%
%
% Characterization Block Round 2
%
%%
idx=idx+1;

idx = createCharacterizationExperiments610A( ...
        idx,...
        isometricConfig,...
        passiveLengthRampConfig,...
        activeLengthRampConfig,...
        stochasticWaveSet,...
        perturbationConfig,...        
        auroraConfig,...
        projectFolders,...
        characterizationMetaData);


fclose(fidProtocol);
success=1;