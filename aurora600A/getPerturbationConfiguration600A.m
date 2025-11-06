function config = getPerturbationConfiguration600A(perturbationSettings,...                                                   
                                                   auroraConfig)

%
% General parameters
%
config.points           = 2^12;
if(isfield(perturbationSettings,'points'))
    config.points = perturbationSettings.points;
end



config.frequencyHz      = auroraConfig.analogToDigitalSampleRateHz;
config.timeUnits = 's';
config.frequencyUnits='Hz';
config.lengthUnits = auroraConfig.defaultLengthUnit;

paddingDurationFraction = 0.05;
paddingPoints = round(config.points*paddingDurationFraction);

config.duration    = ((config.points-2*paddingPoints) ...
                      /config.frequencyHz);  
config.paddingDuration  =  (paddingPoints/config.frequencyHz);

config.magnitude = perturbationSettings.magnitude;

config.distribution='normal';

assert(config.frequencyHz <= auroraConfig.analogToDigitalSampleRateHz,...
       'Error: Perturbation frequency must be <= the a/d sample rate');



switch perturbationSettings.bandwidth
    case 'low'
        %
        % Square wave parameters
        %        
        config.lengthRamp.holdRange         = [(1/100),(1/11.4)];  
        config.lengthRamp.normSpeedRange    = [0.1,1];
        config.lengthRamp.waitTimeRange     = [1,1].*auroraConfig.minimumWaitTime;
        if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
            config.lengthRamp.waitTimeRange = config.lengthRamp.waitTimeRange/1000;
        end
                
        dtMin = (config.duration+2*config.paddingDuration)/config.points;
        assert(max(config.lengthRamp.holdRange) > dtMin);

        %
        % Sine wave parameters
        %
        config.sineWave.magnitudeRange = [0.05,1].* config.magnitude;
        config.sineWave.holdRange      = [(1/100),(1/11.4)];  
        config.sineWave.frequencyRange = [5,39];
        config.sineWave.waitTimeRange  = [1,1].*auroraConfig.minimumWaitTime;
        
        dtMin = (config.duration+2*config.paddingDuration)/config.points;
        assert(max(config.sineWave.holdRange) > dtMin);

        perturbationSettings.larbWave.canBeMerged=1;  
        perturbationSettings.larbWave.bandwidthHz = 35;

        %
        % Arbitrary wave length parameters
        %        
        config.arbitraryWaveform.fileName           ='';
        config.arbitraryWaveform.seed               =6;
        config.arbitraryWaveform.lengthUnit         ='Lo';        
        config.arbitraryWaveform.bandwidth          = 35;
        perturbationSettings.larbWave.canBeMerged   = 1;

    case 'high'


        perturbationSettings.lengthRamp.normSpeedRange  = [0.1,1.5];
        perturbationSettings.lengthRamp.holdRange       = [(1/500),(1/50)];
        
        perturbationSettings.sineWave.normSpeedRange    = [0.1,2.0];
        perturbationSettings.sineWave.holdRange         = [(1/1000),(1/50)];        
        perturbationSettings.sineWave.frequencyRange=[10,150];
        
        perturbationSettings.larbWave.canBeMerged=1;  
        perturbationSettings.larbWave.bandwidthHz = 35;

        %
        % Square wave parameters
        %        
        config.lengthRamp.holdRange         = [(1/500),(1/50)];  
        config.lengthRamp.normSpeedRange    = [0.1,1.5];
        config.lengthRamp.waitTimeRange     = [1,1].*auroraConfig.minimumWaitTime;
        if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
            config.lengthRamp.waitTimeRange = config.lengthRamp.waitTimeRange/1000;
        end
                
        dtMin = (config.duration+2*config.paddingDuration)/config.points;
        assert(max(config.lengthRamp.holdRange) > dtMin);

        %
        % Sine wave parameters
        %
        config.sineWave.magnitudeRange = [0.05,1].* config.magnitude;
        config.sineWave.holdRange      = [(1/500),(1/50)];  
        config.sineWave.frequencyRange = [10,80];
        config.sineWave.waitTimeRange  = [1,1].*auroraConfig.minimumWaitTime;
        if(strcmp(auroraConfig.defaultTimeUnit,'ms'))
            config.sineWave.waitTimeRange = config.sineWave.waitTimeRange/1000;
        end
        dtMin = (config.duration+2*config.paddingDuration)/config.points;
        assert(max(config.sineWave.holdRange) > dtMin);


        %
        % Arbitrary wave length parameters
        %        
        config.arbitraryWaveform.fileName           ='';
        config.arbitraryWaveform.seed               = 6;
        config.arbitraryWaveform.lengthUnit         ='Lo';        
        config.arbitraryWaveform.bandwidth          = 90;
        config.arbitraryWaveform.canBeMerged        = 1;        

    otherwise
        assert(0,'Error: Unrecognized perturbation bandwidth');
end









