function [programMetaData,fcnMetaData]= ...
  writeControlFunction600AUpd(...
                fid,...
                isActive,...
                startTime,...
                controlFunctionName,...
                controlFunctionOptions,...
                externalFileMetaData,...
                auroraConfig,...
                programMetaData,...                
                flag_printMetaDataToFile,...
                flag_onlyRecordDuringCommand)



%options has fields of
% value
% unit
% printUnit


fcnMetaData=struct('type',controlFunctionName, ...
           auroraConfig.labels.time, [nan,nan],...
           'meta_data',[]);


assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
    'Error: auroraConfig.defaultTimeUnit and startTime must be in ms');

if(~isempty(externalFileMetaData))
  assert(isfield(externalFileMetaData,'duration_s'),...
         'Error: externalFileMetaData must have a duration_s field');

  assert(isfield(externalFileMetaData,'file_name'),...
         'Error: externalFileMetaData must have a fileName field');

  assert(isfield(externalFileMetaData,'meta_data'),...
         'Error: externalFileMetaData must have a meta_data field');

end

s2ms = 1000;

sampleTime=1/auroraConfig.analogToDigitalSampleRateHz;

switch auroraConfig.defaultTimeUnit
  case 'ms'
    sampleTime=sampleTime*s2ms;
  case 's'
    assert(0,['Error: auroraConfig.defaultTimeUnit must be ms for now: this code',...
              ' has not been tested with units of s']);
  otherwise
    assert(0,'Error: auroraConfig.defaultTimeUnit must be ms or s');
end



assert(waitTimeInS >= programMetaData.smallestNextWaitTime, ...
     ['Error: waitTimeInS is not larger than',...
    ' programMetaData.smallestNextWaitTime']);


timeStr = sprintf('%1.1f',startTime);
endTime = str2double(timeStr);

while length(timeStr)<9
  timeStr = [' ',timeStr];
end


dataEnableCommandLine = ''
if(flag_onlyRecordDuringCommand==1)

  assert(   ~strcmp(controlFunctionName,'Data-Enable') ...
         && ~strcmp(controlFunctionName,'Data-Disable'),...
         ['Error: cannot use flag_onlyRecordDuringCommand with Data-Enable',...
          ' or Data-Disable']);  

  assert(programMetaData.dataEnable==0,...
         ['Error: flag_onlyRecordDuringCommand can be used only after',...
          ' Data-Disable has been called']);

  dataEnableCommandLine = sprintf('%s\t%s',timeStr,'Data-Enable');

  startTime = startTime+auroraConfig.minimumWaitTime;
  timeStr = sprintf('%1.1f',startTime);
  endTime = str2double(timeStr);

  while length(timeStr)<9
    timeStr = [' ',timeStr];
  end
  
end


if(length(controlFunctionOptions) > 0)
  commandLine = sprintf('%s\t%s\t\t',timeStr,controlFunctionName);
else
  commandLine = sprintf('%s\t%s',timeStr,controlFunctionName);
end
% Check that the options are valid

controlsWithADuration = ...
  {'Length-Ramp','Length-Square','Length-Sine',...
   'Length-Sweep','Length-Sample',...
   'Force-Ramp','Force-Square','Force-Sine',...
   'Force-Sweep','Force-Sample','Force-Clamp',...
   'SL-Ramp','SL-Sample','SL-Trigger',...
   'Stimulus','Trigger1','Trigger2',...
   'Data-Burst','Bath'};

%%
% Build the command in string form.
%%
isLastTimeFieldDelay = 0;

for i=1:1:length(controlsWithADuration)
  if(strcmp(controlsWithADuration{i},controlFunctionName))
    isLastTimeFieldDelay = 1;
  end
end


controlFunctionOptionsUpd = controlFunctionOptions;

