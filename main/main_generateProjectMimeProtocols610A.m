clc;
close all;
clear all;

disp('Update script to take in measured parameters: lceOptMM, fceMax, lpeHalf, fpeHalf')

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
dateIdOverride                  = '20260326';
muscleName                      = 'EDL'; %'EDL', or 'SOL';
measuredMuscleParams.lceOptMM   = 10;
measuredMuscleParams.vceMaxMMPS = 12;

flag_normalizationProtocol    =0;
flag_injuryProtocol           =0;
flag_characterizationProtocol =0;

flag_plateauSearchProtocol    =1;
flag_degradationProtocol      =1;
flag_rampImpededanceProtocol  =1;


flag_generateRandomSignal         = 0;
flag_fitPerturbationPowerSpectrum = 1;
stochasticWaveScalesToTest        = [1];
stochasticWaveSetType             = 6;

normPerturbationLength            = 0.1;
perturbationBandwidth             = [2, 90]; %Only 2/3 of the upper bandwidth
                                             %will be realized
perturbationDuration = [1,2];
sampleFrequency = 4000;



pointsPower = round(log2(sampleFrequency.*perturbationDuration));
pointsSet       = 2.^(pointsPower);
unitSystem      = 'mm_mN_s_Hz'; %Alternative: 'mm_mN_s_Hz'

assert(strcmp(unitSystem,'Ref_s_Hz')==0, ...
   ['Error: Cannot use Ref_s_Hz because this unit system does not work',...
    ' properly on the 1200A']);



flag_plotRandomSignal       = 1 && flag_generateRandomSignal;




%%
% Approximate specimen properties
%%
%From: Table II of
%
%W. L. Johnson, D. L. Jindrich, H. Zhong, R. R. Roy and V. R. Edgerton, 
% "Application of a Rat Hindlimb Model: A Prediction of Force Spaces 
% Reachable Through Stimulation of Nerve Fascicles," in IEEE 
% Transactions on Biomedical Engineering, vol. 58, no. 12, pp. 
% 3328-3338, Dec. 2011, doi: 10.1109/TBME.2011.2106784. 

g2N                 = 9.81*0.001;
switch muscleName
    case 'EDL'
        muscleParams.fisoN     = 265*g2N;   %225g 
        muscleParams.lceOptMM  = 13.7;      %mm 
        muscleParams.vceMaxLPS   = 243/muscleParams.lceOptMM; %Lo/s  
        muscleParams.alphaOpt  = deg2rad(10);
        muscleParams.ltSlkMM   = 9;         %mm
        muscleParams.etIso     = 0.033; % Johnson et al. took the default value from Zajac
    case 'SOL'
        muscleParams.fisoN     = 234*g2N;   %225g 
        muscleParams.lceOptMM  = 16.0;      %mm 
        muscleParams.vceMaxLPS = 89/muscleParams.lceOptMM; %Lo/s  
        muscleParams.alphaOpt  = deg2rad(4);
        muscleParams.ltSlkMM   = 9.5;         %mm
        muscleParams.etIso     = 0.033; % Johnson et al. took the default value from Zajac
    otherwise
        assert(0,'Error: Invalid muscle name');
end




lceOptMM = nan;
vceMaxLPS = nan;
if(isempty(measuredMuscleParams.lceOptMM)==0)
    lceOptMM = measuredMuscleParams.lceOptMM;
else
    lceOptMM = muscleParams.lceOptMM;
end

if(isempty(measuredMuscleParams.vceMaxMMPS)==0 ...
    && isempty(measuredMuscleParams.lceOptMM)==0)
    vceMaxLPS = measuredMuscleParams.vceMaxMMPS ...
               /measuredMuscleParams.lceOptMM;
else
    vceMaxLPS = muscleParams.vceMaxLPS;
end

disp('Generating dpf files for:');
disp(muscleName);
fprintf('%1.1f mm\tlceOpt\n',lceOptMM);
fprintf('%1.1f lps\tvceMaxLPS\n',vceMaxLPS);

%%
% Perturbation settings
%%
perturbation(length(pointsSet)) = ...
  struct('magnitude',[],'bandwidth',[],'unit',[],'points',[]);

for i=1:1:length(pointsSet)
  switch unitSystem
      case 'mm_mN_s_Hz'
          perturbation(i).magnitude = normPerturbationLength*lceOptMM;
          perturbation(i).bandwidth = perturbationBandwidth;
          perturbation(i).unit      = 'mm';
          perturbation(i).points    = pointsSet(i);
      case 'Ref_s_Hz'
          perturbation(i).magnitude = normPerturbationLength;
          perturbation(i).bandwidth = perturbationBandwidth;
          perturbation(i).unit      = 'Ref';
          perturbation(i).points    = pointsSet(i);
    otherwise
          assert(0,'Error: unrecognized unit settings');
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

codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
if(~exist(codeDir,'dir'))
  mkdir(codeDir);
end

dataDir         = fullfile(codeDir,dataFolderName); 
if(~exist(dataDir,'dir'))
  mkdir(dataDir);
end

protocolDir     = fullfile(codeDir,protocolFolderName); 
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

%%
% Generate the protocols
%%
trialId = 1;

if(flag_plateauSearchProtocol==1)  
  plateauConfig.ramp.waitTime       = 1;
  plateauConfig.ramp.lengths        = [-2:1:2]';
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

  trialId = createPlateauSearchTrail610A(...
                        dateId,...
                        trialId,...
                        auroraConfig,...
                        plateauConfig,...
                        expFolders,...
                        projectFolders);  
  
end

if(flag_degradationProtocol==1)
  degradationConfig.waitTime=1;
  degradationConfig.tetanus.initialDelay   = 0;
  degradationConfig.tetanus.pulseFrequency = 70;
  degradationConfig.tetanus.pulseWidth     = 5;
  degradationConfig.tetanus.duration       = 1;
  degradationConfig.tetanus.sampleFrequency= 4000;

  degradationConfig.sineWave.waitTime   = 0;
  degradationConfig.sineWave.frequency  = 1;
  degradationConfig.sineWave.amplitude  = 0.25;
  degradationConfig.sineWave.cycles     = ...
  degradationConfig.sineWave.frequency*25;
  degradationConfig.sineWave.sampleFrequency = 100;

  degradationConfig.muscleName  =muscleName;
  degradationConfig.unitSystem  ='mm_mN_s_Hz';
  degradationConfig.lceOptMM    =lceOptMM;
  degradationConfig.vceMaxLPS   =vceMaxLPS;
  

  trialId = constructDegradationExperiment610A(...
                        dateId,...
                        trialId,...
                        degradationConfig,...
                        expFolders,...
                        projectFolders);   

end

if(flag_rampImpededanceProtocol==1)  

  trialId=1;
  
  rampImpConfig.isStochasticWaveActive = [1,0,1,0];

  rampImpConfig.ramp.waitTime = 1;
  rampImpConfig.ramp.length = [0:1:3]';  
  rampImpConfig.ramp.duration = 1;

  rampImpConfig.sineWave.waitTime  = 10;
  rampImpConfig.sineWave.frequency = 20;
  rampImpConfig.sineWave.amplitude = 0.25;
  rampImpConfig.sineWave.cycles    = ...
  rampImpConfig.sineWave.frequency*5;

  rampImpConfig.tetanus.waitTime       = 1;
  rampImpConfig.tetanus.initialDelay   = 0;
  rampImpConfig.tetanus.pulseFrequency = 70;
  rampImpConfig.tetanus.pulseWidth     = 5;
  rampImpConfig.tetanus.duration       = nan;
  rampImpConfig.tetanus.durationExtension = 0.5;

  rampImpConfig.stochasticWaves.waitTime=5;
  rampImpConfig.stochasticWaves.timeToReachMaxActivation=0.25;
  rampImpConfig.stop.waitTime = 5;

  assert(length(stochasticWaves)==length(rampImpConfig.isStochasticWaveActive),...
         ['Error: number of stochasticWaves and isStochasticWaveActive',...
          ' are incompatible.']);

  seriesId = 'temperature_00';
  trialId = 1;
  trialId = constructRampImpedanceExperiments610A(...
                          seriesId,...
                          dateId,...
                          trialId,...
                          stochasticWaves,...             
                          auroraConfig,...
                          rampImpConfig,...
                          expFolders,...
                          projectFolders);

  seriesId = 'temperature_01';
  trialId = 1;
  trialId = constructRampImpedanceExperiments610A(...
                          seriesId,...
                          dateId,...
                          trialId,...
                          stochasticWaves,...             
                          auroraConfig,...
                          rampImpConfig,...
                          expFolders,...
                          projectFolders);

  seriesId = 'temperature_02';
  trialId = 1;
  trialId = constructRampImpedanceExperiments610A(...
                          seriesId,...
                          dateId,...
                          trialId,...
                          stochasticWaves,...             
                          auroraConfig,...
                          rampImpConfig,...
                          expFolders,...
                          projectFolders);
end



if(flag_normalizationProtocol==1)
  success = constructNormalizationExperiments610A(...
                          stochasticWaveScalesToTest,...
                          stochasticWaves,...                  
                          auroraConfigNormalization,...
                          expConfig,...
                          projectFolders);
end

if(flag_injuryProtocol==1)
  success = constructInjuryExperiments610A(...        
                    stochasticWaves,...             
                    auroraConfig,...
                    expConfig,...
                    projectFolders);
end

if(flag_characterizationProtocol==1)
  success = constructCharacterizationExperiments610A(...        
                    stochasticWaves,...           
                    auroraConfig,...
                    expConfig,...
                    projectFolders);
end