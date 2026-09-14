function [programMetaData,fcnMetaData]= ...
  writeControlFunction600AUpd(...
                fid,...
                startTime,...
                controlFunctionName,...
                controlFunctionOptions,...
                controlFunctionKeywords,...
                externalFileMetaData,...
                auroraConfig,...
                programMetaData,...                
                flag_printMetaDataToCSV)



%options has fields of
% value
% unit
% printUnit

fcnMetaData=getEmptySegmentMetaDataStruct600A(...
              controlFunctionName,...
              auroraConfig);

% fcnMetaData=struct('type',controlFunctionName, ...
%            auroraConfig.labels.time, [nan,nan],...
%            'is_recorded',nan,...
%            'meta_data',[]);

assert(iscell(controlFunctionKeywords),...
  ['Error: controlFunctionKeywords must be a cell even if it is empty']);

assert(strcmp(auroraConfig.defaultTimeUnit,'ms'),...
    'Error: auroraConfig.defaultTimeUnit and startTime must be in ms');

if(~isempty(externalFileMetaData))
  assert(isfield(externalFileMetaData,'duration_s'),...
         'Error: externalFileMetaData must have a duration_s field');

  assert(isfield(externalFileMetaData.meta_data,'file'),...
         'Error: externalFileMetaData must have a file field');

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


[startTime,timeStr]=...
  convertToAuroraFloatingPointFormat600A(...
    startTime,'time',auroraConfig.defaultTimeUnit,0,auroraConfig);

endTime = str2double(timeStr);
while length(timeStr)<9
  timeStr = [' ',timeStr];
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

    if(strcmp(controlFunctionOptions(i).unit,'string'))

      unitStr  = controlFunctionOptions(i).unit;
      valueStr = controlFunctionOptions(i).value; 
      %No update required to controlFunctionOptionsUpd

    else

      [value, valueStr] = convertToAuroraFloatingPointFormat600A(...
                            controlFunctionOptions(i).value,...
                            controlFunctionOptions(i).type,...
                            controlFunctionOptions(i).unit,...
                            controlFunctionOptions(i).isRelative,...
                            auroraConfig);

      if(strcmp(controlFunctionOptions(i).type,'time'))
        assert(strcmp(controlFunctionOptions(i).unit,'ms'),...
          ['Error: all times should be in ms for now.',...
           ' This function has not been tested using units of s.']);
      end

      unitStr = controlFunctionOptions(i).unit;
      controlFunctionOptionsUpd(i).value = value;
    end

    %
    % Do some basic error checking on the inputs
    %
    switch controlFunctionOptions(i).type

      case 'bool'
        assert(controlFunctionOptions(i).value==0 ...
          || controlFunctionOptions(i).value==1,...
             'Error: bool type must be 0 or 1');
        controlFunctionOptionsUpd(i).value = str2double(valueStr);

      case 'integer'
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
           || strcmp(controlFunctionName,'SL-Sample') ...
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

          assert(controlFunctionOptions(i).value >= 1 ...
              && controlFunctionOptions(i).value <= 8,...
              'Error: the 600A only has 8 wells');
          assert(abs(controlFunctionOptions(i).value...
              -round(controlFunctionOptions(i).value))==0,...
               'Error: Bath number must be an integer');

        end
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

%
% Write the command
%
fprintf(fid,'%s\n',commandLine);




%%
%Update the timing data
%%
endTime       = nan;
nextStartTime = nan;


%%
%Update the meta data
%%

expectedUnits = {''};

if(strcmp(controlFunctionName,'Bath'))
  programMetaData.bathNumber=controlFunctionOptionsUpd(1).value;
end

bathNameLabel   = auroraConfig.labels.bathName;
bathName        = auroraConfig.labels.bathNames{programMetaData.bathNumber};

isFcnMetaDataComplete = 0;

