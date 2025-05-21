function auroraCommandFile = readAuroraCommandFile(fileName)
%%
% @author M.Millard
% @date May 2022
%
% @param fileName: 
%  The full path and name of the *.pro file to be read
% @return auroraCommandFile
%  A structure containing fields of
%    
%     type          : 1st line of the header 
%     date          : 2nd line of the header 
%     sampleRate    : 3rd line of the header 
%     comment       : 4th line of the header 
%     minimumLength : 5th line of the header
%     maximumLength : 6th line of the header
%     PDDeadband    : 7th line of the header 
%     stimulusBlock : 8th line of the header
%
%     time               : Time column
%     controlFunction    : Control function column
%     lengthChange       : Extracted from the options column
%     timeChange         : Extracted from the options column
%     length             : Accumulated length change
%     signalTime         : Signal time points (including a hold time for
%                           the post-ramp pause)
%     signalLengthChange : Signal value (including a hold time for
%                           the post-ramp pause),
%%

auroraCommandFile = struct('type',[],'date',[],'sampleRate',[],...
                           'comment',[],'minimumLength',[],'maximumLength',[],...
                           'PDDeadband',[],'stimulusBlock',[],...
                           'time',[], 'length',[], ...
                           'controlFunction', [], 'lengthChange', [],...
                           'timeChange',[] ,...
                           'signalTime',[],'signalLengthChange',[]);

fid =fopen(fileName,'r');

auroraCommandFile.type = fgetl(fid);
auroraCommandFile.date = fgetl(fid);

line = fgetl(fid);
fields = textscan(line,'%s %s %s %d %s');
auroraCommandFile.sampleRate = double(fields{4});

auroraCommandFile.comment = fgetl(fid);
auroraCommandFile.minimumLength = fgetl(fid);
auroraCommandFile.maximumLength = fgetl(fid);
auroraCommandFile.PDDeadband = fgetl(fid);

line = fgetl(fid);
while contains(line,'Time')==0
    if(isempty(auroraCommandFile.stimulusBlock)==0)
        auroraCommandFile.stimulusBlock = ...
            [auroraCommandFile.stimulusBlock;...
                                           {line}];
    else
        auroraCommandFile.stimulusBlock = {line};
    end
    
    line = fgetl(fid);
end

%% Header
assert(contains(line,'Time')==1);
line=fgetl(fid);
assert(contains(line,'Data-Enable')==1);


line=fgetl(fid);

auroraCommandFile.time          = [];
auroraCommandFile.length        = [];
auroraCommandFile.lengthChange  = [];
auroraCommandFile.timeChange    = [];
auroraCommandFile.signalTime    = [];
auroraCommandFile.signalLengthChange   = [];
auroraCommandFile.signalLength=[];
ms2s=0.001;

%Go to the first length change
if(contains(line,'Length-Ramp')==0)
    while ischar(line)    
        line = fgetl(fid);
        if(ischar(line))
            if(contains(line,'Length-Ramp')==1)
                break;
            end
        end
    end
end

if(ischar(line))
    auroraCommandFile.time          = [0];
    auroraCommandFile.length        = [0];
    auroraCommandFile.lengthChange  = [0];
    auroraCommandFile.timeChange    = [0];
    auroraCommandFile.signalTime    = [0];
    auroraCommandFile.signalLengthChange   = [0];
    auroraCommandFile.signalLength=[0];


    idx=1;


    while contains(line,'Length-Ramp')==1
        fields=textscan(line, '%f %s %f Lo  %d ms');

        if(isempty(fields{3}))
            fields=textscan(line, '%f %s %s Lo  %d ms');
            if(contains(fields{3},'-'))
                fields{3} = double(-0);
            else
                fields{3} = double(0);
            end
        end
    
        if(isempty(auroraCommandFile.time))    

            auroraCommandFile.controlFunction = [fields{2}];
            auroraCommandFile.lengthChange = [double(fields{3})];
            auroraCommandFile.timeChange = [double(fields{4}).*ms2s];
            t0= double(fields{1}).*ms2s;
            t1=t0+double(fields{4}).*ms2s;
        
            l0= double(fields{3});
            l1= double(fields{3});
        
            auroraCommandFile.signalTime = [t0;...
                                            t1];
            auroraCommandFile.signalLengthChange = [l0;l1];
            auroraCommandFile.time = [t0;t1];  
            auroraCommandFile.length = [l0;l1];
        else
            auroraCommandFile.controlFunction = [auroraCommandFile.controlFunction;...
                                                 fields{2}];
            auroraCommandFile.lengthChange = [auroraCommandFile.lengthChange;...
                                              double(fields{3})];
            auroraCommandFile.timeChange = [auroraCommandFile.timeChange;...
                                              double(fields{4}).*ms2s];
    
        
            l0=auroraCommandFile.signalLengthChange(end);
            l1= l0+double(fields{3});
        
            t0=double(fields{1}).*ms2s;
            t1=t0+double(fields{4}).*ms2s;
    
            auroraCommandFile.signalTime = [auroraCommandFile.signalTime;...
                                            t0;...
                                            t1];
            auroraCommandFile.signalLengthChange = [...
                auroraCommandFile.signalLengthChange;l0;l1];
    
            l0=auroraCommandFile.length(end);
            l1= l0+double(fields{3});
    
            auroraCommandFile.length = [...
                auroraCommandFile.length;l0;l1];
            auroraCommandFile.time = [auroraCommandFile.time; t0;t1];
        end
    
        idx=idx+1;
        line=fgetl(fid);
    end
    
    fields=textscan(line, '%f %s %f Lo  %d ms');
    auroraCommandFile.controlFunction = [auroraCommandFile.controlFunction;...
                                         fields{2}];
    auroraCommandFile.lengthChange = [auroraCommandFile.lengthChange;...
                                      0.];
    auroraCommandFile.timeChange = [auroraCommandFile.timeChange;...
                                    (double(fields{1}).*ms2s ...
                                     - auroraCommandFile.timeChange(end))];


    l0 = auroraCommandFile.signalLengthChange(end);
    l1 = l0;

    t0=double(fields{1}).*ms2s;
    t1=t0+double(fields{4}).*ms2s;

    auroraCommandFile.signalTime = [auroraCommandFile.signalTime;...
                                    t0;...
                                    t1];
    auroraCommandFile.signalLengthChange = [...
        auroraCommandFile.signalLengthChange;l0;l1];

    l0=auroraCommandFile.length(end);
    l1= l0;

    auroraCommandFile.length = [...
        auroraCommandFile.length;l0];
    auroraCommandFile.time = [auroraCommandFile.time; t0];

end
fclose(fid);
