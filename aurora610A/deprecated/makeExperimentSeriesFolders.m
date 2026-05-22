function [dateId, dateDir, codeDir, codeLabelDir] = ...
            makeExperimentSeriesFolders(...
                seriesName,...
                projectFolders)

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

dateDir         = fullfile(projectFolders.output_code,[dateId,'_610A']); 
codeDir         = fullfile(projectFolders.output_code,[dateId,'_610A'],seriesName);
codeLabelDir    = fullfile(projectFolders.output_code,[dateId,'_610A'],seriesName,'segmentLabels');


fileFolderList=dir(projectFolders.output_code);

dateDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
            && strcmp(fileFolderList(i).name,[dateId,'_610A']))
        dateDirExists=1;
    end
end

if(dateDirExists==0)
    mkdir(dateDir);
end

codeDirExists = 0;
fileFolderList=dir(dateDir);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
        && strcmp(fileFolderList(i).name,seriesName))
        codeDirExists=1;
    end
end

if(codeDirExists==0)
    mkdir(codeDir);
end

codeLabelDirExists=0;   
fileFolderList=dir(codeDir);
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir ...
        && strcmp(fileFolderList(i).name,'segmentLabels'))
        codeLabelDirExists=1;
    end
end
if(codeLabelDirExists==0)
    mkdir(codeLabelDir);
end