switch controlFunctionName
  %Length functions

  case 'Length-Step'
  expectedUnits = {'length'};

  fcnMetaData.meta_data = ...
    struct(      bathNameLabel, bathName,...
    auroraConfig.labels.length, controlFunctionOptionsUpd(1).value,...
           'is_relative', controlFunctionOptionsUpd(1).isRelative);

    commandDuration = auroraConfig.lengthStepResponseTime;


  case 'Length-Ramp'
    expectedUnits = {'length','time'};
  

    assert(controlFunctionOptionsUpd(2).value ...
               >= auroraConfig.minimumCommandDuration,...
           ['Error: Length-Ramp duration must be at least one ',...
            'sample time in duration']);
  
    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
      auroraConfig.labels.length, controlFunctionOptionsUpd(1).value,...
                   'is_relative', controlFunctionOptionsUpd(1).isRelative,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);
  
      commandDuration = controlFunctionOptionsUpd(2).value;    

  case 'Length-Square'
    expectedUnits = {'frequency','length','time'};

    assert(controlFunctionOptionsUpd(3).value ...
            >= auroraConfig.minimumCommandDuration,...
           ['Error: Length-Square duration must be at least one ',...
            'sample time in duration']);


    fcnMetaData.meta_data = ...
      struct(        bathNameLabel, bathName,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.length, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

  case 'Length-Sine'
    expectedUnits = {'frequency','length','time'};

    assert(controlFunctionOptionsUpd(3).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Length-Sine duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(        bathNameLabel, bathName,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.length, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

  case 'Length-Sweep'
    expectedUnits = {'frequency','frequency','length','time'};

    assert(controlFunctionOptionsUpd(4).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Length-Sweep duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     [auroraConfig.labels.frequency,'_start'],...
                    controlFunctionOptionsUpd(1).value,...
     [auroraConfig.labels.frequency,'_end'], ...
                    controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.length, controlFunctionOptionsUpd(3).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(4).value);

    commandDuration = controlFunctionOptionsUpd(4).value;

  case 'Length-Sample'
    expectedUnits = {'integer','time'};

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value+sampleTime;

  case 'Length-Hold'
    expectedUnits = {'integer'};

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

  case 'Read-Larb'
    expectedUnits = {'string','length','time'};

    assert(controlFunctionOptionsUpd(3).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Read-Larb duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
       auroraConfig.labels.fileName, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.lengthUnit, controlFunctionOptionsUpd(2).unit,...
       auroraConfig.labels.sampleTime, controlFunctionOptionsUpd(3).value);

    commandDuration = sampleTime;

  case 'Write-Larb'
    expectedUnits = {'string','length','time'};
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
       auroraConfig.labels.fileName, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.lengthUnit, controlFunctionOptionsUpd(2).unit,...
       auroraConfig.labels.sampleTime, controlFunctionOptionsUpd(3).value);

    commandDuration = sampleTime;

  case 'Send-Larb'
    expectedUnits = {};
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName);

    commandDuration = sampleTime;

  case 'Length-Arb'
    expectedUnits = {'integer','frequency'};

    mdField ={'bandwidth_Hz','amplitude_Lo','point_count','frequency_Hz'};
    extMdField = fields(externalFileMetaData.meta_data);
    if(length(mdField)==length(extMdField))
      for idxF = 1:1:length(mdField)
        assert(strcmp(mdField{idxF},extMdField{idxF}),...
          ['Error: meta_data fields in externalFileMetaData ',...
          'do not match the expected fields']);
      end
    end

    if(length(externalFileMetaData.meta_data.amplitude_Lo)==1)

%       fcnMetaData.meta_data = ...
%         struct(               ...
%                           bathNameLabel, bathName,...
%          auroraConfig.labels.waveNumber, controlFunctionOptionsUpd(1).value,...
%           auroraConfig.labels.frequency, controlFunctionOptionsUpd(2).value,...
%            auroraConfig.labels.fileName, '',...
%            'bandwidth_Hz', externalFileMetaData.meta_data.bandwidth_Hz,...
%            'amplitude_Lo', externalFileMetaData.meta_data.amplitude_Lo,...
%            'point_count',  externalFileMetaData.meta_data.point_count);
%   
%       fcnMetaData.meta_data.(auroraConfig.labels.fileName) = ...
%         externalFileMetaData.file;
      fcnMetaData.meta_data = ...
        struct(               ...
                          bathNameLabel, bathName,...
         auroraConfig.labels.waveNumber, controlFunctionOptionsUpd(1).value,...
          auroraConfig.labels.frequency, controlFunctionOptionsUpd(2).value);
  
      mdField = fields(externalFileMetaData.meta_data);
      for idxF = 1:1:length(mdField)
        fcnMetaData.meta_data.(mdField{idxF}) ...
          = externalFileMetaData.meta_data.(mdField{idxF});
      end
  
      assert(~isempty(externalFileMetaData.duration_s),...
             'Error: externalFileMetaData.duration_s must contain data');    
      assert(~isnan(externalFileMetaData.duration_s),...
             'Error: externalFileMetaData.duration_s must contain data');
      assert(~isinf(externalFileMetaData.duration_s),...
             'Error: externalFileMetaData.duration_s must contain data');
  
      commandDuration = externalFileMetaData.duration_s*s2ms;
    else
      %
      % The Length-Arb data contains several different sections, each
      % with different meta data
      %
      labelBw = auroraConfig.labels.bandwidth;
      labelLo = auroraConfig.labels.amplitude;
      labelFrequency=auroraConfig.labels.frequency;
      labelPoints=auroraConfig.labels.pointCount;

      
      segStartTime=startTime;
      segEndTime=nan;
      segDuration=nan;

      fcnMetaDataEmpty=fcnMetaData;
      fcnMetaDataSet=[];
      commandDuration=0;

      numberLArbSeg=length(externalFileMetaData.meta_data.(labelBw));

      for idxLArb=1:1:numberLArbSeg

        ampLo = externalFileMetaData.meta_data.(labelLo)(idxLArb);
        segPoints=externalFileMetaData.meta_data.(labelPoints)(idxLArb);
        segFrequency=externalFileMetaData.meta_data.(labelFrequency)(idxLArb);
        segDuration=(segPoints/segFrequency)*s2ms;
        segEndTime = segStartTime+segDuration;

        commandDuration = commandDuration+segDuration;

        if(abs(ampLo)>1e-6)
          fcnMetaDataSeg = fcnMetaDataEmpty;
          fcnMetaDataSeg.type = 'Length-Arb';
          fcnMetaDataSeg.(auroraConfig.labels.time)=[segStartTime,segEndTime];
          fcnMetaDataSeg.is_recorded = programMetaData.dataEnable;
          fcnMetaDataSeg.meta_data = ...
            struct(               ...
                              bathNameLabel, bathName,...
             auroraConfig.labels.waveNumber, controlFunctionOptionsUpd(1).value,...
              auroraConfig.labels.frequency, controlFunctionOptionsUpd(2).value);
      
          mdField = fields(externalFileMetaData.meta_data);
          for idxF = 1:1:length(mdField)
            if(length(externalFileMetaData.meta_data.(mdField{idxF}))==numberLArbSeg)
              fcnMetaDataSeg.meta_data.(mdField{idxF}) ...
                = externalFileMetaData.meta_data.(mdField{idxF})(idxLArb);
            else
              fcnMetaDataSeg.meta_data.(mdField{idxF}) ...
                = externalFileMetaData.meta_data.(mdField{idxF});
            end
          end

          if(isempty(fcnMetaDataSet))
            fcnMetaDataSet=fcnMetaDataSeg;
          else
            fcnMetaDataSet=[fcnMetaDataSet,fcnMetaDataSeg];
          end


        end
        
        segStartTime=segEndTime;
      end

      fcnMetaData=fcnMetaDataSet;
      isFcnMetaDataComplete=1;
    end


  %Force functions
  case 'Force-Step'
    expectedUnits = {'force'};
    
    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
             'is_relative', controlFunctionOptionsUpd(1).isRelative);

    commandDuration = auroraConfig.lengthStepResponseTime;

  case 'Force-Ramp'
    expectedUnits = {'force','time'};

    assert(controlFunctionOptionsUpd(2).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Force-Ramp duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
             'is_relative', controlFunctionOptionsUpd(1).isRelative,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

  case 'Force-Square'
    expectedUnits = {'frequency','force','time'};

    assert(controlFunctionOptionsUpd(3).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Force-Square duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
     auroraConfig.labels.force, controlFunctionOptionsUpd(2).value,...
     auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

  case 'Force-Sine'
    expectedUnits = {'frequency','force','time'};

    assert(controlFunctionOptionsUpd(3).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Force-Sine duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
     auroraConfig.labels.frequency, controlFunctionOptionsUpd(1).value,...
       auroraConfig.labels.force, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(3).value;

  case 'Force-Sweep'
    expectedUnits = {'frequency','frequency','force','time'};

    assert(controlFunctionOptionsUpd(4).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Force-Sweep duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     [auroraConfig.labels.frequency, '_start'],...
                     controlFunctionOptionsUpd(1).value,...
     [auroraConfig.labels.frequency, '_end'], ...
                     controlFunctionOptionsUpd(2).value,...
       auroraConfig.labels.force,  controlFunctionOptionsUpd(3).value,...
      auroraConfig.labels.duration,  controlFunctionOptionsUpd(4).value);

    commandDuration = controlFunctionOptionsUpd(4).value;

  case 'Force-Sample'
    expectedUnits = {'integer','time'};

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value+sampleTime;

  case 'Force-Hold'
    expectedUnits = {'integer'};

    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
      auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

  case 'Force-Clamp'
    expectedUnits = {'force','time','time'};

    assert(controlFunctionOptionsUpd(3).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: Force-Clamp duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(        bathNameLabel, bathName,...
         auroraConfig.labels.force, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value,...
      auroraConfig.labels.duration  , controlFunctionOptionsUpd(3).value);

    commandDuration = controlFunctionOptionsUpd(2).value ...
                    + controlFunctionOptionsUpd(3).value;

  %SL
  case 'SL-Step'
    expectedUnits = {'length'};

    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
      auroraConfig.labels.length_um, controlFunctionOptionsUpd(1).value);

    commandDuration = auroraConfig.lengthStepResponseTime;

  case 'SL-Ramp'
    expectedUnits = {'length','time'};

    assert(controlFunctionOptionsUpd(2).value ...
           >= auroraConfig.minimumCommandDuration,...
               ['Error: SL-Ramp duration must be at least one ',...
                'sample time in duration']);

    fcnMetaData.meta_data = ...
      struct(      bathNameLabel, bathName,...
     auroraConfig.labels.length_um, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value;

  case 'SL-Sample'
    expectedUnits = {'integer','time'};
    
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     auroraConfig.labels.sampleNumber, controlFunctionOptionsUpd(1).value,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value+sampleTime;

  case 'SL-Hold'
    expectedUnits = {'integer'};
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(1).value);

    commandDuration = controlFunctionOptionsUpd(1).value+sampleTime;

  case 'SL-Trigger'
    expectedUnits = {'time'};
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(1).value);

    commandDuration = controlFunctionOptionsUpd(1).value+sampleTime;

  case 'SL-Track'
    expectedUnits = {'bool'};
    fcnMetaData.meta_data = ...
      struct(       bathNameLabel, bathName,...
     auroraConfig.labels.switchOnOff, controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;

  %Stim
  case 'Stimulus'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(...
                        bathNameLabel, bathName,...
        auroraConfig.labels.stimulusPatternNumber, ...
                                      controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.initialDelay,...
                                      controlFunctionOptionsUpd(2).value);

    mdField = fields(externalFileMetaData.meta_data);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.meta_data.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms ...
                    + controlFunctionOptionsUpd(2).value;

  case 'Trigger1'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(             bathNameLabel, bathName,...
         auroraConfig.labels.portNumber,'Trigger_Out_1',...
         auroraConfig.labels.triggerPatternNumber,...
                      controlFunctionOptionsUpd(1).value,...
         auroraConfig.labels.initialDelay,...
                      controlFunctionOptionsUpd(2).value);

    mdField = fields(externalFileMetaData.meta_data);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.meta_data.(mdField{idxF});
    end


    assert(~isempty(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');    
    assert(~isnan(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');
    assert(~isinf(externalFileMetaData.duration_s),...
           'Error: externalFileMetaData.duration_s must contain data');

    commandDuration = externalFileMetaData.duration_s*s2ms ...
                    + controlFunctionOptionsUpd(2).value;

  case 'Trigger2'
    expectedUnits = {'integer','time'};
    fcnMetaData.meta_data = ...
      struct(            bathNameLabel, bathName,...
        auroraConfig.labels.portNumber,'Trigger_Out_2',...
        auroraConfig.labels.triggerPatternNumber,...
                      controlFunctionOptionsUpd(1).value,...
        auroraConfig.labels.initialDelay,...
                      controlFunctionOptionsUpd(2).value);

    mdField = fields(externalFileMetaData.meta_data);
    for idxF = 1:1:length(mdField)
      fcnMetaData.meta_data.(mdField{idxF}) ...
        = externalFileMetaData.meta_data.(mdField{idxF});
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
    fcnMetaData.meta_data = struct( bathNameLabel, bathName);

    commandDuration = sampleTime;

    assert(programMetaData.dataEnable==0,...
      'Error: attempted to call Data-Enable twice');

    programMetaData.dataEnable=1;

    programMetaData.totalIgnoredTime = ...
      programMetaData.totalIgnoredTime ...
      + (startTime-programMetaData.timeOfLastDisable);
    programMetaData.timeOfLastEnable=startTime;


  case 'Data-Disable'
    expectedUnits = {};
    fcnMetaData.meta_data = struct( bathNameLabel, bathName);

    commandDuration = sampleTime;
    endTime       = startTime+commandDuration;
    nextStartTime = endTime+auroraConfig.minimumWaitTime;

    assert(programMetaData.dataEnable==1,...
      'Error: attempted to call Data-Disable twice');

    programMetaData.dataEnable=0;

    programMetaData.totalRecordedTime = ...
      programMetaData.totalRecordedTime ...
      + (startTime-programMetaData.timeOfLastEnable);
    programMetaData.timeOfLastDisable=startTime;


  case 'Data-Burst'
    expectedUnits = {'time','time'};

    assert(controlFunctionOptionsUpd(2).value ...
           >= auroraConfig.minimumCommandDuration,...
           ['Error: Data-Burst duration must be at least one ',...
            'sample time in duration']);


    assert(programMetaData.dataEnable==0,...
      'Error: attempted to call Data-Burst when Data-Enable has been called');
    
    fcnMetaData.meta_data = ...
      struct(            bathNameLabel, bathName,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(1).value,...
          auroraConfig.labels.duration, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(1).value ...
                    + controlFunctionOptionsUpd(2).value;

    programMetaData.totalRecordedTime = ...
      programMetaData.totalRecordedTime ...
      + controlFunctionOptionsUpd(2).value;

    programMetaData.totalIgnoredTime = ...
      programMetaData.totalIgnoredTime ...
      + controlFunctionOptionsUpd(1).value;


    programMetaData.timeOfLastEnable=...
      startTime+controlFunctionOptionsUpd(1).value;
    programMetaData.timeOfLastDisable=...
      startTime +controlFunctionOptionsUpd(1).value...
                +controlFunctionOptionsUpd(2).value;
    
    programMetaData.dataBurstStartTime=...
        startTime+controlFunctionOptionsUpd(1).value;

    programMetaData.dataBurstEndTime=...
        programMetaData.dataBurstStartTime...
        +controlFunctionOptionsUpd(2).value;

  case 'Bath'
    expectedUnits = {'integer','time'};

    programMetaData.bathNumber = controlFunctionOptionsUpd(1).value;
    bathName = auroraConfig.labels.bathNames{programMetaData.bathNumber};

    fcnMetaData.meta_data = ...
      struct(            bathNameLabel, bathName,...
        auroraConfig.labels.bathNumber, controlFunctionOptionsUpd(1).value,...
      auroraConfig.labels.initialDelay, controlFunctionOptionsUpd(2).value);

    commandDuration = controlFunctionOptionsUpd(2).value ...
                    + auroraConfig.bath.changeTime;

  case 'Repeat'
    expectedUnits = {'integer','integer'};
    fcnMetaData.meta_data = ...
      struct( bathNameLabel, ...
                bathName,...
              auroraConfig.labels.numberOfRepetitions, ...
                controlFunctionOptionsUpd(1).value);

    commandDuration = sampleTime;
 
  case 'Stop'
    expectedUnits = {};
    fcnMetaData.meta_data =  struct( bathNameLabel, bathName);

    commandDuration = sampleTime;
    
  otherwise
    assert(0,'Error: unrecognized control name');

end

%
% Check that the expected units match the controlFunctionOption units
%

assert(length(expectedUnits)==length(controlFunctionOptionsUpd),...
    ['Error: mismatch in the length of the list of expected units and',...
     ' the length of contronFunctionOptionsUpd']);

if(~isempty(controlFunctionOptionsUpd))
  for i=1:1:length(controlFunctionOptionsUpd)
    if(~isempty(controlFunctionOptionsUpd(i).type))
      assert(strcmp(controlFunctionOptionsUpd(i).type,...
            expectedUnits{i}),...
      ['Error: mismatch between the expected units and the units stored in',...
       ' controlFunctionsOptions']);
    end
  end
end






%
% Update the command meta data structure
%
[commandDuration,commandDurationStr] = ...
  convertToAuroraFloatingPointFormat600A(...
    commandDuration,'time',auroraConfig.defaultTimeUnit,0,auroraConfig);

endTime       = startTime+commandDuration;

[endTime,endTimeStr] = ...
  convertToAuroraFloatingPointFormat600A(...
    endTime,'time',auroraConfig.defaultTimeUnit,0,auroraConfig);

nextStartTime = endTime+auroraConfig.minimumWaitTime;

[nextStartTime,nextStartTimeStr] = ...
  convertToAuroraFloatingPointFormat600A(...
    nextStartTime,'time',auroraConfig.defaultTimeUnit,0,auroraConfig);

if(~isempty(controlFunctionKeywords))
  assert(~isempty(controlFunctionKeywords{1}));
  if(length(fcnMetaData)>1)
    for idxA=1:1:length(fcnMetaData)
      fcnMetaData(idxA).meta_data.keywords=controlFunctionKeywords;
    end
  else
    fcnMetaData.meta_data.keywords=controlFunctionKeywords;
  end
end

if(isFcnMetaDataComplete==0)
  fcnMetaData.(auroraConfig.labels.time)=[startTime,endTime];
  fcnMetaData.is_recorded=programMetaData.dataEnable;
end
  
if(   ( startTime >= programMetaData.dataBurstStartTime ...
     && startTime <= programMetaData.dataBurstEndTime) ... 
     ||  ( endTime >= programMetaData.dataBurstStartTime ...
     &&    endTime <= programMetaData.dataBurstEndTime) )

  if(isFcnMetaDataComplete==0)
    fcnMetaData.is_recorded=1;
  end
end


%Issue a warning if this segment straddles a data burst
if(    (startTime < programMetaData.dataBurstStartTime ...
    &&    endTime > programMetaData.dataBurstStartTime ... 
    &&    endTime < programMetaData.dataBurstEndTime) ... 
    || (startTime > programMetaData.dataBurstStartTime ...
    &&  startTime < programMetaData.dataBurstEndTime ... 
    &&    endTime > programMetaData.dataBurstEndTime) ...
    || (startTime < programMetaData.dataBurstStartTime ...
    &&   endTime > programMetaData.dataBurstEndTime) )

  fprintf(['\nWarning: segment time (%1.1f,%1.1f) is not contained ',...
           'within Data-Burst interval (%1.1f,%1.1f)\n'],...
           startTime,endTime,...
           programMetaData.dataBurstStartTime,...
           programMetaData.dataBurstEndTime);

  if(isFcnMetaDataComplete==0)
    fcnMetaData.is_recorded=0.5;
  end
    
end


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

if(isFcnMetaDataComplete==0)
  fcnMetaData.(auroraConfig.labels.time) = ...
    [programMetaData.controlFunction.startTime,...
     programMetaData.controlFunction.endTime];
end


%%
% Write the meta data
%%


if(flag_printMetaDataToCSV==1)

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



