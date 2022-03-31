%% Bearbetar CO2-datan inför kalibrering
clf
name = fieldnames(data);

% Överblick: Först sorterar vi bort alla NaN och 0:or från datan, sedan
% medelvärdesbildar vi datan för att använda som referens till kalibrering. 
% OBS: Den här koden utgår ifrån att all data är precis lika lång. Det är
% också en ful lösning att ersätta 0:or med föregående nollskillda värde.
% Om vi har många 0:or på rad får vi då en platå

% Antalet punkter att medelvärdesbilda över sätts till 5% av totala
% längden:
movmean_by_amount =  0.05.*length(data.(name{1}).CozIr_Co2_filtered); 

soon_meanvalue_Co2 = zeros(length(data.(name{1}).GPS_hour),1); % skapar array att fylla värdena i, för att sedan dela och få medelvärde

% För att använda ''curve fitting''-appen krävs tydligen vektorer, måste
% därmed skapa nya vektorer av datan... Det är fullt möjligt att det finns
% ett bättre och snyggare sätt att göra detta på
CozIr_array_filtered_1 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_2 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_3 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_4 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_5 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_6 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_7 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_8 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_9 = zeros(length(data.(name{1}).GPS_hour),1);
CozIr_array_filtered_10 = zeros(length(data.(name{1}).GPS_hour),1);

