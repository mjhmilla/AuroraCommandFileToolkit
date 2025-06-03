function [timeAurora, lengthAurora] ...
    = writeAuroraCommandFileFromStruct(...
       commandStruct,...
       auroraConfig,...
       fullFilePath)
%%
% @author M.Millard
% @date May 2025
%
% A function to take a time series of length changes and turn it into
% an equivalent command file to control an Aurora muscle servo testing 
% machine. 
%
% Note: This function currently assumes that time is specified in seconds
%
% @param commandStruct
%   A struct with fields:
%
%   time: 
%       A time vector of samples that is monotonically increasing in units 
%       of seconds. The timeVector can be longer than maximumNumberOfCommands
%       since zero-length-change entries are grouped. 
%
%   lengthChange: 
%       A vector of desired length changes measured in normalized length (Lo). 
%       This vector must have the same length as time vector.
%
% @param auroraConfig
%   A struct that contains the following fields:
%
% analogToDigitalSampleRateHz: 
%   The desired sampling rate in Hz of the ADC. The Aurora machine will not
%   accept any sampling rate, for example 1024 caused Aurora's compiler
%   to crash. Thus far I've been using 5000 Hz which seems to work without
%   any problem.
%
% postMovementPauseTimeInSeconds: 
%   The amount of time to pause after making a ramp. According to the 
%   this value should be at least 0.0001s (0.1 ms).
%
% numberOfEmptyCommandsPrepended: 
%   The Aurora machine seems to ignore commands prior to line 18. To ensure
%   that the position commands don't appear until line 18 we recommend 
%   setting numberOfEmptyCommandsPrepended to 10 to pad header with 
%   filler entries.
%
% maximumNumberOfCommands: 
%   The maximum number of entries into the 
%   Aurora file. This should not exceed 950: at 1000 the Aurora program 
%   crashes and the computer actually has to be restarted. The value
%   in this field is used to check that the final Aurora command file is
%   valid.
%
% bathChangeTime
%    The amount of time allocated to change the baths. We recommend at
%    least 0.5s.

% comment
%   A text comment that goes into the header. For example 
%   'EDL, h: 0.091 w: 0.079';
%
% minimumNormalizedLength
%   The minimum normalized length which is specified in a line in the 
%   header. For example: 0.05;
%
% maximumNormalizedLength
%   The maximum normalized length which is specified in a line in the 
%   header. For example: 1.6;
%
% @param fullFilePath: 
%   The name of the file to export
%
% @return timeVectorExpectedMeasurement: 
%   The time series of measurements from the analog-to-digital 
%   converter (ADC). 
%
% @return signalExpectedMeasurement: 
%   The expected time series of lengths measured from the ADC. This signal
%   will always differ from the commanded length changes, to some degree,
%   because the Aurora's length changes are only accurate to 4 decimal
%   points. There is always some rounding error.
%%

analogToDigitalSampleRateHz=...
    auroraConfig.analogToDigitalSampleRateHz;

postMovementPauseTimeInSeconds=...
    auroraConfig.postMovementPauseTimeInSeconds;

numberOfEmptyCommandsPrepended=...
    auroraConfig.numberOfEmptyCommandsPrepended;

maximumNumberOfCommands=...
    auroraConfig.maximumNumberOfCommands;


assert(length(commandStruct.time)==length(commandStruct.signal), ...
    'commandStruct.time and commandStruct.signal must have the same length');

assert(isempty(fullFilePath)==0,'fullFilePath cannot be empty');

assert( min(diff(commandStruct.time))*1000 > 0.1, ...
    ['The Aurora machine needs at least 0.1ms to execute a step,',...
     ' and probably more like 1ms']);

% Constants
dtPause   = postMovementPauseTimeInSeconds;
dtPauseMs = postMovementPauseTimeInSeconds*1000;

%%
% Write the header
%%
fid =fopen(fullFilePath,'w');
fprintf(fid,'ASI 600A Test Protocol File\n');

% date
t=datetime();
monthNameCell   = month(t,'shortname');
monthName       = monthNameCell{1};

