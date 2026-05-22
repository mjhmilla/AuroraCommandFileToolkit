function configTwitch = getPropertiesTwitch610A(configTiming,verbose)

configTwitch.waitTime       = configTiming.waitTime;
configTwitch.initialDelay   = 0;
configTwitch.pulseWidth     = 0.25;
assert(configTwitch.pulseWidth<=0.25,...
  ['Error: pulseWidth for a twitch must be similar to the pulse',...
   ' width produced by a motor neuron.']);

if(verbose==1)
  settingsFields = fields(configTwitch);
  fprintf('getPropertiesTwitch610A\n')
  for idxF = 1:1:length(settingsFields)
    param = num2str(configTwitch.(settingsFields{idxF}));
    if(isnumeric(param))
      fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
    else
      fprintf('\t%s\t%s\n',param,settingsFields{idxF});
    end
  end
  fprintf('\n\n');
end