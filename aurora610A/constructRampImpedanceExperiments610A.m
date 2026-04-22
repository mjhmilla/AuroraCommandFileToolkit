function trialId = constructRampImpedanceExperiments610A(...
                        seriesId,...
                        dateId,...
                        trialId,...
                        stochasticWaves,...             
                        auroraConfig,...
                        expConfig,...
                        expFolders,...
                        projectFolders)

  %%
  % Set up the experimental folders
  %%
  if(isempty(expFolders))
    rampImpedanceFolderName     = 'rampImpedance';
    dataFolderName        = 'data';
    protocolFolderName    = 'protocols';
    blockLabelsFolderName = 'segmentLabels';
  
    codeDir         = ...
      fullfile(projectFolders.output_code,[dateId,'_610A']); 
  
    if(~exist(codeDir,'dir'))
      mkdir(codeDir);
    end
  
    rampImpedanceDir         = ...
      fullfile(codeDir,rampImpedanceFolderName); 
  
    if(~exist(rampImpedanceDir,'dir'))
      mkdir(rampImpedanceDir);
    end
    
    rampImpedanceDataDir         = ...
      fullfile(rampImpedanceDir,dataFolderName); 
  
    if(~exist(rampImpedanceDataDir,'dir'))
      mkdir(rampImpedanceDataDir);
    end
    
    rampImpedanceProtocolDir         = ...
      fullfile(rampImpedanceDir,protocolFolderName); 
  
    if(~exist(rampImpedanceProtocolDir,'dir'))
      mkdir(rampImpedanceProtocolDir);
    end
    
    rampImpedanceLabelDir         = ...
      fullfile(rampImpedanceDir,blockLabelsFolderName);
  
    if(~exist(rampImpedanceLabelDir,'dir'))
      mkdir(rampImpedanceLabelDir);
    end
    
    expFolders.rootFolderPath         = rampImpedanceDir;
    expFolders.dataFolderName         = dataFolderName;
    expFolders.protocolFolderName     = 'protocols';
    expFolders.blockLabelsFolderName  = 'segmentLabels';
  end

  %%
  % Block of ramp trials
  %%

  seriesName = '';
  idxP=0;
  if(~isempty(trialId))
    idxP=trialId-1;
  end

  for i=1:1:length(expConfig.ramp.length)

%     type = '';
%     for j=1:1:length(stochasticWaves)
%       if(j>1)
%         type = [type,'_'];
%       end
%       type = [type,replace(stochasticWaves(j).controlFunction,' ','_')];
%     end
    if(isempty(expConfig.stochasticWaves.amplitudeSet))
      type = ['ramp_impedance'];
  
  
      idxP=idxP+1;
      idxStr = getTrialIndexString(idxP);
      
      endLength   = expConfig.ramp.length(i);
  
      blockName   = 'RampImpedanceLength';
  
      fnameNoExt  = getTrialName(seriesId,idxP,type,endLength,...
                      auroraConfig.defaultLengthUnit, dateId,'');
  
      expTrialConfig = expConfig;
  
      expTrialConfig.ramp.length = expConfig.ramp.length(i);      
      
      success = createRampImpedanceTrial610A(...                    
                      fnameNoExt,...  
                      stochasticWaves,...
                      auroraConfig,...
                      expTrialConfig,...                
                      expFolders);
    else

      ampScaleFields = {'overridePassiveAmplitude',...
                        'overrideActiveAmplitude',...
                        'scalePassiveAmplitude',...
                        'scaleActiveAmplitude'};     

      for j=1:1:length(expConfig.stochasticWaves.amplitudeSet)
        idxP=idxP+1;
        idxStr = getTrialIndexString(idxP);
        
        endLength   = expConfig.ramp.length(i);
        ampScale    = expConfig.stochasticWaves.amplitudeSet(j);
    
        ampStr = sprintf('%1.2f',ampScale*100);
        k = strfind(ampStr,'.');
        ampStr(k)='p';
        type = sprintf('%s_%s_amp','ramp_impedance',ampStr);

        fnameNoExt  = getTrialName(seriesId,idxP,type,endLength,...
                        auroraConfig.defaultLengthUnit, dateId,'');
    
        expTrialConfig = expConfig;
        
        for k=1:1:length(ampScaleFields)
          expTrialConfig.stochasticWaves.(ampScaleFields{k}) = ...
            expConfig.stochasticWaves.(ampScaleFields{k})*ampScale;
        end

        expTrialConfig.ramp.length = expConfig.ramp.length(i);      
        
        success = createRampImpedanceTrial610A(...                    
                        fnameNoExt,...  
                        stochasticWaves,...
                        auroraConfig,...
                        expTrialConfig,...                
                        expFolders);
        
      end
    end
  end

  trialId = idxP;