clc;
close all;
clear all;

%disp('Update script to take in measured parameters: lceOptMM, fceMax, lpeHalf, fpeHalf')

%% 66 50 LR.: 10N max
% Folders
%%
fprintf('\nPhase 1 Updates');
fprintf('\n Get all functions to work with the updated auroraConfig and expConfig structs');

fprintf('\nPhase 2 updates');
fprintf('\n Update writeControlFunction command to return the meta-data struct');
fprintf('\n Append this struct into the array (perhaps write a function for this)');
fprintf('\n Write a function to create the meta data struct');
fprintf('\n Update all other functions to use this format and reduce the boiler plate\n\n');


rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.aurora610A);
addpath(projectFolders.postprocessing);
addpath(projectFolders.common);
addpath(projectFolders.experiments);
addpath(projectFolders.signals);

%
% Configurations for often used functions
%

dateIdOverride                  = [];

verbose     = 1;

muscleName  ='EDL';
temperatureC= 22;

lceOptMM_measured = [];
vceOptMM_measured = [];

sampleFrequency       = 1000;
sampleFrequencyRecovery=100;
sampleFrequencyTwitch = 4000; %2026/05/22: Twitches must be 0.25 ms, and so, 
                              %            a higher sample rate is needed
                              %            to record these signals
durationRecoveryS=30;
amplitudeMM      = 1;
                 
%
% Generate configuration structs
%

configTiming   = getPropertiesTiming610A( sampleFrequency,...
                                          sampleFrequencyRecovery,...
                                          sampleFrequencyTwitch,...
                                          verbose);
configMuscle   = getPropertiesMuscle610A( muscleName,...
                                          temperatureC,...
                                          lceOptMM_measured, ...
                                          vceOptMM_measured, verbose);
configTetanus  = getPropertiesTetanus610A(configMuscle,...
                                          configTiming,verbose);
configTwitch   = getPropertiesTwitch610A( configTiming,verbose);
configRecovery = getPropertiesRecovery610A(durationRecoveryS,...
                                           amplitudeMM,verbose);
configRelax = getPropertiesPassiveForceRelaxation610A(verbose);

configPositioning = getPropertiesPositioning610A(verbose);

%
% Sequence settings
%
experimentComputerFolder=...
  'C:\Users\Administrator.ASI601A-AHQNPTB\Desktop\skeletal_muscle\';


%
% Aurora configurationconfigTetanus.timeToReachMaxActivation
%
disp('auroraConfig.default');
auroraConfig.default = getDefaultAuroraConfiguration610A(...
                        configTiming.sampleFrequency,...    
                        configMuscle.lceOptMM,...
                        configMuscle.vceMaxLPS,...
                        verbose);

disp('auroraConfig.recovery');
auroraConfig.recovery = getDefaultAuroraConfiguration610A(...
                        configTiming.sampleFrequencyRecovery,...    
                        configMuscle.lceOptMM,...
                        configMuscle.vceMaxLPS,...
                        verbose);

disp('auroraConfig.twitch');
auroraConfig.twitch = getDefaultAuroraConfiguration610A(...
                    configTiming.sampleFrequencyTwitch,...    
                    configMuscle.lceOptMM,...
                    configMuscle.vceMaxLPS,...
                    verbose);

%%
% Configure the experiment
%%

flag_plateauSearchProtocol    =0;
flag_forceFrequencyProtocol   =0;
flag_degradationProtocol      =0;
flag_FLRProtocol              =0;
flag_rampImpededanceProtocol  =0;

flag_preInjuryProtocol        = 1;
flag_injuryRampProtocol       = 1;
flag_postInjuryProtocol       = 1;


flag_impedanceCalibrationProtocol = 0;

%
% Stochastic wave settings
%
flag_generateRandomSignal         = 0;
flag_fitPerturbationPowerSpectrum = 1;
stochasticWaveScalesToTest        = [1];
stochasticWaveSetType             = 7; %only step waves;

perturbationLengthMM              = 0.125;
perturbationBandwidth             = [2, 90]; %Only 2/3 of the upper bandwidth
                                             %will be realized
perturbationDuration = [0.5,2];


settingsImpedance.createMultiTemperatureProtocol = 0;
settingsImpedance.amplitude_mm                   = 0.125;
settingsImpedance.addRampAtStart                 = 1;
settingsImpedance.waveAmplitudeStudy             = 0;

if(strcmp(configMuscle.name,'CAL'))
  settingsImpedance.amplitude_mm=2;
end

%
% Perturbation wave settings
%
pointsPower   = round(log2(configTiming.sampleFrequency.*perturbationDuration));
pointsSet     = 2.^(pointsPower);
unitSystem    = 'mm_mN_s_Hz'; %Alternative: 'mm_mN_s_Hz'

assert(strcmp(unitSystem,'Ref_s_Hz')==0, ...
   ['Error: Cannot use Ref_s_Hz because this unit system does not work',...
    ' properly on the 1200A']);



