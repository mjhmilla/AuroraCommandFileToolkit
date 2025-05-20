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
flag_plotRandomSignal       = 1;

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
%   This is quite challenging because we are limited to 945 commands.
%%
if(flag_generateRandomSignal==1)
    configVibration.points           = 2^12;
    configVibration.frequencyHz      = 1000;
    configVibration.magnitude        = [0.01];
    configVibration.duration         = (configVibration.points ...
                                      -1.5*configVibration.frequencyHz) ...
                                      /configVibration.frequencyHz;
    pointsHalf = configVibration.points/2;    
    
    fprintf('\n\nSystem Identification Perturbation\n');
    fprintf('\t%1.2e s\tDuration\n',configVibration.duration);
    
    configVibration.paddingDuration  = ...
       ((configVibration.points ...
        /configVibration.frequencyHz) ...
        -configVibration.duration)*0.5;
    
    configVibration.maximumSpeedNorm = ...
        auroraConfig.maximumRampSpeed/specimenOptimalLengthApprox;

       
    dtMin = (configVibration.duration+2*configVibration.paddingDuration)...
           /configVibration.points;
    configVibration.holdRange        = [4,30].*(dtMin);
    
    fprintf('\t%1.2e\ttmin\n',...
        (configVibration.holdRange(1,1)));
    fprintf('\t%1.2e\ttmax\n',...
        (configVibration.holdRange(1,2)));    
    fprintf('\t%1.2e\ttmax/tmin\n',...
        (configVibration.holdRange(1,2)/configVibration.holdRange(1,1)));

    %%
    %  Create the random hold vector vector
    %%
    rng(1,'twister'); 
    randomVec = rand(configVibration.points,1);
    signOfFirstChange=1;

    if(randomVec(pointsHalf,1)>(0.5*(diff(configVibration.holdRange))))
        signOfFirstChange=-1;
    end

    randomHoldVector = (1-randomVec).*(configVibration.holdRange(1,1)) ...
                      +randomVec.*(configVibration.holdRange(1,2)...
                                  -configVibration.holdRange(1,1));
    
    randomSquareWave = createSquareWavePattern(configVibration,...
                                               randomHoldVector,...
                                               signOfFirstChange);

    fprintf('\t%i\tNumber of perturbation commands\n',...
            length(randomSquareWave.time));
    
    randomSquareWave.config = configVibration;

    save(fullfile(projectFolders.output_structs,'randomSquareWave.mat'),...
         'randomSquareWave','-mat');    
    %%
    % Get the conditioning vibration vector
    %
    % During pilot experiments we noticed that the output force of the
    % fiber would drop as soon as any vibration was introduced. This
    % lead to a non-stationary change in force. Here we apply a constant
    % square wave signal to the fiber so that its force drops. Then after
    % a quiesent period we apply the perturbation. 
    %%
    configConditioning=configVibration;
    configConditioning.points           = configVibration.points/2;
    configConditioning.frequencyHz      = configVibration.frequencyHz;
    configConditioning.magnitude        = [0.01];
    configConditioning.duration         = (configConditioning.points ...
                                      -.5*configConditioning.frequencyHz) ...
                                      /configConditioning.frequencyHz;  

    configConditioning.holdRange = [1,1].*mean(configVibration.holdRange);
    constantHoldVector = ones(configConditioning.points,1)...
                       .*mean(configVibration.holdRange);

    constantSquareWave = createSquareWavePattern(configConditioning,...
                                               constantHoldVector,...
                                               1);
    fprintf('\t%i\tNumber of pre-conditioning commands\n',...
            length(constantSquareWave.time));

    save(fullfile(projectFolders.output_structs,'constantSquareWave.mat'),...
         'constantSquareWave','-mat');

    totalNumberOfSystemIdCommands = ...
       length(constantSquareWave.time) ...
       +length(randomSquareWave.time);

    assert(totalNumberOfSystemIdCommands < auroraConfig.maximumNumberOfCommands,...
        'Error: System id exceeded the maximum number of commands');

    fprintf('\t%i\tNumber of commands remaining\n',...
         (auroraConfig.maximumNumberOfCommands...
         -totalNumberOfSystemIdCommands));
    %%
    %
    %%
    figH=figure;

    figure(figH);
    subplot('Position',reshape(subplotPanel_2R1C(1,1,:),1,4));
        plot((constantSquareWave.time-max(constantSquareWave.time)),...
             constantSquareWave.length,'-','Color',[1,1,1].*0.75,...
             'LineWidth',0.25,'DisplayName','Pre-conditioning');
        hold on;
        plot(randomSquareWave.time,...
             randomSquareWave.length,'-k',...
             'LineWidth',0.25,'DisplayName','x(t)');
        axis tight;
        xlabel('Time (s)');
        ylabel('Norm. Length (Lo)');
        title('Conditioning and perturbation waveform');
        legend('Location','NorthWest');
        %legend boxoff;
        box off;
        hold on;


    figure(figH);
    subplot('Position',reshape(subplotPanel_2R1C(2,1,:),1,4));
        normPower=randomSquareWave.p(1:pointsHalf,1)...
               ./max(randomSquareWave.p(1:pointsHalf,1));
        plot(randomSquareWave.freqHz(1:pointsHalf,1),...
             normPower,'-','Color',[1,1,1].*0.75,...
             'LineWidth',0.25,'DisplayName','pxx(x(t))');
        hold on;

        meanFreq = sum(randomSquareWave.fwHz.*randomSquareWave.pw) ...
                  ./sum(randomSquareWave.pw);
        [valPeak,idxPeak] = max(randomSquareWave.pw);
        
        pwN = randomSquareWave.pw./max(randomSquareWave.pw);

        plot(randomSquareWave.fwHz,...
             pwN,'-k',...
             'LineWidth',0.25,'DisplayName','pwelch(x(t))');
        hold on;
        plot(randomSquareWave.fwHz(idxPeak),pwN(idxPeak),'o',...
            'MarkerFaceColor',[0,0,0],...
            'HandleVisibility','off');        
        hold on;
        text(randomSquareWave.fwHz(idxPeak)*1.05,pwN(idxPeak),...
             sprintf('Peak: %1.2f Hz',randomSquareWave.fwHz(idxPeak)),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','top');
        hold on;
        plot([1;1].*meanFreq,[0;0.5],'-','Color',[1,1,1],...
             'LineWidth',2,...
             'HandleVisibility','off');
        hold on;
        plot([1;1].*meanFreq,[0;0.5],'-','Color',[0,0,1],...
             'HandleVisibility','off');
        hold on;
        text(meanFreq*1.05,0.5,...
             sprintf('Mean: %1.2f Hz',meanFreq),...
             'HorizontalAlignment','left',...
             'VerticalAlignment','middle');
        hold on;

        legend('Location','NorthEast');
        %legend boxoff;
        axis tight;
        box off;
        xlabel('Frequency (Hz)');
        ylabel('Norm. Power');
        title('Peturbation power spectrum');  
       

    
    configPlotExporter(figH,plotConfig_2R1C);
    saveas(figH,fullfile(projectFolders.output_plots,'fig_randomSquareWave'),'pdf');
    savefig(figH,fullfile(projectFolders.output_plots,'fig_randomSquareWave.fig'));
        


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

trials  = createFiberInjuryExperiments(...
            configExperiment,...
            constantSquareWave,...
            randomSquareWave,...
            dateId);


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



