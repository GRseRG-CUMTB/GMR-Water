clc
clear 

path = "30_2023.txt";
data = readtable(path);


date = char(data{:,1});
date = datetime(date,"Format","dd/MM/yyyy HH:mm");
xaxis = datenum(date);
slvl = data{:,2};
h = plot(datetime(xaxis,'ConvertFrom','datenum'),slvl);

save("mayg_tide_data_2023.mat","xaxis","slvl");

%% for noaa
data = readtable("data\tide_data\CO-OPS_9449880_met.csv");
date1 = char(data{:,1});
date2 = char(data{:,2});
date = [date1 date2];
date = datetime(date,"Format","yyyy/MM/ddHH:mm");
xaxis = datenum(date);
slvl = data{:,5};
h = plot(datetime(xaxis, 'ConvertFrom','datenum'),slvl);

save("sc02_tide_data_2023.mat","xaxis","slvl");