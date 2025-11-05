function [endTime, lineCount] = ...
    writeLarbBlock600A( fid,...
                        startTime,...
                        nominalLength,....
                        larbFolder, ...
                        larbFileName, ...
                        larbData, ...
                        larbOptions, ...
                        larbMetaData,...                        
                        lineCount, ...
                        auroraConfig)

offsetLength=0;
if(larbOptions(2).isRelative==1)
    offsetLength = nominalLength;
    larbOptions(2).isRelative = 0;
end

endTime = writeControlFunction600A(...
            fid,...
            startTime,...
            auroraConfig.defaultTimeUnit,...
            'Length-Arb',...
            larbOptions,...
            auroraConfig);

assert(strcmp(larbOptions(2).unit,'Hz'),...
       'Error: default frequency should be Hz');

frequencyHz = larbOptions(2).value;
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

larbMetaFileName = larbFileName;
idx=strfind(larbMetaFileName,'.');
larbMetaFileName = [larbMetaFileName(1,1:(idx-1)),...
                '_metadata',...
                larbMetaFileName(1,(idx:end))];

fidWaveMeta = fopen(fullfile(larbFolder,larbMetaFileName),'w');

nMetaData = length(larbMetaData.amplitude);
metaFields = fields(larbMetaData);

for i=1:1:length(metaFields)
    metaStr = metaFields{i};
    typeStr = '%i';    
    if(strcmp(metaFields{i},'amplitude'))
        typeStr = '%1.6f';
    end

    metaDataVector = larbMetaData.(metaFields{i});
    for j=1:1:nMetaData
        metaStr = sprintf(['%s,',typeStr],metaStr, metaDataVector(1,j));
    end

    fprintf(fidWaveMeta,'%s\n',metaStr);
end

% fprintf(fidWaveMeta,'amplitude, %1.6f\n',larbMetaData.amplitude);
% fprintf(fidWaveMeta,'bandwidthHz, %1.6f\n',larbMetaData.bandwidth);
% fprintf(fidWaveMeta,'frequencyHz, %i\n',larbMetaData.frequencyHz);
% fprintf(fidWaveMeta,'points, %i\n',larbMetaData.points);
fclose(fidWaveMeta);

lineCount = lineCount+1;


