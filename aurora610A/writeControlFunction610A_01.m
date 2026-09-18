function [programMetaData, fcnMetaData]  = ...
            writeControlFunction610A_01(   ...
                fid,...
                waitTimeInS,...
                controlFunctionName,...
                controlFunctionOptions,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile)



fcnMetaData=struct('type',controlFunctionName, ...
                   auroraConfig.labels.time, [nan,nan],...
                   'meta_data',[]);


assert(waitTimeInS >= programMetaData.smallestNextWaitTime, ...
       ['Error: waitTimeInS is not larger than',...
        ' programMetaData.smallestNextWaitTime']);


startTime = programMetaData.nextStartTime;
isActive= isActive610A(startTime+waitTimeInS,programMetaData);

if(~isempty(programMetaData.data))
  here=1;
  assert(startTime-programMetaData.data(end,1) > 0);
end

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

dataColumnsExpected = {'time_ms','length_mm','stimulation_trigger'};
for idxA = 1:1:length(programMetaData.dataColumns)
  assert(strcmp(programMetaData.dataColumns{idxA},...
          dataColumnsExpected{idxA}),...
          'Error: programMetaData.dataColumns differs from expectations');
end

%
% Update programMetaData.data to include the data from the last
% command to the current start. Update the activation interval accordingly.
%
sampleFrequencyHz = auroraConfig.analogToDigitalSampleRateHz;
dt = 1/sampleFrequencyHz;

if(~isempty(programMetaData.data))
  t0 = programMetaData.data(end,1)+dt;
  t1 = startTime-dt;
  nSteps=abs(t1-t0)*sampleFrequencyHz;
  if( nSteps > 2)
    timeSeries_s=[t0:dt:t1]';
    lengthSeries = ones(size(timeSeries_s)).*programMetaData.data(end,2);
    stimSeries = zeros(size(timeSeries_s));
    for idxT=1:1:length(timeSeries_s)
      stimSeries(idxT)=isActive610A(timeSeries_s(idxT),programMetaData);
    end
    programMetaData.data=[programMetaData.data; ...
                          timeSeries_s,lengthSeries,stimSeries];
  end
end

