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
flag_generateRandomSignal   = 0;

% Experiments to generate
flag_generateRubberProtocol                 = 0;
flag_generateForceRampProtocol              = 0;
flag_generateTRSS2017PerturbationProtocol   = 0;
flag_generateInjuryProtocol                 = 0;

flag_generateArbitraryWaveImpedanceProtocol = 0; 

flag_generateImpedanceForceLengthProtocol_Sine          = 0; %For length/sine
flag_generateImpedanceForceLengthProtocol_Larb          = 0; %For larb
flag_generateImpedanceAmplitudeProtocol_Larb            = 1;


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
perturbationSettings.waveType = 'sineWave';
% 'lengthRamp'
% 'sineWave'
% 'larb


% 0. Lower-frequency Length-Ramp & Sine-Wave 
% 1. Higher-frequency Length-Ramp & Sine-Wave
% 2. Arbitrary Waveform
% Applies to the random Length-Ramp and Sine-Ramp waveforms.

if(flag_generateArbitraryWaveImpedanceProtocol ...
        || flag_generateImpedanceForceLengthProtocol_Larb ...
        || flag_generateImpedanceAmplitudeProtocol_Larb)
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

if(flag_generateImpedanceAmplitudeProtocol_Larb==1)
    arbitraryWaveformManualSettings.frequencyHz   = 1000;

    arbitraryWaveformManualSettings.points        = ...
        [2^13,2^13];
    arbitraryWaveformManualSettings.magnitude     = ...
        [1,1];
    arbitraryWaveformManualSettings.bandwidth     = ...
        [35, 90];        
    arbitraryWaveformManualSettings.canBeMerged = ...
        [1,1];   
    arbitraryWaveformManualSettings.paddingDuration= ...
        [1,1].*0.125;
end



rubber.approximateSampleLengthInMM=1.183;
rubber.minNormLength              = 0.75; %short is fine
rubber.maxNormLength              = 1.02; %long is not
rubber.maxNormalizedSpeedLPS      = 2.0;

ratMuscleName                   = 'EDL';
approximateSampleLengthInMM     = 1.5;
sampleFrequency                 = 1000;
minNormLength                   = 0.5;
maxNormLength                   = 1.85;

switch ratMuscleName
    case 'SOL'
        maxNormalizedShorteningSpeedLPS = 1.02; 
        % in units of norm fiber lengths/second        
    case 'EDL'
        maxNormalizedShorteningSpeedLPS = 2.25;  
    otherwise 
        assert(0,'Error: muscleName not found');
end

auroraConfig = getDefaultAuroraConfiguration600A(...
                    approximateSampleLengthInMM,...
                    sampleFrequency,...
                    minNormLength,...
                    maxNormLength,...
                    maxNormalizedShorteningSpeedLPS);

%%
% Experiment settings
%%
expSettings = getExperimentSettings(maxNormalizedShorteningSpeedLPS); 


%%
% Set perturbation settings
%%
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

muscleTemperatureInC            = 12;



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
    load(fullfile(projectFolders.output_structs,'squareStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'squarePreconditioningWave.mat'));
    load(fullfile(projectFolders.output_structs,'sineStochasticWave.mat'));
    load(fullfile(projectFolders.output_structs,'sinePreconditioningWave.mat'));
    load(fullfile(projectFolders.output_structs,'larbStochasticWaveSet.mat'));

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
                            rubber.approximateSampleLengthInMM,...
                            sampleFrequency,...
                            rubber.minNormLength,...
                            rubber.maxNormLength,...
                            rubber.maxNormalizedSpeedLPS);

    success = createArbitraryWaveExperiments600A(...
                            expSettings.rubber,...
                            stochasticWaves,...
                            projectFolders,...                                                                                                            
                            auroraConfig);

end

if(flag_generateRubberProtocol ==1 )

    auroraConfigRubber = getDefaultAuroraConfiguration600A(...
                            rubber.approximateSampleLengthInMM,...
                            sampleFrequency,...
                            rubber.minNormLength,...
                            rubber.maxNormLength,...
                            rubber.maxNormalizedSpeedLPS);

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


