function config = getPerturbationConfiguration600A(perturbationSettings,...
                                                   auroraConfig)


magnitude      = perturbationSettings.magnitude;
frequencyRange = perturbationSettings.frequencyRange;

config.timeUnits = 's';
config.frequencyUnits='Hz';
config.lengthUnits = auroraConfig.defaultLengthUnit;

config.points           = 2^12;
if(isfield(perturbationSettings,'points'))
    config.points = perturbationSettings.points;
end

config.frequencyHz      = auroraConfig.analogToDigitalSampleRateHz;

config.magnitudeRange    = [1,1].*magnitude;

%This gives the square and sine perturbations the same mean frequency
%in the power spectrum
config.frequencyRange    = frequencyRange; 

%To have a ramp speed between 0.1-1 LPS
config.normSpeedRange    = perturbationSettings.normSpeedRange;

config.holdRange         = perturbationSettings.holdRange;  
config.waitTimeRange     = [1,1].*auroraConfig.minimumWaitTime;

if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
    config.waitTimeRange = config.waitTimeRange/1000;
end

config.duration    = ((config.points-1.5*config.frequencyHz) ...
                      /config.frequencyHz);  

config.paddingDuration  =  ((config.points/config.frequencyHz) ...
                            -config.duration)*0.5;

if(isfield(perturbationSettings,'paddingDuration'))
    config.paddingDuration  =  perturbationSettings.paddingDuration;

    config.duration    = (config.points/config.frequencyHz) ...
                        - 2*config.paddingDuration;
end


dtMin = (config.duration+2*config.paddingDuration)/config.points;

config.distribution = perturbationSettings.distribution;

assert(max(config.holdRange) > dtMin);

assert(config.frequencyHz <= auroraConfig.analogToDigitalSampleRateHz,...
       'Error: Perturbation frequency must be <= the a/d sample rate');






