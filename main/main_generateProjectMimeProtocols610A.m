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
muscleName = 'EDL'; %'EDL', or 'SOL';

perturbationDuration = 2;

sampleFrequency = 4000;

pointsPower = round(log2(sampleFrequency*perturbationDuration));
pointsSet       = 2^(pointsPower);
unitSystem      = 'mm_mN_s_Hz'; %Alternative: 'mm_mN_s_Hz'

assert(strcmp(unitSystem,'Ref_s_Hz')==0, ...
   ['Error: Cannot use Ref_s_Hz because this unit system does not work',...
    ' properly on the 1200A']);

flag_generateRandomSignal         = 1;
flag_fitPerturbationPowerSpectrum = 1;

normPerturbationLength            = 0.01;
perturbationBandwidth             = [2, 90]; %Only 2/3 of the upper bandwidth
                                             %will be realized
stochasticWaveScalesToTest        = [1];

measuredMuscleParams.lceOptMM   = 5;      %6.66;
measuredMuscleParams.vceMaxMMPS = 11.1250;%91.1250;%S243*0.5*0.75;

%1. Square + Sine waves with perturbation
%2. Sine wave only
%3. Square wave only
stochasticWaveSetType       = 4;


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
          perturbation(i).points    = pointsSet(i,1);
      case 'Ref_s_Hz'
          perturbation(i).magnitude = normPerturbationLength;
          perturbation(i).bandwidth = perturbationBandwidth;
          perturbation(i).unit      = 'Ref';
          perturbation(i).points    = pointsSet(i,1);
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
if(flag_generateRandomSignal==1)


    
    %%
    % Square
    %%
    verbose=1;
    figSquarePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;    

    squarePreconditioningWave(length(perturbation)) ...
      = struct('signal',[],'config',[],'controlFunctions',[]);

    squareStochasticWave(length(perturbation)) ...
      = struct('signal',[],'config',[], 'controlFunctions',[]);
    
    for idxP = 1:1:length(perturbation)
      squarePreconditioningWave(idxP) = ...
        struct('signal',[],'config',[],'controlFunctions',[]);
      squareStochasticWave(idxP)      =...
        struct('signal',[],'config',[], 'controlFunctions',[]);
    end

    for idxP = 1:1:length(perturbation)
      assert(strcmp(perturbation(idxP).unit,auroraConfig.defaultLengthUnit),...
          ['Error: perturbation unit and the defaultLengthUnit must',...
           'match']);
  
      configStochasticWave = getPerturbationConfiguration610A(...
                               perturbation(idxP).magnitude,...
                               perturbation(idxP).bandwidth,...
                               perturbation(idxP).points,...
                               flag_fitPerturbationPowerSpectrum,...
                               auroraConfig);
  
      lengthRampOption = ...
          getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);
  
      [squarePreconditioningWave(idxP), ...
       squareStochasticWave(idxP), ...    
       figSquarePerturbation] = ...
        createPerturbationWave610A(...
                'Ramp',...
                lengthRampOption,...
                configStochasticWave,...
                auroraConfig, ...
                figSquarePerturbation,...
                perturbationPlotConfig,...
                verbose);

      saveas(figSquarePerturbation,...
             fullfile(plotDir,...
             sprintf('fig_randomSquareWave_%i',idxP)),'pdf');
      savefig(figSquarePerturbation,...
              fullfile(plotDir,...
              sprintf('fig_randomSquareWave_%i.fig',idxP)));  

      clf(figSquarePerturbation);
    
    end
    save(fullfile(projectFolders.output_structs,...
         'squareStochasticWave.mat'),...
         'squareStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,...
         'squarePreconditioningWave.mat'),...
         'squarePreconditioningWave','-mat');    
    

    %%
    % Sine
    %%

    verbose=1;
    figSinePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;

    sinePreconditioningWave(length(perturbation)) ...
      = struct('signal',[],'config',[],'controlFunctions',[]);

    sineStochasticWave(length(perturbation)) ...
      = struct('signal',[],'config',[], 'controlFunctions',[]);
    
    for idxP = 1:1:length(perturbation)
      sinePreconditioningWave(idxP) = ...
        struct('signal',[],'config',[],'controlFunctions',[]);
      sineStochasticWave(idxP)      =...
        struct('signal',[],'config',[], 'controlFunctions',[]);
    end


    for idxP=1:1:length(perturbation)
      lengthSineOption = ...
          getCommandFunctionOptions610A('Sine Wave','Length Out',auroraConfig);
  
      configStochasticWave = getPerturbationConfiguration610A(...
                               perturbation(idxP).magnitude,...
                               perturbation(idxP).bandwidth,...
                               perturbation(idxP).points,...
                               flag_fitPerturbationPowerSpectrum,...
                               auroraConfig);
  
      [sinePreconditioningWave(idxP), ...
       sineStochasticWave(idxP), ...     
       figSinePerturbation] = createPerturbationWave610A('Sine Wave',...
                                                  lengthSineOption,...
                                                  configStochasticWave,...
                                                  auroraConfig, ...
                                                  figSinePerturbation,...
                                                  perturbationPlotConfig,...
                                                  verbose);

      saveas(figSinePerturbation,...
             fullfile(plotDir,...
                      sprintf('fig_randomSineWave_%i',idxP)),'pdf');
      savefig(figSinePerturbation,...
              fullfile(plotDir,...
                       sprintf('fig_randomSineWave_%i.fig',idxP)));   

      clf(figSinePerturbation);

    end
    save(fullfile(projectFolders.output_structs,...
        'sineStochasticWave.mat'),...
        'sineStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,...
        'sinePreconditioningWave.mat'),...
        'sinePreconditioningWave','-mat');    

    save(fullfile(projectFolders.output_structs,...
                  'configStochasticWave.mat'),...
         'configStochasticWave','-mat');        
    
    


