function [timeVec,signalVec,controlFunctions,lineCount] =...
     createSquareWavePatternUpd(config,...
                                holdTimesVector,...
                                velocityVector,...
                                signOfFirstChange,...
                                functionOption,...
                                auroraConfig)

%Get the parameters
maximumSpeed    = max(config.normSpeedRange);
duration        = config.duration;
amplitude       = config.magnitudeRange(1,1) ;
paddingDuration = config.paddingDuration;

minTime = config.holdRange(1,1);
maxTime = config.holdRange(1,2);

halfTime = (maxTime-minTime)*0.5;

signOfChange=signOfFirstChange;


scaleDurationTime=1;
scaleHoldTime    =1;
switch functionOption(2).unit
    case 's'
        scaleDurationTime=1;        
        scaleHoldTime    =1;
    case 'ms'
        scaleDurationTime=1000;        
        scaleHoldTime    =1000;        
    otherwise
        assert(0,'Error: unrecognized defaultTimeUnit in functionOption');
end


%Generate the signal
n = config.points;
timeVec = zeros(n,1);
signalVec = zeros(n,1);

%Vectors to generate the Aurora commands
waitVec = zeros(n,1);
lengthVec = zeros(n,1);
durationVec = zeros(n,1);
timeVecSum   = 0;
lengthVecSum = 0;


i=1;
timeVec(i,1)    =0;
signalVec(i,1)  =0;

%
% First move: padding
%

i=i+1;
lengthChange    = 0;
timeVec(i,1)    =timeVec(i-1,1)+paddingDuration;
signalVec(i,1)  =signalVec(i-1,1);

lineCount=1;

waitVec(lineCount,1)      = auroraConfig.postCommandPauseTime;
lengthVec(lineCount,1)    = lengthChange;
durationVec(lineCount,1)  = paddingDuration*scaleDurationTime...
                           -auroraConfig.postCommandPauseTime;
timeVecSum  = timeVecSum ...
            + waitVec(lineCount,1)...
            + durationVec(lineCount,1);

lengthVecSum                 = lengthVecSum + lengthChange;

%
% Second move: a step
%
i=i+1;
lengthChange    = 0.5*signOfChange*amplitude;
timeVec(i,1)    = timeVec(i-1,1)+minTime;
signalVec(i,1)  = signalVec(i-1,1)+lengthChange;

lineCount=lineCount+1;

waitVec(lineCount,1)      = auroraConfig.postCommandPauseTime;
lengthVec(lineCount,1)    = lengthChange;
durationVec(lineCount,1)  = (minTime*scaleDurationTime...
                            -auroraConfig.postCommandPauseTime);
lengthVecSum = lengthVecSum + lengthChange;
timeVecSum  = timeVecSum ...
            + waitVec(lineCount,1)...
            + durationVec(lineCount,1);

signOfChange=signOfChange*-1;

flag_limitReached=0;

while timeVec(i,1) < (duration+paddingDuration) && flag_limitReached==0

    i=i+1;
    holdTime   = holdTimesVector(i-1,1);
    nextTime    = timeVec(i-1,1)+holdTime;
    if(nextTime < (duration+paddingDuration))
        timeVec(i,1)    = nextTime;
        signalVec(i,1)  = signalVec(i-1,1);

        stepVel = velocityVector(i-1,1);
        stepTime = 2.0*amplitude/stepVel;

        i=i+1;
        nextTime       = timeVec(i-1,1)+stepTime;
        lengthChange   = signOfChange*amplitude;
        timeVec(i,1)   = nextTime;
        signalVec(i,1) = signalVec(i-1,1)+lengthChange;        

        lineCount = lineCount+1;

        waitVec(lineCount,1)      = holdTime.*scaleHoldTime;
        lengthVec(lineCount,1)    = lengthChange;
        durationVec(lineCount,1)  = (stepTime*scaleDurationTime);
        lengthVecSum = lengthVecSum + lengthChange;
        timeVecSum  = timeVecSum ...
                    + waitVec(lineCount,1) ...
                    + durationVec(lineCount,1);

        signOfChange=signOfChange*-1;         
    else
        i=i-1;
        flag_limitReached=1;
    end
    

end

%%
%Go back one point and set the length to zero
%%
signalVec(i,1)=0;
lengthVec(lineCount,1)    = -lengthVecSum;
lengthVecSum = lengthVecSum-lengthVecSum;

%%
% Update the padding duration
%%
finalPaddingTime = duration+2*paddingDuration-timeVec(i,1);

assert(abs(finalPaddingTime-paddingDuration)/paddingDuration< 0.05);

i=i+1;
timeVec(i) = timeVec(i-1)+finalPaddingTime;
signalVec(i)=0;

%Trim
timeVec = timeVec(1:i,1);
signalVec=signalVec(1:i,1);

%Last point
finalPaddingDuration = (duration+2*paddingDuration)*scaleDurationTime...
                     - timeVecSum;

lineCount                 = lineCount+1;
waitVec(lineCount,1)      = auroraConfig.postCommandPauseTime;
lengthVec(lineCount,1)    = 0;
durationVec(lineCount,1)  = finalPaddingDuration ...
                           -auroraConfig.postCommandPauseTime;


%Trim
waitVec     = waitVec(1:lineCount,1);
lengthVec   = lengthVec(1:lineCount,1);
durationVec = durationVec(1:lineCount,1);

%%
% Set the control function data
%%

assert(functionOption(1).isRelative==1,...
       'Error: Length-Ramp length option must have isRelative=1');


controlFunctions = struct('controlFunction','','waitDuration',[],'optionValues',[],'options',[]);
controlFunctions.controlFunction = 'Length-Ramp';
controlFunctions.waitDuration  = waitVec;
controlFunctions.optionValues  = [lengthVec, durationVec];
controlFunctions.options       = functionOption;