flag_plotRandomSignal       = 1 && flag_generateRandomSignal;


%%
% File name dateId identifier
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

if(~isempty(dateIdOverride))
  dateId = dateIdOverride;
end

%%
% Plot Configuration
%%

plotDir         = fullfile(projectFolders.output_plots,[dateId,'_610A']); 
if(~exist(plotDir,'dir'))
  mkdir(plotDir);
end


plotConfig.numberOfHorizontalPlotColumns    = 2;
plotConfig.numberOfVerticalPlotRows         = 1;
plotConfig.plotWidth                        = 8;
plotConfig.plotHeight                       = 6;
plotConfig.plotHorizMarginCm                = 2;
plotConfig.plotVertMarginCm                 = 2;
plotConfig.baseFontSize                     = 10;

[subplotPanel_1R2C,plotConfig_1R2C]=plotConfigGeneric(plotConfig);


plotConfig.numberOfHorizontalPlotColumns    = 1;
plotConfig.numberOfVerticalPlotRows         = 2;
plotConfig.plotWidth                        = 18;
plotConfig.plotHeight                       = 6;

[subplotPanel_2R1C,plotConfig_2R1C]=plotConfigGeneric(plotConfig);

plotConfig.numberOfHorizontalPlotColumns    = 1;
plotConfig.numberOfVerticalPlotRows         = 3;
plotConfig.plotWidth                        = 18;
plotConfig.plotHeight                       = 6;

[subplotPanel_3R1C,plotConfig_3R1C]=plotConfigGeneric(plotConfig);

%%
% Exp Config
%%
%expConfig = getDefaultExperimentConfiguration610A();



%%
% Perturbation settings
%%

perturbation(length(pointsSet)) = ...
  struct('magnitude',[],'bandwidth',[],'unit',[],'points',[]);

for i=1:1:length(pointsSet)

  perturbation(i).magnitude = perturbationLengthMM;
  perturbation(i).bandwidth = perturbationBandwidth;
  perturbation(i).unit      = 'mm';
  perturbation(i).points    = pointsSet(i);
          
  assert(strcmp(auroraConfig.default.unitSystem,'mm_mN_s_Hz'));
  if(perturbation(i).magnitude > 0.25)
    disp(['Warning: Perturbation magnitude > 0.25mm, expect low coherence']);
  end
end

%%
% System identification perturbation signal configuration
%%
waveConfig(3) = struct('name','','commandFunctionName','');

waveConfig(1).name = 'Step';
waveConfig(1).commandFunctionName = 'Step';

waveConfig(2).name = 'Ramp';
waveConfig(2).commandFunctionName = 'Ramp';

waveConfig(3).name = 'Sine';
waveConfig(3).commandFunctionName = 'Sine Wave';


if(flag_generateRandomSignal==1)
    figPerturbation=figure;
    for idxWave = 1:1:length(waveConfig)

      waveName = waveConfig(idxWave).name;      
      waveNameLC = lower(waveName);

      commandFunctionName = waveConfig(idxWave).commandFunctionName;      
      
      verbose=1;

  
      perturbationPlotConfig.subplot= subplotPanel_3R1C;
      perturbationPlotConfig.config = plotConfig_3R1C;    
  
      preconditioningWave(length(perturbation)) ...
        = struct('signal',[],'config',[],'controlFunctions',[]);
  
      stochasticWave(length(perturbation)) ...
        = struct('signal',[],'config',[], 'controlFunctions',[]);
      
      for idxP = 1:1:length(perturbation)
        preconditioningWave(idxP) = ...
          struct('signal',[],'config',[],'controlFunctions',[]);
        stochasticWave(idxP)      =...
          struct('signal',[],'config',[], 'controlFunctions',[]);
      end
  
      for idxP = 1:1:length(perturbation)
        assert(strcmp(perturbation(idxP).unit,...
                      auroraConfig.default.defaultLengthUnit),...
            ['Error: perturbation unit and the defaultLengthUnit must',...
             'match']);
    
        configStochasticWave = getPerturbationConfiguration610A(...
                                 perturbation(idxP).magnitude,...
                                 perturbation(idxP).bandwidth,...
                                 perturbation(idxP).points,...
                                 flag_fitPerturbationPowerSpectrum,...
                                 auroraConfig.default);
    
        commandFunctionOption = getCommandFunctionOptions610A(...
                          commandFunctionName,'Length Out',auroraConfig.default);
    
        [preconditioningWave(idxP), ...
         stochasticWave(idxP), ...    
         figPerturbation] = ...
          createPerturbationWave610A(...
                  commandFunctionName,...
                  commandFunctionOption,...
                  configStochasticWave,...
                  auroraConfig.default, ...
                  figPerturbation,...
                  perturbationPlotConfig,...
                  verbose);
  
        saveas(figPerturbation,...
               fullfile(plotDir,...
               sprintf('fig_random%sWave_%i',waveName,idxP)),'pdf');
        savefig(figPerturbation,...
                fullfile(plotDir,...
                sprintf('fig_random%sWave_%i.fig',waveName,idxP)));  
  
        clf(figPerturbation);
      
      end
      
      stochasticWaveNewName=sprintf('%sStochasticWave',waveNameLC);
      assignin('base',stochasticWaveNewName,stochasticWave);

      preconditioningWaveNewName=sprintf('%sPreconditioningWave',waveNameLC);
      assignin('base',preconditioningWaveNewName,preconditioningWave);


      save(fullfile(projectFolders.output_structs,...
           [stochasticWaveNewName,'.mat']),...
           stochasticWaveNewName,'-mat');        
      save(fullfile(projectFolders.output_structs,...
           [preconditioningWaveNewName,'.mat']),...
           preconditioningWaveNewName,'-mat');         

    end

