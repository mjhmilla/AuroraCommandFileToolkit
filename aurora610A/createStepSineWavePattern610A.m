function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createStepSineWavePattern610A(...
                                fcnMeanValue,...
                                config,...
                                frequencyHzRangeInput,...
                                amplitudeInput,...
                                waitTimeInput,...
                                functionOption,...
                                auroraConfig)



%Generate the signal
n = config.points;
m = 100; %number of points in each sine wave
timeVecDense   = zeros(n,1);
signalVecDense = zeros(n,1);


numWaves      = 2;
duration      = 0;
freqDistPower = 2/3;

while(duration < config.duration)

  numWaves=numWaves+1;
  
  normFreq = (([1:1:numWaves]').^freqDistPower) ;
  normFreq = normFreq./max(normFreq);

  randomFrequencyVec = ...
    normFreq.*(2*frequencyHzRangeInput(1,2)-frequencyHzRangeInput(1,1))...
                +frequencyHzRangeInput(1,1);

  randomPeriodVec = 1./randomFrequencyVec;
  randomPeriodVec = ...
    round(randomPeriodVec*auroraConfig.analogToDigitalSampleRateHz)...
         /auroraConfig.analogToDigitalSampleRateHz;
  randomFrequencyVec = 1./randomPeriodVec;

  duration = sum(1./randomFrequencyVec) ...
              + waitTimeInput.*length(randomFrequencyVec);
end

numWaves=numWaves-1;
normFreq = (([1:1:numWaves]').^freqDistPower) ;
normFreq = normFreq./max(normFreq);

randomFrequencyVec = ...
  normFreq.*( 2*frequencyHzRangeInput(1,2)-frequencyHzRangeInput(1,1))...
               +frequencyHzRangeInput(1,1);

randomPeriodVec = 1./randomFrequencyVec;
randomPeriodVec = ...
  round(randomPeriodVec.*auroraConfig.analogToDigitalSampleRateHz)...
  ./auroraConfig.analogToDigitalSampleRateHz;
randomFrequencyVec = 1./randomPeriodVec;

duration = sum(1./randomFrequencyVec) ...
            + waitTimeInput.*length(randomFrequencyVec);

%%
% Scramble the frequency vector
%%

rng(3,'twister');
randomFrequencyVec = randomFrequencyVec(randperm(length(randomFrequencyVec)));

n=(length(randomFrequencyVec)*2+1)+2;

%Vectors to generate the Aurora commands
waitVecOutput      = zeros(n,1);
lengthVecOutput    = zeros(n,1);

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
signalVecDense(i,1)  =0;

i=i+1;
timeVecDense(i,1)    =timeVecDense(i-1,1)+config.paddingDuration;
signalVecDense(i,1)  =signalVecDense(i-1,1);

j = 1;
waitVecOutput(j,1)      = config.paddingDuration...
                          -auroraConfig.lengthStepResponseTime;
lengthVecOutput(j,1)    = fcnMeanValue(0);

timeVecSum   = timeVecSum + waitVecOutput(j,1);

i = i+1;
j = j+1;
k = 0;

nextTime = 0;

sampleFrequencyHz = auroraConfig.analogToDigitalSampleRateHz;
samplePeriodS     = (1/sampleFrequencyHz);




while k < length(randomFrequencyVec)

    %If the dense time sample vector is too small, double its size
    if(length(timeVecDense) < (i+m))
        timeVecDense   =[timeVecDense; zeros(size(timeVecDense))];
        signalVecDense =[signalVecDense; zeros(size(signalVecDense))];        
    end



    k=k+1;
    frequencyInput = randomFrequencyVec(k,1);    
    durationInput  = 1/frequencyInput;

    waitTime       = round(0.5*durationInput*sampleFrequencyHz) ...
                          /sampleFrequencyHz;
    if(waitTime < auroraConfig.lengthStepResponseTime)
      waitTime = auroraConfig.lengthStepResponseTime;
    end

    meanLengthInput = fcnMeanValue(timeVecSum);
    
    amplitude = amplitudeInput(1,1);
    if(length(amplitudeInput)>1)
      amplitude = amplitudeInput(j-1,1);
    end

    %%
    % Generate the command vector
    %%
    if(k==1)
      prevWaitTime = auroraConfig.lengthStepResponseTime;      
    else
      prevWaitTime = waitVecOutput(j-1,1);
    end

    waitVecOutput(j,1)        = prevWaitTime;
    lengthVecOutput(j,1)      = 0.5*amplitude + meanLengthInput;
    timeVecSum          = timeVecSum + waitVecOutput(j,1);

    j=j+1;  
    
    waitVecOutput(j,1)        = waitTime;
    lengthVecOutput(j,1)      = -0.5*amplitude + meanLengthInput;
    timeVecSum          = timeVecSum + waitVecOutput(j,1);    

    j=j+1;

    disp('you are here');
    abort();
    %%
    %Generate a densely sampled sine wave
    %%
    timeVecDense(i,1)= timeVecDense(i-1,1) + waitTimeInput;
    signalVecDense(i,1) = 0;    
    i=i+1;
    for k=1:1:m
        omegat = (duration*(k/m))*frequency;

        timeVecDense(i,1)   = timeVecDense(i-1,1) + duration*(1/m);
        signalVecDense(i,1) = 0.5*amplitude*sin(omegat*2*pi);
        i=i+1;
    end
    signalVecDense(i-1,1)=0; %To prevent any numerical drift    

    
end


%%
% Add the padding interval
%%
timeVecDense(i,1) = endTime;
signalVecDense(i,1) = 0;

timeVecDense   = timeVecDense(1:i,1);
signalVecDense = signalVecDense(1:i,1);

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
waitVecOutput(j,1)        = 0;
amplitudeVecOutput(j,1)   = 0;
durationVecOutput(j,1)    = paddingTime;
frequencyVecOutput(j,1)   = 1/durationVecOutput(j,1);
cycleVecOutput(j,1)       = 1;
timeVecSum          = timeVecSum + waitVecOutput(j,1) + durationVecOutput(j,1);

%trim
waitVecOutput        = waitVecOutput(1:j,1);
frequencyVecOutput   = frequencyVecOutput(1:j,1);
amplitudeVecOutput   = amplitudeVecOutput(1:j,1);
durationVecOutput    = durationVecOutput(1:j,1);
cycleVecOutput       = cycleVecOutput(1:j,1);


assert(functionOption(2).isRelative==0,...
       'Error: Length-Sine length option must have isRelative=0 for the 610A');

controlFunctions = struct('controlFunction','','waitDuration',[],'optionValues',[],'options',[]);
controlFunctions.controlFunction = 'Step';
controlFunctions.waitDuration  = waitVecOutput;
controlFunctions.optionValues  = [frequencyVecOutput, amplitudeVecOutput, cycleVecOutput];
controlFunctions.options       = functionOption;

lineCount = j;




    

%end
