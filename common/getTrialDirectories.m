function [codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders, appendIdName)

[y,m,d] = datevec(date());

yStr = int2str(y);
mStr = int2str(m);
dStr = int2str(d);
if(length(mStr)<2)
    mStr = ['0',mStr];
end
if(length(dStr)<2)
    dStr = ['0',dStr];
end
dateId = [yStr,mStr,dStr];

codeDir         = fullfile(projectFolders.output_code,[dateId,appendIdName,'_600A']);
codeLabelDir    = fullfile(projectFolders.output_code,[dateId,appendIdName,'_600A'],'segmentLabels');

fileFolderList=dir(projectFolders.output_code);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,[dateId,appendIdName,'_600A']))
        codeDirExists=1;
    end
end

if(codeDirExists==1)
    codeLabelDirExists=0;   
    fileFolderList=dir(codeDir);
    for i=1:1:length(fileFolderList)
        if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,'segmentLabels'))
            codeLabelDirExists=1;
        end
    end
    if(codeLabelDirExists==0)
        mkdir(codeLabelDir);
    end
else
    mkdir(codeDir);
    mkdir(codeLabelDir);    
end