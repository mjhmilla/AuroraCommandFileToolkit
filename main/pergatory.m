%Johnson is at 37 C

%%
% Approximate specimen properties
%%
%From: Table II of
%
%W. L. Johnson, D. L. Jindrich, H. Zhong, R. R. Roy and V. R. Edgerton, 
% "Application of a Rat Hindlimb Model: A Prediction of Force Spaces 
% Reachable Through Stimulation of Nerve Fascicles," in IEEE 
% Transactions on Biomedical Engineering, vol. 58, no. 12, pp. 
% 3328-3338, Dec. 2011, doi: 10.1109/TBME.2011.2106784. 

g2N                 = 9.81*0.001;
switch muscleName
    case 'EDL'

        muscleParams.fisoN     = 265*g2N;   %225g 
        muscleParams.lceOptMM  = 13.7;      %mm 
        muscleParams.vceMaxLPS  = 243/muscleParams.lceOptMM; %Lo/s  
        muscleParams.alphaOpt  = deg2rad(10);
        muscleParams.ltSlkMM   = 9;         %mm
        muscleParams.etIso     = 0.033; % Johnson et al. took the default value from Zajac
    case 'SOL'
        muscleParams.fisoN     = 234*g2N;   %225g 
        muscleParams.lceOptMM  = 16.0;      %mm 
        muscleParams.vceMaxLPS = 89/muscleParams.lceOptMM; %Lo/s  
        muscleParams.alphaOpt  = deg2rad(4);
        muscleParams.ltSlkMM   = 9.5;         %mm
        muscleParams.etIso     = 0.033; % Johnson et al. took the default value from Zajac
    case 'CAL'
        muscleParams.fisoN     = 1;     %225g 
        muscleParams.lceOptMM  = 10.0;  %mm 
        muscleParams.vceMaxLPS = 100; %Lo/s  
        muscleParams.alphaOpt  = 0;
        muscleParams.ltSlkMM   = muscleParams.lceOptMM;         %mm
        muscleParams.etIso     = 0.0;       
    otherwise
        assert(0,'Error: Invalid muscle name');
end




lceOptMM = nan;
vceMaxLPS = nan;
if(isempty(measuredMuscleParams.lceOptMM)==0)
    lceOptMM = measuredMuscleParams.lceOptMM;
else
    lceOptMM = muscleParams.lceOptMM;
end

if(isempty(measuredMuscleParams.vceMaxMMPS)==0 ...
    && isempty(measuredMuscleParams.lceOptMM)==0)
    vceMaxLPS = measuredMuscleParams.vceMaxMMPS ...
               /measuredMuscleParams.lceOptMM;
else
    vceMaxLPS = muscleParams.vceMaxLPS;
end

disp('Generating dpf files for:');
disp(muscleName);
fprintf('%1.1f mm\tlceOpt\n',lceOptMM);
fprintf('%1.1f lps\tvceMaxLPS\n',vceMaxLPS);