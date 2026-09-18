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
addpath(projectFolders.common);
addpath(projectFolders.signals);

%%
% Script configuration
%%
flag_generateRandomSignal               = 0;
flag_generateExponentiallySpacedSinusoids=0;

% Experiments to generate
flag_generateRubberProtocol                     = 0;
flag_generateForceRampProtocol                  = 0;
flag_generateTRSS2017PerturbationProtocol       = 0;
flag_generateInjuryProtocol                     = 0;

flag_generateArbitraryWaveImpedanceProtocol     = 0; 

flag_generateImpedanceForceLengthProtocol_Sine  = 0; %For length/sine
flag_generateImpedanceForceLengthProtocol_Larb  = 0; %For larb
flag_generateImpedanceAmplitudeProtocol_Larb    = 0;

flag_generateCalibrationProtocol                = 0;
flag_generateLarbSinusoidImpedanceProtocol      = 1;


settingsExperiment = [];

flag_generateMetaDataForACollection = 0;

if(flag_generateMetaDataForACollection==1)
    settingsExperiment.clean = 1;
    settingsExperiment.trialOrder = [1:12];
    settingsExperiment.nameModification = '1';
    settingsExperiment.folderName = '';
    settingsExperiment.date.y = [];
    settingsExperiment.date.m = [];
    settingsExperiment.date.d = [];
    settingsExperiment.dataPathSha256 = [];
end

perturbationSettings.points =2^12;
perturbationSettings.magnitude = 0.01;
perturbationSettings.bandwidth = 'high';
% 'high'
% 'low'
perturbationSettings.waveType = 'larb';
% 'lengthRamp'
% 'sineWave'
% 'larb


% 0. Lower-frequency Length-Ramp & Sine-Wave 
% 1. Higher-frequency Length-Ramp & Sine-Wave
% 2. Arbitrary Waveform
% Applies to the random Length-Ramp and Sine-Ramp waveforms.

if(        flag_generateArbitraryWaveImpedanceProtocol ...
        || flag_generateImpedanceForceLengthProtocol_Larb ...
        || flag_generateImpedanceAmplitudeProtocol_Larb ...
        || flag_generateCalibrationProtocol)
    perturbationSettings.waveType = 'larb';
end

%
% Default arbitrary waveform settings
%
mergedArbitraryWaveformSettings.paddingTime = 1;

arbitraryWaveformManualSettings.lengthUnits   = 'rel';
arbitraryWaveformManualSettings.magnitude     = 0.01;
arbitraryWaveformManualSettings.distribution  = 'normal';
arbitraryWaveformManualSettings.bandwidth     = 90;
arbitraryWaveformManualSettings.seed          = 6;
arbitraryWaveformManualSettings.lengthUnit    = 'Lo';
dateId = getDateId();
arbitraryWaveformManualSettings.fileName = ['larb_',dateId];

arbitraryWaveformManualSettings.frequencyHz   = ...
    [1000,1000,1000,1000,  1000];        
arbitraryWaveformManualSettings.points        = ...
    [2^12,2^12,2^12,2^12,  454];
arbitraryWaveformManualSettings.magnitude     = ...
    [0.01, 0.01, 0.001, 0.001,  0.001];
arbitraryWaveformManualSettings.bandwidth     = ...
    [35, 90, 35, 90, 90];
arbitraryWaveformManualSettings.canBeMerged = ...
    [1,1,1,1, 0];
arbitraryWaveformManualSettings.paddingDuration= ...
    round(arbitraryWaveformManualSettings.points.*0.05) ...
    ./arbitraryWaveformManualSettings.frequencyHz;

assert( arbitraryWaveformManualSettings.seed==6,...
    'Error: changing the seed from 6 will generate different random waves');

if(flag_generateArbitraryWaveImpedanceProtocol==1)
    arbitraryWaveformManualSettings.frequencyHz   = 1000;

    arbitraryWaveformManualSettings.points        = ...
        [2^13,2^13,2^13,2^13];
    arbitraryWaveformManualSettings.magnitude     = ...
        [0.01, 0.01, 0.001, 0.001];
    arbitraryWaveformManualSettings.bandwidth     = ...
        [35, 90, 35, 90];        
    arbitraryWaveformManualSettings.canBeMerged = ...
        [1,1,1,1];   
    arbitraryWaveformManualSettings.paddingDuration= ...
        [1,1,1,1].*0.125;
