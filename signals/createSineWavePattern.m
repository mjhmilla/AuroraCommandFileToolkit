function [timeVec,signalVec,commandCount] = createSineWavePattern(...
                                config,...
                                frequencyVector,...
                                amplitudeVector,...
                                waitTimeVector)



%Generate the signal
n = config.points;
m = 100; %number of points in each sine wave
timeVecDense   = zeros(n,1);
signalVecDense = zeros(n,1);


i=1;
timeVecDense(i,1)    =0;
signalVecDense(i,1)  =0;

i=i+1;
timeVecDense(i,1)    =timeVecDense(i-1,1)+config.paddingDuration;
signalVecDense(i,1)  =signalVecDense(i-1,1);

endTime     = config.duration + 2*config.paddingDuration;
endSineTime = config.duration + config.paddingDuration;
%(config.points/config.frequencyHz)-config.paddingDuration;

j = 1;
i=i+1;

nextTime=0;


while nextTime < endSineTime

    if(length(timeVecDense) < (i+m))
        timeVecDense =[timeVecDense; zeros(size(timeVecDense))];
        signalVecDense =[signalVecDense; zeros(size(signalVecDense))];        
    end

    frequency = frequencyVector(j,1);
    amplitude = 0.5*amplitudeVector(j,1);
    waitTime = waitTimeVector(j,1);
    
   
    duration = 1/frequency;

    for k=1:1:m
        omegat = (duration*(k/m))*frequency;

        timeVecDense(i,1)   = timeVecDense(i-1,1) + duration*(1/m);
        signalVecDense(i,1) = amplitude*sin(omegat*2*pi);
        i=i+1;
    end
    signalVecDense(i-1,1)=0; %To prevent any numerical drift
    timeVecDense(i,1)= timeVecDense(i-1,1) + waitTime;
    signalVecDense(i,1) = 0;
    i=i+1;

    jnext=j+1;
    if(jnext > length(frequencyVector))
        here=1;
    end
    nextFrequency = frequencyVector(jnext,1);
    nextWaitTime = waitTimeVector(jnext,1);

    nextTime = timeVecDense(i-1,1) + (1/nextFrequency) + nextWaitTime;

    j=j+1;
end

commandCount = j-1;

timeVecDense(i,1) = endTime;
signalVecDense(i,1) = 0;

timeVecDense   = timeVecDense(1:i,1);
signalVecDense = signalVecDense(1:i,1);


timeVec = [0:(1/(config.points-1)):1]' * endTime;
signalVec = interp1(timeVecDense,signalVecDense,timeVec);


    

%end
