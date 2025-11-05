function indexEnd = createImpedanceForceLengthExperiments600A_v01(...
                        indexStart,...
                        isActive,...
                        seriesName,...
                        blockName,...
                        settingsImpedance,...
                        stochasticWaveSet,...
                        writeProtocolHeader,...
                        projectFolders,...                                                                                                            
                        auroraConfig)

[codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders,'_impedance');

fidProtocol = [];

if(writeProtocolHeader==1)
    fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');
    
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
else
    fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'a');
end

assert(length(stochasticWaveSet)==1,...
    'Error: stochasticWaveSet should only have one element');
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
idx=indexStart;
for i=1:1:nIsometric

    idxStr = getTrialIndexString(idx);
    
    startLength = isometric(i).length;
    takePhoto   = '';
    fname       = getTrialName(seriesName,idx,blockName,startLength,dateId,'.pro');
    fnameLabels = getTrialName(seriesName,idx,blockName,startLength,[dateId,'_labels'],'.csv');
    
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,seriesName,startLength,takePhoto, blockName,fname,'');

    auroraConfigIso = auroraConfig;
    auroraConfigIso.bath.activationDuration = isometric(i).activationDuration;

    fid = fopen(fullfile(codeDir, fname),'w');
    fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');


    %%
    % 0. Write the preamble
    %%
    
    lineCount=0;
    [startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);

    %%
    % 1. Activate if necessary
    %%
    if(isActive==1)
        [endTime, lineCount] = ...
            writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
        
        endActivation = endTime + auroraConfig.bath.activationDuration;
        
        fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
        fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
        
        startTime = endActivation;
        lineCount = lineCount+1;

    end    

    %%
    % 2. Write the wave 
    %%

    waveDir = fullfile(codeDir, 'wave');
    if(exist(waveDir)==0)
        mkdir(waveDir);
    end   
    
    larbFileName = ['merged_larb_',num2str(i),'_',dateId,'.dat'];
    larbOptions = stochasticWaveSet.options;
    larbOptions(1).value=i;

    [endTime, lineCount] =  writeLarbBlock600A(...
                              fid,...                                      
                              startTime,...
                              startLength,...
                              waveDir,...
                              larbFileName,...
                              stochasticWaveSet.fileData,...
                              larbOptions,...
                              stochasticWaveSet.metadata,...
                              lineCount,...
                              auroraConfig);
    fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
        stochasticWaveSet.type,startTime,endTime);            
    startTime = endTime + auroraConfig.minimumWaitTime;  

    %%
    % 3. Deactivate if necessary
    %%
    if(isActive==1)

        [endTime, lineCount] = ...
            writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);
        
        startTime=endTime+auroraConfig.minimumWaitTime;            
    end
    
    %%
    % End the trial
    %%
    [endTime, lineCount] = ...
        writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);
    
    success = 1;
    assert(lineCount < auroraConfig.maximumNumberOfCommands,...
        'Error: maximumNumberOfCommandsExceeded');
    
    idx = idx+1;    
    fclose(fid);
    fclose(fidLabel);    
end
fclose(fidProtocol);

indexEnd = idx;