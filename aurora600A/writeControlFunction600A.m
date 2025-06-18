function [endTime]= ...
    writeControlFunction600A(   fid,...
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

[optionTypes,isValid,message] ...
    = getCommandFunctionOptionType600A(controlFunctionName,options);
assert(isValid==1, message);





timeStr = sprintf('%1.1f',startTime);
endTime = str2double(timeStr);

while length(timeStr)<9
    timeStr = [' ',timeStr];
end

if(length(options) > 0)
    commandLine = sprintf('%s\t%s\t\t',timeStr,controlFunctionName);
else
    commandLine = sprintf('%s\t%s',timeStr,controlFunctionName);
end
% Check that the options are valid

controlsWithADuration = ...
    {'Length-Ramp','Length-Square','Length-Sine',...
     'Length-Sweep','Length-Sample',...
     'Force-Ramp','Force-Square','Force-Sine',...
     'Force-Sweep','Force-Sample','Force-Clamp',...
     'SL-Ramp','SL-Sample','SL-Trigger',...
     'Stimulus','Trigger1','Trigger2',...
     'Data-Burst','Bath'};

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
        switch optionTypes{i}

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
                valueStr = sprintf('%i',options(i).value);            


            case 'bool'
                valueStr = sprintf('%i',options(i).value);  
                assert(options(i).value==0 || options(i).value==1,...
                       'Error: bool type must be 0 or 1');

            case 'integer'
                valueStr = sprintf('%i',options(i).value);  

                if(    strcmp(controlFunctionName,'Stimulus') ...
                    || strcmp(controlFunctionName,'Trigger1') ...
                    || strcmp(controlFunctionName,'Trigger2'))

                    assert(options(i).value >= 1 && options(i).value <= 10,...
                           'Error: Stimulus pattern must be 1-10');
                    assert(abs(options(i).value-round(options(i).value))==0,...
                           'Error: Stimulus pattern must be an integer');

                end

                if(strcmp(controlFunctionName,'Bath'))
                    assert(options(i).value==1 ...
                        || options(i).value == 2 ...
                        || options(i).value == 3,...
                        'Error: Bath option must be 1, 2, or 3');
                end

        end
        
        if(options(i).printUnit==1)
            if(i==1)
                commandLine = sprintf('%s%s %s',commandLine,valueStr,unitStr);
            else
                commandLine = sprintf('%s  %s %s',commandLine,valueStr,unitStr);
            end
        else
            if(i==1)
                commandLine = sprintf('%s%s',commandLine,valueStr);
            else
                commandLine = sprintf('%s  %s',commandLine,valueStr);
            end
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

