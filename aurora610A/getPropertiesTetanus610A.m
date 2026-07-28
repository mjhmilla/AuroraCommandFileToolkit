function configTetanus = ...
  getPropertiesTetanus610A(configMuscle,configTiming,verbose)


switch configMuscle.name 

  case 'EDL'
    refData.temperatureC            = [  22,    37    ];        
    
    refData.pulseFrequencyHz        = [  70,   300    ];  %From our exp: 20260519
    refData.pulseWidthMs            = [   5,     0.4  ];  %Our settings

    %From our exp: 20260519
    %The 0-97.5% rise time increases with each subsequent activation. 
    %The value below will reach 97.5% of the maximum value for the first
    %20 stimulations, without exceeding 100% and reaching the decline on
    %any trial     
    refData.riseTimeS               = [   0.401, 0.087];  

    [tempError,idxMin] = min(abs(refData.temperatureC-configMuscle.temperatureC));

    configTetanus.initialDelay   = 0;   

    configTetanus.pulseFrequency   =   interp1(refData.temperatureC,...
                                              refData.pulseFrequencyHz,...
                                              configMuscle.temperatureC,...
                                              'linear','extrap');

    configTetanus.pulseWidth       = interp1(refData.temperatureC,...
                                              refData.pulseWidthMs,...
                                              configMuscle.temperatureC,...
                                              'linear','extrap');
   
    configTetanus.timeToReachMaxActivation = ...
        interp1(refData.temperatureC,...
                refData.riseTimeS,...
                configMuscle.temperatureC,...
                'linear','extrap');

    configTetanus.durationExtension        = 0.1;
    %2026/07/27
    %This is used to lengthen the tetanus period when ramps are used
    %Why? Sometimes the ramp and tetanus timing are not completely 
    %synchronized and this can result in a post-tetanus ramp beginning
    %before the tetanus has completed.
    
    configTetanus.recoveryTime            = 5;
    %2026/07/28
    %The time needed to return to baseline.

  case 'SOL'
    assert(0,'Error: Populate the solues settings');

  otherwise
    assert(0,'Error: unrecognized muscle name');

end


assert(((1000/configTiming.sampleFrequency)< configTetanus.pulseWidth),...
        ['Error: configTiming.sampleFrequency is not high enough to ensure that ',...
         'stimulation pulses are recorded.']);

if(verbose==1)
    settingsFields = fields(configTetanus);
    fprintf('getPropertiesTetanus610A\n')
    for idxF = 1:1:length(settingsFields)
      param = num2str(configTetanus.(settingsFields{idxF}));
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        fprintf('\t%s\t%s\n',param,settingsFields{idxF});
      end
    end
    fprintf('\n\n');
end