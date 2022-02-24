clear; 
close all;
clc;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detta script har anv�nts f�r att visualisera data uppm�tt med LCAQMP.
% Det �r lite r�rigt, men funkar helt ok f�r det mesta vid det h�r
% laget. Jag f�rs�ker f�rklara lite vad alla delar g�r och varf�r de �r
% d�r i kommentarer, men jag �r 100 % s�ker p� att saker fortfarande �r 
% oklara. Ni f�r g�rna h�ra av er om ni har funderingar s� kan jag f�rs�ka 
% f�rklara om jag har tid :) Vill ni ha allm�n uppstart eller n�gon form
% av genomg�ng kan ni ocks� h�ra av er s� kan vi nog l�sa det!
% //Axel Eiman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Namn p� m�tningen
input = inputdlg("Namn p� m�tning", "Namn p� m�tning");
if input == ""
    meas_name = 'Nordstan och �ngg�rdsbergen, ';                            % �ndra f�r att l�gga till titel vid graferna
else 
    meas_name = input;
end
% meas_name = 'Nordstan och �ngg�rdsbergen, ';
%% �ppna f�nster f�r att v�lja .csv data
tic;
disp('Choosing and loadingb csv file into Data struct')
name = string;                                                              % name kommer inneh�lla alla namn
[FileID, path] = uigetfile('*.csv','Select .CSV file from LCAQMP to evaluate','MultiSelect', 'on');
FileID = cellstr(FileID);                                                   % Namn p� filen (string i en cell)
LCAQMP_used = length(FileID);                                               % �ndrar till antalet anv�nda.  

for i = 1:LCAQMP_used
    name(i) = FileID{i}(1:end-7);                                           % end-4 tar bort ".csv" fr�n filnamnen, end-7 tar bort "-XX.csv"
    FileDir = append(path,FileID{i});
    opts = detectImportOptions(FileDir);
    opts.VariableNamesLine = 1;
    Data.(name(i)) = readtable(FileDir,opts,'ReadVariableNames', true);    % Sparar till Data.UNITX
    %Test.(name(i)) = readtable(FileDir,opts,'ReadVariableNames', false);
end
fields = fieldnames(Data.(name{5}));
if LCAQMP_used > 10 || LCAQMP_used < 0
    msgbox('Incorrect value for no of LCAQMP');     
    error('Incorrect value for no of LCAQMP');      
end

toc
%% Skapa storhetsvektorer
% L�ser fr�n Data structen till celler f�r varje variabel. Exakt varf�r �r
% lite oklart, har inte �ndrat fr�n f�reg�ende �r. 
tic;
disp('Making individual vectors for data...')

LCAQMP_units = zeros(1,10);                                                 % vektor som visar vilka enheter som anv�nts

for i = 1:length(name)                                                      % Loopar genom en g�ng f�r varje fil
    unit = name(i);                                                         % filnamn (UNIT5), string
    unitID = regexp(unit,'\d*','Match');
    unitID = str2double(unitID);
  
   Data.(name{i}).(fields{1}) = Data.(name{i}).(fields{1}) / (60*1000);
   Data.(name{i}).(fields{10}) = Data.(name{i}).(fields{10}) + 2000;

%      eval(sprintf('t{%d} = Data.%s.processor_millis/(60*1000)', unitID, unit))          % millis() i minuter 
%      eval(sprintf('tCO2{%d} = t{%d}', unitID,unitID));               
%      eval(sprintf('PM25{%d} = Data.%s.Var2', unitID,unit));
%     eval(sprintf('PM10{%d} = Data.%s.Var3', unitID,unit));
%     eval(sprintf('T{%d} = Data.%s.Var4', unitID,unit));
%     eval(sprintf('P{%d} = Data.%s.Var5', unitID,unit));
%     eval(sprintf('H{%d} = Data.%s.Var6', unitID,unit));
%     eval(sprintf('CO2{%d} = Data.%s.Var21', unitID,unit));                  % COzir filtered
%     eval(sprintf('VOC{%d} = Data.%s.Var9', unitID,unit));
%     eval(sprintf('GPSYear{%d} = Data.%s.Var10 + 2000', unitID,unit));       % + 2000 f�r att f� helt �rtal. Kan bli knepigt vid GPS-fel.
%     eval(sprintf('GPSMonth{%d} = Data.%s.Var11', unitID,unit));
%     eval(sprintf('GPSDay{%d} = Data.%s.Var12', unitID,unit));
%     eval(sprintf('GPSHour{%d} = Data.%s.Var13', unitID,unit));              % Timmarna fr�n GPSen �r lite wonky ibland, kolla s� de st�mmer �verens i slut�ndan f�r s�kerhets skull 
%     eval(sprintf('GPSMin{%d} = Data.%s.Var14', unitID,unit));           
%     eval(sprintf('GPSSek{%d} = Data.%s.Var15', unitID,unit));
%     eval(sprintf('GPSsat{%d} = Data.%s.Var18', unitID,unit));
%     eval(sprintf('GPSfix{%d} = Data.%s.Var19', unitID,unit));
    
    % Denna del var t�nkt att l�sa s� det g�r att k�ra med filer som b�de
    % har skapats med arduinokod anpassad f�r NO2 och O3 och gammal kod
    % (som har f�rre kolumner i csv-filen), tror dock alla plattformar
    % uppdaterats med arduinokod som l�ser detta genom att fylla i massa
    % nollor ist�llet.
