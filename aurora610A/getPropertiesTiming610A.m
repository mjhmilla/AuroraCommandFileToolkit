function configTiming = getPropertiesTiming610A(...
                          defaultSampleFrequency,...
                          recoverySampleFrequency,...
                          twitchSampleFrequency,verbose)

configTiming.waitTime     = 1;
configTiming.stopWaitTime = 1;
configTiming.sampleFrequency = defaultSampleFrequency;
configTiming.sampleFrequencyRecovery = recoverySampleFrequency;
configTiming.sampleFrequencyTwitch=twitchSampleFrequency;


if(verbose==1)
    settingsFields = fields(configTiming);
    fprintf('\ngetPropertiesTiming610A\n')
    for idxF = 1:1:length(settingsFields)
      param = num2str(configTiming.(settingsFields{idxF}));
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        fprintf('\t%s\t%s\n',param,settingsFields{idxF});
      end
    end
    fprintf('\n\n');
end