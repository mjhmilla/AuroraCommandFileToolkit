function success = createFiberInjuryExperiments600A(  stochasticWaveSet,...
                                                      projectFolders,...                                                                                                            
                                                      auroraConfig)

%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');



%%
%Make the output folders, if necessary
%%
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

codeDir         = fullfile(projectFolders.output_code,dateId);
codeLabelDir    = fullfile(projectFolders.output_code,dateId,'segmentLabels');

fileFolderList=dir(projectFolders.output_code);
codeDirExists=0;
for i=1:1:length(fileFolderList)
    if(fileFolderList(i).isdir && strcmp(fileFolderList(i).name,dateId))
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

%%
% 
%%

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
    'Number','Type','Starting_Length_Lo',...
    'Take_Photo','Block','FileName','Comment');

%%
% 1. Starting isometric trial to see if the fiber is viable
%%
idx = 1;
idxStr = getTrialIndexString(idx);


startLength = 1;
type        = 'isometric';
takePhoto   = 'Yes';
blockName   = 'Pre-injury';
fname       = getTrialNameUpd(idx,type,startLength,dateId);
fnameLabels = getTrialNameUpd(idx,type,startLength,[dateId,'_labels']);



fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
    idxStr,type,startLength,takePhoto, blockName,fname,'');

success = createIsometricImpedanceTrial(...
                    stochasticWaveSet,...
                    fullfile(codeDir,fname),...
                    fullfile(codeLabelDir,fnameLabels),...
                    auroraConfig);
  
fclose(fidProtocol);

success=1;