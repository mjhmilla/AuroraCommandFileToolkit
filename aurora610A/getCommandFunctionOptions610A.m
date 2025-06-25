function [options,isValid,msg]= ...
            getCommandFunctionOptions610A(controlFunctionName,...
                                          portName,...
                                          auroraConfig)




isValid = 1;
msg = '';
portType ='';

if(length(portName) > 0)
    if(isempty(strfind(portName,'Length'))==0)
        portType ='length';
    end
    
    if(isempty(strfind(portName,'Force'))==0)
        portType ='force';
    end
    
    if(isempty(strfind(portName,'Stimulator'))==0)
        portType ='stimulator';
    end
end



switch controlFunctionName
    case 'Step'

        options(1) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',0);

        i=1;
        switch portType
            case 'length'
                options(i).unit = auroraConfig.defaultLengthUnit;
            case 'force'
                options(i).unit = auroraConfig.defaultForceUnit;
            otherwise
                assert(0,'Error: Unrecognized port type');
        end
        options(i).value        = nan;
        options(i).printUnit    = 0;  %Always zero for the 610A
        options(i).isRelative   = 0; %Always zero for the 610A
        options(i).type         = portType;

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 0;
        end

    case 'Ramp'

        options(2) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',0);

        i=1;
        switch portType
            case 'length'
                options(i).unit = auroraConfig.defaultLengthUnit;
            case 'force'
                options(i).unit = auroraConfig.defaultForceUnit;
            otherwise
                assert(0,'Error: Unrecognized port type');
        end        
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type       = portType;

        i=i+1;
        options(i).unit = 's';
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type       = 'time';

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 0;
        end


    case 'Sine Wave'

        options(3) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',0);


        i=1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';


        i=i+1;
        switch portType
            case 'length'
                options(i).unit = auroraConfig.defaultLengthUnit;
            case 'force'
                options(i).unit = auroraConfig.defaultForceUnit;
            otherwise
                assert(0,'Error: Unrecognized port type');
        end        
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = portType;

        i=i+1;
        options(i).unit = 'cycles';
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'cycles';


        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 0;
        end


    case 'Sum-Sine Wave'

        options(5) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',0);



        i=1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';
        options(i).port = portName;

        i=i+1;
        switch portType
            case 'length'
                options(i).unit = auroraConfig.defaultLengthUnit;
            case 'force'
                options(i).unit = auroraConfig.defaultForceUnit;
            otherwise
                assert(0,'Error: Unrecognized port type');
        end        
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = portType;
        options(i).port = '';

        i=i+1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';
        options(i).port = '';

        i=i+1;
        switch portType
            case 'length'
                options(i).unit = auroraConfig.defaultLengthUnit;
            case 'force'
                options(i).unit = auroraConfig.defaultForceUnit;
            otherwise
                assert(0,'Error: Unrecognized port type');
        end        
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = portType;
        options(i).port = '';        

        i=i+1;
        options(i).unit = 's';
        options(i).value = nan;
        options(i).printUnit =0;  %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = '';

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 0;
        end


    case 'Stimulus-Train'

        options(5) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',1);

        i=1;
        options(i).unit  = 's';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = portName;

        i=i+1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';
        options(i).port = '';

        i=i+1;
        options(i).unit  = 'ms';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = '';

        i=i+1;
        options(i).unit  = 'pulses';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'pulses';
        options(i).port = '';

        i=i+1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';
        options(i).port = '';

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 1;
        end


    case 'Stimulus-Tetanus'

        options(4) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',1);

        i=1;
        options(i).unit  = 's';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = portName;

        i=i+1;
        options(i).unit  = 'Hz';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'frequency';
        options(i).port = '';

        i=i+1;
        options(i).unit  = 'ms';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = '';

        i=i+1;
        options(i).unit  = 's';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = '';

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 1;
        end



    case 'Stimulus-Twitch'

        options(2) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',1);

        i=1;
        options(i).unit  = 's';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = portName;

        i=i+1;
        options(i).unit  = 'ms';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'time';
        options(i).port = '';

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 1;
        end


    case 'Trigger'

        options(1) = struct('unit','','value',nan,'printUnit',nan,...
                            'isRelative',nan,'type','','port','',...
                            'isParallelCommand',1);

        i=1;
        options(i).unit  = '';
        options(i).value = nan;
        options(i).printUnit  = 0; %Always zero for the 610A
        options(i).isRelative = 0; %Always zero for the 610A
        options(i).type = 'integer';
        options(i).port = portName;

        for i=1:1:length(options)
            options(i).port                 = portName;
            options(i).isParallelCommand    = 1;
        end


    case 'Stop'

        options = [];

    otherwise 
        options = [];
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end
