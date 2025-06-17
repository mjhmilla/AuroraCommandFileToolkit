function [commandOption,isValid,msg]= ...
            getCommandFunctionOptions600A(controlFunctionName,...
                                          auroraConfig)


optionTypes = {};

isValid = 1;
msg = '';


switch controlFunctionName
    case 'Length-Step'
        %optionTypes = {'length'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;


    case 'Length-Ramp'
        %optionTypes = {'length','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;

        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;

    case 'Length-Square'
        %optionTypes = {'frequency','length','time'};
        commandOption(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;        

    case 'Length-Sine'
        %optionTypes = {'frequency','length','time'};    
        commandOption(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;              

    case 'Length-Sweep'
        %optionTypes = {'frequency','frequency','length','time'};
        commandOption(4) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  


    case 'Length-Sample'
        %optionTypes = {'sample','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;          
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Length-Hold'
        %optionTypes = {'sample'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;          

    case 'Read-Larb'
        %optionTypes = {'length','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);
        i=1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;   

    case 'Write-Larb'
        %optionTypes = {'length','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);
        i=1;
        commandOption(i).unit = auroraConfig.defaultLengthUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Send-Larb'
        commandOption = [];

    case 'Length-Arb'
        commandOption = [];
    case 'Force-Step'
        %optionTypes = {'force'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;


    case 'Force-Ramp'
        %optionTypes = {'force','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;

        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;        

    case 'Force-Square'
        %optionTypes = {'frequency','force','time'};
        commandOption(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;    

    case 'Force-Sine'
        %optionTypes = {'frequency','force','time'};
        commandOption(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;    

    case 'Force-Sweep'
        %optionTypes = {'frequency','frequency','force','time'};
        commandOption(4) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;
        i=1+1;
        commandOption(i).unit = auroraConfig.defaultFrequencyUnit;
        commandOption(i).printUnit = 1;        
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;    

    case 'Force-Sample'
        %optionTypes = {'sample','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;          
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Force-Hold'
        %optionTypes = {'sample'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;                  

    case 'Force-Clamp'
        %optionTypes = {'force','time','time'};
        commandOption(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = auroraConfig.defaultForceUnit;
        commandOption(i).printUnit = 1;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;

        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;

    case 'SL-Step'
        %optionTypes = {'length'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'um';
        commandOption(i).printUnit = 0;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;

    case 'SL-Ramp'
        %optionTypes = {'length','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'um';
        commandOption(i).printUnit = 0;
        commandOption(i).isRelative = auroraConfig.useRelativeUnits;        
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;


    case 'SL-Sample'
        %optionTypes = {'sample','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;

    case 'SL-Hold'
        %optionTypes = {'sample'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);

        i=1;
        commandOption(i).unit = 'sample';
        commandOption(i).printUnit = 0;

    case 'SL-Trigger'
        %optionTypes = {'time'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);        
        i=1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;        

    case 'SL-Track'
        %optionTypes = {'bool'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);
        i=1;
        commandOption(i).unit = 'bool';
   

    case 'Stimulus'
        %optionTypes = {'integer','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);        
        i=1;
        commandOption(i).unit = 'integer';
        commandOption(i).printUnit = 0;  
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Trigger1'
        %optionTypes = {'integer','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);        
        i=1;
        commandOption(i).unit = 'integer';
        commandOption(i).printUnit = 0;  
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Trigger2'
        %optionTypes = {'integer','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);        
        i=1;
        commandOption(i).unit = 'integer';
        commandOption(i).printUnit = 0;  
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;  

    case 'Data-Enable'
        %optionTypes = {};
        commandOption = [];
    case 'Data-Disable'
        %optionTypes = {};
        commandOption = [];

    case 'Data-Burst'
        %optionTypes = {'time','time'};
        
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);   
        i=1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1; 
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;

    case 'Bath'
        %optionTypes = {'integer','time'};
        commandOption(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);   
        i=1;
        commandOption(i).unit = 'integer';
        commandOption(i).printUnit = 1; 
        i=i+1;
        commandOption(i).unit = auroraConfig.defaultTimeUnit;
        commandOption(i).printUnit = 1;

    case 'Repeat'
        %optionTypes = {'integer'};
        commandOption(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan);   
        i=1;
        commandOption(i).unit = 'integer';
        commandOption(i).printUnit = 1; 

    case 'Stop'
        commandOption = [];
    otherwise 
        %optionTypes={};
        commandOption = [];
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end
