function success = constructPassiveRampImpedanceExperiments610A(...
                        dateId,...
                        stochasticWaves,...             
                        auroraConfig,...
                        expConfig,...
                        projectFolders)

  %%
  % Block of passive trials
  %%
  passiveLengths = expConfig.lengths;

  plotDir         = fullfile(projectFolders.output_plots,[dateId,'_610A']); 
  if(~exist(plotDir,'dir'))
    mkdir(plotDir);
  end

  codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
  if(~exist(plotDir,'dir'))
    mkdir(plotDir);
  end

  passiveDir         = fullfile(codeDir,'passive'); 
  if(~exist(passiveDir,'dir'))
    mkdir(passiveDir);
  end

  passiveDataDir         = fullfile(passiveDir,'data'); 
  if(~exist(passiveDataDir,'dir'))
    mkdir(passiveDataDir);
  end

  passiveProtocolDir         = fullfile(passiveDir,'protocols'); 
  if(~exist(passiveProtocolDir,'dir'))
    mkdir(passiveProtocolDir);
  end
  
  passiveLabelDir         = fullfile(passiveDir,'segmentLabels'); 
  if(~exist(passiveLabelDir,'dir'))
    mkdir(passiveLabelDir);
  end

  seriesName = 'passive';
  idxP=0;
  for i=1:1:length(passiveLengths)

    type = '';
    for j=1:1:length(stochasticWaves)
      if(j>1)
        type = [type,'_'];
      end
      type = [type,replace(stochasticWaves(j).controlFunction,' ','_')];
    end

    type = ['impedance_',type];


    lengthSineOptions = getCommandFunctionOptions610A(...
                          'Sine Wave','Length Out',auroraConfig);
    lengthSineOptions(1).value = expConfig.sineWave.frequency;
    lengthSineOptions(2).value = expConfig.sineWave.amplitude;
    lengthSineOptions(3).value = expConfig.sineWave.cycles;

    lengthRampConfig.lengths  = passiveLengths(i);
    lengthRampConfig.options = ...
      getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    idxP=idxP+1;
    idxStr = getTrialIndexString(idxP);
    
    endLength = passiveLengths(i);
    blockName   = 'PassiveImpedanceLength';
    fnameNoExt  = getTrialName(seriesName,idxP,type,endLength,...
                    auroraConfig.defaultLengthUnit, dateId,'');
    
    folderConfig.rootFolderPath = passiveDir;
    folderConfig.dataFolderName = 'data';
    folderConfig.protocolFolderName = 'protocols';
    folderConfig.blockLabelsFolderName = 'segmentLabels';

                     
    success = createSinglePassiveLengthRampImpedanceTrial610A(...
                    lengthRampConfig,...
                    lengthSineOptions,...
                    stochasticWaves,...
                    fnameNoExt,...                    
                    folderConfig,...
                    auroraConfig);
  end