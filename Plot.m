function [] = Plot(Data, meas_name, clock_startstop, tidsfel) %
%PLOT Summary of this function goes here
%   Detailed explanation goes here

tic;
disp('Creating plots...')

plotcolor = {'#A2142F', '#0000FF', '#00FF00', '#FF0000', '#00FFFF',...
    '#FF00FF', '#D95319', '#EDB120', '#7E2F8E', '#FFFF00'};
figure('units','normalized','outerposition',[0 0 1 1]);
name = fieldnames(Data);
%FelData = cell([1, sum(tidsfel)]);
k = 1;
for i = 1 : length(fieldnames(Data))
    if tidsfel(i) && sum(tidsfel) < length(name)
%FelData{k} =Data{i};
Data = rmfield(Data, name{i});
k = k + 1;
    end
end


name = fieldnames(Data);
OneMin = 1/60/24;
NO2unit = cell([1,length(name)]);
%% Lägger till datum för mätningen i titel
tic
if ~isempty(clock_startstop)
starttime = datetime(max(datenum(clock_startstop(1,:))), 'ConvertFrom', 'datenum');
endtime = datetime(min(datenum(clock_startstop(2,:))), 'ConvertFrom', 'datenum');



if datestr(starttime, ' yy-mm-dd') == datestr(endtime, ' yy-mm-dd')
    meas_name = strcat(meas_name, datestr(starttime, ' yy-mm-dd'));
elseif any(starttime_date ~= endtime_date)
    meas_name = strcat(meas_name, starttime_date, ' to ', datestr(endtime, ' yy-mm-dd'));
end

else
    
    starttime = 0;
    [M, I] = max(structfun(@height,Data));
    endtime = Data.(name{I}).processor_millis(M);
    
end

% Skapar plottar för olika fall av indata
% Plottar ut LCAQMP, ifall den är med i mätningen
% Två fall; för 1-2 LCAQMP plottas både PM2.5 och Pm10 i samma graf
% annars vid LCAQMP>2 så plottas PM2.5 och PM10 i enskilda fönster
tic;
disp('Plotting...')

% Glidande medelvärde för att undvika brus
moving_mean_amount =51;

for i = 1:length(name)
    
    subplot(2,5,[1,2])
    plot(sort(Data.(name{i}).processor_millis),movmean(Data.(name{i}).SDS011_pm25, moving_mean_amount),...
        'Color',plotcolor{i},'LineWidth',1.5);hold on;
    subplot(2,5,[6,7])
    plot(sort(Data.(name{i}).processor_millis),movmean(Data.(name{i}).SDS011_pm10, moving_mean_amount),...
        'Color',plotcolor{i},'LineWidth',1.5);hold on;
    subplot(2,5,3)
    plot(sort(Data.(name{i}).processor_millis),Data.(name{i}).BME680_humidity,'Color',plotcolor{i},'linewidth',1.5);
    hold on;
    subplot(2,5,4)
    plot(sort(Data.(name{i}).processor_millis),Data.(name{i}).BME680_temperature,'Color',plotcolor{i},'linewidth',1.5);
    hold on;
    subplot(2,5,5)
    plot(sort(Data.(name{i}).processor_millis),movmean(Data.(name{i}).CozIr_Co2_filtered, moving_mean_amount,'omitnan'),'Color',plotcolor{i},'linewidth',1.5);
    hold on;
    subplot(2,5,8)
    plot(sort(Data.(name{i}).processor_millis),Data.(name{i}).CCS811_TVOC,'Color',plotcolor{i},'linewidth',1.5);
    hold on;
    
    if max(contains(fieldnames(Data.(name{i})),'NO2'))%~isempty(Data.(name{i}).NO2)                                           % Plottar NO2 och O3 där de finns
        subplot(2,5,9);hold on
        plot(sort(Data.(name{i}).processor_millis),movmean(Data.(name{i}).NO2, moving_mean_amount, 'omitnan'),'Color',plotcolor{i},...
            'linewidth',0.5);
        subplot(2,5,10);hold on
        plot(sort(Data.(name{i}).processor_millis),movmean(Data.(name{i}).O3, moving_mean_amount, 'omitnan'),'Color',plotcolor{i},...
            'linewidth',0.5);
        
        NO2unit{i} = name{i};
    else
    NO2unit{i} = '';
    end
end

