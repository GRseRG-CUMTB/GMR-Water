function [valid, RH_info] = snr2RH_info(elv, snr, azi, time, wave_length, tdatenum, ...
    sta_asl, tide_range, ...
    cur_sys, cur_band, cur_sat, PNR)

varNames = {'Time','System','BAND','PRN','ROC','MIN_elv','MAX_elv','MEAN_AZI','RH','trop_c'};
varTypes = {'datetime','string','string','double','double','double','double','double','double','double'};
RH_info = table('Size',[0,length(varNames)],'VariableTypes',varTypes,'VariableNames',varNames);

load([num2str(tdatenum), 'TropParameters.mat'])

sinelv = sind(elv);
% inverse
if numel(sinelv) < 5
    valid = 0;
    RH_info = [];
    return
end

[refl_h, id, psd, pks] = snr2RH_lsp(sinelv, snr, wave_length, hell, hgtlim);
if isnan(pks)
    valid = 0;
    RH_info = [];
    return
end

% Tropospheric correction
pre_h = refl_h(id);
hsfc = hell - pre_h;
if hsfc > hgtlim(1) && hsfc < hgtlim(2)
    psfc = interp1(hgtlim,plim,hsfc,'linear');
    tsfc = interp1(hgtlim,tlim,hsfc,'linear');
    tmsfc = interp1(hgtlim,tmlim,hsfc,'linear');
    esfc = interp1(hgtlim,elim,hsfc,'linear');

    % dele = (1/60) * 510 * psfc / ((9/5*tsfc+492) * 1010.16) .*cotd(elv+7.31./(elv+4.4));
    % sinelv = sind(elv + dele);
    % elv = elv+dele;

    theta = elv;
    thetarefr = [];
    for jj = 1:numel(theta)
        tau = trop_delay_tp(curjd,lla(1),hell,hsfc,theta(jj),pant,tmant,eant,ah,aw,lambda,psfc,tmsfc,esfc);
        thetarefr(jj) = asind( sind(theta(jj)) + 0.5*tau/pre_h );
    end
    sinelv = sind(thetarefr).';

    [refl_h, id, psd, pks] = snr2RH_lsp(sinelv, snr, wave_length, hell, hgtlim);
    if isnan(pks)
        valid = 0;
        RH_info = [];
        return
    end

end
cur_rh = refl_h(id);  % Final rh
trop_c = cur_rh - pre_h; % Tropospheric correction
valid = 1;
if cur_rh > sta_asl-tide_range(1) || cur_rh < sta_asl-tide_range(2) || max(psd)<PNR*mean(psd)
    valid = 0;
end
if numel(pks) > 1
    if pks(end)/pks(end-1) < 1.5
        valid = 0;
    end
end

if valid == 1
    Time = datetime(tdatenum + mean(time)/86400, 'ConvertFrom', 'datenum');       % datenum
    System = string(cur_sys);
    BAND = string(cur_band);
    PRN = cur_sat;                               % Sat prn
    ROC = tand(mean(elv)) / (( (pi/180) * (elv(end)-elv(1)) )...
        /(time(end)-time(1)));                   % tan(th)/dth/dt :rate of change
    MIN_elv = min(elv);                          % THETA MIN
    MAX_elv = max(elv);                          % THETA MAX
    MEAN_AZI = mean(azi,'omitnan');              % MEAN AZI
    RH = cur_rh;                                 % slvl
    RH_info = table(Time,System,BAND,PRN,ROC,MIN_elv,MAX_elv,MEAN_AZI,RH,trop_c);
end
end