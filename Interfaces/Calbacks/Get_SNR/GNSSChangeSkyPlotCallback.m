function GNSSChangeSkyPlotCallback(app)

global Operation_settings
date = char(app.display_date.Value);
date = datenum(date,'yyyy-mm-dd');
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'.mat'])
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'unselected.mat']);
system = string(app.GNSS_sky.Value);
if system == "GPS"
    app.satellite_sky.Items = ["ALL";unique(string(table2array(snr_all.GPS(:,"GPS_data_prn_str"))))];
elseif system == "GLONASS"
    app.satellite_sky.Items = ["ALL";unique(string(table2array(snr_all.GLONASS(:,"GLONASS_data_prn_str"))))];
elseif system == "GALILEO"
    app.satellite_sky.Items = ["ALL";unique(string(table2array(snr_all.GALILEO(:,"GALILEO_data_prn_str"))))];
elseif system == "BDS"
    app.satellite_sky.Items = ["ALL";unique(string(table2array(snr_all.BDS(:,"BDS_data_prn_str"))))];
end
app.satellite_sky.Value = "ALL";
skyview_plot(app, system, 'ALL')

end