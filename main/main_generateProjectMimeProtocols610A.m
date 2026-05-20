clc;
close all;
clear all;

%disp('Update script to take in measured parameters: lceOptMM, fceMax, lpeHalf, fpeHalf')

%% 66 50 LR.: 10N max
% Folders
%%

rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.aurora610A);
addpath(projectFolders.postprocessing);
addpath(projectFolders.common);
addpath(projectFolders.experiments);
addpath(projectFolders.signals);

%%
% Script Configuration
%%

dateIdOverride                  = [];

temperatureSettings(2)=...
  struct('muscle','','temperatureC',0,'stimulationFrequencyHz',0,'pulseWidthMs',0,...
         'riseTimeS',0,'lceOptMM',0,'vceMaxMMPS',0);

idxTemp = 1;
idxEDL22=1;
idxEDL37=2;
temperatureSettings(idxEDL22).muscle                = 'EDL';
temperatureSettings(idxEDL22).temperatureC          =22;     %20260326
temperatureSettings(idxEDL22).stimulationFrequencyHz=70;     %20260326
temperatureSettings(idxEDL22).pulseWidthMs          = 5;     %20260326
temperatureSettings(idxEDL22).riseTimeS             = 0.401; %20260326
temperatureSettings(idxEDL22).lceOptMM              = 9.8;   %20260311
temperatureSettings(idxEDL22).vceMaxMMPS              = 70; %Ranatunga 1984 Fig.4

temperatureSettings(idxEDL37).muscle                = 'EDL';
temperatureSettings(idxEDL37).temperatureC          = 37;   %20260519
temperatureSettings(idxEDL37).stimulationFrequencyHz= 300;  %20260512
temperatureSettings(idxEDL37).pulseWidthMs          = 0.4;  %20260512
temperatureSettings(idxEDL37).riseTimeS             = 0.087;%20260519 
temperatureSettings(idxEDL37).lceOptMM              = 9.8;  %20260311 (22C)
temperatureSettings(idxEDL37).vceMaxMMPS              = 167.5; %Ranatunga 1984 Fig.4

settingsFields = fields(temperatureSettings(idxTemp));
fprintf('Settings\n')
for idxF = 1:1:length(settingsFields)
  param = num2str(temperatureSettings(idxTemp).(settingsFields{idxF}));
  if(isnumeric(param))
    fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
  else
    fprintf('\t%s\t%s\n',param,settingsFields{idxF});
  end
end
fprintf('\n\n');

sineWaveRecoveryDurationS       = 30;
sineWaveRecoveryAmplitude       = 1;
muscleTemperature               = temperatureSettings(idxTemp).temperatureC;
stimulationFrequency            = temperatureSettings(idxTemp).stimulationFrequencyHz;
stimulationPulseWidth           = temperatureSettings(idxTemp).pulseWidthMs;
timeOfMinimumStimulus           = temperatureSettings(idxTemp).riseTimeS;
lceOptMM                        = temperatureSettings(idxTemp).lceOptMM;
vceMaxMMPS                      = temperatureSettings(idxTemp).vceMaxMMPS;
vceMaxLPS                       = vceMaxMMPS/temperatureSettings(idxTemp).lceOptMM;

muscleName                      = temperatureSettings(idxTemp).muscle; %'EDL', or 'SOL';
measuredMuscleParams.lceOptMM   = [];
measuredMuscleParams.vceMaxMMPS = [];

if(~isempty(measuredMuscleParams.lceOptMM))
  fprintf('%1.1f to %1.1f mm\t Updated lceOptMM\n',...
      lceOptMM,measuredMuscleParams.lceOptMM)
  lceOptMM = measuredMuscleParams.lceOptMM;

end
if(~isempty(measuredMuscleParams.vceMaxMMPS))
  fprintf('%1.1f to %1.1f mm\t Updated vceOptMMPS\n',...
      (vceMaxMMPS),measuredMuscleParams.vceMaxMMPS);  
  vceMaxMMPS  = measuredMuscleParams.vceMaxMMPS;
  vceMaxLPS   = vceMaxMMPS/lceOptMM;
end

%%
% Configure the experiment
%%

flag_normalizationProtocol    =0;
%flag_injuryProtocol           =0;
%flag_characterizationProtocol =0;

flag_plateauSearchProtocol    =1;
flag_degradationProtocol      =0;