%NO2unit = NO2unit >0;

name = sort(name);
k = zeros([1, length(name)]);
for i = 1:length(name)  % Flyttar rätt alla namn, så 10 hamnar sist.
    if strfind(name{i},'UNI10')
    k(i) = strfind(name{i},'UNI10');
    end
end

if max(k)
    name(max(k)) = [];
    NO2unit(max(k)) = [];
    
  name{length(name)+1} = 'UNIT10';
  NO2unit{length(NO2unit)+1} = 'UNIT10';
end

%NO2unit = setdiff(NO2unit, []);
NO2unit(strcmp('',NO2unit)) = [];

toc
% Ordnar plottgrafik, label för axlar och legender.
tic;
disp('Setting up labels etc...')

sgtitle(meas_name);
formatHMS = 'HH:MM:SS';

% Om vi har fler än två mätare kommer denna användas, då vi får separata
% plots för pm2.5 och pm10
%PM2.5
subplot(2,5,[1, 2])
title('PM2.5');
legend(name,'Location','best','FontSize',8);
legend('boxoff');
grid on;
ylabel('Halt [Âµg/m3]');
xlabel('Tid');

% Timestamps PM2.5 (Kan vara värt att uppdatera dessa så de ger jämna
% klockslag istället för 50 minuter isär från starttid
ax = gca;
xtickelick = ax.XTick;
xtickdiff = median(diff(xtickelick));
TimeVector= (starttime:OneMin*xtickdiff:endtime);
xData = datestr(TimeVector,formatHMS);
xtickelick(end) = [];
end_time_of_day = datestr(endtime, formatHMS);
if length(xData(:,1)) ~= numel(xtickelick)
    xData(end+1,:) = char(end_time_of_day);
end
set(gca,'XTick',xtickelick);
set(gca,'XTickLabel',{xData});
set(gca,'XTickLabelRotation',30)

% PM10
subplot(2,5,[6, 7])
title('PM10');
legend(name,'Location','best','FontSize',8);
legend('boxoff');
grid on;
ylabel('Halt [Âµg/m3]');
xlabel('Tid');

% Timestamps pm10
ax = gca;
xtickelick = ax.XTick;
xtickdiff = median(diff(xtickelick));
TimeVector= (starttime:OneMin*xtickdiff:endtime);
xData = datestr(TimeVector,formatHMS);
xtickelick(end) = [];
end_time_of_day = datestr(endtime, formatHMS);
if length(xData(:,1)) ~= numel(xtickelick)
    xData(end+1,:) = char(end_time_of_day);
end
set(gca,'XTick',xtickelick);
set(gca,'XTickLabel',{xData});
set(gca,'XTickLabelRotation',30)

% Luftfuktighet
subplot(2,5,3)
title('Relativ luftfuktighet');
legend(name,'Location','best','FontSize',8);
legend('boxoff');
grid on
ylabel('%');
xlabel('Tid [min]');

% Temperatur
subplot(2,5,4)
title('Temperatur');
legend(name,'Location','best','FontSize',8);
legend('boxoff');
grid on;
ylabel([char(176) 'C']);
xlabel('Tid [min]');

% CO2
subplot(2,5,5)
title('CO2');
legend(name,'Location','best','FontSize',8);
legend('boxoff');
grid on;
xlabel('Tid [min]');
ylabel('PPM');

% VOC
subplot(2,5,8)
title('VOC');
legend(name,'Location','best','FontSize',8);
xlabel('Tid [min]');
ylabel('PPB');
legend('boxoff');grid on;

% Subplot NO2
subplot(2,5,9)
xlabel('Tid [min]')
ylabel('PPB')
title('NO2')
legend(NO2unit,'Location','best','FontSize',8);
legend('boxoff');grid on;

% Subplot O3
subplot(2,5,10)
xlabel('Tid [min]')
ylabel('PPB')
title('O3')
legend(NO2unit,'Location','best','FontSize',8);
legend('boxoff');
grid on;

% Om vi har färre än två mätare kommer denna användas, då vi får en
% gemensam plot för pm2.5 och pm10
toc


%% Variationer med avstånd
% Görs inte  mätningen på olika avstånd från väg exempelvis bör denna vara
% bortkommenterad. Planerar ni inte att göra likadana mätningar för att
% bedöma variationer med avstånd kan ni yeeta den här delen.

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

