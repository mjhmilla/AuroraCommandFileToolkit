function programMetaData = writePreamble610A(fid,auroraConfig,...
                                                programMetaData)


fprintf(fid,'DMCv5.3 Protocol File\n');
fprintf(fid,'Input Sampling Frequency: %iHz\n',...
        auroraConfig.analogToDigitalSampleRateHz);
fprintf(fid,'Output Sampling Frequency: %iHz\n',...
        auroraConfig.analogToDigitalSampleRateHz);
fprintf(fid,'Protocol Type: Unitized\n');
fprintf(fid,'Wait(s)    Then(action)    On(port)    Units   Parameters\n');


programMetaData.startTime                   = 0;
programMetaData.nextStartTime               = 0;
programMetaData.smallestNextWaitTime        = 0;
programMetaData.lineCount                   = 5;


