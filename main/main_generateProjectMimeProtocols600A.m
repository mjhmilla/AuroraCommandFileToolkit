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
flag_generateImpedanceProtocol_v00          = 0;
flag_generateInjuryProtocol                 = 0;

flag_generateArbitraryWaveImpedanceProtocol = 0; 
flag_generateImpedanceProtocol_v01          = 1;


usingArbitraryWaves = 0;
typePerturbation    = 1;
% 0. Lower-frequency Length-Ramp & Sine-Wave 
% 1. Higher-frequency Length-Ramp & Sine-Wave
% 2. Arbitrary Waveform
% Applies to the random Length-Ramp and Sine-Ramp waveforms.

if(flag_generateArbitraryWaveImpedanceProtocol ...
        || flag_generateImpedanceProtocol_v01)
    usingArbitraryWaves=1;
    typePerturbation=2;
end

%%
% Aurora configuration
%%
mergedArbitraryWaveformSettings.paddingTime = 1;

arbitraryWaveformManualSettings.lengthUnits   = 'rel';
arbitraryWaveformManualSettings.magnitude     = 0.01;
arbitraryWaveformManualSettings.distribution  = 'normal';
arbitraryWaveformManualSettings.bandwidth     = 90;
arbitraryWaveformManualSettings.seed          = 6;
arbitraryWaveformManualSettings.lengthUnit    = 'Lo';
dateId = getDateId();
arbitraryWaveformManualSettings.fileName = ['larb_',dateId];


if(usingArbitraryWaves==1)

    if(flag_generateArbitraryWaveImpedanceProtocol==1)
        arbitraryWaveformManualSettings.frequencyHz   = 1000;

        arbitraryWaveformManualSettings.points        = ...
            [2^13,2^13,2^13,2^13];
        arbitraryWaveformManualSettings.magnitude     = ...
            [0.01, 0.01, 0.001, 0.001];
        arbitraryWaveformManualSettings.bandwidth     = ...
            [35, 90, 35, 90];        
        arbitraryWaveformManualSettings.isIsometric = ...
            [1,1,1,1];   
        arbitraryWaveformManualSettings.paddingDuration= ...
            [1,1,1,1].*0.125;
    end
    if(flag_generateImpedanceProtocol_v01==1)
        arbitraryWaveformManualSettings.frequencyHz   = ...
            [1000,1000,1000,1000,  1000];        
        arbitraryWaveformManualSettings.points        = ...
            [2^12,2^12,2^12,2^12,  454];
        arbitraryWaveformManualSettings.magnitude     = ...
            [0.01, 0.01, 0.001, 0.001,  0.001];
        arbitraryWaveformManualSettings.bandwidth     = ...
            [35, 90, 35, 90, 90];
        arbitraryWaveformManualSettings.isIsometric = ...
            [1,1,1,1, 0];


        arbitraryWaveformManualSettings.paddingDuration= ...
            round(arbitraryWaveformManualSettings.points.*0.05) ...
            ./arbitraryWaveformManualSettings.frequencyHz;
        
    end
    

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
        maxNormalizedSpeedLPS = 1.02; 
        % in units of norm fiber lengths/second        
    case 'EDL'
        maxNormalizedSpeedLPS = 2.25;  
    otherwise 
        assert(0,'Error: muscleName not found');
end

auroraConfig = getDefaultAuroraConfiguration600A(...
                    approximateSampleLengthInMM,...
                    sampleFrequency,...
                    minNormLength,...
                    maxNormLength,...
                    maxNormalizedSpeedLPS);

%%
% Detailed impedance block
%%

settingsRubber.normLength              = 1;

settingsRubber.passiveCycles           = 5;
settingsRubber.passiveCycleFrequencyHz = 1;
settingsRubber.passiveCycleMagnitude   = 0.0075;

settingsRubber.startingForce            = 0.20;
settingsRubber.startingForceUnits       = 'mN';
settingsRubber.startingForceFileLabel   = '020mN';

settingsRubber.perturbationMagnitude = 0.005;

settingsRubber.rubberType = 'nitrile';

%%
% Detailed impedance block
%%
settingsImpedance.isometricNormLengths           = [0.6,0.8,1,1.4];
                                                    %[0.6:0.1:1.4];

