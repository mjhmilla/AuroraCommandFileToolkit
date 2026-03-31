function [endTime, lineCount] = writePreamble600A(fid,lineCount,auroraConfig)

endTime = 0;

analogToDigitalSampleRateHz=...
    auroraConfig.analogToDigitalSampleRateHz;

numberOfEmptyCommandsPrepended=...
    auroraConfig.numberOfEmptyCommandsPrepended;



fprintf(fid,'ASI 600A Test Protocol File\n');

%%
% date
%%
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
lineCount = lineCount+1;

fprintf(fid,'A/D Sampling Rate: %i Hz\n', analogToDigitalSampleRateHz);
lineCount = lineCount+1;

fprintf(fid,'Comment: %s\n',auroraConfig.comment);
lineCount = lineCount+1;

fprintf(fid,'Minimum Length: %1.3f (Lo)\n',...
            auroraConfig.minimumNormalizedLength);
lineCount = lineCount+1;

fprintf(fid,'Maximum Length: %1.3f (Lo)\n',...
            auroraConfig.maximumNormalizedLength);
lineCount = lineCount+1;

fprintf(fid,'PD Deadband:    %1.6f mN\n',...
            auroraConfig.pdDeadBand);
lineCount = lineCount+1;


for i=1:1:numberOfEmptyCommandsPrepended
    idStr = int2str(i);
    while(length(idStr)<2)
        idStr=['0',idStr];
    end
    fprintf(fid,['Stimulus %s: 0.5 ms 200.000 Hz 10.0 ms ',...
                 '50.000 Hz 0.500 s\n'],idStr);
    lineCount = lineCount+1;    
end

%%
% Commands
%%
fprintf(fid,'Time (ms)\tControl Function\tOptions \n');
fprintf(fid,'%9.1f\tData-Enable\t\t\n',0.0);
lineCount = lineCount+2;

success=1;

