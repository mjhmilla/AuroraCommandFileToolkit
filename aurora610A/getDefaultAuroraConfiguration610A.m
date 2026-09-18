function auroraConfig =  getDefaultAuroraConfiguration610A(...  
                            isTwitchAvailable,...
                            sampleFrequencyHz,...
                            specimenLceOptInMM,...                                                        
                            maxNormalizedSpeedLPS,...
                            verbose)

%disp('Aurora Configuration for the 305B-LR');

auroraConfig.isTwitchAvailable=isTwitchAvailable;

auroraConfig.model = '305B-LR';

auroraConfig.maximumTrialDurationInSeconds = 300;
%This is needed for the book keeping involved in generating
%time-series data for the protocol when Stimulus-Train is called,
%as this command does not end.

auroraConfig.approximateSampleLengthInDefaultUnits = ...
    specimenLceOptInMM;


%https://aurorascientific.com/products/muscle-physiology/controllers-levers-transducers/300e-dual-mode-muscle-levers/
%We are using the 300E

auroraConfig.maximumRampSpeedInLPS = maxNormalizedSpeedLPS;
auroraConfig.maximumRampSpeedInMMPS = ...
    maxNormalizedSpeedLPS*(specimenLceOptInMM);

auroraConfig.maximumSpeedInMMPS = 20/0.002;
auroraConfig.maximumSpeedInLPS = auroraConfig.maximumRampSpeedInLPS;


auroraConfig.analogToDigitalSampleRateHz = sampleFrequencyHz;
%  This is the rate Aurora's A/D converter will sample signals


auroraConfig.lengthStepResponseTime = 0.002*2;  
%
% From the manual:
%   INSTRUCTION MANUAL
%   Models
%   300B, 300B-LR, 305B, 305B-LR,
%   309B, 310B, 310B-LR
%   Dual-Mode Lever Arm Systems
%
% We have the 305B-LR which has a step response time (1%-99%) of 2 ms.
% I'm doubling that value here just to be safe
%

auroraConfig.maximumLengthChangeInMM = 10;
auroraConfig.scaleLengthUnitsToMM = 1;

%disp('  Note: Find the maximum of commands for the 300E');
auroraConfig.maximumNumberOfCommands = 945;


auroraConfig.unitSystem = 'mm_mN_s_Hz';

assert(strcmp(auroraConfig.unitSystem,'mm_mN_s_Hz'),...
       'Error: Ref_s_Hz is untested on the 610A');

switch auroraConfig.unitSystem
    case 'mm_mN_s_Hz'
        auroraConfig.defaultLengthUnit      = 'mm';
        auroraConfig.defaultForceUnit       = 'mN';
        auroraConfig.defaultTimeUnit        = 's';
        auroraConfig.defaultPulseWidthTimeUnit = 'ms';
        auroraConfig.defaultFrequencyUnit   = 'Hz';

        auroraConfig.approximateSampleLengthInDefaultUnits = ...
            specimenLceOptInMM;

        auroraConfig.maximumSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInMMPS; %mm/s

        auroraConfig.maximumRampSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInMMPS; %mm/s

        auroraConfig.maximumLengthChangeInDefaultUnits = ...
            auroraConfig.maximumLengthChangeInMM;
        auroraConfig.scaleLengthUnitsToMM = 1;            

    case 'Ref_s_Hz'
        auroraConfig.defaultLengthUnit      = 'Ref';
        auroraConfig.defaultForceUnit       = 'Ref';
        auroraConfig.defaultTimeUnit        = 's';
        auroraConfig.defaultPulseWidthTimeUnit = 'ms';
        auroraConfig.defaultFrequencyUnit   = 'Hz';

        auroraConfig.approximateSampleLengthInDefaultUnits = 1;

        auroraConfig.maximumSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInLPS;

        auroraConfig.maximumRampSpeedInDefaultUnits = ...
            auroraConfig.maximumRampSpeedInLPS;

        auroraConfig.maximumLengthChangeInDefaultUnits = ...
            auroraConfig.maximumLengthChangeInMM ...
            ./ specimenLceOptInMM;
        auroraConfig.scaleLengthUnitsToMM = specimenLceOptInMM;            


end

assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
       ['Error: many functions in the 610 only accept seconds',... 
        ' seconds must be the default time unit']);

auroraConfig.labels = getMetaDataFieldNames610A(auroraConfig);

if(verbose==1)
    settingsFields = fields(auroraConfig);
    %fprintf('getDefaultAuroraConfiguration610A\n')
    for idxF = 1:1:length(settingsFields)

      param = auroraConfig.(settingsFields{idxF});
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        if(ischar(param))
          fprintf('\t%s\t%s\n',param,settingsFields{idxF});
        end
        if(isstruct(param))
          fprintf('\n\t.%s\t\t%s\n',settingsFields{idxF},'(struct)');
          subFields = fields(auroraConfig.(settingsFields{idxF}));
          for idxJ = 1:1:length(subFields)
            subParam = auroraConfig.(settingsFields{idxF}).(subFields{idxJ});
            if(isnumeric(subParam))
              fprintf('\t%1.1f\t\t%s.%s\n',subParam,...
                settingsFields{idxF},subFields{idxJ});              
            end
            if(ischar(subParam))
              fprintf('\t%s\t\t%s.%s\n',subParam,...
                settingsFields{idxF},subFields{idxJ});                            
            end
          end
        end
      end
    end
    fprintf('\n\n');
end

