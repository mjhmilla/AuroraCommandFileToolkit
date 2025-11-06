function stochasticWaves = ...
    unifyPerturbationStructure(...
        perturbationSettings,...
        squarePreconditioningWave,...
        squareStochasticWave,...
        sinePreconditioningWave,...
        sineStochasticWave,...
        larbStochasticWaveSet,...
        auroraConfig)

assert(length(squareStochasticWave.controlFunctions.waitDuration)...
        < (auroraConfig.maximumNumberOfCommands + 40),...
      'Error: the number of square perturbation commands is too high');

assert(length(sineStochasticWave.controlFunctions.waitDuration)...
        < (auroraConfig.maximumNumberOfCommands + 40),...
      'Error: the number of sine perturbation commands is too high');



switch perturbationSettings.waveType
    case 'lengthRamp'
        switch(perturbationSettings.bandwidth)
            case 'low'
                stochasticWaves(2)=struct('controlFunction',[],'waitDuration',[],...
                                         'optionValues',[],'options',[],'type','');
                
                controlFields = {'controlFunction','waitDuration',...
                         'optionValues','options'};
        
                for j=1:1:length(controlFields)
                    stochasticWaves(1).(controlFields{j}) = ...
                        squarePreconditioningWave.controlFunctions.(controlFields{j});
                    stochasticWaves(1).type = 'Length-Ramp-Preconditioning';
                
                    stochasticWaves(2).(controlFields{j}) = ...
                        squareStochasticWave.controlFunctions.(controlFields{j});
                    stochasticWaves(2).type = 'Length-Ramp-Stochastic';
                end
            case 'high'
                stochasticWaves(1)=struct('controlFunction',[],'waitDuration',[],...
                                         'optionValues',[],'options',[],'type','');
                
                controlFields = {'controlFunction','waitDuration',...
                         'optionValues','options'};
        
                for j=1:1:length(controlFields)                
                    stochasticWaves(1).(controlFields{j}) = ...
                        squareStochasticWave.controlFunctions.(controlFields{j});
                    stochasticWaves(1).type = 'Length-Ramp-Stochastic';
                end                

            otherwise
                assert(0,'Error: invalid perturbationSettings.bandwidth');
        end
    case 'sineWave'
        switch(perturbationSettings.bandwidth)
            case 'low'
                stochasticWaves(2)=struct('controlFunction',[],'waitDuration',[],...
                                         'optionValues',[],'options',[],'type','');
                
                controlFields = {'controlFunction','waitDuration',...
                                 'optionValues','options'};
                
                for j=1:1:length(controlFields)                    
                    stochasticWaves(1).(controlFields{j}) = ...
                        sinePreconditioningWave.controlFunctions.(controlFields{j});
                    stochasticWaves(1).type = 'Length-Sine-Preconditioning';
                    
                    stochasticWaves(2).(controlFields{j}) = ...
                        sineStochasticWave.controlFunctions.(controlFields{j});
                    stochasticWaves(2).type = 'Length-Sine-Stochastic';                    
                end                

            case 'high'
                stochasticWaves(1)=struct('controlFunction',[],'waitDuration',[],...
                                         'optionValues',[],'options',[],'type','');
                
                controlFields = {'controlFunction','waitDuration',...
                                 'optionValues','options'};
                
                for j=1:1:length(controlFields)                                        
                    stochasticWaves(1).(controlFields{j}) = ...
                        sineStochasticWave.controlFunctions.(controlFields{j});
                    stochasticWaves(1).type = 'Length-Sine-Stochastic';                    
                end                  

            otherwise
                assert(0,'Error: invalid perturbationSettings.bandwidth');
        end
    case 'larb'
        % Arbitrary waveforms
        nWaves = length(larbStochasticWaveSet);

        stochasticWaves(nWaves)=...
            struct('controlFunction',[],'waitDuration',[],...
                   'optionValues',[],'options',[],'type','',...
                   'metadata',[],'auroraConfig',[],'waveConfig',[]);
        
        controlFields = {'controlFunction','waitDuration',...
                         'optionValues','options','fileName','fileData'};
        
        for i=1:1:nWaves
            for j=1:1:length(controlFields)
    
                stochasticWaves(i).(controlFields{j}) = ...
                    larbStochasticWaveSet(i).wave.controlFunctions.(controlFields{j});
                
            end 

            stochasticWaves(i).type = 'Larb-Stochastic';
            stochasticWaves(i).options(1).value=i; %Larb file id   

            stochasticWaves(i).metadata.bandwidth = ...
                larbStochasticWaveSet(i).wave.config.arbitraryWaveform.bandwidth;
            stochasticWaves(i).metadata.amplitude = ...
                max(larbStochasticWaveSet(i).wave.config.magnitude);
            stochasticWaves(i).metadata.points = ...
                max(larbStochasticWaveSet(i).wave.config.points);
            stochasticWaves(i).metadata.frequencyHz = ...
                max(larbStochasticWaveSet(i).wave.config.frequencyHz);

            stochasticWaves(i).auroraConfig = ...
                larbStochasticWaveSet(i).auroraConfig;
            stochasticWaves(i).waveConfig = ...
                larbStochasticWaveSet(i).waveConfig;
            
        end        
    otherwise
        assert(0,'Error: invalid value in perturbationSettings.waveType');
end

