function GetEphCallback(app)
start_date = app.starttime.Value;
end_date = app.endtime.Value;
sp3_option = app.sp3_type.Value;
save_path_sp3 = app.sp3.Value;
fig = app.UIFigure;
get_sp3(fig, start_date, end_date, sp3_option, save_path_sp3)
end