else

  for idxWave = 1:1:length(waveConfig)
    waveName = waveConfig(idxWave).name;
    waveNameLC = lower(waveName);

    load(fullfile(projectFolders.output_structs,...
      sprintf('%sStochasticWave.mat',waveNameLC)));
    load(fullfile(projectFolders.output_structs,...
      sprintf('%sPreconditioningWave.mat',waveNameLC)));
    
  end

end


%
% Package the stochastic waves into the set that will 
% be applied to the specimen
%

switch stochasticWaveSetType
    case 1
        waveSet = {'rampPreconditioningWave','rampStochasticWave',...
                   'sinePreconditioningWave','sineStochasticWave'};        
    case 2
        waveSet = {'sineStochasticWave'};  
    case 3
        waveSet = {'rampStochasticWave'};      
    case 4
        waveSet = {'rampStochasticWave','sineStochasticWave'};  
    case 5
        waveSet = {'stepStochasticWave',...
                   'sinePreconditioningWave',...
                   'sineStochasticWave'};          
    case 6
        waveSet = {'stepStochasticWave',...
                   'sineStochasticWave'}; 
    case 7
        waveSet = {'stepStochasticWave'};
    otherwise
        assert(0,'Error: stochasticWaveSetType incorrectly set');
end

controlFields = {'controlFunction','waitDuration','optionValues','options'};
lineCountStochastic = 0;

disp('Including stochastic waves:');

numberOfWaves=0;
for i=1:1:length(waveSet)
    switch waveSet{i}
        case 'stepPreconditioningWave'
            numberOfWaves = numberOfWaves  ...
              + length(stepPreconditioningWave);  
        case 'stepStochasticWave'
            numberOfWaves = numberOfWaves  ...
              + length(stepStochasticWave);        
        case 'rampPreconditioningWave'
            numberOfWaves = numberOfWaves  ...
              + length(rampPreconditioningWave);  
        case 'rampStochasticWave'
            numberOfWaves = numberOfWaves  ...
              + length(rampStochasticWave);  
        case 'sinePreconditioningWave'
            numberOfWaves = numberOfWaves  ...
              + length(sinePreconditioningWave);           
        case 'sineStochasticWave'
            numberOfWaves = numberOfWaves  ...
              + length(sineStochasticWave); 
        otherwise
            assert(0,'Error: waveSet set incorrectly');
    end
end

stochasticWaves(numberOfWaves)...
    =struct('controlFunction',[],'waitDuration',[],...
            'optionValues',[],'options',[],'type','');

idx=0;
for i=1:1:length(waveSet)
    wave= [];
    typeName = '';
    fprintf('\t%s\n',waveSet{i});
    switch waveSet{i}
        case 'stepPreconditioningWave'
            wave = stepPreconditioningWave;  
            typeName = 'Preconditioning-Length-Step';          
        case 'stepStochasticWave'
            wave = stepStochasticWave;
            typeName = 'Stochastic-Length-Step';
        case 'rampPreconditioningWave'
            wave = rampPreconditioningWave;  
            typeName = 'Preconditioning-Length-Ramp';          
        case 'rampStochasticWave'
            wave = rampStochasticWave;
            typeName = 'Stochastic-Length-Ramp';
        case 'sinePreconditioningWave'
            wave = sinePreconditioningWave;
            typeName = 'Preconditioning-Length-Sine-Wave';
        case 'sineStochasticWave'
            wave = sineStochasticWave;
            typeName = 'Stochastic-Length-Sine-Wave';
        otherwise
            assert(0,'Error: waveSet set incorrectly');
    end
    for j = 1:1:length(wave)
      idx=idx+1;
      for k=1:1:length(controlFields)    
          stochasticWaves(idx).(controlFields{k}) = ...
              wave(j).controlFunctions.(controlFields{k});
      end
      stochasticWaves(idx).type = typeName;
      stochasticWaves(idx).config=wave(j).config;    
  
      lineCountStochastic = lineCountStochastic ...
          + size(wave(j).controlFunctions.optionValues,1);

      assert(size(wave(j).controlFunctions.optionValues,1) ...
           < (auroraConfig.default.maximumNumberOfCommands + 40),...
        'Error: the number of perturbation commands in this perturbation is too high');      
    end
