function programMetaData  = ...
            writeControlFunction610A(   ...
                fid,...
                waitTimeInS,...
                controlFunctionName,...
                controlFunctionOptions,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile)



assert(waitTimeInS >= programMetaData.smallestNextWaitTime,...
       ['Error: waitTimeInS is not larger than',...
        ' programMetaData.smallestNextWaitTime']);


startTime = programMetaData.nextStartTime;


success= 0;

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
        'Error: auroraConfig.defaultTimeUnit must be in s');
assert(strcmp(auroraConfig.defaultFrequencyUnit,'Hz'),...
        'Error: auroraConfig.defaultFrequencyUnit must be in Hz');
assert(strcmp(auroraConfig.defaultForceUnit,'mN')...
    || strcmp(auroraConfig.defaultForceUnit,'Ref'),...
        'Error: auroraConfig.defaultTimeUnit must be in mN or Ref');
assert(strcmp(auroraConfig.defaultLengthUnit,'mm')...
    || strcmp(auroraConfig.defaultForceUnit,'Ref'),...
        'Error: auroraConfig.defaultTimeUnit must be in mm or Ref');

commandDuration = nan;
nextStartTime   = nan;

%auroraConfig.maximumLengthChangeInMM = 10;
%auroraConfig.scaleLengthUnitsToMM = 1;

switch controlFunctionName
    case 'Step'

        smallestNextWaitTime  = auroraConfig.lengthStepResponseTime;        
        commandDuration       = auroraConfig.lengthStepResponseTime;

        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime;

    case 'Ramp'
        
        assert(strcmp(controlFunctionOptions(2).type,'time'),...
               'Error: Expected a duration at this option index');

        if(controlFunctionOptions(2).value ...
                < auroraConfig.lengthStepResponseTime)

            commandDuration         = auroraConfig.lengthStepResponseTime;
            smallestNextWaitTime    = auroraConfig.lengthStepResponseTime;

        else
            commandDuration         = controlFunctionOptions(2).value;        
            smallestNextWaitTime    = 0;            
        end

        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime;


    case 'Sine Wave'
        assert(strcmp(controlFunctionOptions(1).type,'frequency'),...
               'Error: Expected a frequency at this option index');

        assert(strcmp(controlFunctionOptions(3).type,'cycles'),...
               'Error: Expected cycles at this option index');



        f = controlFunctionOptions(1).value;
        c = controlFunctionOptions(3).value;
        dtCycle = (1/f)*c;


        if(dtCycle < auroraConfig.lengthStepResponseTime)
            commandDuration     = auroraConfig.lengthStepResponseTime ;
            smallestNextWaitTime= auroraConfig.lengthStepResponseTime;

        else
            commandDuration         = dtCycle;
            smallestNextWaitTime    = 0;

        end

        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime;



    case 'Sum-Sine Wave'

        assert(strcmp(controlFunctionOptions(5).type,'time'),...
               'Error: Expected time at this option index');


        if(controlFunctionOptions(5).value ...
                < auroraConfig.lengthStepResponseTime)

            commandDuration      = auroraConfig.lengthStepResponseTime;
            smallestNextWaitTime = auroraConfig.lengthStepResponseTime; 

            nextStartTime   = startTime + waitTimeInS ...
                            + smallestNextWaitTime;                                
        else
            commandDuration         = controlFunctionOptions(5).value;
            smallestNextWaitTime    = 0;
            nextStartTime   = startTime + waitTimeInS ...
                            + controlFunctionOptions(5).value;
        end
        
        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime;

        

    case 'Stimulus-Train'

        assert(strcmp(controlFunctionOptions(1).type,'time'),...
               'Error: Expected a duration at this option index');
        assert(strcmp(controlFunctionOptions(2).type,'frequency'),...
               'Error: Expected a frequency at this option index');
        assert(strcmp(controlFunctionOptions(4).type,'pulses'),...
               'Error: Expected pulses at this option index');
        assert(strcmp(controlFunctionOptions(5).type,'Hz'),...
               'Error: Expected Hz at this option index');

        initialDelay    = controlFunctionOptions(1).value;
        pulseFrequency  = controlFunctionOptions(2).value;
        pulsesPerTrain  = controlFunctionOptions(4).value;
        trainFrequency  = controlFunctionOptions(5).value;

        smallestNextWaitTime = 0;
        nextStartTime   = startTime + waitTimeInS;

        commandDuration = inf;

    case 'Stimulus-Tetanus'

        assert(strcmp(controlFunctionOptions(1).type,'time'),...
               'Error: Expected a duration at this option index');
        assert(strcmp(controlFunctionOptions(2).type,'frequency'),...
               'Error: Expected a frequency at this option index');
        assert(strcmp(controlFunctionOptions(4).type,'time'),...
               'Error: Expected pulses at this option index');

        initialDelay    = controlFunctionOptions(1).value;
        timeDuration    = controlFunctionOptions(4).value;

        smallestNextWaitTime   = 0;
        commandDuration        = initialDelay + timeDuration;

        nextStartTime   = startTime + waitTimeInS;


    case 'Stimulus-Twitch'

        smallestNextWaitTime   = 0;

        initialDelay     = controlFunctionOptions(1).value;
        pulseWidth       = controlFunctionOptions(2).value*0.001;

        commandDuration  = initialDelay+pulseWidth;

        nextStartTime   = startTime + waitTimeInS;

    case 'Trigger'

        smallestNextWaitTime   = 0;
        commandDuration        = 0; 
        nextStartTime   = startTime + waitTimeInS;

    case 'Stop'

        smallestNextWaitTime   = 0;
        commandDuration        = 0; 
        nextStartTime   = startTime + waitTimeInS;

    otherwise
        assert(0, ['Error: ',controlFunctionName,...
                ' is an unrecognized function']);
