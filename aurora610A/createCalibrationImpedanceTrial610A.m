function success= createCalibrationImpedanceTrial610A(...                    
                    dateId,...                                    
                    auroraConfig,...
                    expConfig,...
                    expFolders,...
                    plotConfig)

success=0;

idxTrial=0;

flag_generateSingleWaveCalibration     = 1;
flag_generateStochasticWaveCalibration = 1;
%
% Create trials that test one waveform at a time
%
if(flag_generateSingleWaveCalibration==1)

  waveType = {'Sine Wave','Ramp','Step'};
  portType = {'Length Out'};
  waveCount = [1,10];
  
  for idxWaveType=1:1:length(waveType)
  
    for idxPort=1:1:length(portType)
      for idxWaveCount=1:1:length(waveCount)
    
        idxTrial=idxTrial+1;
    
        idxStr = num2str(idxTrial);
        if(length(idxStr)<2)
          idxStr =['0',idxStr];
        end
    
        waveTypeName = strrep(waveType{idxWaveType},' ','');
        portTypeName = strrep(portType{idxPort},' ','');
    
        trialFileNameNoExt = ...
          sprintf('%s_impedanceCal_%i_waves_%s_%s_%s',...
                  idxStr, waveCount(idxWaveCount),...
                  waveTypeName,portTypeName,dateId);
    
        fid = fopen(fullfile(expFolders.rootFolderPath,...
                             expFolders.protocolFolderName,...
                             [trialFileNameNoExt,'.dpf']),'w');
    
        trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                      expFolders.blockLabelsFolderName,...
                                      [trialFileNameNoExt,'.csv']);
        
        %
        % Set up the meta data
        %
        programMetaData = ...
          getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
    
        programMetaData = ...
          writePreamble610A(fid,auroraConfig,programMetaData);
    
        jsonMetaData = struct('data',[],'protocol',[],...
                              'segments',[],'experiment',[]);
        
        
        jsonMetaData.data.file = {expFolders.dataFolderName, ...
                                  [trialFileNameNoExt,'.ddf']};
        jsonMetaData.data.sha256 = "";
        
        jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
                                  [trialFileNameNoExt,'.dpf']};
        jsonMetaData.protocol.sha256 = "";
    
        numberOfSegments = length(expConfig.frequencyHz);
        mdfn = getMetaDataFieldNames610A(auroraConfig);
    
        segmentMetaDataArray(numberOfSegments) = ...
          struct('type','',mdfn.time,[0,0],'meta_data',[]);
        
        for k=1:1:numberOfSegments
          %
          % write the commands
          %
          [options,isValid,msg]= getCommandFunctionOptions610A(...
                                  waveType{idxWaveType},...
                                  portType{idxPort},...
                                  auroraConfig);  
          ampl = 0;
          switch idxPort
            case 1
              ampl = expConfig.amplitudeMM;
            case 2
              ampl = expConfig.amplitudeN;
            otherwise
              assert(0,'Error: invalid port name');
          end
    
          switch waveType{idxWaveType}
            %
            % Sine Wave
            %
            case 'Sine Wave'              
              period = round((1/expConfig.frequencyHz(k))...
                              *auroraConfig.analogToDigitalSampleRateHz)...
                        /auroraConfig.analogToDigitalSampleRateHz;
              frequencyHz = 1/period;
              options(1).value=frequencyHz;
              options(2).value=0.5*ampl;
              options(3).value=waveCount(idxWaveCount);
  
    
              
              if(k>1)
                startTime = programMetaData.controlFunction.endTime ...
                            + expConfig.waitTime;
              else
                startTime=programMetaData.startTime ...
                          + expConfig.waitTime;
              end
              startTime = round(startTime,4);
    
    
              endTime   = startTime ...
                        + round(period*waveCount(idxWaveCount),4);
    
              %
              % Set the meta data
              %
              segmentMetaDataArray(k).(mdfn.time) = [startTime,endTime]; 
              
              segmentMetaDataArray(k).type = ['Sine Wave'];
              segmentMetaDataArray(k).meta_data.is_active = 0;
              
              segmentMetaDataArray(k).meta_data.channel ...
                = options(1).port;
              segmentMetaDataArray(k).meta_data.(mdfn.frequency) ...
                = options(1).value;
              switch idxPort
                case 1
                  segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
                    = options(2).value;    
                case 2
                  segmentMetaDataArray(k).meta_data.(mdfn.amplitudeForce) ...
                    = options(2).value;
                otherwise
                  assert(0,'Error: Unrecognized port');
              end
              segmentMetaDataArray(k).meta_data.(mdfn.cycles) ...
                = options(3).value;    
    
              flag_printMetaDataToFile=1;
    
              programMetaData ...
                      = writeControlFunction610A(...
                              fid,...
                              expConfig.waitTime,...
                              'Sine Wave',...
                              options,...
                              auroraConfig,...                
                              programMetaData,...
                              flag_printMetaDataToFile);  
              
              endTimeError = endTime - programMetaData.controlFunction.endTime;
              assert(abs(endTimeError)<1e-3,...
                  'Error: end time differs from the meta data');          

            %
            % Ramp 
            %              
            case 'Ramp'
              
              period8 = roundTimeToNearestSampleTime(...
                          0.125/expConfig.frequencyHz(k),...
                          auroraConfig);
              period4 = period8*2;
              
              period = period4*4;

              frequencyHz = 1/period;

              if(waveCount(idxWaveCount) == 1)
                  waitTime1  = expConfig.waitTime;
                  rampTime1  = period8;
                  waitTime2  = period4;             
                  rampTime2  = period4;
                  waitTime3  = period4;             
                  rampTime3  = period8;                

                  options1 = options;
                  options2 = options;
                  options3 = options;
    
                  options1(1).value = 0.5*ampl;
                  options1(2).value = rampTime1;
                  
                  options2(1).value = -0.5*ampl;
                  options2(2).value = rampTime2; 

                  options3(1).value = 0;
                  options3(2).value = rampTime3;   


                  if(k>1)
                    startTime = programMetaData.controlFunction.endTime;
                  else
                    startTime=programMetaData.startTime;
                  end    

                  startTime = round(startTime,4);            
                  endTime   = startTime ...
                              +(waitTime1+rampTime1...
                               +waitTime2+rampTime2...
                               +waitTime3+rampTime3);  

                  startBlockTime=startTime+expConfig.waitTime;
                  endBlockTime  = startBlockTime+period;

                  segmentMetaDataArray(k).(mdfn.time) = ...
                    [startBlockTime,endBlockTime]; 
                  
                  segmentMetaDataArray(k).type = ['Ramp Wave'];
                  segmentMetaDataArray(k).meta_data.is_active = 0;
                  
                  segmentMetaDataArray(k).meta_data.channel ...
                    = options(1).port;
                  segmentMetaDataArray(k).meta_data.(mdfn.frequency) ...
                    = frequencyHz;
                  switch idxPort
                    case 1
                      segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
                        = ampl;    
                    case 2
                      assert(0,'Error: not yet implemented');
                    otherwise
                      assert(0,'Error: Unrecognized port');
                  end
    
                  segmentMetaDataArray(k).meta_data.(mdfn.cycles) ...
                    = waveCount(idxWaveCount);       


                  flag_printMetaDataToFile=1;
        
                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime1,...
                                  'Ramp',...
                                  options1,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);  
    
                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime2,...
                                  'Ramp',...
                                  options2,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);  

                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime3,...
                                  'Ramp',...
                                  options3,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);                            

                  endTimeError = endTime - programMetaData.controlFunction.endTime;
                  assert(abs(endTimeError/endTime)<5e-3,...
                      'Error: end time differs from the meta data');                                              

              end

              if(waveCount(idxWaveCount) > 1)
                for idxWave =1:1:waveCount(idxWaveCount)

                  waitTime1  = period4;
                  rampTime1  = period4;
                  waitTime2  = period4;             
                  rampTime2  = period4;
                  
                  if(idxWave ==1)
                    rampTime1 = period8;
                    %waitTime1 = waitTime1 + expConfig.waitTime; 
                  end
                  
                  if(period8 > programMetaData.smallestNextWaitTime)

                    options1 = options;
                    options2 = options;
      
                    options1(1).value = 0.5*ampl;
                    options1(2).value = rampTime1;
                    
                    options2(1).value = -0.5*ampl;
                    options2(2).value = rampTime2;   

                    if( idxWave>1 )
                      startTime = programMetaData.controlFunction.endTime;
                    else
                      startTime=programMetaData.nextStartTime;                      
                      waitTime1=expConfig.waitTime;
                    end    

                    startTime = round(startTime,4);            
                    endTime   = startTime ...
                               + (waitTime1+rampTime1+waitTime2+rampTime2);                  

                    %
                    % Set the meta data
                    %
                    if(idxWave==1)
                      startBlockTime = programMetaData.nextStartTime...
                                      +expConfig.waitTime;
                      endBlockTime = startBlockTime ...
                        + (period)*waveCount(idxWaveCount);
                      segmentMetaDataArray(k).(mdfn.time) ...
                        = [startBlockTime,endBlockTime]; 
                      
                      segmentMetaDataArray(k).type = ['Ramp Wave'];
                      segmentMetaDataArray(k).meta_data.is_active = 0;
                      
                      segmentMetaDataArray(k).meta_data.channel ...
                        = options(1).port;
                      segmentMetaDataArray(k).meta_data.(mdfn.frequency) ...
                        = frequencyHz;
                      switch idxPort
                        case 1
                          segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
                            = ampl;    
                        case 2
                          assert(0,'Error: not yet implemented');
                        otherwise
                          assert(0,'Error: Unrecognized port');
                      end
        
                      segmentMetaDataArray(k).meta_data.(mdfn.cycles) ...
                        = waveCount(idxWaveCount);    
                    end

                    flag_printMetaDataToFile=1;
          
                    programMetaData ...
                            = writeControlFunction610A(...
                                    fid,...
                                    waitTime1,...
                                    'Ramp',...
                                    options1,...
                                    auroraConfig,...                
                                    programMetaData,...
                                    flag_printMetaDataToFile);  
      
                    programMetaData ...
                            = writeControlFunction610A(...
                                    fid,...
                                    waitTime2,...
                                    'Ramp',...
                                    options2,...
                                    auroraConfig,...                
                                    programMetaData,...
                                    flag_printMetaDataToFile);  

                    if(idxWave == waveCount(idxWaveCount))
                      options3 = options;                    
                      options3(1).value = 0;
                      options3(2).value = period8;   
                      
                      waitTime3=waitTime2;
                      endTime = endTime+waitTime3+options3(2).value;

                      programMetaData ...
                              = writeControlFunction610A(...
                                      fid,...
                                      waitTime3,...
                                      'Ramp',...
                                      options3,...
                                      auroraConfig,...                
                                      programMetaData,...
                                      flag_printMetaDataToFile);  


                    end
                    

                    endTimeError = endTime - programMetaData.controlFunction.endTime;
                    if(abs(endTimeError/endTime)>5e-3)
                      here=1;
                    end
                    assert(abs(endTimeError/endTime)<5e-3,...
                        'Error: end time differs from the meta data'); 
                  end                  
                end
              end
       


            %
            % Step 
            %                            
            case 'Step'

              period2 = roundTimeToNearestSampleTime(...
                          (0.5/expConfig.frequencyHz(k)),...
                          auroraConfig);
              
              period = period2*2;

              frequencyHz = 1/period;
              
              if(waveCount(idxWaveCount)==1)
                waitTime1  = expConfig.waitTime;
                waitTime2  = period2;        
                waitTime3  = period2;

                if(period2 > programMetaData.smallestNextWaitTime)
                  options1 = options;
                  options2 = options;
                  options3 = options;
    
                  options1(1).value = 0.5*ampl;                  
                  options2(1).value = -0.5*ampl;
                  options3(1).value = 0;

                  if(k>1)
                    startTime = programMetaData.controlFunction.endTime;
                  else
                    startTime=programMetaData.startTime;
                  end    

                  startTime = round(startTime,4);            
                  endTime   = startTime  ...
                               + (waitTime1+waitTime2+waitTime3); 

                  %
                  % Set the meta data
                  %
                  startBlockTime = startTime+expConfig.waitTime;
                  endBlockTime   = startBlockTime+period;
                  segmentMetaDataArray(k).(mdfn.time) = [startBlockTime,endBlockTime]; 
                  
                  segmentMetaDataArray(k).type = ['Step Wave'];
                  segmentMetaDataArray(k).meta_data.is_active = 0;
                  
                  segmentMetaDataArray(k).meta_data.channel ...
                    = options(1).port;
                  segmentMetaDataArray(k).meta_data.(mdfn.frequency) ...
                    = expConfig.frequencyHz(k);
                  switch idxPort
                    case 1
                      segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
                        = ampl;    
                    case 2
                      assert(0,'Error: not yet implemented');
                    otherwise
                      assert(0,'Error: Unrecognized port');
                  end
    
                  segmentMetaDataArray(k).meta_data.(mdfn.cycles) ...
                    = waveCount(idxWaveCount);    
                                      flag_printMetaDataToFile=1;
      
                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime1,...
                                  'Step',...
                                  options1,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);  
    
                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime2,...
                                  'Step',...
                                  options2,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);  

                  programMetaData ...
                          = writeControlFunction610A(...
                                  fid,...
                                  waitTime3,...
                                  'Step',...
                                  options3,...
                                  auroraConfig,...                
                                  programMetaData,...
                                  flag_printMetaDataToFile);  

                  endTimeError = endTime - programMetaData.controlFunction.endTime;
                  assert(abs(endTimeError/endTime)<5e-3,...
                      'Error: end time differs from the meta data'); 
             

                end



              end

              if(waveCount(idxWaveCount)>1)
                for idxWave =1:1:waveCount(idxWaveCount)

                  waitTime1  = period2;
                  waitTime2  = period2;             
                  
                  %if(idxWave ==1)
                  %  waitTime1 = waitTime1 + expConfig.waitTime; 
                  %end            

                  if(period2 > programMetaData.smallestNextWaitTime)

                    options1 = options;
                    options2 = options;
                    
                    options1(1).value = 0.5*ampl;                  
                    options2(1).value = -0.5*ampl;




                    if( idxWave > 1 )
                      startTime = programMetaData.controlFunction.endTime;
                    else
                      startTime=programMetaData.nextStartTime;
                      waitTime1= expConfig.waitTime;
                    end    

                    startTime = round(startTime,4);            
                    endTime   = startTime  ...
                                 + (waitTime1+waitTime2);                  

                    %
                    % Set the meta data
                    %
                    if(idxWave==1)
                      startBlockTime = startTime+expConfig.waitTime;
                      endBlockTime = startBlockTime ...
                        + (period)*waveCount(idxWaveCount);
                      segmentMetaDataArray(k).(mdfn.time) ...
                        = [startBlockTime,endBlockTime]; 
                      
                      segmentMetaDataArray(k).type = ['Step Wave'];
                      segmentMetaDataArray(k).meta_data.is_active = 0;
                      
                      segmentMetaDataArray(k).meta_data.channel ...
                        = options(1).port;
                      segmentMetaDataArray(k).meta_data.(mdfn.frequency) ...
                        = expConfig.frequencyHz(k);
                      switch idxPort
                        case 1
                          segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
                            = ampl;    
                        case 2
                          assert(0,'Error: not yet implemented');
                        otherwise
                          assert(0,'Error: Unrecognized port');
                      end
      
                      segmentMetaDataArray(k).meta_data.(mdfn.cycles) ...
                        = waveCount(idxWaveCount);    
                    end

                    flag_printMetaDataToFile=1;
          
                    programMetaData ...
                            = writeControlFunction610A(...
                                    fid,...
                                    waitTime1,...
                                    'Step',...
                                    options1,...
                                    auroraConfig,...                
                                    programMetaData,...
                                    flag_printMetaDataToFile);  
      
                    
                    programMetaData ...
                            = writeControlFunction610A(...
                                    fid,...
                                    waitTime2,...
                                    'Step',...
                                    options2,...
                                    auroraConfig,...                
                                    programMetaData,...
                                    flag_printMetaDataToFile);  

                    if(idxWave == waveCount(idxWaveCount))
                      options3 = options;                    
                      options3(1).value = 0;
                      waitTime3=waitTime2;
                      endTime = endTime+waitTime3;

                      programMetaData ...
                              = writeControlFunction610A(...
                                      fid,...
                                      waitTime3,...
                                      'Step',...
                                      options3,...
                                      auroraConfig,...                
                                      programMetaData,...
                                      flag_printMetaDataToFile);  

                    end

                    endTimeError = endTime - programMetaData.controlFunction.endTime;
                    assert(abs(endTimeError/endTime)<5e-3,...
                        'Error: end time differs from the meta data'); 
                  end                  
                end
              end

            otherwise
              assert(0,'Error: invalid wave type');
          end
        
        end
    
        %
        % Write the closing block
        %
        waitTime = auroraConfig.stop.waitTime;
        
        programMetaData = ...
            writeClosingBlock610A(...
                fid,...
                waitTime,...
                auroraConfig,...
                programMetaData,...
                flag_printMetaDataToFile);
        
        success = 1;
        assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
            'Error: maximumNumberOfCommandsExceeded');
        

        maxSegEntries=0;
        for idxSegEntry = 1:1:length(segmentMetaDataArray)
          if(~isempty(segmentMetaDataArray(idxSegEntry).type))
            maxSegEntries=idxSegEntry;
          end
        end

        jsonMetaData.segments = segmentMetaDataArray(1:maxSegEntries);  
        jsonMetaData.experiment.title = ...
          sprintf('%s %s %1.1f-1.1f Hz',...
                  waveType{idxWaveType},...
                  portType{idxPort},...
                  expConfig.frequencyHz(1),...
                  expConfig.frequencyHz(end));
        jsonMetaData.experiment.tags = {'impedanceCalibration',...
                                        waveTypeName,...
                                        portTypeName};
    
        jsonMetaDataEncoded = jsonencode(jsonMetaData);    
        fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                                 [trialFileNameNoExt,'.json']),'w');
        fprintf(fidJson,jsonMetaDataEncoded);
        fclose(fidJson);
    
        %
        % close the file
        %
        fclose(fid);
        fclose(programMetaData.labelFileHandle);    
        here=1;
    
        %
        % clear memory
        %
        clear("segmentMetaDataArray");
      end
    end
  
  end
