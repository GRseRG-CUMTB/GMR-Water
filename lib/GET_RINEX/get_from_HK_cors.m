clc
clear
addpath curl-8.9.1_1-win64-mingw\bin\

station_name = 'hkqt';
start_time = datetime('2022-08-11','InputFormat','yyyy-MM-dd');
end_time = datetime('2022-12-31','InputFormat','yyyy-MM-dd');
target_dir = 'G:\GNSS-IR_data\RINEX\Water_level\HKQT';
crx2rnx_path = "D:\crx2rnx\CRX2RNX.exe";

start_date = datenum(start_time);
end_date = datenum(end_time);
for tdatenum = start_date:end_date
    curdt = datetime(tdatenum,'convertfrom','datenum');
    curjd = juliandate(curdt);    

    strday = char(datetime(curdt,'format','DDD'));
    stryr = char(datetime(curdt,'format','yy'));
    stryrl = char(datetime(curdt,'format','yyyy'));

    % download
    remoteFile = ['/rinex3/',stryrl,'/',strday,'/',station_name,'/30s/',...
        upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
    localFile = [target_dir,'/',upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
    ftps_url = 'ftps://rinex.geodetic.gov.hk';
    command = sprintf('curl.exe --ftp-ssl -k %s%s -o %s', ftps_url, remoteFile, localFile);
    status = 1;
    while status
        status = system(command);
    end
    gunzip(localFile)
    delete(localFile)

    % crx2rnx
    crx_file = [target_dir,'/',upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.crx'];
    d_file = [target_dir,'/',upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.22d'];
    movefile(crx_file, d_file)
    command = sprintf('"%s" "%s"', crx2rnx_path, d_file);
    system(command)
    delete(d_file)
    o_file = [target_dir,'/',upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.22o'];
    rnx_file = [target_dir,'/',upper(station_name),'00','HKG_R_',stryrl,strday,'0000_01D_','30S_MO.rnx'];
    movefile(o_file, rnx_file)
end