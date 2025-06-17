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
%pg 3 of the manual for 322 C-I: 300um in 700us
auroraConfig.maximumRampSpeed = (300e-6/700e-6);

auroraConfig.numberOfEmptyCommandsPrepended = 10;
%  The Aurora machine appears to ignore the first 9-10 commands and then 
%  begins on the 19th command. Here we prepend a bunch of dummy commands
%  so that your desired signal is not affected.

auroraConfig.analogToDigitalSampleRateHz = 1000;
%  This is the rate Aurora's A/D converter will sample signals

auroraConfig.postCommandPauseTimeMS = 0.1; 
%  The Aurora system needs a pause time of at least 0.1 ms between ramps

auroraConfig.maximumNumberOfCommands = 945;
%  The Aurora system tends to crash if the command file has more than 950 
%  commands. This parameter is used to check how many entries are in the 
%  resulting PRO file. As the process of generating a *.pro file is a bit
%  complicated, the most reliable way to ensure that the *.pro file is of 
%  an acceptable size is to check after the fact.

auroraConfig.comment = 'EDL, h: 0.091 w:  0.079';
%
auroraConfig.minimumNormalizedLength    = 0.2;
auroraConfig.maximumNormalizedLength    = 1.5;
auroraConfig.pdDeadBand                 = 0;
auroraConfig.bath.changeTime            = 0.5;
auroraConfig.bath.preActivationDuration = 60;
auroraConfig.bath.passive               = 1;
auroraConfig.bath.preActivation         = 2;
auroraConfig.bath.active                = 3;

auroraConfig.defaultLengthUnit  = 'Lo';
auroraConfig.defaultForceUnit   = 'Fo';
auroraConfig.defaultTimeUnit    = 'ms';
auroraConfig.defaultFrequencyUnit    = 'Hz';

auroraConfig.useRelativeUnits   = 1;

%%
% Commands
%%
fid = fopen(fullfile(projectFolders.output_code,'test.pro'),'w');


startTime = writePreamble600A(fid,auroraConfig);

lengthRamp = getCommandFunctionOptions600A('Length-Ramp',auroraConfig);
lengthRamp(1).value=1.55;
lengthRamp(2).value = 15;


startTime = writeControlFunction600A(fid,startTime,'ms',...
        'Length-Ramp',lengthRamp,auroraConfig);

lengthRamp(1).value = -1.55;
lengthRamp(2).value = 15;

startTime = writeControlFunction600A(fid,startTime,'ms',...
            'Length-Ramp',lengthRamp,auroraConfig);


here=1;