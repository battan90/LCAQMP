clc
clear all
close all

%% Import data from text file
% Script for importing data from the following text file:
%
%    filename: C:\Users\sebas\OneDrive\Skrivbord\20220209a.txt
%
% Auto-generated by MATLAB on 08-Mar-2022 11:34:47

%% Setup the Import Options and import the data
opts = delimitedTextImportOptions("NumVariables", 63);

% Specify range and delimiter
opts.DataLines = [2, Inf];
opts.Delimiter = "\t";

% Specify column names and types
opts.VariableNames = ["Times", "TC0", "TC1", "TC2", "TC3", "TC4", "TC5", "TC6", "TC7", "TC8", "TC9", "TC10", "TC11", "TC12", "TC13", "TC14", "TC15", "PAFA", "test", "dP1Fuji", "aP3ejec", "aP5bDPF", "dP3DPF", "aP1DMS", "aP5dil", "AI3_0", "AI3_1", "AI3_2", "AI3_3", "AI3_4", "AI3_5", "AI3_6", "AI3_7", "AP1", "tmp2", "tmp3", "tmp4", "AI4_0", "AI4_1", "AI4_2", "AI4_3", "co", "co2", "NO", "NOx", "AI5_0", "AI5_1", "AI5_2", "AI5_3", "MFC1SetValmlnmint", "MFC2SetValmlnmint", "MFC3SetValmlnmint", "MFC4SetValmlnmint", "MFC5SetValmlnmint", "MFC1ActValmlnmin", "MFC2ActValmlnmin", "MFC3ActValmlnmin", "MFC4ActValmlnmin", "MFC5ActValmlnmin", "TempSP", "TempPV", "co2M", "coM"];
opts.VariableTypes = ["double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double", "double"];

% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Specify variable properties
opts = setvaropts(opts, ["Times", "TC0", "TC1", "TC2", "TC3", "TC4", "TC5", "TC6", "TC7", "TC8", "TC9", "TC10", "TC11", "TC12", "TC13", "TC14", "TC15", "PAFA", "test", "dP1Fuji", "aP3ejec", "aP5bDPF", "dP3DPF", "aP1DMS", "aP5dil", "AI3_0", "AI3_1", "AI3_2", "AI3_3", "AI3_4", "AI3_5", "AI3_6", "AI3_7", "AP1", "tmp2", "tmp3", "tmp4", "AI4_0", "AI4_1", "AI4_2", "AI4_3", "co", "co2", "NO", "NOx", "AI5_0", "AI5_1", "AI5_2", "AI5_3", "MFC1SetValmlnmint", "MFC2SetValmlnmint", "MFC3SetValmlnmint", "MFC4SetValmlnmint", "MFC5SetValmlnmint", "MFC1ActValmlnmin", "MFC2ActValmlnmin", "MFC3ActValmlnmin", "MFC4ActValmlnmin", "MFC5ActValmlnmin", "TempSP", "TempPV", "co2M", "coM"], "DecimalSeparator", ",");

% Import the data
a1 = readtable("C:\Users\sebas\OneDrive\Skrivbord\20220209a.txt", opts, 'ReadVariableNames', true);

%% Convert to output type
%a1 = table2cell(a1);
%a1 = [opts.VariableNames; a1];
%numIdx = cellfun(@(x) ~isnan(str2double(x)), a1);
%a1(numIdx) = cellfun(@(x) {str2double(x)}, a1(numIdx));
%a1 = table2timetable(a1);
a1 = head(a1,29695);
%% Clear temporary variables
clear opts
%% Plott

stackedplot(a1, {'MFC1ActValmlnmint', 'MFC2ActValmlnmint', 'MFC3ActValmlnmint', 'MFC4ActValmlnmint', 'MFC5ActValmlnmint'})
