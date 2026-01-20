function success = createTRSS2017PerturbationExperiments600A( ...
                      settingsForceLengthImpedanceDynamic,...
                      perturbationSettings,...
                      stochasticWaves,...
                      projectFolders,...                                                                                                            
                      auroraConfig)


%%
% Characterization
%%
[codeDir, codeLabelDir,dateId] = getTrialDirectories(projectFolders,'_TRSS2017Perturbation');

fidProtocol = fopen(fullfile(codeDir,['protocol_',dateId,'.csv']),'w');

idx = 1;
writeProtocolHeader = 1;


scaleTime=1;
switch auroraConfig.defaultTimeUnit
    case 's'
        scaleTime=1;
    case 'ms'
        scaleTime=1000;
    otherwise
        assert(0,'Error: Unrecognized time unit');
end

blockName = '-';

%%
% Impedance across the f-l relation during lengthening 
%%

%1. Measure the impedance response at the given lengths

seriesName = '';

nSeries = size(settingsForceLengthImpedanceDynamic.normLengths,1);

nIsometric = size(settingsForceLengthImpedanceDynamic.normLengths,2);

    
figPerturbedRamp = figure;
figSmallPerturbation=figure;

colorA = [1,1,1].*0.75;
colorB = [0,0,0];

colorSeries = zeros(nSeries,3);
for i=1:1:size(colorSeries,1)
    n = (i-1)/(size(colorSeries,1)-1);
    colorSeries(i,:) = colorA.*n + colorB.*(1-n);
end

