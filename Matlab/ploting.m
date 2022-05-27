function [] = ploting(data, measName, pol, window, plotSolo, clockStartStop)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
    ploting   -   Skapar grafer för mätdatan.
    Delar upp datan i matriser med tidsdata och mätdata för enskilda
    datatyper. Tillämpar vald brusreduceringsmetod. Plottar i enskilda
    figurer för varje datatyp eller i en figur med alla datatyper beroende
    på val.

Syntax:
    [] = ploting(data, measName, pol, window, plotSolo, clockStartStop)

Inputs:
    data            -   Struct med all mätdata.
    measName        -   Mätningens namn.
    pol             -   Brusreduceringsmetod.
    window          -   Fönstret över vilken brusreduceringsmetoden
                        appliceras.
    clockStartStop  -   Matris med första och sista tid för varje enhet.

Outputs:

Exempel:

Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-10
Uppdaterad: 2202-05-27
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp('Creating plots...')

% Ger varje enhet en specifik färg.
plotColor = struct('UNIT1', '#a6cee3', 'UNIT2', '#1f78b4', ...
    'UNIT3', '#e7298a', 'UNIT4', '#33a02c', 'UNIT5', '#1b9e77', ...
    'UNIT6', '#e31a1c', 'UNIT7', '#000000', 'UNIT8', '#ff7f00', ...
    'UNIT9', '#BBBBBB', 'UNIT10', '#6a3d9a');
name = fieldnames(data);

% Används för att skapa labels längsmed X-axeln senare.
oneMin = 1 / 60 / 24;
NO2unit = cell([1, length(name)]);

% Anger storleken på texten i figurerna.
fontSize = 30;

% Använts för att justera fönstret som plottas när vi plottat med en
% referens.
beginPlotData = 1;
%stopPlotData = 4201;
plotData = struct;

% Brusreducering.
smoothing = {pol, window, 'omitnan'};

% Om man vill ha något annat tidsfönster än minuter, t ex 60 för att få
% timmar.
tidsFaktor = 1;

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

% Skapar vektorer för plottning och applicerar brusreducering.
disp('Plotting...')

for i = 1:length(name)
    
    plotData.(name{i}).pm25 = ...
        {data.(name{i}).processor_millis(beginPlotData:end)/tidsFaktor, ...
        smoothdata(data.(name{i}).SDS011_pm25(beginPlotData:end), ...
        smoothing{:})};
    
    plotData.(name{i}).pm10 = ...
        {data.(name{i}).processor_millis(beginPlotData:end)/tidsFaktor, ...
        smoothdata(data.(name{i}).SDS011_pm10(beginPlotData:end), ...
        smoothing{:})};
    
    plotData.(name{i}).humidity = ...
        {data.(name{i}).processor_millis(beginPlotData:end)/tidsFaktor, ...
        smoothdata(data.(name{i}).BME680_humidity(beginPlotData:end), ...
        smoothing{:})};
    
    plotData.(name{i}).temperature = {data.(name{i}).processor_millis/...
        tidsFaktor, smoothdata(data.(name{i}).BME680_temperature, ...
        smoothing{:})};
    
    plotData.(name{i}).co2Filtered = {data.(name{i}).processor_millis/...
        tidsFaktor, smoothdata(data.(name{i}).CozIr_Co2_filtered, ...
        smoothing{1}, smoothing{2}*6, smoothing{3})};
    
    plotData.(name{i}).VOC = {data.(name{i}).processor_millis/tidsFaktor, ...
        smoothdata(data.(name{i}).CCS811_TVOC, smoothing{:})};
    
    % Vi satte alla enheter som inte hade möjlighet at mäta NO2 till att
    % skriva -1, det här filtrerar ut så att man bara får enheter som mäter
    % i plotten.
    if max(contains(fieldnames(data.(name{i})), 'NO2')) && ...
            max(data.(name{i}).NO2) ~= -1 && min(data.(name{i}).NO2) ~= -1
        plotData.(name{i}).NO2 = {data.(name{i}).processor_millis/...
            tidsFaktor, smoothdata(data.(name{i}).NO2, smoothing{:})};
        plotData.(name{i}).O3 = {data.(name{i}).processor_millis/tidsFaktor, ...
            smoothdata(data.(name{i}).O3, smoothing{:})};
        NO2unit{i} = name{i};
    else
        NO2unit{i} = '';
    end
end

subSetting = {[1, 2], [6, 7], 3, 4, 5, 8, 9, 10};
plotColorFields = fieldnames(plotColor);

    % Tar bort så man inte har tom data så man slipper varning när den
    % skriver legend.
NO2unit(strcmp('', NO2unit)) = [];

    % Behöver ändras på om indatan ändrar ordning
    Title = {'PM2.5', 'PM10', 'Relativ luftfuktighet', 'Temperatur', ...
        'CO2', 'VOC', 'NO2', 'O3'};
    Legend = {name, name, name, name, name, name, NO2unit, NO2unit};
    Xlabel = {'Tid', 'Tid', 'Tid [min]', 'Tid [min]', 'Tid [min]', ...
        'Tid [min]', 'Tid [min]', 'Tid [min]'};
    Ylabel = {'Halt [µg/m3]', 'Halt [µg/m3]', ...
        '%', [char(176), 'C'], 'PPM', 'PPB', 'PPB', 'PPB'};

