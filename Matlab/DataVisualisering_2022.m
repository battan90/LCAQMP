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
tic
counter = 1;
measName = 'Botaniska, ';

%% Namn p� m�tningen
% input = inputdlg("Namn p� m�tning", "Namn p� m�tning");
% if input == ""
%     measName = 'M�tning, ';
% else
%     measName = input;
% end

%% �ppna f�nster f�r att v�lja .csv data

% while counter
%     try
%         [data, timeDN] = selection();
%         counter = 0;
%     catch
%         A = questdlg('Ingen fil vald', 'Ingen fil vald','Starta om', ...
%             'Avbryt', 'Avbryt');
%         switch A
%             case 'Avbryt'
%                 return
%         end
%     end
% end
data = selection();

[data, felData, clockStartStop] = datafix(data);

%kalibrering(data)


meth = "sgolay";

window = 31;

        ploting(data, measName, clockStartStop, meth, window);

if ~isempty(fieldnames(felData))
    ploting(felData, ['Data med fel ,', measName], clockStartStop, meth, window);
end

%print2excel(data);
toc