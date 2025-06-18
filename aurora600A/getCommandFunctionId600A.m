function [id,isValid,msg]= ...
            getCommandFunctionId600A(controlFunctionName)


optionTypes = {};

isValid = 1;
msg = '';


switch controlFunctionName
    case 'Length-Step'
        id = 1;
    case 'Length-Ramp'
        id = 2;
    case 'Length-Square'
        id = 3;
    case 'Length-Sine'
        id = 4;
    case 'Length-Sweep'
        id = 5;
    case 'Length-Sample'
        id = 6;
    case 'Length-Hold'
        id = 7;
    case 'Read-Larb'
        id = 8;
    case 'Write-Larb'
        id = 9;
    case 'Send-Larb'
        id = 10;
    case 'Length-Arb'
        id = 11;
    case 'Force-Step'
        id = 20;
    case 'Force-Ramp'
        id = 21;
    case 'Force-Square'
        id = 22;
    case 'Force-Sine'
        id = 23;
    case 'Force-Sweep'
        id = 24;
    case 'Force-Sample'
        id = 25;
    case 'Force-Hold'
        id = 26;
    case 'Force-Clamp'
        id = 27;
    case 'SL-Step'
        id = 30;
    case 'SL-Ramp'
        id = 31;
    case 'SL-Sample'
        id = 32;
    case 'SL-Hold'
        id = 33;
    case 'SL-Trigger'
        id = 34;
    case 'SL-Track'
        id = 35;
    case 'Stimulus'
        id = 40;
    case 'Trigger1'
        id = 41;
    case 'Trigger2'
        id = 42;
    case 'Data-Enable'
        id = 43;
    case 'Data-Disable'
        id = 44;
    case 'Data-Burst'
        id = 45;
    case 'Bath'
        id = 46;        
    case 'Repeat'
        id = 47;        
    case 'Stop'
        id = 48;        
    otherwise 
        %optionTypes={};
        commandOption = [];
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end
