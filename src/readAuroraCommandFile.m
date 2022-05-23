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
        
        here=1;
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
        auroraCommandFile.time = [t1];  
        auroraCommandFile.length = [l1];
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
            auroraCommandFile.length;l1];
        auroraCommandFile.time = [auroraCommandFile.time; t1];
    end

    
    %updLen = auroraCommandFile.signalLengthUnbiased(end,1) + ...
    %    double(fields{3});

    %auroraCommandFile.signalLengthUnbiased=...
    %    [auroraCommandFile.signalLengthUnbiased;...
    %    updLen];
        

    idx=idx+1;
    line=fgetl(fid);
end

fclose(fid);
