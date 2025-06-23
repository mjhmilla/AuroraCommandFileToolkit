function [endTime, lineCount] = writePreamble610A(fid,lineCount,auroraConfig)


fprintf(fid,'DMCv5.3 Protocol File\n');
fprintf(fid,'Input Sampling Frequency: %iHz\n',...
        auroraConfig.analogToDigitalSampleRateHz);
fprintf(fid,'Output Sampling Frequency: %iHz\n',...
        auroraConfig.analogToDigitalSampleRateHz);
fprintf(fid,'Protocol Type: Unitized\n');
fprintf(fid,'Wait(s)    Then(action)    On(port)    Units   Parameters\n');

endTime=0;
lineCount=5;


