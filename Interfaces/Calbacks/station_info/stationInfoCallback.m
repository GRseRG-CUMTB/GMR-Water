function stationInfoCallback(app)
    [fileNames, filepath] = uigetfile(fullfile(pwd, 'data', 'station_info', '*.m*'), ...
        'Select station information');
    
    if isequal(fileNames, 0)
        return; 
    end
    

    load(fullfile(filepath, fileNames));
    

    app.elv_max.Value = num2str(elv_lim(2));
    app.elv_min.Value = num2str(elv_lim(1));
    app.azi_min.Value = num2str(azi_lim(1));
    app.azi_max.Value = num2str(azi_lim(2));
    app.azimask_max.Value = num2str(azi_mask(2));
    app.azimask_min.Value = num2str(azi_mask(1));
    app.lat.Value = num2str(sta_lat);
    app.lon.Value = num2str(sta_lon);
    [~,~,h] = ecef2geodetic(wgs84Ellipsoid('kilometer'), staxyz(1), staxyz(2), staxyz(3));
    app.H.Value = num2str(h);

    app.X.Value = staxyz(1);
    app.Y.Value = staxyz(2);
    app.Z.Value = staxyz(3);

    app.belong.Value = station_belong;
    app.station.Value = fileNames(1:4);
end
