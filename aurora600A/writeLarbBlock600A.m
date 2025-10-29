function [endTime, lineCount] =writeLarbBlock600A(fid,startTime,...
                           nominalLength,....
                           larbFolder, larbFileName, larbData, ...
                           larbOptions, lineCount, auroraConfig)

offsetLength=0;
if(larbOptions(2).isRelative==1)
    offsetLength = nominalLength;
    larbOptions(2).isRelative = 0;
end

endTime = writeControlFunction600A(...
            fid,...
            startTime,...
            auroraConfig.defaultTimeUnit,...
            'Larb',...
            larbOptions,...
            auroraConfig);

assert(strcmp(larbOptions(3).unit,'Hz'),...
       'Error: default frequency should be Hz');

frequencyHz = larbOptions(3).value;
larbDuration = (length(larbData)/frequencyHz);

switch(auroraConfig.defaultTimeUnit)
    case 's'
        larbDuration = larbDuration*1;
    case 'ms'
        larbDuration = larbDuration*1000;        
    otherwise assert(0,'Error: the default time unit should be ms or s');
end

endTime = endTime + larbDuration;

fidWave = fopen(fullfile(larbFolder,larbFileName),'w');
for i=1:1:length(larbData)
    fprintf(fidWave,'%1.6f\n',(offsetLength+larbData(i,1)));
end
fclose(fidWave);

lineCount = lineCount+1;


