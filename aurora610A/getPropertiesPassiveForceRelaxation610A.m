function configRelaxation = getPropertiesPassiveForceRelaxation610A(verbose)


configRelaxation.waitTime  = 1;
configRelaxation.duration  = 2;
configRelaxation.frequency = 50;
configRelaxation.amplitude = 0.5;
configRelaxation.cycles    = configRelaxation.frequency ...
                            *configRelaxation.duration;


if(verbose==1)
    settingsFields = fields(configRelaxation);
    fprintf('getPropertiesRecovery610A\n')
    for idxF = 1:1:length(settingsFields)
      param = num2str(configRelaxation.(settingsFields{idxF}));
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        fprintf('\t%s\t%s\n',param,settingsFields{idxF});
      end
    end
    fprintf('\n\n');
end