end





%%
%Update the meta data struct
%%

programMetaData.controlFunction.startTime   = startTime + waitTimeInS;
programMetaData.controlFunction.endTime     = startTime + waitTimeInS+commandDuration;
programMetaData.controlFunction.duration    = commandDuration;

programMetaData.startTime                   = startTime;
programMetaData.nextStartTime               = nextStartTime;
programMetaData.smallestNextWaitTime        = smallestNextWaitTime;

programMetaData.lineCount                   = programMetaData.lineCount + 1;





%%
% Write the command
%%

waitTimeStr = sprintf('%1.6f',waitTimeInS);


if(length(controlFunctionOptions) > 0)
    commandLine = sprintf(  '%s\t%s\t%s\t',...
                            waitTimeStr,...
                            controlFunctionName,...
                            controlFunctionOptions(1).port);
else
    commandLine = sprintf(  '%s\t%s',...
                            waitTimeStr,...
                            controlFunctionName);
end




valueStr = '-';
if(isempty(controlFunctionOptions)==0)
    for i=1:1:length(controlFunctionOptions)


        unitStr     = '';
        valueStr    = '';
        switch controlFunctionOptions(i).type

            case 'time'
                unitStr = controlFunctionOptions(i).unit;  
                switch unitStr
                    case 'ms'
                        valueStr = sprintf('%1.1f',controlFunctionOptions(i).value);
                    case 's'
                        valueStr = sprintf('%1.6f',controlFunctionOptions(i).value);                    
                    otherwise 
                        assert(0,'Error: time unit must be ms or s');
                end



            case 'length'
                unitStr = controlFunctionOptions(i).unit;                    
                if(controlFunctionOptions(i).isRelative==1)
                    if(controlFunctionOptions(i).value >= 0)
                        valueStr = sprintf('+%1.4f',controlFunctionOptions(i).value);
                    else
                        valueStr = sprintf('%1.4f',controlFunctionOptions(i).value);
                    end
                else
                    valueStr = sprintf('%1.6f',controlFunctionOptions(i).value);                
                end

                lengthChange = controlFunctionOptions(i).value;
                assert(lengthChange <= auroraConfig.maximumLengthChangeInDefaultUnits,...
                 ['Error: desired length change exceeds the maximum value of', ...
                  sprintf('%1.1f',auroraConfig.maximumLengthChangeInDefaultUnits),...
                  ' in default units']);


            case 'force'
                unitStr = controlFunctionOptions(i).unit;                    
                if(controlFunctionOptions(i).isRelative==1)
                    if(controlFunctionOptions(i).value >= 0)
                        valueStr = sprintf('+%1.4f',controlFunctionOptions(i).value);
                    else
                        valueStr = sprintf('-%1.4f',controlFunctionOptions(i).value);
                    end
                else
                    assert( controlFunctionOptions(i).value > 0, ...
                            'Error: an absolute force must be positive');                
                    valueStr = sprintf('%1.6f',controlFunctionOptions(i).value);                
                end

            case 'frequency'
                unitStr  = controlFunctionOptions(i).unit;  

                %Question: must all frequencies be whole number values?
                valueStr = sprintf('%1.4f',controlFunctionOptions(i).value);            


            case 'cycles'
                valueStr = sprintf('%1.4f',controlFunctionOptions(i).value);  


            case 'pulses'
                valueStr = sprintf('%i',controlFunctionOptions(i).value);  


            case 'integer'
                valueStr = sprintf('%i',controlFunctionOptions(i).value);  

        end
        
        if(i > 1)
            valueStr=[',',valueStr];
        end

        if(controlFunctionOptions(i).printUnit==1)
            commandLine = sprintf('%s%s %s',commandLine,valueStr,unitStr);
        else
            commandLine = sprintf('%s%s',commandLine,valueStr);
        end

    end

end


%%
% Write the meta data
%%


if(flag_printMetaDataToFile)

    portName = '-';
    if(length(controlFunctionOptions) > 0)
        portName = controlFunctionOptions(1).port;
    end
    idx=strfind(commandLine,char(9));
    idx=idx+1;
    commandLineShort = commandLine(1,idx:end);

    %Stimulus-Twitch is a special case because it does not have a defined
    %ending time.    
    if(strcmp(controlFunctionName,'Stimulus-Twitch'))

        isStarting = 0;
        for i=1:1:length(controlFunctionOptions)
            if( abs(controlFunctionOptions(i).value) > 0)
                isStarting = 1;
            end
        end
        if(isStarting==1)
            fprintf(programMetaData.labelFileHandle,'%s,%s,%1.6f,,\"%s\"\n',...
                    controlFunctionName,...
                    portName,...
                    programMetaData.controlFunction.startTime,...
                    commandLineShort);
        else
            fprintf(programMetaData.labelFileHandle,'%s,%s,,%1.6f,\"%s\"\n',...
                    controlFunctionName,...
                    portName,...
                    programMetaData.controlFunction.startTime,...
                    commandLineShort);
        end

    else
        fprintf(programMetaData.labelFileHandle,'%s,%s,%1.6f,%1.6f,\"%s\"\n',...
                controlFunctionName,...
                portName,...
                programMetaData.controlFunction.startTime,...
                programMetaData.controlFunction.endTime  ,...
                commandLineShort);
    end

end


fprintf(fid,'%s\n',commandLine);



success= 1;
