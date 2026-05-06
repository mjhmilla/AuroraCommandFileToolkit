function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createRampSineWavePattern610A(...
                                fcnMeanValue,...
                                config,...
                                frequencyHzRangeInput,...
                                amplitudeInput,...
                                functionOption,...
                                auroraConfig)


lengthStepTimeError = ...
  (round(auroraConfig.lengthStepResponseTime ...
        *auroraConfig.analogToDigitalSampleRateHz) ...
        /auroraConfig.analogToDigitalSampleRateHz) ...
        -auroraConfig.lengthStepResponseTime;

assert(abs(lengthStepTimeError) < 1e-8,...
       'Error: lengthStepResponseTime is not a multiple of the sample rate');

minPeriodTime = auroraConfig.lengthStepResponseTime*3;


numWaves      = 2;
duration      = 0;
freqDistPower = 2/3;
scaleFrequencyRange=1;

while(duration < config.duration)

  numWaves=numWaves+1;


  if(length(frequencyHzRangeInput)>1)
    normFreq = (([1:1:numWaves]').^freqDistPower) ;
    normFreq = normFreq./max(normFreq);
  
    randomFrequencyVec = ...
      normFreq.*(scaleFrequencyRange*frequencyHzRangeInput(1,2)...
                -frequencyHzRangeInput(1,1))...
                +frequencyHzRangeInput(1,1);
  else
    randomFrequencyVec = ones(numWaves,1).*frequencyHzRangeInput(1,1);
  end

  randomPeriodVec = 1./randomFrequencyVec;
  randomPeriodVec = ...
    round(randomPeriodVec*auroraConfig.analogToDigitalSampleRateHz)...
         /auroraConfig.analogToDigitalSampleRateHz;
  randomFrequencyVec = 1./randomPeriodVec;

  durationVec = 1./randomFrequencyVec;
  durationVec( durationVec < minPeriodTime) = minPeriodTime;    


  duration = sum(durationVec);

end

numWaves=numWaves-1;

if(length(frequencyHzRangeInput)>1)
  normFreq = (([1:1:numWaves]').^freqDistPower) ;
  normFreq = normFreq./max(normFreq);
  
  randomFrequencyVec = ...
    normFreq.*( scaleFrequencyRange*frequencyHzRangeInput(1,2) ...
               -frequencyHzRangeInput(1,1))...
              +frequencyHzRangeInput(1,1);
else
    randomFrequencyVec = ones(numWaves,1).*frequencyHzRangeInput(1,1);
end

randomPeriodVec = 1./randomFrequencyVec;
randomPeriodVec = ...
  round(randomPeriodVec.*auroraConfig.analogToDigitalSampleRateHz)...
  ./auroraConfig.analogToDigitalSampleRateHz;

randomPeriodVec( randomPeriodVec < minPeriodTime) = minPeriodTime;

randomFrequencyVec = 1./randomPeriodVec;

duration = sum(1./randomFrequencyVec);

%Generate the signal
timeVecDense    = zeros(numWaves*4+4,1);
signalVecDense  = zeros(numWaves*4+4,1);

%%
% Scramble the frequency vector
%%

if(length(frequencyHzRangeInput)>1)
  rng(3,'twister');
  randomFrequencyVec = randomFrequencyVec(randperm(length(randomFrequencyVec)));
end

n=(length(randomFrequencyVec)*2+1)+2;

%Vectors to generate the Aurora commands
waitVecOutput      = zeros(n,1);
rampVecTimeOutput  = zeros(n,1);
lengthVecOutput    = zeros(n,1);
timeVecOutput      = zeros(n,1);


timeVecSum   = 0;


assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
    'Error: auroraConfig.defaultTimeUnit must be s');

endTime     = config.duration + 2*config.paddingDuration;
endSineTime = config.duration +   config.paddingDuration;

%
% First move: padding
%

i=1;
timeVecDense(i,1)    =0;
signalVecDense(i,1)  =fcnMeanValue(timeVecDense(i,1));

i=i+1;

timeVecDense(i,1)    =timeVecDense(i-1,1)+config.paddingDuration ...
                      -minPeriodTime;
signalVecDense(i,1)  =fcnMeanValue(timeVecDense(i,1));

i = i+1;

j = 1;
waitVecOutput(j,1)      = 0.5*(config.paddingDuration-minPeriodTime);
rampVecTimeOutput(j,1)  = 0.5*(config.paddingDuration-minPeriodTime);

timeVecOutput(j,1)      = timeVecSum + waitVecOutput(j,1)+rampVecTimeOutput(j,1);
timeVecSum              = timeVecSum + waitVecOutput(j,1)+rampVecTimeOutput(j,1);
lengthVecOutput(j,1)    = fcnMeanValue(timeVecSum);

j = j+1;

k = 0; %wave number


sampleFrequencyHz = auroraConfig.analogToDigitalSampleRateHz;





while k < length(randomFrequencyVec)

%     %If the dense time sample vector is too small, double its size
%     if(length(timeVecDense) < (i+m))
%         timeVecDense   =[timeVecDense; zeros(size(timeVecDense))];
%         signalVecDense =[signalVecDense; zeros(size(signalVecDense))];        
%     end



    k=k+1;
    frequencyInput = randomFrequencyVec(k,1);    
    durationInput  = 1/frequencyInput;


    rampTime       = round(0.25*durationInput*sampleFrequencyHz) ...
                          /sampleFrequencyHz;
    waitTime       = round(0.25*durationInput*sampleFrequencyHz) ...
                          /sampleFrequencyHz;


    if(rampTime < auroraConfig.lengthStepResponseTime)
      rampTime = auroraConfig.lengthStepResponseTime;
    end
    if(waitTime < auroraConfig.lengthStepResponseTime)
      waitTime = auroraConfig.lengthStepResponseTime;
    end    
    
    amplitude = amplitudeInput(1,1);
    if(length(amplitudeInput)>1)
      amplitude = amplitudeInput(k,1);
    end

    %%
    % Generate the command vector
    %%
    %if(k==1)
    %  prevWaitTime = minPeriodTime;      
    %else
    %  prevWaitTime = waitVecOutput(j-1,1);      
    %end 
%     if(prevWaitTime < auroraConfig.lengthStepResponseTime)
%       prevWaitTime = auroraConfig.lengthStepResponseTime;
%     end    

    
    waitVecOutput(j,1)        = waitTime;
    rampVecTimeOutput(j,1)    = rampTime;

    timeVecOutput(j,1)        = timeVecSum+waitVecOutput(j,1)+rampVecTimeOutput(j,1);    
    timeVecSum                = timeVecSum+waitVecOutput(j,1)+rampVecTimeOutput(j,1);
    meanLengthInput           = fcnMeanValue(timeVecSum);   

    if(isnan(meanLengthInput))
      here=1;
    end
    assert(~isnan(meanLengthInput));
    lengthVecOutput(j,1)      = 0.5*amplitude + meanLengthInput;
    
    j=j+1;  
    
    waitVecOutput(j,1)        = waitTime;
    rampVecTimeOutput(j,1)    = rampTime;

    timeVecOutput(j,1)        = timeVecSum+waitVecOutput(j,1)+rampVecTimeOutput(j,1);    
    timeVecSum                = timeVecSum+waitVecOutput(j,1)+rampVecTimeOutput(j,1);
    meanLengthInput           = fcnMeanValue(timeVecSum);   

    assert(~isnan(meanLengthInput));    
    if(k==length(randomFrequencyVec))
      lengthVecOutput(j,1)      = meanLengthInput;
    else    
      lengthVecOutput(j,1)      = -0.5*amplitude + meanLengthInput;
    end

    j=j+1;


    %%
    %Generate a densely sampled sine wave
    %%
    assert(i <= length(signalVecDense));

    timeVecDense(i,1)   = timeVecDense(i-1,1) + waitVecOutput(j-2,1);

%     if(k==1)
%       timeVecDense(i,1)   = timeVecDense(i-1,1) + waitVecOutput(j-2,1);
%     end

    signalVecDense(i,1) = lengthVecOutput(j-3,1);    
    i=i+1;

    timeVecDense(i,1)   = timeVecDense(i-1,1) + rampVecTimeOutput(j-2,1);
    signalVecDense(i,1) = lengthVecOutput(j-2,1);    
    i=i+1;

    timeVecDense(i,1)   = timeVecDense(i-1,1) + waitVecOutput(j-1,1);
    signalVecDense(i,1) = lengthVecOutput(j-2,1);    
    i=i+1;

    timeVecDense(i,1)   = timeVecDense(i-1,1) + rampVecTimeOutput(j-1,1);
    signalVecDense(i,1) = lengthVecOutput(j-1,1);    
    i=i+1;

    if(abs(timeVecDense(i-1,1)-timeVecSum)>1e-6)
      here=1;
    end
    assert( abs(timeVecDense(i-1,1)-timeVecSum)<1e-6);

        
end


%%
% Add the padding interval
%%
timeVecDense(i,1) = timeVecDense(i-1,1)+auroraConfig.lengthStepResponseTime;
signalVecDense(i,1) = fcnMeanValue(endTime);

i=i+1;
timeVecDense(i,1) = endTime;
signalVecDense(i,1) = fcnMeanValue(endTime);


assert(i==length(timeVecDense));

%%
% Resample the time domain signal using the configuration of the
% perturbation signal
%%
timeVec = [0:(1/(config.points-1)):1]' * endTime;
signalVec = interp1(timeVecDense,signalVecDense,timeVec);

%%
% Add the padding time command and then form the command structure
%%

paddingTime = endTime - timeVecSum;

%padding interval
waitVecOutput(j,1)    = round(paddingTime*0.5*sampleFrequencyHz)/sampleFrequencyHz;
rampVecTimeOutput(j,1)= round(paddingTime*0.5*sampleFrequencyHz)/sampleFrequencyHz;
timeVecSum          = timeVecSum + waitVecOutput(j,1)+rampVecTimeOutput(j,1);

lengthVecOutput(j,1)  = lengthVecOutput(j-1,1);

%trim
waitVecOutput        = waitVecOutput(1:j,1);
lengthVecOutput      = lengthVecOutput(1:j,1);
rampVecTimeOutput    = rampVecTimeOutput(1:j,1);

assert(functionOption(1).isRelative==0,...
       'Error: Step length option must have isRelative=0 for the 610A');

controlFunctions = struct('controlFunction','','waitDuration',[],'optionValues',[],'options',[]);
controlFunctions.controlFunction = 'Ramp';
controlFunctions.waitDuration  = waitVecOutput;
controlFunctions.optionValues  = [lengthVecOutput,rampVecTimeOutput];
controlFunctions.options       = functionOption;

lineCount = j;




    

%end
