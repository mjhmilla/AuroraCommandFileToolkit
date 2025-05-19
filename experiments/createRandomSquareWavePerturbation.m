function signal = createRandomSquareWavePerturbation(config)

%Get the parameters
maximumSpeed    = config.maximumSpeedNorm;
duration        = config.duration;
amplitude       = config.magnitude ;
paddingDuration = config.paddingDuration;

if(isempty(config.rng)==0)
    rng(config.rng);
end

minTime = config.holdRange(1,1);
maxTime = config.holdRange(1,2);

%Get the random hold vector vector
n = floor(duration*1000);
randomVec = rand(n,1);

signOfChange = 1;
if(randomVec(1,1)>0.5)
    signOfChange = -1;
end

randomHoldTimes = minTime + randomVec.*maxTime;

%Generate the signal
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


while timeVec(i,1) < (duration+paddingDuration)

    i=i+1;
    timeVec(i,1)    =timeVec(i-1,1)+randomHoldTimes(i-1,1);
    signalVec(i,1)  =signalVec(i-1,1);
    
    i=i+1;
    timeVec(i,1)=timeVec(i-1,1)+minTime;
    signalVec(i,1)=signalVec(i-1,1)+signOfChange*amplitude;
    
    signOfChange=signOfChange*-1;

end

signalVec(i,1)=0;

paddingDurationUpd = ((duration+2*paddingDuration)...
                   -(timeVec(i,1)-paddingDuration))*0.5;
paddingDurationErr = paddingDurationUpd-paddingDuration;

timeVec(:,1)=timeVec+paddingDurationErr;

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
signal.length=signalVec;

%Interpolated signal used to analyze the spectrum
samplePoints = config.points;
dt = max(timeVec)/samplePoints;
assert(dt < min(diff(timeVec)));

timeSample = ([0:(1/(samplePoints-1)):1]').*max(timeVec);
signalSample = interp1(timeVec,signalVec,timeSample);

sampleFrequency = 1/dt;

signal.t = timeSample;
signal.x = signalSample;
signal.freqHz = [1:samplePoints]'.*(sampleFrequency/samplePoints);
signal.freq   = signal.freqHz.*(2*pi);

signal.y = fft(signal.x);
p2 = abs(signal.y/samplePoints);
  p1 = p2(1:floor(samplePoints/2) + 1);
  p1(2:end-1) = 2*p1(2:end-1);
signal.p(:,1) = p1;

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