end




%%
% Generate the experiment folder structure
%%

dataFolderName        = 'data';
protocolFolderName    = 'protocols';
blockLabelsFolderName = 'segmentLabels';
sequenceMetaData      = 'sequenceMetaData';


codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
if(~exist(codeDir,'dir'))
  mkdir(codeDir);
end

dataDir         = fullfile(codeDir,dataFolderName); 
if(~exist(dataDir,'dir'))
  mkdir(dataDir);
end

protocolDir     = fullfile(codeDir,protocolFolderName); 
protocolLocalDir= fullfile([dateId,'_610A'],protocolFolderName);
if(~exist(protocolDir,'dir'))
  mkdir(protocolDir);
end

labelDir = fullfile(codeDir,blockLabelsFolderName); 
if(~exist(labelDir,'dir'))
  mkdir(labelDir);
end


expFolders.rootFolderPath         = codeDir;
expFolders.dataFolderName         = dataFolderName;
expFolders.protocolFolderName     = protocolFolderName;
expFolders.blockLabelsFolderName  = blockLabelsFolderName;
expFolders.sequenceMetaData       = sequenceMetaData;

%%
% Generate the protocols
%%
trialId = 1;
sequenceId = 1;

if(flag_plateauSearchProtocol==1)  
  if(verbose==1)
    fprintf('createPlateauSearchTrial610A\n');
  end

  plateauConfig.muscle = configMuscle;
  plateauConfig.timing = configTiming;
  plateauConfig.twitch = configTwitch;
  plateauConfig.relax = configRelax;

  plateauConfig.ramp.waitTime       = 1;
  plateauConfig.ramp.lengths        = [-3:1:3]';
  plateauConfig.ramp.duration       = 5;
  
  trialIdStart=trialId;
  flag_isASequence=0;
  
  trialId = createPlateauSearchTrial610A(...
                        [],...
                        dateId,...
                        trialId,...
                        sequenceId,...
                        auroraConfig,...
                        plateauConfig,...
                        expFolders,...
                        projectFolders,...
                        flag_isASequence);  

  sequenceId=sequenceId+1;

end

if(flag_forceFrequencyProtocol==1)

  if(verbose==1)
    fprintf('createForceFrequencyTrials610A\n');
  end

  ffrConfig.muscle    = configMuscle;
  ffrConfig.timing     = configTiming;
  ffrConfig.tetanus   = configTetanus;
  ffrConfig.recovery  = configRecovery;

  %Make sure the duty cycle less than 50% (for no apparent reason)
  assert(configTetanus.pulseWidth*0.001 ...
         < 0.5/max(ffrConfig.tetanus.pulseFrequency));  
  
  %Make sure the ADC is running fast enough to record the pulses
  assert((1/auroraConfig.default.analogToDigitalSampleRateHz) ...
                < (configTetanus.pulseWidth/1000));

  ffrConfig.tetanus.pulseFrequency = [50,100,200,300,400,500];
  ffrConfig.tetanus.duration       = configTetanus.timeToReachMaxActivation*2;
  ffrConfig.tetanus.sampleFrequency= configTiming.sampleFrequency;
  ffrConfig.waitTime       =1;

  flag_isASequence=0; 

  trialId = createForceFrequencyTrials610A(...
                      dateId,...
                      trialId,...                      
                      sequenceId,...
                      auroraConfig,...
                      ffrConfig,...   
                      expFolders,...
                      projectFolders);

  sequenceId=sequenceId+1;
end



if(flag_degradationProtocol==1)


  degradationConfig.muscle    = configMuscle;
  degradationConfig.timing    = configTiming;
  degradationConfig.recovery  = configRecovery;
  degradationConfig.tetanus   = configTetanus;

  degradationConfig.exp.numberOfTrials      = [10,10];
  degradationConfig.exp.stimulationDuration = [1,0.25];

  

  [trialId,degradationFolders]= constructDegradationExperiment610A(...
                                  dateId,...
                                  trialId,...
                                  sequenceId,...
                                  auroraConfig,...                                  
                                  degradationConfig,...
                                  expFolders,...
                                  projectFolders);   
  sequenceId=sequenceId+1;


  [protocolPath,sequenceName] = fileparts(degradationFolders.protocolFolderName);
  protocolLocalDirWindows = strrep(protocolLocalDir,'/','\');

  degradationSequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  degradationSequenceSettings.baseFile = [dateId,'_degradation_610A'];
  degradationSequenceSettings.isTimed = 1;
  degradationSequenceSettings.delayTime =0;
  degradationSequenceSettings.repeats   =0;
  degradationSequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
    fullfile(degradationFolders.rootFolderPath,...
             degradationFolders.protocolFolderName),...
    degradationSequenceSettings)  ;
end

