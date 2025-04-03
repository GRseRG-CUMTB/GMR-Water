function [slvlr,lspy,cnt] = analyze(app,SNRdata,ahgt,ahgt_bounds,band,gnss_system,hgtlim,plim,tlim ...
    ,nol1,tropd,hell ...
    ,tempsnr,templsp,cnt,ltdrun,tdatenum,doo,aa,axes_dsnr,axes_lsp,pant,tmant,eant,ah,aw,lambda,tmlim,elim)

global Operation_settings
plat = Operation_settings.station_l(2);
plon = Operation_settings.station_l(1);
elv_low  = Operation_settings.elv(1);    
elv_high = Operation_settings.elv(2);   
slvlr = [];
lspy = [];
sinelv = sind(SNRdata(:,2));

SNR = sqrt(10.^(SNRdata(:,7)./10));
deln = isnan(SNR(:,1)) == 1;
SNR(deln,:) = [];
sinelv(deln,:) = [];

Lcar = get_wave_length(gnss_system, band, aa);

% lack enough data
if numel(sinelv)<5
    return
end


%% The first retrieval
hgtlim = [hgtlim(2), hgtlim(1)];
[reflh1, id, psd, pks, dsnr, f] = snr2RH_lsp(sinelv, SNR, Lcar, hell, hgtlim);
if isnan(pks)
    return
end

%% Trop correction
if tropd == 1
    % trop delay
    preh = reflh1(id);
    hsfc  = hell-preh; 
    if hsfc < hgtlim(1) && hsfc > hgtlim(2) 
        psfc = interp1(hgtlim,plim,hsfc,'linear');
        tmsfc = interp1(hgtlim,tmlim,hsfc,'linear');
        esfc = interp1(hgtlim,elim,hsfc,'linear'); 

        theta = SNRdata(:,2);

        clear thetarefr
        curdt = datetime(tdatenum,'convertfrom','datenum');
        curjd = juliandate(curdt);
        for jj = 1:numel(theta)
            tau = trop_delay_tp(curjd,plat,hell,hsfc,theta(jj),pant,tmant,eant,ah,aw,lambda,psfc,tmsfc,esfc);
            thetarefr(jj) = asind( sind(theta(jj)) + 0.5*tau/preh );
        end

        sinelv = sind(thetarefr).';

        [reflh1, id, psd, pks, dsnr, f] = snr2RH_lsp(sinelv, SNR, Lcar, hell, hgtlim);
        if isnan(pks)
            return
        end
    else
        thetarefr = SNRdata(:,2);
    end

elseif tropd==2
    % refraction
    preh = reflh1(id);
    hsfc = hell-preh;
    if hsfc > hgtlim(2) && hsfc < hgtlim(1)
        psfc = interp1(hgtlim,plim,hsfc,'linear');
        tsfc = interp1(hgtlim,tlim,hsfc,'linear'); 

        theta=SNRdata(:,2);
        dele = (1/60) * 510 * psfc / ((9/5*tsfc+492) * 1010.16) .*cotd(theta+7.31./(theta+4.4)); 

        sinelv=sind(theta+dele);
        thetarefr = theta+dele;
        [reflh1, id, psd, pks, dsnr, f] = snr2RH_lsp(sinelv, SNR, Lcar, hell, hgtlim);
        if isnan(pks)
            return
        end
    else
        thetarefr=SNRdata(:,2);
    end
end
trop_cor = preh - reflh1(id);

% Validation
if reflh1(id) < ahgt-ahgt_bounds || reflh1(id) > ahgt+ahgt_bounds || max(psd)<10*mean(pks(1:end-1))
    nol1 = 1;
end

