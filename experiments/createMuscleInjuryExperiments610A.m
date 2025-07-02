function success = createMuscleInjuryExperiments610A( stochasticWaveSet,...
                                                      perturbationConfig,...    
                                                      auroraConfig,...
                                                      projectFolders)

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

passiveLengthRamp(2) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','','port','');

%
% If the amount of activation time needs to be reduced then adjust
% 1. Remove the square wave perturbations
% 2. Reduce the active post-ramp wait time
% 

i=1;
passiveLengthRamp(i).wait         = 1;
passiveLengthRamp(i).waitPostRamp = 5; 
passiveLengthRamp(i).normLengths  = [-0.4,0.4];
passiveLengthRamp(i).lengths      = ...
    passiveLengthRamp(i).normLengths...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
passiveLengthRamp(i).lengthChange = diff(passiveLengthRamp(i).lengths);
passiveLengthRamp(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRamp(i).duration     = passiveLengthRamp(i).lengthChange ./ passiveLengthRamp(i).velocity;
passiveLengthRamp(i).options      = lengthRampOptions;  
passiveLengthRamp(i).type         = 'Passive-Length-Ramp';

i=2;
passiveLengthRamp(i).wait         = 1;
passiveLengthRamp(i).waitPostRamp = 5;
passiveLengthRamp(i).normLengths  = [-0.4,0.4];
passiveLengthRamp(i).lengths      = ...
    passiveLengthRamp(i).normLengths...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
passiveLengthRamp(i).lengthChange = diff(passiveLengthRamp(i).lengths);
passiveLengthRamp(i).velocity     = (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRamp(i).duration     = passiveLengthRamp(i).lengthChange ./ passiveLengthRamp(i).velocity;
passiveLengthRamp(i).options      = lengthRampOptions;  
passiveLengthRamp(i).type         = 'Passive-Length-Ramp';

isometric(3)= struct('length',0);

isometric(1).normLength = -0.4;
isometric(2).normLength = 0.0;
isometric(3).normLength = 0.4;

for i=1:1:length(isometric)
    isometric(i).length = isometric(i).normLength*auroraConfig.approximateSampleLengthInDefaultUnits;
end

activeLengthRamp(4) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','');

i=1;
activeLengthRamp(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRamp(i).normLengths  = [0.1,-0.1];
activeLengthRamp(i).lengths      = ...
    activeLengthRamp(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRamp(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRamp(i).normLengths  = [0.1,-0.1];
activeLengthRamp(i).lengths      = ...
    activeLengthRamp(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRamp(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRamp(i).normLengths  = [-0.1,0.1];
activeLengthRamp(i).lengths      = ...
    activeLengthRamp(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Lengthening';

i=i+1;
activeLengthRamp(i).wait         = auroraConfig.timeToReachMaxActivation;
activeLengthRamp(i).normLengths  = [-0.1,0.1];
activeLengthRamp(i).lengths      = ...
    activeLengthRamp(i).normLengths ...
    .*auroraConfig.approximateSampleLengthInDefaultUnits;
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = (2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Lengthening';





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
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = 1;
idxStr = getTrialIndexString(idx);

startLength = 1;
type        = 'isometric';
blockName   = 'Pre-injury';
fname       = getTrialNameUpd(idx,type,startLength,dateId,'.dpf');
fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_labels'],'.csv');


fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
    idxStr,type,startLength, blockName,fname,'');

success = createIsometricImpedanceTrial610A(...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    perturbationConfig,...
                    auroraConfig);
  

%%
% Block of passive trials
%%
flag_passiveTrialsReady = 0;

if(flag_passiveTrialsReady==1)
    for i=1:1:length(passiveLengthRamp)
        idx=idx+1;
        idxStr = getTrialIndexString(idx);
        
        startLength = passiveLengthRamp(i).normLengths(1,1)+1;
        type        = 'passiveLengthening';
        blockName   = 'Pre-injury';
        fname       = getTrialNameUpd(idx,type,startLength,dateId,'.dpf');
        fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_labels'],'.csv');
        
        
        fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
            idxStr,type,startLength, blockName,fname,'');
        
           
    
        %success = createActiveLengthRampImpedanceTrial610A(...
        %                    isRampActive,...
        %                    passiveLengthRamp(i),...
        %                    stochasticWaveSet,...
        %                    fullfile(codeDir,fname),...
        %                    fullfile(codeLabelDir,fnameLabels),...
        %                    perturbationConfig,...
        %                    auroraConfig);
          
    end
end

%%
% Block of isometric trials
%%
for i=1:1:length(isometric)
    idx = idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = isometric(i).normLength(1,1)+1;
    type        = 'isometric';
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialNameUpd(idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength, blockName,fname,'');
    
    success = createIsometricImpedanceTrial610A(...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        perturbationConfig,...
                        auroraConfig);
end

%%
% Block of active ramp trials
%%
for i=1:1:length(activeLengthRamp)
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = activeLengthRamp(i).normLengths(1,1)+1;
    if(activeLengthRamp(i).velocity > 0)
        type        = 'activeLengthening';
    else
        type        = 'activeShortening';
    end
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialNameUpd(idx,type,startLength,dateId,'.dpf');
    fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s\n',...
        idxStr,type,startLength,blockName,fname,'');
    
       

    success = createActiveLengthRampImpedanceTrial610A(...
                        activeLengthRamp(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        perturbationConfig,...
                        auroraConfig);
      
end  



fclose(fidProtocol);
success=1;