if(flag_impedanceCalibrationProtocol==1)


  settingsImpedanceCalibration.timing = configTiming;

  settingsImpedanceCalibration.amplitudeMM = 4; %peak-to-peak 
  settingsImpedanceCalibration.amplitudeN  = 0.1;

  freqSample = [sqrt(2/100):0.1:1]';
  settingsImpedanceCalibration.frequencyHz = (freqSample.^2)*100;

  settingsImpedanceCalibration.perturbation.bandwidthHz  = ...
      [1,100];
  settingsImpedanceCalibration.perturbation.points = ...
      2.^round(log2(configTiming.sampleFrequency.*4));

  settingsImpedanceCalibration.perturbation.amplitudeMM = ...
      settingsImpedanceCalibration.amplitudeMM;


  success= createCalibrationImpedanceTrial610A(...                    
                    dateId,...                      
                    auroraConfig.default,...
                    settingsImpedanceCalibration,...                    
                    expFolders,...
                    plotConfig);
  sequenceId=sequenceId+1;



end



if(flag_FLRProtocol==1)

  flrConfig.muscle    = configMuscle;
  flrConfig.recovery  = configRecovery;
  flrConfig.tetanus   = configTetanus;
  flrConfig.timing    = configTiming;

  %flrConfig.waitTime = 1;  
  %flrConfig.stopWaitTime = 5;
  %flrConfig.temperature = muscleTemperature;

  
  flrConfig.ramp.velocity = 1; 
  flrConfig.ramp.waitTime = 1;
  flrConfig.ramp.length   = [0,-3,3,-2,2,0,-1,1,-4,4,0];  
  flrConfig.ramp.duration = abs(flrConfig.ramp.length./flrConfig.ramp.velocity);
  flrConfig.ramp.duration = max(flrConfig.ramp.duration,0.1);

  %Activations settings
  %flrConfig.tetanus = config
  %flrConfig.tetanus.waitTime       = 5;
  %flrConfig.tetanus.initialDelay   = 0;
  %flrConfig.tetanus.pulseFrequency = pulseFrequency;
  %flrConfig.tetanus.pulseWidth     = configTetanus.pulseWidth;
  %flrConfig.tetanus.durationExtension = 0.5;
  %flrConfig.tetanus.duration       = ;

 
  %This is the relaxation sine wave between trials
  %flrConfig.sineWave.waitTime  = 10;
  %flrConfig.sineWave.frequency = 1;
  %flrConfig.sineWave.amplitude = sineWaveRecoveryAmplitude;
  %flrConfig.sineWave.cycles    = ...
  %flrConfig.sineWave.frequency*sineWaveRecoveryDurationS;
  %flrConfig.sineWave.sampleFrequency = 100;
  %flrConfig.muscleName  =muscleName;
  %flrConfig.unitSystem  =unitSystem;
  %flrConfig.lceOptMM    =lceOptMM;
  %flrConfig.vceMaxLPS   =vceMaxLPS;

  [trialId, flrFolders]= constructForceLengthRelationshipExperiment610A(...
                          dateId,...
                          trialId,...
                          sequenceId,...
                          auroraConfig,...
                          flrConfig,...
                          expFolders,...
                          projectFolders);  
  sequenceId=sequenceId+1;

  [protocolPath,sequenceName] = fileparts(flrFolders.protocolFolderName);
  protocolLocalDirWindows = strrep(protocolLocalDir,'/','\');

  flrSequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  flrSequenceSettings.baseFile = [dateId,'_flr_610A'];
  flrSequenceSettings.isTimed = 1;
  flrSequenceSettings.delayTime =0;
  flrSequenceSettings.repeats   =0;
  flrSequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
            fullfile(flrFolders.rootFolderPath,...
                     flrFolders.protocolFolderName),...
                     flrSequenceSettings)  ;

end

