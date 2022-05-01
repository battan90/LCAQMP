%% Ratio PM

% Kod för att beräkna förhållandet mellan antal PM av storlekar 10 och 2.5

clf

data = selection();

[data, felData, clockStartStop] = datafix(data);

name = fieldnames(data);
lname = length(name); % antal LCAQMP

lengths = zeros(1,length(name));

for i = 1:lname
    lengths(1,i) = length(data.(name{i}).GPS_hour); %längden på alla data i en vektor
end

mini = min(lengths); % vill utgå från den kortaste datamängden

ratio = zeros(lname, mini);

for i = 1:lname
    for j = 1:mini
        if (data.(name{i}).SDS011_pm25(j) == 0) || (isnan(data.(name{i}).SDS011_pm25(j)))
            ratio(i,j) = 0; % För att undvika dela med noll eller nan
        else
            ratio(i,j) = data.(name{i}).SDS011_pm10(j)./data.(name{i}).SDS011_pm25(j); %beräknar förhållandet
        end
    end
    
end

% Ger svaret som ett medelvärde
medel = sum(transpose(ratio))/mini

% (Försökte även plotta istället för att medelvärdera, blev inte bra..
% Kanske man kan plotta halvtimmesmeddelvärde)
