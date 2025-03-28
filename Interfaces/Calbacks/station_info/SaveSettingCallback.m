function SaveSettingCallback(app)
global Operation_settings

station_name   = app.station.Value;
station_belong = app.belong.Value;
station_xyz    = [app.X.Value app.Y.Value app.Z.Value];
station_l      = [str2double(app.lon.Value) str2double(app.lat.Value)];

azi     = [str2double(app.azi_min.Value) str2double(app.azi_max.Value)];
azimask = [str2double(app.azimask_min.Value) str2double(app.azimask_max.Value)];
elv     = [str2double(app.elv_min.Value) str2double(app.elv_max.Value)];

dt            = app.dt.Value;
rinex_version = app.rinex_version.Value;

sp3_type = app.sp3_type.Value;
sp3_file = app.sp3filename.Value;
obs_file = app.obsfilename.Value;
obs_path = app.observation.Value;
sp3_path = app.sp3.Value;
time     = [app.starttime.Value app.endtime.Value];

savedir = uigetdir;
save_path = strcat(savedir,'\station_setting.mat');
save(save_path,"time","sp3_type","rinex_version","station_l","station_xyz","elv","azimask", ...
    "azi","station_belong","station_name","obs_path","sp3_path","dt", "sp3_file", "obs_file")

fig = app.UIFigure;
message = ["Station information saved successfully! ",strcat("Path: ",save_path)];
uialert(fig,message,"Have been saved", "Icon","success");

Operation_settings = load(save_path);
end