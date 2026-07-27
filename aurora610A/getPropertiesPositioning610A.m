function configPositioning = getPropertiesPositioning610A(verbose)


configPositioning.rampSpeedInMMPS  = 0.5;
configPositioning.minimumRampTime  = 1.0;
configPositioning.waitTime         = 1.0;
configPositioning.recoveryWaitTime = 5.0;

if(verbose==1)
    settingsFields = fields(configPositioning);
    fprintf('getPropertiesPositioning610A\n')
    for idxF = 1:1:length(settingsFields)
      param = num2str(configPositioning.(settingsFields{idxF}));
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        fprintf('\t%s\t%s\n',param,settingsFields{idxF});
      end
    end
    fprintf('\n\n');
end