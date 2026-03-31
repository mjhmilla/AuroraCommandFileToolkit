function indexEnd = createStretchShorteningTrial600A(  ...
                        isRampActive,...
                        shortLength,...               
                        trialFileFullPath,...
                        trialBlockLabelFullPath,...
                        auroraConfig)


%seriesName = 'injury';
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


stretchShortenRamp(2) = struct('wait',0,'waitPostRamp',0,...
                    'lengths',[0,0],'lengthChange',0,...
                    'velocity',0,'duration',0,'options',[],'type','');

i=1;
stretchShortenRamp(i).wait         = 1.*scaleTime;
stretchShortenRamp(i).waitPostRamp = 0;
stretchShortenRamp(i).lengths      = [1.0, 1.8];
stretchShortenRamp(i).lengthChange = diff(stretchShortenRamp(i).lengths);
stretchShortenRamp(i).velocity     = [(1/3)].*auroraConfig.maximumRampSpeedInDefaultUnits;
stretchShortenRamp(i).duration     = stretchShortenRamp(i).lengthChange ./ stretchShortenRamp(i).velocity;
stretchShortenRamp(i).options      = lengthRampOptions;  
stretchShortenRamp(i).type         = 'Active-Stretch';

i=2;
stretchShortenRamp(i).wait         = 0;
stretchShortenRamp(i).waitPostRamp = 15*scaleTime;
stretchShortenRamp(i).lengths      = [1.8, 1.0];
stretchShortenRamp(i).lengthChange = diff(stretchShortenRamp(i).lengths);
stretchShortenRamp(i).velocity     = [-(1/3)].*auroraConfig.maximumRampSpeedInDefaultUnits;
stretchShortenRamp(i).duration     = stretchShortenRamp(i).lengthChange ./ stretchShortenRamp(i).velocity;
stretchShortenRamp(i).options      = lengthRampOptions;  
stretchShortenRamp(i).type         = 'Active-Shorten';

%%
%Make the output folders, if necessary
%%
[codeDir, codeLabelDir] = getTrialDirectories(projectFolders);

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
type        = 'isometric';
takePhoto   = 'Yes';
blockName   = 'Pre-injury';
fname       = getTrialName(seriesName,idx,type,startLength,...
                auroraConfig.defaultLengthUnit,dateId,'.pro');
fnameLabels = getTrialName(seriesName,idx,type,startLength,...
                auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');


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
    fname       = getTrialName(seriesName,idx,type,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
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
    fname       = getTrialName(seriesName,idx,type,startLength, ...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,type,startLength, ...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
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
    fname       = getTrialName(seriesName,idx,type,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,type,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
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



%fclose(fidProtocol);
indexEnd = index;