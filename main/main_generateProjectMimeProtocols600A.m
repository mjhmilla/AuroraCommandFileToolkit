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
% Experiment configuration
%%
[endTime,lineCount] = createTestExperiment(auroraConfig, projectFolders);

%%
% Generate stochastic signals
%%
preconditioningWave = [];
stochasticWave = [];

%%
% Generate the injury experiment protocol files
%%
dateVec = datevec(date());
dateId  = [int2str(dateVec(1,1)),int2str(dateVec(1,2)),int2str(dateVec(1,3))];

lineCount = createFiberInjuryExperiments600A(...
                  preconditioningWave,...
                  stochasticWave,...
                  dateId,...
                  projectFolders,...
                  auroraConfig);
