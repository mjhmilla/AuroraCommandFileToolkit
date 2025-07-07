function success = createFiberInjuryExperiments600A(  stochasticWaveSet,...
                                                      projectFolders,...                                                                                                            
                                                      auroraConfig)


seriesName = 'injury';
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

passiveLengthRamp(2) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','');

i=1;
passiveLengthRamp(i).wait         = 1.*scaleTime;
passiveLengthRamp(i).waitPostRamp = 15.*scaleTime;
passiveLengthRamp(i).lengths      = [0.6,1.55];
passiveLengthRamp(i).lengthChange = diff(passiveLengthRamp(i).lengths);
passiveLengthRamp(i).velocity     = 0.1*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRamp(i).duration     = passiveLengthRamp(i).lengthChange ./ passiveLengthRamp(i).velocity;
passiveLengthRamp(i).options      = lengthRampOptions;  
passiveLengthRamp(i).type         = 'Passive-Length-Ramp';
i=2;
passiveLengthRamp(i).wait         = 1.*scaleTime;
passiveLengthRamp(i).waitPostRamp = 15.*scaleTime;
passiveLengthRamp(i).lengths      = [0.6,1.55];
passiveLengthRamp(i).lengthChange = diff(passiveLengthRamp(i).lengths);
passiveLengthRamp(i).velocity     = 1*auroraConfig.maximumRampSpeedInDefaultUnits;
passiveLengthRamp(i).duration     = passiveLengthRamp(i).lengthChange ./ passiveLengthRamp(i).velocity;
passiveLengthRamp(i).options      = lengthRampOptions;  
passiveLengthRamp(i).type         = 'Passive-Length-Ramp';

isometric(3)= struct('length',0);
isometric(1).length = 0.6;
isometric(2).length = 1;
isometric(3).length = 1.4;

activeLengthRamp(4) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','');

i=1;
activeLengthRamp(i).wait         = 1.*scaleTime;
activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
activeLengthRamp(i).lengths      = [1.1,0.9];
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = -(1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRamp(i).wait         = 1.*scaleTime;
activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
activeLengthRamp(i).lengths      = [1.1,0.9];
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = -(2/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Shortening';

i=i+1;
activeLengthRamp(i).wait         = 1.*scaleTime;
activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
activeLengthRamp(i).lengths      = [0.9,1.1];
activeLengthRamp(i).lengthChange = diff(activeLengthRamp(i).lengths);
activeLengthRamp(i).velocity     = (1/3)*auroraConfig.maximumRampSpeedInDefaultUnits;
activeLengthRamp(i).duration     = activeLengthRamp(i).lengthChange ./ activeLengthRamp(i).velocity;
activeLengthRamp(i).options      = lengthRampOptions;  
activeLengthRamp(i).type         = 'Active-Lengthening';

i=i+1;
activeLengthRamp(i).wait         = 1.*scaleTime;
activeLengthRamp(i).waitPostRamp = 15.*scaleTime;
activeLengthRamp(i).lengths      = [0.9,1.1];
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

codeDir         = fullfile(projectFolders.output_code,[dateId,'_600A']);
codeLabelDir    = fullfile(projectFolders.output_code,[dateId,'_600A'],'segmentLabels');

fileFolderList=dir(projectFolders.output_code);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,[dateId,'_600A']))
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

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo',...
    'Take_Photo','Block','FileName','Comment');

%%
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = 1;
idxStr = getTrialIndexString(idx);

startLength = 1;
type        = 'isometric';
takePhoto   = 'Yes';
blockName   = 'Pre-injury';
fname       = getTrialNameUpd(seriesName,idx,type,startLength,dateId,'.pro');
fnameLabels = getTrialNameUpd(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');


fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
    idxStr,type,startLength,takePhoto, blockName,fname,'');

success = createIsometricImpedanceTrial600A(...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    auroraConfig);
  

%%
% Block of passive trials
%%

for i=1:1:length(passiveLengthRamp)
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = passiveLengthRamp(i).lengths(1,1);
    type        = 'passiveLengthening';
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialNameUpd(seriesName,idx,type,startLength,dateId,'.pro');
    fnameLabels = getTrialNameUpd(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,type,startLength,takePhoto, blockName,fname,'');
    
       
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
for i=1:1:length(isometric)
    idx = idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = isometric(i).length;
    type        = 'isometric';
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialNameUpd(seriesName,idx,type,startLength,dateId,'.pro');
    fnameLabels = getTrialNameUpd(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,type,startLength,takePhoto, blockName,fname,'');
    
    success = createIsometricImpedanceTrial600A(...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);
end

%%
% Block of active ramp trials
%%
for i=1:1:length(activeLengthRamp)
    idx=idx+1;
    idxStr = getTrialIndexString(idx);
    
    startLength = activeLengthRamp(i).lengths(1,1);
    if(activeLengthRamp(i).velocity > 0)
        type        = 'activeLengthening';
    else
        type        = 'activeShortening';
    end
    takePhoto   = '';
    blockName   = 'Pre-injury';
    fname       = getTrialNameUpd(seriesName,idx,type,startLength,dateId,'.pro');
    fnameLabels = getTrialNameUpd(seriesName,idx,type,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,type,startLength,takePhoto, blockName,fname,'');
    
       
    isRampActive=1;

    success = createLengthRampImpedanceTrial600A(...
                        isRampActive,...
                        activeLengthRamp(i),...
                        stochasticWaveSet,...
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfig);
      
end  



fclose(fidProtocol);
success=1;