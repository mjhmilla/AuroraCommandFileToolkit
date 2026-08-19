function sinSeries = generateExponentiallySpacedSinusoids(...
                        sampleFrequencyHz,...
                        settings,...
                        verbose)

ts            = sampleFrequencyHz;
maxFrequency  = settings.maxFrequencyHz;
minFrequency  = settings.minFrequencyHz;
n             = settings.numberOfSinusoids;
maxDuration   = settings.maxSinusoidDurationS;
maxCycleCount = settings.maxCycleCount;

nDigits       = settings.numberOfDigits;

a = 10^(log10(maxFrequency/minFrequency)/(n-1));

if(verbose==1)

  fprintf('\n\ngenerateExponentiallySpacedSinusoids\n\n');
  fprintf('#\tSinusoid number\n');
  fprintf('F\tFrequency target (Hz)\n');
  fprintf(['C(F)\tFrequency corrected (Hz)\n']);
  fprintf('Err(F)\tFrequency error (Hz)\n');
  fprintf('Err(A)\tAngular error (degrees)\n\n');


  fprintf('#\tF\t\tC(F)\tErr(F)\t\tErr(A)\n');
end

sinSeries = struct('frequencyHz',zeros(n,1),...
                   'cycles',zeros(n,1),...
                   'sampleCount',zeros(n,1),...
                   'sampleError',zeros(n,1),...
                   'periodError',zeros(n,1),...
                   'angularDegreeError',zeros(n,1),...                   
                   'duration',zeros(n,1));




tt=0;
for i=1:1:n

  f = minFrequency*a^(i-1);
  mag = max(ceil(log10(f)),1);
  nRound = nDigits-mag;
  rf= round(f,(nRound),'decimals');

  t = 1/rf;
  s = t*ts;
  rs = round(s);

  f2 = 1/(rs/ts);
  mag = max(ceil(log10(f2)),1);
  nRound = nDigits-mag;
  rf2= round(f2,(nRound),'decimals');

  rt = 1/rf2;
  c = min([round(maxDuration*rf2),maxCycleCount]);


  d = c*rt;
  errorDeg = (d*ts-round(d*ts))*(180/pi)/(1/rf2);
  
  if(abs(errorDeg) > settings.maxAngularErrorDegrees ...
      && settings.flag_correctFrequencyToSampleRate == 1)
    
    errorBest=errorDeg;
    sBest=s;

    sminFraction=1-settings.frequencyHzTolerancePercentage;
    smaxFraction=1+settings.frequencyHzTolerancePercentage;

    smin = round(sBest*sminFraction);
    smax = round(sBest*smaxFraction);

    for j=smin:1:smax
      rs = round(j);    
      f2 = 1/(rs/ts);
      mag = max(ceil(log10(f2)),1);
      nRound = nDigits-mag;
      rf2= round(f2,(nRound),'decimals');
    
      rt = 1/rf2;
      c = min([round(maxDuration*rf2),maxCycleCount]);
      d        = c*rt;
      errorDeg = (d*ts-round(d*ts))*(180/pi)/(1/rf2); 

      if(abs(errorDeg)<abs(errorBest))
        errorBest=errorDeg;
        sBest=rs;
      end
    end

    rs = sBest;    
    f2 = 1/(rs/ts);
    mag = max(ceil(log10(f2)),1);
    nRound = nDigits-mag;
    rf2= round(f2,(nRound),'decimals');
  
    rt = 1/rf2;
    c = min([round(maxDuration*rf2),maxCycleCount]);
    d        = c*rt;
    errorDeg = (d*ts-round(d*ts))*(180/pi)/(1/rf2); 


  end

  tt= tt+d;  

  sinSeries.frequencyHz(i)        = rf2;
  sinSeries.cycles(i)             = c;
  sinSeries.sampleCount(i)        = round(d*ts);
  sinSeries.sampleError(i)        = (d*ts-round(d*ts));
  sinSeries.periodError(i)        = sinSeries.sampleError(i)/(1/rf2);
  sinSeries.angularDegreeError(i) = sinSeries.periodError(i)*(180/pi);
  sinSeries.duration(i)=d;

  if(verbose==1)

    dataV = [i,f,rf2,(f-rf2),sinSeries.periodError(i)];
    strFormat = '%i\t%1.6e';
    t1 = max(ceil(log10(rf2+1)),1);
    t2 = nDigits-t1;
    strFormat = [strFormat,['\t%',num2str(t1),'.',num2str(t2),'f']];
    strFormat = [strFormat,'\t%1.5e\t%1.5e\t'];
    strFormat = [strFormat,'\n'];

    fprintf(strFormat,...
        i,f,rf2,(f-rf2),sinSeries.periodError(i));
  end
end