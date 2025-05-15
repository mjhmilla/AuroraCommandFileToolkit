function [timeVectorExpectedMeasurement, signalExpectedMeasurement] ...
    = writeAuroraCommandFile(...
       timeVector,...
       displacementVector,...
       analogToDigitalSampleRate,...
       postRampPauseTime,...
       numberOfEmptyCommandsPrepended,...
       maximumNumberOfEntries,  ...
       fileName)
%%
% @author M.Millard
% @date May 2022
%
% A function to take a time series of length changes and turn it into
% an equivalent command file to control an Aurora muscle puller. Zero
% length change entries are grouped together to reduce the number of 
% commands to a minimum, except for the first number of entries 
% specified by numberOfEmptyCommandsPrepended: the Aurora machine seems to
% ignore the first 9/10 entries entirely and start near the 19th entry.
% It is important to both pad the displacementVector with zeros for the
% first numberOfEmptyCommandsPrepended (approx 20) and to set 
% numberOfEmptyCommandsPrepended (approx 20) so that these first padding
% entries are not collapsed into a single entry.
%
% @param timeVector: 
%   A time vector of samples that is monotonically increasing in units 
%   of seconds. The timeVector can be longer than maximumNumberOfEntries
%   since zero-length-change entries are grouped. 
%
% @param displacementVector: 
%   A vector of desired length changes measured in normalized length (Lo). 
%   This vector must have the same length as time vector.
%
% @param analogToDigitalSampleRate: 
%   The desired sampling rate in Hz of the ADC. The Aurora machine will not
%   accept any sampling rate, for example 1024 caused Aurora's compiler
%   to crash. Thus far I've been using 5000 Hz which seems to work without
%   any problem.
%
% @param postRampPauseTime: 
%   The amount of time to pause after making a ramp. According to the 
%   this value should be at least 0.0001s (0.1 ms).
%
% @param numberOfEmptyCommandsPrepended: 
%   This number of entries in the timeVector and displacementVector are
%   written as they appear in the data: these entries are not grouped. The
%   intention of this feature is to allow the signal designer to make a
%   set of padding commands of zero-moves that the Aurora machine can 
%   ignore/throw out without affecting the signal.
%
% @param maximumNumberOfEntries: 
%   The maximum number of entries into the 
%   Aurora file. This should not exceed 950: at 1000 the Aurora program 
%   crashes and the computer actually has to be restarted. The value
%   in this field is used to check that the final Aurora command file is
%   valid.
%
% @param fileName: 
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

assert(length(timeVector)==length(displacementVector), ...
    'timeVector and displacementVector must have the same length');





assert(isempty(fileName)==0,'fileName cannot be empty');

assert( min(diff(timeVector))*1000 > 0.1, ...
    ['The Aurora machine needs at least 0.1ms to execute a step,',...
     ' and probably more like 1ms']);

fid =fopen(fileName,'w');
fprintf(fid,'ASI 600A Test Protocol File\n');

% Constants
%dtPause = 0.0001; %Additional pause time required by the Aurora machine
%dtPauseMs = dtPause*1000;
dtPause   = postRampPauseTime;
dtPauseMs = postRampPauseTime*1000;

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

fprintf(fid,'A/D Sampling Rate: %i Hz\n', analogToDigitalSampleRate);
%Just putting dummy numbers in here
fprintf(fid,'Comment: EDL, h: 0.091 w:  0.079\n');
fprintf(fid,'Minimum Length: 0.050 (Lo)\n');
fprintf(fid,'Maximum Length: 1.700 (Lo)\n');
fprintf(fid,'PD Deadband:    0.000000 mN\n');

%This line is not functional, may not be needed, but is here for now. 
fprintf(fid,'Stimulus 01: 0.5 ms 200.000 Hz 10.0 ms 50.000 Hz 0.500 s\n');

fprintf(fid,'Time (ms)\tControl Function\tOptions \n');

fprintf(fid,'%9.1f\tData-Enable\t\t\n',0.0);
commandCounter = 1;




idxStart= 1;
idxEnd  = length(timeVector)-1;

timeInMs        = timeVector(idxStart,1)*1000;
timeAurora      = zeros(size(displacementVector,1)*2,1);
lengthAurora    = zeros(size(displacementVector,1)*2,1);
idxAurora=1;

timeAurora(1,1)   = timeVector(1,1);
lengthAurora(1,1) = displacementVector(1,1);


dlErrMax=0;