dayNameCell = day(t,'shortname');
dayName     = dayNameCell{1};

dayNumber = day(t);

hourNumber   = hour(t);
minuteNumber = minute(t);
secondNumber = second(t);

hourStr   = num2str(hourNumber);
minuteStr = num2str(minuteNumber);
secondStr = num2str(round(secondNumber));
if(length(hourStr)<2)
    hourStr =['0',hourStr];
end
if(length(minuteStr)<2)
    minuteStr =['0',minuteStr];
end
if(length(secondStr)<2)
    secondStr =['0',secondStr];
end

timeName = [hourStr,':',minuteStr,':',secondStr];

yearNumber = year(t);

fprintf(fid,'Created: %s %s %i %s %i\n',dayName,monthName,...
    dayNumber, timeName,yearNumber);

fprintf(fid,'A/D Sampling Rate: %i Hz\n', analogToDigitalSampleRateHz);

fprintf(fid,'Comment: %s\n',auroraConfig.comment);

fprintf(fid,'Minimum Length: %1.3f (Lo)\n',...
            auroraConfig.minimumNormalizedLength);

fprintf(fid,'Maximum Length: %1.3f (Lo)\n',...
            auroraConfig.maximumNormalizedLength);

fprintf(fid,'PD Deadband:    %1.6f mN\n',...
            auroraConfig.pdDeadBand);


for i=1:1:numberOfEmptyCommandsPrepended
    idStr = int2str(i);
    while(length(idStr)<2)
        idStr=['0',idStr];
    end
    fprintf(fid,['Stimulus %s: 0.5 ms 200.000 Hz 10.0 ms ',...
                 '50.000 Hz 0.500 s\n'],idStr);
end

%%
% Commands
%%
fprintf(fid,'Time (ms)\tControl Function\tOptions \n');
fprintf(fid,'%9.1f\tData-Enable\t\t\n',0.0);

commandCounter = 1;

timeOffset = 0;
if(commandStruct.active==1)
    timeOffset = timeOffset ...
               + auroraConfig.bath.changeTime*1000; 
    fprintf(fid,'%9.1f\tBath\t\t%i 0 ms\n',timeOffset,...
                 auroraConfig.bath.preActivation);
    timeOffset = timeOffset ...
        + auroraConfig.bath.preActivationDuration*1000 ...
        + auroraConfig.bath.changeTime*1000;
    fprintf(fid,'%9.1f\tBath\t\t%i 0 ms\n',timeOffset,...
            auroraConfig.bath.active);
    timeOffset = timeOffset + auroraConfig.bath.changeTime*1000;
    commandCounter = commandCounter+2;
end



i       = 1;
idxEnd  = length(commandStruct.time);

timeInMs        = commandStruct.time(i,1)*1000 + timeOffset;
timeAurora      = zeros(size(commandStruct.signal,1)*2,1);
lengthAurora    = zeros(size(commandStruct.signal,1)*2,1);
idxAurora=1;

timeAurora(1,1)   = commandStruct.time(1,1) + timeOffset/1000;
lengthAurora(1,1) = commandStruct.signal(1,1);

dlErrMax=0;

