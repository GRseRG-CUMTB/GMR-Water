function DateChangeCallback(app)
date = char(app.display_date.Value);
date = datenum(date,'yyyy-mm-dd');

global Operation_settings
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'.mat'])
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'unselected.mat']);
if isfield(snr_data, 'GPS')
    app.GPS_result.Data = snr_data.GPS;
    app.GPS_result.ColumnName = snr_data.GPS.Properties.VariableNames;
    app.GPS_satellite_display.Items = unique(string(table2array(snr_all.GPS(:,"GPS_data_prn_str"))));
    app.GPS_band.Items = snr_all.GPS.Properties.VariableNames(5:end-1);
end
if isfield(snr_data, 'GLONASS')
    app.GLONASS_result.Data = snr_data.GLONASS;
    app.GLONASS_result.ColumnName = snr_data.GLONASS.Properties.VariableNames;
    app.GLONASS_satellite_display.Items = unique(string(table2array(snr_all.GLONASS(:,"GLONASS_data_prn_str"))));
    app.GLONASS_band.Items = snr_all.GLONASS.Properties.VariableNames(5:end-1);
end
if isfield(snr_data, 'GALILEO')
    app.GALILEO_result.Data = snr_data.GALILEO;
    app.GALILEO_result.ColumnName = snr_data.GALILEO.Properties.VariableNames;
    app.GALILEO_satellite_display.Items = unique(string(table2array(snr_all.GALILEO(:,"GALILEO_data_prn_str"))));
    app.GALILEO_band.Items = snr_all.GALILEO.Properties.VariableNames(5:end-1);
end
if isfield(snr_data, 'BDS')
    app.BDS_result.Data = snr_data.BDS;
    app.BDS_result.ColumnName = snr_data.BDS.Properties.VariableNames;
    app.BDS_satellite_display.Items = unique(string(table2array(snr_all.BDS(:,"BDS_data_prn_str"))));
    app.BDS_band.Items = snr_all.BDS.Properties.VariableNames(5:end-1);
end
end
