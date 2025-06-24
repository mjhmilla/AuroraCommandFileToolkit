clc;
close all;
clear all;

%%
% Folders
%%

rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.aurora610A);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);
addpath(projectFolders.signals);

%%
% Script Configuration
%%
flag_generateRandomSignal   = 1;
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

ratMuscleName = 'EDL';
muscleTemperatureInC = 12;
sampleFrequency =1000;



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

g2N      = 9.81*0.001;
edlParams.fisoN     = 225*g2N;   %225g 
edlParams.lceOptMM  = 13.7;      %mm 
edlParams.vceNMax   = 243/edlParams.lceOptMM; %Lo/s  
edlParams.alphaOpt  = deg2rad(10);
edlParams.ltSlkMM   = 9;         %mm
edlParams.etIso     = 0.033; % Johnson et al. took the default value from Zajac

perturbation.magnitude = 0.01*edlParams.lceOptMM;
perturbation.unit = 'mm';

%%
% Plot Configuration
%%

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
% Aurora configuration
%%



auroraConfig = getDefaultAuroraConfiguration610A(...
                    sampleFrequency,...    
                    edlParams.lceOptMM,...
                    edlParams.vceNMax);

%%
% System identification perturbation signal configuration
%%


%%
% Create the system identification vibration signal
%   This is quite challenging because we are limited to 945 commands.
%%
if(flag_generateRandomSignal==1)
    %%
    % Square
    %%
    verbose=1;
    figSquarePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;

    assert(strcmp(perturbation.unit,auroraConfig.defaultLengthUnit),...
        ['Error: perturbation unit and the defaultLengthUnit must',...
         'match']);

    configStochasticWave = getPerturbationConfiguration610A(...
                       perturbation.magnitude,...
                       auroraConfig);

    lengthRampOption = ...
        getCommandFunctionOptions610A('Ramp','Length Out',auroraConfig);

    [squareStochasticWave, ...
    squarePreconditioningWave, ...
    figSquarePerturbation] = ...
    createPerturbationWave610A(...
            'Ramp',...
            lengthRampOption,...
            configStochasticWave,...
            auroraConfig, ...
            figSquarePerturbation,...
            perturbationPlotConfig,...
            verbose);

    save(fullfile(projectFolders.output_structs,...
         'squareStochasticWave.mat'),...
         'squareStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,...
         'squarePreconditioningWave.mat'),...
         'squarePreconditioningWave','-mat');    
    
    saveas(figSquarePerturbation,...
           fullfile(projectFolders.output_plots,...
          'fig_randomSquareWave'),'pdf');
    savefig(figSquarePerturbation,...
            fullfile(projectFolders.output_plots,...
            'fig_randomSquareWave.fig'));    

    %%
    % Sine
    %%
    verbose=1;
    figSinePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;

    lengthSineOption = ...
        getCommandFunctionOptions610A('Sine Wave','Length Out',auroraConfig);

    [sineStochasticWave, ...
     sinePreconditioningWave, ...
     figSinePerturbation] = createPerturbationWave610A('Sine Wave',...
                                                lengthSineOption,...
                                                configStochasticWave,...
                                                auroraConfig, ...
                                                figSinePerturbation,...
                                                perturbationPlotConfig,...
                                                verbose);

    save(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'),...
         'sineStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'),...
         'sinePreconditioningWave','-mat');    

    save(fullfile(projectFolders.output_structs,'configStochasticWave.mat'),...
         'configStochasticWave','-mat');        
    
    saveas(figSinePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSineWave'),'pdf');
    savefig(figSinePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSineWave.fig'));      

else
    load(fullfile(projectFolders.output_structs,'squareStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat'));
    load(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'));
    load(fullfile(projectFolders.output_structs,'configStochasticWave.mat'));
end


%%
% Generate the injury experiment protocol files
%%

%
% Put all of the stochastic waveforms into a struct: all of these
% will be applied at the beginning and end of each trial
%
lineCountStochastic = ...
    length(squarePreconditioningWave.controlFunctions.waitDuration) ...
  + length(squareStochasticWave.controlFunctions.waitDuration) ...
  + length(sinePreconditioningWave.controlFunctions.waitDuration) ...
  + length(sineStochasticWave.controlFunctions.waitDuration);

assert(lineCountStochastic*2 < (auroraConfig.maximumNumberOfCommands + 40),...
      'Error: the number of perturbation commands is too high');

stochasticWaves(4)=struct('controlFunction',[],'waitDuration',[],...
                         'optionValues',[],'options',[],'type','');

controlFields = {'controlFunction','waitDuration','optionValues','options'};

for j=1:1:length(controlFields)
    stochasticWaves(1).(controlFields{j}) = ...
        squarePreconditioningWave.controlFunctions.(controlFields{j});
    stochasticWaves(1).type = 'Length-Ramp-Preconditioning';
    stochasticWaves(1).config=configStochasticWave;

    stochasticWaves(2).(controlFields{j}) = ...
        squareStochasticWave.controlFunctions.(controlFields{j});
    stochasticWaves(2).type = 'Length-Ramp-Stochastic';
    stochasticWaves(2).config=configStochasticWave;
    
    stochasticWaves(3).(controlFields{j}) = ...
        sinePreconditioningWave.controlFunctions.(controlFields{j});
    stochasticWaves(3).type = 'Length-Sine-Preconditioning';
    stochasticWaves(3).config=configStochasticWave;
    
    stochasticWaves(4).(controlFields{j}) = ...
        sineStochasticWave.controlFunctions.(controlFields{j});
    stochasticWaves(4).type = 'Length-Sine-Stochastic';
    stochasticWaves(4).config=configStochasticWave;
    
end


success = createFiberInjuryExperiments610A(...        
                  stochasticWaves,...
                  auroraConfig,...
                  projectFolders);