flag_forceFrequencyProtocol   =0;
flag_FLRProtocol              =0;
flag_rampImpededanceProtocol  =0;

flag_preInjuryProtocol        = 1;
flag_injuryRampProtocol       = 1;
flag_postInjuryProtocol       = 1;


flag_impedanceCalibrationProtocol = 0;

flag_generateRandomSignal         = 0;
flag_fitPerturbationPowerSpectrum = 1;
stochasticWaveScalesToTest        = [1];
stochasticWaveSetType             = 7; %only step waves;

perturbationLengthMM              = 0.125;
perturbationBandwidth             = [2, 90]; %Only 2/3 of the upper bandwidth
                                             %will be realized
perturbationDuration = [0.5,2];
sampleFrequency = 4000;

experimentComputerFolder=...
  'C:\Users\Administrator.ASI601A-AHQNPTB\Desktop\skeletal_muscle\';

%
% Protocol specific settings
%
settingsImpedanceCalibration.amplitudeMM = 4; %peak-to-peak 
settingsImpedanceCalibration.amplitudeN  = 0.1;

freqSample = [sqrt(2/100):0.1:1]';
settingsImpedanceCalibration.frequencyHz = (freqSample.^2)*75;

settingsImpedanceCalibration.perturbation.bandwidthHz  = ...
    [1,35];
settingsImpedanceCalibration.perturbation.points = ...
    2.^round(log2(sampleFrequency.*4));
settingsImpedanceCalibration.perturbation.amplitudeMM = ...
    settingsImpedanceCalibration.amplitudeMM;

settingsImpedanceCalibration.waitTime    = 0.5;

settingsImpedance.createMultiTemperatureProtocol = 0;
settingsImpedance.amplitude_mm                   = 0.125;
settingsImpedance.addRampAtStart                 = 1;
settingsImpedance.waveAmplitudeStudy             = 0;

if(strcmp(muscleName,'CAL'))
  settingsImpedance.amplitude_mm=2;
end

%
% Perturbation wave settings
%
pointsPower = round(log2(sampleFrequency.*perturbationDuration));
pointsSet       = 2.^(pointsPower);
unitSystem      = 'mm_mN_s_Hz'; %Alternative: 'mm_mN_s_Hz'

assert(strcmp(unitSystem,'Ref_s_Hz')==0, ...
   ['Error: Cannot use Ref_s_Hz because this unit system does not work',...
    ' properly on the 1200A']);



flag_plotRandomSignal       = 1 && flag_generateRandomSignal;






%%
% Perturbation settings
%%
perturbation(length(pointsSet)) = ...
  struct('magnitude',[],'bandwidth',[],'unit',[],'points',[]);

for i=1:1:length(pointsSet)
  switch unitSystem
      case 'mm_mN_s_Hz'
          perturbation(i).magnitude = perturbationLengthMM;
          perturbation(i).bandwidth = perturbationBandwidth;
          perturbation(i).unit      = 'mm';
          perturbation(i).points    = pointsSet(i);
      case 'Ref_s_Hz'
          perturbation(i).magnitude = perturbationLengthMM/lceOptMM;
          perturbation(i).bandwidth = perturbationBandwidth;
          perturbation(i).unit      = 'Ref';
          perturbation(i).points    = pointsSet(i);
    otherwise
          assert(0,'Error: unrecognized unit settings');
  end  
  if(perturbation(i).magnitude > 0.25)
    disp(['Warning: Perturbation magnitude > 0.25mm, expect low coherence']);
  end
end

%%
% Plot Configuration
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
expConfig = getDefaultExperimentConfiguration610A();

%%
% Aurora configuration
%%

%During normalization the specimen parameters are not known
auroraConfigNormalization = getDefaultAuroraConfiguration610A(...
                                muscleName,...
                                'mm_mN_s_Hz',...
                                sampleFrequency,...    
                                lceOptMM,...
                                vceMaxLPS);

