function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createSineWavePattern600A(...
                                config,...
                                functionOption,...
                                auroraConfig,...
                                makePreconditioningWave)


scaleControlFunctionTime=1;
switch functionOption(3).unit
    case 's'
        scaleControlFunctionTime=1;        
    case 'ms'
        scaleControlFunctionTime=1000;        
    otherwise
        assert(0,'Error: unrecognized defaultTimeUnit in functionOption');
end
scaleTime = scaleControlFunctionTime;

%%
%  Create all of the random vectors needed to construct a 
%  pseudo random signal using Length-Ramp and Length-Sine commands.
%  The arbitrary waveform construction is in the function
%  createArbitraryWavePatterns
%%

switch config.distribution
    case 'uniform'
        rng(1,'twister'); 
        randomVecA = rand(config.points,1);
        
        rng(2,'twister'); 
        randomVecB = rand(config.points,1);
        
        rng(3,'twister'); 
        randomVecC = rand(config.points,1);
        
        rng(4,'twister'); 
        randomVecD = rand(config.points,1);
        
        rng(5,'twister'); 
        randomVecE = rand(config.points,1);


    case 'normal'
        mu = 0.5;
        sigma = (1-mu)/1.5;

        rng(1,'twister'); 
        randomVecA = normrnd(mu,sigma,[config.points,1]);
        randomVecA(randomVecA < 0)=0;
        randomVecA(randomVecA>1)=1;

        rng(2,'twister'); 
        randomVecB = normrnd(mu,sigma,[config.points,1]);
        randomVecB(randomVecB < 0)=0;
        randomVecB(randomVecB>1)=1;
        
        rng(3,'twister'); 
        randomVecC = normrnd(mu,sigma,[config.points,1]);
        randomVecC(randomVecC < 0)=0;
        randomVecC(randomVecC>1)=1;
        
        rng(4,'twister'); 
        randomVecD = normrnd(mu,sigma,[config.points,1]);
        randomVecD(randomVecD < 0)=0;
        randomVecD(randomVecD>1)=1;
        
        rng(5,'twister'); 
        randomVecE = normrnd(mu,sigma,[config.points,1]);
        randomVecE(randomVecE < 0)=0;
        randomVecE(randomVecE>1)=1;    
        
    otherwise assert(0,'Error: unrecognized distribution');
end

%%
%We adjust the frequency values so that they have a period that is
%as close as possible to a time that ends perfectly at a multiple of 
%0.1 ms, which is the finest level of precision offered by Aurora's
%duration field
%%
if(length(config.sineWave.frequencyRange) == 2 ...
        && abs(diff(config.sineWave.frequencyRange)) > 0 )
    frequencyVector = ...
        (1-randomVecC).*(config.sineWave.frequencyRange(1,1)) ...
           +randomVecC.*(config.sineWave.frequencyRange(1,2)...
                        -config.sineWave.frequencyRange(1,1));
else
    frequencyVector = ones(size(randomVecC)).*config.sineWave.frequencyRange(1,1);
end

period = round( (frequencyVector.^(-1)).*scaleTime, 1);

frequencyTmp = round( ((period.*(1/scaleTime)).^(-1)), 4);
frequencyErr = abs(frequencyVector-frequencyTmp);
periodA      = (frequencyTmp.^(-1)).*scaleTime;
periodB      = round((periodA),1);
cycleErr    = abs(periodA-periodB)./periodB;

assert(max(cycleErr) < 1e-4,...
    ['Error: the cycle error in the sinusoid perturbation ',...
     'function may accumulate at a rate greater than 1% per 100 cycles']);

frequencyVector = frequencyTmp;

if(length(config.sineWave.magnitudeRange) == 2 ...
        && abs(diff(config.sineWave.magnitudeRange)) > 0 )

    amplitudeVector = ...
        (1-randomVecD).*(config.sineWave.magnitudeRange(1,1)) ...
           +randomVecD.*(config.sineWave.magnitudeRange(1,2)...
                        -config.sineWave.magnitudeRange(1,1));
else
    amplitudeVector = ones(size(randomVecD)).*config.sineWave.magnitudeRange(1,1);
end

if(length(config.sineWave.waitTimeRange)==2 ...
        && abs(diff(config.sineWave.waitTimeRange)) > 0)
    waitTimeVector = ...
        (1-randomVecE).*(config.sineWave.waitTimeRange(1,1)) ...
           +randomVecE.*(config.sineWave.waitTimeRange(1,2)...
                        -config.sineWave.waitTimeRange(1,1));
else
    waitTimeVector = ones(size(randomVecE)).*config.sineWave.waitTimeRange(1,1);
end

%%
% Make a constant perturbation if desired
%%
if(makePreconditioningWave==1)

    frequencyVector = ones(config.points,1)...
                       .*mean(config.sineWave.frequencyRange);
    frequencyVector = round(frequencyVector);
    
      
    amplitudeVector = ones(config.points,1)...
                       .*mean(config.sineWave.magnitudeRange);    
    waitTimeVector = ones(config.points,1)...
                       .*mean(config.sineWave.waitTimeRange);
end


%%
% Construct the signal
%%
n = config.points;
m = 100; %number of points in each sine wave
timeVecDense   = zeros(n,1);
signalVecDense = zeros(n,1);

%Vectors to generate the Aurora commands
waitVec      = zeros(n,1);
frequencyVec = zeros(n,1);
amplitudeVec = zeros(n,1);
durationVec  = zeros(n,1);
timeVecSum   = 0;



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
waitVec(j,1)      = auroraConfig.minimumWaitTime;
frequencyVec(j,1) = 10;
amplitudeVec(j,1) = 0;
durationVec(j,1)  = config.paddingDuration*scaleControlFunctionTime...
                           -auroraConfig.minimumWaitTime;

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
waitVec(j,1)        = auroraConfig.minimumWaitTime;
frequencyVec(j,1)   = 10;
amplitudeVec(j,1)   = 0;
durationVec(j,1)    = paddingTime-waitVec(j,1);
timeVecSum          = timeVecSum + waitVec(j,1) + durationVec(j,1);

%trim
waitVec        = waitVec(1:j,1);
frequencyVec   = frequencyVec(1:j,1);
amplitudeVec   = amplitudeVec(1:j,1);
durationVec    = durationVec(1:j,1);


assert(functionOption(2).isRelative==1,...
       'Error: Length-Sine length option must have isRelative=1');

controlFunctions = struct('controlFunction','','waitDuration',[],'optionValues',[],'options',[]);
controlFunctions.controlFunction = 'Length-Sine';
controlFunctions.waitDuration  = waitVec;
controlFunctions.optionValues  = [frequencyVec, amplitudeVec, durationVec];
controlFunctions.options       = functionOption;

lineCount = j;




    

%end