settingsImpedance.isometricActivationDurationMultiple= ...
    ones(size(settingsImpedance.isometricNormLengths));

settingsImpedance.isometricActivationDurationMultiple(...
    settingsImpedance.isometricNormLengths < 0.8) = 2;
    
%%
% Force-Velocity using Force-Ramp block
%%

settingsForceRampFV.activeLengthening.normLength  = [ 0.9     ];
settingsForceRampFV.activeLengthening.normForce   = [ 1.0, 1.6];
settingsForceRampFV.activeLengthening.duration    = [ 1.0, 1.0];
settingsForceRampFV.activeShortening.normLength   = [ 1.1     ];
settingsForceRampFV.activeShortening.normForce    = [ 1.0, 0.1];
settingsForceRampFV.activeShortening.duration     = [ 1.0, 1.0];

%%
% Test protocol to investigate force distribution between 
% titin and cross-bridges
%
% Impedance across the force-length-relation isometric/lengthening
%%
settingsTRSS2017Impedance.rampNormLengths           = [0.70,1.15;...
                                                       0.85,1.30;...
                                                       1.0,1.45];
settingsTRSS2017Impedance.normLengths = ...
    zeros(size(settingsTRSS2017Impedance.rampNormLengths));

settingsTRSS2017Impedance.normLengths(:,1) =...
    settingsTRSS2017Impedance.rampNormLengths(:,1)+0.02;
settingsTRSS2017Impedance.normLengths(:,2) =...
    settingsTRSS2017Impedance.rampNormLengths(:,2)-0.08;

settingsTRSS2017Impedance.activationDurationMultiple= [ 1.5,1;...
                                                        1.5,1;...
                                                        1.5,1];

dl = settingsTRSS2017Impedance.rampNormLengths(:,2) ...
     -settingsTRSS2017Impedance.rampNormLengths(:,1);
assert(abs(dl(1,1)-dl(2,1)) < 1e-6);
assert(abs(dl(2,1)-dl(3,1)) < 1e-6);

v = 0.11*maxNormalizedSpeedLPS;

settingsTRSS2017Impedance.rampDuration              = ones(3,1).*([dl(1,1)/v].*1000);
settingsTRSS2017Impedance.perturbationMagnitude     = ones(3,1).*0.005;
settingsTRSS2017Impedance.perturbationHoldTime      = ones(3,1).*([1/50].*1000);
settingsTRSS2017Impedance.perturbationCycles        = ones(3,1).*5;
%%
% Characterization block
%%
settingsCharacterization.passive.normLengths             = [0.6,1.55];
settingsCharacterization.passive.normVelocities          = [0.1,1];

settingsCharacterization.isometricNormLengths           = [0.7,1,1.4];
settingsCharacterization.isometricActivationDurationMultiple= [2,1,1];

settingsCharacterization.activeLengthening.normLengths  = [   0.9,  1.1 ];
settingsCharacterization.activeLengthening.normVelocity = [ (1/3), (2/3)];
settingsCharacterization.activeShortening.normLengths   = [   1.1,  0.9 ];
settingsCharacterization.activeShortening.normVelocity  = [-(1/3),-(2/3)];


flag_useForceRampInjury     = 1;
flag_useLengthRampInjury    = 1;

settingsLengthRampInjury.normLengths    = [1.0, 1.8, 1.0];
settingsLengthRampInjury.normVelocity   = [1,1,-1].*(1/3);
settingsLengthRampInjury.enable         = 1;

settingsForceRampInjury.normLength      = [1.0];
settingsForceRampInjury.enable          = 1;
settingsForceRampInjury.normForce       = [1.0,2.75,1.0];
settingsForceRampInjury.duration        = [1.0,0.25,0.25].*1000;
 


%%
% Set perturbation settings
%%
flag_plotRandomSignal       = 1 && flag_generateRandomSignal;

muscleTemperatureInC            = 12;
perturbationSettings.mode       = typePerturbation; %0. default, 1. high bandwidth
perturbationSettings.magnitude  = 0.005;

