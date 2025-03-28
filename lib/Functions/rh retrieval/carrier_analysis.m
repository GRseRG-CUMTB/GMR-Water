function [results] = carrier_analysis(app, file_name, gnss_system, c1, c2, c3, tdatenum)

global Operation_settings
%% get carrier pseudorange
try
    combination_type = string(app.combination_type.Value);
    band = char(c1);
    load([file_name,'.mat'])
    if exist("pseudorange_data","var")
        carrier_data = pseudorange_data;
    end
    results = [];
    if gnss_system == "GPS"
        data = carrier_data.GPS;
    elseif gnss_system == "GLONASS"
        data = carrier_data.GLONASS;
    elseif gnss_system == "GALILEO"
        data = carrier_data.GALILEO;
    elseif gnss_system == "BDS"
        data = carrier_data.BDS;
    end
    try
        L1 = data.(c1);
        L2 = data.(c2);
        L5 = data.(c3);
    catch
        L1 = data.(c1);
        L2 = data.(c2);
    end
catch % Carrier & Pseudorange combination inversion
    combination_type = "Carrier & Pseudorange combination inversion";
    file_name1 = strcat(file_name,'\','carrier_data\',Operation_settings.station_name,num2str(tdatenum),'.mat');
    load(file_name1)
    results = [];
    if gnss_system == "GPS"
        data = carrier_data.GPS;
    elseif gnss_system == "GLONASS"
        data = carrier_data.GLONASS;
    elseif gnss_system == "GALILEO"
        data = carrier_data.GALILEO;
    elseif gnss_system == "BDS"
        data = carrier_data.BDS;
    end
    L1 = data.(c1);
    file_name2 = strcat(file_name,'\','pseudorange_data\',Operation_settings.station_name,num2str(tdatenum),'.mat');
    load(file_name2)
    if gnss_system == "GPS"
        data = pseudorange_data.GPS;
    elseif gnss_system == "GLONASS"
        data = pseudorange_data.GLONASS;
    elseif gnss_system == "GALILEO"
        data = pseudorange_data.GALILEO;
    elseif gnss_system == "BDS"
        data = pseudorange_data.BDS;
    end
    L2 = data.(c2);
end

%% get combination value
if gnss_system ~= "GLONASS"
    try % Three-frequency combination
        lamda1 = get_wave_length(gnss_system, char(c1),[]);
        lamda2 = get_wave_length(gnss_system, char(c2),[]);
        lamda3 = get_wave_length(gnss_system, char(c3),[]);

        yita1 = lamda3^2 - lamda2^2;
        yita2 = lamda1^2 - lamda3^2;
        yita3 = lamda2^2 - lamda1^2;

        kama1 = yita1 * lamda1;
        kama2 = yita2 * lamda2;
        kama3 = yita3 * lamda3;
    catch % Dual frequency combination
        lamda1 = get_wave_length(gnss_system, char(c1));
        lamda2 = get_wave_length(gnss_system, char(c2));
    end
    band = char(c1);
    if  band(1) == 'L' % Carrier
        if combination_type == "Dual frequency combination"
            M = L1*lamda1 - L2*lamda2;
            if gnss_system == "GPS"
                a = 0.1217;
                b = 0.00134;
            elseif gnss_system == "GALILEO"
                a = 0.1252;
                b = 0.0161;
            elseif gnss_system == "BDS"
                a = 0.1237;
                b = 0.283;
            end
        elseif combination_type == "Three-frequency combination"
            M = kama1*L1 + kama2*L2 + kama3*L5;
            if gnss_system == "GPS"
                a = 0.1248;
                b = 0.114;
            elseif gnss_system == "GALILEO"
                a = 0.1257;
                b = -0.0548;
            elseif gnss_system == "BDS"
                a = 0.1207;
                b = -0.25;
            end
        elseif combination_type == "Carrier & Pseudorange combination inversion"
            M = L2 - L1*lamda1;
            if gnss_system == "GPS"
                if band(2) == '1'
                    a = 0.0951;
                    b = 0.0016;
                elseif band(2) == '2'
                    a = 0.1221;
                    b = 0.0026;
                end
            elseif gnss_system == "GALILEO"
                if band(2) == '1'
                    a = 0.0951;
                    b = 0.0016;
                elseif band(2) == '8'% E5
                    a = 0.1257;
                    b = 0.0037;
                end
            elseif gnss_system == "BDS"
                a = 0.0951;
                b = 0.0016;
            end
        end
    elseif band(1) == 'C' % Pseudorange
        if combination_type == "Dual frequency combination"
            M = L1 - L2;
            if gnss_system == "GPS"
                a = 0.1217;
                b = 0;
            elseif gnss_system == "GALILEO"
                a = 0.1252;
                b = 0.0161;
            elseif gnss_system == "BDS"
                a = 0.1237;
                b = 0.3233;
            end
        elseif combination_type == "Three-frequency combination"
            M = yita1*L1 + yita2*L2 + yita3*L5; % 伪距组合
            if gnss_system == "GPS"
                a = 0.1248;
                b = 0.08;
            elseif gnss_system == "GALILEO"
                a = 0.1257;
                b = -0.0548;
            elseif gnss_system == "BDS"
                a = 0.1207;
                b = -0.2413;
            end
        end
    end

    M = array2table(M,"VariableNames","M");

elseif gnss_system == "GLONASS"
    sat_num = unique(data(:,1));
    glok = [1 -4 5 6 1 -4 5 6 -2 -7 0 -1 -2 -7 0 -1 4 -3 3 2 4 -3 3 2 0 0 0];
    for i = 1:numel(sat_num)
        sat = sat_num(i);
        lamda1 = 299792458/((1602+0.5625*glok(sat))*1e6);
        lamda2 = 299792458/((1246+0.4375*glok(sat))*1e6);
        lamda4 = 299792458/1600.995e06;

        data_temp = data(data(:,1)==sat);
        L1 = data_temp.(c1);
        L2 = data_temp.(c2);
        L5 = data_temp.(c3);

        lamda1 = get_wave_length_glo(sat, char(c1));
        lamda2 = get_wave_length(sat, char(c2));
        lamda3 = get_wave_length(sat, char(c3));
    end
end
data(:,end+1) = M; % data : combination Value

%% start inverse

% trop
curdt = datetime(tdatenum,'convertfrom','datenum'); % 时间
curjd = juliandate(curdt);
curyr = datetime(curdt,'format','yyyy');
curyr = double(int16(convertTo(curyr,'yyyymmdd') / 10000));
curday = datetime(curdt,'format','DDD');
curday = day(curday,'dayofyear');
plat = Operation_settings.station_l(2);
plon = Operation_settings.station_l(1);

ahgt = app.antenna_height.Value;
ahgt_bounds = app.rf_range.Value;
lla = ecef2lla(Operation_settings.station_xyz);
hell = lla(3);
gpt3_grid = gpt3_5_fast_readGrid;
curjd2 = doy2jd(curyr,curday)-2400000.5;
hgtlim(1) = hell-ahgt-ahgt_bounds;
hgtlim(2) = hell-ahgt+ahgt_bounds;
dlat(1) = plat*pi/180.d0;
dlon(1) = plon*pi/180.d0;
[plim(1),tlim(1),~,~,~,~,~,~,~] = gpt3_5_fast (curjd2,dlat,dlon,hgtlim(1),0, gpt3_grid);
[plim(2),tlim(2),~,~,~,~,~,~,~] = gpt3_5_fast (curjd2,dlat,dlon,hgtlim(2),0, gpt3_grid);

data_all = table2array(data);
data_all = data_all(~isnan(data_all(:,end)),:);% get rid of nan
sat_num = unique(data_all(:,1));
for i = 1:numel(sat_num)
    sat = sat_num(i);
    data_one = data_all(data_all(:,1)==sat,:);
    dift = diff(data_one(:,2));
    dt = str2double(Operation_settings.dt);
    ind = dift > 3*dt;
    dif_point = find(ind); % arc

    for ts = 1:numel(dif_point)+1
        if ts == 1
            startt = 1;
        else
            startt = dif_point(ts-1)  + 1;
        end
        if ts == numel(dif_point)+1
            data_time = data_one(startt:end,:);
        else
            endt = dif_point(ts);
            data_time = data_one(startt:endt,:);
        end
        elv = data_time(:,4);
        diff_elv = diff(elv);
        inflection_points = find(diff(sign(diff_elv)) ~= 0) + 1;
        for fra = 1:numel(inflection_points)+1
            if fra == 1
                starts = 1;
            else
                starts = inflection_points(fra-1)  + 1;
            end
            if fra == numel(inflection_points)+1
                data_fra = data_time(starts:end,:);
            else
                ends = inflection_points(fra);
                data_fra = data_time(starts:ends,:);
            end
            elv = data_fra(:,4);
            if all(diff(elv) < 0) % 高度角要求递增排列
                data_fra = flip(data_fra);
            end

            if band(1) == 'C'
                data_time_l = data_fra;
                elv = data_time_l(:,4);
                azi = data_time_l(:,3);

                sinelv = sind(elv);
                t = mean(data_time_l(:,2));% time
                m = data_time_l(:,end); % 三频组合结果
                if all(isnan(m)) || numel(m) < 15
                    continue
                end

                if combination_type == "Dual frequency combination" % 多项式拟合剔除电离层误差
                    p = polyfit(sinelv, m, 5);
                    m_fit = polyval(p, sinelv);
                    m = m-m_fit;
                end
                maxf1 = numel(sinelv) / (2*(max(sinelv)-min(sinelv)));
                [psd,f] = plomb(m,sinelv,maxf1,20);

                [~,id] = max(psd(:)); % id 为波峰
                pks = findpeaks(psd);
                pks = sort(pks);
                fh = f(id) * a + b; % 反射高度

                % trop correction
                preh = fh;
                hsfc = hell - preh;
                if hsfc > hgtlim(1) && hsfc < hgtlim(2) % 在潮位范围内
                    psfc = interp1(hgtlim,plim,hsfc,'linear');
                    tsfc = interp1(hgtlim,tlim,hsfc,'linear'); % 插值当前潮位气压与温度
                    theta = elv;
                    dele  = (1/60) * 510 * psfc / ((9/5*tsfc+492) * 1010.16) .*cotd(theta+7.31./(theta+4.4)); % 高度角改正数
                    % 改正高度角后重新反演
                    sinelv   = sind(theta+dele);
                    thetarefr= theta+dele;
                    if combination_type == "Dual frequency combination"
                        p = polyfit(sinelv, m, 5);
                        m_fit = polyval(p, sinelv);
                        m = m-m_fit;
                    end
                    [psd,f] = plomb(m,sinelv,maxf1,20);
                    [~,id] = max(psd(:));
                    pks = findpeaks(psd);
                    pks = sort(pks);
                    fh = f(id) * a + b;
                else
                    thetarefr = elv;
                end

                if fh < app.antenna_height.Value - app.rf_range.Value || fh > app.antenna_height.Value + app.rf_range.Value || max(psd)<10*mean(pks(1:end-1))
                    fh = nan;
                end
                trop_c = preh - fh;

                % for results
                elvmin = min(thetarefr);
                elvmax = max(thetarefr);
                meanazi = mean(azi);
                roc = tand(mean(thetarefr))/(((pi/180)*(thetarefr(end)-thetarefr(1))) / (data_time_l(end,2)-data_time_l(1,2)));
                result = [t/86400 + tdatenum, sat, elvmin, elvmax, meanazi, fh, roc, trop_c];
                results = [results; result];

                % draw picture
                if string(app.ispic.Value) == "Yes"
                    drawnow
                    ax1 = app.psd;
                    plot(ax1,f, psd);
                    ax2 = app.cmps;
                    plot(ax2,sinelv,m)
                end

            elseif band(1) == 'L' % 涉及载波相位的组合
                m = data_fra(:,end);
                dif_m = diff(m); % cycle slip
                Q1 = quantile(dif_m, 0.25);
                Q3 = quantile(dif_m, 0.75);
                IQR = Q3 - Q1;

                % Find cycle slips
                sp = find(dif_m < Q1 - 6*IQR | dif_m > Q3 + 6*IQR);
                for l = 1:numel(sp)+1
                    if l == 1
                        startt = 1;
                    else
                        startt = sp(l-1)  + 1;
                    end
                    if l == numel(sp)+1
                        data_time_l = data_fra(startt:end,:);
                    else
                        endt = sp(l);
                        data_time_l = data_fra(startt:endt,:);
                    end

                    data_time_l(:,4) = sind(data_time_l(:,4));
                    data_time_l = sortrows(data_time_l,4);
                    sinelv = data_time_l(:,4);
                    azi = data_time_l(:,3);

                    t = mean(data_time_l(:,2));% time
                    m = data_time_l(:,end); % 三频组合结果
                    if all(isnan(m)) || numel(m) < 15
                        continue
                    end
                    if combination_type == "Dual frequency combination" ||combination_type == "Carrier & Pseudorange combination inversion"% 多项式拟合剔除电离层误差
                        p = polyfit(sinelv, m, 10);
                        m_fit = polyval(p, sinelv);
                        m = m-m_fit;

                    end
                    maxf1 = numel(sinelv) / (2*(max(sinelv)-min(sinelv)));
                    try
                        [psd,f] = plomb(m,sinelv,maxf1,20);
                    catch
                        continue
                    end
                    [~,id] = max(psd(:)); % id 为波峰
                    pks = findpeaks(psd);
                    pks = sort(pks);
                    fh = f(id) * a + b;

                    % trop correction
                    preh = fh;
                    hsfc = hell - preh;
                    if hsfc > hgtlim(1) && hsfc < hgtlim(2) % 在潮位范围内
                        psfc = interp1(hgtlim,plim,hsfc,'linear');
                        tsfc = interp1(hgtlim,tlim,hsfc,'linear'); % 插值当前潮位气压与温度
                        theta = asind(sinelv);
                        dele  = (1/60) * 510 * psfc / ((9/5*tsfc+492) * 1010.16) .*cotd(theta+7.31./(theta+4.4)); % 高度角改正数
                        % 改正高度角后重新反演
                        sinelv   = sind(theta+dele);
                        thetarefr= theta+dele;
                        if combination_type == "Dual frequency combination" ||combination_type == "Carrier & Pseudorange combination inversion"
                            p = polyfit(sinelv, m, 5);
                            m_fit = polyval(p, sinelv);
                            m = m-m_fit;
                        end
                        [psd,f] = plomb(m,sinelv,maxf1,20);
                        [~,id] = max(psd(:));
                        pks = findpeaks(psd);
                        pks = sort(pks);
                        fh = f(id) * a + b;
                    else
                        thetarefr = elv;
                    end

                    if fh < app.antenna_height.Value - app.rf_range.Value || fh > app.antenna_height.Value + app.rf_range.Value || max(psd)<10*mean(pks(1:end-1))
                        fh = nan;
                    end
                    trop_c = preh - fh;
                    % for results
                    elvmin = min(elv);
                    elvmax = max(elv);
                    meanazi = mean(azi);
                    roc = tand(mean(thetarefr))/(((pi/180)*(thetarefr(end)-thetarefr(1))) / (data_time_l(end,2)-data_time_l(1,2)));
                    result = [t/86400 + tdatenum, sat, elvmin, elvmax, meanazi, fh, roc, trop_c];
                    results = [results; result];

                    % draw picture
                    if string(app.ispic.Value) == "Yes"
                        drawnow
                        ax1 = app.psd;
                        plot(ax1,f, psd);
                        ax2 = app.cmps;
                        plot(ax2,sinelv,m)
                    end
                end
            end
        end
    end
end
end