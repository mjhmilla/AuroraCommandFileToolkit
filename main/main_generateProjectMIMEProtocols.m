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
%pg 3 of the manual for 322 C-I: 300um in 700us
auroraConfig.maximumRampSpeed = (300e-6/700e-6);

auroraConfig.numberOfEmptyCommandsPrepended = 10;
%  The Aurora machine appears to ignore the first 9-10 commands and then 
%  begins on the 19th command. Here we prepend a bunch of dummy commands
%  so that your desired signal is not affected.

auroraConfig.analogToDigitalSampleRateHz = 1000;
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
auroraConfig.minimumNormalizedLength = 0.2;
auroraConfig.maximumNormalizedLength = 1.5;
auroraConfig.pdDeadBand              = 0;
auroraConfig.bath.changeTime            = 0.5;
auroraConfig.bath.preActivationDuration = 60;
auroraConfig.bath.passive       = 1;
auroraConfig.bath.preActivation = 2;
auroraConfig.bath.active        = 3;

%%
% System identification perturbation signal configuration
%%
configVibration.points           = 2^12;
configVibration.frequencyHz      = 500;
configVibration.magnitude        = [0.001];
configVibration.duration         = (configVibration.points ...
                                  -1.5*configVibration.frequencyHz) ...
                                  /configVibration.frequencyHz;
configVibration.command          ='Length-Ramp';
configVibration.paddingDuration  = ...
   ((configVibration.points ...
    /configVibration.frequencyHz) ...
    -configVibration.duration)*0.5;

configVibration.normSpeedRange = [0.1,1];

dtMin = (configVibration.duration+2*configVibration.paddingDuration)...
       /configVibration.points;
configVibration.holdRange        = [(1/100),(1/10)];

assert(max(configVibration.holdRange) > dtMin);

