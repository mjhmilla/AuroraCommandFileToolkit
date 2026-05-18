function success  = generateSequenceFile(protocolFolderPath,settings)

success=0;

protocolDirContents = dir(protocolFolderPath);

fid = fopen(fullfile(protocolFolderPath,settings.sequenceFileName),'w');

fprintf(fid,'DMCv5 Sequence File\n');
fprintf(fid,'Base File:  %s\n',settings.baseFile);
fprintf(fid,'Protocol File\tTimed?\tTimeToWait\tFileMarker\tRepeat\n');

fileCounter=0;
for i=1:1:length(protocolDirContents)
  if(protocolDirContents(i).isdir == 0 )
    if(contains(protocolDirContents(i).name,'.dpf'))
      fileCounter=fileCounter+1;

      fullFilePath = [settings.expProtocolFolderName,...
                      protocolDirContents(i).name];

      fileMarker = num2str(fileCounter);
      if(length(fileMarker)<2)
        fileMarker=['0',fileMarker];
      end
    
      repeats=settings.repeats;
      

      timingTag = '';
      timingValue=0;
      if(settings.isTimed==1)
        timingTag = 'Timed';
        timingValue = settings.delayTime;
      else
        timingTag = 'Manual';
      end
      fprintf(fid,'%s\t%s\t%1.3f\t%s\t%i\t\t\n',...
        fullFilePath,timingTag,timingValue,fileMarker,repeats);
    end
  end
end
fclose(fid);