for indexSeries = 1:1:nSeries
    
    for i = 1:1:nIsometric
    
        idxStr = getTrialIndexString(idx);
        
        startLength = settingsForceLengthImpedanceDynamic.normLengths(indexSeries,i);
        typeName    = 'isometric';
        takePhoto   = '';
    
        fname       = getTrialName(seriesName,idx,typeName,startLength, dateId,'.pro');
        fnameLabels = getTrialName(seriesName,idx,typeName,startLength,[dateId,'_labels'],'.csv');
        
        
        fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
            idxStr,typeName,startLength,takePhoto, blockName,fname,'');
    
        auroraConfigIso = auroraConfig;
        auroraConfigIso.bath.activationDuration = ...
          auroraConfig.bath.activationDuration ...
          *settingsForceLengthImpedanceDynamic.activationDurationMultiple(indexSeries,i);
    
        success = createIsometricImpedanceTrial600A(...
                            stochasticWaves,...
                            fullfile(codeDir,fname),...
                            fullfile(codeLabelDir,fnameLabels),...
                            auroraConfigIso);
    
        idx = idx+1;
    end
    
    
    % 2. Perform the active-lengthening ramp
    % 3. Perform the active-lengthening ramp + perturbations
    
    
    smallPerturbationDurationInS = ...
        (1/8)*settingsForceLengthImpedanceDynamic.rampDuration(indexSeries,1)*(1/scaleTime);
    
    smallPerturbationSettings = perturbationSettings;
    
    smallPerturbationSettings.points =  ...
        2*ceil(0.5*smallPerturbationDurationInS*auroraConfig.analogToDigitalSampleRateHz);
    smallPerturbationSettings.paddingDuration = smallPerturbationDurationInS/20;
    
    configVibration = getPerturbationConfiguration600A(...
                        smallPerturbationSettings,...
                        auroraConfig);
    
    startLength = settingsForceLengthImpedanceDynamic.rampNormLengths(indexSeries,1);
    endLength   = settingsForceLengthImpedanceDynamic.rampNormLengths(indexSeries,end);
    duration    = settingsForceLengthImpedanceDynamic.rampDuration(indexSeries,1);
    durationInS = duration*(1/scaleTime);
    
    
    lengthRampOptions = ...
        getCommandFunctionOptions600A('Length-Ramp',auroraConfig);
    
    verbose=0;
    
    plotConfig.numberOfHorizontalPlotColumns    = 1;
    plotConfig.numberOfVerticalPlotRows         = 3;
    plotConfig.plotWidth                        = 5;
    plotConfig.plotHeight                       = 1.5;
    plotConfig.plotHorizMarginCm                = 2;
    plotConfig.plotVertMarginCm                 = 2;
    plotConfig.baseFontSize                     = 10;
    
    [subplotPanel_3R1C,plotConfig_3R1C]=plotConfigGeneric(plotConfig);
    

    plotConfig.numberOfHorizontalPlotColumns    = 2;
    plotConfig.numberOfVerticalPlotRows         = 3;
    plotConfig.plotWidth                        = 5;
    plotConfig.plotHeight                       = 5;
    plotConfig.plotHorizMarginCm                = 2;
    plotConfig.plotVertMarginCm                 = 2;
    plotConfig.baseFontSize                     = 10;
    
    [subplotPanel_3R2C,plotConfig_3R2C]=plotConfigGeneric(plotConfig);
    
    perturbationPlotConfig.subplot=subplotPanel_3R1C;
    perturbationPlotConfig.config = plotConfig_3R1C;
    perturbationPlotConfig.column = 1;

    

    if(indexSeries==1)
        [  smallStochasticWave, ...
           smallPreConditioningWave, ...
           figSmallPerturbation] = createPerturbationWave600A(...
                                  'Length-Ramp',...
                                  lengthRampOptions,...
                                  configVibration,...
                                  auroraConfig,...
                                  figSmallPerturbation,...
                                  perturbationPlotConfig,...
                                  verbose);
    end
    

    
    for i=1:1:2
        idxStr = getTrialIndexString(idx);
        
    
        %
        % file setup
        %
        typeName    = 'activeLengthening';
        takePhoto   = '';
        

        fname       = getTrialName(seriesName,idx,typeName,startLength, dateId,'.pro');
        fnameLabels = getTrialName(seriesName,idx,typeName,startLength,[dateId,'_labels'],'.csv');
        
        fprintf(fidProtocol,'%s,%s,%1.1f,%s,%s,%s,%s\n',...
            idxStr,typeName,startLength,takePhoto, blockName,fname,'');
        
        fid = fopen(fullfile(codeDir,fname),'w');
        fidLabel = fopen(fullfile(codeLabelDir,fnameLabels),'w');
        
        %
        % write the protocol
        %
        lineCount=0;
        [startTime,lineCount] = writePreamble600A(fid,lineCount,auroraConfig);
    
        [endTime, lineCount] = ...
            writeActivationBlock600A(fid, startTime, 'ms', lineCount, auroraConfig);
        
        endActivation = endTime + auroraConfig.bath.activationDuration;
        
        fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Pre-Activation',startTime,endTime);
        fprintf(fidLabel,'%s,%1.6f,%1.6f\n','Activation',endTime,endActivation);
        

        startTimeBlock = endActivation;
    
        %
        % execute the ramp
        %
        startLength = settingsForceLengthImpedanceDynamic.rampNormLengths(indexSeries,1);
        endLength   = settingsForceLengthImpedanceDynamic.rampNormLengths(indexSeries,end);
        duration    = settingsForceLengthImpedanceDynamic.rampDuration(indexSeries,1);
        durationInS = duration .* (1/scaleTime);
    
        switch i 
            case 1
                lengthVector   = [endLength-startLength];
                durationVector = ones(size(lengthVector)).*duration;
                waitTimeVector = ones(size(lengthVector)).*auroraConfig.minimumWaitTime;            
            case 2
    
    
                %Add a perturbation near the 
                % settingsForceLengthImpedanceDynamic.normLengths
                lengthVector = [0];
                waitTimeVector = [0];
                durationVector = [0];
                flag_emptyVectors=1;
    
                timeVectorTotal = [0,duration];
                lengthVectorTotal=[startLength,endLength];
    
                signalVec.time   = [0];
                signalVec.length = [startLength];
                lj = startLength;
                tj = 0;

                for j=1:1:length(settingsForceLengthImpedanceDynamic.normLengths(indexSeries,:))
                    ti     = tj;
                    li     = lj;
                    lj     = settingsForceLengthImpedanceDynamic.normLengths(indexSeries,j);
                    tj     = interp1(lengthVectorTotal,timeVectorTotal,lj);
                    startTime       = tj;
                    startTimeInS    = tj*(1/scaleTime);
                    timeSumInS      = startTimeInS;
                    %timeSum         = tj;
                    
                    if(flag_emptyVectors==1)
                        lengthVector    = (lj-li);
                        waitTimeVector  = auroraConfig.minimumWaitTime;
                        durationVector  = startTime-waitTimeVector;                       
                        flag_emptyVectors=0;
    
                    else
                        lengthVector = [lengthVector;(lj-li)];
                        waitTimeVector = ...
                            [waitTimeVector;...
                             auroraConfig.minimumWaitTime];
                        durationVector = ...
                            [durationVector;...
                            (tj-ti-auroraConfig.minimumWaitTime)];                    
                    end
    
                    signalVec.time = [signalVec.time;startTimeInS];
                    signalVec.length = [signalVec.length;lj];
    
                    for k=1:1:size(smallStochasticWave.controlFunctions.optionValues,1)   
                        % A length-ramp has two segments:
                        % - ramp from l0-l1 in time dt
                        % - wait at length l1
                        %
                        % I'm replacing the wait with another ramp to more
                        % closely follow the underlying function
    
                        t1 = smallStochasticWave.controlFunctions.optionValues(k,2);
                        t2 = smallStochasticWave.controlFunctions.waitDuration(k,1);
    
                        dp = smallStochasticWave.controlFunctions.optionValues(k,1);                    
    
                        ct0 = tj;%timeSum;                    
                        l0 = interp1(timeVectorTotal,lengthVectorTotal,ct0); 
    
                        ct1 = ct0+t1;                    
                        l1 = interp1(timeVectorTotal,lengthVectorTotal,ct1);
                        
                        ct2 = ct1+t2;                    
                        l2 = interp1(timeVectorTotal,lengthVectorTotal,ct2); 

                        lj = l2;
                        tj = ct2;
    
                        
                        %timeSum = ct2;
    
                        dl1 = (l1-l0)+2*dp;
                        dl2 = (l2-l1);%+dp;
    
                        if((t2-2*auroraConfig.minimumWaitTime)<=0)
                            t12 = t1+t2;
                            t2 = 2*auroraConfig.minimumWaitTime;
                            t1 = t12-t2;
                        end
                        
                        dt1 = t1-auroraConfig.minimumWaitTime;
                        wt1 = auroraConfig.minimumWaitTime;
                        dt2 = t2-auroraConfig.minimumWaitTime;
                        wt2 = auroraConfig.minimumWaitTime;
    
                        lerrA = (l2) ...
                              -interp1(timeVectorTotal,lengthVectorTotal,...
                                       (ct0+dt1+wt1+dt2+wt2));
                        here=1;
    
                        lengthVector    = [...
                            lengthVector;...
                            dl1;...
                            dl2];
    
                        waitTimeVector  = [...
                            waitTimeVector; ...
                            wt1; ...
                            wt2];

                        durationVector  = ...
                            [durationVector; ...
                            dt1;...
                            dt2];
    
                        t1InS   = dt1*(1/scaleTime);
                        wt1InS  = wt1*(1/scaleTime);
                        t2InS   = dt2*(1/scaleTime);
                        wt2InS  = wt2*(1/scaleTime);
    
                        signalVec.time = ...
                            [  signalVec.time;...
                              (signalVec.time(end)+t1InS);...
                              (signalVec.time(end)+t1InS+wt1InS);...
                              (signalVec.time(end)+t1InS+wt1InS+t2InS);...
                              (signalVec.time(end)+t1InS+wt1InS+t2InS+wt2InS)];
    
                        signalVec.length = [...
                             signalVec.length;...
                            (l1+dp);...
                            (l1+dp);...
                            (l2+dp);...
                            (l2+dp)];
    
                        lerrB = (l2) ...
                              -interp1(timeVectorTotal,lengthVectorTotal,...
                                       (signalVec.time(end).*scaleTime));
                        here=1;
    
    
                    end
                    here=1;
    
                end
    
                %The final step
                li     = signalVec.length(end);
                startTime       = interp1(lengthVectorTotal,timeVectorTotal,li);
                lj     = lengthVectorTotal(end);
                endTime       = interp1(lengthVectorTotal,timeVectorTotal,lj);

                endTimeInS      = endTime*(1/scaleTime);
                timeSumInS      = endTimeInS;
                timeSum         = endTime;
                
                lengthVector    = [lengthVector;(lj-li)];
                waitTimeVector  = [waitTimeVector;auroraConfig.minimumWaitTime];                
                durationVector  = [durationVector;(endTime-startTime)];                    
    
                signalVec.time = [signalVec.time;endTimeInS];
                signalVec.length = [signalVec.length;lj];            
    
                controlVec.time = [0];
                controlVec.length =[lengthVectorTotal(1,1)];
                for j=1:1:length(lengthVector)

                    lastTime = controlVec.time(end);
                    lastLength = controlVec.length(end);                        

                    controlVec.time = ...
                        [controlVec.time;...
                         (lastTime+durationVector(j,1));...
                         (lastTime+durationVector(j,1)+waitTimeVector(j,1))];

                    controlVec.length = ...
                        [controlVec.length;...
                         (lastLength+lengthVector(j,1));...
                         (lastLength+lengthVector(j,1))];

                end

                %%
                % Plot the ramp+perturbation
                %%
                figure(figPerturbedRamp);


                subplot('Position',reshape(subplotPanel_3R2C(indexSeries,1,:),1,4));
                    plot(timeVectorTotal.*(1/scaleTime),...
                         lengthVectorTotal,'-','Color',[1,0,0],...
                         'LineWidth',0.5);
                    hold on;            
                    plot(signalVec.time,signalVec.length,'-',...
                        'Color',colorSeries(indexSeries,:),...
                        'LineWidth',0.5);
                    hold on;
                    plot(controlVec.time.*(1/scaleTime),controlVec.length,'-',...
                        'Color',[1,0,1],...
                        'LineWidth',0.5);
                    hold on;
                    
                    hold on;
                    axis tight;
                    box off;
    
    
                    xlabel('Time (s)');
                    ylabel('Length');
                    title('Perturbed Ramp');
                subplot('Position',reshape(subplotPanel_3R2C(indexSeries,2,:),1,4));
                    yp = signalVec.length...
                        -interp1(timeVectorTotal,...
                                 lengthVectorTotal,...
                                 signalVec.time.*scaleTime);
                    plot(signalVec.time,yp,'-',...
                        'Color',colorSeries(indexSeries,:),...
                        'LineWidth',0.5);
                    hold on;
                    axis tight;
                    box off;
    
                    xlabel('Time (s)');
                    ylabel('Length');
                    title('Perturbation');
    
                
        
    
            otherwise
                assert(0,['Error: ramp-length-perturbation loop',...
                            ' is only valid for 2 iterations'])
        end
    
    
        lengthRampOptions = getCommandFunctionOptions600A('Length-Ramp',auroraConfig);
    
        [endTime, lineCount] = ...
            writeLengthRampBlock600A(...
                    fid,...
                    startTimeBlock,...
                    waitTimeVector,...
                    lengthVector,...
                    durationVector,...
                    lengthRampOptions,...
                    lineCount,...
                    auroraConfig);

        fprintf(fidLabel,'%s,%1.6f,%1.6f\n',...
            lengthRampOptions.type,startTime,endTime);
    
        startTime = endTime + auroraConfig.minimumWaitTime;    
    
        [endTime, lineCount] = ...
            writeDeactivationBlock600A(fid, startTime, lineCount, auroraConfig);
        
        startTime=endTime+auroraConfig.minimumWaitTime;
        
        [endTime, lineCount] = ...
            writeClosingBlock600A(fid, startTime, lineCount, auroraConfig);
        
        success = 1;
        assert(lineCount < auroraConfig.maximumNumberOfCommands,...
            'Error: maximumNumberOfCommandsExceeded');
        
        
        fclose(fid);
        fclose(fidLabel);
    
        idx = idx+1;    
    end
    


    if(indexSeries==1)
        configPlotExporter(figSmallPerturbation,plotConfig_3R1C);
        saveas(figSmallPerturbation,fullfile(projectFolders.output_plots,...
                        'fig_randomSquareWaveSmall'),'pdf');
        savefig(figSmallPerturbation,fullfile(projectFolders.output_plots,...
                        'fig_randomSquareWaveSmall.fig')); 
    end
    if(indexSeries==nSeries)
        configPlotExporter(figPerturbedRamp,plotConfig_3R2C);
        saveas(figPerturbedRamp,fullfile(projectFolders.output_plots,...
                        'fig_randomSquareWaveRamp'),'pdf');
        savefig(figPerturbedRamp,fullfile(projectFolders.output_plots,...
                        'fig_randomSquareWaveRamp.fig')); 
    end


end 

fclose(fidProtocol);

