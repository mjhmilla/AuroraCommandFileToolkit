function signal = createSquareWavePattern(config,...
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



%%
% Create the signal struct
%%

%Signal that the Auorora machine will use
signal.time=timeVec;
signal.signal=signalVec;
signal.command = config.command;

%Interpolated signal used to analyze the spectrum
samplePoints = config.points;
dt = max(timeVec)/samplePoints;
assert(dt < min(diff(timeVec)),...
    sprintf(['Error: minimum hold time must ',...
             'be decreased to below %1.3e\n'],dt));

timeSample = ([0:(1/(samplePoints-1)):1]').*max(timeVec);
signalSample = interp1(timeVec,signalVec,timeSample);

sampleFrequency = 1/dt;

signal.t = timeSample;
signal.x = signalSample;
signal.freqHz = [1:samplePoints]'.*(sampleFrequency/samplePoints);
signal.freq   = signal.freqHz.*(2*pi);

%Evaluate the power spectrum
signal.y = fft(signal.x);
p2 = abs(signal.y/samplePoints);
  p1 = p2(1:floor(samplePoints/2) + 1);
  p1(2:end-1) = 2*p1(2:end-1);
signal.p(:,1) = p1;

%Evaluate the power spectrum using Welch's method
[signal.pw(:,1),fw] = pwelch(signal.x);
signal.fw(:,1) = fw.*sampleFrequency;
signal.fwHz(:,1) = (fw/(2*pi)).*sampleFrequency;

% [cpsd_Gxy,cpsd_Fxy] = cpsd(xTimeDomain,yTimeDomain,[],[],[],sampleFrequency,'onesided');
% [cpsd_Gxx,cpsd_Fxx] = cpsd(xTimeDomain,xTimeDomain,[],[],[],sampleFrequency,'onesided');
% [cpsd_Gyy,cpsd_Fyy] = cpsd(yTimeDomain,yTimeDomain,[],[],[],sampleFrequency,'onesided');
% [cpsd_Gyx,cpsd_Fyx] = cpsd(yTimeDomain,xTimeDomain,[],[],[],sampleFrequency,'onesided');
% 
% coherenceSq     = ( abs(cpsd_Gyx).*abs(cpsd_Gyx) ) ./ (cpsd_Gxx.*cpsd_Gyy) ;
% freqHz          = cpsd_Fyx;
% freqRadians     = freqHz.*(2*pi);
% idxBW         = find(freqHz <= max(bandwidth+1));
% 
% gain  = abs(cpsd_Gyx./cpsd_Gxx);
% phase = angle(cpsd_Gyx./cpsd_Gxx);


%Take the signal derivative
s = complex(0,1).*(signal.freq(:,1));
xdotS = ifft(signal.y(:,1).*s,'symmetric'); 

if(abs(xdotS(1,1)) > 1e-2)
  disp(['Initial xdot is ',num2str(abs(xdotS(1,1))),...
  ' but should be close to zero']);
end

xdotS(1,1) = 0.; %Muscle model currently can only be initialized
                 %with a velocity that is < sqrt(eps)
signal.xdot(:,1) = xdotS;


here=1;
