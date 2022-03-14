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
counter = 1;
measName = 'Nordstan och änggårdsbergen, ';
%% Namn på mätningen
%input = inputdlg("Namn på mätning", "Namn på mätning");
% if input == ""
%     meas_name = 'Mätning, '; 
% else
%     meas_name = input;
% end
%% Öppna fönster för att välja .csv data

% while counter
%     try
%         [Data, timeDN] = Selection();
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
[data, timeDN] = selection();

[data, tidsFel, clockStartStop] = datafix (data, timeDN);

ploting(data, measName, clockStartStop, tidsFel); 