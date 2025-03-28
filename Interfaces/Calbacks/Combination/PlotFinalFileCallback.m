function PlotFinalFileCallback(app,type)
global Operation_settings
path = app.tide_path.Value;
load(path)
ax = app.results;
plot(ax, datetime(xaxis,'ConvertFrom','datenum'),slvl,'black','DisplayName','Tide Level');
hold(ax,"on")
startdate = datenum(Operation_settings.time(1));
enddate   = datenum(Operation_settings.time(2));
gnss_system = string(app.s1.Value);

% load final file
data_path = [app.path_cpi_m.Value,'/',Operation_settings.station_name,'_',...
    char(datetime(startdate,'ConvertFrom','datenum','Format','uuuu-MM-dd')),'_',...
    char(datetime(enddate,'ConvertFrom','datenum','Format','uuuu-MM-dd'))...
    ,'_OBS','-',char(type),'.mat'];
load(data_path)

data = Final_info.(strcat(gnss_system,type));
if type == "CP"
    combination_type = 'Carrier & Pseudorange';
else
    combination_type = app.combination_type.Value;
end
scatter(ax, data.Time, app.antenna_height.Value-data.RH,'red+',DisplayName=[app.s1.Value, '  ',combination_type])

xlim(ax, [Operation_settings.time(1), Operation_settings.time(2)+1])
legend(ax)
hold(ax,"off")

if app.cor.Value == 1
    cor_plot(app.antenna_height.Value-data.RH, datenum(data.Time), slvl, xaxis)
end

if app.DH.Value == 1
    DH_plot(app.antenna_height.Value-data.RH, datenum(data.Time), slvl, xaxis)
end
return
end