end

if(flag_generateLarbSinusoidImpedanceProtocol==1)
    arbitraryWaveformManualSettings.frequencyHz   = 1000;

    arbitraryWaveformManualSettings.points        = ...
        [2^13,2^13,2^13,2^13,2^13];
    arbitraryWaveformManualSettings.magnitude     = ...
        [0.01, 0.01, 0.001, 0.001,0.002];
    arbitraryWaveformManualSettings.bandwidth     = ...
        [35, 90, 35, 90,90];        
    arbitraryWaveformManualSettings.canBeMerged = ...
        [1,1,1,1,0];   
    arbitraryWaveformManualSettings.paddingDuration= ...
        [1,1,1,1,1].*0.125;
end

if(flag_generateImpedanceAmplitudeProtocol_Larb==1)
    arbitraryWaveformManualSettings.frequencyHz   = 1000;
    arbitraryWaveformManualSettings.points          = [2^13,2^13];
    arbitraryWaveformManualSettings.magnitude       = [1,1];
    arbitraryWaveformManualSettings.bandwidth       = [35, 90];        
    arbitraryWaveformManualSettings.canBeMerged     = [1,1];   
    arbitraryWaveformManualSettings.paddingDuration = [1,1].*0.125;
end

if(flag_generateCalibrationProtocol==1)
    arbitraryWaveformManualSettings.frequencyHz     = 1000;
    arbitraryWaveformManualSettings.points          = [2^13];
    arbitraryWaveformManualSettings.magnitude       = [1];
    arbitraryWaveformManualSettings.bandwidth       = [90];        
    arbitraryWaveformManualSettings.canBeMerged     = [1];   
    arbitraryWaveformManualSettings.paddingDuration = [1].*0.125;
end





rubber.approximateSampleLengthInMM=1.183;
rubber.minNormLength              = 0.75; %short is fine
rubber.maxNormLength              = 1.02; %long is not
rubber.maxNormalizedSpeedLPS      = 2.0;

ratMuscleName                   = 'EDL';
approximateSampleLengthInMM     = 1.5;
sampleFrequency                 = 1000;
sampleFrequencySlow             = 100;
minNormLength                   = 0.5;
maxNormLength                   = 1.85;

if(flag_generateCalibrationProtocol==1)
  sampleFrequency=4000;
end

minActivationTimeS=nan;
commentStr = '';
switch ratMuscleName
    case 'SOL'
        minActivationTimeS = 5; %2026/08/20 SW says 3-5 seconds
        maxNormalizedShorteningSpeedLPS = 1.02;         
        % in units of norm fiber lengths/second        
        commentStr = 'EDL, h: xxx w:  xxx';
    case 'EDL'
        minActivationTimeS = 2; %2026/08/20 SW says 1-2 seconds
        maxNormalizedShorteningSpeedLPS = 2.25;  
        commentStr = 'SOL, h: xxx w:  xxx';        
    otherwise 
        assert(0,'Error: muscleName not found');
end

auroraConfig = getDefaultAuroraConfiguration600A(...
                    minActivationTimeS,...
                    approximateSampleLengthInMM,...
                    sampleFrequency,...
                    minNormLength,...
                    maxNormLength,...
                    maxNormalizedShorteningSpeedLPS,...
                    commentStr);


auroraConfigSlow = getDefaultAuroraConfiguration600A(...
                    minActivationTimeS,...
                    approximateSampleLengthInMM,...
                    sampleFrequencySlow,...
                    minNormLength,...
                    maxNormLength,...
                    maxNormalizedShorteningSpeedLPS,...
                    commentStr);


%%
% Experiment settings
%%
expSettings = getExperimentSettings(maxNormalizedShorteningSpeedLPS); 


%%
% Set perturbation settings
%%
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

muscleTemperatureInC        = 12;


