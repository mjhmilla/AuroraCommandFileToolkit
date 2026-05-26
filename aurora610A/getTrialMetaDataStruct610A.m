function jsonMetaData = getTrialMetaDataStruct610A(...
    trialFileNameNoExt, expFolders, flag_isASequence)

if(flag_isASequence==0)
  jsonMetaData = struct('data',[],'protocol',[],...
                        'segments',[],'experiment',[]);
  
  jsonMetaData.data.file = {expFolders.dataFolderName, ...
                            [trialFileNameNoExt,'.ddf']};
  jsonMetaData.data.sha256 = "";
  
  jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
                                [trialFileNameNoExt,'.dpf']};
  jsonMetaData.protocol.sha256 = "";
else
  jsonMetaData = struct('segments',[],'experiment',[]);
  
end