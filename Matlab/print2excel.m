function [] = print2excel(data)

name = fieldnames(data);
%T = table('VariableNames', {'Processor_millis', 'Year', 'Month', 'Day', 'Hour', 'Minute', 'Seconds', 'CO2'});
VariableNames = {'Processor_millis', 'Year', 'Month', 'Day', 'Hour', 'Minute', 'Seconds', 'CO2'};
for i = 1:length(name)
    filename = 'CO2data.xlsx';
    writecell(VariableNames,filename,"Sheet" ,char(name{i}),"Range",'A1'); % save column headers in first line
    T = [data.(name{i}).processor_millis, data.(name{i}).GPS_year, ...
        data.(name{i}).GPS_month, data.(name{i}).GPS_day, ...
        data.(name{i}).GPS_hour, data.(name{i}).GPS_minute, ...
        data.(name{i}).GPS_seconds, data.(name{i}).CozIr_Co2_filtered];
writematrix(T,filename,"Sheet" ,char(name{i}),"Range",'A2'); % save data (cell) to excel file
end
end