%     if size(eval(sprintf('Data.%s', unit)), 2) == 29        
%         eval(sprintf('errors{%d} = Data.%s.Var29', unitID,unit));   
%         eval(sprintf('NO2{%d} = Data.%s.Var26', unitID,unit));
%         eval(sprintf('O3{%d} = Data.%s.Var27', unitID,unit));
%     else
%         eval(sprintf('errors{%d} = Data.%s.Var22', unitID,unit));
%     end
%     
    %clc;
    LCAQMP_units(unitID) = 1;
end

disp('Making individual vectors for data...')
toc

%% skapar en tidsvektor med t0 d� GPS har connection
% H�r b�rjar den knepiga processen att synka alla till en gemensam tid.
% Tanken �r att alla ska ha f�tt GPS-uppkoppling s� man �r s�ker p� att
% GPS-tiderna st�mmer f�r alla m�tare. N�r GPSfix har gett 1 b�r GPSen
% funka, och d�rf�r tas v�rden innan detta bort f�r att undvika problem som
% att GPSen s�ger att �ret �r 80.

%Vill till�gga att GPSen emellan�t gett helt random v�rden

firstGPS_fix = zeros(1,10);
tic;
disp('Removing values before GPSfix is 1')
for i = 1:length(name)
    unit = name(i);
    unitID = regexp(unit,'\d*','Match');
    unitID = str2double(unitID);
    
    if any(Data.(name{i}).GPS_fix == 0 )                                             % Om GPS aldrig har mottagning, ta bort f�rsta 10 raderna 
                                                                            %(varf�r d�? kanske f�r att klockan inte �r startad de f�rsta m�tpunkterna eller n�t)
        firstGPS_fix(unitID) = length(Data.(name{i}).GPS_fix) - 10;
        str = sprintf('OBS: ingen mottagning f�r gps p� LCAQMP#%i under m�tningen',unitID);
        msgbox(str);
    else
        for ii = length(Data.(name{i}).GPS_fix):-1:1                                % Loopar f�r att hitta f�rsta tillf�llet d� GPS har mottagning
                                                                            % if 'GPS' not in errors,  dvs f�r alla v�rden som gpsen
                                                                            % funkar: (Beh�ver inte visa position som det verkar, eller r�tt tid f�r den delen?)
            if contains(char(Data.(name{i}).Var29{ii}),'GPS') == 0
                firstGPS_fix(unitID) = length(Data.(name{i}).GPS_fix) - ii;

            end
        end
    end
    
%     if any(GPSfix{unitID}) == 0                                             % Om GPS aldrig har mottagning, ta bort f�rsta 10 raderna 
%                                                                             %(varf�r d�? kanske f�r att klockan inte �r startad de f�rsta m�tpunkterna eller n�t)
%         firstGPS_fix(unitID) = length(GPSfix{unitID}) - 10;
%         str = sprintf('OBS: ingen mottagning f�r gps p� LCAQMP#%i under m�tningen',unitID);
%         msgbox(str);
%     else
%         for ii = length(GPSfix{unitID}):-1:1                                % Loopar f�r att hitta f�rsta tillf�llet d� GPS har mottagning
%                                                                             % if 'GPS' not in errors,  dvs f�r alla v�rden som gpsen
%                                                                             % funkar: (Beh�ver inte visa position som det verkar, eller r�tt tid f�r den delen?)
%             if contains(char(errors{unitID}(ii)),'GPS') == 0
%                 firstGPS_fix(unitID) = length(GPSfix{unitID}) - ii;
% 
%             end
%         end
%     end
  % �ndra GPSfix till att ge vanligt index. Beh�ver nog inte vara s�h�r men
  % har inte pallat fixa :)
  firstGPS_fix(unitID) = length(Data.(name{i}).GPS_fix) - firstGPS_fix(unitID);
 
  % Tar bort alla v�rden innan GPSfix
