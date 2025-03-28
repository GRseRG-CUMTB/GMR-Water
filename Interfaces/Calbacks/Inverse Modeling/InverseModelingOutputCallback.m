function InverseModelingOutputCallback(app)

global Operation_settings

startdate = datenum(Operation_settings.time(1));
enddate = datenum(Operation_settings.time(2));
% path setting
invdir = cellstr({app.inverse_analysis_result_path.Value});
tgstring = app.tide_path.Value;

kspac = app.kspac_hours.Value/24; % in days
tlen = app.tlen_hours.Value/24; % in days
plotl = 1/(24*60);
roughnessplot = 0;

[t_rh,rh_invjs,rh_invpre,rms_js,rms_pre] = invsnr_plot(invdir,startdate, enddate,kspac,tlen,plotl,roughnessplot,app,tgstring);

%% save Final file
Final_file_path = app.FinalfilepathEditField.Value;
Time = datetime(t_rh,'ConvertFrom','datenum')';
RH_Inverse = rh_invjs';
RH_Spectral_bsp = rh_invpre';
Final_info = table(Time,RH_Inverse,RH_Spectral_bsp);
Final_file_name = [Operation_settings.station_name,'_', char(Operation_settings.time(1)),'_',...
    char(Operation_settings.time(2)),'_SNR-Inverse.mat'];
save(fullfile(Final_file_path,Final_file_name),"Final_info")

app.rms_inv.Value = rms_js*100;
app.rms_sp.Value = rms_pre*100;
end