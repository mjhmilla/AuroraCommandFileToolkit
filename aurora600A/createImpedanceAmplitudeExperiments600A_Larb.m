function indexEnd = createImpedanceAmplitudeExperiments600A_Larb(...
                        indexStart,...
                        seriesName,...
                        settingsImpedanceAmplitude,...
                        stochasticWaveSet,...
                        writeProtocolHeader,...
                        projectFolders,...                                                                                                            
                        auroraConfig,...
                        settingsExperiment)

assert(~isempty(seriesName),...
    'Error: series name must have a meaningful keyword in it');

nameMod='';
nameAppend = ['_',seriesName,'_impedance_ampl'];
if(~isempty(settingsExperiment))
    nameMod = settingsExperiment.nameModification;
    nameAppend = [nameAppend,'_',nameMod];
end



[codeDir, codeProtocolDir, codeLabelDir,dateId] = ...
    getTrialDirectories2026(projectFolders,nameAppend,...
                            settingsExperiment);

fidProtocol = [];

if(writeProtocolHeader==1)
    fidProtocol = fopen(fullfile(codeProtocolDir,['protocol_',dateId,'.csv']),'w');
    
    fprintf(fidProtocol,'%s,%s,%s,%s,%s,%s,%s\n',...
        'Number','Type','Starting_Length_Lo',...
        'Take_Photo','Block','FileName','Comment');
else
    fidProtocol = fopen(fullfile(codeProtocolDir,['protocol_',dateId,'.csv']),'a');
end

assert(length(stochasticWaveSet)==1,...
    'Error: stochasticWaveSet should only have one element');
%%
% Check (some) of the inputs
%%
success=0;
assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
       'Error: printed time values configured for ms only.');

%%
%Experiment configuration
%%
lengthRampOptions=getCommandFunctionOptions600A('Length-Ramp',auroraConfig);

scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

assert(strcmp(auroraConfig.defaultLengthUnit,'Lo'),...
      'Error: Assumed length unit is Lo');

nAmplitudes = length(settingsImpedanceAmplitude.amplitudeNormLengths);
amplitudes(nAmplitudes)= struct('length',0,'activationDuration',0,'amplitude',0);

for idxAmplitude = 1:1:nAmplitudes
    amplitudes(idxAmplitude).amplitude = ...
        settingsImpedanceAmplitude.amplitudeNormLengths(idxAmplitude);
    amplitudes(idxAmplitude).length = ...
        settingsImpedanceAmplitude.isometricNormLengths(idxAmplitude);
    amplitudes(idxAmplitude).activationDuration = ...
        auroraConfig.bath.activationDuration ...
        * settingsImpedanceAmplitude.isometricActivationDurationMultiple(1,idxAmplitude);
end

