function skyview_plot(app,system,sat)
global Operation_settings
%load data
date = datenum(app.display_date.Value);
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'.mat'])
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'unselected.mat']);

if system == "GPS"
    data_SNR = snr_all.GPS; % for unselected
    SNR_data = snr_data.GPS;
    str = 'G';
elseif system == "GLONASS"
    data_SNR = snr_all.GLONASS;
    SNR_data = snr_data.GLONASS;
    str = 'R';
elseif system == "GALILEO"
    data_SNR = snr_all.GALILEO;
    SNR_data = snr_data.GALILEO;
    str = 'E';
elseif system == "BDS"
    data_SNR = snr_all.BDS;
    SNR_data = snr_data.BDS;
    str = 'C';
end

if sat == "ALL"
    elvation = table2array(data_SNR(:,4));
    elvation(elvation<=0) = nan;

    pic = skyplot(app.sky_all, table2array(data_SNR(:,3)), elvation, ...
        GroupData = categorical(string(table2array(data_SNR(:,end)))));
    set(pic,'MarkerSizeData',2);
    legend(pic, 'NumColumns', 2)

    SNR_data = [SNR_data,table(strcat(str,num2str(SNR_data{:,1})))];
    elvation = table2array(SNR_data(:,4));
    elvation(elvation<=0) = nan;
    pic = skyplot(app.sky_selected,table2array(SNR_data(:,3)),elvation,GroupData = categorical(string(table2array(SNR_data(:,end)))));
    set(pic,'MarkerSizeData',2);
    legend(pic, 'NumColumns', 2)
else
    indx = string(data_SNR{:,end})==string(sat);
    data = data_SNR(indx,:);
    elvation = table2array(data(:,4));
    elvation(elvation<=0) = nan;
    pic = skyplot(app.sky_all,table2array(data(:,3)),elvation,GroupData = categorical(string(table2array(data(:,end)))));
    set(pic,'MarkerSizeData',2);
    legend(pic)

    SNR_data = [SNR_data,table(strcat(str,num2str(SNR_data{:,1})))];
    indx = string(SNR_data{:,end})==string(sat);
    data = SNR_data(indx,:);
    elvation = table2array(data(:,4));
    elvation(elvation<=0) = nan;
    pic = skyplot(app.sky_selected,table2array(data(:,3)),elvation,GroupData = categorical(string(table2array(data(:,end)))));
    set(pic,'MarkerSizeData',2);
    legend(pic, 'NumColumns', 2)
end


end