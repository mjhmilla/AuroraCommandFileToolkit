function auroraConfig =  getDefaultAuroraConfiguration610A(... 
                            muscleName,...
                            unitSystem,...                        
                            sampleFrequencyHz,...
                            specimenLceOptInMM,...                                                        
                            maxNormalizedSpeedLPS)

disp('Aurora Configuration for the 3EE');


auroraConfig.approximateSampleLengthInDefaultUnits = ...
    specimenLceOptInMM;


%https://aurorascientific.com/products/muscle-physiology/controllers-levers-transducers/300e-dual-mode-muscle-levers/
%We are using the 300E

auroraConfig.maximumRampSpeedInLPS = maxNormalizedSpeedLPS;
auroraConfig.maximumRampSpeedInMMPS = ...
    maxNormalizedSpeedLPS*(specimenLceOptInMM);

disp('  Note: Find the maximum Length-Ramp speed of the 300E');
auroraConfig.maximumSpeedInMMPS = auroraConfig.maximumRampSpeedInMMPS;
auroraConfig.maximumSpeedInLPS = auroraConfig.maximumRampSpeedInLPS;


auroraConfig.analogToDigitalSampleRateHz = sampleFrequencyHz;
%  This is the rate Aurora's A/D converter will sample signals


auroraConfig.lengthStepResponseTime = 0.002;  
% Set to 2 x the length-step reponse time of the 305B and 305B-LR

auroraConfig.maximumLengthChangeInMM = 10;
auroraConfig.scaleLengthUnitsToMM = 1;

disp('  Note: Find the maximum of commands for the 300E');
auroraConfig.maximumNumberOfCommands = 945;


auroraConfig.unitSystem = unitSystem;

switch unitSystem
    case 'mm_mN_s_Hz'
        auroraConfig.defaultLengthUnit      = 'mm';
        auroraConfig.defaultForceUnit       = 'mN';
        auroraConfig.defaultTimeUnit        = 's';
        auroraConfig.defaultFrequencyUnit   = 'Hz';

        auroraConfig.approximateSampleLengthInDefaultUnits = ...
            specimenLceOptInMM;

        auroraConfig.maximumSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInMMPS; %mm/s

        auroraConfig.maximumRampSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInMMPS; %mm/s

        auroraConfig.maximumLengthChangeInDefaultUnits = ...
            auroraConfig.maximumLengthChangeInMM;
        auroraConfig.scaleLengthUnitsToMM = 1;            

    case 'Ref_s_Hz'
        auroraConfig.defaultLengthUnit      = 'Ref';
        auroraConfig.defaultForceUnit       = 'Ref';
        auroraConfig.defaultTimeUnit        = 's';
        auroraConfig.defaultFrequencyUnit   = 'Hz';

        auroraConfig.approximateSampleLengthInDefaultUnits = 1;

        auroraConfig.maximumSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInLPS;

        auroraConfig.maximumRampSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInLPS;

        auroraConfig.maximumLengthChangeInDefaultUnits = ...
            auroraConfig.maximumLengthChangeInMM ...
            ./ specimenLceOptInMM;
        auroraConfig.scaleLengthUnitsToMM = specimenLceOptInMM;            


end



assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
       ['Error: many functions in the 610 only accept seconds',... 
        ' seconds must be the default time unit']);

%Duration of pre/post trial positioning length ramps
auroraConfig.prePostPositioningDuration = 1;

%Passive properties
auroraConfig.passive.recoveryTime = 10;
%Amount of time needed for the enhanced passive force to subside
%after lengthening the muscle passively

%
auroraConfig.restTimeBetweenActivations  = 10;
auroraConfig.activationPaddingTime       = 0.25;


%Used for long active blocks
switch muscleName
    case 'EDL'
        auroraConfig.stimulation.frequencyHz =80;
        auroraConfig.timeToReachMaxActivation= 0.5;
        auroraConfig.stimulation.maxDuration =5;

    case 'SOL'
        auroraConfig.stimulation.frequencyHz  = 70;
        auroraConfig.timeToReachMaxActivation = 2;
        auroraConfig.stimulation.maxDuration  = 7;

    otherwise
        assert(0, 'Error: unrecognized muscle');
end
auroraConfig.stimulation.pulseWidthMs=5;
auroraConfig.stimulation.minDuration =1;

%Used to probe the active tension of the muscle
auroraConfig.twitch.frequencyHz = 70;
auroraConfig.twitch.pulseWidthMs= 5;
auroraConfig.twitch.duration    = 0.2;
auroraConfig.twitch.restTimeAfterTwitch = 1;

auroraConfig.stop.waitTime = 1;