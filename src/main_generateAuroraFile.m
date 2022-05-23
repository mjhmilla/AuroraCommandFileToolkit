% @author M.Millard
% @date May 2022

clc;
close all;
clear all;

numberOfEmptyCommandsPrepended = 30;
%  The Aurora machine appears to ignore the first 9-10 commands and then 
%  begins on the 19th command. Here we prepend a bunch of dummy commands
%  so that your desired signal is not affected.

analogToDigitalSampleRateHz = 5000;
%  This is the rate Aurora's A/D converter will sample signals

postRampPauseTimeInSeconds = 0.0001; 
%  The Aurora system needs a pause time of at least 0.1 ms between ramps

maximumNumberOfCommands = 945;
%  The Aurora system tends to crash if the command file has more than 950 
%  commands. This parameter is used to check how many entries are in the 
%  resulting PRO file. As the process of generating a *.pro file is a bit
%  complicated, the most reliable way to ensure that the *.pro file is of 
%  an acceptable size is to check after the fact.



%Generate the signal
signalType = 2;
signalName = '';
signalOscillations = 10;

commandRateHz      = 200;
commandDeltaTime   = 1/commandRateHz;

maximumMagnitudeLo = 0.05;
paddingPointsToAppend = 10;

maximumCommands    = (maximumNumberOfCommands ...
                      -numberOfEmptyCommandsPrepended ...
                      - paddingPointsToAppend);

commandTimeVector  = [1:1:maximumNumberOfCommands]'...
                        .*(1/commandRateHz);

commandSignal = zeros(size(commandTimeVector));

switch signalType
    case 0
        signalName = 'sinusoid';

        idx1        = numberOfEmptyCommandsPrepended;
        idx2        = length(commandTimeVector)-paddingPointsToAppend;
        arg12       = ([1:1:(idx2-idx1+1)]').*commandDeltaTime;
        arg12Max    = max(arg12);

        commandSignal(1:1:(idx1-1)) = 0;
        commandSignal(idx1:1:idx2,1) = ...
            maximumMagnitudeLo.*sin(arg12*(signalOscillations*2*pi/arg12Max)); 
        commandSignal((idx2+1):1:end) = 0;        




    case 1
        signalName = 'square';

        idx1        = numberOfEmptyCommandsPrepended;
        idx2        = length(commandTimeVector)-paddingPointsToAppend;
        arg12       = ([1:1:(idx2-idx1+1)]').*commandDeltaTime;
        arg12Max    = max(arg12);

        commandSignal(1:1:(idx1-1)) = 0;
        commandSignal(idx1:1:idx2,1) = sin(arg12*(signalOscillations*2*pi/arg12Max)); 
        commandSignal((idx2+1):1:end) = 0;  

        commandSignal( commandSignal > 0) = maximumMagnitudeLo;
        commandSignal( commandSignal < 0) = -maximumMagnitudeLo;

        here=1;

    case 2
        signalName = 'sawtooth';

        %Generate a square wave signal that has half the length we want
        idx1        = 1;
        idx2        = length(commandTimeVector)-paddingPointsToAppend...
                      -numberOfEmptyCommandsPrepended;
        arg12       = ([0:1:(idx2-idx1+1)]').*commandDeltaTime;
        arg12Max    = max(arg12);

        moduloWave  = mod(arg12,arg12Max/signalOscillations); 
        moduloWave  = moduloWave - 0.5*max(moduloWave); 

        commandSignal = [zeros(numberOfEmptyCommandsPrepended,1);...
                         moduloWave(1:1:(end-1));...
                         zeros(paddingPointsToAppend,1)];
        commandSignal = commandSignal .*(...
                            maximumMagnitudeLo / max(abs(commandSignal)));

        assert(length(commandSignal)==length(commandTimeVector));


    otherwise 
        assert(0,['Error: signalType (',num2str(signalType),...
                    ') not recognized']);
end


% Generate a meaningful file name
magnitudeStr = sprintf('%1.4f',max(abs(commandSignal)));
magnitudeStr(strfind(magnitudeStr,'.'))='p';

fileName = sprintf('../output/%s__%s_Lo__%i_osc__%i_HzAD__%i_pre.pro',...
            signalName, ...
            magnitudeStr,...
            signalOscillations,...
            round(analogToDigitalSampleRateHz),...
            numberOfEmptyCommandsPrepended);

% Write the file
[timeVectorExpectedMeasurement,...
    signalExpectedMeasurement] ...
     = writeAuroraCommandFile(...
        commandTimeVector,...
        commandSignal,...
        analogToDigitalSampleRateHz,...
        postRampPauseTimeInSeconds,...
        numberOfEmptyCommandsPrepended,...
        maximumNumberOfCommands, ...
        fileName);

% Read the Aurora command file
auroraCommandFile = readAuroraCommandFile(fileName);

% Plot the commanded signal and the signal we expect to see in the
% measurements
figSignal = figure;
    subplot(2,1,1);
        minVal = min(commandSignal);
        maxVal = max(commandSignal);
        ignoreBoxTime = ...
            [commandTimeVector(1:1:numberOfEmptyCommandsPrepended);...
            fliplr(commandTimeVector(1:1:numberOfEmptyCommandsPrepended)')';...
            commandTimeVector(1,1)];
        ignoreBoxValue = ...
            [ones(numberOfEmptyCommandsPrepended,1).*minVal;...
             ones(numberOfEmptyCommandsPrepended,1).*maxVal;...
             minVal];
        fill(ignoreBoxTime,ignoreBoxValue,[1,1,1].*0.75,...
            'DisplayName','Ignored');
        hold on;

        plot(commandTimeVector,...
            commandSignal,...
            'Color',[1,1,1].*0.75,...
            'LineWidth',2,...
            'DisplayName','desired');
        hold on;

        plot(auroraCommandFile.time,...
             auroraCommandFile.length,...
             'Color',[0,0,0],...
             'LineWidth',0.5,...
             'DisplayName','written')

        plot(timeVectorExpectedMeasurement,...
             signalExpectedMeasurement,'--',...
             'Color',[0,0,1],...
             'DisplayName','measured');


        hold on;
        legend;
        box off;
        xlabel('Time (s)');
        ylabel('Length (Lo)');
        title('Aurora commanded vs. measured length changes');


    subplot(2,1,2);        
        errorSignal = signalExpectedMeasurement ...
                      -interp1(commandTimeVector,...
                               commandSignal,...
                               timeVectorExpectedMeasurement);

        minVal = min(errorSignal);
        maxVal = max(errorSignal);
        ignoreBoxTime = ...
            [commandTimeVector(1:1:numberOfEmptyCommandsPrepended);...
            fliplr(commandTimeVector(1:1:numberOfEmptyCommandsPrepended)')';...
            commandTimeVector(1,1)];
        ignoreBoxValue = ...
            [ones(numberOfEmptyCommandsPrepended,1).*minVal;...
             ones(numberOfEmptyCommandsPrepended,1).*maxVal;...
             minVal];
        fill(ignoreBoxTime,ignoreBoxValue,[1,1,1].*0.75,...
            'DisplayName','Ignored');
        hold on;

        plot(timeVectorExpectedMeasurement,...
             errorSignal,'-',...
             'Color',[1,0,0],'DisplayName','error');
        hold on;
        legend;
        box off;
        xlabel('Time (s)');
        ylabel('Length (Lo)');
        title('Error: measured-desired');