for i = 1:length(name)
    for j = 1:length(data.(name{i}).GPS_hour)
        % Denna kod är inte 100% robust, om vi t.ex har två på varandra
        % följande NaN värden kommer vi inte bli av med Nan här, krävs fler
        % if-satser för det...
        if isnan(data.(name{i}).CozIr_Co2_filtered(j)) && j > 1 && j < length(data.(name{1}).GPS_hour) %kollar om vi har ett NaN på plats j, där j inte är första eller sista indexet i arrayen
            data.(name{i}).CozIr_Co2_filtered(j) = (data.(name{i}).CozIr_Co2_filtered(j-1) +  data.(name{i}).CozIr_Co2_filtered(j+1))./2; % ersätter NaN med ett medelvärde av punkterna till höger och vänster
        elseif isnan(data.(name{i}).CozIr_Co2_filtered(j)) && j == 1
            data.(name{i}).CozIr_Co2_filtered(j) = (data.(name{i}).CozIr_Co2_filtered(j+1) +  data.(name{i}).CozIr_Co2_filtered(j+2))./2; % ersätter NaN med ett medelvärde av två punkterna till höger
        elseif isnan(data.(name{i}).CozIr_Co2_filtered(j)) && j == length(data.(name{1}).GPS_hour)
            data.(name{i}).CozIr_Co2_filtered(j) = (data.(name{i}).CozIr_Co2_filtered(j-1) +  data.(name{i}).CozIr_Co2_filtered(j-2))./2; % ersätter NaN med ett medelvärde av två punkterna till vänster
        end
        % Ersätter 0:or med det tidgigare värdet (ej bra lösning):
        if data.(name{i}).CozIr_Co2_filtered(j) == 0 && j > 1
            data.(name{i}).CozIr_Co2_filtered(j) = data.(name{i}).CozIr_Co2_filtered(j-1); 
        end
    end
    % Glidande medelvärde för brusreducering:
    data.(name{i}).CozIr_Co2_filtered = movmean(data.(name{i}).CozIr_Co2_filtered, movmean_by_amount);
    
    for j = 1:length(data.(name{i}).GPS_hour)
        % appendar de nya arrayerna som behövs till curve fitting:
        if i == 1
            CozIr_array_filtered_1(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 2
            CozIr_array_filtered_2(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 3
            CozIr_array_filtered_3(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 4
            CozIr_array_filtered_4(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 5
            CozIr_array_filtered_5(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 6
            CozIr_array_filtered_6(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 7
            CozIr_array_filtered_7(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 8
            CozIr_array_filtered_8(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 9
            CozIr_array_filtered_9(j) = data.(name{i}).CozIr_Co2_filtered(j);
        elseif i == 10
            CozIr_array_filtered_10(j) = data.(name{i}).CozIr_Co2_filtered(j);
        end        
    end
end



% CozIr_array_filtered_1 = movmean(CozIr_array_filtered_1, movmean_by_amount);
% CozIr_array_filtered_2 = movmean(CozIr_array_filtered_2, movmean_by_amount);
% CozIr_array_filtered_3 = movmean(CozIr_array_filtered_3, movmean_by_amount);
% CozIr_array_filtered_4 = movmean(CozIr_array_filtered_4, movmean_by_amount);
% CozIr_array_filtered_5 = movmean(CozIr_array_filtered_5, movmean_by_amount);
% CozIr_array_filtered_6 = movmean(CozIr_array_filtered_6, movmean_by_amount);
% CozIr_array_filtered_7 = movmean(CozIr_array_filtered_7, movmean_by_amount);
% CozIr_array_filtered_8 = movmean(CozIr_array_filtered_8, movmean_by_amount);
% CozIr_array_filtered_9 = movmean(CozIr_array_filtered_9, movmean_by_amount);
% CozIr_array_filtered_10 = movmean(CozIr_array_filtered_10, movmean_by_amount);


for i = 1:length(name)
    for j = 1:length(data.(name{i}).GPS_hour)
        soon_meanvalue_Co2(j) = soon_meanvalue_Co2(j) + data.(name{i}).CozIr_Co2_filtered(j); % adderar j:te komponentens data från enhet i, för alla i och j
    end
end

meanvalue_Co2 = soon_meanvalue_Co2./length(name);

nancheck = 0; 
for j = 1:length(data.(name{i}).GPS_hour)
    if isnan(meanvalue_Co2(j))
        nancheck = nancheck + 1;
    end
    
end

nancheck % om nancheck är 0 har vi inga NaN kvar :), om inte måste koden utökas ovan..


% Plottar för att kontrollera datan
A = linspace(0, length(data.(name{1}).GPS_hour),length(data.(name{1}).GPS_hour));

plot(A, meanvalue_Co2)
hold on

% for i = 1:length(name)
%     plot(A, transpose(data.(name{i}).CozIr_Co2_filtered),'--')
%     hold on
% end



plot(A, CozIr_array_filtered_1)
hold on
plot(A, CozIr_array_filtered_2)
hold on
plot(A, CozIr_array_filtered_3)
hold on
plot(A, CozIr_array_filtered_4)
hold on
plot(A, CozIr_array_filtered_5)
hold on
plot(A, CozIr_array_filtered_6)
hold on
plot(A, CozIr_array_filtered_7)
hold on
plot(A, CozIr_array_filtered_8)



% Note2self: Just nu är det väldigt förvirrande för datan från LCAQMP2
% hamnar som #1 etc...


%% Kalibrering av CO2-datan
clf

CozIr_array_filtered_corrected = zeros(length(name), length(data.(name{1}).GPS_hour));

%skapar arrayer för k- och m-värdena för kalibering, blir tyvärr mycket manuellt arbete
%k = [0.996, 0.9696, 0.8633, 1.131, 1.002, 1, 1.026, 0.9988]; 
%m = [39.51, 18.96, -241.8, 130.7, 3.332, 74.57, 78.7, 15.83];

k = [1.002, 1.025, 1.153, 0.8818, 0.985, 0.9868, 0.9683, 0.9979]; 
m = [-37.44, -11.84, 287.5, -112.1, 13.04, -58.27, -68.95, -11.75];

%OBS1: Om kalibreringen ska implementeras i framtiden är det alltså
%dessa k- och m-värden som ska användas. Notera då att det första paret 
%av k- och m-värde egentligen tillhör LCAQMP2 etc.. vilket gör att man
%måste vara extra noga med att kontrollera så att rätt korrektionsfaktorer
%används till rätt enhet!!!

%OBS2: Kalibreringen gjordes med medelvärdet som referens, därmed är
%osäkerheten i resultatet fortfarande väldigt hög. T.ex ligger nu topparna
%på ca 3300 ppm medan vi borde ha fått 3000 ppm (eller lägre ännu)

% Korrigerar datan med ''y=kx+m''
for i = 1:length(name)
    for j = 1:length(data.(name{i}).GPS_hour)
        CozIr_array_filtered_corrected(i,j) = (data.(name{i}).CozIr_Co2_filtered(j) - m(i))./k(i);
    end
    
end


        % Följande behävs inte längre men är kvar atm just in case:
% for i = 1:length(name)
%     if i == 1
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 2
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 3
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 4
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 5
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 6
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 7
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 8
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 9
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     elseif i == 10
%         for j = 1:length(Data.(name{i}).GPS_hour)
%             CozIr_array_filtered_1(j) = k(i).*CozIr_array_filtered_1(j) + m(i);
%         end
%     end
%     
% end



% Plottar för att kontrollera datan:
A = linspace(0, length(data.(name{1}).GPS_hour),length(data.(name{1}).GPS_hour));

plot(A, meanvalue_Co2)
hold on

for i = 1:length(name)
    plot(A, CozIr_array_filtered_corrected(i,:),'--')
    hold on
end
