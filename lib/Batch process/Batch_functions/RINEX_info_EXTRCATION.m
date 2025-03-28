% Extract and save the information from the RINEX file
% For batch process
%-----------------------------------------------------------


startdate = datenum(start_time);
enddate   = datenum(end_time);
station_info_all = struct('azi_lim',azi_lim,'elv_lim',elv_lim,'azi_mask',azi_mask, ...
    'sta_lon',sta_lon,'sta_lat',sta_lat,'staxyz',staxyz,'station_belong',station_belong);
% LOAD SNR DATA
if string(settings.par) == "None"
    for tdatenum = startdate: enddate
        disp([char(datetime(tdatenum,'ConvertFrom','datenum'))])
        Extract(settings, tdatenum, station_info_all)
    end
else
    par = parpool(str2double(settings.par));
    parfor tdatenum = startdate: enddate
        Extract(settings, tdatenum, station_info_all)
    end
    delete(par)
end

function Extract(settings, tdatenum, station_info_all)
station   = settings.station_name;
station_belong = station_info_all.station_belong;
datastr   = settings.Rinex_path;
curdt = datetime(tdatenum,'convertfrom','datenum');
curjd = juliandate(curdt);
[gpsw, sow, ~] = jd2gps(curjd);
dow = sow / 86400;

strday = char(datetime(curdt,'format','DDD'));
stryr  = char(datetime(curdt,'format','yy'));
stryrl = char(datetime(curdt,'format','yyyy'));

% rinex version
if settings.Rinex_version == '2'
    rinex_option = 1;
elseif settings.Rinex_version == '3'
    rinex_option = 2;
end

% for the different way of naming
if rinex_option == 1
    if exist([datastr, '/', station, strday, '0.', stryr, 'o'], 'file') == 2 % exist
        obsstr = [datastr, '/',station, strday, '0.', stryr, 'o'];
    else
        uialert(fig, 'Rinex files does not exist, please check the naming method!', ...
            'warning');
    end
elseif rinex_option == 2
    dts = sprintf('%02s',num2str(settings.Rinex_dt));
    if exist([datastr, '/',upper(station), '00', station_belong, '_R_', ...
            stryrl, strday, '0000_01D_', num2str(dts), 'S_MO.rnx'], 'file') == 2
        obsstr = [datastr, '/', upper(station), '00', station_belong, '_R_',...
            stryrl, strday, '0000_01D_', num2str(dts), 'S_MO.rnx'];
    elseif exist([datastr, '/', station, strday, '0.', stryr, 'o'], 'file')
        obsstr = [datastr, '/', station, strday, '0.', stryr, 'o'];
    else
        uialert(fig, 'Rinex files does not exist, please check the naming method!', ...
            'warning');
    end
end

% The different precision ephemeris mechanism
AC = settings.AC;
if AC == "com"
    sp3str = [settings.Eph_path, '\com', num2str(gpsw), num2str(round(dow)), '.sp3'];
elseif AC == "igs"
    sp3str = [settings.Eph_path, '\igs', num2str(gpsw), num2str(round(dow)), '.sp3'];
elseif AC == "CODE"
    sp3str = [settings.Eph_path, '\COD0MGXFIN_', stryrl, strday, '0000_01D_05M_ORB.SP3'];
elseif AC == "GFZ"
    sp3str = [settings.Eph_path, '\GFZ0MGXRAP_', stryrl, strday, '0000_01D_05M_ORB.SP3'];
end
if ~exist(sp3str,"file")
    uialert(fig, 'Ephemeris file not found, please use standard naming format!', ...
        'warning');
end

% For the different rinex version