%After normalization, the other unit systems can be used
auroraConfig = getDefaultAuroraConfiguration610A(...
                    muscleName,...
                    unitSystem,...
                    sampleFrequency,...    
                    lceOptMM,...
                    vceMaxLPS);

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
                      auroraConfig.defaultLengthUnit),...
            ['Error: perturbation unit and the defaultLengthUnit must',...
             'match']);
    
        configStochasticWave = getPerturbationConfiguration610A(...
                                 perturbation(idxP).magnitude,...
                                 perturbation(idxP).bandwidth,...
                                 perturbation(idxP).points,...
                                 flag_fitPerturbationPowerSpectrum,...
                                 auroraConfig);
    
        commandFunctionOption = getCommandFunctionOptions610A(...
                          commandFunctionName,'Length Out',auroraConfig);
    
        [preconditioningWave(idxP), ...
         stochasticWave(idxP), ...    
         figPerturbation] = ...
          createPerturbationWave610A(...
                  commandFunctionName,...
                  commandFunctionOption,...
                  configStochasticWave,...
                  auroraConfig, ...
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
           < (auroraConfig.maximumNumberOfCommands + 40),...
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
  plateauConfig.ramp.waitTime       = 1;
  plateauConfig.ramp.lengths        = [-3:1:3]';
  plateauConfig.ramp.duration       = 1;
  
  plateauConfig.sineWave.waitTime   = 1;
  plateauConfig.sineWave.frequency  = 20;
  plateauConfig.sineWave.amplitude  = 0.25;
  plateauConfig.sineWave.cycles     = ...
    plateauConfig.sineWave.frequency*5;

  plateauConfig.twitch.waitTime     = 1;
  plateauConfig.twitch.initialDelayS = 0;
  plateauConfig.twitch.pulseWidthMS  = 0.25;

  plateauConfig.stopWaitTime =1;
  plateauConfig.temperature = muscleTemperature;

  trialIdStart=trialId;
  flag_isASequence=0;
  trialId = createPlateauSearchTrail610A(...
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

  ffrConfig.waitTime=1;
  ffrConfig.tetanus.initialDelay   = 0;
  ffrConfig.tetanus.pulseFrequency = [50,100,200,300,400,500];

  assert(stimulationPulseWidth*0.001 < 0.5/max(ffrConfig.tetanus.pulseFrequency));

  ffrConfig.tetanus.pulseWidth     = stimulationPulseWidth;
  ffrConfig.tetanus.duration       = 1;
  ffrConfig.tetanus.sampleFrequency= 4000;

  ffrConfig.sineWave.waitTime   = 1;
  ffrConfig.sineWave.frequency  = 1;
  ffrConfig.sineWave.amplitude  = sineWaveRecoveryAmplitude;
  ffrConfig.sineWave.cycles     = ffrConfig.sineWave.frequency...
                                  *sineWaveRecoveryDurationS;
  ffrConfig.sineWave.sampleFrequency = 100;
  ffrConfig.stopWaitTime = 5;
  ffrConfig.temperature = muscleTemperature;

  ffrConfig.muscleName  =muscleName;
  ffrConfig.unitSystem  ='mm_mN_s_Hz';
  ffrConfig.lceOptMM    =lceOptMM;
  ffrConfig.vceMaxLPS   =vceMaxLPS;  
  
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

  degradationConfig.numberOfTrials = [10,10];
  degradationConfig.waitTime=[1,1];
  degradationConfig.tetanus.initialDelay   = [0,0];
  degradationConfig.tetanus.pulseFrequency = [1,1].*stimulationFrequency;

  assert(stimulationPulseWidth*0.001 < 0.5/max(stimulationFrequency));

  degradationConfig.tetanus.pulseWidth     = [1,1].*stimulationPulseWidth;
  degradationConfig.tetanus.duration       = [1,0.25];
  degradationConfig.tetanus.sampleFrequency= [1,1].*4000;

  degradationConfig.sineWave.waitTime   = 0;
  degradationConfig.sineWave.frequency  = 1;
  degradationConfig.sineWave.amplitude  = sineWaveRecoveryAmplitude;
  degradationConfig.sineWave.cycles     = ...
    degradationConfig.sineWave.frequency...
    *sineWaveRecoveryDurationS;
  degradationConfig.sineWave.sampleFrequency = 100;

  degradationConfig.muscleName  =muscleName;
  degradationConfig.unitSystem  ='mm_mN_s_Hz';
  degradationConfig.lceOptMM    =lceOptMM;
  degradationConfig.vceMaxLPS   =vceMaxLPS;
  
  degradationConfig.temperature = muscleTemperature;

  [trialId,degradationFolders]= constructDegradationExperiment610A(...
                        dateId,...
                        trialId,...
                        sequenceId,...
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
  success= createCalibrationImpedanceTrial610A(...                    
                    dateId,...                      
                    auroraConfig,...
                    settingsImpedanceCalibration,...                    
                    expFolders,...
                    plotConfig);
  sequenceId=sequenceId+1;



end



if(flag_FLRProtocol==1)

  flrConfig.waitTime = 1;  
  flrConfig.stopWaitTime = 5;
  flrConfig.temperature = muscleTemperature;
  flrConfig.timeOfMinimumStimulus = timeOfMinimumStimulus;
  
  flrConfig.ramp.velocity = 1; 
  flrConfig.ramp.waitTime = 1;
  flrConfig.ramp.length   = [0,-3,3,-2,2,0,-1,1,-4,4,0];  
  flrConfig.ramp.duration = abs(flrConfig.ramp.length./flrConfig.ramp.velocity);
  flrConfig.ramp.duration = max(flrConfig.ramp.duration,0.1);

  %Activations settings
  flrConfig.tetanus.waitTime       = 5;
  flrConfig.tetanus.initialDelay   = 0;
  flrConfig.tetanus.pulseFrequency = stimulationFrequency;
  flrConfig.tetanus.pulseWidth     = stimulationPulseWidth;
  flrConfig.tetanus.durationExtension = 0.5;
  flrConfig.tetanus.duration       = timeOfMinimumStimulus;

 
  %This is the relaxation sine wave between trials
  flrConfig.sineWave.waitTime  = 10;
  flrConfig.sineWave.frequency = 1;
  flrConfig.sineWave.amplitude = sineWaveRecoveryAmplitude;
  flrConfig.sineWave.cycles    = ...
  flrConfig.sineWave.frequency*sineWaveRecoveryDurationS;
  flrConfig.sineWave.sampleFrequency = 100;
  flrConfig.muscleName  =muscleName;
  flrConfig.unitSystem  ='mm_mN_s_Hz';
  flrConfig.lceOptMM    =lceOptMM;
  flrConfig.vceMaxLPS   =vceMaxLPS;

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

  %trialId=1;

  switch muscleName
    case 'EDL'
      rampImpConfig.isStochasticWaveActive = [1,0];
    case 'SOL'
      rampImpConfig.isStochasticWaveActive = [1,0];
    case 'CAL'
      rampImpConfig.isStochasticWaveActive = [0,0];
    otherwise
      assert(0,'Error: unrecognized muscle name');
  end

  rampImpConfig.stopWaitTime = 5;
  rampImpConfig.temperature = muscleTemperature;

  rampImpConfig.ramp.waitTime = 1;
  rampImpConfig.ramp.length = [0];  
  rampImpConfig.ramp.duration = 1;


  if(settingsImpedance.addRampAtStart==1)
    rampImpConfig.ramp.waitTime = 1;
    rampImpConfig.ramp.length = [0:1:4]';  
    rampImpConfig.ramp.duration = 1;
  end

  %This is the relaxation sine wave between trials
  rampImpConfig.sineWave.waitTime  = 1;
  rampImpConfig.sineWave.frequency = 1;
  rampImpConfig.sineWave.amplitude = sineWaveRecoveryAmplitude;
  rampImpConfig.sineWave.cycles    = ...
  rampImpConfig.sineWave.frequency*sineWaveRecoveryDurationS;
  rampImpConfig.sineWave.sampleFrequency = 100;
  rampImpConfig.muscleName  =muscleName;
  rampImpConfig.unitSystem  ='mm_mN_s_Hz';
  rampImpConfig.lceOptMM    =lceOptMM;
  rampImpConfig.vceMaxLPS   =vceMaxLPS;

  %This sine wave brings the passive force more quickly to a static
  %value
  rampImpConfig.sineWaveEqualization.waitTime  = 10;
  rampImpConfig.sineWaveEqualization.frequency = 20;
  rampImpConfig.sineWaveEqualization.amplitude = 1;
  rampImpConfig.sineWaveEqualization.cycles    = ...
  rampImpConfig.sineWaveEqualization.frequency*5;

  rampImpConfig.tetanus.waitTime       = 1;
  rampImpConfig.tetanus.initialDelay   = 0;
  rampImpConfig.tetanus.pulseFrequency = stimulationFrequency;
  rampImpConfig.tetanus.pulseWidth     = stimulationPulseWidth;
  rampImpConfig.tetanus.duration       = nan;
  rampImpConfig.tetanus.durationExtension = 0.5;

  rampImpConfig.stochasticWaves.waitTime                 = 5;
  rampImpConfig.stochasticWaves.timeToReachMaxActivation = ...
      timeOfMinimumStimulus;

  switch muscleName
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

  rampImpConfig.stop.waitTime                            = 5;

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
                            auroraConfig,...
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
                            auroraConfig,...
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
                            auroraConfig,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);
  else
    seriesId = ['impedance_',muscleName];
    %trialId = 1;
    trialId = constructRampImpedanceExperiments610A(...
                            dateId,...    
                            trialId,...
                            sequenceId,...
                            stochasticWaves,...             
                            auroraConfig,...
                            rampImpConfig,...
                            expFolders,...
                            projectFolders);    

  end
  sequenceId=sequenceId+1;

end



if(flag_preInjuryProtocol==1)

  prePostConfig.muscleName  =muscleName;
  prePostConfig.temperature = muscleTemperature;
  prePostConfig.timeToReachMaxActivation = timeOfMinimumStimulus;  
  prePostConfig.unitSystem  ='mm_mN_s_Hz';
  prePostConfig.lceOptMM    =lceOptMM;
  prePostConfig.vceMaxLPS   =vceMaxLPS;

  prePostConfig.waitTime = 1;  
  prePostConfig.stopWaitTime = 5;
  
  prePostConfig.passive.ramp.velocity = vceMaxMMPS*0.5; 
  prePostConfig.passive.ramp.waitTime = 1;
  prePostConfig.passive.ramp.length   = [3,3];  

  durationRamp      = prePostConfig.passive.ramp.length ./ ([0.1,0.5].*vceMaxMMPS);
  durationRamp      = round(durationRamp.*sampleFrequency)./sampleFrequency;
  velocityRampMMPS  = prePostConfig.passive.ramp.length./durationRamp;

  prePostConfig.passive.ramp.duration = durationRamp;
  prePostConfig.passive.ramp.holdDuration=[5,5];
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
  prePostConfig.activeRamp.velocity= [-1;1].*(vceMaxMMPS*0.5);

  %Active impedance
  prePostConfig.active.impedance.waitTime = 1;
  prePostConfig.active.impedance.length = [0];
  prePostConfig.active.impedance.stochasticWaveIndex=1;
  prePostConfig.active.impedance.amplitude=perturbationLengthMM;  


  %Activations settings
  prePostConfig.tetanus.waitTime       = 1;
  prePostConfig.tetanus.initialDelay   = 0;
  prePostConfig.tetanus.pulseFrequency = stimulationFrequency;
  prePostConfig.tetanus.pulseWidth     = stimulationPulseWidth;
  prePostConfig.tetanus.durationExtension = 0;
  prePostConfig.tetanus.duration       = nan;  



  %This is the relaxation sine wave between trials
  prePostConfig.recovery.sineWave.waitTime  = 1;
  prePostConfig.recovery.sineWave.frequency = 1;
  prePostConfig.recovery.sineWave.amplitude = sineWaveRecoveryAmplitude;
  prePostConfig.recovery.sineWave.cycles    = ...
    prePostConfig.recovery.sineWave.frequency*sineWaveRecoveryDurationS;
  prePostConfig.recovery.sineWave.sampleFrequency = 100;
  prePostConfig.recovery.stopWaitTime = 5;
  prePostConfig.recovery.sampleFrequency = 100;
  prePostConfig.recovery.ramp.waitTime = 1;

  prePostConfig.plateau.ramp.waitTime       = 1;
  prePostConfig.plateau.ramp.lengths        = [-3:1:3]';
  prePostConfig.plateau.ramp.duration       = 1;
  
  prePostConfig.plateau.sineWave.waitTime   = 1;
  prePostConfig.plateau.sineWave.frequency  = 20;
  prePostConfig.plateau.sineWave.amplitude  = 0.25;
  prePostConfig.plateau.sineWave.cycles     = ...
    prePostConfig.plateau.sineWave.frequency*5;

  prePostConfig.plateau.twitch.waitTime     = 1;
  prePostConfig.plateau.twitch.initialDelayS = 0;
  prePostConfig.plateau.twitch.pulseWidthMS  = 0.25;

  prePostConfig.plateau.stopWaitTime =1;
  prePostConfig.plateau.temperature = muscleTemperature;

  
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

  degradationSequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  degradationSequenceSettings.baseFile = ['preInjury_610A_',dateId];
  degradationSequenceSettings.isTimed = 1;
  degradationSequenceSettings.delayTime =0;
  degradationSequenceSettings.repeats   =0;
  degradationSequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
    fullfile(preInjuryFolders.rootFolderPath,...
             preInjuryFolders.protocolFolderName),...
    degradationSequenceSettings)  ;  

end

if(flag_injuryRampProtocol==1)

  rampConfig.waitTime = 1;  
  rampConfig.stopWaitTime = 5;
  rampConfig.temperature = muscleTemperature;
  rampConfig.timeToReachMaxActivation = timeOfMinimumStimulus;
  
  rampConfig.ramp.velocity = vceMaxMMPS*0.5; 
  rampConfig.ramp.waitTime = 1;
  rampConfig.ramp.length   = [5,7,9];  
  rampConfig.ramp.duration = rampConfig.ramp.length ./ rampConfig.ramp.velocity;
  rampConfig.ramp.duration = round(rampConfig.ramp.duration*sampleFrequency)/sampleFrequency;
  rampConfig.ramp.velocity = rampConfig.ramp.length./rampConfig.ramp.duration;
  rampConfig.ramp.isActive = ones(size(rampConfig.ramp.length));
  
  %Activations settings
  rampConfig.tetanus.waitTime       = 1;
  rampConfig.tetanus.initialDelay   = 0;
  rampConfig.tetanus.pulseFrequency = stimulationFrequency;
  rampConfig.tetanus.pulseWidth     = stimulationPulseWidth;
  rampConfig.tetanus.durationExtension = 0.5*timeOfMinimumStimulus;
  rampConfig.tetanus.duration       = nan;

  %Probe trial settings
  rampConfig.probe.velocity = 1;
  rampConfig.probe.waitTime = 1;
  rampConfig.probe.passiveLength = 3;

    
  %This is the relaxation sine wave between trials
  rampConfig.recovery.sineWave.waitTime  = 1;
  rampConfig.recovery.sineWave.frequency = 1;
  rampConfig.recovery.sineWave.amplitude = sineWaveRecoveryAmplitude;
  rampConfig.recovery.sineWave.cycles    = ...
    rampConfig.recovery.sineWave.frequency*sineWaveRecoveryDurationS;
  rampConfig.recovery.sineWave.sampleFrequency = 100;
  rampConfig.recovery.stopWaitTime = rampConfig.stopWaitTime;
  rampConfig.recovery.sampleFrequency = 100;

  rampConfig.muscleName  =muscleName;
  rampConfig.unitSystem  ='mm_mN_s_Hz';
  rampConfig.lceOptMM    =lceOptMM;
  rampConfig.vceMaxLPS   =vceMaxLPS;

  [trialId, alFolders] = constructActiveLengtheningInjuryExperiment610A(...
                              dateId,...
                              trialId,...
                              sequenceId,...
                              'rampInjury',...
                              auroraConfig,...
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

  degradationSequenceSettings.sequenceFileName = [sequenceName,'.dsf'];
  degradationSequenceSettings.baseFile = ['postInjury_610A_',dateId];
  degradationSequenceSettings.isTimed = 1;
  degradationSequenceSettings.delayTime =0;
  degradationSequenceSettings.repeats   =0;
  degradationSequenceSettings.expProtocolFolderName = ...
    [ experimentComputerFolder,...
      protocolLocalDirWindows,...
      '\',sequenceName,'\'];

  success=generateSequenceFile(...
    fullfile(postInjuryFolders.rootFolderPath,...
             postInjuryFolders.protocolFolderName),...
    degradationSequenceSettings)  ;  

end


if(flag_normalizationProtocol==1)
  success = constructNormalizationExperiments610A(...
                          stochasticWaveScalesToTest,...
                          stochasticWaves,...                  
                          auroraConfigNormalization,...
                          expConfig,...
                          projectFolders);
  sequenceId=sequenceId+1;

end

% if(flag_injuryProtocol==1)
%   success = constructInjuryExperiments610A(...        
%                     stochasticWaves,...             
%                     auroraConfig,...
%                     expConfig,...
%                     projectFolders);
%   sequenceId=sequenceId+1;
% 
% end
% 
% if(flag_characterizationProtocol==1)
%   success = constructCharacterizationExperiments610A(...        
%                     stochasticWaves,...           
%                     auroraConfig,...
%                     expConfig,...
%                     projectFolders);
%   sequenceId=sequenceId+1;  
% end