function endTime = writePreamble600A(fid,auroraConfig)

endTime = auroraConfig.postCommandPauseTimeMS;

analogToDigitalSampleRateHz=...
    auroraConfig.analogToDigitalSampleRateHz;

numberOfEmptyCommandsPrepended=...
    auroraConfig.numberOfEmptyCommandsPrepended;



fprintf(fid,'ASI 600A Test Protocol File');

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

success=1;

