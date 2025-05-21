function [  stochasticWave, ...
            preConditioningWave, ...
            figPerturbation] = createPerturbationWave(...
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
% stochastic perturbation is applied
%
% 
%%
pointsHalf = configVibration.points/2;    

if(verbose==1)
    fprintf('\n\nSystem Identification Perturbation\n');
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
randomVec = rand(configVibration.points,1);
signOfFirstChange=1;

if(randomVec(pointsHalf,1)>(0.5*(diff(configVibration.holdRange))))
    signOfFirstChange=-1;
end

randomHoldVector = (1-randomVec).*(configVibration.holdRange(1,1)) ...
                  +randomVec.*(configVibration.holdRange(1,2)...
                              -configVibration.holdRange(1,1));

stochasticWave = createSquareWavePattern(configVibration,...
                                           randomHoldVector,...
                                           signOfFirstChange);

stochasticWaveCommands = round(length(stochasticWave.time)*0.5);
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
configConditioning=configVibration;
configConditioning.points           = configVibration.points/2;
configConditioning.frequencyHz      = configVibration.frequencyHz;
configConditioning.magnitude        = configVibration.magnitude;
configConditioning.duration         = (configConditioning.points ...
                                  -.5*configConditioning.frequencyHz) ...
                                  /configConditioning.frequencyHz;  

configConditioning.holdRange = [1,1].*mean(configVibration.holdRange);
constantHoldVector = ones(configConditioning.points,1)...
                   .*mean(configVibration.holdRange);

preConditioningWave = createSquareWavePattern(configConditioning,...
                                           constantHoldVector,...
                                           1);

preConditionWaveCommands = round(length(preConditioningWave.time)*0.5);

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
             preConditioningWave.length,'-','Color',[1,1,1].*0.75,...
             'LineWidth',0.25,'DisplayName','Pre-conditioning');
        hold on;
        plot(stochasticWave.time,...
             stochasticWave.length,'-k',...
             'LineWidth',0.25,'DisplayName','x(t)');
        axis tight;
        xlabel('Time (s)');
        ylabel('Norm. Length (Lo)');
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

