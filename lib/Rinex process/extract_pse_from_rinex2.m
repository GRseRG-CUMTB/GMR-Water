function [snr_data] = extract_pse_from_rinex2(obsstr, sp3str, elv_lims, ...
    azi_lims, staxyz, plat, plon,~)

s1data=NaN(86401,92);
s2data=NaN(86401,92);
s5data=NaN(86401,92);
s6data=NaN(86401,92);
s7data=NaN(86401,92);
s8data=NaN(86401,92);
satmatr={'G01';'G02';'G03';'G04';'G05';'G06';'G07';'G08';'G09';...
    'G10';'G11';'G12';'G13';'G14';'G15';'G16';'G17';'G18';'G19';...
    'G20';'G21';'G22';'G23';'G24';'G25';'G26';'G27';'G28';'G29';...
    'G30';'G31';'G32';...
    'R01';'R02';'R03';'R04';'R05';'R06';'R07';'R08';'R09';...
    'R10';'R11';'R12';'R13';'R14';'R15';'R16';'R17';'R18';'R19';...
    'R20';'R21';'R22';'R23';'R24';...
    'E01';'E02';'E03';'E04';'E05';'E06';'E07';'E08';'E09';...
    'E10';'E11';'E12';'E13';'E14';'E15';'E16';'E17';'E18';'E19';...
    'E20';'E21';'E22';'E23';'E24';'E25';'E26';'E27';'E28';'E29';...
    'E30';'E31';'E32';'E33';'E34';'E35';'E36'}; 

fid = fopen(obsstr);

tline=fgets(fid);
endnow=0;
while endnow==0 % find end of header
    tline = fgets(fid);
    obsq = strfind(tline,'# / TYPES OF OBSERV');
    if size(obsq,1)>0
        numobs = str2double(tline(1:6));
        if numobs<6
            obsl = 1;
        elseif numobs>5 && numobs<11
            obsl = 2;
        elseif numobs>10 && numobs<16
            obsl = 3;
        elseif numobs>15 && numobs<21
            obsl = 4;
        elseif numobs>20 && numobs<26
            obsl = 5;
        end
        clear s1pos s2pos
        for ii=1:numobs
            if ii==10 || ii==19
                tline=fgets(fid);
            end

            if ii < 10
                obstype(ii,:) = tline(ii*6+5:ii*6+6);
            elseif ii>9 && ii<19
                obstype(ii,:) = tline((ii-9)*6+5:(ii-9)*6+6);
            elseif ii>18
                obstype(ii,:) = tline((ii-18)*6+5:(ii-18)*6+6);
            end
            if strcmp(obstype(ii,:),'C1') == 1
                s1pos = ii;
            elseif strcmp(obstype(ii,:),'C2') == 1
                s2pos = ii;
            elseif strcmp(obstype(ii,:),'C5') == 1
                s5pos = ii;
            elseif strcmp(obstype(ii,:),'C6') == 1
                s6pos = ii;
            elseif strcmp(obstype(ii,:),'C7') == 1
                s7pos = ii;
            elseif strcmp(obstype(ii,:),'C8') == 1
                s8pos = ii;
            end
        end
    end
    endq = strfind(tline,'END OF HEADER');%头文件结束
    if size(endq,1) > 0
        endnow = 1;
        tline=fgets(fid);
    end
end

% NOW SORTING OUT THE OBSERVATIONS

cursecs=0;
numsats = 0;

