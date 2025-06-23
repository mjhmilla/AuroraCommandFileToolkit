function [endTime]= ...
    writeControlFunction610A(   fid,...
                                startTime,...
                                timeUnit,...
                                controlFunctionName,...
                                options,...
                                auroraConfig)

%options has fields of
% value
% unit
% printUnit



assert(strcmp(timeUnit,'ms'),...
        'Error: timeUnit and startTime must be in ms');



timeStr = sprintf('%1.6f',startTime);
endTime = str2double(timeStr);


if(length(options) > 0)
    commandLine = sprintf('%s\t%s\t%s\t',timeStr,controlFunctionName,options(1).port);
else
    commandLine = sprintf('%s\t%s',timeStr,controlFunctionName);
end
% Check that the options are valid

controlsWithADuration = ...
    {'Ramp','Sum-Sine Wave','Stimulus-Tetanus','Stimulus-Twitch'};

isLastTimeFieldDelay = 0;

for i=1:1:length(controlsWithADuration)
    if(strcmp(controlsWithADuration{i},controlFunctionName))
        isLastTimeFieldDelay = 1;
    end
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

                if(isLastTimeFieldDelay)
                    switch unitStr
                        case 'ms'
                            endTime = endTime + str2double(valueStr);
                        case 's'
                            endTime = endTime + str2double(valueStr)/1000;                   
                        otherwise 
                            assert(0,'Error: time unit must be ms or s');
                    end                               
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
                    assert( options(i).value > 0, ...
                            'Error: an absolute length must be positive');
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

%nextStartTime = endTime;

%if(abs(endTime-startTime) < auroraConfig.postCommandPauseTime)
%    nextStartTime = endTime + auroraConfig.postCommandPauseTime;
%else
%    
%end

fprintf(fid,'%s\n',commandLine);

