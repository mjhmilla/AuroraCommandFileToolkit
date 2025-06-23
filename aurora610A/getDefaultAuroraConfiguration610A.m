function auroraConfig =  getDefaultAuroraConfiguration610A(...                            
                            sampleFrequencyHz,...
                            approximateSampleLengthInMM,...                            
                            maxNormalizedSpeedLPS)

disp('Aurora Configuration for the 3EE');


%https://aurorascientific.com/products/muscle-physiology/controllers-levers-transducers/300e-dual-mode-muscle-levers/
%We are using the 300E

auroraConfig.maximumRampSpeedInLPS = maxNormalizedSpeedLPS;
auroraConfig.maximumRampSpeedInMPS = ...
    auroraConfig.maximumRampSpeedInLPS*(approximateSampleLengthInMM/1000);

disp('  Note: Find the maximum Length-Ramp speed of the 300E');
auroraConfig.maximumSpeedInMPS = auroraConfig.maximumRampSpeedInMPS;
auroraConfig.maximumSpeedInLPS = auroraConfig.maximumRampSpeedInLPS;


auroraConfig.analogToDigitalSampleRateHz = sampleFrequencyHz;
%  This is the rate Aurora's A/D converter will sample signals


disp('  Note: Is there a minimum wait time between commands?');
auroraConfig.postCommandPauseTime = 0.0001; 
%  The Aurora system needs a pause time of at least 0.1 ms between ramps


disp('  Note: Find the maximum of commands for the 300E');
auroraConfig.maximumNumberOfCommands = 945;


auroraConfig.activationTime = 2;

auroraConfig.defaultLengthUnit      = 'mm';
auroraConfig.defaultForceUnit       = 'N';
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