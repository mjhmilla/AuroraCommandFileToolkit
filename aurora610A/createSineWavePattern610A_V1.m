function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createSineWavePattern610A_V1(...
                                config,...
                                frequencyHzRangeInput,...
                                amplitudeInput,...
                                waitTimeInput,...
                                randomNumberGeneratorConfig,...
                                functionOption,...
                                auroraConfig)



%Generate the signal
n = config.points;
m = 100; %number of points in each sine wave
timeVecDense   = zeros(n,1);
signalVecDense = zeros(n,1);


numWaves=2;
duration = 0;
freqDistPower=2/3;
scaleBandwidth=2.5;
while(duration < config.duration)
  numWaves=numWaves+1;
  if(length(frequencyHzRangeInput)>1)
    normFreq = (([1:1:numWaves]').^freqDistPower) ;
    normFreq = normFreq./max(normFreq);
  
    randomFrequencyVec = ...
      normFreq.*(...
        scaleBandwidth*frequencyHzRangeInput(1,2)-frequencyHzRangeInput(1,1))...
       +frequencyHzRangeInput(1,1);
  else
    randomFrequencyVec = ones(numWaves,1).*frequencyHzRangeInput(1,1);
  end
  randomPeriodVec = 1./randomFrequencyVec;
  randomPeriodVec = ...
    round(randomPeriodVec*auroraConfig.analogToDigitalSampleRateHz)...
    /auroraConfig.analogToDigitalSampleRateHz;
  randomFrequencyVec = 1./randomPeriodVec;

  duration = sum(1./randomFrequencyVec) + waitTimeInput.*length(randomFrequencyVec);
end

numWaves=numWaves-1;
normFreq = (([1:1:numWaves]').^freqDistPower) ;
normFreq = normFreq./max(normFreq);

if(length(frequencyHzRangeInput)>1)
  randomFrequencyVec = ...
    normFreq.*(...
      scaleBandwidth*frequencyHzRangeInput(1,2)-frequencyHzRangeInput(1,1))...
      +frequencyHzRangeInput(1,1);

else
    randomFrequencyVec = ones(numWaves,1).*frequencyHzRangeInput(1,1);
end

randomPeriodVec = 1./randomFrequencyVec;
randomPeriodVec = ...
  round(randomPeriodVec.*auroraConfig.analogToDigitalSampleRateHz)...
  ./auroraConfig.analogToDigitalSampleRateHz;
randomFrequencyVec = 1./randomPeriodVec;

duration = sum(1./randomFrequencyVec) + waitTimeInput.*length(randomFrequencyVec);

%%
% Scramble the frequency vector
%%

rng(randomNumberGeneratorConfig.seed,randomNumberGeneratorConfig.type);
randomFrequencyVec = randomFrequencyVec(randperm(length(randomFrequencyVec)));

n=length(randomFrequencyVec)+2;

%Vectors to generate the Aurora commands
waitVecOutput      = zeros(n,1);
amplitudeVecOutput = zeros(n,1);
durationVecOutput  = zeros(n,1);
cycleVecOutput     = ones(n,1);
timeVecSum   = 0;

scaleControlFunctionTime=1;
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
waitVecOutput(j,1)      = 0;
frequencyVecOutput(j,1) = (1/config.paddingDuration);
amplitudeVecOutput(j,1) = 0;
durationVecOutput(j,1)  = config.paddingDuration*scaleControlFunctionTime;
cycleVecOutput(j,1)     = 1;

timeVecSum   = timeVecSum + waitVecOutput(j,1) + durationVecOutput(j,1);


i =i+1;
j =j+1;

nextTime=0;

sampleFrequencyHz = auroraConfig.analogToDigitalSampleRateHz;
samplePeriodS = (1/sampleFrequencyHz);

while j <= (length(randomFrequencyVec)+1)

    %If the dense time sample vector is too small, double its size
    if(length(timeVecDense) < (i+m))
        timeVecDense =[timeVecDense; zeros(size(timeVecDense))];
        signalVecDense =[signalVecDense; zeros(size(signalVecDense))];        
    end

    frequencyInput = randomFrequencyVec(j-1,1);    
    durationInput  = 1/frequencyInput;
    duration       = round(durationInput*sampleFrequencyHz) ...
                          /sampleFrequencyHz;
    frequency      = 1/duration;
    
    amplitude = amplitudeInput(1,1);
    if(length(amplitudeInput)>1)
      amplitude = amplitudeInput(j-1,1);
    end

    %%
    % Generate the command vector
    %%
    waitVecOutput(j,1)        = waitTimeInput* scaleControlFunctionTime;
    frequencyVecOutput(j,1)   = frequency;
    amplitudeVecOutput(j,1)   = 0.5*amplitude;
    durationVecOutput(j,1)    = duration * scaleControlFunctionTime;
    cycleVecOutput(j,1)       = 1;
    timeVecSum          = timeVecSum + waitVecOutput(j,1) + durationVecOutput(j,1);

    j=j+1;  
    
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

paddingTime = endTime*scaleControlFunctionTime - timeVecSum;

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
controlFunctions.controlFunction = 'Sine Wave';
controlFunctions.waitDuration  = waitVecOutput;
controlFunctions.optionValues  = [frequencyVecOutput, amplitudeVecOutput, cycleVecOutput];
controlFunctions.options       = functionOption;

lineCount = j;




    

%end
