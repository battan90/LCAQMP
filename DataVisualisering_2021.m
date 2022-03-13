
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
clear;
close all;
clc;
format long
%% Namn p� m�tningen
%input = inputdlg("Namn p� m�tning", "Namn p� m�tning");
% if input == ""
%     meas_name = 'Nordstan och �ngg�rdsbergen, ';                            % �ndra f�r att l�gga till titel vid graferna
% else
%     meas_name = input;
% end
meas_name = 'Nordstan och �ngg�rdsbergen, ';
%% �ppna f�nster f�r att v�lja .csv data
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

%% Utv�rderar CO2 sensorn, plockar ut felv�rden
% CO2 sensorn har m�jlighet att m�ta mellan 0-5000.
tic;
disp('Evaluating CO2 values...')
name = fieldnames(Data);
for i = 1:length(name)
    %for j = 1:height(Data.(name{i}))
    if Data.(name{i}).CozIr_Co2_filtered(1) > 5000 %|| CO2{unitID}(ii) < 50
        msgbox('F�r h�ga v�rden f�r CO2 p� LCAQMP#%i',name{i});
        CO2error = 1;
    end
    % Tar bort v�rden som inneb�r att de troligtvis inte st�mmer
    if contains(Data.(name{i}).Var29,'CozIR')
        Data.(name{i}).CozIr_Co2(contains(Data.(name{i}).Var29,'CozIR')) = NaN();
        Data.(name{i}).CozIr_Co2_filtered(contains(Data.(name{i}).Var29,'CozIR')) = NaN();
    end
    %end
end
toc
%%

Plot(Data, meas_name, clock_startstop, tidsfel); %