else

    load(fullfile(projectFolders.output_structs,'squareStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat'));

    load(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'));

    load(fullfile(projectFolders.output_structs,'configStochasticWave.mat'));
end


%
% Package the stochastic waves into the set that will 
% be applied to the specimen
%

switch stochasticWaveSetType
    case 1
        waveSet = {'squarePreconditioningWave','squareStochasticWave',...
                   'sinePreconditioningWave','sineStochasticWave'};        
    case 2
        waveSet = {'sineStochasticWave'};  
    case 3
        waveSet = {'squareStochasticWave'};      
    case 4
        waveSet = {'squareStochasticWave','sineStochasticWave'};    
    otherwise
        assert(0,'Error: stochasticWaveSetType incorrectly set');
end

controlFields = {'controlFunction','waitDuration','optionValues','options'};
lineCountStochastic = 0;

disp('Including stochastic waves:');

numberOfWaves=0;
for i=1:1:length(waveSet)
    switch waveSet{i}
        case 'squarePreconditioningWave'
            numberOfWaves = numberOfWaves  ...
              + length(squarePreconditioningWave);  
        case 'squareStochasticWave'
            numberOfWaves = numberOfWaves  ...
              + length(squareStochasticWave);  
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
        case 'squarePreconditioningWave'
            wave = squarePreconditioningWave;  
            typeName = 'Preconditioning-Length-Ramp';          
        case 'squareStochasticWave'
            wave = squareStochasticWave;
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
% Generate the normalization trials
%%
success = constructNormalizationExperiments610A(...
                        stochasticWaveScalesToTest,...
                        stochasticWaves,...                  
                        auroraConfigNormalization,...
                        expConfig,...
                        projectFolders);

%%
% Generate the injury experiment protocol files
%%


success = constructInjuryExperiments610A(...        
                  stochasticWaves,...             
                  auroraConfig,...
                  expConfig,...
                  projectFolders);

success = constructCharacterizationExperiments610A(...        
                  stochasticWaves,...           
                  auroraConfig,...
                  expConfig,...
                  projectFolders);