while ~feof(fid)
    i=0;
    % this is to deal with spliced files 
    if numel(tline) >= 31
        if strcmp(tline(1:31),'                            4  ')==1 || strcmp(tline(1:32),'                            4 64')
            tmpskip = str2double(tline(32)) + 1;
            while i<tmpskip
                tline=fgets(fid);
                i=i+1;
            end
            if numel(tline)>=67
                while strcmp(tline(61:67),'COMMENT')
                    tline=fgets(fid);
                    i=i+1;
                end
            end
            continue
        end
    end

    cursecsold = cursecs;
    cursecs = str2double(tline(11:12)) * 60 * 60 + str2double(tline(14:15)) * 60 + str2double(tline(16:26));% 参考时刻
    numsatsold = numsats;
    numsats=str2double(tline(31:32));
    if isnan(numsats)==1 || isnan(cursecs)==1 || (cursecs==0 && cursecsold~=0)
        issue=1;
        disp('issue')
        return
    end

    if numel(tline)<34
        while i<numsats + 1
            tline = fgets(fid);
            i = i+1;
        end
        continue
    end
    if cursecs > 86400 %|| cursecs-cursecsold>1
        break
    end

    % here just saving the order of the satellites
    numsatst=min([12 numsats]);% 卫星数量
    satsord=tline(33:32+numsatst*3);% G04G09G01G20G11G16G03G31G32G23G25
    mult12=12;
    ab=1;
    while mult12<numsats
        ab = ab+1;
        mult12 = 12*ab;
        numsatst=min([mult12 numsats])-12*(ab-1);
        tline=fgets(fid);
        satsord=[satsord,tline(33:32+(numsatst)*3)];
    end
    tline=fgets(fid);

    % now collect the data
    for ss=1:numsats
        satname = satsord((ss-1)*3+1:(ss-1)*3+3);% 卫星编号 eg：G04
        satis = strcmp(satname,satmatr(:,1))==1;% satis矩阵 第i行为1则卫星是第i个
        satind = sum(satis.*[1:size(satis,1)].');% 卫星编号 表里面第几个
        i=0;

        if sum(satis)==0% 没找到卫星
            while i~=obsl
                tline=fgets(fid);
                i=i+1;
            end
            continue
        end

        % getting s1
        mult5 = 5;
        while s1pos > mult5
            i = i + 1;
            mult5 = 5*(i+1);
            tline = fgets(fid);
        end
        if numel(tline) >= (s1pos - i*5 - 1)*16 + 14
            s1data(cursecs+1,satind) = str2double(tline((s1pos- i*5 -1)*16 + 1:(s1pos-i*5-1)*16+14));
        end
        % getting s2
        if exist('s2pos', 'var')
        while s2pos > mult5
            i=i+1;
            mult5=5*(i+1);
            tline=fgets(fid);
        end
        if numel(tline) >= (s2pos - i*5 - 1)*16 + 14
            s2data(cursecs+1,satind) = str2double(tline((s2pos-i*5-1)*16+1:(s2pos-i*5-1)*16+14));
        end
        end
         % getting s5
         if exist('s5pos', 'var')
        while s5pos > mult5
            i=i+1;
            mult5=5*(i+1);
            tline=fgets(fid);
        end
         
        if numel(tline) >= (s5pos - i*5 - 1)*16 + 14
            s5data(cursecs+1,satind) = str2double(tline((s5pos-i*5-1)*16+1:(s5pos-i*5-1)*16+14));
        end
         end
        % getting s6
        if exist('s6pos', 'var')
        while s6pos > mult5
            i=i+1;
            mult5=5*(i+1);
            tline=fgets(fid);
        end
        
        if numel(tline) >= (s6pos - i*5 - 1)*16 + 14
            s6data(cursecs+1,satind) = str2double(tline((s6pos-i*5-1)*16+1:(s6pos-i*5-1)*16+14));
        end
        end
        % getting s7
        if exist('s7pos', 'var')
        while s7pos > mult5
            i=i+1;
            mult5=5*(i+1);
            tline=fgets(fid);
        end
        if numel(tline) >= (s7pos - i*5 - 1)*16 + 14
            s7data(cursecs+1,satind) = str2double(tline((s7pos-i*5-1)*16+1:(s7pos-i*5-1)*16+14));
        end
        end
          % getting s8
          if exist('s8pos', 'var')
        while s8pos > mult5
            i=i+1;
            mult5=5*(i+1);
            tline=fgets(fid);
        end
        if numel(tline) >= (s8pos - i*5 - 1)*16 + 14
            s8data(cursecs+1,satind) = str2double(tline((s8pos-i*5-1)*16+1:(s8pos-i*5-1)*16+14));
        end
          end
        while i~=obsl
            tline=fgets(fid);
            i=i+1;
        end
    end
end


[txyz,xyz] = readsp3file(sp3str);
txyzsecs=txyz-txyz(1);
txyzsecs=txyzsecs.*86400;

snr_data=[];

for satind=1:92

    s1datat=squeeze(s1data(:,satind));
    s2datat=squeeze(s2data(:,satind));
    s5datat=squeeze(s5data(:,satind));
    s6datat=squeeze(s6data(:,satind));
    s7datat=squeeze(s7data(:,satind));
    s8datat=squeeze(s8data(:,satind));
    secs   = find(~isnan(s1datat(:)) | ~isnan(s2datat(:))| ~isnan(s5datat(:))| ...
        ~isnan(s6datat(:))| ~isnan(s7datat(:))|~isnan(s8datat(:)));% 参考时刻
    s1datat=s1datat(secs);
    s2datat=s2datat(secs);
    s5datat=s5datat(secs);
    s6datat=s6datat(secs);
    s7datat=s7datat(secs);
    s8datat=s8datat(secs);



    clear xyzt
    if sum(~isnan( squeeze(xyz(satind,:,1)) ))>1
        xyzt(:,1)=spline(txyzsecs,squeeze(xyz(satind,:,1)),secs-1);
        xyzt(:,2)=spline(txyzsecs,squeeze(xyz(satind,:,2)),secs-1);
        xyzt(:,3)=spline(txyzsecs,squeeze(xyz(satind,:,3)),secs-1);
    else
        continue
    end

    ind=0;
    snrdatat=[];
    for tt=1:numel(secs)
        [azi,elv] = gnss2azelv(staxyz,xyzt(tt,:),plat,plon); % 大地方位角
        if (azi>azi_lims(1) && azi<azi_lims(2)) && (elv>elv_lims(1) && elv<elv_lims(2)) % 在限制范围内
            ind = ind+1;
            snrdatat(ind,1) = satind;
            snrdatat(ind,2) = azi;
            snrdatat(ind,3) = elv;
            snrdatat(ind,4) = secs(tt)-1;
            snrdatat(ind,5) = s1datat(tt);
            snrdatat(ind,6) = s2datat(tt);
            snrdatat(ind,7) = s5datat(tt);
            snrdatat(ind,8) = s6datat(tt);
            snrdatat(ind,9) = s7datat(tt);
            snrdatat(ind,10) = s8datat(tt);
            
        end
    end
    snr_data = [snr_data;snrdatat];
end
snr_data(:, [2, 4]) = snr_data(:, [4, 2]);
snr_data(:, [3, 4]) = snr_data(:, [4, 3]);
if size(snr_data,1)>0
    snr_data=sortrows(snr_data,2);
else
    disp('sorry no data mate')
end
%%
sat_id = snr_data(:, 1);
GPS_ind = sat_id >= 1 & sat_id <= 32;
snr_struct.GPS = snr_data(GPS_ind,:);
GLONASS_ind = sat_id >= 33 & sat_id <= 56;
snr_struct.GLONASS = snr_data(GLONASS_ind,:);
snr_struct.GLONASS(:,1) = snr_struct.GLONASS(:,1)-32;
GALILEO_ind = sat_id >= 57 & sat_id <= 92;
snr_struct.GALILEO = snr_data(GALILEO_ind,:);
snr_struct.GALILEO(:,1) = snr_struct.GALILEO(:,1)-56;

% 将 snr_struct 赋值回 snr_data，形成一个包含分类信息的结构体
snr_data = snr_struct;

% 为 GPS 系统添加列头信息，并转换为表格
if ~isempty(snr_data.GPS)
    GPS_data_prn_str = arrayfun(@(x) sprintf('G%02d', x), snr_data.GPS(:,1), 'UniformOutput', false);
    snr_data.GPS = array2table(snr_data.GPS, ...
        'VariableNames', {'GPS_data_prn_num', 'GPS_data_time', 'GPS_azi', ...
                          'GPS_elv', 'S1', 'S2', 'S5', 'S6', 'S7', 'S8'});
    snr_data.GPS.GPS_data_prn_str = GPS_data_prn_str;
end
if ~isempty(snr_data.GLONASS)
    GLONASS_data_prn_str = arrayfun(@(x) sprintf('R%02d', x), snr_data.GLONASS(:,1), 'UniformOutput', false);
    snr_data.GLONASS = array2table(snr_data.GLONASS, ...
        'VariableNames', {'GLONASS_data_prn_num', 'GLONASS_data_time', 'GLONASS_azi', ...
                          'GLONASS_elv', 'S1', 'S2', 'S5', 'S6', 'S7', 'S8'});
    snr_data.GLONASS.GLONASS_data_prn_str = GLONASS_data_prn_str;
end

% 同理为 GALILEO 数据添加列头信息
if ~isempty(snr_data.GALILEO)
    GALILEO_data_prn_str = arrayfun(@(x) sprintf('E%02d', x), snr_data.GALILEO(:,1), 'UniformOutput', false);
    snr_data.GALILEO = array2table(snr_data.GALILEO, ...
        'VariableNames', {'GALILEO_data_prn_num', 'GALILEO_data_time', 'GALILEO_azi', ...
                          'GALILEO_elv', 'S1', 'S2', 'S5', 'S6', 'S7', 'S8'});
    snr_data.GALILEO.GALILEO_data_prn_str = GALILEO_data_prn_str;
end


% 删除GPS中的NaN列
if ~isempty(snr_data.GPS)
    nan_columns = all(ismissing(snr_data.GPS), 1);  % 检查每列是否全为 NaN
    snr_data.GPS(:, nan_columns) = [];  % 删除全是NaN的列
end

% 删除GLONASS中的NaN列
if ~isempty(snr_data.GLONASS)
    nan_columns = all(ismissing(snr_data.GLONASS), 1);  % 检查每列是否全为 NaN
    snr_data.GLONASS(:, nan_columns) = [];  % 删除全是NaN的列
end

% 删除Galileo中的NaN列
if ~isempty(snr_data.GALILEO)
    nan_columns = all(ismissing(snr_data.GALILEO), 1);  % 检查每列是否全为 NaN
    snr_data.GALILEO(:, nan_columns) = [];  % 删除全是NaN的列
end


end