function [DataCommon, tidsfel, clock_startstop] = Timefix(Data, timeDN)
%% Plot Setup
% skapar en gemensam tidslinje för att plotta på "x".
% t0 sätts efter den enhet som sist började logga av alla till den som
% först avslutas
% Denna del är rejält stökig, men tar iaf inte 15 min att köra som den
% gjort tidigare. Kan vara en del grejer som inte behövs, samt allmänt
% snyggas till en hel del om man känner att det är viktigt.
tic;
disp('Setting up plot and clock...')
clock_startstop = string;
tidsfel = zeros([1,length(fieldnames(Data))]);
name = fieldnames(Data);

years = [2001, year(datetime(now, 'ConvertFrom', 'datenum'))];
for i = 1:length(name)
    fprintf("... for %s\n", name{i})
    if Data.(name{i}).GPS_year(1) >= years(1) && Data.(name{i}).GPS_year(end) <= years(2)
        for j = 1:length(timeDN{i})                                      % Hittar första tiden utan fel
            if ~contains(char(Data.(name{i}).Var29{j}),'GPS') &&...
                    years(1) < Data.(name{i}).GPS_year(j) &&...
                    Data.(name{i}).GPS_year(j) <= years(2)
                mini = j;
                break
            end
            mini = j;
        end
        
        for j = length(timeDN{i}):-1:1
            if ~contains(char(Data.(name{i}).Var29{j}),'GPS')
                maxi = j;
                break
            end
        end
        
        
        
        clock_startstop(1,i) = datetime(timeDN{i}(mini), 'ConvertFrom', 'datenum');                             % Dessa anger start & slutvärde
        clock_startstop(2,i) = datetime(timeDN{i}(maxi), 'ConvertFrom', 'datenum');
        
        
        %     if clock_startstop(1,i) == clock_startstop(2,i)
        %         tidsfel(i) = i;
        %     end
        
    else
        tidsfel(i) = 1;
        clock_startstop(1,i) = 0;
        clock_startstop(2,i) = 0;
    end
end
tidsfel = tidsfel > 0 ;
clock_startstop(:, tidsfel) = [];


if length(tidsfel) ~= length(name)
    clock_startstop(:,tidsfel) = [];
    
    toc
    %%
    % Loopar för att hitta den tidpunkt då samtliga enheter loggar samt den
    % tidpunkt då första enheten stängs av.
    tic;
    disp('Finding start and end time...')
    
    starttime = datetime(max(datenum(clock_startstop(1,:))), 'ConvertFrom', 'datenum');
    endtime = datetime(min(datenum(clock_startstop(2,:))), 'ConvertFrom', 'datenum');
    
    toc
    
    %%
    tic;
    disp('Syncing up measurement data...')
    
    commonstart = zeros(1:length(name)-length(tidsfel));
    commonend = zeros(1:length(name)-length(tidsfel));
    %k = 0;
    for i = 1:length(name)
        if tidsfel(i)
            %k = k + 1;
            continue
        end
        % nedan ska ange index för gemensam start- respektive sluttid för
        % alla mätare
        commonstart(i) = find(timeDN{i} >= datenum(starttime),1);                      % find() funkar ej för datetime, därav Datenum
        commonend(i) = find(timeDN{i} <= datenum(endtime), 1, 'last');               % Fuckar gpsen upp är denna körd för tillfället.
        % (Har inte koll på exakt vad som funkar och inte när GPSen får spatt, hoppas bara att den inte får det)
        
        % ändrar vektorerna till att endast omfatta det gemensamma
        % tidsspannet
        fields = fieldnames(Data.(name{i}));
        for j = 1:length(fields)-3
            DataCommon.(name{i}).(fields{j}) = Data.(name{i}).(fields{j})....
                (commonstart(i):commonend(i));
        end
        DataCommon.(name{i}).processor_millis = DataCommon.(name{i}).processor_millis - DataCommon.(name{i}).processor_millis(1); % Tid för det första mätvärdet som kommer med, lägger plotten från noll
    end
    
else
    DataCommon = Data;
end
toc

end