switch controlFunctionName
    case 'Step'
        assert(strcmp(controlFunctionOptions(1).type,'length'),...
               'Error: Expected a length at this option index');

        smallestNextWaitTime  = 0;        
        commandDuration       = 0;

        if(waitTimeInS > auroraConfig.lengthStepResponseTime)
          nextStartTime   = startTime + waitTimeInS+dt;
        else
          nextStartTime   = startTime  ...
                          + auroraConfig.lengthStepResponseTime+dt;        
        end
        
        metaData = struct('is_active',isActive,...
          'channel', controlFunctionOptions(1).port,...
          auroraConfig.labels.length, controlFunctionOptions(1).value);

        fcnMetaData.meta_data=metaData;

        %
        % update time-series record
        %        
        t0= startTime;
        l0= programMetaData.length;
        dataKeyPoints= [t0,l0];

        if(waitTimeInS>0)
          t1= t0+waitTimeInS-auroraConfig.lengthStepResponseTime;
          l1= programMetaData.length;
          dataKeyPoints= [dataKeyPoints;t1,l1];
        end

        t2= dataKeyPoints(end,1)+auroraConfig.lengthStepResponseTime;
        l2= controlFunctionOptions(1).value;
        dataKeyPoints= [dataKeyPoints;t2,l2];
      
        timeSeries_s = [t0:dt:t2]';
        lengthSeries = interp1(dataKeyPoints(:,1),...
                               dataKeyPoints(:,2),...
                               timeSeries_s);
        stimSeries = zeros(size(timeSeries_s));

        for idxT=1:1:length(stimSeries)
          stimSeries(idxT)=isActive610A(timeSeries_s(idxT),...  
                                        programMetaData);
        end

        dataUpd = [timeSeries_s,lengthSeries,stimSeries];

        programMetaData.data = ...
          [programMetaData.data;...
           dataUpd];

        programMetaData.length=controlFunctionOptions(1).value;
        
        

    case 'Ramp'
        assert(strcmp(controlFunctionOptions(1).type,'length'),...
               'Error: Expected a duration at this option index');
        
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
                        + commandDuration + smallestNextWaitTime+dt;

        metaData = struct('is_active',isActive,...
          'channel', controlFunctionOptions(1).port,...
          auroraConfig.labels.length, controlFunctionOptions(1).value,...
          auroraConfig.labels.time, controlFunctionOptions(2).value);

        fcnMetaData.meta_data=metaData;

        %
        % update time-series record
        %
        
        t0= startTime;
        l0= programMetaData.length;
        dataKeyPoints = [t0,l0];

        if(waitTimeInS>0)
          t1= t0+waitTimeInS;
          l1= programMetaData.length;
          dataKeyPoints=[dataKeyPoints; t1,l1];
        end

        t2= dataKeyPoints(end,1)+commandDuration;
        l2= controlFunctionOptions(1).value;
        dataKeyPoints = [dataKeyPoints; t2,l2];

        timeSeries_s = [t0:dt:t2]';
        lengthSeries = interp1(dataKeyPoints(:,1),...
                               dataKeyPoints(:,2),...
                               timeSeries_s);
        stimSeries = zeros(size(timeSeries_s));

        for idxT=1:1:length(stimSeries)
          stimSeries(idxT)=isActive610A(timeSeries_s(idxT),...  
                                        programMetaData);
        end

        dataUpd = [timeSeries_s,lengthSeries,stimSeries];

        programMetaData.data = ...
          [programMetaData.data;...
           dataUpd];

        programMetaData.length=controlFunctionOptions(1).value;
        

    case 'Sine Wave'
        assert(strcmp(controlFunctionOptions(1).type,'frequency'),...
               'Error: Expected a frequency at this option index');

        assert(strcmp(controlFunctionOptions(3).type,'cycles'),...
               'Error: Expected cycles at this option index');



        f = controlFunctionOptions(1).value;
        l = controlFunctionOptions(2).value;
        c = controlFunctionOptions(3).value;
        duration = (1/f)*c;


        if(duration < auroraConfig.lengthStepResponseTime)
            commandDuration     = auroraConfig.lengthStepResponseTime ;
            smallestNextWaitTime= auroraConfig.lengthStepResponseTime;

        else
            commandDuration         = duration;
            smallestNextWaitTime    = 0;

        end

        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime+dt;

        metaData = struct(  'is_active', isActive,...
                             'channel', controlFunctionOptions(1).port,...
          auroraConfig.labels.frequency,controlFunctionOptions(1).value,...
          auroraConfig.labels.amplitude,controlFunctionOptions(2).value,...
          auroraConfig.labels.cycles   ,controlFunctionOptions(3).value);

        fcnMetaData.meta_data=metaData;

        %
        % update time-series record
        %
        
        t0= startTime;
        l0= programMetaData.length;
        dataKeyPoints = [t0,l0];

        if(waitTimeInS>0)
          t1= t0+waitTimeInS;
          l1= programMetaData.length;        
          dataKeyPoints=[dataKeyPoints;t1 l1];

          timeSeriesA_s=[t0:dt:t1]';
          lengthSeriesA_mm=interp1(dataKeyPoints(:,1),...
                                  dataKeyPoints(:,2),...
                                  timeSeriesA_s);
          stimSeriesA=zeros(size(timeSeriesA_s));
          for idxT=1:1:length(stimSeriesA)
            stimSeriesA(idxT)=isActive610A(timeSeriesA_s(idxT),...
                                           programMetaData);
          end

        else
          timeSeriesA_s=t0;
          lengthSeriesA_mm=l0;
          stimSeriesA = isActive610A(t0,programMetaData);
        end

        assert(strcmp(auroraConfig.unitSystem,'mm_mN_s_Hz'),...
               ['Error: Time-series data generation for Sine Wave', ...
                ' only functions for mm_mN_s_Hz']);

        timeSeries_s    = [dt:dt:duration]';
        lengthSeries_mm = l.*sin((f*2*pi).*timeSeries_s) ...
                          + programMetaData.length;
        stimSeries = zeros(size(timeSeries_s));

        timeSeries_s = timeSeries_s + timeSeriesA_s(end);
        for idxT=1:1:length(timeSeries_s)
          stimSeries(idxT)=isActive610A(timeSeries_s(idxT),...
                                        programMetaData);
        end
        
        dataUpd = [timeSeriesA_s, lengthSeriesA_mm, stimSeriesA;
                   timeSeries_s, lengthSeries_mm, stimSeries];

        programMetaData.data = ...
          [programMetaData.data;...
           dataUpd];

        programMetaData.length=lengthSeries_mm(end);


    case 'Sum-Sine Wave'

        assert(strcmp(controlFunctionOptions(5).type,'time'),...
               'Error: Expected time at this option index');


        if(controlFunctionOptions(5).value ...
                < auroraConfig.lengthStepResponseTime)

            commandDuration      = auroraConfig.lengthStepResponseTime;
            smallestNextWaitTime = auroraConfig.lengthStepResponseTime; 

            nextStartTime   = startTime + waitTimeInS ...
                            + smallestNextWaitTime+dt;                                
        else
            commandDuration         = controlFunctionOptions(5).value;
            smallestNextWaitTime    = 0;
            nextStartTime   = startTime + waitTimeInS ...
                            + controlFunctionOptions(5).value+dt;
        end
        
        nextStartTime   = startTime + waitTimeInS ...
                        + commandDuration + smallestNextWaitTime+dt;

        %
        % update time-series record
        %

        
        t0= startTime;
        l0= programMetaData.length;
        dataKeyPoints = [t0,l0];

        if(waitTimeInS>0)
          t1= t0+waitTimeInS;
          l1= programMetaData.length;        
          dataKeyPoints=[dataKeyPoints;t1 l1];

          timeSeriesA_s=[t0:dt:t1]';
          lengthSeriesA_mm=interp(dataKeyPoints(:,1),...
                                  dataKeyPoints(:,2),...
                                  timeSeriesA_s);
          stimSeriesA=zeros(size(timeSeriesA_s));
          for idxT=1:1:length(stimSeriesA)
            stimSeriesA(idxT)=isActive610A(timeSeriesA_s(idxT),...
                                           programMetaData);
          end

        else
          timeSeriesA_s=t0;
          lengthSeriesA_mm=l0;
          stimSeriesA = isActive610A(t0,programMetaData);
        end

        fA = controlFunctionOptions(1).value;
        lA = controlFunctionOptions(2).value;
        fB = controlFunctionOptions(3).value;
        lB = controlFunctionOptions(4).value;        
        duration = controlFunctionOptions(5).value;

        assert(strcmp(auroraConfig.unitSystem,'mm_mN_s_Hz'),...
               ['Error: Time-series data generation for Sine Wave', ...
                ' only functions for mm_mN_s_Hz']);
        
        timeSeries_s    = [dt:dt:duration]';
        lengthSeries_mm = lA.*sine((fA*2*pi).*timeSeries_s) ...
                         +lB.*sine((fB*2*pi).*timeSeries_s) ...
                         + programMetaData.length;        

        stimSeries = zeros(size(timeSeries_s));

        timeSeries_s = timeSeries_s + timeSeriesA_s(end);
        for idxT=1:1:length(timeSeries_s)
          stimSeries(idxT)=isActive610A(timeSeries_s(idxT),...
                                        programMetaData);
        end
        
        dataUpd = [timeSeriesA_s, lengthSeriesA_mm, stimSeriesA;...
                   timeSeries_s, lengthSeries_mm, stimSeries];

        programMetaData.data = ...
          [programMetaData.data;...
           dataUpd];

        programMetaData.length=lengthSeries_mm(end);        

        assert(0,'Delete this once it has been run successfully');
        
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
        nextStartTime   = startTime + waitTimeInS+dt;

        commandDuration = inf;

        %
        % update the time series record
        %
        t0 = startTime;
        l0 = programMetaData.length;
        a0 = isActive610A(t0,programMetaData);
        assert(a0==0);

        dataUpd = [t0,l0,a0];        
        
        if(initialDelay>0)
          t1 = t0+initialDelay;
          l1 = programMetaData.length;
          a1 = isActive610A(t1,programMetaData);
          assert(a1==0);
          
          dataUpd = [dataUpd;...
                     t1,l1,a1];       
        end
        programMetaData.data=[programMetaData.data;...
                              dataUpd];

        trainPeriod=1/trainFrequency;
        programMetaData.Stimulus_time=[];
        
        if(pulsesPerTrain > 0)
          nMaxTrains = auroraConfig.maximumTrialDurationInSeconds ...
                       /trainPeriod;
          for idxA =1:1:nMaxTrains
            startTime=nan;
            endTime=nan;
            if(idxA==1)
              startTime=t1;
            else
              startTime=startTime+trainPeriod;
            end
            endTime=startTime + (pulsesPerTrain/pulseFrequency);
            programMetaData.Stimulus_time = ...
              [programMetaData.Stimulus_time;...
              startTime,endTime];          
          end
        else
          programMetaData.Stimulus_time = [t1,inf];
        end

        assert(0,'Delete this once it has been run successfully');
        
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

        nextStartTime   = startTime + waitTimeInS+dt;

        %
        % update the time series record
        %
        timeStartStim=startTime+waitTimeInS+initialDelay;
        
        t0 = startTime;
        l0 = programMetaData.length;
        a0 = isActive610A(t0,programMetaData);
        assert(a0==0);

        dataUpd = [t0,l0,a0];        
        if(initialDelay>0)
          t1 = t0+initialDelay;
          l1 = programMetaData.length;
          a1 = isActive610A(t1,programMetaData);
          assert(a1==0);
          
          dataUpd = [dataUpd;...
                     t1,l1,a1];
        end
        programMetaData.data=[programMetaData.data;...
                              dataUpd];

        programMetaData.Stimulus_time = ...
          [timeStartStim,(timeStartStim+timeDuration)];


    case 'Stimulus-Twitch'

        smallestNextWaitTime   = 0;

        initialDelay     = controlFunctionOptions(1).value;
        pulseWidth       = controlFunctionOptions(2).value*0.001;

        commandDuration  = initialDelay+pulseWidth;

        nextStartTime   = startTime + waitTimeInS+dt;

        metaData = struct(  'is_active', 1,...
                             'channel', controlFunctionOptions(1).port,...
          auroraConfig.labels.initialDelay,controlFunctionOptions(1).value,...
          auroraConfig.labels.pulseWidth,controlFunctionOptions(2).value);

        fcnMetaData.meta_data=metaData;

        %
        % update the time series record
        %
        t0 = startTime;
        l0 = programMetaData.length;
        a0 = isActive610A(t0,programMetaData);
        assert(a0==0);
        
        dataUpd=[t0,l0,a0];
          
        if(initialDelay>0)
          t1 = t0+initialDelay;
          l1 = programMetaData.length;
          a1 = isActive610A(t1,programMetaData);
          assert(a1==0);

          dataUpd=[dataUpd; t1,l1,a1];
        end

        t2 = dataUpd(end,1)+1e-6;
        l2 = programMetaData.length;
        a2 = 1;
        dataUpd=[dataUpd; t2,l2,a2];
        
        t3 = t2+pulseWidth-2e-6;
        l3 = programMetaData.length;
        a3 = 1;
        dataUpd=[dataUpd; t3,l3,a3];

        t4 = t3+1e-6;
        l4 = programMetaData.length;
        a4 = 0;
        dataUpd=[dataUpd; t4,l4,a4];
              
        programMetaData.data=[programMetaData.data;...
                              dataUpd];
        
        programMetaData.Stimulus_time = [t1,(t1+pulseWidth)];
        assert(0,'Delete this once it has been run successfully');

    case 'Trigger'

        smallestNextWaitTime   = 0;
        commandDuration        = 0; 
        nextStartTime   = startTime + waitTimeInS;

        %
        % update the time series record
        %
        t0 = startTime;
        l0 = programMetaData.length;
        a0 = isActive610A(t0,programMetaData);
        
        dataUpd = [t0,l0,a0];
      
        programMetaData.data=[programMetaData.data;...
                              dataUpd];
        assert(0,'Delete this once it has been run successfully');

    case 'Stop'

        smallestNextWaitTime   = 0;
        commandDuration        = 0; 
        nextStartTime   = startTime + waitTimeInS+dt;

        %
        % update the time series record
        %
        t0 = startTime;
        l0 = programMetaData.length;
        a0 = isActive610A(t0,programMetaData);
        
        dataUpd = [t0,l0,a0];

        assert(t0 < auroraConfig.maximumTrialDurationInSeconds,...
               ['Error: this trial exceeded ',...
               'auroraConfig.maximumTrialDurationInSeconds']);
      
        programMetaData.data=[programMetaData.data;...
                              dataUpd]; 

        programMetaData.Stimulus_time=[];
        

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

fcnMetaData.(auroraConfig.labels.time) = ...
  [programMetaData.controlFunction.startTime,...
   programMetaData.controlFunction.endTime];



%%
% Write the command
%%

waitTimeStr = sprintf('%1.6f',waitTimeInS);


if(~isempty(controlFunctionOptions))
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
                        valueStr = sprintf('%1.2f',controlFunctionOptions(i).value);
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
                if(lengthChange > auroraConfig.maximumLengthChangeInDefaultUnits)
                  here=1;
                end
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
