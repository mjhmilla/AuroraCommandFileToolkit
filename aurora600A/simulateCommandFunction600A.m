function [simulatedSignals,isValid,msg]= ...
            simulateCommandFunction600A(startTime,...
                                        controlFunctionName,...
                                        options,...
                                        simulatedSignals,...
                                        auroraConfig)

disp('Warning: this is not complete. I have to work on other things right now.');

assert(strcmp(timeUnit,'ms'),...
        'Error: timeUnit and startTime must be in ms');


assert(simulatedSignals.index >= 2,'Error: the first entry must contain the starting length and force');

switch controlFunctionName
    case 'Length-Step'

        assert(strcmp(auroraConfig.defaultLengthUnit, options(1).unit),...
               'Error: the command units and the default units must match');

        i0 = simulatedSignals.index;
        i1 = simulatedSignals.index+1;

        if(i > (length(simulatedSignals.length)+2))
            simulatedSignals = ...
                resizeSimulatedCommandFunctionStruct(simulatedSignals);
        end

        dl = 0;
        l1 = 0;
        if(commandOption(i0).isRelative==1)
            dl = option(1).value;
            l0 = simulatedSignals.length(i0-1);
            l1 = l0 + dl;            
        else
            l0 = simulatedSignals.length(i0-1);
            l1 = option(1).value;
            dl = l1-l0;
        end

        dt = abs(dl / auroraConfig.maximumRampSpeedInDefaultUnits);

        simulatedSignals.time(i0)=startTime;
        simulatedSignals.time(i1)= dt + simulatedSignals.time(i);

        simulatedSignals.lengthAbs(i0)=l0;
        simulatedSignals.lengthAbs(i1)=l1;

        simulatedSignals.forceAbs(i0)=nan;
        simulatedSignals.forceAbs(i1)=nan;

        simulatedSignals.commandId(i0)=getCommandFunctionId600A(controlFunctionName);
        simulatedSignals.commandId(i1)=getCommandFunctionId600A(controlFunctionName);

        simulatedSignals.index=i1+1;



    case 'Length-Ramp'

        assert(strcmp(auroraConfig.defaultLengthUnit, options(1).unit),...
               'Error: the command units and the default units must match');
        assert(strcmp(auroraConfig.defaultTimeUnit, options(2).unit),...
               'Error: the command units and the default units must match');

        i0 = simulatedSignals.index;
        i1 = simulatedSignals.index+1;

        if(i > (length(simulatedSignals.length)+2))
            simulatedSignals = ...
                resizeSimulatedCommandFunctionStruct(simulatedSignals);
        end

        dl = 0;
        l1 = 0;
        if(commandOption(i0).isRelative==1)
            dl = option(1).value;
            l0 = simulatedSignals.length(i0-1);
            l1 = l0 + dl;            
        else
            l0 = simulatedSignals.length(i0-1);
            l1 = option(1).value;
            dl = l1-l0;
        end

        dt = option(2).value;

        simulatedSignals.time(i0)=startTime;
        simulatedSignals.time(i1)= dt + simulatedSignals.time(i);

        simulatedSignals.lengthAbs(i0)=l0;
        simulatedSignals.lengthAbs(i1)=l1;

        simulatedSignals.forceAbs(i0)=nan;
        simulatedSignals.forceAbs(i1)=nan;

        simulatedSignals.commandId(i0)=getCommandFunctionId600A(controlFunctionName);
        simulatedSignals.commandId(i1)=getCommandFunctionId600A(controlFunctionName);

        simulatedSignals.index=i1+1;        


    case 'Length-Square'

        assert(strcmp(auroraConfig.defaultFrequencyUnit, options(1).unit),...
               'Error: the command units and the default units must match');
        assert(strcmp(auroraConfig.defaultLengthUnit, options(2).unit),...
               'Error: the command units and the default units must match');
        assert(strcmp(auroraConfig.defaultTimeUnit, options(3).unit),...
               'Error: the command units and the default units must match');


        %The Aurora controller will do fractional cycles, so this is
        %an approximation
        n = round(options(3).value * options(1).value);

        if( abs(n - (options(3).value * options(1).value)) > 1e-6)
            disp(['Warning: fractional Length-Square cycle is simulated as ',...
                  'a whole cycle']);
        end

        if(i > (length(simulatedSignals.length)+n*5))
            simulatedSignals = ...
                resizeSimulatedCommandFunctionStruct(simulatedSignals);
        end        

        for i=1:1:n            

            i0 = simulatedSignals.index;
            i1 = i0+1;
            i2 = i1+1;
            i3 = i2+1;
            i4 = i3+1;

            dl = 0;
            l0 = 0;
            if(commandOption(i0).isRelative==1)
                dl = option(2).value;
                l0 = simulatedSignals.length(i0-1);           
            else
                l0 = simulatedSignals.length(i0-1);
                l1 = option(2).value;
                dl = l1-l0;
            end            

            dtA = abs(dl / auroraConfig.maximumRampSpeedInDefaultUnits);
            dtB = abs(2*dl / auroraConfig.maximumRampSpeedInDefaultUnits);
            
            dtWave = 1/(options(1).value*auroraConfig.scaleFrequencyUnit);

            simulatedSignals.time(i0)= dtA      + startTime;
            simulatedSignals.time(i1)= dtWave   + simulatedSignals.time(i1);
            simulatedSignals.time(i2)= dtB      + simulatedSignals.time(i2);
            simulatedSignals.time(i3)= dtWave   + simulatedSignals.time(i3);
            simulatedSignals.time(i4)= dtA      + simulatedSignals.time(i4);


            simulatedSignals.lengthAbs(i0)=l0+dl;
            simulatedSignals.lengthAbs(i1)=l0+dl;
            simulatedSignals.lengthAbs(i2)=l0-dl;
            simulatedSignals.lengthAbs(i3)=l0-dl;
            simulatedSignals.lengthAbs(i4)=l0+dl;
            

            simulatedSignals.forceAbs(i0)=nan;
            simulatedSignals.forceAbs(i1)=nan;
            simulatedSignals.forceAbs(i2)=nan;
            simulatedSignals.forceAbs(i3)=nan;
            simulatedSignals.forceAbs(i4)=nan;


            simulatedSignals.commandId(i0)=getCommandFunctionId600A(controlFunctionName);
            simulatedSignals.commandId(i1)=getCommandFunctionId600A(controlFunctionName);
            simulatedSignals.commandId(i2)=getCommandFunctionId600A(controlFunctionName);
            simulatedSignals.commandId(i3)=getCommandFunctionId600A(controlFunctionName);
            simulatedSignals.commandId(i4)=getCommandFunctionId600A(controlFunctionName);

            simulatedSignals.index=i4+1;        


        end





    case 'Length-Sine'


    case 'Length-Sweep'

    case 'Length-Sample'

    case 'Length-Hold'

    case 'Read-Larb'


    case 'Write-Larb'


    case 'Send-Larb'

    case 'Length-Arb'

    case 'Force-Step'

    case 'Force-Ramp'
     

    case 'Force-Square'
 

    case 'Force-Sine'

    case 'Force-Sweep'
  

    case 'Force-Sample'


    case 'Force-Hold'
              

    case 'Force-Clamp'


    case 'SL-Step'


    case 'SL-Ramp'


    case 'SL-Sample'


    case 'SL-Hold'


    case 'SL-Trigger'
      

    case 'SL-Track'

   

    case 'Stimulus'


    case 'Trigger1'


    case 'Trigger2'
 

    case 'Data-Enable'

    case 'Data-Disable'


    case 'Data-Burst'


    case 'Bath'


    case 'Repeat'

    case 'Stop'

    otherwise 
        isValid = 0;
        msg = ['Error ', commandFunctionName,...
              ' is not in the list of valid commands'];
 end
