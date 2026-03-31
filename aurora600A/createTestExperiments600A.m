function success = createTestExperiments600A( ...
                      settingsForceRampFV,...
                      projectFolders,...                                                                                                            
                      auroraConfig)


%%
% Characterization
%%
[codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders,'_ForceRamp');

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

characterizationFolders.codeDir         = codeDir;
characterizationFolders.codeLabelDir    = codeLabelDir;
characterizationFolders.dateId          = dateId;

idx = 1;
writeProtocolHeader = 1;


scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

%%
% Force-velocity using the force-ramp
%%

fvFields = fields(settingsForceRampFV);
numberOfFvTrials = length(fvFields);

for idxField = 1:1:numberOfFvTrials

    auroraConfigForceCommands = auroraConfig;

    auroraConfigForceCommands.useRelativeUnits=0;

    auroraConfigForceCommands.minimumNormalizedLength = 0.7;
    auroraConfigForceCommands.maximumNormalizedLength = 1.2;

    forceRampOptions=getCommandFunctionOptions600A('Force-Ramp',...
                                    auroraConfigForceCommands);
        
    settingsForceRamp.wait         = [1, 0]'.*scaleTime;
    settingsForceRamp.waitPostRamp = [1,15]'.*scaleTime;
    settingsForceRamp.force        = ...
        settingsForceRampFV.(fvFields{idxField}).normForce';
    settingsForceRamp.duration     = ...
        settingsForceRampFV.(fvFields{idxField}).duration' .* scaleTime;

    settingsForceRamp.type         = [fvFields{idxField},'ForceRamp'];
    
    idxUpd = find(settingsForceRamp.wait ...
                    < auroraConfigForceCommands.minimumWaitTime);
    
    settingsForceRamp.wait(idxUpd) = ...
            auroraConfigForceCommands.minimumWaitTime;
    
    settingsForceRamp.options      = forceRampOptions;  
        
    
    isRampActive=1;
    
    trialType = 'forceRampFV';
    startLength=settingsForceRampFV.(fvFields{idxField}).normLength;
    
    fname       = getTrialName('',idx,trialType,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName('',idx,trialType,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
        
    success = createForceRampTrial600A(...
                        isRampActive,...
                        settingsForceRamp,...               
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfigForceCommands);
        
    idxStr = getTrialIndexString(idx);
    takePhoto = '';
    blockName = '-';
    
    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,trialType,startLength,takePhoto, blockName,fname,'');    
    
    idx=idx+1;


end

fclose(fidProtocol);

