function [snr_data] = load_SNRdata(app, d)
% Extract and save the SNR information from the RINEX file
% On the basis of Operation_settings
%-----------------------------------------------------------

fig = app.UIFigure;

global Operation_settings
station   = Operation_settings.station_name;
startdate = datenum(Operation_settings.time(1));
enddate   = datenum(Operation_settings.time(2));
all_days  = daysact(Operation_settings.time(1), Operation_settings.time(2)) + 1;

tdatenum = startdate - 1; 
datastr = Operation_settings.obs_path;
ok_days = 0;

% LOAD SNR DATA
while tdatenum < enddate
    tdatenum = tdatenum + 1;
    curdt = datetime(tdatenum,'convertfrom','datenum');
    curjd = juliandate(curdt);
    [gpsw, sow, ~] = jd2gps(curjd);
    dow = sow / 86400;

    strday = char(datetime(curdt,'format','DDD'));
    stryr = char(datetime(curdt,'format','yy'));
    stryrl = char(datetime(curdt,'format','yyyy'));

    % rinex version
    if Operation_settings.rinex_version == 'rinex 2'
        rinex_option = 1;
    elseif Operation_settings.rinex_version == 'rinex 3'
        rinex_option = 2;
    end
    d.Message = strcat('Date: ', char(curdt),  '  Rinex version:', Operation_settings.rinex_version(end));

    % for the different way of naming
    if rinex_option == 1
        if exist([datastr, '/', station, strday, '0.', stryr, 'o'], 'file') == 2 % exist
            obsstr = [datastr, station, strday, '0.', stryr, 'o'];
        else
            uialert(fig, 'Rinex files does not exist, please check the naming method!', ...
                'warning');
            continue
        end
    elseif rinex_option == 2
        dts = sprintf('%02s',Operation_settings.dt);
        if exist([datastr, upper(station), '00', Operation_settings.station_belong, '_R_', stryrl, strday, '0000_01D_', num2str(dts), 'S_MO.rnx'], 'file') == 2
            obsstr = [datastr, upper(station), '00', Operation_settings.station_belong, '_R_', stryrl, strday, '0000_01D_', num2str(dts), 'S_MO.rnx'];
        elseif exist([datastr, '/', station, strday, '0.', stryr, 'o'], 'file')
            obsstr = [datastr, '/', station, strday, '0.', stryr, 'o'];
        else
            uialert(fig, 'Rinex files does not exist, please check the naming method!', ...
                'warning');
            continue
        end
    end

    % The different precision ephemeris mechanism
    sp3option = Operation_settings.sp3_type;
    if sp3option == 'com'
        sp3str = [Operation_settings.sp3_path, 'com', num2str(gpsw), num2str(round(dow)), '.sp3'];
    elseif sp3option == 'igs'
        sp3str = [Operation_settings.sp3_path, '\igs', num2str(gpsw), num2str(round(dow)), '.sp3'];
    elseif sp3option == 'COD'
        sp3str = [Operation_settings.sp3_path, 'COD0MGXFIN_', stryrl, strday, '0000_01D_05M_ORB.SP3'];
    elseif sp3option == 'GFZ'
        sp3str = [Operation_settings.sp3_path, 'GFZ0MGXRAP_', stryrl, strday, '0000_01D_05M_ORB.SP3'];
    elseif sp3option == 'WUM'
        sp3str = [Operation_settings.sp3_path, 'WUM0MGXFIN_', stryrl, strday, '0000_01D_05M_ORB.SP3'];
    end
    if ~exist(sp3str,"file")
        uialert(fig, 'Ephemeris file not found, please use standard naming format!', ...
                'warning');
    end

    % For the different rinex version
    if rinex_option == 1    % for RINEX2
        [snr_azi, snr_all, snr_data] = rinex2snrfile_1(obsstr, sp3str, d);
    elseif rinex_option == 2 % for RINEX3
        [snr_azi, snr_all, snr_data] = rinex2snrfile_2(obsstr, sp3str, d, all_days);
    end

    save([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(tdatenum), '.mat'], 'snr_data');
    save([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(tdatenum), 'unselected.mat'], 'snr_all');
    save([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(tdatenum), 'azi.mat'], 'snr_azi');

    % progress update
    ok_days = ok_days + 1;
    progress_day = strcat('(', num2str(ok_days), '/', num2str(all_days), ')');
    d.Title = strcat('Extraction progress: ', progress_day);
    d.Value = ok_days / all_days;
end
end
