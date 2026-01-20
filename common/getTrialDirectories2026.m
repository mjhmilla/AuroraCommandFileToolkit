function [codeDir, codeProtocolDir, codeLabelDir,dateId] = ...
    getTrialDirectories2026(projectFolders, appendIdName, ...
    settingsExperiment)

if(~isempty(settingsExperiment))
    y = settingsExperiment.date.y;
    m = settingsExperiment.date.m;
    d = settingsExperiment.date.d;

else
    [y,m,d] = datevec(date());
end

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

codeFolderName = [dateId,appendIdName,'_600A'];
if(~isempty(settingsExperiment))
    if(~isempty(settingsExperiment.folderName))
        codeFolderName = settingsExperiment.folderName;
    end
end

codeDir         =...
    fullfile(projectFolders.output_code,codeFolderName);
codeProtocolDir    = ...
    fullfile(projectFolders.output_code,codeFolderName,...
    'protocols');
codeLabelDir    = ...
    fullfile(projectFolders.output_code,codeFolderName,...
    'segmentLabels');
dataDir    = ...
    fullfile(projectFolders.output_code,codeFolderName,...
    'data');

fileFolderList=dir(projectFolders.output_code);
codeDirExists=0;

for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,codeFolderName))
        codeDirExists=1;
    end
end

forceClean = 0;
if(~isempty(settingsExperiment))
    forceClean = settingsExperiment.clean;
end

if(codeDirExists==1 && forceClean == 1)
    if(settingsExperiment.clean==1)
        [status, message, messageid] = rmdir(codeDir,'s');
        if(status==1)
            disp(['  successfully cleaned: ',codeDir]);
        else
            disp(['  cleaning failed     : ',codeDir]);        
        end
    end
end

if(codeDirExists==1 && forceClean == 0)
    protocolDirExists=0;
    labelDirExists=0;  
    dataDirExists=0;
    fileFolderList=dir(codeDir);
    for i=1:1:length(fileFolderList)
        if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,'segmentLabels'))
            labelDirExists=1;
        end
        if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,'data'))
            dataDirExists=1;
        end
        if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,'protocols'))
            protocolDirExists=1;
        end
    end
    if(protocolDirExists==0)
        mkdir(codeProtocolDir);
    end
    if(labelDirExists==0)
        mkdir(codeLabelDir);
    end
    if(dataDirExists==0)
        mkdir(dataDir);
    end
else
    mkdir(codeDir);
    mkdir(codeProtocolDir);
    mkdir(codeLabelDir); 
    mkdir(dataDir); 
end