function [carrier_azi, carrier_all , carrier_data] = rinex2carrier_2(obsstr, sp3str, d,all_days,type)
% Extract carrier information from RINEX3 files

global Operation_settings
elv_lims = Operation_settings.elv;
azi_lims = Operation_settings.azi;
azi_mask = Operation_settings.azimask;
plat     = Operation_settings.station_l(2);
plon     = Operation_settings.station_l(1);
staxyz   = Operation_settings.station_xyz;
pace = 1/all_days;
GNSS_num = 0;
data = rinexread(obsstr);
d.Message = [obsstr,' Extracted complete'];
[txyz,xyz] = readsp3file(sp3str);
txyzsecs=txyz-txyz(1);
txyzsecs=txyzsecs.*86400;
if ~isa(Operation_settings.dt,'double')
    dts = str2double(Operation_settings.dt);
end
secs = 0:dts:(86400-dts);
[satind,~,~] = size(xyz);
for i = 1:satind
    if isnan(squeeze(xyz(i,:,1)))
        continue
    end
    xyzt(:,1,i) = spline(txyzsecs,squeeze(xyz(i,:,1)),secs);
    xyzt(:,2,i) = spline(txyzsecs,squeeze(xyz(i,:,2)),secs);
    xyzt(:,3,i) = spline(txyzsecs,squeeze(xyz(i,:,3)),secs);
end

clear xyz obsvec

obsvec(:,1,:) = xyzt(:,1,:)-staxyz(1);
obsvec(:,2,:) = xyzt(:,2,:)-staxyz(2);
obsvec(:,3,:) = xyzt(:,3,:)-staxyz(3);

ll = [plat;plon];
trans_matrix = zeros(3, 3);
trans_matrix(1,1)=-sind(ll(2));
trans_matrix(2,1)=-sind(ll(1))*cosd(ll(2));
trans_matrix(3,1)=cosd(ll(1))*cosd(ll(2));
trans_matrix(1,2)=cosd(ll(2));
trans_matrix(2,2)=-sind(ll(1))*sind(ll(2));
trans_matrix(3,2)=cosd(ll(1))*sind(ll(2));
trans_matrix(1,3)=0;
trans_matrix(2,3)= cosd(ll(1));
trans_matrix(3,3)= sind(ll(1));

[time_points, coordinates, satellites] = size(obsvec);
for t = 1:time_points
    for s = 1:satellites
        xyz = squeeze(obsvec(t, :, s));

        rss = trans_matrix * xyz';
        azimuth = atan2(rss(1, :), rss(2, :))*180/pi;
        if azimuth<0
            azimuth = 360+azimuth;
        end
        azi_all(t,s) = azimuth;
        elev = asind(rss(3, :)/sqrt(sum((rss).^2)));
        elv_all(t,s) = elev;
    end
end
d.Message = [obsstr,' Extracted complete',  newline, sp3str... 
    'Extracted complete'  newline  'Start sifting through GPS data...'];

%
if type == "Carrier"
    id = 'L';
elseif type == "Pseudorange"
    id = 'C';
