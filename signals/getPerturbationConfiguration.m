function config = getPerturbationConfiguration(auroraConfig)


config.timeUnits = 's';
config.frequencyUnits='Hz';
config.lengthUnits = 'Lo';

config.points           = 2^12;
config.frequencyHz      = auroraConfig.analogToDigitalSampleRateHz;

config.magnitudeRange    = [0.005,0.005];

%This gives the square and sine perturbations the same mean frequency
%in the power spectrum
config.frequencyRange    = [5, 39]; 

%To have a ramp speed between 0.1-1 LPS
config.normSpeedRange    = [0.1,1];

config.holdRange         = [(1/500),(1/20)];  
config.waitTimeRange     = [1,1].*auroraConfig.postCommandPauseTime;

if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
    config.waitTimeRange = config.waitTimeRange/1000;
end

config.duration    = ((config.points-1.5*config.frequencyHz) ...
                      /config.frequencyHz);  

config.paddingDuration  =  ((config.points/config.frequencyHz) ...
                            -config.duration)*0.5;

dtMin = (config.duration+2*config.paddingDuration)/config.points;



assert(max(config.holdRange) > dtMin);

assert(config.frequencyHz <= auroraConfig.analogToDigitalSampleRateHz,...
       'Error: Perturbation frequency must be <= the a/d sample rate');






