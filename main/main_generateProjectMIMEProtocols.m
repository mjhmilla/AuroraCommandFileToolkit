% @author M.Millard
% @date May 2025

clc;
close all;
clear all;

rootDir        = getRootProjectDirectory('AuroraCommandFileToolkit');
projectFolders = getProjectFolders(rootDir);

addpath(projectFolders.aurora);
addpath(projectFolders.postprocessing);

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
% Trial configuration
%%
experimentConfig.timeIsometricHold = 20;
experimentConfig.postMovementPauseTimeInSeconds ...
        = auroraConfig.postMovementPauseTimeInSeconds;
experimentConfig.maximumRampSpeed = inf;
protocol = createFiberInjuryExperiments(experimentConfig);


idx = 1;
trials(idx).number      = idx;
trials(idx).type        = 'isometric';
trials(idx).takePhoto   = 'Yes';
trials(idx).active      = 1;
trials(idx).startLength = 1.0;
trials(idx).endLength   = 1.0;
trials(idx).endForce    = 0;
trials(idx).time        = [0,timeIsometricHold];
trials(idx).lengthChange= [0,0];
trials(idx).comment     = 'Pre-injury';

filePath = fullfile(projectFolders.output_code,'test.pro');

fileProtocol=fullfile(projectFolders.output_code,'protocol.csv');
fidProtocol = fopen(fileProtocol,'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo','Take_Photo','Comment')

[timeAurora,...
 lengthAurora] ...
     = writeAuroraCommandFileFromStruct(...
        trials(1),...
        auroraConfig,...
        filePath);    

fprintf(fidProtocol, '%i,%s,%1.2f,%s,%s\n',...
    trials(1).number,...
    trials(1).type,...
    trials(1).startLength,...
    trials(1).takePhoto,...
    trials(1).comment);

fclose(fidProtocol);


maxLength = 1.4;

timeInitialActivation= 15;
timeFinalPause       = 15;
timeClosingPause     = max(auroraConfig.postMovementPauseTimeInSeconds,0.1);
lengthChange = 0.2;
rampVelocity = 1; %1 lo/s. Maximum for the EDL is 2.25 lo/s

lengthSetA = [0.6,0.8,1,1.2,1.4];
lengthSetB = lengthSetA - lengthChange;
lengthSetC = lengthSetA;
lengthSetD = lengthSetC + lengthChange;
lengthSetD = min(lengthSetD,ones(size(lengthSetD)).*maxLength);

lengthSet= [lengthSetA,lengthSetC;...
            lengthSetA,lengthSetC;...
            lengthSetB,lengthSetD;...
            lengthSetB,lengthSetD;...
            lengthSetB,lengthSetD];


timeSetStart = ones(size(lengthSet(1,:))).*timeInitialActivation;
timeSetRamp  = ones(size(lengthSet(1,:))).*(lengthChange/rampVelocity);
timeSetEnd   = ones(size(lengthSet(1,:))).*timeFinalPause; 

timeSet = [ zeros(size(timeSetStart));...
            timeSetStart;...
           (timeSetStart+timeSetRamp);...
           (timeSetStart+timeSetRamp+timeSetEnd);...
           (timeSetStart+timeSetRamp+timeSetEnd+timeClosingPause)];

for i=1:1:length(lengthSetA)
    
    commandTimeVector   = timeSet(:,i);
    commandSignal       = lengthSet(:,i);   

    fname = 'ramp';
    fnumber = int2str(i);
    if(length(fnumber)<2)
        fnumber=['0',fnumber];
    end
    fname=[fname,fnumber];

    fileName = sprintf('%s_%1.1f_%1.1f_%1.1f.pro',...
                       fname, lengthSet(1,i),lengthSet(3,i),rampVelocity);
    idx = strfind(fileName,'.');
    idx = idx(1:(end-1));
    fileName(idx)='p';

    filePath = fullfile(projectFolders.output_code,fileName);

    [timeVectorExpectedMeasurement,...
        signalExpectedMeasurement] ...
         = writeAuroraCommandFile(...
            commandTimeVector,...
            commandSignal,...
            auroraConfig,...
            filePath);    

end