if(flag_rampImpededanceProtocol==1)  

  rampImpConfig.muscle    = configMuscle;
  rampImpConfig.recovery  = configRecovery;
  rampImpConfig.timing    = configTiming;
  rampImpConfig.tetanus   = configTetanus;
  rampImpConfig.relax     = configRelax;

  %trialId=1;

  switch configMuscle.name
    case 'EDL'
      rampImpConfig.isStochasticWaveActive = [1,0];
    case 'SOL'
      rampImpConfig.isStochasticWaveActive = [1,0];
    case 'CAL'
      rampImpConfig.isStochasticWaveActive = [0,0];
    otherwise
      assert(0,'Error: unrecognized muscle name');
  end

  %rampImpConfig.stopWaitTime = 5;
  %rampImpConfig.temperature = muscleTemperature;

  rampImpConfig.ramp.waitTime = 1;
  rampImpConfig.ramp.length = [0];  
  rampImpConfig.ramp.duration = 1;


  if(settingsImpedance.addRampAtStart==1)
    rampImpConfig.ramp.waitTime = 1;
    rampImpConfig.ramp.length = [0:1:4]';  
    rampImpConfig.ramp.duration = 1;
  end

  %This is the relaxation sine wave between trials

  %rampImpConfig.sineWave.waitTime  = 1;
  %rampImpConfig.sineWave.frequency = 1;
  %rampImpConfig.sineWave.amplitude = sineWaveRecoveryAmplitude;
  %rampImpConfig.sineWave.cycles    = ...
  %rampImpConfig.sineWave.frequency*sineWaveRecoveryDurationS;
  %rampImpConfig.sineWave.sampleFrequency = 100;
  %rampImpConfig.muscleName  =muscleName;
  %rampImpConfig.unitSystem  =unitSystem;
  %rampImpConfig.lceOptMM    =lceOptMM;
  %rampImpConfig.vceMaxLPS   =vceMaxLPS;

  %This sine wave brings the passive force more quickly to a static
  %value
  rampImpConfig.sineWaveEqualization.waitTime  = 10;
  rampImpConfig.sineWaveEqualization.frequency = 20;
  rampImpConfig.sineWaveEqualization.amplitude = 1;
  rampImpConfig.sineWaveEqualization.cycles    = ...
  rampImpConfig.sineWaveEqualization.frequency*5;

  %rampImpConfig.tetanus.waitTime       = 1;
  %rampImpConfig.tetanus.initialDelay   = 0;
  %rampImpConfig.tetanus.pulseFrequency = pulseFrequency;
  %rampImpConfig.tetanus.pulseWidth     = configTetanus.pulseWidth;
  %rampImpConfig.tetanus.duration       = nan;
  %rampImpConfig.tetanus.durationExtension = 0.5;

  rampImpConfig.stochasticWaves.waitTime                 = 5;
  rampImpConfig.stochasticWaves.timeToReachMaxActivation = ...
      configTetanus.timeToReachMaxActivation;

  switch configMuscle.name
    case 'EDL'
      rampImpConfig.stochasticWaves.amplitudeSet             = [1];
      rampImpConfig.stochasticWaves.overridePassiveAmplitude = 0.125;
      rampImpConfig.stochasticWaves.overrideActiveAmplitude  = 0.125;
      rampImpConfig.stochasticWaves.scalePassiveAmplitude    = [];
      rampImpConfig.stochasticWaves.scaleActiveAmplitude     = [];  
      
    case 'SOL'
      rampImpConfig.stochasticWaves.amplitudeSet             = [1];
      rampImpConfig.stochasticWaves.overridePassiveAmplitude = 0.125;
      rampImpConfig.stochasticWaves.overrideActiveAmplitude  = 0.125;
      rampImpConfig.stochasticWaves.scalePassiveAmplitude    = [];
      rampImpConfig.stochasticWaves.scaleActiveAmplitude     = [];  
      
    case 'CAL'
      rampImpConfig.sineWave.waitTime                        = 1;
      rampImpConfig.stochasticWaves.amplitudeSet             = [1];
      rampImpConfig.stochasticWaves.overridePassiveAmplitude = settingsImpedance.amplitude_mm;
      rampImpConfig.stochasticWaves.overrideActiveAmplitude  = [];
      rampImpConfig.stochasticWaves.scalePassiveAmplitude    = [];
      rampImpConfig.stochasticWaves.scaleActiveAmplitude     = [];  
      
    otherwise
      assert(0,'Error: unrecognized muscle name');
  end

  if(settingsImpedance.waveAmplitudeStudy==1)
    rampImpConfig.stochasticWaves.amplitudeSet = [1,0.5,0.25,0.125,0.0625];
  end

  %rampImpConfig.stop.waitTime                            = 5;

  assert(length(stochasticWaves)==length(rampImpConfig.isStochasticWaveActive),...
         ['Error: number of stochasticWaves and isStochasticWaveActive',...
          ' are incompatible.']);

  if(settingsImpedance.createMultiTemperatureProtocol==1)

    %seriesId = 'temperature_00';
    %trialId = 1;
    trialId = constructRampImpedanceExperiments610A(...
                            dateId,...
                            trialId,...
                            sequenceId,...
                            stochasticWaves,...             
                            auroraConfig.default,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);
  
    seriesId = 'temperature_01';
    %trialId = 1;
    trialId = constructRampImpedanceExperiments610A(...
                            dateId,...    
                            trialId,...
                            sequenceId,...
                            stochasticWaves,...             
                            auroraConfig.default,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);
  
    seriesId = 'temperature_02';
    %trialId = 1;
    trialId = constructRampImpedanceExperiments610A(...
                            dateId,...    
                            trialId,...
                            sequenceId,...
                            stochasticWaves,...             
                            auroraConfig.default,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);
  else
    seriesId = ['impedance_',configMuscle.name];
    %trialId = 1;
    trialId = constructRampImpedanceExperiments610A(...
                            dateId,...    
                            trialId,...
                            sequenceId,...
                            stochasticWaves,...             
                            auroraConfig.default,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);    

  end
  sequenceId=sequenceId+1;

end



