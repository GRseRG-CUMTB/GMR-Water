function [slvlr,lspy] = analyzesnr_fun(app,snr_data,tdatenum,tropd,decimate,tempsnr,templsp, ...
   axes_dsnr,axes_lsp,gnss_system,band)

clear slvlr lspy

ltdrun=0; % change if you just want to produce a set number of figures

curdt = datetime(tdatenum,'convertfrom','datenum');
curyr = datetime(curdt,'format','yyyy');
curyr = double(int16(convertTo(curyr,'yyyymmdd') / 10000));
curday = datetime(curdt,'format','DDD');
curday = day(curday,'dayofyear');


% directory that contains mpsim, lla2ecef, station_inputs
% there is also a matlab function lla2ecef that is probably better

maxf1fix=0; % if you want to set a max freq and not worry about nyquist lim

global Operation_settings
ahgt = app.asl.Value; 


plat = Operation_settings.station_l(2);
plon = Operation_settings.station_l(1);
staxyz = Operation_settings.station_xyz;

azi_low  = Operation_settings.azi(1); 
azi_high = Operation_settings.azi(2);                        
azi_mask = Operation_settings.azimask;       
if isnan(azi_mask)
    clear azi_mask
end
elv_low =  Operation_settings.elv(1);        % elevation angle interval (low limit)
elv_high = Operation_settings.elv(2);       % elevation angle interval (high limit)
dt = app.decimates.Value;
ahgt_bounds = app.RangemEditField.Value; % should be tidal range + more


if decimate~=0
    dt = decimate;
end

lla = ecef2lla(staxyz);
hell = lla(3);

cnt=0;
clear delete

% tropd
gpt3_grid = gpt3_5_fast_readGrid;
curjd2 = doy2jd(curyr,curday)-2400000.5;
hgtant = hell;
hgtlim(1) = hell-ahgt+ahgt_bounds;
hgtlim(2) = hell-ahgt-ahgt_bounds;
dlat(1) = plat*pi/180.d0;
dlon(1) = plon*pi/180.d0;               % ellipsoidal latitude/longitude in radians

it = 0;                                 % with time variation (annual and semiannual terms)
[pant,~,~,tmant,eant,ah,aw,lambda,~] = gpt3_5_fast (curjd2, dlat,dlon, hgtant,it, gpt3_grid); % 天线处气象参数
% ah:   hydrostatic mapping function coefficient at zero height (VMF1) (vector of length nstat)
% aw:   wet mapping function coefficient (VMF1) (vector of length nstat)
% la:   water vapor decrease factor (vector of length nstat)
[plim(1),tlim(1),~,tmlim(1),elim(1),~,~,~,~] = gpt3_5_fast (curjd2, dlat,dlon, hgtlim(1),it, gpt3_grid);
[plim(2),tlim(2),~,tmlim(2),elim(2),~,~,~,~] = gpt3_5_fast (curjd2, dlat,dlon, hgtlim(2),it, gpt3_grid);



% note SNR data is sat#, elev, azimuth, seconds, refl dist1, refl dist2, S1, S2
clear slvl