%% output fresnel & plot SNR
if string(app.fresnel_kml.Value) == "Yes" && nol1==0
    % currently for L1 signal, could change to L2, see function description
    fresout = [pwd,'\fresnel_kml\'];
    if ~exist(fresout, "dir")
        mkdir(fresout)
    end
    set(0,'DefaultFigureVisible', 'off');
    filename1 = googlefresnel(plat,plon,SNRdata(1,2),SNRdata(1,3),doo,fresout,reflh1(id),299792458/Lcar);
    filename2 = googlefresnel(plat,plon,SNRdata(end,2),SNRdata(end,3),doo,fresout,reflh1(id),299792458/Lcar);
    set(0,'DefaultFigureVisible', 'on');
end

if tempsnr==1 || templsp==1
    fsz = 11;      % Fontsize
    lw = 1.5;      % LineWidth
    msz = 5;       % MarkerSize
    set(0,'defaultLineLineWidth',lw);   % set the default line width to lw
    set(0,'defaultLineMarkerSize',msz); % set the default line marker size to msz
    close all
end

% SNR PLOT
if tempsnr==1 && nol1==0
    plot(axes_dsnr,asind(sinelv),dsnr,'b','linewidth',0.8);
    xlabel(axes_dsnr,'Elevation angle','interpreter','latex','fontsize',fsz)
    ylabel(axes_dsnr,'$\delta SNR$','interpreter','latex','fontsize',fsz)
    set(axes_dsnr,'ticklabelinterpreter','latex','fontsize',fsz-1)
    axis(axes_dsnr,[elv_low elv_high -50 50])
    drawnow

end
% PERIODOGRAM
if templsp==1 && nol1==0
    plot(axes_lsp,reflh1,psd,'r');
    xlabel(axes_lsp,'RH','interpreter','latex','fontsize',fsz)
    ylabel(axes_lsp,'Power','interpreter','latex','fontsize',fsz)
    set(axes_lsp,'ticklabelinterpreter','latex','fontsize',fsz-1)
    drawnow

end

cnt = cnt+1;
if ltdrun~=0
    if cnt == ltdrun
        return
    end
end

%% Save results
if nol1 == 0
    slvlr(cnt,1) = tdatenum + mean(SNRdata(:,4))/86400;       % datenum
    slvlr(cnt,2) = doo;                                       % prn
    if tropd ~= 0                                             % tan(th)/dth/dt
        slvlr(cnt,3)=tand(mean(thetarefr(:)))/(((pi/180)*(thetarefr(end)-thetarefr(1)))...
            /(SNRdata(end,4)-SNRdata(1,4)));
        clear thetarefr
    else
        slvlr(cnt,3)=tand(mean(SNRdata(:,2)))/(((pi/180)*(SNRdata(end,2)-SNRdata(1,2)))...
            /(SNRdata(end,4)-SNRdata(1,4)));
    end
    slvlr(cnt,4)=min(SNRdata(:,2));                          % THETA MIN
    slvlr(cnt,5)=max(SNRdata(:,2));                          % THETA MAX
    slvlr(cnt,6)=nanmean(SNRdata(:,3));                      % MEAN AZI

    if nol1==0
        slvlr(cnt,7) = reflh1(id);                           % L1 slvl
    else
        slvlr(cnt,7) = NaN;
    end
    y = SNR-dsnr;
    slvlr(cnt,8) = mean(y, 'omitnan');                               % mean mag. tSNR
    slvlr(cnt,9) = max(psd);                                  % the peak
    slvlr(cnt,10)= var(SNR);                               % the variance
    try
        slvlr(cnt,11:13) = double(band);
    catch
        slvlr(cnt,11:12) = double(band);
    end
    if gnss_system == "GPS"
        slvlr(cnt,14) = double('G');
    elseif gnss_system == "GLONASS"
        slvlr(cnt,14) = double('R');
    elseif gnss_system == "GALILEO"
        slvlr(cnt,14) = double('E');
    elseif gnss_system == "BDS"
        slvlr(cnt,14) = double('C');
    end
    slvlr(cnt,15) = trop_cor;

    lspy_flim = 300;
    lspy(cnt,:)=interp1(f,psd,1:1:lspy_flim);
end
end