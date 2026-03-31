function success = createInjuryExperiments600A( settingsCharacterization,...
                                                settingsLengthRampInjury,...
                                                settingsForceRampInjury,...
                                                stochasticWaves,...
                                                projectFolders,...                                                                                                            
                                                auroraConfig)


%%
% Characterization
%%
[codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders,'_injury');

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

characterizationFolders.codeDir         = codeDir;
characterizationFolders.codeLabelDir    = codeLabelDir;
characterizationFolders.dateId          = dateId;

idxStart = 1;
writeProtocolHeader = 1;
idxEnd = createCharacterizationExperiments600A(...
                  '',...
                  'Pre-Injury',...
                  idxStart,...
                  settingsCharacterization,...
                  stochasticWaves,...
                  characterizationFolders,...
                  projectFolders,...
                  auroraConfig,...
                  fidProtocol,...
                  writeProtocolHeader);

idxStart=idxEnd+1;
writeProtocolHeader = 0;

%%
%Length-Ramp SSC Injury trial
%%
flag_useLengthRampInjury = settingsLengthRampInjury.enable;
flag_useForceRampInjury  = settingsLengthRampInjury.enable;

scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end


if(flag_useLengthRampInjury==1)
    lengthRampOptions=getCommandFunctionOptions600A('Length-Ramp',auroraConfig);
    
    stretchShortenRamp.wait         = [1,0,0]'.*scaleTime;
    stretchShortenRamp.waitPostRamp = [1,0,15]'.*scaleTime;
    stretchShortenRamp.lengths      = settingsLengthRampInjury.normLengths';
    stretchShortenRamp.lengthChange = [0,diff(settingsLengthRampInjury.normLengths)]';
    stretchShortenRamp.velocity     = ...
        settingsLengthRampInjury.normVelocity'...
        .*auroraConfig.maximumRampSpeedInDefaultUnits;
    stretchShortenRamp.duration     =   stretchShortenRamp.lengthChange...
                                        ./ stretchShortenRamp.velocity;
    stretchShortenRamp.duration(1,1) = 1*scaleTime;
    stretchShortenRamp.type         = 'Stretch-Shorten-Cycle-Length';
    
    idxUpd = find(stretchShortenRamp.wait < auroraConfig.minimumWaitTime);
    stretchShortenRamp.wait(idxUpd) = auroraConfig.minimumWaitTime;
    
    stretchShortenRamp.options      = lengthRampOptions;  
        
    
    isRampActive=1;
    
    trialType = 'injuryLengthSSC';
    startLength=settingsLengthRampInjury.normLengths(1,1);
    fname       = ...
        getTrialName('',idxStart,trialType,startLength,...
                        auroraConfig.defaultLengthUnit, dateId,'.pro');
    fnameLabels = ...
        getTrialName('',idxStart,trialType,startLength,...
                        auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    auroraConfigInjury=auroraConfig;
    maxLengthInjurySSC=max([max(stretchShortenRamp.lengths+0.1),...
                             auroraConfig.maximumNormalizedLength]);

    auroraConfigInjury.maximumNormalizedLength=maxLengthInjurySSC;
    
    success = createLengthRampTrial600A(...
                        isRampActive,...
                        stretchShortenRamp,...               
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfigInjury);
        
    idxStr = getTrialIndexString(idxStart);
    takePhoto = '';
    blockName = 'Injury';

    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,trialType,startLength,takePhoto, blockName,fname,...
            'Hold on to your butt ...');    

    idxStart=idxStart+1;

end


if(flag_useForceRampInjury==1)

    auroraConfigForceCommands = auroraConfig;
    auroraConfigForceCommands.useRelativeUnits=0;

    forceRampOptions=getCommandFunctionOptions600A('Force-Ramp',...
                                    auroraConfigForceCommands);
        
    settingsForceRampInjury.wait         = [1,0,0]'.*scaleTime;
    settingsForceRampInjury.waitPostRamp = [1,0,15]'.*scaleTime;
    settingsForceRampInjury.force        = settingsForceRampInjury.normForce';
    %settingsForceRampInjury.forceChange  = [0,diff(settingsForceRampInjury.normForce)]';
    settingsForceRampInjury.duration     = settingsForceRampInjury.duration';
    settingsForceRampInjury.type         = 'Stretch-Shorten-Cycle-Force';
    
    idxUpd = find(settingsForceRampInjury.wait ...
                    < auroraConfigForceCommands.minimumWaitTime);
    
    settingsForceRampInjury.wait(idxUpd) = ...
            auroraConfigForceCommands.minimumWaitTime;
    
    settingsForceRampInjury.options      = forceRampOptions;  
        
    
    isRampActive=1;
    
    trialType = 'injuryForceSSC';
    startLength=settingsLengthRampInjury.normLengths(1,1);

    fname       = getTrialName('',idxStart,trialType,startLength,...
                    auroraConfig.defaultLengthUnit,dateId,'.pro');
    fnameLabels = getTrialName('',idxStart,trialType,startLength,...
                    auroraConfig.defaultLengthUnit,[dateId,'_labels'],'.csv');
    
    
    success = createForceRampTrial600A(...
                        isRampActive,...
                        settingsForceRampInjury,...               
                        fullfile(codeDir,fname),...
                        fullfile(codeLabelDir,fnameLabels),...
                        auroraConfigForceCommands);
        
    idxStr = getTrialIndexString(idxStart);
    takePhoto = '';
    blockName = 'Injury';

    fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
        idxStr,trialType,startLength,takePhoto, blockName,fname,'Hold on to your butt ...');    

    idxStart=idxStart+1;

end

%%
% Characterization
%%

idxEnd = createCharacterizationExperiments600A(...
                  '',...
                  'Post-Injury',...
                  idxStart,...
                  settingsCharacterization,...
                  stochasticWaves,...
                  characterizationFolders,...
                  projectFolders,...
                  auroraConfig,...
                  fidProtocol,...
                  writeProtocolHeader);

fclose(fidProtocol);