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
addpath(projectFolders.experiments);
addpath(projectFolders.signals);

%%
% Script Configuration
%%
flag_generateRandomSignal   = 1;
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

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

%%
% Aurora configuration
%%
approximateSampleLengthInMM=1.5;
sampleFrequency =1000;
minNormLength = 0.5;
maxNormLength = 1.6;
auroraConfig = getDefaultAuroraConfiguration600A(approximateSampleLengthInMM,...
                                        sampleFrequency,...
                                        minNormLength,...
                                        maxNormLength);

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

    perturbationPlotConfig.subplot=subplotPanel_2R1C;
    perturbationPlotConfig.config = plotConfig_2R1C;

    configVibration = getPerturbationConfiguration(auroraConfig);

    [squareStochasticWave, ...
    squarePreconditioningWave, ...
    figSquarePerturbation] = createPerturbationWaveUpd('Length-Ramp',...
                                                configVibration,...
                                                auroraConfig, ...
                                                figSquarePerturbation,...
                                                perturbationPlotConfig,...
                                                verbose);

    save(fullfile(projectFolders.output_structs,'squareStochasticWave.mat'),...
         'squareStochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat'),...
         'squarePreconditioningWave','-mat');    
    
    saveas(figSquarePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSquareWave'),'pdf');
    savefig(figSquarePerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSquareWave.fig'));    

    %%
    % Sine
    %%
    verbose=1;
    figSinePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_2R1C;
    perturbationPlotConfig.config = plotConfig_2R1C;


    [sineStochasticWave, ...
     sinePreconditioningWave, ...
     figSinePerturbation] = createPerturbationWaveUpd('Length-Sine',...
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
dateVec = datevec(date());
dateId  = [int2str(dateVec(1,1)),int2str(dateVec(1,2)),int2str(dateVec(1,3))];

lineCount = createFiberInjuryExperiments600A(...
                  squarePreconditioningWave,...
                  squareStochasticWave,...
                  dateId,...
                  projectFolders,...
                  auroraConfig);
