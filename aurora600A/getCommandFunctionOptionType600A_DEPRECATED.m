function [optionTypes, isValid, msg]=...
        getCommandFunctionOptionType600A(commandFunctionName, options)





optionTypes = {};

isValid = 1;
msg = '';


switch commandFunctionName
    case 'Length-Step'
        optionTypes = {'length'};
    case 'Length-Ramp'
        optionTypes = {'length','time'};
    case 'Length-Square'
        optionTypes = {'frequency','length','time'};
    case 'Length-Sine'
        optionTypes = {'frequency','length','time'};        
    case 'Length-Sweep'
        optionTypes = {'frequency','frequency','length','time'};
    case 'Length-Sample'
        optionTypes = {'sample','time'};
    case 'Length-Hold'
        optionTypes = {'sample'};
    case 'Read-Larb'
        optionTypes = {'length','time'};
    case 'Write-Larb'
        optionTypes = {'length','time'};
    case 'Send-Larb'
        optionTypes = {};
    case 'Length-Arb'
        optionTypes = {};
    case 'Force-Step'
        optionTypes = {'force'};
    case 'Force-Ramp'
        optionTypes = {'force','time'};
    case 'Force-Square'
        optionTypes = {'frequency','force','time'};
    case 'Force-Sine'
        optionTypes = {'frequency','force','time'};
    case 'Force-Sweep'
        optionTypes = {'frequency','frequency','force','time'};
    case 'Force-Sample'
        optionTypes = {'sample','time'};
    case 'Force-Hold'
        optionTypes = {'sample'};
    case 'Force-Clamp'
        optionTypes = {'force','time','time'};
    case 'SL-Step'
        optionTypes = {'length'};
    case 'SL-Ramp'
        optionTypes = {'length','time'};
    case 'SL-Sample'
        optionTypes = {'sample','time'};
    case 'SL-Hold'
        optionTypes = {'sample'};
    case 'SL-Trigger'
        optionTypes = {'time'};
    case 'SL-Track'
        optionTypes = {'bool'};
    case 'Stimulus'
        optionTypes = {'integer','time'};
    case 'Trigger1'
        optionTypes = {'integer','time'};
    case 'Trigger2'
        optionTypes = {'integer','time'};
    case 'Data-Enable'
        optionTypes = {};
    case 'Data-Disable'
        optionTypes = {};
    case 'Data-Burst'
        optionTypes = {'time','time'};
    case 'Bath'
        optionTypes = {'integer','time'};
    case 'Repeat'
        optionTypes = {'integer'};
    case 'Stop'
        optionTypes = {};
    otherwise 
        optionTypes={};
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end



if(isValid == 1 && length(options) > 0)
    if(length(options) == length(optionTypes))
        isValid = 1;
        if(length(optionTypes)>0)
            for i=1:1:length(optionTypes)
                unitType = getUnitType600A(options(i).unit);
                if(~strcmp(unitType,optionTypes{i}))
                    isValid = 0;
                    msg = ['Error: expected option ',num2str(i),' to be ',...
                           options(i).type,' but found ',optionTypes{i} ];                    
                end
            end
        end    
    else
        isValid = 0;
        msg = ['Error: expected ',num2str(length(optionTypes)),...
                 ' found ',num2str(length(options))];

    end
end