%%
% Create the exponentially spaced sinusoids used by Kawai to measure the
% response of muscle fibers
%%
if(flag_generateExponentiallySpacedSinusoids==1)
  
  sinSettings.maxFrequencyHz                    = 167*1.43526477;
  sinSettings.minFrequencyHz                    = 0.25;
  sinSettings.numberOfSinusoids                 = 20;
  %sinSettings.maxSinusoidDurationS              = (1/sinSettings.minFrequencyHz)+sqrt(eps);
  sinSettings.preferredSinusoidDurationS        = 1;
  sinSettings.minCycleCount                     = 1;
  sinSettings.maxCycleCount                     = inf;
  sinSettings.maxAngularErrorDegrees            = 0.1;
  sinSettings.frequencyHzTolerancePercentage    = 0.075;
  sinSettings.flag_correctFrequencyToSampleRate =1;

  sineSeriesExponentiallySpaced = ...
    generateExponentiallySpacedSinusoids(sampleFrequency,...
                                         sinSettings,...
                                         auroraConfig,...
                                         1);

  save(fullfile(projectFolders.output_structs,...
       'sineSeriesExponentiallySpaced.mat'),...
       'sineSeriesExponentiallySpaced','-mat');    
else
  filePath=fullfile(projectFolders.output_structs,...
          'sineSeriesExponentiallySpaced.mat');
  load(filePath);    
  fprintf('\nSine-series file loaded\n\t%s\n\n',filePath);
  
end

