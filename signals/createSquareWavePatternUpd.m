function [timeVec,signalVec,commandCount] =...
     createSquareWavePatternUpd(config,...
                                holdTimesVector,...
                                velocityVector,...
                                signOfFirstChange)

%Get the parameters
maximumSpeed    = max(config.normSpeedRange);
duration        = config.duration;
amplitude       = config.magnitudeRange(1,1) ;
paddingDuration = config.paddingDuration;

minTime = config.holdRange(1,1);
maxTime = config.holdRange(1,2);

halfTime = (maxTime-minTime)*0.5;

signOfChange=signOfFirstChange;



%Generate the signal
n = config.points;
timeVec = zeros(n,1);
signalVec = zeros(n,1);


i=1;
timeVec(i,1)    =0;
signalVec(i,1)  =0;

i=i+1;
timeVec(i,1)    =timeVec(i-1,1)+paddingDuration;
signalVec(i,1)  =signalVec(i-1,1);

i=i+1;
timeVec(i,1)=timeVec(i-1,1)+minTime;
signalVec(i,1)=signalVec(i-1,1)+0.5*signOfChange*amplitude;

commandCount=1;

signOfChange=signOfChange*-1;

flag_limitReached=0;

while timeVec(i,1) < (duration+paddingDuration) && flag_limitReached==0

    i=i+1;
    tmpTime    =timeVec(i-1,1)+holdTimesVector(i-1,1);
    if(tmpTime < (duration+paddingDuration))
        timeVec(i,1)=tmpTime;
        signalVec(i,1)  =signalVec(i-1,1);

        stepVel = velocityVector(i-1,1);
        stepTime = 2.0*amplitude/stepVel;

        i=i+1;
        tmpTime    =timeVec(i-1,1)+stepTime;
        timeVec(i,1)=tmpTime;
        signalVec(i,1)=signalVec(i-1,1)+signOfChange*amplitude;        
        signOfChange=signOfChange*-1;            
        commandCount = commandCount+1;
    else
        i=i-1;
        flag_limitReached=1;
    end
    

end

%Go back one point
signalVec(i,1)=0;

paddingDurationUpd = ((duration+2*paddingDuration)...
                   -(timeVec(i,1)-paddingDuration))*0.5;
paddingDurationErr = paddingDurationUpd-paddingDuration;

timeVec(:,1)=timeVec+paddingDurationErr;
timeVec(1,1)=0;

finalPaddingDuration = duration+2*paddingDuration-timeVec(i,1);

assert(abs(finalPaddingDuration-paddingDurationUpd)<1e-6);

i=i+1;
timeVec(i) = timeVec(i-1)+finalPaddingDuration;
signalVec(i)=0;

timeVec = timeVec(1:i,1);
signalVec=signalVec(1:i,1);




