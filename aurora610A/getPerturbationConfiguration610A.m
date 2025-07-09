function config = getPerturbationConfiguration610A(magnitude,auroraConfig)


config.timeUnits = 's';
config.frequencyUnits='Hz';
config.lengthUnits = auroraConfig.defaultLengthUnit;

config.points           = 2^12;
config.frequencyHz      = auroraConfig.analogToDigitalSampleRateHz;



config.magnitudeRange    = [1,1].*magnitude;

%This gives the square and sine perturbations the same mean frequency
%in the power spectrum
config.frequencyRange    = [5, 39]; 

%To have a ramp speed between 0.1-1 LPS
vmax = magnitude/auroraConfig.lengthStepResponseTime;
vmaxN = vmax / auroraConfig.maximumSpeedInDefaultUnits;

config.normSpeedRange    = [0.1,1].*vmaxN;

config.holdRange         = [(1/100),(1/11.4)];  
config.waitTimeRange     = [2,2].*auroraConfig.lengthStepResponseTime;

assert( min(config.waitTimeRange) > auroraConfig.lengthStepResponseTime,...
       ['Error: min(config.waitTimeRange) > ',...
       'auroraConfig.lengthStepResponseTime is not true']);


%config.waitTimeRange     = [1,1].*auroraConfig.lengthStepResponseTime;

if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
    config.waitTimeRange = config.waitTimeRange/1000;
end


config.paddingDuration  = 0.25;

config.duration    = ...
       ((config.points-2*config.paddingDuration*config.frequencyHz) ...
       /config.frequencyHz);  

probeFrequency  = 20;
probePeriod     = round(1/probeFrequency,3);
probeFrequency  = 1/probePeriod;

config.probe.frequencyHz = probeFrequency;
config.probe.magnitude   = magnitude; 
config.probe.cycles      = round(config.probe.frequencyHz*0.5);
config.probe.duration    = (1/config.probe.frequencyHz)*config.probe.cycles;
config.probe.type        = 'Probe-Length-Sine-Wave';

dtMin = (config.duration+2*config.paddingDuration)/config.points;

assert(config.frequencyHz <= auroraConfig.analogToDigitalSampleRateHz,...
       'Error: Perturbation frequency must be <= the a/d sample rate');