i=idxStart;
%for i=(idxStart):1:(idxEnd-1)
while i < (idxEnd-1)



    dtB = round( (timeVector(i+1)-timeVector(i))*1000, 1);
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
        dtStr = dtStr(1);
    end
    
    dlFull = displacementVector(i+1)-lengthAurora(idxAurora,1);





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
        signStr =' ';
    end      

    %Trim off all trailing zeros: Aurora's working pro files have no
    %trailing zeroes
    while strcmp(dlStr(end),'0')==1 && flag_zero==0
        lastIndex = length(dlStr);
        dlStr = dlStr(1:(lastIndex-1));
    end
    if(strcmp(dlStr(end),'.')==1)
        %lastIndex = length(dlStr);
        %dlStr = dlStr(1:(lastIndex-1));
        dlStr = [dlStr,'0'];
    end
    assert( (contains(dlStr,'-') && length(dlStr) > 1) ...
          || length(dlStr) >= 1, 'Lenth change contains no number');

    if contains(signStr,'+')==1 && contains(dlStr,'-')==1
        here=1;
    end

    timeInMsStr = sprintf('%9.1f',timeInMs);

    fprintf(fid,'%s\tLength-Ramp\t\t%s%s Lo  %s ms\n', ...
        timeInMsStr, signStr, dlStr, dtStr);
    commandCounter = commandCounter+1;

    %Do the step
    idxAurora=idxAurora+1;
    timeAurora(idxAurora,1)   = timeAurora(idxAurora-1,1)+dtA/1000;
    lengthAurora(idxAurora,1) = lengthAurora(idxAurora-1,1)+dl;

    %The Aurora machine execute a ramp change and then needs 0.1 ms of 
    %extra time before executing the next step.
    idxAurora=idxAurora+1;
    timeAurora(idxAurora,1)   = timeAurora(idxAurora-1,1)+dtPause;
    lengthAurora(idxAurora,1) = lengthAurora(idxAurora-1,1);

    %Check to see if there is a zero block that can be lumped together
    idxZeroBlockStart = i+1;
    idxZeroBlockEnd = idxZeroBlockStart+1;
    dlNext = round(displacementVector(idxZeroBlockEnd)...
             -displacementVector(idxZeroBlockStart),4);
    tol  = sqrt(eps);

    %Lump blocks of zero length changes together if we have passed the
    %first block of empty commands
    if(abs(dlNext) < tol && i > numberOfEmptyCommandsPrepended )
        while abs(dlNext)<tol && idxZeroBlockEnd < (idxEnd-1)
            idxZeroBlockEnd = idxZeroBlockEnd+1;
            dlNext = round((displacementVector(idxZeroBlockEnd)...
                     -displacementVector(idxZeroBlockStart)),4);
        end
        idxZeroBlockEnd = idxZeroBlockEnd-1;        
        zeroBlockTime = round( (timeVector(idxZeroBlockEnd)-timeVector(idxZeroBlockStart))*1000, 1);
        i=i+(idxZeroBlockEnd-idxZeroBlockStart)+1;

        timeInMs = timeInMs + dtB + zeroBlockTime;
        timeAurora(idxAurora,1)=...
            timeAurora(idxAurora-1,1)+dtPause+(timeVector(idxZeroBlockEnd)-timeVector(idxZeroBlockStart));
        here=1;
    else
        timeInMs = timeInMs + dtB;
        i=i+1;
    end
    
end




timeAurora      = timeAurora(1:idxAurora,1);
lengthAurora    = lengthAurora(1:idxAurora,1);


%Write the closing lines

dt = timeVector(end,1)-timeAurora(end,1);
timeInMs = timeInMs + dt*1000 +dtPauseMs;

fprintf(fid,'%9.1f\tData-Disable\t\t\n',timeInMs);
fprintf(fid,'%9.1f\tStop\t\t\n',(timeInMs+dtPauseMs));
commandCounter = commandCounter+2;
fclose(fid);

assert(commandCounter <= maximumNumberOfEntries, ...
   sprintf('Entries (%i) exceeds maximum allowed (%i)',idxAurora, maximumNumberOfEntries));

fprintf('writeAuroraCommandFile:\n\t%i of %i command entries used\n',...
    commandCounter, maximumNumberOfEntries);


%Return the super sampled signal, which due to the small processing delays
%between the linear moves is slightly different than the desired signal

dt = 1/analogToDigitalSampleRate;

timeVectorExpectedMeasurement = ...
    ([dt:dt:1]') .* (max(timeAurora)-min(timeAurora))...
     + min(timeAurora);

signalExpectedMeasurement = interp1(timeAurora, lengthAurora, ...
                            timeVectorExpectedMeasurement,'linear');


success=1;