if(isempty(controlFunctionOptions)==0)
  for i=1:1:length(controlFunctionOptions)
    unitStr = '';
    valueStr = '';
    value = nan;
    switch controlFunctionOptions(i).type

      case 'time'
        unitStr = controlFunctionOptions(i).unit;  
        switch unitStr
          case 'ms'
            valueStr = sprintf('%1.1f',...  
                      controlFunctionOptions(i).value);
          case 's'
            valueStr = sprintf('%1.4f',...
                      controlFunctionOptions(i).value);
            assert(0,'Error: all time units should be in ms');            
          otherwise 
            assert(0,'Error: time unit must be ms or s');
        end

        value=str2double(valueStr);

        controlFunctionOptionsUpd(i).unit='ms'
        controlFunctionOptionsUpd(i).value = value;

      case 'length'
        unitStr = controlFunctionOptions(i).unit;     

        [value,valueStr]=convertToAuroraFloatingPointFormat600A(...
                          controlFunctionOptions(i).value);

        if(controlFunctionOptions(i).isRelative==1)
          if(controlFunctionOptions(i).value >= 0)
            valueStr = ['+',valueStr];
          end
        else
          assert( controlFunctionOptions(i).value > 0, ...
              'Error: an absolute length must be positive');
        end

        controlFunctionOptionsUpd(i).value = str2double(valueStr);


      case 'force'
        unitStr = controlFunctionOptions(i).unit;          

        [value,valueStr]=convertToAuroraFloatingPointFormat600A(...
                          controlFunctionOptions(i).value);

        if(controlFunctionOptions(i).isRelative==1)
          if(controlFunctionOptions(i).value >= 0)
            valueStr = ['+',valueStr];
          end
        else
          assert( controlFunctionOptions(i).value > 0, ...
              'Error: an absolute force must be positive');        
        end

        controlFunctionOptionsUpd(i).value = str2double(valueStr);

      case 'frequency'
        unitStr  = controlFunctionOptions(i).unit;  
        assert(strcmp(unitStr,'Hz'),...
            'Error: Frequency must be in units of Hz');

        [value,valueStr]=convertToAuroraFloatingPointFormat600A(...
                          controlFunctionOptions(i).value);

        controlFunctionOptionsUpd(i).value = str2double(valueStr);

      case 'bool'
        valueStr = sprintf('%i',controlFunctionOptions(i).value);  
        assert(controlFunctionOptions(i).value==0 ...
          || controlFunctionOptions(i).value==1,...
             'Error: bool type must be 0 or 1');
        controlFunctionOptionsUpd(i).value = str2double(valueStr);

      case 'integer'
        valueStr = sprintf('%i',controlFunctionOptions(i).value);  

        if(   strcmp(controlFunctionName,'Trigger1') ...
          ||  strcmp(controlFunctionName,'Trigger2') ...
          ||  strcmp(controlFunctionName,'Stimulus'))

          assert(controlFunctionOptions(i).value >= 1 ...
            && controlFunctionOptions(i).value <= 10,...
               'Error: Stimulus pattern must be 1-10');
          assert(abs(controlFunctionOptions(i).value...
              -round(controlFunctionOptions(i).value))==0,...
               'Error: Stimulus pattern must be an integer');

        end     

        if(   strcmp(controlFunctionName,'Length-Sample') ...
           || strcmp(controlFunctionName,'Force-Sample') ...
           || strcmp(controlFunctionName,'SL-Sample')
           || strcmp(controlFunctionName,'SL-Hold'))

          assert(controlFunctionOptions(i).value >= 1 ...
              && controlFunctionOptions(i).value <= 9,...
               'Error: sample number must be 1-9');
          
          assert(abs(controlFunctionOptions(i).value...
              -round(controlFunctionOptions(i).value))==0,...
               'Error: sample number must be an integer');          
        end

        if(   strcmp(controlFunctionName,'Length-Hold') ...
           || strcmp(controlFunctionName,'Force-Hold') ...
           || strcmp(controlFunctionName,'SL-Hold'))

          assert(controlFunctionOptions(i).value >= 0 ...
              && controlFunctionOptions(i).value <= 9,...
               'Error: sample number must be 0-9');
          
          assert(abs(controlFunctionOptions(i).value...
              -round(controlFunctionOptions(i).value))==0,...
               'Error: sample number must be an integer');          
        end

        if(  strcmp(controlFunctionName,'Length-Arb') )

          assert(controlFunctionOptions(i).value >= 1 ...
              && controlFunctionOptions(i).value <= 4,...
               'Error: Larb file id must be 1-4');

          assert(abs(controlFunctionOptions(i).value...
              -round(controlFunctionOptions(i).value))==0,...
               'Error: Larb file id must be an integer');          
        end

        if(strcmp(controlFunctionName,'Bath'))
          assert(controlFunctionOptions(i).value==1 ...
            || controlFunctionOptions(i).value == 2 ...
            || controlFunctionOptions(i).value == 3,...
            'Error: Bath option must be 1, 2, or 3');
        end
      case 'string'
        unitStr  = controlFunctionOptions(i).unit;
        valueStr = controlFunctionOptions(i).value; 

    end
    
    if(controlFunctionOptions(i).printUnit==1)
      if(i==1)
        commandLine = sprintf('%s%s %s',commandLine,valueStr,unitStr);
      else
        commandLine = sprintf('%s  %s %s',commandLine,valueStr,unitStr);
      end
    else
      if(i==1)
        commandLine = sprintf('%s%s',commandLine,valueStr);
      else
        commandLine = sprintf('%s  %s',commandLine,valueStr);
      end
    end

  end

