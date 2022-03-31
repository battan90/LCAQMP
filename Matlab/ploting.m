function [] = ploting(data, measName, clockStartStop, pol, window) %
%PLOT Summary of this function goes here
%   Detailed explanation goes here

disp('Creating plots...')

plotColor = struct('UNIT1', '#a6cee3', 'UNIT2', '#1f78b4', ...
    'UNIT3', '#e7298a', 'UNIT4', '#33a02c', 'UNIT5', '#1b9e77', ...
    'UNIT6', '#e31a1c', 'UNIT7', '#000000', 'UNIT8', '#ff7f00', ...
    'UNIT9', '#BBBBBB', 'UNIT10', '#6a3d9a');
figure('units', 'normalized', 'outerposition', [0, 0, 1, 1]);
name = fieldnames(data);
OneMin = 1 / 60 / 24;
NO2unit = cell([1, length(name)]);

%% Lägger till datum för mätningen i titel

if ~isempty(clockStartStop)
    startTime = datetime(max(datenum(clockStartStop(1, :))), ...
        'ConvertFrom', 'datenum');
    endTime = datetime(min(datenum(clockStartStop(2, :))), ...
        'ConvertFrom', 'datenum');

    if datestr(startTime, ' yy-mm-dd') == datestr(endTime, ' yy-mm-dd')
        measName = strcat(measName, datestr(startTime, ' yy-mm-dd'));
    elseif any(startTime ~= endTime)
        measName = strcat(measName, datestr(startTime, ' yy-mm-dd'), ...
            ' to ', datestr(endTime, ' yy-mm-dd'));
    end

else

    startTime = 0;
    [M, I] = max(structfun(@height, data));
    endTime = data.(name{I}).processor_millis(M);

end

% Skapar plottar för olika fall av indata

disp('Plotting...')

plotData = struct;
smoothing = {pol, window, 'includenan'};
for i = 1:length(name)
    plotData.(name{i}).pm25 = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).SDS011_pm25, smoothing{:})};

    plotData.(name{i}).pm10 = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).SDS011_pm10, smoothing{:})};

    plotData.(name{i}).humidity = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).BME680_humidity, smoothing{:})};

    plotData.(name{i}).temperature = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).BME680_temperature, smoothing{:})};

    plotData.(name{i}).co2Filtered = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).CozIr_Co2_filtered, smoothing{:})};

    plotData.(name{i}).voc = {data.(name{i}).processor_millis, ...
        smoothdata(data.(name{i}).CCS811_TVOC, smoothing{:})};

    if max(contains(fieldnames(data.(name{i})), 'NO2'))
        plotData.(name{i}).no2 = {data.(name{i}).processor_millis, ...
            smoothdata(data.(name{i}).NO2, smoothing{:})};
        plotData.(name{i}).o3 = {data.(name{i}).processor_millis, ...
            smoothdata(data.(name{i}).O3, smoothing{:})};
        NO2unit{i} = name{i};
    else
        NO2unit{i} = '';
    end
end

subSetting = {[1, 2], [6, 7], 3, 4, 5, 8, 9, 10};

for i = 1:length(name)
    plotsetting = {'Color', plotColor.(name{i}), 'LineWidth', 1.5};
    for k = 1:length(fieldnames(plotData.(name{i})))
        fields = fieldnames(plotData.(name{i}));
        subplot(2, 5, subSetting{k})
        plot(plotData.(name{i}).(fields{k}){:, 1}, plotData.(name{i}).(fields{k}){:, 2}, plotsetting{:});
        hold on;
    end
end

NO2unit(strcmp('', NO2unit)) = [];

% Ordnar plottgrafik, label för axlar och legender.

disp('Setting up labels etc...')
sgtitle(measName);
formatHMS = 'HH:MM:SS';

subLabeling.title = {'PM2.5', 'PM10', 'Relativ luftfuktighet', 'Temperatur', ...
    'CO2', 'VOC', 'NO2', 'O3'};
subLabeling.legend = {name, name, name, name, name, name, NO2unit, NO2unit};
subLabeling.xlabel = {'Tid', 'Tid', 'Tid [min]', 'Tid [min]', 'Tid [min]', ...
    'Tid [min]', 'Tid [min]', 'Tid [min]'};
