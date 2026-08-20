function metaDataFieldNames = getMetaDataFieldNames600A(auroraConfig)

metaDataFieldNames.time   = ...
  ['time_',auroraConfig.defaultTimeUnit];

metaDataFieldNames.cycles ='cycles';

metaDataFieldNames.frequency = ...
  ['frequency_',auroraConfig.defaultFrequencyUnit];

metaDataFieldNames.bandwidth = ...
  ['bandwidth_',auroraConfig.defaultFrequencyUnit];

metaDataFieldNames.amplitude = ...
  ['amplitude_',auroraConfig.defaultLengthUnit]; 

metaDataFieldNames.amplitudeForce = ...
  ['amplitude_',auroraConfig.defaultForceUnit]; 

metaDataFieldNames.length    = ...
  ['length_',auroraConfig.defaultLengthUnit];

%If the unit is explicitly included, then I'm
%breaking the lower camel-case format and using
%snake case to distinguish the unit from all 
%other types of information
metaDataFieldNames.length_um    = ...
  ['length_um'];


metaDataFieldNames.force    = ...
  ['force_',auroraConfig.defaultForceUnit];  

metaDataFieldNames.initialDelay = ...
  ['initial_delay_',auroraConfig.defaultTimeUnit];

metaDataFieldNames.duration = ...
  ['duration_',auroraConfig.defaultTimeUnit];

metaDataFieldNames.sampleNumber = 'sample_number';

metaDataFieldNames.fileName = 'file_name';

metaDataFieldNames.lengthUnit = 'length_unit';

metaDataFieldNames.sampleTime =...
  ['sample_time_',auroraConfig.defaultTimeUnit];

metaDataFieldNames.switchOnOff = ['switch_on_off'];

metaDataFieldNames.waveNumber = ...
  ['wave_number'];

metaDataFieldNames.stimulusPatternNumber = ...
  ['stimulus_pattern_number'];

metaDataFieldNames.triggerPatternNumber = ...
  ['trigger_pattern_number'];

metaDataFieldNames.portNumber=['port_number'];

metaDataFieldNames.bathNumber=['bath_number'];

metaDataFieldNames.numberOfRepetitions=['number_of_repetitions'];

metaDataFieldNames.fileName=['file_name'];