if(flag_preInjuryProtocol==1)

  prePostConfig.muscle      = configMuscle;
  prePostConfig.timing      = configTiming;
  prePostConfig.recovery    = configRecovery;
  prePostConfig.tetanus     = configTetanus;
  prePostConfig.twitch      = configTwitch;
  prePostConfig.positioning = configPositioning;
  prePostConfig.relax       = configRelax;

  %prePostConfig.unitSystem  = unitSystem;
  %prePostConfig.lceOptMM    = lceOptMM;
  %prePostConfig.vceMaxLPS   = vceMaxLPS;

  %prePostConfig.waitTime = 1;  
  %prePostConfig.stopWaitTime = 5;
  
  prePostConfig.passive.ramp.velocity = [0.01,0.33,1].*configMuscle.vceMaxMMPS*0.5; 
  prePostConfig.passive.ramp.waitTime = 1;
  prePostConfig.passive.ramp.length   = [3,3,3];  

  durationRamp      = prePostConfig.passive.ramp.length ...
                     ./ prePostConfig.passive.ramp.velocity;
  durationRamp      = roundTimeToNearestSampleTime(durationRamp,auroraConfig.default);
  

  velocityRampMMPS  = prePostConfig.passive.ramp.length./durationRamp;

  prePostConfig.passive.ramp.duration = durationRamp;
  prePostConfig.passive.ramp.holdDuration=[5,5,5];
  prePostConfig.passive.ramp.velocity = velocityRampMMPS;
  prePostConfig.passive.ramp.isActive = zeros(size(prePostConfig.passive.ramp.length));
  
  prePostConfig.passive.impedance.waitTime = 1;
  prePostConfig.passive.impedance.length = [2,4];
  prePostConfig.passive.impedance.stochasticWaveIndex=2;
  prePostConfig.passive.impedance.amplitude=perturbationLengthMM;  

  f0 = sqrt(min(perturbationBandwidth)/max(perturbationBandwidth));
  sineFreqSample = [f0:((1-f0)/10):1]';
  prePostConfig.passive.impedance.sine.frequencyHz = ...
      (sineFreqSample.^2)*max(perturbationBandwidth);
  prePostConfig.passive.impedance.sine.amplitude = ...
      perturbationLengthMM;
  prePostConfig.passive.impedance.sine.cycles = 10;

  %Isometric
  prePostConfig.isometric.lengths = [-3,3];

  %Active ramp
  prePostConfig.activeRamp.lengths = [1,-2;-2,1];
  prePostConfig.activeRamp.velocity= [-1;1].*(configMuscle.vceMaxMMPS*0.5);

  %Active impedance
  prePostConfig.active.impedance.waitTime = 1;
  prePostConfig.active.impedance.length = [0];
  prePostConfig.active.impedance.stochasticWaveIndex=1;
  prePostConfig.active.impedance.amplitude=perturbationLengthMM;  


  %Activations settings
  %prePostConfig.tetanus.waitTime       = 1;
  %prePostConfig.tetanus.initialDelay   = 0;
  %prePostConfig.tetanus.pulseFrequency = configTetanus.pulseFrequency;
  %prePostConfig.tetanus.pulseWidth     = configTetanus.pulseWidth;
  %prePostConfig.tetanus.durationExtension = 0;
  %prePostConfig.tetanus.duration       = nan;  



  %This is the relaxation sine wave between trials
  %prePostConfig.recovery = configRecovery;
  %prePostConfig.recovery.sineWave.waitTime  = 1;
  %prePostConfig.recovery.sineWave.frequency = 1;
  %prePostConfig.recovery.sineWave.amplitude = sineWaveRecoveryAmplitude;
  %prePostConfig.recovery.sineWave.cycles    = ...
  %  prePostConfig.recovery.sineWave.frequency*sineWaveRecoveryDurationS;
  %prePostConfig.recovery.sineWave.sampleFrequency = 100;
  %prePostConfig.recovery.stopWaitTime = 5;
  %prePostConfig.recovery.sampleFrequency = 100;
  %prePostConfig.recovery.ramp.waitTime = 1;

  prePostConfig.plateau.ramp.waitTime       = 1;
  prePostConfig.plateau.ramp.lengths        = [-3:1:3]';
  prePostConfig.plateau.ramp.duration       = 1;


  
  sequenceName = 'preInjury';

  [trialId, preInjuryFolders] = ...
    constructPrePostInjuryExperiment610A(...
                          dateId,...
                          trialId,...
                          sequenceId,...
                          sequenceName,...
                          stochasticWaves,...                          
                          auroraConfig,...
                          prePostConfig,...
                          expFolders,...
                          projectFolders);  
  sequenceId=sequenceId+1;


  [protocolPath,sequenceName] = fileparts(preInjuryFolders.protocolFolderName);
  protocolLocalDirWindows = strrep(protocolLocalDir,'/','\');

  preInjurySequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  preInjurySequenceSettings.baseFile = ['preInjury_610A_',dateId];
  preInjurySequenceSettings.isTimed = 1;
  preInjurySequenceSettings.delayTime =0;
  preInjurySequenceSettings.repeats   =0;
  preInjurySequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
    fullfile(preInjuryFolders.rootFolderPath,...
             preInjuryFolders.protocolFolderName),...
    preInjurySequenceSettings)  ;  

