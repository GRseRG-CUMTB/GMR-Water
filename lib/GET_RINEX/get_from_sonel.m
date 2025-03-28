function get_from_sonel(station_name, ISO_short, st, et, target_dir, Rinex_version, varargin)

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
        stryr = char(datetime(curdt,'format','yy'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if ~exist(target_dir,"dir")
            mkdir(target_dir)
        end
        if Rinex_version == "RINEX3"
            rnx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.rnx'];
            remoteFile = ['/gps/data/',stryrl,'/',strday,'/',...
                upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
            localFile = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        elseif Rinex_version == "RINEX2"
            rnx_file = [target_dir,'/',lower(station_name),strday,'0.',stryr,'o'];
            remoteFile = ['/gps/data/',stryrl,'/',strday,'/',...
                lower(station_name),strday,'0.',stryr,'d.Z'];
            localFile = [target_dir,'/',lower(station_name),strday,'0.',stryr,'d.Z'];
        end
        if exist(rnx_file, "file")
            continue
        end
        try
            % download
            ftps_url = 'ftp.sonel.org';
            command = sprintf('curl.exe --ftp-ssl -k %s%s -o %s', ftps_url, remoteFile, localFile);
            status = 1;
            while status
                status = system(command);
            end
            if Rinex_version == "RINEX3"
                gunzip(localFile)
                delete(localFile)
                % crx2rnx
                crx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx'];
                d_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22d'];
                movefile(crx_file, d_file)
                currentPath = fileparts(mfilename('fullpath'));
                command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
                system(command)
                delete(d_file)
                o_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22o'];

                movefile(o_file, rnx_file)
            elseif Rinex_version == "RINEX2"
                command = sprintf('"7z.exe" x "%s" -o"%s" -y', localFile, target_dir);
                system(command);

                % crx2rnx
                d_file = [target_dir,'/',lower(station_name),strday,'0.',stryr,'d'];
                currentPath = fileparts(mfilename('fullpath'));
                command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
                system(command)
                delete(d_file)
            end
        catch
            continue
        end
    end
    delete(p)
else
    for tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'convertfrom','datenum');

        strday = char(datetime(curdt,'format','DDD'));
        stryr = char(datetime(curdt,'format','yy'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if ~exist(target_dir,"dir")
            mkdir(target_dir)
        end
        if Rinex_version == "RINEX3"
            rnx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.rnx'];
            remoteFile = ['/gps/data/',stryrl,'/',strday,'/',...
                upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
            localFile = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx.gz'];
        elseif Rinex_version == "RINEX2"
            rnx_file = [target_dir,'/',lower(station_name),strday,'0.',stryr,'o'];
            remoteFile = ['/gps/data/',stryrl,'/',strday,'/',...
                lower(station_name),strday,'0.',stryr,'d.Z'];
            localFile = [target_dir,'/',lower(station_name),strday,'0.',stryr,'d.Z'];
        end
        if exist(rnx_file, "file")
            continue
        end
        try
            % download
            ftps_url = 'ftp.sonel.org';
            command = sprintf('curl.exe --ftp-ssl -k %s%s -o %s', ftps_url, remoteFile, localFile);
            status = 1;
            while status
                status = system(command);
            end
            if Rinex_version == "RINEX3"
                gunzip(localFile)
                delete(localFile)
                % crx2rnx
                crx_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.crx'];
                d_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22d'];
                movefile(crx_file, d_file)
                currentPath = fileparts(mfilename('fullpath'));
                command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
                system(command)
                delete(d_file)
                o_file = [target_dir,'/',upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_','30S_MO.22o'];

                movefile(o_file, rnx_file)
            elseif Rinex_version == "RINEX2"
                command = sprintf('"7z.exe" x "%s" -o"%s" -y', localFile, target_dir);
                system(command);

                % crx2rnx
                d_file = [target_dir,'/',lower(station_name),strday,'0.',stryr,'d'];
                currentPath = fileparts(mfilename('fullpath'));
                command = sprintf('%s %s', [currentPath,'\CRX2RNX.exe'], d_file);
                system(command)
                delete(d_file)
            end
        catch
            continue
        end
    end
end