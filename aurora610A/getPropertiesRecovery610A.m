function configRecovery = getPropertiesRecovery610A(...
                            durationS,amplitudeMM, verbose)

configRecovery.sineWave.waitTime  = 1;
configRecovery.sineWave.frequency = 1;
configRecovery.sineWave.amplitude = amplitudeMM;
configRecovery.sineWave.cycles    = ...
    configRecovery.sineWave.frequency*durationS;
configRecovery.sampleFrequency    = 100;
configRecovery.ramp.waitTime      = 1;
configRecovery.waitTime           = 1;
configRecovery.stopWaitTime       = 1;

if(verbose==1)
    settingsFields = fields(configRecovery);
    fprintf('getPropertiesRecovery610A\n')
    for idxF = 1:1:length(settingsFields)

      subFields = [];
      if(~isnumeric(configRecovery.(settingsFields{idxF})) ...
           && ~ischar(configRecovery.(settingsFields{idxF})))
        subFields = fields(configRecovery.(settingsFields{idxF}));
      end

      if(isempty(subFields))
        param=num2str(configRecovery.(settingsFields{idxF}));
        if(isnumeric(param))          
          fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
        else
          fprintf('\t%s\t%s\n',param,settingsFields{idxF});
        end
      else
        for idxSF = 1:1:length(subFields)
          param=num2str(configRecovery.(settingsFields{idxF}).(subFields{idxSF}));
          if(isnumeric(param))          
            fprintf('\t%1.1f\t%s.%s\n',param,settingsFields{idxF},subFields{idxSF});
          else
            fprintf('\t%s\t%s.%s\n',param,settingsFields{idxF},subFields{idxSF});
          end

        end
      end

    end
    fprintf('\n\n');
end