%%
% Block of isometric trials with varying perturbation amplitudes
%%
jsonProtocolTrialArray = cell(nAmplitudes*2,1);
fileCount=indexStart;
for i=1:1:nAmplitudes    
    for j=1:1:2
        blockName='';
        isActive=nan;
        switch j
            case 1
                blockName='passive';
                isActive = 0;
            case 2
                blockName='active';
                isActive =1;
            otherwise 
                assert(0,'Error: j must be 1 or 2');
        end

        idx=fileCount;
        idxStr = getTrialIndexString(idx);
        if(~isempty(settingsExperiment))
            if(~isempty(settingsExperiment.trialOrder))
                idx = settingsExperiment.trialOrder(fileCount);
                idxStr = getTrialIndexString(idx);
            end                    
        end
        
        startLength = amplitudes(i).length;
        takePhoto   = '';

        amplStr = sprintf('%1.1f',amplitudes(i).amplitude*100);
        idxP = strfind(amplStr,'.');
        amplStr(idxP)='p';
        amplStr=[amplStr,'Lo'];

        fname       = getTrialName(seriesName,idx,blockName,startLength,...
                        [amplStr,'_',dateId],'.pro');
        fnameOutput = getTrialName(seriesName,idx,blockName,startLength,...
                        [amplStr,'_',dateId],'.dat');
        fnameMetaData = getTrialName(seriesName,idx,blockName,startLength,...
                        [amplStr,'_',dateId],'.json');
        fnameLabels = getTrialName(seriesName,idx,blockName,startLength,...
                        [amplStr,'_',dateId,'_labels'],'.csv');
        larbFileName = getTrialName(seriesName,idx,blockName,startLength,...
                        [amplStr,'_',dateId,'_larb'],'.dat');
        
        jsonProtocolTrialArray(idx) = {fnameMetaData};

        jsonMetaData = struct('data',[],'protocol',[],...
                              'segments',[],'experiment',[]);

        jsonMetaData.data.file = {'data',fnameOutput};

        jsonMetaData.data.sha256 = 'MANUALLY_UPDATE_AFTER_EXPERIMENT';        
        if(~isempty(settingsExperiment))
            if(~isempty(settingsExperiment.dataPathSha256))
                measurementFolder=settingsExperiment.dataPathSha256;
                [status,cmdout] =  system(['sha256sum ',fullfile(measurementFolder,fnameOutput)]);
                i0 = strfind(cmdout,' ');        
                i0=i0-1;
                sha256Sum = cmdout;
                sha256Sum = sha256Sum(1,1:i0);            
                jsonMetaData.data.sha256 = sha256Sum;
            end
        end
        jsonMetaData.protocol.file = {'protocols',fname};


        fprintf(fidProtocol,'%s,%s,%1.2f,%s,%s,%s,%s\n',...
            idxStr,seriesName,startLength,takePhoto, blockName,fname,...
            ['Load arb wave 1 with: ',larbFileName]);
    
        auroraConfigIso = auroraConfig;
        auroraConfigIso.bath.activationDuration = amplitudes(i).activationDuration;
    
        fid = fopen(fullfile(codeProtocolDir,fname),'w');
        fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');
    
    
        %%
        % 0. Write the preamble
        %%
        
        lineCount=0;
        [startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);
    
        %%
        % 1. Activate if necessary
        %%
        if(isActive==1)
            [endTime, lineCount] = ...
                writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
            
            endActivation = endTime + auroraConfig.bath.activationDuration;
            
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
            fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
            
            startTime = endActivation;
            lineCount = lineCount+1;
    
        end    
    
        %%
        % 2. Write the wave 
        %%
    
        waveDir = fullfile(codeDir, 'wave');
        if(exist(waveDir)==0)
            mkdir(waveDir);
        end

        waveMetaDataDir = fullfile(codeDir, 'waveMetaData');
        if(exist(waveMetaDataDir)==0)
            mkdir(waveMetaDataDir);
        end
                
        larbOptions = stochasticWaveSet.options;
        larbOptions(1).value=1;
    
        segmentStartTime=startTime;
        segmentCount =1;
        numberOfSegments=0;
        for idxMeta = 1:1:length(stochasticWaveSet.metadata.bandwidth)
            if(stochasticWaveSet.metadata.bandwidth(idxMeta)>0)
                numberOfSegments=numberOfSegments+1;
            end
        end
        segmentMetaDataArray(numberOfSegments) = ...
            struct('type','','duration',[0,0],'meta_data',[]);
        for idxSeg=1:1:numberOfSegments
            segmentMetaDataArray(idxSeg).duration = [0,0];
            segmentMetaDataArray(idxSeg).meta_data.is_active = isActive;
            segmentMetaDataArray(idxSeg).meta_data.bandwidth = [0,0];
            segmentMetaDataArray(idxSeg).meta_data.amplitude = 0;
            segmentMetaDataArray(idxSeg).meta_data.file ={};
        end

        idxSeg=1;
        for idxMeta = 1:1:length(stochasticWaveSet.metadata.bandwidth)
            segmentFrequency = stochasticWaveSet.metadata.frequencyHz(idxMeta);
            segmentBandwidth = stochasticWaveSet.metadata.bandwidth(idxMeta);
            segmentDuration  = (stochasticWaveSet.metadata.points(idxMeta) ...
                               /segmentFrequency)*scaleTime;
            segmentAmplitude = amplitudes(i).amplitude;

            if(stochasticWaveSet.metadata.bandwidth(idxMeta)>0)
                
                t0 = segmentStartTime;                
                t1 = t0 + segmentDuration;

                segmentMetaDataArray(idxSeg).type = ...
                    stochasticWaveSet.type;                
                segmentMetaDataArray(idxSeg).duration = ...
                    [t0,t1];
                segmentMetaDataArray(idxSeg).meta_data.is_active =...
                    isActive;
                segmentMetaDataArray(idxSeg).meta_data.bandwidth = ...
                    [0,segmentBandwidth];
                segmentMetaDataArray(idxSeg).meta_data.amplitude = ...
                    segmentAmplitude;
                segmentMetaDataArray(idxSeg).meta_data.file =...
                    {'wave',...
                    larbFileName};

                idxSeg=idxSeg+1;
            end
            segmentStartTime = segmentStartTime + segmentDuration;

        end
        jsonMetaData.segments = segmentMetaDataArray;        

        scaledPerturbation = stochasticWaveSet.fileData.*segmentAmplitude;

        [endTime, lineCount] =  writeLarbBlock600A(...
                                  fid,...                                      
                                  startTime,...
                                  startLength,...
                                  scaledPerturbation,...
                                  larbOptions,...                                  
                                  stochasticWaveSet.metadata,...
                                  larbFileName,...
                                  waveDir,...
                                  waveMetaDataDir,...
                                  lineCount,...
                                  auroraConfig);

        fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
            stochasticWaveSet.type,startTime,endTime);

        segmentStartTime = startTime;
        for k=1:1:length(stochasticWaveSet.metadata.amplitude)
            segmentPoints = stochasticWaveSet.metadata.points(1,k);
            segmentFrequency = stochasticWaveSet.metadata.frequencyHz(1,k);
            segmentAmplitude = stochasticWaveSet.metadata.amplitude(1,k);
            segmentBandwidth = stochasticWaveSet.metadata.bandwidth(1,k);
            segmentTime = (segmentPoints/segmentFrequency)*scaleTime;
            segmentEndTime = segmentStartTime + segmentTime;

            fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
                [stochasticWaveSet.type,'-',num2str(k)],...
                segmentStartTime,segmentEndTime);

            segmentStartTime=segmentEndTime;
        end

        startTime = endTime + auroraConfig.minimumWaitTime;  
    
        %%
        % 3. Deactivate if necessary
        %%
        if(isActive==1)
    
            [endTime, lineCount] = ...
                writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);
            
            startTime=endTime+auroraConfig.minimumWaitTime;            
        end
        
        %%
        % End the trial
        %%
        [endTime, lineCount] = ...
            writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);
        
        success = 1;
        assert(lineCount < auroraConfig.maximumNumberOfCommands,...
            'Error: maximumNumberOfCommandsExceeded');
        
        fileCount = fileCount+1;   

        trialTitle=sprintf('Impedance %1.2f Lo ',startLength);
        if(isActive==1)
            trialTitle = [trialTitle,'Active'];
        else
            trialTitle = [trialTitle,'Passive'];            
        end

        jsonMetaData.experiment.title = trialTitle;

        jsonMetaDataEncoded = jsonencode(jsonMetaData);
        fidJson = fopen(fullfile(codeDir,fnameMetaData),'w');
        fprintf(fidJson,jsonMetaDataEncoded);        
        fclose(fidJson);

        fclose(fid);
        fclose(fidLabel);    
    end
