function auroraConfig =  getDefaultAuroraConfiguration610A(...                            
                            sampleFrequencyHz,...
                            approximateSampleLengthInMM,...                            
                            maxNormalizedSpeedLPS)

disp('Aurora Configuration for the 3EE');


%https://aurorascientific.com/products/muscle-physiology/controllers-levers-transducers/300e-dual-mode-muscle-levers/
%We are using the 300E

auroraConfig.maximumRampSpeedInLPS = maxNormalizedSpeedLPS;
auroraConfig.maximumRampSpeedInMPS = ...
    maxNormalizedSpeedLPS*(approximateSampleLengthInMM/1000);

disp('  Note: Find the maximum Length-Ramp speed of the 300E');
auroraConfig.maximumSpeedInMPS = auroraConfig.maximumRampSpeedInMPS;
auroraConfig.maximumSpeedInLPS = auroraConfig.maximumRampSpeedInLPS;


auroraConfig.analogToDigitalSampleRateHz = sampleFrequencyHz;
%  This is the rate Aurora's A/D converter will sample signals


auroraConfig.lengthStepResponseTime = 0.002;  
% Set to 2 x the length-step reponse time of the 305B and 305B-LR


disp('  Note: Find the maximum of commands for the 300E');
auroraConfig.maximumNumberOfCommands = 945;


auroraConfig.defaultLengthUnit      = 'mm';
auroraConfig.defaultForceUnit       = 'mN';
auroraConfig.defaultTimeUnit        = 's';
auroraConfig.defaultFrequencyUnit   = 'Hz';

auroraConfig.approximateSampleLengthInDefaultUnits = ...
    approximateSampleLengthInMM;

if(strcmp(auroraConfig.defaultLengthUnit,'m'))
    auroraConfig.approximateSampleLengthInDefaultUnits = ...
        approximateSampleLengthInMM/1000;
end

auroraConfig.scaleFrequencyUnit     = 1; %To put it in cycles/millisecond 

auroraConfig.useRelativeUnits       = 1;

auroraConfig.maximumSpeedInDefaultUnits = ...
    auroraConfig.maximumRampSpeedInMPS*1000; %mm/s

auroraConfig.maximumRampSpeedInDefaultUnits = ...
    auroraConfig.maximumRampSpeedInMPS*1000; %mm/s


assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
       ['Error: many functions in the 610 only accept seconds',... 
        ' seconds must be the default time unit']);

%
auroraConfig.activationTime              = 0.5;
auroraConfig.restTimeBetweenActivations   = 10;
auroraConfig.activationTimeAfterMovement = 0.5;


%Used for long active blocks
auroraConfig.stimulation.frequencyHz =50;
auroraConfig.stimulation.pulseWidthMs=5;
auroraConfig.stimulation.maxDuration =5;

%Used to probe the active tension of the muscle
auroraConfig.twitch.frequencyHz = 70;
auroraConfig.twitch.pulseWidthMs= 5;
auroraConfig.twitch.duration    = 0.2;
auroraConfig.twitch.restTimeAfterTwitch = 1;

auroraConfig.stop.waitTime = 1;