%%
% Create the system identification vibration signal
%   This is quite challenging because we are limited to 945 commands.
%%
if(flag_generateRandomSignal==1)
    %%
    % Square
    %%
    plotConfig.numberOfHorizontalPlotColumns    = 1;
    plotConfig.numberOfVerticalPlotRows         = 3;
    plotConfig.plotWidth                        = 15;
    plotConfig.plotHeight                       = 5;
    plotConfig.plotHorizMarginCm                = 3;
    plotConfig.plotVertMarginCm                 = 3;
    plotConfig.baseFontSize                     = 6;
    
    [subplotPanel_lengthRamp,plotConfig_lengthRamp]=...
        plotConfigGeneric(plotConfig);

    verbose=1;
    figSquarePerturbation=figure;

    perturbationPlotConfig.subplot= subplotPanel_lengthRamp;
    perturbationPlotConfig.config = plotConfig_lengthRamp;
    perturbationPlotConfig.column=1;


    configVibration = ...
        getPerturbationConfiguration600A(...
            perturbationSettings,...
            auroraConfig);

    lengthRampOption = ...
        getCommandFunctionOptions600A('Length-Ramp',auroraConfig);


    [squareStochasticWave, ...
    squarePreconditioningWave, ...
    figSquarePerturbation] = createPerturbationWave600A('Length-Ramp',...
                                                lengthRampOption,...
                                                configVibration,...
                                                auroraConfig, ...
                                                figSquarePerturbation,...
                                                perturbationPlotConfig,...
                                                verbose);

    save(fullfile(projectFolders.output_structs,...
         'squareStochasticWave.mat'),...
         'squareStochasticWave','-mat');   

    save(fullfile(projectFolders.output_structs,...
         'squarePreconditioningWave.mat'),...
         'squarePreconditioningWave','-mat');    
    
    saveas(figSquarePerturbation,...
           fullfile(projectFolders.output_plots,...
          'fig_randomSquareWave'),'pdf');

    savefig(figSquarePerturbation,...
            fullfile(projectFolders.output_plots,...
            'fig_randomSquareWave.fig'));    

    %%
    % Sine
    %%
    plotConfig.numberOfHorizontalPlotColumns    = 1;
    plotConfig.numberOfVerticalPlotRows         = 3;
    plotConfig.plotWidth                        = 15;
    plotConfig.plotHeight                       = 5;
    plotConfig.plotHorizMarginCm                = 3;
    plotConfig.plotVertMarginCm                 = 3;
    plotConfig.baseFontSize                     = 6;
    
    [subplotPanel_sine,plotConfig_sine]=...
        plotConfigGeneric(plotConfig);    
    verbose=1;
    figSinePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_sine;
    perturbationPlotConfig.config = plotConfig_sine;
    perturbationPlotConfig.column=1;


    lengthSineOption = ...
        getCommandFunctionOptions600A('Length-Sine',auroraConfig);

    [sineStochasticWave, ...
     sinePreconditioningWave, ...
     figSinePerturbation] = createPerturbationWave600A('Length-Sine',...
                                                lengthSineOption,...
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

    %%
    % Arbitrary Waveform
    %%    
    verbose=1;
    figLarbPerturbation=figure;

    lengthLarbOption = ...
        getCommandFunctionOptions600A('Length-Arb',auroraConfig);    

    switch arbitraryWaveformManualSettings.lengthUnits
        case 'rel'
            lengthLarbOption(2).isRelative=1;            
        case 'abs'
            lengthLarbOption(2).isRelative=0;                        
        otherwise assert(0,'Error: Larb units must be rel or abs');
    end

    nWave = length(arbitraryWaveformManualSettings.magnitude);

    plotConfig.numberOfHorizontalPlotColumns    = nWave;
    plotConfig.numberOfVerticalPlotRows         = 3;
    plotConfig.plotWidth                        = 15;
    plotConfig.plotHeight                       = 5;  
    plotConfig.plotHorizMarginCm                = 3;
    plotConfig.plotVertMarginCm                 = 3;
    plotConfig.baseFontSize                     = 6;

    [subplotPanel_wave,plotConfig_wave]=plotConfigGeneric(plotConfig);  

    arbitraryWavePlotConfig=perturbationPlotConfig;
    arbitraryWavePlotConfig.subplot = subplotPanel_wave;
    arbitraryWavePlotConfig.config  = plotConfig_wave;
    arbitraryWavePlotConfig.column=1;



    for idxWave = 1:1:nWave
        

        larbConfig = ...
            getPerturbationConfiguration600A(...
                perturbationSettings,...
                auroraConfig);
        
        %
        % Update the parameters specific to this wave
        %
        larbConfig.magnitude = ...
            arbitraryWaveformManualSettings.magnitude(idxWave);

        larbConfig.arbitraryWaveform.bandwidth = ...
            arbitraryWaveformManualSettings.bandwidth(idxWave);

        larbConfig.points = ...
            arbitraryWaveformManualSettings.points(idxWave);
    
        paddingPoints = round(larbConfig.points*0.05);        
        larbConfig.paddingDuration = ...
            paddingPoints/larbConfig.frequencyHz;
        larbConfig.duration = ...
            (larbConfig.points-2*paddingPoints)/larbConfig.frequencyHz;

        larbConfig.arbitraryWaveform.fileName = ...
           [arbitraryWaveformManualSettings.fileName,'_',num2str(idxWave),'.dat'];

        larbConfig.arbitraryWaveform.seed = ...
            arbitraryWaveformManualSettings.seed;

        larbConfig.canBeMerged = ...
            arbitraryWaveformManualSettings.canBeMerged(idxWave);

        arbitraryWavePlotConfig.column=idxWave;

        [larbStochasticWave, ...
         larbPreconditioningWave, ...
         figLarbPerturbation] = createPerturbationWave600A(...
                                    'Length-Arb',...
                                    lengthLarbOption,...
                                    larbConfig,...
                                    auroraConfig, ...
                                    figLarbPerturbation,...
                                    arbitraryWavePlotConfig,...
                                    verbose);
        larbStochasticWaveSet(idxWave).wave = larbStochasticWave;
        larbStochasticWaveSet(idxWave).auroraConfig=auroraConfig;
        larbStochasticWaveSet(idxWave).waveConfig=larbConfig;
    end
    save(fullfile(projectFolders.output_structs,'larbStochasticWaveSet.mat'),...
         'larbStochasticWaveSet','-mat');        
 
    
    saveas(figLarbPerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomLarbWave'),'pdf');
    savefig(figLarbPerturbation,fullfile(projectFolders.output_plots,...
                    'fig_randomLarbWave.fig'));        

else
    filePath01=fullfile(projectFolders.output_structs,'squareStochasticWave.mat');
    filePath02=fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat');
    filePath03=fullfile(projectFolders.output_structs,'sineStochasticWave.mat');
    filePath04=fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat');
    filePath05=fullfile(projectFolders.output_structs,'larbStochasticWaveSet.mat');

    load(filePath01);
    load(filePath02);
    load(filePath03);
    load(filePath04);
    load(filePath05);

  fprintf('\n\nsquare-stochastic-wave file loaded\n\t%s\n',filePath01);
  fprintf('square-preconditioning-wave file loaded\n\t%s\n',filePath02);
  fprintf('sine-stochastic-wave file loaded\n\t%s\n',filePath03);
  fprintf('sine-preconditioning-wave file loaded\n\t%s\n',filePath04);
  fprintf('larb-preconditioning-wave file loaded\n\t%s\n\n',filePath05);


end





%%
% Generate the injury experiment protocol files
%%

%
% Put all of the stochastic waveforms into a consistent struct, and 
% pick and choose the waveforms that you need
%

stochasticWaves = ...
    unifyPerturbationStructure(...
        perturbationSettings,...
        squarePreconditioningWave,...
        squareStochasticWave,...
        sinePreconditioningWave,...
        sineStochasticWave,...
        larbStochasticWaveSet,...
        auroraConfig);

%%
% Generate the protocols
%%
if(flag_generateCalibrationProtocol==1)
  assert(length(larbStochasticWaveSet)==1);

  %We're going to scale and shift this perturbation waveform, so it 
  %should have a magnitude of 1
  assert(abs(larbStochasticWaveSet(1).wave.config.magnitude-1)<1e-6);  

  %For now
  assert(abs(larbStochasticWaveSet(1).wave.config.arbitraryWaveform.bandwidth-90)<1e-6);

  indexStart=1;
  writeProtocolHeader=1;

  indexEnd = createCalibrationExperiments600A(...
              indexStart,...
              'zcal',...              
              expSettings.impedanceCalibration,...              
              stochasticWaves,...
              sineSeriesExponentiallySpaced,...
              writeProtocolHeader,...
              projectFolders,...
              auroraConfig,...
              auroraConfigSlow,...
              settingsExperiment);

end

if(flag_generateLarbSinusoidImpedanceProtocol==1)

  mergedStochasticWave = mergeArbitraryWaveSegments(stochasticWaves,...
                                  mergedArbitraryWaveformSettings,...
                                  auroraConfig);

  countCalibrationWave=0;
  for idxWave=1:1:length(stochasticWaves)    
    if(stochasticWaves(idxWave).waveConfig.canBeMerged==0)
      calibrationStochasticWave = stochasticWaves(idxWave);
      countCalibrationWave=countCalibrationWave+1;
    end
  end

  if(countCalibrationWave==0)
    calibrationStochasticWave=mergedStochasticWave;
  end
  assert(countCalibrationWave==1,...
         'Error: there should be at least one calibration trial');

  indexStart=1;
  writeProtocolHeader=1;

  assert(length(expSettings.impedance.isometricNormLengths)==7,...
        'Error: expected 7 different isometric lengths');

  lengthRandomization = ...
      [7     1     3     2     5     6     4;...
       1     5     2     3     4     7     6;...
       4     6     2     5     3     7     1;...
       1     3     5     7     4     6     2;...
       5     2     6     4     3     7     1;...
       4     6     5     3     2     1     7;...
       6     1     3     4     7     2     5;...
       6     5     7     3     4     2     1;...
       2     4     5     1     6     7     3;...
       6     1     5     7     2     4     3];
  
  idxR=4;
  settingsImpedance=expSettings.impedance;
  settingsFields=fields(expSettings.impedance);
  for i=1:1:length(settingsFields)
    if(length(expSettings.impedance.(settingsFields{i}))==7)
      settingsImpedance.(settingsFields{i}) = ...
        expSettings.impedance.(settingsFields{i})(lengthRandomization(idxR,:));
    end
  end

  indexEnd = createImpedanceForceLengthExperiments600A_LarbSine(...
              indexStart,...
              ['zLR',num2str(idxR),'_'],...              
              settingsImpedance,...              
              mergedStochasticWave,...
              calibrationStochasticWave,...
              sineSeriesExponentiallySpaced,...
              writeProtocolHeader,...
              projectFolders,...
              auroraConfig,...
              auroraConfigSlow,...
              settingsExperiment);


end


if(flag_generateImpedanceAmplitudeProtocol_Larb==1)
    %%
    % Merge the isometric waves
    %%
    mergedStochasticWave = mergeArbitraryWaveSegments(stochasticWaves,...
                                    mergedArbitraryWaveformSettings);

    indexStart=1;
    writeProtocolHeader = 1;

    indexEnd = createImpedanceAmplitudeExperiments600A_Larb(...
                    indexStart,...
                    'larb',...
                    expSettings.impedanceAmplitude,...
                    mergedStochasticWave,...
                    writeProtocolHeader,...
                    projectFolders,...                                                                                                            
                    auroraConfig,...
                    settingsExperiment);     
end

if(flag_generateImpedanceForceLengthProtocol_Larb==1)
  
    % pilot to establish the decrease in force with each perturbation trial
    %
    % version of TRSS2017 with perturbation during the lengthening
    %

    %%
    % Merge the isometric waves
    %%
    mergedStochasticWave = mergeArbitraryWaveSegments(stochasticWaves,...
                                    mergedArbitraryWaveformSettings);

    %%
    % Write the impedance files
    %%
    indexStart=1;
    writeProtocolHeader = 1;
 

    
    indexEnd = createImpedanceForceLengthExperiments600A_Larb(...
                    indexStart,...
                    'larb',...
                    expSettings.impedance,...
                    mergedStochasticWave,...
                    writeProtocolHeader,...
                    projectFolders,...                                                                                                            
                    auroraConfig,...
                    settingsExperiment);  
    
      
end

if(flag_generateImpedanceForceLengthProtocol_Sine==1)
    indexEnd = createImpedanceForceLengthExperiments600A_Sine(...
                    'sine',...
                    '',...
                    expSettings.impedance,...
                    stochasticWaves,...
                    projectFolders,...                                                                                                            
                    auroraConfig);
end


if(flag_generateArbitraryWaveImpedanceProtocol==1)
    auroraConfigRubber = getDefaultAuroraConfiguration600A(...
                            nan,...
                            rubber.approximateSampleLengthInMM,...
                            sampleFrequency,...
                            rubber.minNormLength,...
                            rubber.maxNormLength,...
                            rubber.maxNormalizedSpeedLPS,...
                            'nitrile-rubber');

    success = createArbitraryWaveExperiments600A(...
                            expSettings.rubber,...
                            stochasticWaves,...
                            projectFolders,...                                                                                                            
                            auroraConfig);

end

if(flag_generateRubberProtocol ==1 )

    auroraConfigRubber = getDefaultAuroraConfiguration600A(...
                            nan,...
                            rubber.approximateSampleLengthInMM,...
                            sampleFrequency,...
                            rubber.minNormLength,...
                            rubber.maxNormLength,...
                            rubber.maxNormalizedSpeedLPS,...
                            'nitrile-rubber');

    success = createRubberTestingExperiments600A(...
                            expSettings.rubber,...
                            stochasticWaves,...
                            projectFolders,...                                                                                                            
                            auroraConfigRubber);
end

if(flag_generateForceRampProtocol ==1 )
    success= ...
        createForceRampExperiments600A( ...
                expSettings.forceRampFV,... 
                projectFolders,...                                                                                                            
                auroraConfig);
end

if(flag_generateTRSS2017PerturbationProtocol ==1 )
    success= ...
        createTRSS2017PerturbationExperiments600A( ...
                expSettings.TRSS2017Impedance,...
                perturbationSettings,...
                stochasticWaves,...    
                projectFolders,...                                                                                                            
                auroraConfig);
end


if(flag_generateInjuryProtocol==1)
    success = createInjuryExperiments600A( ...
                    expSettings.characterization,...
                    expSettings.lengthRampInjury,...
                    expSettings.forceRampInjury,...
                    stochasticWaves,...
                    projectFolders,...                                                                                                            
                    auroraConfig);
end


