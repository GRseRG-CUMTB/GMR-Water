function ImportSettingCallback(app)

[fileNames, filepath] = uigetfile(fullfile([pwd, '\Settings\'], '*.mat*'), ...
    'Select Settings');
load(fullfile(filepath,fileNames))

app.station.Value = station_name;
app.belong.Value = station_belong;
app.X.Value = station_xyz(1);
app.Y.Value = station_xyz(2);
app.Z.Value = station_xyz(3);
app.lon.Value = num2str(station_l(1));
app.lat.Value = num2str(station_l(2));

app.azi_min.Value = num2str(azi(1));
app.azi_max.Value = num2str(azi(2));
app.azimask_min.Value = num2str(azimask(1));
app.azimask_max.Value = num2str(azimask(2));
app.elv_min.Value = num2str(elv(1));
app.elv_max.Value = num2str(elv(2));

app.dt.Value = dt;
app.rinex_version.Value = rinex_version;

app.sp3_type.Value = sp3_type;
app.sp3filename.Value = sp3_file;
app.obsfilename.Value = obs_file;
app.observation.Value = obs_path;
app.sp3.Value = sp3_path;
app.starttime.Value = time(1);
app.endtime.Value = time(2);

global Operation_settings
Operation_settings = load(fullfile(filepath, fileNames));
fig = app.UIFigure;
uialert(fig,"Import successful!","Have been saved", "Icon","success");

end