if sum(settings.methods(1:2)) ~= 0 % For SNR
    if rinex_option == 1    % for RINEX2
        [snr_azi, snr_all, snr_data] = Batch_rinex2snrfile_1(obsstr, sp3str, station_info_all);
    elseif rinex_option == 2 % for RINEX3
        [snr_azi, snr_all ,snr_data] = Batch_rinex2snrfile_2(obsstr, sp3str, station_info_all, settings);
    end
    
    if ~exist([settings.Out_path,'\SNR_file'],'dir')
        mkdir([settings.Out_path,'\SNR_file'])
    end
    parsave([settings.Out_path , '\SNR_file\', settings.station_name, num2str(tdatenum), '.mat'],           snr_data,'snr_data');
%     parsave([settings.Out_path , '\SNR_file\', settings.station_name, num2str(tdatenum), 'unselected.mat'], snr_all,'snr_all');
%     parsave([settings.Out_path , '\SNR_file\', settings.station_name, num2str(tdatenum), 'azi.mat'],        snr_azi,'snr_azi');
end

if settings.methods(3) ~= 0 % For carrier
    if rinex_option == 1    % for RINEX2
        [carrier_azi, carrier_all, carrier_data] = Batch_rinex2carrierfile_1(obsstr, sp3str, station_info_all);
    elseif rinex_option == 2 % for RINEX3
        [carrier_azi, carrier_all, carrier_data] = Batch_rinex2carrierfile_2(obsstr, sp3str, station_info_all, settings);
    end
    
    if ~exist([settings.Out_path,'\Carrier_file'],'dir')
        mkdir([settings.Out_path,'\Carrier_file'])
    end
    parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), '.mat'],           carrier_data,'carrier_data');
%     parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), 'unselected.mat'], carrier_all,'carrier_all');
%     parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), 'azi.mat'],        carrier_azi,'carrier_azi');
    is_carrier = 1;
end

if settings.methods(4) ~= 0 % For pseudorange
    if rinex_option == 1    % for RINEX2
        [pseudorange_azi, pseudorange_all, pseudorange_data] = Batch_rinex2pseudorangefile_1(obsstr, sp3str, station_info_all);
    elseif rinex_option == 2 % for RINEX3
        [pseudorange_azi, pseudorange_all, pseudorange_data] = Batch_rinex2pseudorangefile_2(obsstr, sp3str, station_info_all, settings);
    end
    
    if ~exist([settings.Out_path,'\Pseudorange_file'],'dir')
        mkdir([settings.Out_path,'\Pseudorange_file'])
    end
    parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), '.mat'],           pseudorange_data,'pseudorange_data');
%     parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), 'unselected.mat'], pseudorange_all,'pseudorange_all');
%     parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), 'azi.mat'],        pseudorange_azi,'pseudorange_azi');
    is_pseudorange = 1;
end

if settings.methods(5) ~= 0 % For carrier & pseudorange
    if ~is_pseudorange
        if rinex_option == 1    % for RINEX2
            [pseudorange_azi, pseudorange_all, pseudorange_data] = Batch_rinex2pseudorangefile_1(obsstr, sp3str, station_info_all);
        elseif rinex_option == 2 % for RINEX3
            [pseudorange_azi, pseudorange_all, pseudorange_data] = Batch_rinex2pseudorangefile_2(obsstr, sp3str, station_info_all, settings);
        end
        
        if ~exist([settings.Out_path,'\Pseudorange_file'],'dir')
            mkdir([settings.Out_path,'\Pseudorange_file'])
        end
        parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), '.mat'],           pseudorange_data,'pseudorange_data');
%         parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), 'unselected.mat'], pseudorange_all,'pseudorange_all');
%         parsave([settings.Out_path , '\Pseudorange_file\', settings.station_name, num2str(tdatenum), 'azi.mat'],        pseudorange_azi,'pseudorange_azi');
    end
    
    if ~is_carrier
        if rinex_option == 1    % for RINEX2
            [carrier_azi, carrier_all, carrier_data] = Batch_rinex2carrierfile_1(obsstr, sp3str, station_info_all);
        elseif rinex_option == 2 % for RINEX3
            [carrier_azi, carrier_all, carrier_data] = Batch_rinex2carrierfile_2(obsstr, sp3str, station_info_all, settings);
        end
        
        if ~exist([settings.Out_path,'\Carrier_file'],'dir')
            mkdir([settings.Out_path,'\Carrier_file'])
        end
        parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), '.mat'],           carrier_data,'carrier_data');
%         parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), 'unselected.mat'], carrier_all,'carrier_all');
%         parsave([settings.Out_path , '\Carrier_file\', settings.station_name, num2str(tdatenum), 'azi.mat'],        carrier_azi,'carrier_azi');
    end
end
end