end
fclose(fidProtocol);


protocolMetaData.trials = jsonProtocolTrialArray;

protocolMetaData.experiment.date = 'YYYY/MM/DD';
protocolMetaData.experiment.location = 'University of Stuttgart';
protocolMetaData.experiment.experimenter='Sven Weidner';
protocolMetaData.experiment.apparatus = 'Aurora 1400A';
protocolMetaData.experiment.specimen = 'animal-muscle-name';
protocolMetaData.experiment.temperature_C = nan;
protocolMetaData.experiment.temperatureControl = nan;
protocolMetaData.experiment.length_mm = nan;
protocolMetaData.experiment.width_mm = nan;
protocolMetaData.experiment.height_mm = nan;
protocolMetaData.experiment.maximum_isometric_stress_kPa = nan;
protocolMetaData.experiment.comment = nan;

protocolMetaData.funding.agency = 'Deutsche Forschungsgemeinschaft';
protocolMetaData.funding.number = '540349998';
protocolMetaData.funding.authors = 'Matthew Millard, André Tomalka';
protocolMetaData.funding.institution = 'Institute of Sport and Movement Science, University of Stuttgart, Stuttgart, Germany';

protocolMetaData.ethics.board = 'Regierungspräsidium Stuttgart, Referat 35';
protocolMetaData.ethics.number = 'RPS35-9185-99/411';
protocolMetaData.ethics.dates = 'January 1, 2024 to December 31, 2028';

jsonProtocolMetaData = jsonencode(protocolMetaData);

fnameJsonProtocol = fullfile(codeDir,...
    [dateId,'_',seriesName,'_impedance','_600A.json']);

if(~isempty(settingsExperiment))
    if(~isempty(settingsExperiment.folderName))
        fnameJsonProtocol = ...
            fullfile(codeDir,[settingsExperiment.folderName,'.json']);
    end
end

fidJsonProtocol = fopen(fnameJsonProtocol,'w');
fprintf(fidJsonProtocol,jsonProtocolMetaData);
fclose(fidJsonProtocol);

indexEnd = idx;