end

if(flag_generateStochasticWaveCalibration==1)

  waveType = {'Sine Wave','Ramp','Step'};
  portType = {'Length Out'};

  for idxWaveType=1:1:length(waveType)
    for idxPort=1:1:length(portType)

      idxTrial=idxTrial+1;
      %
      % Create trials that test an entire bandwidth in one perturbation
      %
      flag_fitPerturbationPowerSpectrum = 1;
      commandFunctionName = waveType{idxWaveType};
      
      configStochasticWave = getPerturbationConfiguration610A(...
                               expConfig.perturbation.amplitudeMM,...
                               expConfig.perturbation.bandwidthHz,...
                               expConfig.perturbation.points,...
                               flag_fitPerturbationPowerSpectrum,...
                               auroraConfig);
      
      commandFunctionOption = getCommandFunctionOptions610A(...
                        commandFunctionName,'Length Out',auroraConfig);
      
      figPerturbation=figure;
      verbose        =1;
      
      plotConfig.numberOfHorizontalPlotColumns    = 1;
      plotConfig.numberOfVerticalPlotRows         = 3;
      plotConfig.plotWidth                        = 18;
      plotConfig.plotHeight                       = 6;
      
      [subplotPanel_3R1C,plotConfig_3R1C]=plotConfigGeneric(plotConfig);
      
      
      perturbationPlotConfig.subplot= subplotPanel_3R1C;
      perturbationPlotConfig.config = plotConfig_3R1C;    
      
      [preconditioningWave, ...
       stochasticWave, ...    
       figPerturbation] = ...
        createPerturbationWave610A(...
                commandFunctionName,...
                commandFunctionOption,...
                configStochasticWave,...
                auroraConfig, ...
                figPerturbation,...
                perturbationPlotConfig,...
                verbose);
    
      %
      % Write the trial
      %
      idxTrialStr = num2str(idxTrial);
      if(length(idxTrialStr)<2)
        idxTrialStr = ['0',idxTrialStr];
      end
      
      waveTypeName = strrep(waveType{idxWaveType},' ','');
      portTypeName = strrep(portType{idxPort},' ','');
    
      [options,isValid,msg]= getCommandFunctionOptions610A(...
                              waveType{idxWaveType},...
                              portType{idxPort},...
                              auroraConfig);    
    
      trialFileNameNoExt = ...
        sprintf('%s_impedanceCal_%s_%s_%s_%s',...
                idxTrialStr, 'stochastic',waveTypeName,portTypeName,dateId);
    
      fid = fopen(fullfile(expFolders.rootFolderPath,...
                           expFolders.protocolFolderName,...
                           [trialFileNameNoExt,'.dpf']),'w');
    
      trialBlockLabelFilePath = fullfile(expFolders.rootFolderPath,...
                                    expFolders.blockLabelsFolderName,...
                                    [trialFileNameNoExt,'.csv']);
      
      programMetaData = getEmptyProgramMetaDataStruct(trialBlockLabelFilePath);
      programMetaData = writePreamble610A(fid,auroraConfig,programMetaData);
    
      %
      % Setup meta-data
      %
      
      jsonMetaData = struct('data',[],'protocol',[],...
                            'segments',[],'experiment',[]);
      
      
      jsonMetaData.data.file = {expFolders.dataFolderName, ...
                                [trialFileNameNoExt,'.ddf']};
      jsonMetaData.data.sha256 = "";
      
      jsonMetaData.protocol.file = {expFolders.protocolFolderName, ...
                                [trialFileNameNoExt,'.dpf']};
      jsonMetaData.protocol.sha256 = "";
    
      numberOfSegments = 1;
      mdfn = getMetaDataFieldNames610A(auroraConfig);
    
      segmentMetaDataArray(numberOfSegments) = ...
        struct('type','',mdfn.time,[0,0],'meta_data',[]);
    
      %
      % Write the protocol
      %
      waitTimeForBlock=1;
      flag_printMetaDataToFile = 1;
    
      switch waveType{idxWaveType}
        case 'Step'

            programMetaData = ...
                writeLengthStepBlock610A(...
                    fid, ...
                    waitTimeForBlock,...
                    stochasticWave.controlFunctions.waitDuration,...
                    stochasticWave.controlFunctions.optionValues(:,1),...
                    stochasticWave.controlFunctions.options,...
                    auroraConfig,...
                    programMetaData,...
                    [waveType{idxWaveType},'-Stochastic'],...
                    flag_printMetaDataToFile);  

        case 'Ramp'            


            programMetaData = ...
                writeLengthRampBlock610A(...
                    fid, ...
                    waitTimeForBlock,...
                    stochasticWave.controlFunctions.waitDuration,...
                    stochasticWave.controlFunctions.optionValues(:,1),...
                    stochasticWave.controlFunctions.optionValues(:,2),...
                    stochasticWave.controlFunctions.options,...
                    auroraConfig,...
                    programMetaData,...
                    [waveType{idxWaveType},'-Stochastic'],...
                    flag_printMetaDataToFile); 

        case 'Sine Wave'
          programMetaData = ...
              writeLengthSineBlock610A(...
                  fid,...
                  waitTimeForBlock,...
                  stochasticWave.controlFunctions.waitDuration,...
                  stochasticWave.controlFunctions.optionValues(:,1),...
                  stochasticWave.controlFunctions.optionValues(:,2),...
                  stochasticWave.controlFunctions.optionValues(:,3),...
                  stochasticWave.controlFunctions.options,...
                  auroraConfig,...
                  programMetaData,...
                  [waveType{idxWaveType},'-Stochastic'],...
                  flag_printMetaDataToFile); 


        otherwise 
          assert(0,'Error: Unrecognized wave type');
    
      end
      k=1;
      startTime = waitTimeForBlock;
      endTime   = programMetaData.controlFunction.endTime;
      
      segmentMetaDataArray(k).type = [waveType{idxWaveType},'-Stochastic'];
      segmentMetaDataArray(k).(mdfn.time) = [startTime,endTime]; 
    
      segmentMetaDataArray(k).meta_data.is_active = 0;
     
      segmentMetaDataArray(k).meta_data.(mdfn.bandwidth) ...
        = expConfig.perturbation.bandwidthHz;
      segmentMetaDataArray(k).meta_data.(mdfn.amplitude) ...
        = expConfig.perturbation.amplitudeMM;
    
    
      %
      % Closing block
      %  
      waitTime = auroraConfig.stop.waitTime;
      
      programMetaData = ...
          writeClosingBlock610A(...
              fid,...
              waitTime,...
              auroraConfig,...
              programMetaData,...
              flag_printMetaDataToFile);
      
      assert(programMetaData.lineCount < auroraConfig.maximumNumberOfCommands,...
          'Error: maximumNumberOfCommandsExceeded');
    
      %
      % Write the meta data
      %
      jsonMetaData.segments = segmentMetaDataArray;  
      jsonMetaData.experiment.title = ...
        sprintf('%s %s %1.1f-%1.1f Hz',...
                [waveTypeName,'-Stochastic'],...
                portTypeName,...
                expConfig.perturbation.bandwidthHz(1),...
                expConfig.perturbation.bandwidthHz(2));
      jsonMetaData.experiment.tags = {'impedance',...
                                      [waveTypeName,'-Stochastic'],...
                                      portTypeName};
    
      jsonMetaDataEncoded = jsonencode(jsonMetaData);    
      fidJson = fopen(fullfile(expFolders.rootFolderPath,...
                               [trialFileNameNoExt,'.json']),'w');
      fprintf(fidJson,jsonMetaDataEncoded);
      fclose(fidJson);
      %
      % Close the file handles and clear any (potentially) re-used memory
      %
      fclose(fid);
      fclose(programMetaData.labelFileHandle);  
    
      clear("segmentMetaDataArray");
    end
  end
end
success=1;

