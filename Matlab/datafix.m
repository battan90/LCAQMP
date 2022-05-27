function [dataCommon, felData, clockStartStop] = datafix(data, ~)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
    Datafix   -   Justerar mätdatan inför plot
    Skapar en gemensam tidslinje för samtlig mätdata med t0 efter den
    enheten som började logga sist och bryter vid den tidpunkten första
    enheten stängdes av.
Syntax:
    [dataCommon, tidFel, clockStartStop] = datafix(data, timeDN)

Inputs:
    data                -   Struct med all mätdata.
    GPSFel              -   Logisk variabel för att bestämma om man ska
                            sortera ut data med GPSFel eller ej.

Outputs:
    dataCommon          -   Struct med all mätdata justerad så det är för
                            samma tidsfönster.
    felData             -   Struct med data som innehåller tidsfel.
    clockStartStop      -   Matris med första och sista tid för varje enhet.

Exempel:

%}
%{
Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-12
Uppdaterad: 2202-05-27
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp('Setting up plot and clock...')
clockStartStop = string;
tidsFel = false([1, length(fieldnames(data))]);
name = fieldnames(data);
% Vektor för att sedan kolla så att datan ligger inom rätt år. (GPS fel)
years = [2015, year(datetime(now, 'ConvertFrom', 'datenum'))];
dataCommon = struct;
timeDN = {length(name)};

for i = 1:length(name)
    fprintf("... for %s\n", name{i})
    % Gör processor_millis till minuter
    data.(name{i}).processor_millis = data.(name{i}).processor_millis / ...
        (60 * 1000);
    % GPSen, loggar bara sista två värdena i året, lägger till 20 i början.
    data.(name{i}).GPS_year = data.(name{i}).GPS_year + 2000;
    
    % Justerar för sommar-/vintertid
    % Skapar en vektor med DD-MMM-YYYY HH:MM:SS.
    tDT = datetime(data.(name{i}).GPS_year, ...
        data.(name{i}).GPS_month, data.(name{i}).GPS_day, ...
        data.(name{i}).GPS_hour, data.(name{i}).GPS_minute, ...
        data.(name{i}).GPS_seconds, 'TimeZone', 'Europe/Zurich');
    % Skapar logiskvektor för vilka värden som är sommartid.
    tisdst = isdst(tDT);
    % Gör vektorn till datenum för att senare kunna jämföra tider på ett
    % vettigt sätt.
    tDN = datenum(tDT);
    % Lägger till UTC + X där X är 1 eller 2 beroende på om det är
    % sommartid eller inte.
    timeDN{i} = tDN + (tisdst + 1) ./ 24;
    
    % Ett försök att säkerställa så att inte all data har GPSfel. Kan göras
    % mycket snyggare
    if data.(name{i}).GPS_year(floor(length(data.(name{i}).GPS_year)/2)) ...
            >= years(1) && data.(name{i}).GPS_year(end) <= years(2)
        % Söker efter första tiden utan GPSfel, genom att kolla efter
        % Errors framifrån.
        for j = 1:length(timeDN{i})
            if ~contains(char(data.(name{i}).Errors{j}), ...
                    'GPS') && years(1) < data.(name{i}).GPS_year(j) && ...
                    data.(name{i}).GPS_year(j) <= years(2)
                mini = j;
                break
            end
            mini = j;
        end
        % Söker efter sista tiden utan GPSfel, genom att kolla efter
        % Errors bakifrån.
        for j = length(timeDN{i}):-1:1
            if ~contains(char(data.(name{i}).Errors{j}), 'GPS')
                maxi = j;
                break
            end
        end
        % Lagrar första och sista mätpunkten för enheten.
        clockStartStop(1, i) = datetime(timeDN{i}(mini), ...
            'ConvertFrom', 'datenum');
        clockStartStop(2, i) = datetime(timeDN{i}(maxi), ...
            'ConvertFrom', 'datenum');
    else
        % Om enheten har kontinuerligt GPSfel får den start- och stopptid
        % 0.
        tidsFel(i) = true;
        clockStartStop(1, i) = 0;
        clockStartStop(2, i) = 0;
    end
end
% Tar bort felaktig data från start och stopp för mätningen. Viktigt att
% tidsFel är en logisk vektor, annars krashar MATLAB. Mycket konstigt.
if sum(tidsFel) > 0
    clockStartStop(:, tidsFel) = [];
end
felData = struct;

%%
if sum(tidsFel) ~= length(name)
    
    % Hittar den sista starttiden bland enheterna och den första
    % stopptiden.
    disp('Finding start and end time...')
    startTime = datetime(max(datenum(clockStartStop(1, :))), ...
        'ConvertFrom', 'datenum');
    endTime = datetime(min(datenum(clockStartStop(2, :))), ...
        'ConvertFrom', 'datenum');
    
    %%
    
    disp('Syncing up measurement data...')
    
    commonStart = zeros(1:length(name)-length(tidsFel));
    commonEnd = zeros(1:length(name)-length(tidsFel));
    
    for i = 1:length(name)
        % Tar bort data med GPSfel från mätningen. Den ställer till
        % det en del om den ska plottas med resten annars.
        if tidsFel(i)
            felData.(name{i}) = data.(name{i});
            data = rmfield(data, name{i});
            continue
        end
        % nedan ska ange index för gemensam start- respektive sluttid för
        % alla mätare
        commonStart(i) = find(timeDN{i} >= datenum(startTime) & ...
            timeDN{i} < now, 1);
        commonEnd(i) = find(timeDN{i} <= datenum(endTime), 1, 'last');
        % ändrar vektorerna till att endast omfatta det gemensamma
        % tidsspannet
        dataCommon.(name{i}) = data.(name{i}) ...
            (commonStart(i):commonEnd(i), :);
        % Tid för det första mätvärdet som kommer med, lägger plotten från noll
        dataCommon.(name{i}).processor_millis = ...
            dataCommon.(name{i}).processor_millis - ...
            dataCommon.(name{i}).processor_millis(1);
    end
    
else
    dataCommon = data;
end
disp('Evaluating CO2 values...')
name = fieldnames(data);
for i = 1:length(name)
    if data.(name{i}).CozIr_Co2_filtered(1) > 5000
        msgbox('För höga värden för CO2 på %s', name{i});
    end
    % Tar bort värden som innebär att de troligtvis inte stämmer
    if contains(data.(name{i}).Errors, 'CozIR')
        data.(name{i}).CozIr_Co2(contains(data.(name{i}). ...
            Errors, 'CozIR')) = NaN();
        data.(name{i}).CozIr_Co2_filtered(contains(data.(name{i}). ...
            Errors, 'CozIR')) = NaN();
    end
end
end