while i < (idxEnd)

    dtB = round( (commandStruct.time(i+1)-commandStruct.time(i))*1000, 1);
    dtA = dtB-dtPauseMs;

    dtAStr = sprintf('%1.1f',dtA);
    dtBStr = sprintf('%1.1f',dtB);

    dtA = str2double(dtAStr);
    dtB = str2double(dtBStr);

    dtStr = sprintf('%1.1f',dtA);


    %Trim off all trailing zeros: Aurora's working pro files have no
    %trailing zeroes
    while strcmp(dtStr(end),'0')==1 && length(dtStr) > 1
        lastIndex = length(dtStr);
        dtStr = dtStr(1:(lastIndex-1));
    end
    if(strcmp(dtStr(end),'.')==1)
        dtStr = dtStr(1:(end-1));
    end
    
    dlFull = commandStruct.signal(i+1)-lengthAurora(idxAurora,1);

    dlStr = sprintf('%1.4f',dlFull);

    flag_zero=0;
    if(contains(dlStr,'0.0000'))
        dlStr = '0.0';
        flag_zero=1;
    end

    dl    = str2double(dlStr);
    dlErr = (dl-dlFull);
    if(dlErr>dlErrMax)
        dlErrMax=dlFull;
    end

    signStr = '+';
    if(dl < 0 && flag_zero==0)
        signStr ='';
    end      

    %Trim off all trailing zeros: Aurora's working pro files have no
    %trailing zeroes
    while strcmp(dlStr(end),'0')==1 && flag_zero==0
        lastIndex = length(dlStr);
        dlStr = dlStr(1:(lastIndex-1));
    end
    if(strcmp(dlStr(end),'.')==1)
        dlStr = [dlStr,'0'];
    end
    assert( (contains(dlStr,'-') && length(dlStr) > 1) ...
          || length(dlStr) >= 1, 'Lenth change contains no number');

    if contains(signStr,'+')==1 && contains(dlStr,'-')==1
        here=1;
    end

    timeInMsStr = sprintf('%9.1f',timeInMs);

    if(abs(timeInMs-54016.9)<1)
        here=1;
    end

    if(abs(dlFull)>1e-6)
        unitStr = 'Lo';
        if(strcmp(commandStruct.command{i},'Force-Ramp')==1)
            unitStr = 'Fmax';
        end

        fprintf(fid,'%s\t%s\t\t%s%s %s  %s ms\n', ...
            timeInMsStr, commandStruct.command{i}, signStr, dlStr, unitStr, dtStr);
        commandCounter = commandCounter+1;
    else
        here=1;
    end
    %Do the step
    idxAurora=idxAurora+1;
    timeAurora(idxAurora,1)   = timeAurora(idxAurora-1,1)+dtA/1000;
    lengthAurora(idxAurora,1) = lengthAurora(idxAurora-1,1)+dl;

    %The Aurora machine execute a ramp change and then needs 0.1 ms of 
    %extra time before executing the next step.
    idxAurora=idxAurora+1;
    timeAurora(idxAurora,1)   = timeAurora(idxAurora-1,1)+dtPause;
    lengthAurora(idxAurora,1) = lengthAurora(idxAurora-1,1);
    
    timeInMs = timeInMs + dtB;
    i=i+1;

    
end

if(commandStruct.active==1)
    timeInMs = timeInMs + auroraConfig.bath.changeTime*1000; 
    fprintf(fid,'%9.1f\tBath\t\t%i 0 ms\n',timeInMs,...
            auroraConfig.bath.passive);
    commandCounter = commandCounter+2;
    timeInMs = timeInMs + auroraConfig.bath.changeTime*1000;
end

%Write the closing lines
timeInMs = timeInMs +dtPauseMs;

fprintf(fid,'%9.1f\tData-Disable\t\t\n',timeInMs);
fprintf(fid,'%9.1f\tStop\t\t\n',(timeInMs+dtPauseMs));
commandCounter = commandCounter+2;
fclose(fid);

assert(commandCounter <= maximumNumberOfCommands, ...
   sprintf('Entries (%i) exceeds maximum allowed (%i)',idxAurora, maximumNumberOfCommands));

fprintf('writeAuroraCommandFile:\n\t%i of %i command entries used\n',...
    commandCounter, maximumNumberOfCommands);


%%
% Generate an estimate of the measured signal
%%

timeAurora      = timeAurora(1:idxAurora,1);
lengthAurora    = lengthAurora(1:idxAurora,1);

%Return the super sampled signal, which due to the small processing delays
%between the linear moves is slightly different than the desired signal

% dt = 1/analogToDigitalSampleRateHz;
% 
% timeVectorExpectedMeasurement = ...
%     ([dt:dt:1]') .* (max(timeAurora)-min(timeAurora))...
%      + min(timeAurora);
% 
% signalExpectedMeasurement = interp1(commandStruct.time,...
%                                     commandStruct.signal, ...
%                             timeVectorExpectedMeasurement,'linear');


success=1;