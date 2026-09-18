function success = writeTimeSeriesDataAndImages610A(...                     
                      programMetaData,...
                      auroraConfig,...
                      trialFileNameNoExt,...
                      expFolders)


dataColumnsExpected = {'time_ms','length_mm','stimulation_trigger'};
for idxA = 1:1:length(programMetaData.dataColumns)
  assert(strcmp(programMetaData.dataColumns{idxA},...
          dataColumnsExpected{idxA}),...
          'Error: programMetaData.dataColumns differs from expectations');
end

success=0;
tStart = programMetaData.data(1,1);
tEnd   = programMetaData.data(end,1);

sampleFrequencyHz = auroraConfig.analogToDigitalSampleRateHz;
dt_s = 1/sampleFrequencyHz;
timeSeries=[tStart:dt_s:tEnd]';

%[valUnique,idxUnique] = unique(programMetaData.data(:,1));

dataSeries = zeros(size(programMetaData.data,1),...
                   size(programMetaData.data,2));
dataSeries(:,1)=programMetaData.data(:,1);

dataSeries(:,2)=interp1(programMetaData.data(:,1),...
                        programMetaData.data(:,2),...
                        dataSeries(:,1));
dataSeries(:,3)=interp1(programMetaData.data(:,1),...
                        programMetaData.data(:,3),...
                        dataSeries(:,1));

fidCsv = fopen(fullfile(expFolders.rootFolderPath,...
                        expFolders.timeSeriesDataFolderName,...
                        [trialFileNameNoExt,'.csv']),'w');

assert(strcmp(auroraConfig.unitSystem,'mm_mN_s_Hz'),...
       ['Error: Time-series data generation for Sine Wave', ...
        ' only functions for mm_mN_s_Hz']);


fprintf(fidCsv,'time_s,length_mm,stimulation');

for i=1:1:size(dataSeries,1)
  fprintf(fidCsv,'%1.6f,%1.6f,%i\n',...
    dataSeries(i,1),dataSeries(i,2),dataSeries(i,3));
end
fclose(fidCsv);

plotConfig.numberOfHorizontalPlotColumns    = 1;
plotConfig.numberOfVerticalPlotRows         = 1;
plotConfig.plotWidth                        = 16.0;
plotConfig.plotHeight                       = 5.0;
plotConfig.plotHorizMarginCm                = 1;
plotConfig.plotVertMarginCm                 = 1;
plotConfig.baseFontSize                     = 8;

[subplotPanel,plotConfig]=plotConfigGeneric(plotConfig);
plotConfig.pageWidth = plotConfig.plotWidth+2*plotConfig.plotHorizMarginCm;
plotConfig.pageHeight= plotConfig.plotHeight+2*plotConfig.plotVertMarginCm;

figTrialPlot=figure;
subplot('Position',reshape(subplotPanel(1,1,:),1,4));
  yyaxis left;
  plot(dataSeries(:,1),dataSeries(:,2),'LineWidth',1);
  hold on;
  lrange=[min(dataSeries(:,2)),max(dataSeries(:,2))];
  lrangeUpd= lrange + [-0.01,0.01].*(lrange(2)-lrange(1));
  xlim([tStart,tEnd]);
  ylim(lrangeUpd);
  xlabel('Time (s)');
  ylabel('Length (mm)');

  yyaxis right;  
  plot(dataSeries(:,1),dataSeries(:,3),'LineWidth',1);
  hold on;
  xlim([tStart,tEnd]);  
  ylim([-0.01,1.01]);
  ylabel('Stimulation (0/1)');

  box off;

  titleText=strrep(trialFileNameNoExt,'_','\_');
  titleText=['Time-series data: ',titleText];

  title(titleText);

  configPlotExporter(figTrialPlot,plotConfig);

  saveas(figTrialPlot,...
         fullfile( expFolders.rootFolderPath,...
                   expFolders.timeSeriesImagesFolderName,...
                   [trialFileNameNoExt,'.png']),'png');
close(figTrialPlot);
  