%   t{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   PM25{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   PM10{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   T{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   H{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   CO2{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   VOC{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   P{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSYear{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSMonth{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSDay{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSHour{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSMin{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSSek{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   GPSsat{1,unitID}(1:firstGPS_fix(unitID)) = [];

%   if ~isempty(NO2{1,unitID})
%       NO2{1,unitID}(1:firstGPS_fix(unitID)) = [];
%       O3{1,unitID}(1:firstGPS_fix(unitID)) = [];
%   end
 end

toc
%% Plot Setup
% skapar en gemensam tidslinje f�r att plotta p� "x".
% t0 s�tts efter den enhet som sist b�rjade logga av alla till den som
% f�rst avslutas
% Denna del �r rej�lt st�kig, men tar iaf inte 15 min att k�ra som den
% gjort tidigare. Kan vara en del grejer som inte beh�vs, samt allm�nt
% snyggas till en hel del om man k�nner att det �r viktigt.

tic;
disp('Setting up plot and clock...')

formatOut = 'yyyy-mm-dd HH:MM:SS';
%formatIn = 'yyyy,mm,dd,HH,MM,SS';


clock_startstop = string;
%time = zeros(length(Data.(name{1}).GPS_year));
%timeDN = zeros(length(Data.(name{1}).GPS_year));
for i = 1:length(name)
    fprintf("... for %s\n", name(i))
    
        time{i} = datetime(Data.(name{i}).GPS_year,Data.(name{i}).GPS_month,Data.(name{i}).GPS_day, Data.(name{i}).GPS_hour,Data.(name{i}).GPS_minute,Data.(name{i}).GPS_seconds);
        timeDN{i} = datenum(time{i});
        mini = 1;
        for jj = 1:length(Data.(name{i}).GPS_hour)                                      % Hittar f�rsta tiden utan fel
            if ~contains(char(Data.(name{i}).Var29{jj}),'GPS') &&...
               mini == 0 && 2001 < Data.(name{i}).GPS_year(jj) &&...
               Data.(name{i}).GPS_year(jj) < 2099
                mini = jj;
            elseif ~contains(char(Data.(name{i}).Var29{jj}),'GPS') && mini ~= 0
                maxi = jj;
            end                    
        end
        clock_startstop(1,i) = time{i}(mini);                             % Dessa anger start & slutv�rde
        clock_startstop(2,i) = time{i}(maxi);
end

% for ii = 1:length(LCAQMP_units)                                             % Loopar genom de m�tarna som anv�nds, ex 5 & 9
%     if LCAQMP_units(ii) == 1
%         fprintf(" ...for unit %i\n", ii)
%         for k = 1:length(GPSHour{ii})
% %             str = sprintf('%i,%i,%i,%i,%i,%i',GPSYear{ii}(k),GPSMonth{ii}(k),GPSDay{ii}(k), GPSHour{ii}(k),GPSMin{ii}(k),GPSSek{ii}(k));
% %             TimeStamp = datestr(datenum(str,formatIn),formatOut);
% %             Clock(k,ii) = TimeStamp;
%         end
%         time{ii} = datetime(GPSYear{ii},GPSMonth{ii},GPSDay{ii}, GPSHour{ii},GPSMin{ii},GPSSek{ii});
%         timeDN{ii} = datenum(time{ii});
%         mini = 0;
%         for jj = 1:length(GPSHour{ii})                                      % Hittar f�rsta tiden utan fel
%             if ~contains(char(errors{ii}(jj)),'GPS') && mini == 0 && 2001 < GPSYear{ii}(jj) && GPSYear{ii}(jj) < 2079
%                 mini = jj;
%             elseif ~contains(char(errors{ii}(jj)),'GPS') && mini ~= 0
%                 maxi = jj;
%             end                    
%         end
%         clock_startstop(1,ii) = time{ii}(mini);                             % Dessa anger start & slutv�rde
%         clock_startstop(2,ii) = time{ii}(maxi);
%     end
% end
toc
%%
% Loopar f�r att hitta den tidpunkt d� samtliga enheter loggar samt den
% tidpunkt d� f�rsta enheten st�ngs av. 
tic;
disp('Finding start and end time...')
FirstTime = datetime(2000,01,01, 00,00,00);
minPrev = FirstTime;
% maxPrev = "2079-12-12 23:59:59";
FinalTime = datetime(2999, 12, 12, 24, 59, 59);
maxPrev = FinalTime;
for i = 1:length(name)
    %if LCAQMP_units(i) == 1
        minNew = clock_startstop(1,i);
        maxNew = clock_startstop(2,i);
        if minNew > minPrev                                                 %Hittar den st�rsta minimiv�rde p� klockorna, allts� den sista som s�tts p�
            starttime = minNew;
            minPrev = minNew;
            unitLatest_min = i;
        end
        if maxNew < maxPrev                                                 % Hittar det minsta maxv�rde, den f�rsta som st�ngs av
            endtime = maxNew;
            maxPrev = maxNew;
            unitLatest_max = i;
        end
    %end
end
formatIn = 'yyyy-mm-dd HH:MM:SS';
StartTime = datenum(starttime);%,formatIn);                                 %Dessa verkar vara f�r att ordna plot
EndTime = datenum(endtime);%,formatIn);
OneSecond = 1/3600/24;
OneMin = OneSecond*60;

toc
 
%%
tic;
disp('Syncing up measurement data...')

commonstart = [];commonend = [];
for i = 1:length(name)
    %if LCAQMP_units(i) == 1
        % nedan ska ange index f�r gemensam start- respektive sluttid f�r
        % alla m�tare
        commonstart(i) = find(timeDN{i} >= StartTime & timeDN{i}... 
        < datenum(FinalTime), 1);                                           % find() funkar ej f�r datetime, d�rav Datenum
        commonend(i) = find(timeDN{i} <= EndTime, 1, 'last');               % Fuckar gpsen upp �r denna k�rd f�r tillf�llet. 
                                                                            % (Har inte koll p� exakt vad som funkar och inte n�r GPSen f�r spatt, hoppas bara att den inte f�r det)

        % �ndrar vektorerna till att endast omfatta det gemensamma
        % tidsspannet
        timespan = -diff([commonstart(i) commonend(i)]);                    % Hur m�nga m�tningar i spannet minus ett
        
        for j = 1:length(fields)-3
            
         DataCommon.(name{i}).(fields{j}) = Data.(name{i}).(fields{j})....
             (commonstart:commonend);
        end
%          t{1, i} = t{1, i}(commonstart(i):commonend(i)); 
%         PM25{1,i} = PM25{1, i}(commonstart(i):commonend(i));
%         PM10{1,i} = PM10{1, i}(commonstart(i):commonend(i));
%         T{1,i} = T{1, i}(commonstart(i):commonend(i));
%         H{1,i} = H{1, i}(commonstart(i):commonend(i));
%         CO2{1,i} = CO2{1, i}(commonstart(i):commonend(i));
%         tCO2{1, i} = tCO2{1, i}(commonstart(i):commonend(i));               % Verkar vara n�got med att man tar bort co2v�rden och den beh�ver lika l�ng tidsvektor?
%         VOC{1, i} = VOC{1, i}(commonstart(i):commonend(i));
%         P{1, i} = P{1, i}(commonstart(i):commonend(i));
%         
%         if ~isempty(NO2{1,i})
%             NO2{1, i} = NO2{1, i}(commonstart(i):commonend(i));
%             O3{1, i} = O3{1, i}(commonstart(i):commonend(i));
%         end
% 
%         GPSYear{1, i} = GPSYear{1, i}(commonstart(i):commonend(i));
%         GPSMonth{1, i} = GPSMonth{1, i}(commonstart(i):commonend(i));
%         GPSDay{1, i} = GPSDay{1, i}(commonstart(i):commonend(i));
%         GPSHour{1, i} = GPSHour{1, i}(commonstart(i):commonend(i));
%         GPSMin{1, i} = GPSMin{1, i}(commonstart(i):commonend(i));
%         GPSSek{1, i} = GPSSek{1, i}(commonstart(i):commonend(i));
        initial_time = DataCommon.(name{i}).(fields{1})(1);                                          % Tid f�r det f�rsta m�tv�rdet som kommer med, l�gger plotten fr�n noll
        DataCommon.(name{i}).(fields{1}) = DataCommon.(name{i}).(fields{1}) - initial_time;
    %end
end   

starttime_date = datestr(starttime, ' yy-mm-dd'); 
endtime_date = datestr(endtime, ' yy-mm-dd');
toc
%% L�gger till datum f�r m�tningen i titel
if starttime_date == endtime_date
    meas_name = strcat(meas_name, starttime_date);
elseif any(starttime_date ~= endtime_date)
    meas_name = strcat(meas_name, starttime_date, ' to ', endtime_date);
end
toc
%% Utv�rderar CO2 sensorn, plockar ut felv�rden
% CO2 sensorn har m�jlighet att m�ta mellan 0-5000. 
tic;
disp('Evaluating CO2 values...')
    
% for i = 1:length(name)
%     unit = name(i);
%     unitID = regexp(unit,'\d*','Match');
%     unitID = str2double(unitID);        
% 
%     initial_time = tCO2{unitID}(1);                                         % tid f�r det f�rsta m�tv�rdet som kommer med
%     tCO2{unitID} = tCO2{unitID} - initial_time;
%     CO2error = 0;
    for i = 1:length(DataCommon.(name{i}).CozIr_Co2_filtered(1))
        if DataCommon.(name{i}).CozIr_Co2_filtered(1) > 5000 %|| CO2{unitID}(ii) < 50
            msgbox('F�r h�ga v�rden f�r CO2 p� LCAQMP#%i',name(i));
            CO2error = 1;
        end
    end
%     if CO2error == 1
%         msgbox(str)
%     end
    for i = 1:length(DataCommon.(name{i}).CozIr_Co2_filtered(1))
    % Tar bort v�rden som inneb�r att de troligtvis inte st�mmer
    DataCommon.(name{i}).CozIr_Co2_filtered(DataCommon.(name{i}).CozIr_Co2_filtered>=5000) = nan;
    DataCommon.(name{i}).CozIr_Co2_filtered(DataCommon.(name{i}).CozIr_Co2_filtered<1) = nan;
    end
% end

toc
%%
tic;
disp('Creating plots...')

multiplot = 2;                                                              % �ndras till 1 eller 0
plotcolor = {'#A2142F', '#0000FF', '#00FF00', '#FF0000', '#00FFFF',...
    '#FF00FF', '#D95319', '#EDB120', '#7E2F8E', '#FFFF00'};
figure('units','normalized','outerposition',[0 0 1 1]);


% Skapar plottar f�r olika fall av indata
% Plottar ut LCAQMP, ifall den �r med i m�tningen
% Tv� fall; f�r 1-2 LCAQMP plottas b�de PM2.5 och Pm10 i samma graf
% annars vid LCAQMP>2 s� plottas PM2.5 och PM10 i enskilda f�nster
tic;
disp('Plotting...')

% Glidande medelv�rde f�r att undvika brus
moving_mean_amount =899;
for i = 1:length(name)

    %if LCAQMP_units(i) == 1

        if length(name) <= 2                                                 % L�gger pm2.5 och pm10 i samma f�nster
            multiplot = 0;      
            subplot(2,5,[1:2,6:7]);hold on      
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).SDS011_pm25, moving_mean_amount),'-',...
            'Color',plotcolor{i},'LineWidth',1.5);                          % �ndra dessa till i???
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).SDS011_pm10, moving_mean_amount),':',...
            'Color',plotcolor{i},'LineWidth',1.5);
            subplot(2,5,3);hold on
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).BME680_humidity,'-','Color',plotcolor{i},'linewidth',1.5);
            subplot(2,5,4);hold on
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).BME680_temperature,'-','Color',plotcolor{i},'linewidth',1.5);
            subplot(2,5,5);hold on
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).CozIr_Co2_filtered, moving_mean_amount,'omitnan'),'Color',...
            plotcolor{i},'linewidth',1.5);
            subplot(2,5,8);hold on
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).CCS811_TVOC,'Color',plotcolor{i},'linewidth',1.5);
            
            if ~isempty(DataCommon.(name{i}).NO2)
                subplot(2,5,9);hold on
                plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).NO2,'Color',plotcolor{i},'linewidth',1.5);
                subplot(2,5,10);hold on

                plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).O3,'Color',plotcolor{i},'Marker','.',...
                'LineStyle', 'none');
            end
        else
            multiplot = 1;                                                  % L�gger pm2.5 och pm10 i olika f�nster
            subplot(2,5,[1,2])
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).SDS011_pm25, moving_mean_amount),...
            'Color',plotcolor{i},'LineWidth',1.5);hold on;
            subplot(2,5,[6,7])
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).SDS011_pm10, moving_mean_amount),...
            'Color',plotcolor{i},'LineWidth',1.5);hold on;
            subplot(2,5,3)
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).BME680_humidity,'Color',plotcolor{i},'linewidth',1.5);
            hold on;
            subplot(2,5,4)
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).BME680_temperature,'Color',plotcolor{i},'linewidth',1.5);
            hold on;
            subplot(2,5,5)
            plot(sort(DataCommon.(name{i}).processor_millis),movmean(DataCommon.(name{i}).CozIr_Co2_filtered, moving_mean_amount,'omitnan'),'Color',plotcolor{i},'linewidth',1.5);
            hold on;
            subplot(2,5,8)
            plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).CCS811_TVOC,'Color',plotcolor{i},'linewidth',1.5);
            hold on;
            
            if ~isempty(DataCommon.(name{i}).NO2)                                           % Plottar NO2 och O3 d�r de finns
                subplot(2,5,9);hold on
                plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).NO2,'Color',plotcolor{i},...
                'linewidth',0.5);
                subplot(2,5,10);hold on
                plot(sort(DataCommon.(name{i}).processor_millis),DataCommon.(name{i}).O3,'Color',plotcolor{i},...
                'linewidth',0.5);
            end
        end
    %end
