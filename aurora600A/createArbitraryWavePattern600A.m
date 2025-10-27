function [timeVec,signalVec,controlFunctions,lineCount] = ...
            createArbitraryWavePattern600A(...
                                signalType,...
                                config,...
                                functionOption,...
                                auroraConfig)



scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

%Generate the signal
period      = round((1/config.frequencyHz)*scaleTime,1);
periodStr   = sprintf('%1.1f',period);
frequencyHz = 1/(period/scaleTime);

switch auroraConfig.defaultTimeUnit
    case 's'
        periodStr = [periodStr,' s'];
    case 'ms'
        periodStr = [periodStr,' ms'];        
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

bandwidthHz = max(config.frequencyRange);
assert( abs(frequencyHz/bandwidthHz) > 2,...
        ['Error: sampling frequency should be at least',...
         ' 2x higher than the desired bandwidth']);

npts = config.points;
spts = round(config.duration*frequencyHz);
ppts = round(config.paddingDuration*frequencyHz);

paddingVec = zeros(ppts,1);

%%
% Construct the random signal
%%
randomVecArb = [];

timeVec = [0:1:(npts-1)]' .* (period/scaleTime);

switch signalType
    case 'random'
        switch config.distribution
            case 'uniform'
                rng(config.arbitraryWaveform.seed,'twister'); 
                randomVecArb = rand(spts,1);
            case 'normal'
                mu      = 0.;
                sigma   = 1;
                rng(config.arbitraryWaveform.seed,'twister'); 
                randomVecArb = normrnd(mu,sigma,[spts,1]);        
            otherwise
                assert(0,'Error: unrecognized distribution');
        end
        
        randomVecArb = randomVecArb-mean(randomVecArb);
        randomVecArb = randomVecArb./max(abs(randomVecArb));
        
        signalVecRaw = [paddingVec;randomVecArb;paddingVec];
        [b,a] = butter(2, (bandwidthHz/(frequencyHz*0.5)),'low');
        signalVec = filtfilt(b,a,signalVecRaw);

        signalVec = signalVec./max(abs(signalVec));
        signalVec = signalVec .* max(config.magnitudeRange);


        assert((length(signalVecRaw)-npts)==0,...
                'Error: arbitrary signal length is incorrect');
        

    case 'preconditioning'

        preconditioningFrequencyHz = round(bandwidthHz/2);
        preconditioningVec = ...
            sin(timeVec(1:spts,1).*(2*pi*(preconditioningFrequencyHz)));
        signalVecRaw = [paddingVec;preconditioningVec;paddingVec];

        assert((length(signalVecRaw)-npts)==0,...
                'Error: arbitrary signal length is incorrect');
        
        [b,a] = butter(2, (bandwidthHz/(frequencyHz*0.5)),'low');
        signalVec = filtfilt(b,a,signalVecRaw);
        
    otherwise
        assert(0,'Error: signalType must be random or preconditioning');

end



controlFunctions = struct('controlFunction','',...
                          'waitDuration',[],...
                          'optionValues',[],...
                          'options',[],...
                          'fileName','',...
                          'fileData',[]);
controlFunctions.controlFunction = 'Length-Arb';
controlFunctions.waitDuration  = 1*scaleTime;

fileName    = [signalType,'_',config.arbitraryWaveform.fileName];
lengthUnit  = config.arbitraryWaveform.lengthUnit;

controlFunctions.optionValues  = [{fileName},{lengthUnit},{periodStr}];
controlFunctions.options       = functionOption;
controlFunctions.fileName      = fileName;
controlFunctions.fileData      = signalVec;
lineCount = 1;

