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
tic
counter = 1;
measName = 'Botaniska, ';

%% Namn på mätningen
% input = inputdlg("Namn på mätning", "Namn på mätning");
% if input == ""
%     measName = 'Mätning, ';
% else
%     measName = input;
% end

%% Öppna fönster för att välja .csv data

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