switch perturbationSettings.mode
    case 0
        perturbationSettings.frequencyRange=[5,39];
        perturbationSettings.normSpeedRange=[0.1,1];
        perturbationSettings.holdRange = [(1/100),(1/11.4)];
        perturbationSettings.distribution = 'uniform';
        perturbationSettings.isIsometric=1;

    case 1
        perturbationSettings.frequencyRange=[10,80];
        perturbationSettings.normSpeedRange=[0.1,1.5];
        perturbationSettings.holdRange = [(1/500),(1/50)];
        perturbationSettings.distribution = 'normal';
        perturbationSettings.isIsometric=1;

    case 2
        perturbationSettings.frequencyRange=[10,90];
        perturbationSettings.normSpeedRange=[0.1,1.5];
        perturbationSettings.holdRange = [(1/500),(1/50)];
        perturbationSettings.distribution = 'normal';
        perturbationSettings.isIsometric=1;

    otherwise
        assert(0,'Error: invalid perturbation mode setting');
end





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

plotConfig.numberOfHorizontalPlotColumns    = 1;
plotConfig.numberOfVerticalPlotRows         = 3;
plotConfig.plotWidth                        = 15;
plotConfig.plotHeight                       = 5;

[subplotPanel_3R1C,plotConfig_3R1C]=plotConfigGeneric(plotConfig);



%%
% System identification perturbation signal configuration
%%


%%
% Create the system identification vibration signal
%   This is quite challenging because we are limited to 945 commands.
%%
if(flag_generateRandomSignal==1)
    %%
    % Square
    %%
    verbose=1;
    figSquarePerturbation=figure;

    perturbationPlotConfig.subplot= subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;
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
    verbose=1;
    figSinePerturbation=figure;

    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;
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
    [subplotPanel_wave,plotConfig_wave]=plotConfigGeneric(plotConfig);  

    arbitraryWavePlotConfig=perturbationPlotConfig;
    arbitraryWavePlotConfig.subplot = subplotPanel_wave;
    arbitraryWavePlotConfig.config  = plotConfig_wave;
    arbitraryWavePlotConfig.column=1;

    auroraConfigWave = auroraConfig;

    for idxWave = 1:1:nWave
        
        arbitraryWaveformSettings = perturbationSettings; 

        arbitraryWaveformSettings.paddingDuration=...
            arbitraryWaveformManualSettings.paddingDuration(idxWave);

        auroraConfigWave.analogToDigitalSampleRateHz = ...
            arbitraryWaveformManualSettings.frequencyHz(idxWave);
        
        configWaveVibration = ...
            getPerturbationConfiguration600A(...
                arbitraryWaveformSettings,...
                auroraConfigWave);
        
        arbitraryWaveformSettings.magnitude = ...
            arbitraryWaveformManualSettings.magnitude(idxWave);

        arbitraryWaveformSettings.frequencyRange = ...
            [0,arbitraryWaveformManualSettings.bandwidth(idxWave)];

        arbitraryWaveformSettings.points = ...
            arbitraryWaveformManualSettings.points(idxWave);

        configArbitraryWaveformVibration = ...
            getPerturbationConfiguration600A(...
                arbitraryWaveformSettings,...
                auroraConfigWave);


        configArbitraryWaveformVibration.arbitraryWaveform.fileName = ...
           [arbitraryWaveformManualSettings.fileName,'_',num2str(idxWave),'.dat'];

        configArbitraryWaveformVibration.arbitraryWaveform.seed = ...
            arbitraryWaveformManualSettings.seed;

        configArbitraryWaveformVibration.isIsometric = ...
            arbitraryWaveformManualSettings.isIsometric(idxWave);

        arbitraryWavePlotConfig.column=idxWave;

        [larbStochasticWave, ...
         larbPreconditioningWave, ...
         figLarbPerturbation] = createPerturbationWave600A(...
                                    'Length-Arb',...
                                    lengthLarbOption,...
                                    configArbitraryWaveformVibration,...
                                    auroraConfigWave, ...
                                    figLarbPerturbation,...
                                    arbitraryWavePlotConfig,...
                                    verbose);
        larbStochasticWaveSet(idxWave).wave = larbStochasticWave;
        larbStochasticWaveSet(idxWave).auroraConfig=auroraConfigWave;
        larbStochasticWaveSet(idxWave).waveConfig=configArbitraryWaveformVibration;
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
% Put all of the stochastic waveforms into a struct: all of these
% will be applied at the beginning and end of each trial
%
lineCountStochastic = ...
    length(squarePreconditioningWave.controlFunctions.waitDuration) ...
  + length(squareStochasticWave.controlFunctions.waitDuration) ...
  + length(sinePreconditioningWave.controlFunctions.waitDuration) ...
  + length(sineStochasticWave.controlFunctions.waitDuration);

