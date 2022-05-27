%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%{
    DataVisualisering_2022   -   Läser in och plottar data från LCAQMP
    Läser in data på CSV. format som innehåller följande fält:
    processor_millis, SDS011_pm25, SDS011_pm10, BME680_temperature,
    BME680_humidity, CCS811_TVOC, GPS_year, GPS_month, GPS_day, GPS_hour,
    GPS_minute, GPS_seconds, CozIr_Co2_filtered, NO2, O3 och Errors.
    Framtagen under kandidatarbete för hantering av insamlad data vid
    mätning av luftkvalitet.

Functions:
    selection.m     -   Läser in data.
    datafix.m       -   Formaterar data.
    ploting.m       -   Plottar data.
    kalibrering.m   -   Tänk att användas för att kunna kalibrera baserat
                        referensmätning och sen skriva till .mat fil.
    print2excel.m   -   Skriver data till Excel i tabellformat.

Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-10
Uppdaterad: 2202-05-27
%}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
close all;
clc;
format long

% För att i framtiden köra en kalibreringskod, fanns ett initiativ år 2022
% men fick aldrig vår kalibrering att fungera i brist på bra referens.
kalibrering = 0;

% För att plotta en typ av mätdata i ett eget fönster. Ovärderligt till
% rapportskrivningen. 1, skriver i separata fönster. 0, skriver i genemsamt
% fönster.
plotSolo = 0;

% Tänkt att användas för att välja mellan om data med GPSfel ska sorteras
% bort eller inte, dock är den biten inte implementerad. Istället så ger
% den möjlighet att välja om data med GPSfel ska plottas separat eller inte
% alls.
GPSFel = 0;

% Vilken typ av brusreducering som ska användas och hur stort fönstret det
% appliceras på skall vara. Kolla docs för "smoothing" för fler alternativ.
meth = "movmean";
window = 31;

tic

% Gör så att om man stänger ner fönstret för att välja data så avslutas
% programmet istället för att man får ett fel.
counter = 1;
while counter
    try
        [data, measName] = selection();
        counter = 0;
    catch
        return
    end
end

[data, felData, clockStartStop] = datafix(data, GPSFel);

%kalibrering(data)

ploting(data, measName, meth, window, plotSolo, clockStartStop);

if ~isempty(fieldnames(felData)) && GPSFel == 1
    ploting(felData, ['Data med fel ,', measName], meth, window, plotSolo, clockStartStop);
end

%print2excel(data);

toc