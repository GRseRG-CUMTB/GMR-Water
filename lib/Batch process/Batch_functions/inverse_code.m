varNames = {'Time','System','BAND','PRN','ROC','MIN_elv','MAX_elv','MEAN_AZI','RH','trop_c'};
varTypes = {'datetime','string','string','double','double','double','double','double','double','double'};
RH_info = table('Size',[0,length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);
rid   = 0;

load('MethodsSettings.mat','PNR','WinLSP')

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
                                    if max(time_win) - min(time_win) < 600
                                        continue
                                    end
                                    [valid, RH_info_win] = snr2RH_info(elv_win, snr_win, azi_win, time_win, wave_length, tdatenum, ...
                                        sta_asl, tide_range, ...
                                        cur_sys, cur_band, cur_sat, PNR);

                                    if valid
                                        rid = rid + 1; % row id
                                        RH_info(rid,:) = RH_info_win;
                                    end
                                end
                            else % No winlsp
                                if max(time) - min(time) < 60*30
                                    continue
                                end
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
                            if max(time_win) - min(time_win) < 600
                                continue
                            end
                            [valid, RH_info_win] = mp2RH_info(elv_win, M_win, azi_win, time_win, a, b, tdatenum, ...
                                sta_asl, tide_range, ...
                                cur_sys, cur_band, cur_sat, Meth_id, PNR);

                            if valid
                                rid = rid + 1; % row id
                                RH_info(rid,:) = RH_info_win;
                            end
                        end
                    else
                        if max(time) - min(time) < 60*30
                            continue
                        end
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
                                if max(time_win) - min(time_win) < 600
                                    continue
                                end
                                [valid, RH_info_win] = mp2RH_info(elv_win, M_win, azi_win, time_win, a, b, tdatenum, ...
                                    sta_asl, tide_range, ...
                                    cur_sys, cur_band, cur_sat, Meth_id, PNR);

                                if valid
                                    rid = rid + 1; % row id
                                    RH_info(rid,:) = RH_info_win;
                                end
                            end
                        else
                            if max(time) - min(time) < 60*30
                                continue
                            end
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