allsats = unique(snr_data(:,1));
slvlr=[];
lspy=[];
for aa = 1:size(allsats,1) %遍历所有卫星
    ijk=0;
    repgaps = 1;
    while ijk ~= repgaps

        ijk = ijk+1;

        doo = allsats(aa);                                  % 卫星号
        tmpid = snr_data(:,1)==doo;
        sat2 = snr_data(tmpid,:);                           % 把指定编号的卫星数据提取出来
        in = sat2(:,3)>azi_low & sat2(:,3)<azi_high;        % 判断是否在大地方位角范围
        sat2trr = sat2(in,:);
        in = sat2trr(:,2)<elv_high & sat2trr(:,2)>elv_low;
        sat2tr = sat2trr(in,:);                               % 筛选角度符合条件的观测
        sat2tr = sortrows(sat2tr,4);                          % 按照时间序列进行排序
        if exist('azi_mask') == 1
            out = sat2tr(:,3)>azi_mask(1) & sat2tr(:,3)<azi_mask(2);
            sat2tr(out) = [];
        end
        if decimate~=0
            modspl  =mod(sat2tr(:,4),decimate);             % 按照采样间隔取余
            delt=modspl(:)>0;
            sat2tr(delt,:)=[];
        end
        %%%%%%%
        times=sat2tr(:,4);
        if size(times,1)<1                                  %无符合时段数
            continue
        end
        % to sort satellites which have more than one valid overpass
        gaps = diff(times(:,1)) > dt*10;                    % 找到分割时间段
        repgaps = sum(gaps) + 1;
        gapids = 1:numel(gaps);
        gaps=gapids(gaps);                                  % 时间在gaps处分割
        if repgaps>1                                        % 时间段数大于1
            if ijk==1
                sat2tr(gaps(ijk)+1:end,:) = [];               % 分割时段
            elseif ijk>1
                sat2tr(1:gaps(ijk-1),:)=[];
                if repgaps>2 && ijk<repgaps
                    sat2tr(gaps(ijk)-gaps(ijk-1)+1:end,:)=[];
                end
            end
        end
        if size(sat2tr,1)<3                                 % 时段数太少
            continue
        end
        if sum(isnan(sat2tr(:,end)))>20
            continue
        end

        fwd=0;
        if sat2tr(2,2)-sat2tr(1,2)>0
            fwd=1;
        end
        for a = 3:size(sat2tr,1) % this is basically just deleting all data if it gets to a point where it changes directions
            if sat2tr(a,2)-sat2tr(a-1,2)>0
                tmp=1;
            else
                tmp=0;
            end
            if tmp~=fwd                                     % 非递增
                times(a:end)=[];
                sat2tr(a:end,:)=[];
                break
            end
        end
        if fwd==0
            sat2tr=flipud(sat2tr);                          % 非递增则翻转
        end

        if abs(sat2tr(end,4)-sat2tr(1,4)) < 300             % 时段太少
            continue
        end

        nol1=0;
        nol2=0;
        
        if string(app.window_choose.Value) == "On" 
            win_len = app.win_length.Value;
            win_gap = app.win_gap.Value;

            for win_begin = elv_low:win_gap:elv_high-win_len
                win_end = win_begin+win_len;
                SNR_windata = sat2tr(sat2tr(:,2)>win_begin & sat2tr(:,2)<win_end , :);
                if numel(SNR_windata) == 0
                    continue
                end
                [slvlr_win,lspy_win,cnt] = analyze(app,SNR_windata,ahgt,ahgt_bounds,band,gnss_system,hgtlim,plim,tlim,nol1,tropd,hell, ...
                   tempsnr,templsp,cnt,ltdrun,tdatenum,doo,aa,axes_dsnr,axes_lsp,pant,tmant,eant,ah,aw,lambda,tmlim,elim);
                if numel(slvlr_win) ~= 0
                    slvlr = [slvlr;slvlr_win(end,:)];
                    lspy = [lspy;lspy_win(end,:)];
                end
            end

        elseif string(app.window_choose.Value) == "Off"
            snr_data_in = sat2tr;
            [slvlr_off,lspy_off,cnt] = analyze(app,snr_data_in,ahgt,ahgt_bounds,band,gnss_system,hgtlim,plim,tlim,nol1,tropd,hell, ...
               tempsnr,templsp,cnt,ltdrun,tdatenum,doo,aa,axes_dsnr,axes_lsp,pant,tmant,eant,ah,aw,lambda,tmlim,elim);
            if numel(slvlr_off) ~= 0
                slvlr = [slvlr;slvlr_off(end,:)];
                lspy = [lspy;lspy_off(end,:)];
            end
        end
    end
end

if cnt == 0
    slvlr=[];
    lspy=[];
end

end