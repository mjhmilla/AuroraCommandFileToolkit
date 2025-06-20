function [  stochasticWave, ...
            preConditioningWave, ...
            figPerturbation] = createPerturbationWaveUpd(...
                                  controlFunctionName,...
                                  configVibration,...
                                  auroraConfig,...
                                  figPerturbation,...
                                  perturbationPlotConfig,...
                                  verbose)
%%
% @return stochasticWave
% A pseudo-random stochastic perturbation signal for use
% in system identification as applied to muscle fibers
%
% @return preConditioningWave
% An isometric fiber's force drops immediately once its length is perturbed
% to a lower value. This makes the system time-variant. To make the 
% response more consistent with an LTI system, here we generate a set of 
% vibrations that can be used prior to the stochastic wave in order to 
% pre-condition it so that its mean force does not drop when the 
% stochastic perturbation is applied.
%
% The other option is to perturb in the force domain, which is possible
% with the Aurora machine.
% 
%%
pointsHalf = configVibration.points/2;    

if(verbose==1)
    fprintf('\n\nSystem Identification Perturbation\n');
    fprintf('\t%s\tWaveform\n',controlFunctionName);
    fprintf('\t%1.2e s\tDuration\n',configVibration.duration);
    fprintf('\t%1.2e\ttmin\n',...
        (configVibration.holdRange(1,1)));
    fprintf('\t%1.2e\ttmax\n',...
        (configVibration.holdRange(1,2)));    
    fprintf('\t%1.2e\ttmax/tmin\n',...
        (configVibration.holdRange(1,2)/configVibration.holdRange(1,1)));
end

%%
%  Create the random hold vector vector
%%
rng(1,'twister'); 
randomVecA = rand(configVibration.points,1);

rng(2,'twister'); 
randomVecB = rand(configVibration.points,1);

rng(3,'twister'); 
randomVecC = rand(configVibration.points,1);

rng(4,'twister'); 
randomVecD = rand(configVibration.points,1);

rng(5,'twister'); 
randomVecE = rand(configVibration.points,1);

signOfFirstChange=1;




if(length(configVibration.holdRange) == 2 ...
        && abs(diff(configVibration.holdRange)) > 0)
    randomSignals.duration = ...
       (1-randomVecA).*(configVibration.holdRange(1,1)) ...
          +randomVecA.*(configVibration.holdRange(1,2)...
                       -configVibration.holdRange(1,1));
else
    randomSignals.duration = ones(size(randomVecA)).*configVibration.holdRange(1,1);
end

if(length(configVibration.normSpeedRange) == 2 ...
        && abs(diff(configVibration.normSpeedRange)) > 0 )
    randomSignals.velocity = ...
        (1-randomVecB).*(configVibration.normSpeedRange(1,1)) ...
           +randomVecB.*(configVibration.normSpeedRange(1,2)...
                        -configVibration.normSpeedRange(1,1));
else
    randomSignals.velocity = ones(size(randomVecA)).*configVibration.normSpeedRange(1,1);
end

if(length(configVibration.frequencyRange) == 2 ...
        && abs(diff(configVibration.frequencyRange)) > 0 )
    randomSignals.frequency = ...
        (1-randomVecC).*(configVibration.frequencyRange(1,1)) ...
           +randomVecC.*(configVibration.frequencyRange(1,2)...
                        -configVibration.frequencyRange(1,1));
else
    randomSignals.frequency = ones(size(randomVecC)).*configVibration.frequencyRange(1,1);
end

if(length(configVibration.magnitudeRange) == 2 ...
        && abs(diff(configVibration.magnitudeRange)) > 0 )

    randomSignals.magnitude = ...
        (1-randomVecD).*(configVibration.magnitudeRange(1,1)) ...
           +randomVecD.*(configVibration.magnitudeRange(1,2)...
                        -configVibration.magnitudeRange(1,1));
else
    randomSignals.magnitude = ones(size(randomVecD)).*configVibration.magnitudeRange(1,1);
end

if(length(configVibration.waitTimeRange)==2 ...
        && abs(diff(configVibration.waitTimeRange)) > 0)
    randomSignals.wait = ...
        (1-randomVecE).*(configVibration.waitTimeRange(1,1)) ...
           +randomVecE.*(configVibration.waitTimeRange(1,2)...
                        -configVibration.waitTimeRange(1,1));
else
    randomSignals.wait = ones(size(randomVecE)).*configVibration.waitTimeRange(1,1);
end



switch controlFunctionName
    case 'Length-Ramp'    
        if(randomVecA(pointsHalf,1)>(0.5*(diff(configVibration.holdRange))))
            signOfFirstChange=-1;
        end        
    
        [timeVec,signalVec,stochasticWaveCommands] =...
            createSquareWavePatternUpd(...
                             configVibration,...
                             randomSignals.duration,...
                             randomSignals.velocity,...
                             signOfFirstChange);
    case 'Length-Sine'

        [timeVec,signalVec,stochasticWaveCommands] = ...
            createSineWavePattern(...
                            configVibration,...
                            randomSignals.frequency,...
                            randomSignals.magnitude,...
                            randomSignals.wait);

    otherwise
        assert(0,['Error: no signal generator has been written for ',...
                    controlFunctionName]);