end
%% for GPS
if isfield(data,'GPS')
    GNSS_num = GNSS_num+1;
    GPS_data = data.GPS;
    error_num = table2array(GPS_data(:,'EpochFlag'));
    error_ind = error_num~=0;% error indx
    band = GPS_data.Properties.VariableNames;
    [~,hang] = size(band); % number of SNR
    ind = 1;
    bool = 0;
    for i = 4:hang
        var = char(band(i));
        [~,len] = size(var);
        if var(1) == id && len < 4 %SNR value
            GPS_data_SNR(:,ind) = table2array(GPS_data(:,var));
            list(ind,:) = var;
            ind = ind+1;
        end
    end

    GPS_data_prn_num = table2array(GPS_data(:,1));
    GPS_data_prn_str = arrayfun(@(x) sprintf('G%02d', x), GPS_data_prn_num, 'UniformOutput', false);
    GPS_data_time = GPS_data.Time;
    X = convertTo(GPS_data_time,'posixtime');
    GPS_data_time = X - X(1);
    
    
    for j = 1:numel(secs)
        time_indx = GPS_data_time==secs(j);
        satnum = GPS_data_prn_num(time_indx); % the prn number in this time
        for satindx = 1:numel(satnum)
            satindx_num = satnum(satindx);
            if error_ind(ind) ~= 0
                ind = ind+1;
            end

            i = 1;
            if satindx_num>32
                i = 0;
                GPS_azi(ind,1) = nan;
                GPS_elv(ind,1) = nan;
                ind = ind + 1;
                if ind > numel(GPS_data_time)
                    bool = 1;
                    break
                end
            end
            if (secs(j) == GPS_data_time(ind) && satindx_num == GPS_data_prn_num(ind)) ...
                    && i == 1
                GPS_azi(ind,1) = azi_all(j,satindx_num);
                GPS_elv(ind,1) = elv_all(j,satindx_num);
                ind = ind + 1;
                if ind > numel(GPS_data_time)
                    bool = 1;
                    break
                end
            end

        end
        if bool == 1
            break
        end
    end
    
    data_SNR = table(GPS_data_prn_num,GPS_data_time,GPS_azi,GPS_elv);
    [l,~] = size(list);
    for i = 5:l+4
        data_SNR(:,i) = table(GPS_data_SNR(:,i-4));
    end
    data_SNR(:,end+1) = table(GPS_data_prn_str);
    data_SNR.Properties.VariableNames = ['GPS_data_prn_num','GPS_data_time',...
        'GPS_azi','GPS_elv',string(list)','GPS_data_prn_str'];

    % azi elv select
    azi = table2array(data_SNR(:,"GPS_azi"));
    if isnan(azi_mask)
        aziok_ind = (azi>azi_lims(1) & azi<azi_lims(2));
    else
        aziok_ind = ((azi>azi_lims(1) & azi<azi_mask(1)) | ...
            (azi<azi_lims(2) & azi>azi_mask(2)));
    end
    GPS_SNR_azi = data_SNR(aziok_ind,:);
    elv = table2array(GPS_SNR_azi(:,"GPS_elv"));
    elvok_ind = elv>elv_lims(1) & elv<elv_lims(2);
    GPS_SNR = GPS_SNR_azi(elvok_ind,:);

    d.Message = 'GPS data filtering complete!';

    GPS_SNR(:,end) = [];
    GPS_all = data_SNR;
    clear data_SNR list

    carrier_data.GPS = GPS_SNR;
    carrier_all.GPS = GPS_all;
    carrier_azi.GPS = GPS_SNR_azi;
    clear GPS_SNR GPS_all
end
%% for GLONASS
if isfield(data,'GLONASS')
    GNSS_num = GNSS_num+1;
    GLONASS_data = data.GLONASS;
    error_num = table2array(GLONASS_data(:,'EpochFlag'));
    error_ind = error_num~=0;
    band = GLONASS_data.Properties.VariableNames;
    [~,hang] = size(band);
    ind = 1;
    for i = 4:hang
        var = char(band(i));
        [~,len] = size(var);
        if var(1) == id && len < 4
            GLONASS_data_SNR(:,ind) = table2array(GLONASS_data(:,var));
            list(ind,:) = var;
            ind = ind+1;
        end
    end
    GLONASS_data_prn_num = table2array(GLONASS_data(:,1));
    GLONASS_data_prn_str = arrayfun(@(x) sprintf('R%02d', x), GLONASS_data_prn_num, 'UniformOutput', false);
    GLONASS_data_time = GLONASS_data.Time;
    X = convertTo(GLONASS_data_time,'posixtime');
    GLONASS_data_time = X - X(1);
    ind = 1;
    bool = 0;
    d.Message = 'Start sifting through GLONASS data...';
    
    for j = 1:numel(secs)
        time_indx = GLONASS_data_time==secs(j);
        satnum = GLONASS_data_prn_num(time_indx);
        for satindx = 1:numel(satnum)
            satindx_num = satnum(satindx);

            if error_ind(ind) ~= 0
                ind = ind+1;
            end

            i = 1;
            if satindx_num>24
                i = 0;
                GLONASS_azi(ind,1) = nan;
                GLONASS_elv(ind,1) = nan;
                ind = ind + 1;
                if ind > numel(GLONASS_data_time)
                    bool = 1;
                    break
                end
            end
            if (secs(j) == GLONASS_data_time(ind) && ...
                    satindx_num == GLONASS_data_prn_num(ind)) && i == 1
                [azi,elv] = gnss2azelv(staxyz,xyzt(j,:,satindx_num+32),plat,plon);
                GLONASS_azi(ind,1) = azi;
                GLONASS_elv(ind,1) = elv;
                ind = ind + 1;
                if ind > numel(GLONASS_data_time)
                    bool = 1;
                    break
                end
            end

            if ind > numel(GLONASS_data_time)
                bool = 1;
                break
            end
        end
        if bool == 1
            break
        end
    end
    
    data_SNR = table(GLONASS_data_prn_num,GLONASS_data_time,GLONASS_azi,GLONASS_elv);
    [l,~] = size(list);
    for i = 5:l+4
        data_SNR(:,i) = table(GLONASS_data_SNR(:,i-4));
    end
    data_SNR(:,end+1) = table(GLONASS_data_prn_str);
    data_SNR.Properties.VariableNames = ['GLONASS_data_prn_num','GLONASS_data_time',...
        'GLONASS_azi','GLONASS_elv',string(list)',"GLONASS_data_prn_str"];

    % azi elv select
    azi = table2array(data_SNR(:,"GLONASS_azi"));
    if isnan(azi_mask)
        aziok_ind = (azi>azi_lims(1) & azi<azi_lims(2));
    else
        aziok_ind = ((azi>azi_lims(1) & azi<azi_mask(1)) | ...
            (azi<azi_lims(2) & azi>azi_mask(2)));
    end
    GLONASS_SNR_azi = data_SNR(aziok_ind,:);
    elv = table2array(GLONASS_SNR_azi(:,"GLONASS_elv"));
    elvok_ind = elv>elv_lims(1) & elv<elv_lims(2);
    GLONASS_SNR = GLONASS_SNR_azi(elvok_ind,:);


    GLONASS_SNR(:,end) = [];
    GLONASS_all = data_SNR;
    clear data_SNR list
    d.Message = 'GLONASS data filtering complete!';

    carrier_data.GLONASS = GLONASS_SNR;
    carrier_all.GLONASS = GLONASS_all;
    carrier_azi.GLONASS = GLONASS_SNR_azi;
    clear GLONASS_SNR GLONASS_all
end
%% for GALILEO
if isfield(data,'Galileo')
    GNSS_num = GNSS_num+1;
    GALILEO_data = data.Galileo;
    error_num = table2array(GALILEO_data(:,'EpochFlag'));
    error_ind = error_num~=0;
    band = GALILEO_data.Properties.VariableNames;
    [~,hang] = size(band);
    ind = 1;
    for i = 4:hang
        var = char(band(i));
        [~,len] = size(var);
        if var(1) == id && len < 4
            GALILEO_data_SNR(:,ind) = table2array(GALILEO_data(:,var));
            list(ind,:) = var;
            ind = ind+1;
        end
    end
    GALILEO_data_prn_num = table2array(GALILEO_data(:,1));
    GALILEO_data_prn_str = arrayfun(@(x) sprintf('E%02d', x), GALILEO_data_prn_num, 'UniformOutput', false);
    GALILEO_data_time = GALILEO_data.Time;
    X = convertTo(GALILEO_data_time,'posixtime');
    GALILEO_data_time = X - X(1);
    ind = 1;
    bool = 0;
    d.Message = 'Start sifting through GALILEO data...';
    
    for j = 1:numel(secs)
        time_indx = GALILEO_data_time==secs(j);
        satnum = GALILEO_data_prn_num(time_indx);
        for satindx = 1:numel(satnum)
            satindx_num = satnum(satindx);

            if error_ind(ind) ~= 0
                ind = ind+1;
            end

            i = 1;
            if satindx_num>36
                i = 0;
                GALILEO_azi(ind,1) = nan;
                GALILEO_elv(ind,1) = nan;
                ind = ind + 1;
                if ind > numel(GALILEO_data_time)
                    bool = 1;
                    break
                end
            end
            if (secs(j) == GALILEO_data_time(ind) && ...
                    satindx_num == GALILEO_data_prn_num(ind)) && i == 1
                [azi,elv] = gnss2azelv(staxyz,xyzt(j,:,satindx_num+32+24),plat,plon);
                GALILEO_azi(ind,1) = azi;
                GALILEO_elv(ind,1) = elv;
                ind = ind + 1;
                if ind > numel(GALILEO_data_time)
                    bool = 1;
                    break
                end
            end
        end
        if bool == 1
            break
        end
    end
    
    data_SNR = table(GALILEO_data_prn_num,GALILEO_data_time,GALILEO_azi,GALILEO_elv);

    [l,~] = size(list);
    for i = 5:l+4
        data_SNR(:,i) = table(GALILEO_data_SNR(:,i-4));
    end
    data_SNR(:,end+1) = table(GALILEO_data_prn_str);
    data_SNR.Properties.VariableNames = ['GALILEO_data_prn_num','GALILEO_data_time',...
        'GALILEO_azi','GALILEO_elv',string(list)','GALILEO_data_prn_str'];

    % azi elv select
    azi = table2array(data_SNR(:,"GALILEO_azi"));
    if isnan(azi_mask)
        aziok_ind = (azi>azi_lims(1) & azi<azi_lims(2));
    else
        aziok_ind = ((azi>azi_lims(1) & azi<azi_mask(1)) | (azi<azi_lims(2) & azi>azi_mask(2)));
    end
    GALILEO_SNR_azi = data_SNR(aziok_ind,:);
    elv = table2array(GALILEO_SNR_azi(:,"GALILEO_elv"));
    elvok_ind = elv>elv_lims(1) & elv<elv_lims(2);
    GALILEO_SNR = GALILEO_SNR_azi(elvok_ind,:);

    GALILEO_SNR(:,end) = [];
    GALILEO_all = data_SNR;
    clear data_SNR list

    d.Message = 'GALILEO data filtering complete!';

    carrier_data.GALILEO = GALILEO_SNR;
    carrier_all.GALILEO = GALILEO_all;
    carrier_azi.GALILEO = GALILEO_SNR_azi;
    clear GALILEO_SNR GALILEO_all
end
%% for BDS
if isfield(data,'BeiDou')
    GNSS_num = GNSS_num+1;
    BDS_data = data.BeiDou;
    error_num = table2array(BDS_data(:,'EpochFlag'));
    error_ind = error_num~=0;
    band = BDS_data.Properties.VariableNames;
    [~,hang] = size(band);
    ind = 1;
    for i = 4:hang
        var = char(band(i));
        [~,len] = size(var);
        if var(1) == id && len < 4
            BDS_data_SNR(:,ind) = table2array(BDS_data(:,var));
            list(ind,:) = var;
            ind = ind+1;
        end
    end
    BDS_data_prn_num = table2array(BDS_data(:,1));
    BDS_data_prn_str = arrayfun(@(x) sprintf('C%02d', x), BDS_data_prn_num, 'UniformOutput', false);
    BDS_data_time = BDS_data.Time;
    X = convertTo(BDS_data_time,'posixtime');
    BDS_data_time = X - X(1);
    ind = 1;
    bool = 0;
    d.Message = 'Start sifting through BDS data...';
    for j = 1:numel(secs)
        time_indx = BDS_data_time==secs(j);
        satnum = BDS_data_prn_num(time_indx);
        for satindx = 1:numel(satnum)
            satindx_num = satnum(satindx);

            if error_ind(ind) ~= 0
                ind = ind+1;
            end

            i = 1;
            if satindx_num>46
                i = 0;
                BDS_azi(ind,1) = nan;
                BDS_elv(ind,1) = nan;
                ind = ind + 1;
                if ind > numel(BDS_data_time)
                    bool = 1;
                    break
                end
            end
            if (secs(j) == BDS_data_time(ind) && satindx_num == BDS_data_prn_num(ind)) ...
                    && i == 1
                [azi,elv] = gnss2azelv(staxyz,xyzt(j,:,satindx_num+32+24+36),plat,plon);
                BDS_azi(ind,1) = azi;
                BDS_elv(ind,1) = elv;
                ind = ind + 1;
                
                if ind > numel(BDS_data_time)
                    bool = 1;
                    break
                end
            end
        end
        if bool == 1
            break
        end
    end
    data_SNR = table(BDS_data_prn_num,BDS_data_time,BDS_azi,BDS_elv);
    [l,~] = size(list);
    for i = 5:l+4
        data_SNR(:,i) = table(BDS_data_SNR(:,i-4));
    end
    data_SNR(:,end+1) = table(BDS_data_prn_str);
    data_SNR.Properties.VariableNames = ['BDS_data_prn_num','BDS_data_time',...
        'BDS_azi','BDS_elv',string(list)','BDS_data_prn_str'];

    % azi elv select
    azi = table2array(data_SNR(:,"BDS_azi"));
    if isnan(azi_mask)
        aziok_ind = (azi>azi_lims(1) & azi<azi_lims(2));
    else
        aziok_ind = ((azi>azi_lims(1) & azi<azi_mask(1)) | (azi<azi_lims(2) & azi>azi_mask(2)));
    end
    BDS_SNR_azi = data_SNR(aziok_ind,:);
    elv = table2array(BDS_SNR_azi(:,"BDS_elv"));
    elvok_ind = elv>elv_lims(1) & elv<elv_lims(2);
    BDS_SNR = BDS_SNR_azi(elvok_ind,:);


    d.Message = 'Saving……';
    BDS_SNR(:,end) = [];
    BDS_all = data_SNR;
    clear data_SNR list

    carrier_data.BDS = BDS_SNR;
    carrier_all.BDS  = BDS_all;
    carrier_azi.BDS  = BDS_SNR_azi;
    clear BDS_SNR BDS_all
end

d.Value = (GNSS_num/4)*pace ;
end