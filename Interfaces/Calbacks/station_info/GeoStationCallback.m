function GeoStationCallback(app)
fig = app.UIFigure;
uiprogressdlg(fig,'Message','Waiting……','Cancelable','on');

% station map
plon = str2double(app.lon.Value);
plat = str2double(app.lat.Value);

children = app.stationmap.Children;
delete(children);

h = geoaxes(app.stationmap);
geoscatter(h, plat, plon, 300,'red', 'p','filled');
geolimits(h,[plat-0.0025 plat+0.0025],[plon-0.00125 plon+0.00125]);
geobasemap(h,app.basemap.Value)
legend(h,'Station')
end