subLabeling.ylabel = {'Halt [Âµg/m3]', 'Halt [Âµg/m3]', ...
    '%', [char(176), 'C'], 'PPB', 'PPB', 'PPB', 'PPB'};

for i = 1:length(subSetting)
    subplot(2, 5, subSetting{i})
    title(subLabeling.title{i});
    legend(subLabeling.legend{i}, 'Location', 'best', 'FontSize', 8);
    legend('boxoff');
    xlabel(subLabeling.xlabel{i});
    ylabel(subLabeling.ylabel{i});
    grid on;


    if i <= 2
        % Timestamps PM (Kan vara värt att uppdatera dessa så de ger jämna
        % klockslag istället för 50 minuter isär från starttid
        ax = gca;
        xkdiff = median(diff(ax.XTick));
        xData = datestr((startTime:OneMin * xkdiff:endTime), formatHMS);
        %         end_time_of_day = datestr(endTime, formatHMS);
        %         if length(xData(:, 1)) ~= numel(ax.XTick(1,end-1))
        %             xData(end+1, :) = char(end_time_of_day);
        %         end
        set(gca, 'XTick', ax.XTick);
        set(gca, 'XTickLabel', {xData});
        set(gca, 'XTickLabelRotation', 30)
    end

    %% Variationer med avstånd
    % Görs inte  mätningen på olika avstånd från väg exempelvis bör denna vara
    % bortkommenterad. Planerar ni inte att göra likadana mätningar för att
    % bedöma variationer med avstånd kan ni yeeta den här delen.

    % longitude = zeros([1, length(fieldnames(data))]);
    % latitude = zeros([1, length(fieldnames(data))]);
    % for i = 1: length(name)
    %     longitude(i) = data.(name{i}).GPS_longitude(1);
    %     latitude(i) = data.(name{i}).GPS_latitude(1);
    % end
    % for i = 2:length(name)-1
    %     disp(stdist([longitude(i-1), longitude(i)], [latitude(i-1), latitude(i)]));
    % end

    % PM10_means = [];
    % PM25_means = [];
    %
    % for i = 1:length(LCAQMP_units)
    %     if LCAQMP_units(i) == 1
    %         PM10_means(i) = mean(PM10{i});
    %         PM25_means(i) = mean(PM25{i});
    %     end
    % end
    %
    % % lägg in avstånden från "utsläppspunkten", och
    % % DISTANCES = [-10, 35, 85, 120]; % Gårda
    % DISTANCES = [0, 45, 120, 210, 330]; % Botaniska
    % PM10_pair_means = [mean([PM10_means(1), PM10_means(5)]), mean([PM10_means(3), PM10_means(9)]), mean([PM10_means(4), PM10_means(6)]), mean([PM10_means(2), PM10_means(7)]) mean([PM10_means(10), PM10_means(8)])];
    % PM25_pair_means = [mean([PM25_means(1), PM25_means(5)]), mean([PM25_means(3), PM25_means(9)]), mean([PM25_means(4), PM25_means(6)]), mean([PM25_means(2), PM25_means(7)]) mean([PM25_means(10), PM25_means(8)])];
    %
    % figure
    % subplot(1,2,1);
    % hold on;
    % plot(DISTANCES, PM25_pair_means, '.', 'MarkerSize', 25)
    % ylabel('Halt [Âµg/m3]');
    % xlabel('Avstånd från Dag Hammarskjöldsleden [m]');
    % title('PM2,5');
    % grid on;
    % xlim([min(DISTANCES)-10, max(DISTANCES)+10]);
    % yMax = max([max(PM25_pair_means), max(PM10_pair_means)])*1.1;
    % ylim([0, yMax])
    %
    % subplot(1,2,2);
    % hold on;
    % plot(DISTANCES, PM10_pair_means, '.', 'MarkerSize', 25)
    % ylabel('Halt [Âµg/m3]');
    % xlabel('Avstånd från Dag Hammarskjöldsleden [m]');
    % title('PM10');
    % grid on;
    % xlim([min(DISTANCES)-10, max(DISTANCES)+10]);
    % ylim([0, yMax])

end