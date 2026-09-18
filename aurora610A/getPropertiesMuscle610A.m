function configMuscle= getPropertiesMuscle610A(muscleName,temperatureC,...
                                  lceOptMM_measured, vceOptMMPS_measured,...
                                  verbose)

configMuscle = [];

switch muscleName
    case 'EDL'

        refData.temperatureC            = [  22,    37    ];        
        refData.lceOptMM                = [   9.8,   9.8  ];  %From our exp: 20260311
        refData.vceMaxMMPS              = [  70,   167.5  ];  %Ranatunga 1984 Fig.4

        [tempError,idxMin] = min(abs(refData.temperatureC-temperatureC));

        configMuscle.name                 = 'EDL';
        configMuscle.temperatureC           = temperatureC                  ;
        configMuscle.referenceTemperature   = refData.temperatureC(idxMin)  ;
        if(~isempty(lceOptMM_measured))
          configMuscle.lceOptMM = lceOptMM_measured;
        else
          configMuscle.lceOptMM               = refData.lceOptMM(idxMin)      ;
        end
        if(~isempty(vceOptMMPS_measured))
          configMuscle.vceMaxMMPS = vceOptMMPS_measured;
        else
          configMuscle.vceMaxMMPS             = refData.vceMaxMMPS(idxMin)    ;
        end
        configMuscle.vceMaxLPS  = configMuscle.vceMaxMMPS/configMuscle.lceOptMM;
        configMuscle.passiveRelaxationTime  = 10;
        assert(abs(refData.temperatureC(idxMin)-temperatureC)<5,...
               'Error: target temperature differs from reference by 5C');

    case 'SOL'
        assert(0,'Error: Populate the solues settings');
    case 'GL'

        configMuscle.name                   = 'GL';
        configMuscle.temperatureC           = temperatureC                  ;
        configMuscle.referenceTemperature   = 37;
        configMuscle.lceOptMM   = mean([13.7,14.7,13.3]); %Reuvers et al. 2026
        configMuscle.vceMaxMMPS = mean([144,147,140]); %Reuvers et al. 2026
        configMuscle.vceMaxLPS  = configMuscle.vceMaxMMPS/configMuscle.lceOptMM;
        configMuscle.passiveRelaxationTime  = 10;
    
    otherwise 
        assert(0,'Error: unrecognized muscle name');
end



if(verbose==1)
    settingsFields = fields(configMuscle);
    fprintf('getPropertiesMuscle610A\n')
    for idxF = 1:1:length(settingsFields)
      param = num2str(configMuscle.(settingsFields{idxF}));
      if(isnumeric(param))
        fprintf('\t%1.1f\t%s\n',param,settingsFields{idxF});
      else
        fprintf('\t%s\t%s\n',param,settingsFields{idxF});
      end
    end
    fprintf('\n\n');
end