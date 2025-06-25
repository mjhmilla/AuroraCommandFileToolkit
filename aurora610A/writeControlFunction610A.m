function [smallestNextWaitTime, commandDuration] = ...
    writeControlFunction610A(   fid,...
                                waitTimeInS,...
                                controlFunctionName,...
                                options,...
                                auroraConfig)

%options has fields of
% value
% unit
% printUnit


success= 0;

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
        'Error: auroraConfig.defaultTimeUnit must be in s');
assert(strcmp(auroraConfig.defaultFrequencyUnit,'Hz'),...
        'Error: auroraConfig.defaultFrequencyUnit must be in Hz');
assert(strcmp(auroraConfig.defaultForceUnit,'mN'),...
        'Error: auroraConfig.defaultTimeUnit must be in mN');
assert(strcmp(auroraConfig.defaultLengthUnit,'mm'),...
        'Error: auroraConfig.defaultTimeUnit must be in mm');

commandDuration = waitTimeInS;


switch controlFunctionName
    case 'Step'
        smallestNextWaitTime  = auroraConfig.lengthStepResponseTime;
        commandDuration       = commandDuration ...
                              + auroraConfig.lengthStepResponseTime;

    case 'Ramp'
        
        assert(strcmp(options(2).type,'time'),...
               'Error: Expected a duration at this option index');


        if(options(2).value < auroraConfig.lengthStepResponseTime)
            commandDuration         = commandDuration ...
                                    + auroraConfig.lengthStepResponseTime;
            smallestNextWaitTime    = auroraConfig.lengthStepResponseTime;
        else
            commandDuration         = commandDuration + options(2).value;        
            smallestNextWaitTime    = 0;            
        end

    case 'Sine Wave'
        assert(strcmp(options(1).type,'frequency'),...
               'Error: Expected a frequency at this option index');

        assert(strcmp(options(3).type,'cycles'),...
               'Error: Expected cycles at this option index');



        f = options(1).value;
        c = options(3).value;
        dtCycle = (1/f)*c;


        if(dtCycle < auroraConfig.lengthStepResponseTime)
            commandDuration     = commandDuration ...
                                + auroraConfig.lengthStepResponseTime ;
            smallestNextWaitTime = auroraConfig.lengthStepResponseTime;
        else
            commandDuration         =  commandDuration + dtCycle;
            smallestNextWaitTime    = 0;
        end


    case 'Sum-Sine Wave'

        assert(strcmp(options(5).type,'time'),...
               'Error: Expected time at this option index');


        if(options(5).value < auroraConfig.lengthStepResponseTime)
            commandDuration      = commandDuration ...
                                 + auroraConfig.lengthStepResponseTime;
            smallestNextWaitTime = auroraConfig.lengthStepResponseTime;                                 
        else
            commandDuration         = commandDuration + options(5).value;
            smallestNextWaitTime    = 0;
        end
        

    case 'Stimulus-Train'

        assert(strcmp(options(1).type,'time'),...
               'Error: Expected a duration at this option index');
        assert(strcmp(options(2).type,'frequency'),...
               'Error: Expected a frequency at this option index');
        assert(strcmp(options(4).type,'pulses'),...
               'Error: Expected pulses at this option index');
        assert(strcmp(options(5).type,'Hz'),...
               'Error: Expected Hz at this option index');

        initialDelay    = options(1).value;
        pulseFrequency  = options(2).value;
        pulsesPerTrain  = options(4).value
        trainFrequency  = options(5).value

        smallestNextWaitTime = 0;

        commandDuration = inf;


    case 'Stimulus-Tetanus'

        assert(strcmp(options(1).type,'time'),...
               'Error: Expected a duration at this option index');
        assert(strcmp(options(2).type,'frequency'),...
               'Error: Expected a frequency at this option index');
        assert(strcmp(options(4).type,'time'),...
               'Error: Expected pulses at this option index');

        initialDelay    = options(1).value;
        timeDuration    = options(4).value;

        smallestNextWaitTime   = 0;
        commandDuration        = commandDuration + initialDelay + timeDuration;

    case 'Stimulus-Twitch'

        smallestNextWaitTime   = 0;
        %commandDuration        = 0; just the wait time

    case 'Trigger'

        smallestNextWaitTime   = 0;
        %commandDuration        = 0; just the wait time

    case 'Stop'

        smallestNextWaitTime   = 0;
        %commandDuration        = 0; just the wait time

    otherwise
        assert(0, ['Error: ',controlFunctionName,...
                ' is an unrecognized function']);
end


waitTimeStr = sprintf('%1.6f',waitTimeInS);


if(length(options) > 0)
    commandLine = sprintf('%s\t%s\t%s\t',waitTimeStr,controlFunctionName,options(1).port);
else
    commandLine = sprintf('%s\t%s',waitTimeStr,controlFunctionName);
end


if(isempty(options)==0)
    for i=1:1:length(options)


        unitStr = '';
        valueStr = '';
        switch options(i).type

            case 'time'
                unitStr = options(i).unit;  
                switch unitStr
                    case 'ms'
                        valueStr = sprintf('%1.1f',options(i).value);
                    case 's'
                        valueStr = sprintf('%1.6f',options(i).value);                    
                    otherwise 
                        assert(0,'Error: time unit must be ms or s');
                end



            case 'length'
                unitStr = options(i).unit;                    
                if(options(i).isRelative==1)
                    if(options(i).value >= 0)
                        valueStr = sprintf('+%1.4f',options(i).value);
                    else
                        valueStr = sprintf('%1.4f',options(i).value);
                    end
                else
                    valueStr = sprintf('%1.6f',options(i).value);                
                end

            case 'force'
                unitStr = options(i).unit;                    
                if(options(i).isRelative==1)
                    if(options(i).value >= 0)
                        valueStr = sprintf('+%1.4f',options(i).value);
                    else
                        valueStr = sprintf('-%1.4f',options(i).value);
                    end
                else
                    assert( options(i).value > 0, ...
                            'Error: an absolute force must be positive');                
                    valueStr = sprintf('%1.6f',options(i).value);                
                end

            case 'frequency'
                unitStr  = options(i).unit;  

                %Question: must all frequencies be whole number values?
                valueStr = sprintf('%1.4f',options(i).value);            


            case 'cycles'
                valueStr = sprintf('%1.4f',options(i).value);  


            case 'pulses'
                valueStr = sprintf('%i',options(i).value);  


            case 'integer'
                valueStr = sprintf('%i',options(i).value);  

        end
        
        if(i > 1)
            valueStr=[',',valueStr];
        end

        if(options(i).printUnit==1)
            commandLine = sprintf('%s%s %s',commandLine,valueStr,unitStr);
        else
            commandLine = sprintf('%s%s',commandLine,valueStr);
        end

    end

end



fprintf(fid,'%s\n',commandLine);

success= 1;
