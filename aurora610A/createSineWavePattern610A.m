function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createSineWavePattern610A(...
                                config,...
                                frequencyVector,...
                                amplitudeVector,...
                                waitTimeVector,...
                                functionOption,...
                                auroraConfig)



%Generate the signal
n = config.points;
m = 100; %number of points in each sine wave
timeVecDense   = zeros(n,1);
signalVecDense = zeros(n,1);

%Vectors to generate the Aurora commands
waitVec      = zeros(n,1);
frequencyVec = zeros(n,1);
amplitudeVec = zeros(n,1);
durationVec  = zeros(n,1);
cycleVec     = ones(n,1);
timeVecSum   = 0;


scaleControlFunctionTime=1;
assert(strcmp(auroraConfig.defaultTimeUnit,'s'),...
    'Error: auroraConfig.defaultTimeUnit must be s');

endTime     = config.duration + 2*config.paddingDuration;
endSineTime = config.duration + config.paddingDuration;

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
waitVec(j,1)      = 0;
frequencyVec(j,1) = (1/config.paddingDuration);
amplitudeVec(j,1) = 0;
durationVec(j,1)  = config.paddingDuration*scaleControlFunctionTime;
cycleVec(j,1)     = 1;

timeVecSum   = timeVecSum + waitVec(j,1) + durationVec(j,1);


i =i+1;
j =j+1;

nextTime=0;


while nextTime < endSineTime

    %If the dense time sample vector is too small, double its size
    if(length(timeVecDense) < (i+m))
        timeVecDense =[timeVecDense; zeros(size(timeVecDense))];
        signalVecDense =[signalVecDense; zeros(size(signalVecDense))];        
    end

    frequency   = frequencyVector(j-1,1);
    amplitude   = 0.5*amplitudeVector(j-1,1);
    waitTime    = waitTimeVector(j-1,1);      
    duration = 1/frequency;
    
    %%
    % Generate the command vector
    %%
    waitVec(j,1)        = waitTime* scaleControlFunctionTime;
    frequencyVec(j,1)   = frequency;
    amplitudeVec(j,1)   = amplitude;
    durationVec(j,1)    = duration * scaleControlFunctionTime;
    cycleVec(j,1)       = 1;
    timeVecSum          = timeVecSum + waitVec(j,1) + durationVec(j,1);

    j=j+1;    
    
    %%
    %Generate a densely sampled sine wave
    %%
    timeVecDense(i,1)= timeVecDense(i-1,1) + waitTime;
    signalVecDense(i,1) = 0;    
    i=i+1;
    for k=1:1:m
        omegat = (duration*(k/m))*frequency;

        timeVecDense(i,1)   = timeVecDense(i-1,1) + duration*(1/m);
        signalVecDense(i,1) = amplitude*sin(omegat*2*pi);
        i=i+1;
    end
    signalVecDense(i-1,1)=0; %To prevent any numerical drift    


    %%
    % Get the end time of the next sinusoid
    %%
    
    assert(j < length(frequencyVector), ...
        'Error: input frequencyVectory is too short');

    nextFrequency = frequencyVector(j,1);
    nextWaitTime = waitTimeVector(j,1);
    nextTime = timeVecDense(i-1,1) + (1/nextFrequency) + nextWaitTime;

    
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
waitVec(j,1)        = 0;
amplitudeVec(j,1)   = 0;
durationVec(j,1)    = paddingTime;
frequencyVec(j,1)   = 1/durationVec(j,1);
cycleVec(j,1)       = 1;
timeVecSum          = timeVecSum + waitVec(j,1) + durationVec(j,1);

%trim
waitVec        = waitVec(1:j,1);
frequencyVec   = frequencyVec(1:j,1);
amplitudeVec   = amplitudeVec(1:j,1);
durationVec    = durationVec(1:j,1);
cycleVec       = cycleVec(1:j,1);


assert(functionOption(2).isRelative==0,...
       'Error: Length-Sine length option must have isRelative=0 for the 610A');

controlFunctions = struct('controlFunction','','waitDuration',[],'optionValues',[],'options',[]);
controlFunctions.controlFunction = 'Sine Wave';
controlFunctions.waitDuration  = waitVec;
controlFunctions.optionValues  = [frequencyVec, amplitudeVec, cycleVec];
controlFunctions.options       = functionOption;

lineCount = j;




    

%end