% Skriver en datatyp per fönster.
if plotSolo == 1
    
        % Ger index baserat på listan Title
        listSelect = listdlg('PromptString', {'Välj vad som ska plottas', ...
        'Kan välja flera olika samtidigt',''}, 'ListString', Title);
    
    % Anger på vilket format XTickLabel skrivs, ändra till DD/mm för datum.
    % HH:MM:SS för tid.
    formatHMS = 'DD/mm'; 
    plotColorFields = fieldnames(plotColor);
    for i = 1:length(listSelect)
        figure;
        counter = 3;
        for j = 1:length(name)
            
            % Skapar inställning för plotten baserat på vilken enhet det
            % är.
            if ~contains(name{j}, 'UNIT')
                plotSetting = {'Color', ...
                    plotColor.(plotColorFields{counter}), 'LineWidth', 2.5, ...
                    'LineStyle', ':'};
                counter = counter + 1;
            else
                plotSetting = {'Color', plotColor.(name{j}), 'LineWidth', 2.5};
            end
            
            % Plottar vald data
            fields = fieldnames(plotData.(name{j}));
                if ismember(Title{listSelect(i)}, fields)
                plot(plotData.(name{j}).(fields{listSelect(i)}){1,1}(:,1), ...
                    plotData.(name{j}).(fields{listSelect(i)}){1,2}(:,1), ...
                    plotSetting{:});
                hold on;
                elseif ~ismember(Title{listSelect(i)}, fields)
                    
                    continue
                end
        end
        
        % Redigerar titel, legend och labels i figuren.
        title(Title(listSelect(i)), 'FontSize', fontSize + 20);
        legend(Legend{listSelect(i)}, 'Location', 'best', 'FontSize', ...
            fontSize - 10);
        legend('boxoff');
        xlabel(Xlabel{listSelect(i)},'FontSize',fontSize);
        xlabel('Tid [min]','FontSize',fontSize);
        ylabel(Ylabel{listSelect(i)},'FontSize',fontSize);
        hold off
        grid on;
        
        % Sätter klockslag på X-axeln om det är PM som plottas, annars är
        % det löpande minuter.
        if ismember(Title(listSelect),Title(1:2))
            
            % Timestamps PM (Kan vara värt att uppdatera dessa så de ger jämna
            % klockslag istället för 50 minuter isär från starttid. Inget
            % vi la någon tid på 2022 förrän det skulle med bilder i
            % rapporten. Absolut värt att lista ut ungefär hur man vill att
            % ens figurer ska se ut tidigt och sätta sig in i hur man
            % skriver kod för att få det så.
            ax = gca;
            
            % Tar fram avståndet mellan varje vertikal linje i griden.
            xkdiff = median(diff(ax.XTick));
            
            % Tar fram labels för X-axeln baserat på start- och sluttid för
            % datan med en steglängd på en minut * avståndet mellan dom
            % vertikala linjerna på griden.
            xData = datestr((startTime:oneMin * xkdiff: endTime), formatHMS);
            set(ax, 'XTick', ax.XTick);
            set(ax, 'XTickLabel', {xData}, 'FontSize', fontSize);
            set(ax, 'XTickLabelRotation', 30);
        else
            set(gca, 'FontSize', fontSize)
        end
        
    end
    set(gca, 'FontSize', fontSize)
    
    % För att få XTickLabel att följa med i en zoomning i plotten använder
    % man funktionen zoom. Inte satt mig in i hur det fungerar, men tänker
    % att det kan vara något man kan pyssla med i framtiden.
%     h = zoom(fig);
%     set(h, 'ActionPostCallback', {@ZoomCallBack, fig})
    
elseif plotSolo == 0
    figure
    counter = 1;
    for i = 1:length(name)
        
        % Skapar inställning för plotten baserat på vilken enhet det
        % är.
        if ~contains(name{i}, 'UNIT')
            plotSetting = {'Color', plotColor.(plotColorFields{counter}), ...
                'LineWidth', 1.5, 'LineStyle', ':'};
            counter = counter + 1;
        else
            plotSetting = {'Color', plotColor.(name{i}), 'LineWidth', 1.5};
        end
        
        % Plottar i varje subplot
        for k = 1:length(fieldnames(plotData.(name{i})))
            fields = fieldnames(plotData.(name{i}));
            subplot(2, 5, subSetting{k})
            plot(plotData.(name{i}).(fields{k}){:, 1}, ...
                plotData.(name{i}).(fields{k}){:, 2}, plotSetting{:});
            hold on;
        end
    end
    
    % Ordnar plottgrafik, label för axlar och legender.
    disp('Setting up labels etc...')
    sgtitle(measName);
    formatHMS = 'HH:MM:SS';
    
    subLabeling.title = Title;
    subLabeling.legend = Legend;
    subLabeling.xlabel = Xlabel;
    subLabeling.ylabel = Ylabel;
    for i = 1:length(subSetting)
        subplot(2, 5, subSetting{i})
        title(subLabeling.title{i});
        legend(subLabeling.legend{i}, 'Location', 'best', 'FontSize', 8);
        legend('boxoff');
        xlabel(subLabeling.xlabel{i});
        ylabel(subLabeling.ylabel{i});
        grid on;
        
        if i <= 2
            ax = gca;
            xkdiff = median(diff(ax.XTick));
            xData = datestr((startTime:oneMin * xkdiff:endTime), formatHMS);
            set(ax, 'XTick', ax.XTick);
            set(ax, 'XTickLabel', {xData});
            set(ax, 'XTickLabelRotation', 30);
        end
        
        %% Variationer med avstånd
        % Görs inte  mätningen på olika avstånd från väg exempelvis bör denna vara
        % bortkommenterad. Planerar ni inte att göra likadana mätningar för att
        % bedöma variationer med avstånd kan ni yeeta den här delen. 2022
        % har inte arbetat eller använt den här koden någonting.
        
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
end

end