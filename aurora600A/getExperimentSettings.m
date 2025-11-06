function expSettings = getExperimentSettings(maxNormalizedShorteningSpeedLPS)
%%
% Detailed impedance block
%%

expSettings.rubber.normLength              = 1;

expSettings.rubber.passiveCycles           = 5;
expSettings.rubber.passiveCycleFrequencyHz = 1;
expSettings.rubber.passiveCycleMagnitude   = 0.0075;

expSettings.rubber.startingForce            = 0.20;
expSettings.rubber.startingForceUnits       = 'mN';
expSettings.rubber.startingForceFileLabel   = '020mN';

expSettings.rubber.perturbationMagnitude = 0.005;

expSettings.rubber.rubberType = 'nitrile';

%%
% Detailed impedance block
%%
expSettings.impedance.isometricNormLengths  = [0.55,0.70,0.85,1,1.15,1.30,1.45];

expSettings.impedance.isometricActivationDurationMultiple= ...
    ones(size(expSettings.impedance.isometricNormLengths));

expSettings.impedance.isometricActivationDurationMultiple(...
    expSettings.impedance.isometricNormLengths < 0.8) = 2;
    
%%
% Force-Velocity using Force-Ramp block
%%

expSettings.forceRampFV.activeLengthening.normLength  = [ 0.9     ];
expSettings.forceRampFV.activeLengthening.normForce   = [ 1.0, 1.6];
expSettings.forceRampFV.activeLengthening.duration    = [ 1.0, 1.0];
expSettings.forceRampFV.activeShortening.normLength   = [ 1.1     ];
expSettings.forceRampFV.activeShortening.normForce    = [ 1.0, 0.1];
expSettings.forceRampFV.activeShortening.duration     = [ 1.0, 1.0];

%%
% Test protocol to investigate force distribution between 
% titin and cross-bridges
%
% Impedance across the force-length-relation isometric/lengthening
%%
expSettings.TRSS2017Impedance.rampNormLengths           = [0.70,1.15;...
                                                       0.85,1.30;...
                                                       1.0,1.45];
expSettings.TRSS2017Impedance.normLengths = ...
    zeros(size(expSettings.TRSS2017Impedance.rampNormLengths));

expSettings.TRSS2017Impedance.normLengths(:,1) =...
    expSettings.TRSS2017Impedance.rampNormLengths(:,1)+0.02;
expSettings.TRSS2017Impedance.normLengths(:,2) =...
    expSettings.TRSS2017Impedance.rampNormLengths(:,2)-0.08;

expSettings.TRSS2017Impedance.activationDurationMultiple= [ 1.5,1;...
                                                        1.5,1;...
                                                        1.5,1];

dl = expSettings.TRSS2017Impedance.rampNormLengths(:,2) ...
     -expSettings.TRSS2017Impedance.rampNormLengths(:,1);
assert(abs(dl(1,1)-dl(2,1)) < 1e-6);
assert(abs(dl(2,1)-dl(3,1)) < 1e-6);

v = 0.11*maxNormalizedShorteningSpeedLPS;

expSettings.TRSS2017Impedance.rampDuration              = ones(3,1).*([dl(1,1)/v].*1000);
expSettings.TRSS2017Impedance.perturbationMagnitude     = ones(3,1).*0.005;
expSettings.TRSS2017Impedance.perturbationHoldTime      = ones(3,1).*([1/50].*1000);
expSettings.TRSS2017Impedance.perturbationCycles        = ones(3,1).*5;

%%
% Characterization block
%%
expSettings.characterization.passive.normLengths             = [0.6,1.55];
expSettings.characterization.passive.normVelocities          = [0.1,1];

expSettings.characterization.isometricNormLengths           = [0.7,1,1.4];
expSettings.characterization.isometricActivationDurationMultiple= [2,1,1];

expSettings.characterization.activeLengthening.normLengths  = [   0.9,  1.1 ];
expSettings.characterization.activeLengthening.normVelocity = [ (1/3), (2/3)];
expSettings.characterization.activeShortening.normLengths   = [   1.1,  0.9 ];
expSettings.characterization.activeShortening.normVelocity  = [-(1/3),-(2/3)];


flag_useForceRampInjury     = 1;
flag_useLengthRampInjury    = 1;

expSettings.lengthRampInjury.normLengths    = [1.0, 1.8, 1.0];
expSettings.lengthRampInjury.normVelocity   = [1,1,-1].*(1/3);
expSettings.lengthRampInjury.enable         = 1;

expSettings.forceRampInjury.normLength      = [1.0];
expSettings.forceRampInjury.enable          = 1;
expSettings.forceRampInjury.normForce       = [1.0,2.75,1.0];
expSettings.forceRampInjury.duration        = [1.0,0.25,0.25].*1000;