end

if(flag_injuryRampProtocol==1)

  rampConfig.muscle=configMuscle;
  rampConfig.timing=configTiming;
  rampConfig.tetanus=configTetanus;
  rampConfig.recovery = configRecovery;
  rampConfig.positioning = configPositioning;


  %rampConfig.waitTime = 1;  
  %rampConfig.stopWaitTime = 5;
  %rampConfig.temperature = muscleTemperature;
  %rampConfig.timeToReachMaxActivation = configTetanus.timeToReachMaxActivation;
  
  rampConfig.ramp.velocity = configMuscle.vceMaxMMPS*0.5; 
  rampConfig.ramp.waitTime = 1;
  rampConfig.ramp.length   = [5,7,9];  
  rampConfig.ramp.duration = rampConfig.ramp.length ./ rampConfig.ramp.velocity;
  rampConfig.ramp.duration = ...
    roundTimeToNearestSampleTime(rampConfig.ramp.duration,auroraConfig.default);
  rampConfig.ramp.velocity = rampConfig.ramp.length./rampConfig.ramp.duration;
  rampConfig.ramp.isActive = ones(size(rampConfig.ramp.length));
  
  %Activations settings
  %rampConfig.tetanus.waitTime       = 1;
  %rampConfig.tetanus.initialDelay   = 0;
  %rampConfig.tetanus.pulseFrequency = pulseFrequency;
  %rampConfig.tetanus.pulseWidth     = configTetanus.pulseWidth;
  %rampConfig.tetanus.durationExtension = 0.5*configTetanus.timeToReachMaxActivation;
  %rampConfig.tetanus.duration       = nan;

  %Probe trial settings
  rampConfig.probe.velocity = 1;
  rampConfig.probe.waitTime = 1;
  rampConfig.probe.passiveLength = 3;

    
  %This is the relaxation sine wave between trials

  %rampConfig.recovery.sineWave.waitTime  = 1;
  %rampConfig.recovery.sineWave.frequency = 1;
  %rampConfig.recovery.sineWave.amplitude = sineWaveRecoveryAmplitude;
  %rampConfig.recovery.sineWave.cycles    = ...
  %  rampConfig.recovery.sineWave.frequency*sineWaveRecoveryDurationS;
  %rampConfig.recovery.sineWave.sampleFrequency = 100;
  %rampConfig.recovery.stopWaitTime = rampConfig.stopWaitTime;
  %rampConfig.recovery.sampleFrequency = 100;

  %rampConfig.muscleName  =muscleName;
  %rampConfig.unitSystem  =unitSystem;
  %rampConfig.lceOptMM    =lceOptMM;
  %rampConfig.vceMaxLPS   =vceMaxLPS;

  [trialId, alFolders] = constructActiveLengtheningInjuryExperiment610A(...
                              dateId,...
                              trialId,...
                              sequenceId,...
                              'rampInjury',...
                              auroraConfig.default,...
                              rampConfig,...
                              expFolders,...
                              projectFolders);  

  [protocolPath,sequenceName] = fileparts(alFolders.protocolFolderName);
  protocolLocalDirWindows = strrep(protocolLocalDir,'/','\');

  alSequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  alSequenceSettings.baseFile = ['rampInjury_610A_',dateId];
  alSequenceSettings.isTimed = 0;
  alSequenceSettings.delayTime =0;
  alSequenceSettings.repeats   =0;
  alSequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
            fullfile(alFolders.rootFolderPath,...
                     alFolders.protocolFolderName),...
                     alSequenceSettings)  ;

  sequenceId=sequenceId+1;



end



if(flag_postInjuryProtocol==1)

  
  sequenceName = 'postInjury';

  [trialId, postInjuryFolders] = ...
    constructPrePostInjuryExperiment610A(...
                          dateId,...
                          trialId,...
                          sequenceId,...
                          sequenceName,...
                          stochasticWaves,...                          
                          auroraConfig,...
                          prePostConfig,...
                          expFolders,...
                          projectFolders);  
  sequenceId=sequenceId+1;


  [protocolPath,sequenceName] = fileparts(postInjuryFolders.protocolFolderName);
  protocolLocalDirWindows = strrep(protocolLocalDir,'/','\');

  postInjurySequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  postInjurySequenceSettings.baseFile = ['postInjury_610A_',dateId];
  postInjurySequenceSettings.isTimed = 1;
  postInjurySequenceSettings.delayTime =0;
  postInjurySequenceSettings.repeats   =0;
  postInjurySequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
    fullfile(postInjuryFolders.rootFolderPath,...
             postInjuryFolders.protocolFolderName),...
    postInjurySequenceSettings)  ;  

end

