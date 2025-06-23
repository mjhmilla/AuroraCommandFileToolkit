function [timeVec,signalVec,controlFunctions,lineCount] =...
     createSquareWavePatternUpd(config,...
                                holdTimesVector,...
                                velocityVector,...
                                signOfFirstChange,...
                                functionOption,...
                                auroraConfig)

%Get the parameters
maxRampSpeed    = auroraConfig.maximumRampSpeedInDefaultUnits;


switch auroraConfig.defaultTimeUnit
    case 's'
        maxRampSpeedLPS = maxRampSpeed*config.normSpeedRange(1,2);
    case 'ms'
        maxRampSpeedLPS = maxRampSpeed*1000*config.normSpeedRange(1,2);
    otherwise
        assert(0,'Error: Unrecognized time unit');

end

duration        = config.duration;
amplitude       = config.magnitudeRange(1,1) ;
paddingDuration = config.paddingDuration;

minTime = config.holdRange(1,1);
maxTime = config.holdRange(1,2);



halfTime = (maxTime-minTime)*0.5;

signOfChange=signOfFirstChange;


scaleDurationTime=1;
scaleHoldTime    =1;
minStepTimeInS   = auroraConfig.postCommandPauseTime;
switch functionOption(2).unit
    case 's'
        scaleDurationTime=1;        
        scaleHoldTime    =1;
    case 'ms'
        scaleDurationTime=1000;        
        scaleHoldTime    =1000; 
        minStepTimeInS   = minStepTimeInS*0.001;
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


stepVel    = velocityVector(i-1,1)*maxRampSpeedLPS;
stepTime   = round(abs(lengthChange/stepVel)*1000,1)/1000;
assert(stepTime > minStepTimeInS,...
       'Error: ramp duration is too small');


timeVec(i,1)    = timeVec(i-1,1)+stepTime;
signalVec(i,1)  = signalVec(i-1,1)+lengthChange;

lineCount=lineCount+1;

waitVec(lineCount,1)      = auroraConfig.postCommandPauseTime;
lengthVec(lineCount,1)    = lengthChange;
durationVec(lineCount,1)  = (stepTime*scaleDurationTime...
                            -auroraConfig.postCommandPauseTime);
lengthVecSum = lengthVecSum + lengthChange;
timeVecSum  = timeVecSum ...
            + waitVec(lineCount,1)...
            + durationVec(lineCount,1);

signOfChange=signOfChange*-1;

flag_limitReached=0;

while timeVec(i,1) < (duration+paddingDuration) && flag_limitReached==0

    i=i+1;

    lengthChange    = signOfChange*amplitude;    
    stepVel         = velocityVector(i-1,1)*maxRampSpeedLPS;
    stepTime        = round(abs(lengthChange/stepVel)*1000,1)/1000;    
    holdTime        = holdTimesVector(i-1,1);
    nextTime        = timeVec(i-1,1)+holdTime+stepTime;

    if(nextTime < (duration+paddingDuration))
        timeVec(i,1)    = timeVec(i-1,1)+holdTime;
        signalVec(i,1)  = signalVec(i-1,1);


        assert(stepTime > minStepTimeInS,...
               'Error: ramp duration is too small');

        i=i+1;
        timeVec(i,1)   = timeVec(i-1,1)+stepTime;
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
        flag_limitReached=1;
    end
    

end

%%
% Add the final point to bring the net length change to zero
%%
 


lengthChange    = 0.5*signOfChange*amplitude;    
stepVel         = velocityVector(i-1,1)*maxRampSpeedLPS;
stepTime        = round(abs(lengthChange/stepVel)*1000,1)/1000;    
holdTime        = (duration+2*paddingDuration) ...
                 -(timeVec(i-1,1) + stepTime + paddingDuration);

assert((holdTime)*scaleHoldTime > auroraConfig.postCommandPauseTime,... 
       'Error: final wait time is too small.');

timeVec(i,1)    = timeVec(i-1,1)+holdTime;
signalVec(i,1)  = signalVec(i-1,1);

assert(stepTime > minStepTimeInS,...
       'Error: ramp duration is too small');

i=i+1;
timeVec(i,1)   = timeVec(i-1,1)+stepTime;
signalVec(i,1) = signalVec(i-1,1)+lengthChange;        

lineCount = lineCount+1;

waitVec(lineCount,1)      = holdTime.*scaleHoldTime;
lengthVec(lineCount,1)    = lengthChange;
durationVec(lineCount,1)  = (stepTime*scaleDurationTime);
lengthVecSum = lengthVecSum + lengthChange;
timeVecSum  = timeVecSum ...
            + waitVec(lineCount,1) ...
            + durationVec(lineCount,1);


%%
% Update the padding duration
%%
finalPaddingTime = duration+2*paddingDuration-timeVec(i,1);

assert((finalPaddingTime-paddingDuration)/paddingDuration< 0.1);

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



