function get_from_earthscope(station_name, ISO_short, st, et, target_dir, ...
    Rinex_version, api_key, varargin)

for var_id = 1:numel(varargin)
    var = varargin{var_id};
    if var(1) == 'p'
        par_settings = str2double(var(2:end));
    end
end

start_time = datetime(st,'InputFormat','yyyy-MM-dd');
end_time   = datetime(et,'InputFormat','yyyy-MM-dd');
start_date = datenum(start_time);
end_date = datenum(end_time);
if exist("par_settings", "var")
    p = parpool(par_settings);
    parfor tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'convertfrom','datenum');

        strday = char(datetime(curdt,'format','DDD'));
        stryr = char(datetime(curdt,'format','yy'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if Rinex_version == "RIENX3"
            url1 = strcat('https://gage-data.earthscope.org/archive/gnss/rinex3/obs/',stryrl,'/',strday,'/');
            url2 = strcat( upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_15S_MO.rnx.gz');
        elseif Rinex_version == "RINEX2"
            url1 = strcat('https://gage-data.earthscope.org/archive/gnss/rinex/obs/',stryrl,'/',strday,'/');
            url2 = strcat( lower(station_name),strday,'0.',stryr,'o.Z');
        end
        fileurl = strcat(url1,url2);

        if exist(url2(1:end-2), "file")
            continue
        end

        curlCommand = sprintf('curl -H "Authorization: Bearer %s" -o %s %s', api_key, url2, fileurl);
        system(curlCommand);
        command = sprintf('"7z.exe" x "%s" -o"%s"', url2, pwd);
        system(command);
        delete(url2)
    end
    delete(p)
else
    for tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'convertfrom','datenum');

        strday = char(datetime(curdt,'format','DDD'));
        stryr = char(datetime(curdt,'format','yy'));
        stryrl = char(datetime(curdt,'format','yyyy'));

        if Rinex_version == "RIENX3"
            url1 = strcat('https://gage-data.earthscope.org/archive/gnss/rinex3/obs/',stryrl,'/',strday,'/');
            url2 = strcat( upper(station_name),'00',ISO_short,'_R_',stryrl,strday,'0000_01D_15S_MO.rnx.gz');
        elseif Rinex_version == "RINEX2"
            url1 = strcat('https://gage-data.earthscope.org/archive/gnss/rinex/obs/',stryrl,'/',strday,'/');
            url2 = strcat( lower(station_name),strday,'0.',stryr,'o.Z');
        end
        fileurl = strcat(url1,url2);

        if exist(url2(1:end-2), "file")
            continue
        end

        curlCommand = sprintf('curl -H "Authorization: Bearer %s" -o %s %s', api_key, url2, fileurl);
        system(curlCommand);
        command = sprintf('"7z.exe" x "%s" -o"%s"', url2, pwd);
        system(command);
        delete(url2)
    end
end