assert(lineCountStochastic*2 < (auroraConfig.maximumNumberOfCommands + 40),...
      'Error: the number of perturbation commands is too high');

switch perturbationSettings.mode
    case 0
        stochasticWaves(4)=struct('controlFunction',[],'waitDuration',[],...
                                 'optionValues',[],'options',[],'type','');
        
        controlFields = {'controlFunction','waitDuration','optionValues','options'};
        
        for j=1:1:length(controlFields)
            stochasticWaves(1).(controlFields{j}) = ...
                squarePreconditioningWave.controlFunctions.(controlFields{j});
            stochasticWaves(1).type = 'Length-Ramp-Preconditioning';
        
            stochasticWaves(2).(controlFields{j}) = ...
                squareStochasticWave.controlFunctions.(controlFields{j});
            stochasticWaves(2).type = 'Length-Ramp-Stochastic';
            
            stochasticWaves(3).(controlFields{j}) = ...
                sinePreconditioningWave.controlFunctions.(controlFields{j});
            stochasticWaves(3).type = 'Length-Sine-Preconditioning';
            
            stochasticWaves(4).(controlFields{j}) = ...
                sineStochasticWave.controlFunctions.(controlFields{j});
            stochasticWaves(4).type = 'Length-Sine-Stochastic';
            
        end
    case 1
        %These perturbations have a higher bandwidth, which means a 
        %far greater number of commands. If we use both square and 
        %sine perturbations we exceed the allowed number of commands
        stochasticWaves(2)=struct('controlFunction',[],'waitDuration',[],...
                                 'optionValues',[],'options',[],'type','');
        
        controlFields = {'controlFunction','waitDuration','optionValues','options'};
        
        for j=1:1:length(controlFields)

            stochasticWaves(1).(controlFields{j}) = ...
                sinePreconditioningWave.controlFunctions.(controlFields{j});
            stochasticWaves(1).type = 'Length-Sine-Preconditioning';
            
            stochasticWaves(2).(controlFields{j}) = ...
                sineStochasticWave.controlFunctions.(controlFields{j});
            stochasticWaves(2).type = 'Length-Sine-Stochastic';
            
        end

    case 2
    % Arbitrary waveforms
        nWaves = length(larbStochasticWaveSet);
        stochasticWaves(nWaves)=...
            struct('controlFunction',[],'waitDuration',[],...
                   'optionValues',[],'options',[],'type','','metadata',[],...
                   'auroraConfig',[],'waveConfig',[]);
        
        controlFields = {'controlFunction','waitDuration','optionValues',...
                        'options','fileName','fileData'};
        
        for i=1:1:nWaves
            for j=1:1:length(controlFields)
    
                stochasticWaves(i).(controlFields{j}) = ...
                    larbStochasticWaveSet(i).wave.controlFunctions.(controlFields{j});
                
            end 

            stochasticWaves(i).type = 'Larb-Stochastic';
            stochasticWaves(i).options(1).value=i; %Larb file id   

            stochasticWaves(i).metadata.bandwidth = ...
                max(larbStochasticWaveSet(i).wave.config.frequencyRange);
            stochasticWaves(i).metadata.amplitude = ...
                max(larbStochasticWaveSet(i).wave.config.magnitudeRange);
            stochasticWaves(i).metadata.points = ...
                max(larbStochasticWaveSet(i).wave.config.points);
            stochasticWaves(i).metadata.frequencyHz = ...
                max(larbStochasticWaveSet(i).wave.config.frequencyHz);

            stochasticWaves(i).auroraConfig = ...
                larbStochasticWaveSet(i).auroraConfig;
            stochasticWaves(i).waveConfig = ...
                larbStochasticWaveSet(i).waveConfig;
 
            here=1;
            
        end

        
    otherwise assert(0,'Error: Unexpected perturbationSetting.mode');
