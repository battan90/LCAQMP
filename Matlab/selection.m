%function [Data, timeDN] = Selection(FileID, path)
function [data, measName] = selection()
%{
    selection   -   Tar fram datan och skapar en struct för vidare hantering


Syntax:
    [data, timeDN] = Selection()

Inputs:


Outputs:
    data        -   Struct med all mätdata
    timeDN      -   Cellarray med en vektor för varje enhet innehållande
                    GPS-värden för datum och tid i datenum-format.

Exempel:

Författare: Sebastian Boström
Chalmers Tekniska Högskola
email: sebbos@student.chalmers.se
Skapad: 2022-03-10
Uppdaterad: 2202-03-14
%}

disp('Choosing and loading csv file into Data struct')
name = string;
[fileID, path] = uigetfile('*.csv', ...
    'Select .CSV file from LCAQMP to evaluate', 'MultiSelect', ...
    'on');
%Användt vid utveckling för att inte behöva välja filer
% fileID = {'UNI10_01.CSV','UNIT1_00.CSV','UNIT2_00.CSV','UNIT3_00.CSV','UNIT4_06.CSV','UNIT5_00.CSV','UNIT6_00.CSV','UNIT7_00.CSV','UNIT8_00.CSV','UNIT9_00.CSV'};
% path = 'C:\Users\sebas\OneDrive\Allt annat\Dokument\Programmering\Kandidatarbete\LCAQMP\Matlab\Mätdata\Batteritest\';
fileID = cellstr(fileID);
temp = regexp(path, '\', 'split');
measName = temp(end-1);
for i = 1:length(fileID)
    if contains(fileID{i}, '_')
        temp = regexp(fileID{i}, '_', 'split');
        temp = regexp(temp, '\d*', 'Match');
        name(i) = strcat('UNIT', temp{1});
    else
        temp = regexp(fileID{i}, '\.', 'split');
        temp = regexp(temp, '\d*', 'Match');
        name(i) = strcat('UNIT', temp{1});
    end
    fileDir = append(path, fileID{i});
    opts = detectImportOptions(fileDir);
    opts.VariableNamesLine = 1;
    data.(name(i)) = readtable(fileDir, opts, 'ReadVariableNames', true);
    if max(contains(string(fieldnames(data.(name{i}))), 'Var29'))
        data.(name{i}).Errors = data.(name{i}).Var29;
    end
end
end