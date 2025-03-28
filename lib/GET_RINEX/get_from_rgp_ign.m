function get_from_rgp_ign(station_name, ISO_short, st, et, target_dir, varargin)
% mcc -m get_from_rgp_ign.m -a 7z.exe -a CRX2RNX.exe -a E:\GMR-water\code\GET_RINEX\curl-8.9.1_1-win64-mingw

for var_id = 1:numel(varargin)
    var = varargin{var_id};
    if var(1) == 'p'
        par_settings = str2double(var(2:end));
    end
end

start_time = datetime(st,'InputFormat','yyyy-MM-dd');
end_time = datetime(et,'InputFormat','yyyy-MM-dd');
start_date = datenum(start_time);
end_date = datenum(end_time);
if exist("par_settings", "var")
    p = parpool(par_settings);
    parfor tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'convertfrom','datenum');

        strday = char(datetime(curdt,'format','DDD'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if ~exist(target_dir,"dir")
            mkdir(target_dir)
        end
        rnx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.rnx'];
        if exist(rnx_file, "file")
            continue
        end

        % download
        remoteFile = ['/pub/data_v3/',stryrl,'/',strday,'/data_30/',...
            upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        localFile = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        ftps_url = 'ftp://rgpdata.ign.fr/';
        command = sprintf('curl.exe --ftp-ssl -k %s%s -o %s', ftps_url, remoteFile, localFile);
        status = 1;
        while status
            status = system(command);
        end
        gunzip(localFile)
        delete(localFile)

        % crx2rnx
        crx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx'];
        d_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22d'];
        movefile(crx_file, d_file)
        currentPath = fileparts(mfilename('fullpath'));
        command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
        system(command);
        delete(d_file)
        o_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22o'];

        movefile(o_file, rnx_file)

        continue
    end

    delete(p)
else
    for tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'convertfrom','datenum');

        strday = char(datetime(curdt,'format','DDD'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if ~exist(target_dir,"dir")
            mkdir(target_dir)
        end
        rnx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.rnx'];
        if exist(rnx_file, "file")
            continue
        end

        % download
        remoteFile = ['/pub/data_v3/',stryrl,'/',strday,'/data_30/',...
            upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        localFile = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        ftps_url = 'ftp://rgpdata.ign.fr/';
        command = sprintf('curl.exe --ftp-ssl -k %s%s -o %s', ftps_url, remoteFile, localFile);
        status = 1;
        while status
            status = system(command);
        end
        gunzip(localFile)
        delete(localFile)

        % crx2rnx
        crx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx'];
        d_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22d'];
        movefile(crx_file, d_file)
        currentPath = fileparts(mfilename('fullpath'));
        command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
        system(command);
        delete(d_file)
        o_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22o'];

        movefile(o_file, rnx_file)
        continue
    end
end
end