end


name = sort(name);
for i = 1:length(name)                                                      % Flyttar r�tt alla namn, s� 10 hamnar sist. 
    if name(i) == "UNI10"
        name(end+1) = name(i);
        name(i) = [];
    end
end

toc
% Ordnar plottgrafik, label f�r axlar och legender. 
tic;
disp('Setting up labels etc...')

sgtitle(meas_name);  
formatHMS = 'HH:MM:SS';

% Om vi har fler �n tv� m�tare kommer denna anv�ndas, d� vi f�r separata
% plots f�r pm2.5 och pm10
if multiplot == 1   
    %PM2.5
    subplot(2,5,[1, 2])
    title('PM2.5');
    legend(name,'Location','best','FontSize',8);
    legend('boxoff');
    grid on;
    ylabel('Halt [µg/m3]');
    xlabel('Tid');
    
    % Timestamps PM2.5 (Kan vara v�rt att uppdatera dessa s� de ger j�mna
    % klockslag ist�llet f�r 50 minuter is�r fr�n starttid
    ax = gca;
    xtickelick = ax.XTick;
    xtickdiff = median(diff(xtickelick));
    TimeVector= (StartTime:OneMin*xtickdiff:EndTime);
    xData = datestr(TimeVector,formatHMS);
    xtickelick(end) = [];
    end_time_of_day = datestr(EndTime, formatHMS);
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
    ylabel('Halt [µg/m3]');
    xlabel('Tid');
    
    % Timestamps pm10
    ax = gca;
    xtickelick = ax.XTick;
    xtickdiff = median(diff(xtickelick));
    TimeVector= (StartTime:OneMin*xtickdiff:EndTime);
    xData = datestr(TimeVector,formatHMS);
    xtickelick(end) = [];
    end_time_of_day = datestr(EndTime, formatHMS);
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
    legend(name,'Location','best','FontSize',8);
    legend('boxoff');grid on;

    % Subplot O3
    subplot(2,5,10)  
    xlabel('Tid [min]')
    ylabel('PPB')
    title('O3')
    legend(name,'Location','best','FontSize',8);
    legend('boxoff');
    grid on;

% Om vi har f�rre �n tv� m�tare kommer denna anv�ndas, d� vi f�r en
% gemensam plot f�r pm2.5 och pm10
elseif multiplot == 0
    if LCAQMP_used > 0
        
        subplot(2,5,[1:2,6:7])  % PM
        ylabel('Halt [µg/m3]');
        xlabel('Tid');
        title('Partikelhalter');
        
        % Timestamps
        ax = gca;  
        xtickelick = ax.XTick;
        xtickdiff = median(diff(xtickelick));
        TimeVector = (StartTime:OneMin*xtickdiff:EndTime);
        xData = datestr(TimeVector,formatHMS);
        xtickelick(end) = [];
        end_time_of_day = datestr(EndTime, formatHMS);
        if length(xData(:,1)) ~= numel(xtickelick)
            xData(end+1,:) = char(end_time_of_day);
        end
        set(gca,'XTick',xtickelick);
        set(gca,'XTickLabel',{xData});
        set(gca,'XTickLabelRotation',30);
        
        if LCAQMP_used == 1     
            str = sprintf('%s', name(1));
            lgdPM = legend({'PM2.5','PM10',},'Location','best',...
            'NumColumns',1);
            title(lgdPM,str);
        elseif LCAQMP_used == 2
            str = sprintf('%s        %s', name(1),name(2));
            lgdPM = legend({'PM2.5','PM10','PM2.5','PM10'},...
            'Location','best','NumColumns',2);
            title(lgdPM,str);

        end 
        legend('boxoff');grid on;
        
        % Subplot f�r Luftfuktighet
        subplot(2,5,3)  
        ylabel('Procent fukt [%]');
        xlabel('Tid [min]');
        title('Relativ luftfuktighet');
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;
        
        % Subplot Temperatur:
        subplot(2,5,4)  
        xlabel('Tid [min]')
        ylabel([char(176) 'C']);
        title('Temperatur');
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;
        
        % Subplot CO2:
        subplot(2,5,5)  
        xlabel('Tid [min]')
        ylabel('PPM')
        title('CO2')
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;
        
        % Subplot VOC
        subplot(2,5,8)  
        xlabel('Tid [min]')
        ylabel('PPB')
        title('VOC')
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;
        
        % Subplot NO2
        subplot(2,5,9)  
        xlabel('Tid [min]')
        ylabel('PPB')
        title('NO2')
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;
        
        % Subplot O3
        subplot(2,5,10)
        xlabel('Tid [min]')
        ylabel('PPB')
        title('O3')
        legend(name,'Location','best','FontSize',8);
        legend('boxoff');grid on;

    end
end
toc


%% Variationer med avst�nd
% G�rs inte  m�tningen p� olika avst�nd fr�n v�g exempelvis b�r denna vara
% bortkommenterad. Planerar ni inte att g�ra likadana m�tningar f�r att
% bed�ma variationer med avst�nd kan ni yeeta den h�r delen.

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
% % l�gg in avst�nden fr�n "utsl�ppspunkten", och
% % DISTANCES = [-10, 35, 85, 120]; % G�rda
% DISTANCES = [0, 45, 120, 210, 330]; % Botaniska 
% PM10_pair_means = [mean([PM10_means(1), PM10_means(5)]), mean([PM10_means(3), PM10_means(9)]), mean([PM10_means(4), PM10_means(6)]), mean([PM10_means(2), PM10_means(7)]) mean([PM10_means(10), PM10_means(8)])];
% PM25_pair_means = [mean([PM25_means(1), PM25_means(5)]), mean([PM25_means(3), PM25_means(9)]), mean([PM25_means(4), PM25_means(6)]), mean([PM25_means(2), PM25_means(7)]) mean([PM25_means(10), PM25_means(8)])];
% 
% figure
% subplot(1,2,1); 
% hold on;
% plot(DISTANCES, PM25_pair_means, '.', 'MarkerSize', 25)
% ylabel('Halt [µg/m3]');
% xlabel('Avst�nd fr�n Dag Hammarskj�ldsleden [m]');
% title('PM2,5');
% grid on;
% xlim([min(DISTANCES)-10, max(DISTANCES)+10]);
% yMax = max([max(PM25_pair_means), max(PM10_pair_means)])*1.1;
% ylim([0, yMax])
% 
% subplot(1,2,2); 
% hold on;
% plot(DISTANCES, PM10_pair_means, '.', 'MarkerSize', 25)
% ylabel('Halt [µg/m3]');
% xlabel('Avst�nd fr�n Dag Hammarskj�ldsleden [m]');
% title('PM10');
% grid on;
% xlim([min(DISTANCES)-10, max(DISTANCES)+10]);
% ylim([0, yMax])


