%function [Data, timeDN] = Selection(FileID, path)
function [data, timeDN] = selection()
%{
    selection   -   Tar fram datan och skapar en struct för vidare hantering


Syntax:
    [data, timeDN] = Selection()

Inputs:


Outputs:
    data        -   Struct med all mätdata
    timeDN      -   Cellarray med en vektor för varje enhet innehållande
                    GPS-värden för datum och tid i datenum-format.

Exempel:

Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-10
Uppdaterad: 2202-03-14
%}

disp('Choosing and loading csv file into Data struct')
name = string;
[fileID, path] = uigetfile('*.csv',...
    'Select .CSV file from LCAQMP to evaluate','MultiSelect', ...
    'on');
%Användt vid utveckling för att inte behöva välja filer
% fileID = {'UNI10.CSV','UNIT1.CSV','UNIT2.CSV','UNIT3.CSV','UNIT4.CSV','UNIT5.CSV','UNIT6.CSV','UNIT7.CSV','UNIT8.CSV','UNIT9.CSV'};
% path = 'C:\Users\sebas\Downloads\Fältmätningar\Fältmätningar\Botaniska 13-15 apr\';
fileID = cellstr(fileID);
timeDN = {length(fileID)};
for i = 1:length(fileID)
    if contains(fileID{i}, '_')
        temp = regexp(fileID{i}, '_', 'split');
        name(i) = temp(1);
    else
        temp = regexp(fileID{i}, '\.', 'split');
        name(i) = temp(1);
    end
    fileDir = append(path,fileID{i});
    
    opts = detectImportOptions(fileDir);
    opts.VariableNamesLine = 1;
    data.(name(i)) = readtable(fileDir, opts, 'ReadVariableNames', true);
    
    data.(name{i}).processor_millis = data.(name{i}).processor_millis / ...
        (60*1000);
    data.(name{i}).GPS_year = data.(name{i}).GPS_year + 2000;
    data.(name{i}).GPS_hour = data.(name{i}).GPS_hour - 1;
    
    timeDN{i} = datenum(datetime(data.(name{i}).GPS_year, ...
        data.(name{i}).GPS_month, data.(name{i}).GPS_day, ...
        data.(name{i}).GPS_hour, data.(name{i}).GPS_minute, ...
        data.(name{i}).GPS_seconds));
end
if max(contains(fieldnames(data), 'UNI10'))
    data.UNIT10 = data.UNI10;
    data = rmfield(data, 'UNI10');
    timeDN{length(timeDN)+1} = timeDN{1};
    timeDN(1) = [];
end
end