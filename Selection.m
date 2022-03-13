function [Data, timeDN] = Selection()
tic;
disp('Choosing and loadingb csv file into Data struct')

name = string;                                                              % name kommer innehålla alla namn


[FileID, path] = uigetfile('*.csv','Select .CSV file from LCAQMP to evaluate','MultiSelect', 'on');                   
%path = 'C:\Users\sebas\Downloads\Data Referens i tält\';
%FileID = cellstr({'UNIT2_07.CSV','UNIT3_03.CSV','UNIT4_03.CSV','UNIT5_14.CSV','UNIT6_27.CSV','UNIT7_17.CSV','UNIT8_02.CSV','UNIT9_04.CSV'});
FileID = cellstr(FileID);                                                   % Namn på filen (string i en cell)
LCAQMP_used = length(FileID);                                               % ändrar till antalet använda.
timeDN = {length(FileID)};
for i = 1:LCAQMP_used
    name(i) = FileID{i}(1:end-7);                                           % end-4 tar bort ".csv" från filnamnen, end-7 tar bort "-XX.csv"
    FileDir = append(path,FileID{i});
   
    opts = detectImportOptions(FileDir);
    opts.VariableNamesLine = 1;
    Data.(name(i)) = readtable(FileDir, opts, 'ReadVariableNames', true);    % Sparar till Data.UNITX
    
    Data.(name{i}).processor_millis = Data.(name{i}).processor_millis / (60*1000);
    Data.(name{i}).GPS_year = Data.(name{i}).GPS_year + 2000;
    Data.(name{i}).GPS_hour = Data.(name{i}).GPS_hour - 1;
    
    timeDN{i} = datenum(datetime(Data.(name{i}).GPS_year,Data.(name{i}).GPS_month,Data.(name{i}).GPS_day, Data.(name{i}).GPS_hour,Data.(name{i}).GPS_minute,Data.(name{i}).GPS_seconds));
end
%%fields = fieldnames(Data.(name{1}));
if LCAQMP_used > 10 || LCAQMP_used < 0
    msgbox('Incorrect value for no of LCAQMP');
    error('Incorrect value for no of LCAQMP');
end

toc
end