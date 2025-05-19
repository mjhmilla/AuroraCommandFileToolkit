% @author M.Millard
% @date May 2025

clc;
close all;
clear all;

rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.postprocessing);
addpath(projectFolders.experiments);

%%
% Script Configuration
%%
specimenOptimalLengthApprox = 0.0015; %in m
flag_generateRandomSignal   = 1;

%%
% Plot Configuration
%%

plotConfig.numberOfHorizontalPlotColumns    = 1;
plotConfig.numberOfVerticalPlotRows         = 2;
plotConfig.plotWidth                        = 18;
plotConfig.plotHeight                       = 6;
plotConfig.plotHorizMarginCm                = 3;
plotConfig.plotVertMarginCm                 = 3;
plotConfig.baseFontSize                     = 10;

[subplotPanel,plotConfigUpd]=plotConfigGeneric(plotConfig);

%%
% Aurora configuration
%%
%pg 3 of the manual for 322 C-I: 300um in 700us
auroraConfig.maximumRampSpeed = (300e-6/700e-6);

auroraConfig.numberOfEmptyCommandsPrepended = 10;
%  The Aurora machine appears to ignore the first 9-10 commands and then 
%  begins on the 19th command. Here we prepend a bunch of dummy commands
%  so that your desired signal is not affected.

auroraConfig.analogToDigitalSampleRateHz = 5000;
%  This is the rate Aurora's A/D converter will sample signals

auroraConfig.postMovementPauseTimeInSeconds = 0.0001; 
%  The Aurora system needs a pause time of at least 0.1 ms between ramps

auroraConfig.maximumNumberOfCommands = 945;
%  The Aurora system tends to crash if the command file has more than 950 
%  commands. This parameter is used to check how many entries are in the 
%  resulting PRO file. As the process of generating a *.pro file is a bit
%  complicated, the most reliable way to ensure that the *.pro file is of 
%  an acceptable size is to check after the fact.

auroraConfig.comment = 'EDL, h: 0.091 w:  0.079';
%
auroraConfig.minimumNormalizedLength = 0.05;
auroraConfig.maximumNormalizedLength = 2.5;
auroraConfig.pdDeadBand              = 0;
auroraConfig.bathChangeTime          = 0.5;
auroraConfig.bath.passive       = 1;
auroraConfig.bath.preActivation = 2;
auroraConfig.bath.active        = 3;

%%
% Create the system identification vibration signal
%%
if(flag_generateRandomSignal==1)
    configVibration.points           = 2^11;
    configVibration.frequencyHz      = 333;
    configVibration.magnitude        = [0.01];
    configVibration.duration         = 5;
    
    configVibration.paddingDuration  = ...
       ((configVibration.points ...
        /configVibration.frequencyHz) ...
        -configVibration.duration)*0.5;
    
    configVibration.maximumSpeedNorm = ...
        auroraConfig.maximumRampSpeed/specimenOptimalLengthApprox;

    configVibration.rng              = rng('default');
    
    dtMin = configVibration.duration...
           /configVibration.points;
    configVibration.holdRange        = [dtMin*2,0.3];
    
    randomSquareWave = createRandomSquareWavePerturbation(configVibration);
    randomSquareWave.rng    = rng('default');
    randomSquareWave.config = configVibration;
    
    save(fullfile(projectFolders.output_structs,'randomSquareWave.mat'));
else
    load(fullfile(projectFolders.output_structs,'randomSquareWave.mat'));
end

%%
% Trial configuration
%%

configExperiment.postMovementPauseTimeInSeconds = ...
    auroraConfig.postMovementPauseTimeInSeconds;

%Nominal specimen length
configExperiment.optimalSpecimenLength = specimenOptimalLengthApprox;

configExperiment.maximumRampSpeed             = auroraConfig.maximumRampSpeed;
configExperiment.maximumRampSpeedNorm         = ...
        configExperiment.maximumRampSpeed/specimenOptimalLengthApprox;


%Passive settings
configExperiment.passive.holdTime             = [20,20;...
                                                 20,20];
configExperiment.passive.lengths              = [0.6,1.4;... 
                                                 0.6,1.4];
configExperiment.passive.velocity             = [0.1;...
                                                 1.0];
configExperiment.isometric.appendVibration    = [1;1];

%Isometric settings
configExperiment.isometric.holdTime        = [20;20;20];
configExperiment.isometric.lengths         = [0.6;1;1.4];
configExperiment.isometric.appendVibration = [1;1;1];

%Ramp settings
configExperiment.ramp.holdTime            =[20;20;20;20];

configExperiment.ramp.lengths             =[1.1,0.9;...
                                            1.1,0.9;...
                                            0.9,1.1;...
                                            0.9,1.1];

configExperiment.ramp.velocity            =[-(1/3);-(2/3);(1/3);(2/3)];

%Injury settings
configExperiment.injury.length      = [0.7];
configExperiment.injury.endingForce = [2.4];
configExperiment.injury.active      = 1;
configExperiment.injury.type        = 'force'; %passive-ramp, active-ramp, force

%%
% Create the experiments
%%

dateVec = datevec(date());
dateId  = [int2str(dateVec(1,1)),int2str(dateVec(1,2)),int2str(dateVec(1,3))];

trials  = createFiberInjuryExperiments(configExperiment,randomSquareWave,dateId);


%%
% Write the pro files and the csv file to disk
%%

protocolName = ['protocol_',dateId,'.csv'];
fileProtocol    = fullfile(projectFolders.output_code,protocolName);
fidProtocol     = fopen(fileProtocol,'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo','Take_Photo','Block','FileName','Comment')

for i=1:1:length(trials)

    filePath = fullfile(projectFolders.output_code,trials(i).name);
    
    [trials(i).timeAurora,...
     trials(i).lengthAurora] ...
         = writeAuroraCommandFileFromStruct(...
            trials(i),...
            auroraConfig,...
            filePath);    
    
    fprintf(fidProtocol, '%i,%s,%1.2f,%s,%s,%s,%s\n',...
        trials(i).number,...
        trials(i).type,...
        trials(i).startLength,...
        trials(i).takePhoto,...
        trials(i).block,...
        trials(i).name,...
        trials(i).comment);
end
fclose(fidProtocol);



