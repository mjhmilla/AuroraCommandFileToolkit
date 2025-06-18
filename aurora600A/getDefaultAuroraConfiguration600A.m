function auroraConfig =  getDefaultAuroraConfiguration600A(...
                            approximateSampleLengthInMM,...
                            sampleFrequencyHz,...
                            minLengthLo,...
                            maxLengthLo)

%pg 3 of the manual for 322 C-I: 300um in 700us
auroraConfig.maximumRampSpeedInMPS = (300e-6/700e-6);
auroraConfig.maximumRampSpeedInLPS = ...
    auroraConfig.maximumRampSpeedInMPS/(approximateSampleLengthInMM/1000);

auroraConfig.numberOfEmptyCommandsPrepended = 10;
%  The Aurora machine appears to ignore the first 9-10 commands and then 
%  begins on the 19th command. Here we prepend a bunch of dummy commands
%  so that your desired signal is not affected.

auroraConfig.analogToDigitalSampleRateHz = sampleFrequencyHz;
%  This is the rate Aurora's A/D converter will sample signals

auroraConfig.postCommandPauseTime = 0.1; 
%  The Aurora system needs a pause time of at least 0.1 ms between ramps

auroraConfig.maximumNumberOfCommands = 945;
%  The Aurora system tends to crash if the command file has more than 950 
%  commands. This parameter is used to check how many entries are in the 
%  resulting PRO file. As the process of generating a *.pro file is a bit
%  complicated, the most reliable way to ensure that the *.pro file is of 
%  an acceptable size is to check after the fact.

auroraConfig.comment = 'EDL, h: 0.091 w:  0.079';
%
s2ms = 1000;

auroraConfig.minimumNormalizedLength    = minLengthLo;
auroraConfig.maximumNormalizedLength    = maxLengthLo;
auroraConfig.pdDeadBand                 = 0;
auroraConfig.bath.changeTime            = 0.5*s2ms;
auroraConfig.bath.preActivationDuration = 60*s2ms;
auroraConfig.bath.passive               = 1;
auroraConfig.bath.preActivation         = 2;
auroraConfig.bath.active                = 3;


auroraConfig.defaultLengthUnit      = 'Lo';
auroraConfig.defaultForceUnit       = 'Fo';
auroraConfig.defaultTimeUnit        = 'ms';
auroraConfig.defaultFrequencyUnit   = 'Hz';

auroraConfig.scaleFrequencyUnit     = 0.001; %To put it in cycles/millisecond 

auroraConfig.useRelativeUnits   = 1;

auroraConfig.maximumRampSpeedInDefaultUnits = ...
    auroraConfig.maximumRampSpeedInLPS/1000; %lengths per millisecond