end





%%
%Update the timing data
%%
endTime       = nan;
nextStartTime = nan;

%%
%Update the meta data
%%

expectedUnits = {''};

switch controlFunctionName
  %Length functions

  case 'Length-Step'
  expectedUnits = {'length'};

  fcnMetaData.meta_data = ...
    struct(      'is_active', isActive,...
    auroraConfig.labels.length, controlFunctionOptionsUpd(1).value,...
           'is_relative', controlFunctionOptionsUpd(1).isRelative);


    commandDuration = auroraConfig.lengthStepResponseTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Length-Ramp'
  expectedUnits = {'length','time'};

  fcnMetaData.meta_data = ...
    struct(        'is_active', isActive,...
    auroraConfig.labels.length, controlFunctionOptionsUpd(1).value,...
                 'is_relative', controlFunctionOptionsUpd(1).isRelative,...
    auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);


    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Length-Square'
    expectedUnits = {'frequency','length','time'};

    fcnMetaData.meta_data = ...
      struct(      'is_active',isActive,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.length, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Length-Sine'
    expectedUnits = {'frequency','length','time'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.length, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Length-Sweep'
    expectedUnits = {'frequency','frequency','length','time'};

    fcnMetaData.meta_data = ...
      struct(       'is_active',isActive,...
     [auroraConfig.labels.frequency,'_start'],...
                    controlFunctionOptionsUpd(1).value,...
     [auroraConfig.labels.frequency,'_end'], ...
                    controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.length, controlFunctionOptionsUpd(3).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(4).value);

    commandDuration = controlFunctionOptionsUpd(4).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Length-Sample'
    expectedUnits = {'integer','time'};

    fcnMetaData.meta_data = ...
      struct(       'is_active',  isActive,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Length-Hold'
    expectedUnits = {'integer'};

    fcnMetaData.meta_data = ...
      struct(       'is_active',  isActive,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Read-Larb'
    expectedUnits = {'string','length','time'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
       auroraConfig.labels.fileName, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.lengthUnit, controlFunctionOptionsUpd(2).unit,...
       auroraConfig.labels.sampleTime, controlFunctionOptionsUpd(3).value);

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Write-Larb'
    expectedUnits = {'string','length','time'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
       auroraConfig.labels.fileName, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.lengthUnit, controlFunctionOptionsUpd(2).unit,...
       auroraConfig.labels.sampleTime, controlFunctionOptionsUpd(3).value);

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Send-Larb'
    expectedUnits = {};
    fcnMetaData.meta_data = [];

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Length-Arb'
    expectedUnits = {'integer','frequency'};

    fcnMetaData.meta_data = ...
      struct(        'is_active', isActive,...
           auroraConfig.labels.waveNumber, controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.frequencyUnit, controlFunctionOptionsUpd(2).value,...
             auroraConfig.labels.fileName, externalFileMetaData.fileName);

    mdField = fields(externalFileMetaData.fields);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;



  %Force functions
  case 'Force-Step'
    expectedUnits = {'force'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
             'is_relative', controlFunctionOptionsUpd(1).isRelative);

    commandDuration = auroraConfig.lengthStepResponseTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Force-Ramp'
    expectedUnits = {'force','time'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
             'is_relative', controlFunctionOptionsUpd(1).isRelative,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Force-Square'
    expectedUnits = {'frequency','force','time'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Force-Sine'
    expectedUnits = {'frequency','force','time'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Force-Sweep'
    expectedUnits = {'frequency','frequency','force','time'};

    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
     [auroraConfig.labels.frequency, '_start'],...
                     controlFunctionOptionsUpd(1).value,...
     [auroraConfig.labels.frequency, '_end'], ...
                     controlFunctionOptionsUpd(2).value,...
       auroraConfig.labels.force,  controlFunctionOptionsUpd(3).value,...
      auroraConfig.labels.duration,  controlFunctionOptionsUpd(4).value);

    commandDuration = controlFunctionOptionsUpd(4).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Force-Sample'
    expectedUnits = {'integer','time'};

    fcnMetaData.meta_data = ...
      struct(       'is_active',  isActive,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Force-Hold'
    expectedUnits = {'integer'};

    fcnMetaData.meta_data = ...
      struct(       'is_active',  isActive,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Force-Clamp'
    expectedUnits = {'force','time','time'};

    fcnMetaData.meta_data = ...
      struct(        'is_active', isActive,...
         auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration  , controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(2).value ...
                    + controlFunctionOptionsUpd(3).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  %SL
  case 'SL-Step'
    expectedUnits = {'length'};

    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
      auroraConfig.labels.length_um, controlFunctionOptionsUpd(1).value);

    commandDuration = auroraConfig.lengthStepResponseTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'SL-Ramp'
    expectedUnits = {'length','time'};
    fcnMetaData.meta_data = ...
      struct(      'is_active', isActive,...
     auroraConfig.labels.length_um, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'SL-Sample'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
     auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'SL-Hold'
    expectedUnits = {'integer'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'SL-Trigger'
    expectedUnits = {'time'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(1).value);

    commandDuration = controlFunctionOptionsUpd(1).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'SL-Track'
    expectedUnits = {'bool'};
    fcnMetaData.meta_data = ...
      struct(       'is_active', isActive,...
     auroraConfig.labels.switchOnOff, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  %Stim
  case 'Stimulus'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(...
        auroraConfig.labels.stimulusPatternNumber, ...
                                      controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.initialDelay,...
                                      controlFunctionOptionsUpd(2).value,...
        auroraConfig.labels.fileName, externalFileMetaData.fileName);

    mdField = fields(externalFileMetaData.fields);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms ...
                    + controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Trigger1'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(auroraConfig.labels.portNumber,'Trigger_Out_1',...
         auroraConfig.labels.triggerPatternNumber,...
                      controlFunctionOptionsUpd(1).value,...
         auroraConfig.labels.initialDelay,...
                      controlFunctionOptionsUpd(2).value,...
        auroraConfig.labels.fileName, externalFileMetaData.fileName);

    mdField = fields(externalFileMetaData.fields);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms ...
                    + controlFunctionOptionsUpd(2).value;

    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Trigger2'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(auroraConfig.labels.portNumber,'Trigger_Out_2',...
         auroraConfig.labels.triggerPatternNumber,...
                      controlFunctionOptionsUpd(1).value,...
         auroraConfig.labels.initialDelay,...
                      controlFunctionOptionsUpd(2).value,...
        auroraConfig.labels.fileName, externalFileMetaData.fileName);

    mdField = fields(externalFileMetaData.fields);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms ...
                    + controlFunctionOptionsUpd(2).value;


  %Control
  case 'Data-Enable'
    expectedUnits = {};
    commandDuration = sampleTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

    programMetaData.dataEnable=1;

  case 'Data-Disable'
    expectedUnits = {};
    commandDuration = sampleTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

    programMetaData.dataEnable=0;


  case 'Data-Burst'
    expectedUnits = {'time','time'};
    fcnMetaData.meta_data = ...
      struct(...
      auroraConfig.labels.initialDelay,controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.duration,controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(1).value ...
                    + controlFunctionOptionsUpd(2).value;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Bath'
    expectedUnits = {'integer','time'};

    fcnMetaData.meta_data = ...
      struct(...
        auroraConfig.labels.bathNumber,controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay,controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value ...
                    + auroraConfig.bath.changeTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;

  case 'Repeat'
    expectedUnits = {'integer','integer'};
    fcnMetaData.meta_data = ...
      struct(...
        auroraConfig.labels.numberOfRepetitions,...
        controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+programMetaData.smallestNextWaitTime;


  case 'Stop'
    expectedUnits = {};

  otherwise
    assert(0,'Error: unrecognized control name');

end

%
% Check that the expected units match the controlFunctionOption units
%

assert(length(expectedUnits)==length(controlFunctionOptionsUpd),...
    ['Error: mismatch in the length of the list of expected units and',...
     ' the length of contronFunctionOptionsUpd']);

if(length(controlFunctionOptionsUpd)>0)
  for i=1:1:length(controlFunctionOptionsUpd)
  if(~isempty(controlFunctionOptionsUpd(i).type))
    assert(strcmp(controlFunctionOptionsUpd(i).type,...
          expectedUnits{i}),...
    ['Error: mismatch between the expected units and the units stored in',...
     ' controlFunctionsOptions']);
  end
  end
end


if(flag_onlyRecordDuringCommand==1)

  disableTime = nextStartTime+auroraConfig.minimumWaitTime;
  timeStr = sprintf('%1.1f',disableTime);

  while length(timeStr)<9
    timeStr = [' ',timeStr];

  dataDisableCommandLine = sprintf('%s\t%s',timeStr,'Data-Disable');

  nextStartTime = nextStartTime+auroraConfig.minimumWaitTime;

  programMetaData.dataEnable=0;  
end

%
% Write the commands
%
if(flag_onlyRecordDuringCommand==1)
  fprintf(fid,'%s\n',dataEnableCommandLine);
end

fprintf(fid,'%s\n',commandLine);

if(flag_onlyRecordDuringCommand==1)
  fprintf(fid,'%s\n',dataDisableCommandLine);
end


%
% Update the command meta data structure
%
fcnMetaData.(auroraConfig.labels.time)=[startTime,endTime];

%
% Update the program meta data
%
assert(~isnan(nextStartTime),'Error: nextStartTime has not been set');

programMetaData.controlFunction.startTime = startTime;
programMetaData.controlFunction.endTime   = endTime;
programMetaData.controlFunction.duration  = commandDuration;

programMetaData.startTime             = startTime;
programMetaData.nextStartTime         = nextStartTime;

programMetaData.lineCount             = programMetaData.lineCount + 1;

fcnMetaData.(auroraConfig.labels.time) = ...
  [programMetaData.controlFunction.startTime,...
   programMetaData.controlFunction.endTime];



%%
% Write the meta data
%%


if(flag_printMetaDataToFile)

    idx=strfind(commandLine,char(9));
    idx=idx+1;
    commandLineShort = commandLine(1,idx:end);

    fprintf(programMetaData.labelFileHandle,'%s,%1.6f,%1.6f,\"%s\"\n',...
            controlFunctionName,...
            programMetaData.controlFunction.startTime,...
            programMetaData.controlFunction.endTime  ,...
            commandLineShort);
end

success= 1;



