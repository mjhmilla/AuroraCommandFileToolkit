function expConfig = getDefaultExperimentConfiguration610A()


expConfig.normalization.forceVelocity.lengthsMM = [   1,-1;...
                                                     -1, 1];

expConfig.normalization.forceVelocity.forceRampDurationS = [1;nan];
expConfig.normalization.forceVelocity.forceRampForceMN   = [1;nan];

expConfig.normalization.forceVelocity.velocityRangeMMPS = [nan;10];

expConfig.endNormLength = 0;

expConfig.passive.normLengths           = [ -0.35, 0.35 ];

expConfig.passive.normVelocityRange     = [ (1/3), (2/3)];

expConfig.isometric.normLengthRange     = [-0.4, 0.4];

%Only used in characterization experiments
expConfig.activeRamp.lengthOffset = [0,-0.4,0.4];

expConfig.activeRamp.normLengthRange    = [ 0.1,-0.1;...
                                            0.1,-0.1;...
                                           -0.1, 0.1;...
                                           -0.1, 0.1]; 

expConfig.activeRamp.normVelocityRange  = [-(1/3);...
                                           -(2/3);...
                                            (1/3);... 
                                            (2/3)];

expConfig.activeInjury.normLengthRange  = [-0.1,0.5,-0.1];
expConfig.activeInjury.normVelocityRange= [ 1/2, -1/2];


%Only used in characterization experiments;
expConfig.stretchShortening.lengthOffset    = [-0.4,-0.1,0.4];

expConfig.stretchShortening.normLengthRange = [  0, 0.1,   0;...
                                                 0, 0.1,   0;...
                                               0.1,   0, 0.1;...
                                               0.1,   0, 0.1];

expConfig.stretchShortening.normVelocityRange = [(1/3),-(1/3);...
                                                 (2/3),-(2/3);...
                                                -(1/3), (1/3);...
                                                -(2/3), (2/3)];
