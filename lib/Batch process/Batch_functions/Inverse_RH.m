%% Data path
snr_savepath         = [settings.Out_path,'/SNR_file'];
carrier_savepath     = [settings.Out_path,'/Carrier_file'];
pseudorange_savepath = [settings.Out_path,'/Pseudorange_file'];

load('MethodsSettings.mat')
%% Inversion is carried out by five methods
if string(settings.par) == "None"
    for tdatenum = start_date: end_date
        RH_file = [settings.Out_path,'/RH_file/',settings.station_name,num2str(tdatenum),'RH_info.mat'];
        if ~exist([settings.Out_path,'/RH_file'], "dir")
            mkdir([settings.Out_path,'/RH_file'])
        end

        % start
        disp([char(datetime(tdatenum,'ConvertFrom','datenum'))])
        inverse_code
    end
    % inverse modeling
    if settings.methods(2)
        tlen = 18/24;
        kspac = 3/24;
        load([num2str(tdatenum), 'TropParameters.mat'],"hell","hgtlim")

        temp_outdir = [settings.Out_path,'\temp'];
        if exist(temp_outdir, "dir")==0 % create output dir
            mkdir(temp_outdir);
        end
        for tdatenum  = start_date+tlen/3 : tlen/3 : end_date+1-tlen/3
            temp_file = [temp_outdir,'/',num2str(round(tdatenum,10,'significant')),'.mat'];
            % if exist(temp_file,"file")
            %     continue
            % end
            % load snr data
            st = tdatenum - tlen/3;
            et = tdatenum + 2*tlen/3;
            snrfilet = [];
            for t = floor(st):floor(et)
                if ~exist([settings.Out_path,'\SNR_file\',settings.station_name,num2str(t),'.mat'],'file')
                    continue
                end
                snr = load([settings.Out_path,'\SNR_file\',settings.station_name,num2str(t),'.mat']);
                snr = snr.snr_data;
                GNSS_name = fieldnames(snr);
                snr_filet = [];
                snrdata = [];
                for sys_id = 1:numel(fieldnames(snr))
                    system = snr.(GNSS_name{sys_id});
                    if string(GNSS_name{sys_id}) == "GPS"
                        add = 0;
                    elseif string(GNSS_name{sys_id}) == "GLONASS"
                        add = 32;
                    elseif string(GNSS_name{sys_id}) == "GALILEO"
                        add = 32+24;
                    elseif string(GNSS_name{sys_id}) == "BDS"
                        add = 32+24+36;
                    end
                    band_num = size(system.Properties.VariableNames);

                    for l = 1 : band_num(2)-4
                        band = system.Properties.VariableNames(l+4);
                        bandchar = char(band);
                        if numel(bandchar) == 3
                            if bandchar(2) ~= '1' || bandchar(3) == 'W'
                                continue
                            end
                        else
                            if bandchar(2) ~= '1'
                                continue
                            end
                        end

                        [hang,~] = size(system);
                        nan_all = nan(hang ,2);
                        snrfile_raw = [table2array(system(:,1))+add, table2array(system(:,4)),...
                            table2array(system(:,3)),table2array(system(:,2)),...
                            nan_all, table2array(system(:,band))];
                        [~,lie] = size(snrfile_raw);
                        if lie == 7
                            snrdata = [snrdata; snrfile_raw];
                        end
                    end
                end
                snrdata(:,9) = t + snrdata(:,4)./86400;
                snrdata(:,10)= 1;

                % now get rid of data outside window
                tmpout = snrdata(:,9)<st | snrdata(:,9)>=et;
                snrdata(tmpout,:) = [];
                snrfilet = [snrfilet; snrdata];
            end
            snrfile = sortrows(snrfilet,1);

            dt = settings.Rinex_dt;
            roughin = 0.01;
            station_info = load(settings.Station_info_file);
            ahgt = station_info.sta_asl;
            tdate = tdatenum-tlen/3;
            [hinit,xinit,sfacspre,sfacsjs,consts_out,roughout] = inverse(dt,snrfile,hell,hgtlim,ahgt, ...
                1,tdate,tlen,kspac,1,0,0,0,"Off","Off",roughin);

            % saving results
            save(temp_file, ...
                'sfacsjs','sfacspre','hinit','xinit','consts_out','roughout')
        end

        plotl = 1/(24*60);
        roughnessplot = 0;
        [t_rh, rh_invjs, rh_invpre, ~, ~] = invsnr_plot(cellstr({temp_outdir}),start_date, end_date, ...
            kspac,tlen,plotl,roughnessplot);

        % output Final file
        Time = datetime(t_rh,'ConvertFrom','datenum')';
        RH_Inverse = rh_invjs';
        RH_Spectral_bsp = rh_invpre';
        Final_info = table(Time,RH_Inverse,RH_Spectral_bsp);
        final_file_name = [settings.Out_path,'/Final_file/',settings.station_name,'_',...
            char(start_time),'_',char(end_time),'_SNR-Inverse.mat'];
        if ~exist([settings.Out_path,'/Final_file'],"dir")
            mkdir([settings.Out_path,'/Final_file'])
        end
        save(final_file_name, "Final_info")
    end
    % delete TropParameters file
    fileList = dir('*TropParameters.mat');
    for i = 1:length(fileList)
        fileName = fileList(i).name;
        delete(fileName);
    end


else % par
    par = parpool(str2double(settings.par));
    parfor tdatenum = start_date: end_date
        varNames = {'Time','System','BAND','PRN','ROC','MIN_elv','MAX_elv','MEAN_AZI','RH','trop_c'};
        varTypes = {'datetime','string','string','double','double','double','double','double','double','double'};
        RH_info = table('Size',[0,length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
        rid   = 0;

        ms = load('MethodsSettings.mat','PNR','WinLSP');
        PNR = ms.PNR;
        WinLSP = ms.WinLSP;

        genTropParameters(tdatenum,staxyz,sta_asl,tide_range);
        for Meth_id = 1:5
            % load Data
            if settings.methods(Meth_id)
                if Meth_id == 1     % inverse base on SNR
                    disp('    Spectral analysis method......')
                    Data     = load([snr_savepath, '\', settings.station_name, num2str(tdatenum),'.mat']);
                    All_data = Data.snr_data;
                elseif Meth_id == 2 % inverse modeling
                    continue
                elseif Meth_id == 3 % base on carrier
                    disp('    Multiple frequency carrier phase method......')
                    Data     = load([carrier_savepath, '\', settings.station_name, num2str(tdatenum),'.mat']);
                    All_data = Data.carrier_data;
                elseif Meth_id == 4 % base on psedorange
                    disp('    Multiple frequency pseudo range method......')
                    Data     = load([pseudorange_savepath, '\', settings.station_name, num2str(tdatenum),'.mat']);
                    All_data = Data.pseudorange_data;
                elseif Meth_id == 5
                    disp('    Single frequency carrier phase & pseudo range method......')
                    Data      = load([carrier_savepath, '\', settings.station_name, num2str(tdatenum),'.mat']);
                    All_data1 = Data.carrier_data;
                    Data      = load([pseudorange_savepath, '\', settings.station_name, num2str(tdatenum),'.mat']);
                    All_data2 = Data.pseudorange_data;
                    All_data  = mergeStructTables(All_data1, All_data2);
                end
            else
                continue
            end

            %% Start inverse using All_data
            system     = fieldnames(All_data);
            system_num = numel(system);

            for s = 1:system_num                                    % GNSS
                cur_sys = system{s};
                cur_data= All_data.(cur_sys);
                prn     = unique(cur_data{:,1});
                sat_num = numel(prn);
                for sat = 1:sat_num                                 % Satellite
                    cur_sat = prn(sat);
                    inverse_indx = cur_data{:,1}==cur_sat;
                    inverse_data = cur_data(inverse_indx,:);
                    time_a   = inverse_data{:,2};
                    headers  = cur_data.Properties.VariableNames;
                    bands    = headers(5:end);
                    band_num = numel(bands);

                    %% For SNR inverse
                    % spectral inverse
                    done = 0;
                    if (Meth_id == 1 || Meth_id == 2) && done == 0
                        done = 1;
                        for group_id = 1:band_num          % band
                            cur_band = bands{group_id};
                            if cur_band(1) ~= 'S'   % only for snr
                                continue
                            end
                            time_gap = diff(time_a);
                            gap_indx = find((time_gap>10*settings.Rinex_dt) == 1);
                            for g = 1:numel(gap_indx)+1
                                if numel(gap_indx) == 0
                                    indx = 1:size(inverse_data,1);
                                else
                                    if g == 1
                                        indx = 1:gap_indx(g);
                                    elseif g == numel(gap_indx)+1
                                        indx = (gap_indx(g-1)+1):size(inverse_data,1);
                                    else
                                        indx = (gap_indx(g-1)+1) : gap_indx(g);
                                    end
                                end
                                time_o= inverse_data{indx,2};
                                azi_o = inverse_data{indx,3};
                                snr_o = inverse_data{indx,cur_band};
                                elv_o = inverse_data{indx,4};

                                elv_one = all(diff(elv_o)<0) || all(diff(elv_o)>0);
                                if elv_one
                                    arc_num = 1;
                                else
                                    arc_num = 2;
                                    try
                                        gap_elv = find(elv_o == findpeaks(elv_o));
                                    catch
                                        try
                                            elv_o = -elv_o;
                                            gap_elv = find(elv_o == findpeaks(elv_o));
                                        catch
                                            continue
                                        end
                                    end
                                end
                                for arc_id = 1:arc_num
                                    if arc_num ~= 1
                                        if arc_id == 1
                                            time = time_o(1:gap_elv);
                                            azi = azi_o(1:gap_elv);
                                            snr = snr_o(1:gap_elv);
                                            elv = elv_o(1:gap_elv);
                                        else
                                            time = time_o(gap_elv+1,:);
                                            azi = azi_o(gap_elv+1,:);
                                            snr = snr_o(gap_elv+1,:);
                                            elv = elv_o(gap_elv+1,:);
                                        end
                                    else
                                        time = time_o;
                                        azi = azi_o;
                                        snr = snr_o;
                                        elv = elv_o;
                                    end

                                    % get wave length
                                    wave_length = get_wave_length(cur_sys,cur_band,cur_sat);
                                    if isnan(wave_length)
                                        continue
                                    end

                                    % check nan
                                    nan_indx = isnan(snr);
                                    snr(nan_indx) = [];
                                    elv(nan_indx) = [];
                                    azi(nan_indx) = [];
                                    time(nan_indx) = [];

                                    if WinLSP.Enable
                                        % winLSP
                                        for win_s = min(elv): WinLSP.gap: max(elv)-WinLSP.length
                                            win_indx = elv>win_s & elv<win_s+WinLSP.length;
                                            snr_win = snr(win_indx);
                                            elv_win = elv(win_indx);
                                            azi_win = azi(win_indx);
                                            time_win = time(win_indx);
                                            [valid, RH_info_win] = snr2RH_info(elv_win, snr_win, azi_win, time_win, wave_length, tdatenum, ...
                                                sta_asl, tide_range, ...
                                                cur_sys, cur_band, cur_sat, PNR);

                                            if valid
                                                rid = rid + 1; % row id
                                                RH_info(rid,:) = RH_info_win;
                                            end
                                        end
                                    else % No winlsp
                                        [valid, RH_info_arc] = snr2RH_info(elv, snr, azi, time, wave_length, tdatenum, ...
                                            sta_asl, tide_range, ...
                                            cur_sys, cur_band, cur_sat, PNR);

                                        if valid
                                            rid = rid + 1; % row id
                                            RH_info(rid,:) = RH_info_arc;
                                        end
                                    end

                                end
                            end
                        end
                    end

                    %% For carrier and pseudorange multi-frequence
                    if Meth_id == 3 || Meth_id == 4
                        time_gap = diff(time_a);
                        gap_indx = find((time_gap>10*settings.Rinex_dt) == 1);
                        for g = 1:numel(gap_indx)+1
                            if numel(gap_indx) == 0
                                indx = 1:size(inverse_data,1);
                            else
                                if g == 1
                                    indx = 1:gap_indx(g);
                                elseif g == numel(gap_indx)+1
                                    indx = (gap_indx(g-1)+1):size(inverse_data,1);
                                else
                                    indx = (gap_indx(g-1)+1) : gap_indx(g);
                                end
                            end
                            time_o = inverse_data{indx,2};
                            azi_o    = inverse_data{indx,3};
                            elv_o  = inverse_data{indx,4};

                            if string(cur_sys) == "GLONASS"
                                continue
                            end
                            [M,a,b,cur_band] = Get_combined_observations(Meth_id, cur_sys, inverse_data, indx, cur_sat);

                            % Start inversion based on combined observations
                            nan_indx = isnan(M);
                            info = [elv_o,M,time_o,azi_o];
                            info(nan_indx,:) = [];
                            if numel(info) == 0
                                continue
                            end
                            info = sortrows(info);
                            elv = info(:,1);
                            M = info(:,2);
                            time = info(:,3);
                            azi = info(:,4);

                            if WinLSP.Enable
                                % winLSP
                                for win_s = min(elv): WinLSP.gap: max(elv)-WinLSP.length
                                    win_indx = elv>win_s & elv<win_s+WinLSP.length;
                                    M_win = M(win_indx);
                                    elv_win = elv(win_indx);
                                    azi_win = azi(win_indx);
                                    time_win = time(win_indx);
                                    [valid, RH_info_win] = mp2RH_info(elv_win, M_win, azi_win, time_win, a, b, tdatenum, ...
                                        sta_asl, tide_range, ...
                                        cur_sys, cur_band, cur_sat, Meth_id, PNR);

                                    if valid
                                        rid = rid + 1; % row id
                                        RH_info(rid,:) = RH_info_win;
                                    end
                                end
                            else
                                [valid, RH_info_arc] = mp2RH_info(elv, M, azi, time, a, b,  tdatenum, ...
                                    sta_asl, tide_range, ...
                                    cur_sys, cur_band, cur_sat, Meth_id, PNR);
                                if valid
                                    rid = rid+1;
                                    RH_info(rid,:) = RH_info_arc;
                                end
                            end

                        end

                    end

                    %% For single frequence combination of carrier and pseudorange
                    if Meth_id == 5
                        groups = CP_combination(bands);
                        for group_id = 1:numel(groups)  % frequence band
                            group = groups{group_id};

                            time_gap = diff(time_a);
                            gap_indx = find((time_gap>10*settings.Rinex_dt) == 1);
                            for g = 1:numel(gap_indx)+1
                                if numel(gap_indx) == 0
                                    indx = 1:size(inverse_data,1);
                                else
                                    if g == 1
                                        indx = 1:gap_indx(g);
                                    elseif g == numel(gap_indx)+1
                                        indx = (gap_indx(g-1)+1):size(inverse_data,1);
                                    else
                                        indx = (gap_indx(g-1)+1) : gap_indx(g);
                                    end
                                end
                                time_o = inverse_data{indx,2};
                                azi_o    = inverse_data{indx,3};
                                elv_o  = inverse_data{indx,4};

                                [M,a,b,cur_band] = Get_combined_observations(Meth_id, cur_sys, inverse_data, indx, cur_sat, group);

                                % Start inversion based on combined observations
                                nan_indx = isnan(M);
                                info = [elv_o,M,time_o,azi_o];
                                info(nan_indx,:) = [];
                                if numel(info) == 0
                                    continue
                                end
                                info = sortrows(info);
                                elv = info(:,1);
                                M = info(:,2);
                                time = info(:,3);
                                azi = info(:,4);

                                if WinLSP.Enable
                                    % winLSP
                                    for win_s = min(elv): WinLSP.gap: max(elv)-WinLSP.length
                                        win_indx = elv>win_s & elv<win_s+WinLSP.length;
                                        M_win = M(win_indx);
                                        elv_win = elv(win_indx);
                                        azi_win = azi(win_indx);
                                        time_win = time(win_indx);
                                        [valid, RH_info_win] = mp2RH_info(elv_win, M_win, azi_win, time_win, a, b, tdatenum, ...
                                            sta_asl, tide_range, ...
                                            cur_sys, cur_band, cur_sat, Meth_id, PNR);

                                        if valid
                                            rid = rid + 1; % row id
                                            RH_info(rid,:) = RH_info_win;
                                        end
                                    end
                                else
                                    [valid, RH_info_arc] = mp2RH_info(elv, M, azi, time, a, b, tdatenum, ...
                                        sta_asl, tide_range, ...
                                        cur_sys, cur_band, cur_sat, Meth_id, PNR);
                                    if valid
                                        rid = rid+1;
                                        RH_info(rid,:) = RH_info_arc;
                                    end
                                end

                            end
                        end
                    end
                end
            end
        end
        % save the RH_file
        parsave(RH_file,RH_info,'RH_info')
    end
    delete(par)
end