function [dataCommon, felData, clockStartStop] = datafix(data, timeDN)
%{
    Datafix   -   Justerar mätdatan inför plot
    Skapar en gemensam tidslinje för samtlig mätdata med t0 efter den
    enheten som började logga sist och bryter vid den tidpunkten första
    enheten stängdes av.
Syntax:
    [dataCommon, tidFel, clockStartStop] = datafix(data, timeDN)

Inputs:
    data                -   Struct med all mätdata
    timeDN              -   Cellarray med en vektor för varje enhet
                            innehållande GPS-värden för datum och tid i
                            datenum-format.

Outputs:
    dataCommon          -   Struct med all mätdata justerad så det är för
                            samma tidsfönster
    felData             -   Struct med data som innehåller tidsfel
    clockStartStop      -   Matris med första och sista tid för varje enhet

Exempel:

%}
%{
Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-12
%}

%%


disp('Setting up plot and clock...')
clockStartStop = string;
tidsFel = zeros([1,length(fieldnames(data))]);
name = fieldnames(data);
years = [2015, year(datetime(now, 'ConvertFrom', 'datenum'))];
korr = struct('UNIT1', [1, 0], 'UNIT2', [1.002, -37.44], ...
    'UNIT3', [1.025, -11.84], 'UNIT4', [1.153, 287.5], ...
    'UNIT5', [0.8818, -112.1], 'UNIT6', [0.985, 13.04], 'UNIT7', ...
    [0.9868, -58.27], 'UNIT8', [0.9683, -68.95], 'UNIT9', [0.9979, -11.75], ...
    'UNIT10', [1, 0]);
for i = 1:length(name)
    fprintf("... for %s\n", name{i})
    data.(name{i}).CozIr_Co2_filtered = ...
        data.(name{i}).CozIr_Co2_filtered./korr.(name{i})(1)-korr.(name{i})(2);
    % Säkerställer så att datan in har en fullständigt tidsfel.
    if data.(name{i}).GPS_year(floor(length(data.(name{i}).GPS_year)/2)) >= years(1) &&...
            data.(name{i}).GPS_year(end) <= years(2)
        % Hittar första tiden utan fel.
        for j = 1:length(timeDN{i})
            
            if ~contains(char(data.(name{i}).(width(data.(name{i}))){j}), ...
                    'GPS') && years(1) < data.(name{i}).GPS_year(j) &&...
                    data.(name{i}).GPS_year(j) <= years(2)
                mini = j;
                break
            end
            mini = j;
        end
        
        for j = length(timeDN{i}):-1:1
            if ~contains(char(data.(name{i}).(width(data.(name{i}))){j}),'GPS')
                maxi = j;
                break
            end
        end
        % Dessa anger start & slutvärde.
        clockStartStop(1,i) = datetime(timeDN{i}(mini),...
            'ConvertFrom', 'datenum');
        clockStartStop(2,i) = datetime(timeDN{i}(maxi),...
            'ConvertFrom', 'datenum');
    else
        tidsFel(i) = 1;
        clockStartStop(1,i) = 0;
        clockStartStop(2,i) = 0;
    end
end
tidsFel = tidsFel > 0 ;
clockStartStop(:, tidsFel) = [];
felData = {};
%%
if sum(tidsFel) ~= length(name)
    % Loopar för att hitta den tidpunkt då samtliga enheter loggar samt den
    % tidpunkt då första enheten stängs av.
    
    disp('Finding start and end time...')
    startTime = datetime(max(datenum(clockStartStop(1,:))), ...
        'ConvertFrom', 'datenum');
    endTime = datetime(min(datenum(clockStartStop(2,:))), ...
        'ConvertFrom', 'datenum');
    
    
    
    %%
    
    disp('Syncing up measurement data...')
    
    commonStart = zeros(1:length(name)-length(tidsFel));
    commonEnd = zeros(1:length(name)-length(tidsFel));
    
    felData = data;
    for i = 1:length(name)
        if tidsFel(i)
            data = rmfield(data, name{i});
            continue
        end
        felData = rmfield(felData, name{i});
        % nedan ska ange index för gemensam start- respektive sluttid för
        % alla mätare
        commonStart(i) = find(timeDN{i} >= datenum(startTime) &...
            timeDN{i} < now,1);
        commonEnd(i) = find(timeDN{i} <= datenum(endTime), 1, 'last');
        AA = commonEnd(i) - commonStart(i);
        % ändrar vektorerna till att endast omfatta det gemensamma
        % tidsspannet
        fields = fieldnames(data.(name{i}));
        for j = 1:length(fields)-3
            dataCommon.(name{i}).(fields{j}) = data.(name{i}).(fields{j})...
                (commonStart(i):commonEnd(i));
        end
        % Tid för det första mätvärdet som kommer med, lägger plotten från noll
        dataCommon.(name{i}).processor_millis = ...
            dataCommon.(name{i}).processor_millis - ...
            dataCommon.(name{i}).processor_millis(1);
    end
    
    %% Utvärderar CO2 sensorn, plockar ut felvärden
    % CO2 sensorn har möjlighet att mäta mellan 0-5000.
    
    disp('Evaluating CO2 values...')
    name = fieldnames(data);
    for i = 1:length(name)
        if data.(name{i}).CozIr_Co2_filtered(1) > 5000 %|| CO2{unitID}(ii) < 50
            msgbox('För höga värden för CO2 på %s',name{i});
        end
        % Tar bort värden som innebär att de troligtvis inte stämmer
        if contains(data.(name{i}).Var29,'CozIR')
            data.(name{i}).CozIr_Co2(contains(data.(name{i}).(width(data.(name{i}))), ...
                'CozIR')) = NaN();
            data.(name{i}).CozIr_Co2_filtered(contains(data.(name{i}).(width(data.(name{i}))), ...
                'CozIR')) = NaN();
        end
    end
    
else
    % Justerar felvärden för CO2 om all data har tidsfel
    
    disp('Evaluating CO2 values...')
    name = fieldnames(data);
    for i = 1:length(name)
        if data.(name{i}).CozIr_Co2_filtered(1) > 5000
            msgbox('För höga värden för CO2 på %s',name{i});
        end
        % Tar bort värden som innebär att de troligtvis inte stämmer
        if contains(data.(name{i}).Var29,'CozIR')
            data.(name{i}).CozIr_Co2(contains(data.(name{i}). ...
                Var29,'CozIR')) = NaN();
            data.(name{i}).CozIr_Co2_filtered(contains(data.(name{i}). ...
                Var29,'CozIR')) = NaN();
        end
    end
    
    dataCommon = data;
end


end