function ExtractSNRCallback(app)

global Operation_settings
sp3option = Operation_settings.sp3_type;
startdate = datenum(Operation_settings.time(1));
enddate = datenum(Operation_settings.time(2));

all_days = daysact(Operation_settings.time(1), Operation_settings.time(2)) + 1;
dateList = Operation_settings.time(1) : days(1) : Operation_settings.time(2);
app.display_date.Items = string(datestr(dateList, 'yyyy-mm-dd'));
app.display_date.Value = app.display_date.Items(end);
ok_days = 0;
fig = app.UIFigure;
progress_day = strcat('(', num2str(ok_days), '/', num2str(all_days), ')');
d = uiprogressdlg(fig, 'Title', strcat('Extraction progress ', progress_day), ...
    'Message', 'Extracting……', 'Cancelable', 'on');
drawnow
set(0, 'DefaultFigureVisible', 'off');
[snr_data] = load_SNRdata(app, d);

% display result

load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(enddate), '.mat'])
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(enddate), 'unselected.mat']);

if isfield(snr_data, 'GPS')
    app.GPS_result.Data = snr_data.GPS;
    app.GPS_result.ColumnName = snr_data.GPS.Properties.VariableNames;
    app.GPS_satellite_display.Items = unique(string(table2array(snr_all.GPS(:, "GPS_data_prn_str"))));
    app.GPS_band.Items = snr_all.GPS.Properties.VariableNames(5:end-1);
    snr_plot(app, app.GPS_satellite_display.Value, app.GPS_band.Value);
end
if isfield(snr_data, 'GLONASS')
    app.GLONASS_result.Data = snr_data.GLONASS;
    app.GLONASS_result.ColumnName = snr_data.GLONASS.Properties.VariableNames;
    app.GLONASS_satellite_display.Items = unique(string(table2array(snr_all.GLONASS(:, "GLONASS_data_prn_str"))));
    app.GLONASS_band.Items = snr_all.GLONASS.Properties.VariableNames(5:end-1);
    snr_plot(app, app.GLONASS_satellite_display.Value, app.GLONASS_band.Value);
end
if isfield(snr_data, 'GALILEO')
    app.GALILEO_result.Data = snr_data.GALILEO;
    app.GALILEO_result.ColumnName = snr_data.GALILEO.Properties.VariableNames;
    app.GALILEO_satellite_display.Items = unique(string(table2array(snr_all.GALILEO(:, "GALILEO_data_prn_str"))));
    app.GALILEO_band.Items = snr_all.GALILEO.Properties.VariableNames(5:end-1);
    snr_plot(app, app.GALILEO_satellite_display.Value, app.GALILEO_band.Value);
end
if isfield(snr_data, 'BDS')
    app.BDS_result.Data = snr_data.BDS;
    app.BDS_result.ColumnName = snr_data.BDS.Properties.VariableNames;
    app.BDS_satellite_display.Items = unique(string(table2array(snr_all.BDS(:, "BDS_data_prn_str"))));
    app.BDS_band.Items = snr_all.BDS.Properties.VariableNames(5:end-1);
    snr_plot(app, app.BDS_satellite_display.Value, app.BDS_band.Value);
end

set(0, 'DefaultFigureVisible', 'on');
return
end