end

stochasticWave = analyzeSignalSpectrum(controlFunctionName, ...
                                    timeVec, signalVec,configVibration);

% The wave requires half the number of commands as time 
% entries because the 0-hold length changes are not written to file

fprintf('\t%i\tNumber of perturbation commands\n',...
        stochasticWaveCommands);

stochasticWave.config = configVibration;


%%
% Get the conditioning vibration vector
%
% During pilot experiments we noticed that the output force of the
% fiber would drop as soon as any vibration was introduced. This
% lead to a non-stationary change in force. Here we apply a constant
% square wave signal to the fiber so that its force drops. Then after
% a quiesent period we apply the perturbation. 
%%





configConstant=configVibration;
configConstant.points = round(configVibration.points/4);
configConstant.duration = configVibration.duration/4;
configConstant.holdRange = [1,1].*mean(configVibration.holdRange);

constantHoldVector = ones(configConstant.points,1)...
                   .*mean(configVibration.holdRange);

constantFrequencyVector = ones(configConstant.points,1)...
                   .*mean(configVibration.frequencyRange);

constantVelocityVector = ones(configConstant.points,1)...
                   .*mean(configVibration.normSpeedRange);

constantMagnitudeVector = ones(configConstant.points,1)...
                   .*mean(configVibration.magnitudeRange);

constantWaitVector = ones(configConstant.points,1)...
                   .*mean(configVibration.waitTimeRange);


switch controlFunctionName
    case 'Length-Ramp'
    
        if(randomVecA(configConstant.points,1)>(0.5*(diff(configVibration.holdRange))))
            signOfFirstChange=-1;
        end        
    
        [timeVec, signalVec, preConditionWaveCommands] = ...
            createSquareWavePatternUpd(configConstant,...
                                       constantHoldVector,...
                                       constantVelocityVector,...
                                       1);
    case 'Length-Sine'
        [timeVec,signalVec,preConditionWaveCommands] = ...
            createSineWavePattern(  configConstant,...
                                    constantFrequencyVector,...
                                    constantMagnitudeVector,...
                                    constantWaitVector);        

    otherwise
        assert(0,['Error: no signal generator has been written for ',...
                    controlFunctionName]);
end

preConditioningWave = analyzeSignalSpectrum(controlFunctionName, ...
                                  timeVec, signalVec,configConstant);


if(verbose==1)
    fprintf('\t%i\tNumber of pre-conditioning commands\n',...
            preConditionWaveCommands);
end


totalNumberOfSystemIdCommands = ...
    stochasticWaveCommands ...
   +preConditionWaveCommands;

assert(totalNumberOfSystemIdCommands < auroraConfig.maximumNumberOfCommands,...
    'Error: System id exceeded the maximum number of commands');

if(verbose==1)
    fprintf('\t%i\tNumber of commands remaining\n',...
         (auroraConfig.maximumNumberOfCommands...
         -totalNumberOfSystemIdCommands));
end
%%
%
%%
if(isempty(figPerturbation)==0)
        
    subplotPanel = perturbationPlotConfig.subplot;
    plotConfig   = perturbationPlotConfig.config;

    figure(figPerturbation);
    subplot('Position',reshape(subplotPanel(1,1,:),1,4));
        plot((preConditioningWave.time-max(preConditioningWave.time)),...
             preConditioningWave.signal,'-','Color',[1,1,1].*0.75,...
             'LineWidth',0.25,'DisplayName','Pre-conditioning');
        hold on;
        plot(stochasticWave.time,...
             stochasticWave.signal,'-k',...
             'LineWidth',0.25,'DisplayName','x(t)');
        axis tight;
        xlabel('Time (s)');
        ylabel('Amplitude');
        title('Conditioning and perturbation waveform');
        legend('Location','NorthWest');
        %legend boxoff;
        box off;
        hold on;
    
    
    figure(figPerturbation);
    subplot('Position',reshape(subplotPanel(2,1,:),1,4));
        normPower=stochasticWave.p(1:pointsHalf,1)...
               ./max(stochasticWave.p(1:pointsHalf,1));
        plot(stochasticWave.freqHz(1:pointsHalf,1),...
             normPower,'-','Color',[1,1,1].*0.75,...
             'LineWidth',0.25,'DisplayName','pxx(x(t))');
        hold on;
    
        meanFreq = sum(stochasticWave.fwHz.*stochasticWave.pw) ...
                  ./sum(stochasticWave.pw);
        [valPeak,idxPeak] = max(stochasticWave.pw);
        
        pwN = stochasticWave.pw./max(stochasticWave.pw);
    
        plot(stochasticWave.fwHz,...
             pwN,'-k',...
             'LineWidth',0.25,'DisplayName','pwelch(x(t))');
        hold on;
        plot(stochasticWave.fwHz(idxPeak),pwN(idxPeak),'o',...
            'MarkerFaceColor',[0,0,0],...
            'HandleVisibility','off');        
        hold on;
        text(stochasticWave.fwHz(idxPeak)*1.05,pwN(idxPeak),...
             sprintf('Peak: %1.2f Hz',stochasticWave.fwHz(idxPeak)),...
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
       


    configPlotExporter(figPerturbation,plotConfig);
end

