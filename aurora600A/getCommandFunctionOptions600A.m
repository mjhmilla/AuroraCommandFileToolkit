function [options,isValid,msg]= ...
            getCommandFunctionOptions600A(controlFunctionName,...
                                          auroraConfig)




isValid = 1;
msg = '';


switch controlFunctionName
    case 'Length-Step'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type = 'length';

    case 'Length-Ramp'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type = 'length';

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type = 'time';

    case 'Length-Square'

        options(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type = 'frequency';

        i=i+1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type = 'length';

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;        
        options(i).type = 'time';

    case 'Length-Sine'

        options(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type = 'frequency';
        i=i+1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type = 'length';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;   
        options(i).type = 'time';           

    case 'Length-Sweep'

        options(4) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type ='frequency';
        i=i+1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type ='frequency';
        i=i+1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='length';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;  
        options(i).type ='time';

    case 'Length-Sample'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;          
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;  
        options(i).type ='time';

    case 'Length-Hold'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;          
        options(i).type ='integer';

    case 'Read-Larb'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');
        i=1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='length';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;   
        options(i).type ='time';

    case 'Write-Larb'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultLengthUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='length';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;  
        options(i).type ='time';

    case 'Send-Larb'

        options = [];

    case 'Length-Arb'

        options = [];

    case 'Force-Step'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';


    case 'Force-Ramp'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;        
        options(i).type ='time';

    case 'Force-Square'

        options(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type ='frequency';        
        i=i+1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;    
        options(i).type ='time';

    case 'Force-Sine'

        options(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type ='frequency';
        i=i+1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;    
        options(i).type ='time';

    case 'Force-Sweep'

        options(4) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;
        options(i).type ='frequency';
        i=1+1;
        options(i).unit = auroraConfig.defaultFrequencyUnit;
        options(i).printUnit = 1;    
        options(i).type ='frequency';    
        i=i+1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;    
        options(i).type ='time';

    case 'Force-Sample'
        
        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;          
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1; 
        options(i).type ='time'; 

    case 'Force-Hold'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;   
        options(i).type ='integer';               

    case 'Force-Clamp'

        options(3) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = auroraConfig.defaultForceUnit;
        options(i).printUnit = 1;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='force';

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;  
        options(i).type ='time';

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type ='time';        

    case 'SL-Step'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'um';
        options(i).printUnit = 0;
        options(i).isRelative = auroraConfig.useRelativeUnits;
        options(i).type ='length';

    case 'SL-Ramp'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'um';
        options(i).printUnit = 0;
        options(i).isRelative = auroraConfig.useRelativeUnits;   
        options(i).type ='length';     

        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type ='time';

    case 'SL-Sample'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type ='time';

    case 'SL-Hold'
        optionTypes = {'integer'};
        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');

        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;
        options(i).type ='integer';

    case 'SL-Trigger'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');        
        i=1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;  
        options(i).type ='time';      

    case 'SL-Track'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');
        i=1;
        options(i).unit = 'bool';
        options(i).type ='bool';
   

    case 'Stimulus'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');        
        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;  
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1; 
        options(i).type ='time'; 

    case 'Trigger1'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');        
        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;  
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1; 
        options(i).type ='time'; 

    case 'Trigger2'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');        
        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0;  
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1; 
        options(i).type ='time'; 

    case 'Data-Enable'
        optionTypes = {};
        options = [];
    case 'Data-Disable'
        optionTypes = {};
        options = [];

    case 'Data-Burst'        
        
        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');   
        i=1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1; 
        options(i).type ='time';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type ='time';

    case 'Bath'

        options(2) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');   
        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 0; 
        options(i).type ='integer';
        i=i+1;
        options(i).unit = auroraConfig.defaultTimeUnit;
        options(i).printUnit = 1;
        options(i).type ='time';

    case 'Repeat'

        options(1) = struct('unit','','value',nan,'printUnit',nan,'isRelative',nan,'type','');   
        i=1;
        options(i).unit = 'integer';
        options(i).printUnit = 1; 
        options(i).type ='integer';
        
    case 'Stop'
        options = [];
    otherwise 
        options = [];
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end
