function config = getPerturbationConfiguration(auroraConfig)

config.timeUnits = 's';
config.frequencyUnits='Hz';
config.lengthUnits = 'Lo';

config.points           = 2^13;
config.frequencyHz      = auroraConfig.analogToDigitalSampleRateHz;

config.magnitudeRange    = [0.001,0.001];

%This gives the square and sine perturbations the same mean frequency
%in the power spectrum
config.frequencyRange    = [3, 40.43]; 

config.normSpeedRange    = [0.1,1];
config.holdRange         = [(1/100),(1/10)];  
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



% s2ms =1000;
% 
% switch auroraConfig.defaultTimeUnit
%     case 's'
%         config.holdRange   = [(1/100),(1/10)];  
% 
%         config.duration    = ((config.points-1.5*config.frequencyHz) ...
%                               /config.frequencyHz);  
% 
%         config.paddingDuration  = ...
%            ((config.points ...
%             /config.frequencyHz) ...
%             -config.duration)*0.5;
%         
%         dtMin = (config.duration+2*config.paddingDuration)...
%                /config.points;        
%     case 'ms'
%         config.holdRange   = [(1/100),(1/10)].*s2ms;
% 
%         config.duration    = ((config.points -1.5*config.frequencyHz) ...
%                               /config.frequencyHz).*s2ms;    
% 
%         config.paddingDuration  = ...
%            ((config.points ...
%             /config.frequencyHz) ...
%             -config.duration)*0.5 * s2ms;
%         
%         dtMin = ((config.duration+2*config.paddingDuration)...
%                /config.points) * s2ms;
%     otherwise 
%         assert(0,'Error: invalid time unit');
% 
% end



