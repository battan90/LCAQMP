% f = fopen('Ny(tt) Textdokument.txt');
% fscanf(f', ''%s')
fields = {'processor_millis', 'SDS011_pm25', 'SDS011_pm10', 'BME680_temperature', 'BME680_pressure', 'BME680_humidity', 'BME680_gasResistance', 'CCS811_C02', 'CCS811_TVOC', 'GPS_year', 'GPS_month', 'GPS_day', 'GPS_hour', 'GPS_minute', 'GPS_seconds', 'GPS_longitude', 'GPS_latitude', 'GPS_noSaltilites', 'GPS_fix', 'CozIr_Co2', 'CozIr_Co2_filtered', 'SN1_WE_u', 'SN1_AE_u', 'SN2_WE_u', 'SN2_AE_u', 'NO2', 'O3', 'PT1000Temp', 'Errors'};
% for i = length(fields)
% UNIT10 = struct(fields{i}, {});
% end
fid = fopen('Ny(tt) Textdokument.txt');
tline = fgetl(fid);
k = 1;
UNIT10 = struct;
while ischar(tline)
    temp = regexp(tline, ',', 'split');
    if ~isempty(temp{1})
    if max(~contains(fieldnames(UNIT10), temp{1})) && max(contains(fields,temp{1}))
    for i = 1:length(temp)/2
        UNIT10 = struct(temp{i}, temp{length(temp)/2 + i});
    end
    elseif max(contains(fields,temp{1}))
        for i = 1:length(temp)/2
        UNIT10.(temp{i})(end+1) = temp{length(temp)/2 + i};
        end
    end
    end
            
    %disp(tline)
    tline = fgetl(fid);
    k = k + 1;
end