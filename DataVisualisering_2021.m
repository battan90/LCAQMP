
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Detta script har använts för att visualisera data uppmätt med LCAQMP.
% Det är lite rörigt, men funkar helt ok för det mesta vid det här
% laget. Jag försöker förklara lite vad alla delar gör och varför de är
% där i kommentarer, men jag är 100 % säker på att saker fortfarande är
% oklara. Ni får gärna höra av er om ni har funderingar så kan jag försöka
% förklara om jag har tid :) Vill ni ha allmän uppstart eller någon form
% av genomgång kan ni också höra av er så kan vi nog lösa det!
% //Axel Eiman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
close all;
clc;
format long
%% Namn på mätningen
%input = inputdlg("Namn på mätning", "Namn på mätning");
% if input == ""
%     meas_name = 'Nordstan och änggårdsbergen, ';                            % ändra för att lägga till titel vid graferna
% else
%     meas_name = input;
% end
meas_name = 'Nordstan och änggårdsbergen, ';
%% Öppna fönster för att välja .csv data
counter = 1;
while counter
    try
        [Data, timeDN] = Selection();
        counter = 0;
    catch
        A = questdlg('Ingen fil vald', 'Ingen fil vald','Starta om', 'Avbryt', 'Avbryt');
        switch A
            case 'Avbryt'
                return
        end
    end
end
%[Data, timeDN] = Selection();

[Data, tidsfel, clock_startstop] = Timefix (Data, timeDN);

%% Utvärderar CO2 sensorn, plockar ut felvärden
% CO2 sensorn har möjlighet att mäta mellan 0-5000.
tic;
disp('Evaluating CO2 values...')
name = fieldnames(Data);
for i = 1:length(name)
    %for j = 1:height(Data.(name{i}))
    if Data.(name{i}).CozIr_Co2_filtered(1) > 5000 %|| CO2{unitID}(ii) < 50
        msgbox('För höga värden för CO2 på LCAQMP#%i',name{i});
        CO2error = 1;
    end
    % Tar bort värden som innebär att de troligtvis inte stämmer
    if contains(Data.(name{i}).Var29,'CozIR')
        Data.(name{i}).CozIr_Co2(contains(Data.(name{i}).Var29,'CozIR')) = NaN();
        Data.(name{i}).CozIr_Co2_filtered(contains(Data.(name{i}).Var29,'CozIR')) = NaN();
    end
    %end
end
toc
%%

Plot(Data, meas_name, clock_startstop, tidsfel); %






