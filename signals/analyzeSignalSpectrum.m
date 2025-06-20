function signal = analyzeSignalSpectrum(controlFunctionName, ...
                                    timeVec, signalVec,config)

%%
% Create the signal struct
%%

%Signal that the Auorora machine will use
signal.time=timeVec;
signal.signal=signalVec;
signal.command = controlFunctionName;

%Interpolated signal used to analyze the spectrum
samplePoints = config.points;
dt = max(timeVec)/samplePoints;
%assert(dt < min(diff(timeVec)),...
%    sprintf(['Error: minimum hold time must ',...
%             'be decreased to below %1.3e\n'],dt));
if(dt < min(diff(timeVec)))
   sprintf(['Error: minimum hold time must ',...
            'be decreased to below %1.3e\n'],dt);
end

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