end
%%
% Generate the protocols
%%
if(flag_generateImpedanceProtocol_v01==1)
  
    % pilot to establish the decrease in force with each perturbation trial
    %
    % version of TRSS2017 with perturbation during the lengthening
    %

    %%
    % Merge the isometric waves
    %%
    mergedStochasticWave = [];

    for i=1:1:length(stochasticWaves)
        if(stochasticWaves(i).waveConfig.isIsometric==1)
            if(isempty(mergedStochasticWave)==1)

                mergedStochasticWave = stochasticWaves(i);

                %Update the file names
                mergedStochasticWave.waveConfig.arbitraryWaveform.fileName = ...
                    ['merged_',stochasticWaves(i).waveConfig.arbitraryWaveform.fileName];
                mergedStochasticWave.optionValues(1,1) = ...
                    {['merged_',stochasticWaves(i).optionValues{1}]};
                mergedStochasticWave.fileName = ...
                    ['merged_',stochasticWaves(i).fileName];
            else
                if(mergedStochasticWave.waveConfig.frequencyHz ...
                        == stochasticWaves(i).waveConfig.frequencyHz)

                    %Update the data
                    nPaddingPoints = ...
                        round(mergedArbitraryWaveformSettings.paddingTime ...
                             *mergedStochasticWave.waveConfig.frequencyHz);
                    paddingPoints = zeros(nPaddingPoints,1);
                    mergedStochasticWave.fileData = ...
                        [mergedStochasticWave.fileData;...
                        paddingPoints;...
                        stochasticWaves(i).fileData];

                    %Update the meta data
                    metaFields =...
                        {'bandwidth','amplitude','points','frequencyHz'};
                    paddingData=...
                        [0,0,nPaddingPoints,...
                        mergedStochasticWave.waveConfig.frequencyHz];

                    for j=1:1:length(metaFields)

                        mergedStochasticWave.metadata.(metaFields{j}) = ...
                        [mergedStochasticWave.metadata.(metaFields{j}),...
                        paddingData(1,j)];

                        mergedStochasticWave.metadata.(metaFields{j}) = ...
                        [mergedStochasticWave.metadata.(metaFields{j}),...
                        stochasticWaves(i).metadata.(metaFields{j})];                        

                    end
                   
                end
            end
        end
    end


    %%
    % Write the impedance files
    %%
    indexStart=1;
    isActive=1;
    writeProtocolHeader = 1;

    indexEnd = createImpedanceForceLengthExperiments600A_v01(...
                    indexStart,...
                    isActive,...
                    'larb',...
                    'passive',...
                    settingsImpedance,...
                    mergedStochasticWave,...
                    writeProtocolHeader,...
                    projectFolders,...                                                                                                            
                    auroraConfig);  
    
    indexStart=indexEnd;
    isActive=0;
    writeProtocolHeader = 0;

    indexEnd = createImpedanceForceLengthExperiments600A_v01(...
                    indexStart,...
                    isActive,...
                    'larb',...
                    'active',...
                    settingsImpedance,...
                    mergedStochasticWave,...
                    writeProtocolHeader,...
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
                            settingsRubber,...
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
                            settingsRubber,...
                            stochasticWaves,...
                            projectFolders,...                                                                                                            
                            auroraConfigRubber);
end

if(flag_generateForceRampProtocol ==1 )
    success= ...
        createForceRampExperiments600A( ...
                settingsForceRampFV,... 
                projectFolders,...                                                                                                            
                auroraConfig);
end

if(flag_generateTRSS2017PerturbationProtocol ==1 )
    success= ...
        createTRSS2017PerturbationExperiments600A( ...
                settingsTRSS2017Impedance,...
                perturbationSettings,...
                stochasticWaves,...    
                projectFolders,...                                                                                                            
                auroraConfig);
end

if(flag_generateImpedanceProtocol_v00==1)
    indexEnd = createImpedanceForceLengthExperiments600A_v00(...
                    '',...
                    '',...
                    settingsImpedance,...
                    stochasticWaves,...
                    projectFolders,...                                                                                                            
                    auroraConfig);
end

if(flag_generateInjuryProtocol==1)
    success = createInjuryExperiments600A( ...
                    settingsCharacterization,...
                    settingsLengthRampInjury,...
                    settingsForceRampInjury,...
                    stochasticWaves,...
                    projectFolders,...                                                                                                            
                    auroraConfig);
end