%%
% Create the system identification vibration signal
%   This is quite challenging because we are limited to 945 commands.
%%
if(flag_generateRandomSignal==1)
    verbose=1;
    figPerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_2R1C;
    perturbationPlotConfig.config = plotConfig_2R1C;

    [stochasticWave, ...
    preConditioningWave, ...
    figPerturbation] = createPerturbationWave(configVibration,...
                                                auroraConfig, ...
                                                figPerturbation,...
                                                perturbationPlotConfig,...
                                                verbose);

    save(fullfile(projectFolders.output_structs,'stochasticWave.mat'),...
         'stochasticWave','-mat');        
    save(fullfile(projectFolders.output_structs,'preConditioningWave.mat'),...
         'preConditioningWave','-mat');    
    
    saveas(figPerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSquareWave'),'pdf');
    savefig(figPerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomSquareWave.fig'));    
else
    load(fullfile(projectFolders.output_structs,'stochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'preConditioningWave.mat'));
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
configExperiment.passive.appendVibration    = [1;1];

%Isometric settings
configExperiment.isometric.holdTime        = [20;20;20];
configExperiment.isometric.lengths         = [0.6;1;1.4];
configExperiment.isometric.appendVibration = [1;1;1];

%Ramp settings
configExperiment.ramp.holdTime            =[20,20;...
                                            20,20;...
                                            20,20;...
                                            20,20];

configExperiment.ramp.lengths             =[1.1,0.9;...
                                            1.1,0.9;...
                                            0.9,1.1;...
                                            0.9,1.1];

configExperiment.ramp.velocity            =[-(1/3);...
                                            -(2/3);...
                                             (1/3);...
                                             (2/3)];

configExperiment.ramp.appendVibration     =[0;0;0;0];

%Injury settings - using stretch-shortening
configExperiment.injury.holdTime    = [20,2;...
                                       20,2;
                                       20,2;...
                                       20,2;...
                                       20,2;...
                                       20,2];

configExperiment.injury.lengths     = [0,0.5,0;...
                                       0,0,0;...
                                       0,0.75,0;...
                                       0,0,0;...
                                       0,1.0,0;...
                                       0,0,0];

configExperiment.injury.velocity    = [(2/3),-(2/3);...
                                       0,0;...
                                       (2/3),-(2/3);...
                                       0,0;...
                                       (2/3),-(2/3);...
                                       0,0];
configExperiment.injury.comments = ...
    {'Injury','If Fmax is 20% lower skip remaining injury block',...
     'Injury','If Fmax is 20% lower skip remaining injury block',...
     'Injury','If Fmax is 20% lower skip remaining injury block'};

configExperiment.injury.type = {'injury','isometricTest',...
                                'injury','isometricTest',...
                                'injury','isometricTest'};
configExperiment.injury.active      = 1;

%%
% Create the experiments
%%

dateVec = datevec(date());
dateId  = [int2str(dateVec(1,1)),int2str(dateVec(1,2)),int2str(dateVec(1,3))];

trials  = createFiberInjuryExperiments(...
            configExperiment,...
            preConditioningWave,...
            stochasticWave,...
            dateId);


%%
% Write the pro files and the csv file to disk
%%

protocolName = ['protocol_',dateId,'.csv'];
fileProtocol    = fullfile(projectFolders.output_code,protocolName);
fidProtocol     = fopen(fileProtocol,'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo',...
    'Take_Photo','Block','FileName','Comment');

figTest=figure;

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

    auroraCommands = readAuroraCommandFile(filePath);
    
    %%
    %Check for errors
    %%
    if(isempty(auroraCommands.time)==0)
        dtMinA = min(diff(trials(i).time));
        dtMinB = min(diff(auroraCommands.time));
        dtMin = min([dtMinA,dtMinB]);
        dtMin = dtMin*0.2;
    
        %Super sample the length changes ramps to a common time    
        timeSuper = [0:dtMin:max(trials(i).time+auroraCommands.time(1,1))]';
    
        trialLengthSuper = interp1(trials(i).time+trials(i).timeAurora(1,1),...
                              trials(i).signal,...
                              timeSuper);
    
        writtenLengthSuper = interp1(trials(i).timeAurora,...
                              trials(i).lengthAurora,...
                              timeSuper);
        if(i==12)
            here=1;
        end
        readLengthSuper = interp1(auroraCommands.time,...
                              auroraCommands.length,...
                              timeSuper);
        
        lerrWritten = writtenLengthSuper-trialLengthSuper;
        lerrRead    = readLengthSuper-trialLengthSuper;    
    

        if(abs(max(lerrWritten)) >= (configVibration.magnitude*0.5))
            here=1;
        end
        if(abs(max(lerrRead)) >= (configVibration.magnitude*0.5))
            here=1;
        end
%         assert(abs(max(lerrWritten)) < (configVibration.magnitude*0.5),...
%                ['Error: written length change has an error that exceeds the ',...
%                 'the perturbation magnitude.']);
%     
%         assert(abs(max(lerrRead)) < (configVibration.magnitude*0.5),...
%                ['Error: read length change has an error that exceeds the ',...
%                 'the perturbation magnitude.']);
    end

    if(isempty(auroraCommands.time)==0)
        clf(figTest);
        figure(figTest);
        subplot(2,3,1);
            plot(trials(i).time,...
                 trials(i).signal,'-','Color',[1,1,1].*0.5);
            hold on;
            xlabel('Time (s)');
            ylabel('Length (Lo)');
            title('Desired');
        subplot(2,3,2);        
            plot(trials(i).time+trials(i).timeAurora(1,1),...
                 trials(i).signal,'-','Color',[1,1,1].*0.5);
            hold on;
    
            plot(trials(i).timeAurora,...
                 trials(i).lengthAurora,'--b');
            hold on; 
            title('Written (rounded)');
        subplot(2,3,3);        
            plot(trials(i).time+trials(i).timeAurora(1,1),...
                 trials(i).signal,'-','Color',[1,1,1].*0.5);
            hold on;    
            plot(auroraCommands.time,...
                 auroraCommands.length,'--r');
            hold on;
            xlabel('Time (s)');
            ylabel('Length (Lo)');
            title('Read (from file)');
    
        %Errors

    
        subplot(2,3,5);
            plot(timeSuper,lerrWritten,'b');
            hold on;
            xlabel('Time (s)');
            ylabel('Length Error (Lo)');
            title('Written (error)');
    
        subplot(2,3,6);
            plot(timeSuper,lerrRead,'r');
            hold on;
            xlabel('Time (s)');
            ylabel('Length Error (Lo)');
            title('Read (error)');
    
            here=1;
    end
end
fclose(fidProtocol);




