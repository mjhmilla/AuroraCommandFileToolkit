clc;
close all;
clear all;

%%
% Folders
%%

rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.aurora600A);
addpath(projectFolders.postprocessing);
addpath(projectFolders.common);
addpath(projectFolders.signals);

%%
% Script Configuration
%%
flag_generateRandomSignal   = 1;
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

ratMuscleName           = 'EDL';
muscleTemperatureInC    = 12;
perturbationMagnitude   = 0.005;

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
approximateSampleLengthInMM=1.5;
sampleFrequency =1000;
minNormLength = 0.5;
maxNormLength = 1.6;

switch ratMuscleName
    case 'SOL'
        maxNormalizedSpeedLPS = 1.02; 
        % in units of norm fiber lengths/second        
    case 'EDL'
        maxNormalizedSpeedLPS = 2.25;  
    otherwise 
        assert(0,'Error: muscleName not found');
end

auroraConfig = getDefaultAuroraConfiguration600A(approximateSampleLengthInMM,...
                                        sampleFrequency,...
                                        minNormLength,...
                                        maxNormLength,...
                                        maxNormalizedSpeedLPS);

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

    configVibration = ...
        getPerturbationConfiguration600A(perturbationMagnitude,auroraConfig);

    lengthRampOption = ...
        getCommandFunctionOptions600A('Length-Ramp',auroraConfig);


    [squareStochasticWave, ...
    squarePreconditioningWave, ...
    figSquarePerturbation] = createPerturbationWave600A('Length-Ramp',...
                                                lengthRampOption,...
                                                configVibration,...
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
        getCommandFunctionOptions600A('Length-Sine',auroraConfig);

    [sineStochasticWave, ...
     sinePreconditioningWave, ...
     figSinePerturbation] = createPerturbationWave600A('Length-Sine',...
                                                lengthSineOption,...
                                                configVibration,...
                                                auroraConfig, ...
                                                figSinePerturbation,...
                                                perturbationPlotConfig,...
                                                verbose);

    save(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'),...
         'sineStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'),...
         'sinePreconditioningWave','-mat');    
    
    saveas(figSinePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSineWave'),'pdf');
    savefig(figSinePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSineWave.fig'));      

else
    load(fullfile(projectFolders.output_structs,'squareStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat'));
    load(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'));
end



%%
% Experiment configuration
%%


[endTime,lineCount] = createTestExperiment(auroraConfig, projectFolders);


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

    stochasticWaves(2).(controlFields{j}) = ...
        squareStochasticWave.controlFunctions.(controlFields{j});
    stochasticWaves(2).type = 'Length-Ramp-Stochastic';
    
    stochasticWaves(3).(controlFields{j}) = ...
        sinePreconditioningWave.controlFunctions.(controlFields{j});
    stochasticWaves(3).type = 'Length-Sine-Preconditioning';
    
    stochasticWaves(4).(controlFields{j}) = ...
        sineStochasticWave.controlFunctions.(controlFields{j});
    stochasticWaves(4).type = 'Length-Sine-Stochastic';
    
end


success = createFiberInjuryExperiments600A(...        
                  stochasticWaves,...
                  projectFolders,...
                  auroraConfig);
