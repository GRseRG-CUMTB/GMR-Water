function [residout] = bsp_snrout(app,coefs_0,t1_all,sinelv1_all,snr1_all,knots,bspline_order,...
    satno_all,gps,glo,gal,bds,antno_all,meanhgts,dtdv,elv_low,elv_high)


t1_alls=t1_all;
sinelv1_alls = sinelv1_all;
snr1_alls = snr1_all;
satno_alls = satno_all;

snrout=NaN(size(snr1_all));
ants=unique(antno_all);

consts=gps+glo+gal+bds;
is_rough = string(app.rough_sw.Value);
if is_rough == "On"
    height_coeff = coefs_0(1:end-consts*2-1);
else
    height_coeff = coefs_0(1:end-consts*2);
    coefs_0 = [coefs_0 0.01];
end

for k=1:numel(ants)

    now = antno_all(:)==k;
    t1_all=t1_alls(now);
    sinelv1_all=sinelv1_alls(now);
    snr1_all=snr1_alls(now);
    satno_all=satno_alls(now);
    snrout_all=snrout(now);

    h1 = bspline_deboor(bspline_order+1,knots,height_coeff,t1_all);
    h1 = h1.';
    if k > 1
        h1 = h1+meanhgts(k) - meanhgts(1);
    end

    tmpc = 0;
    % GPS
    if gps == 1
        tmpc = tmpc+1;
        gps = satno_all(:,1)<33;
        L1car = (299792458/(1575.42e06/1.023)); % for GPS
        L1k = (2*pi)/L1car;
        modelSNR1 = (coefs_0(end-1)*sin((4*pi*h1(gps).*sinelv1_all(gps))/L1car)+...
            coefs_0(end-2)*cos((4*pi*h1(gps).*sinelv1_all(gps))/L1car)).*...
            exp(-4*L1k^2*coefs_0(end)*sinelv1_all(gps).^2);
        snrout_all(gps) = modelSNR1;
    end
    % GLO
    if glo == 1
        tmpc = tmpc+1;
        glo = satno_all(:,1)>32 & satno_all(:,1)<57;
        load('glonasswlen.mat')
        satnotmp=satno_all(glo,1);
        for ij=1:numel(satnotmp)
            L1car(ij)=glonasswlen(satnotmp(ij)-32);
        end
        L1car=L1car.';
        L1k=(2*pi)./L1car;
        modelSNR1 = (coefs_0(end-(tmpc-1)*2-1)*sin((4*pi*h1(glo).*sinelv1_all(glo))./L1car)+...
            coefs_0(end-(tmpc-1)*2-2)*cos((4*pi*h1(glo).*sinelv1_all(glo))./L1car)).*...
            exp(-4*L1k.^2*coefs_0(end).*sinelv1_all(glo).^2);
        snrout_all(glo)=modelSNR1;
    end
    % GAL
    if gal==1
        tmpc=tmpc+1;
        gal=satno_all(:,1)>56 & satno_all(:,1)<56+36+1;
        L1car=(299792458/(1575.42e06/1.023)); % for Galileo
        L1k=(2*pi)/L1car;
        modelSNR1 = (coefs_0(end-(tmpc-1)*2-1)*sin((4*pi*h1(gal).*sinelv1_all(gal))/L1car)+...
            coefs_0(end-(tmpc-1)*2-2)*cos((4*pi*h1(gal).*sinelv1_all(gal))/L1car)).*...
            exp(-4*L1k^2*coefs_0(end)*sinelv1_all(gal).^2);
        snrout_all(gal)=modelSNR1;
    end
    % BDS
    if bds == 1
        tmpc=tmpc+1;
        bds = satno_all(:,1)>56+36;
        L1car=(299792458/(1575.42e06/1.023)); % for bds
        L1k=(2*pi)/L1car;
        modelSNR1 = (coefs_0(end-(tmpc-1)*2-1)*sin((4*pi*h1(bds).*sinelv1_all(bds))/L1car)+...
            coefs_0(end-(tmpc-1)*2-2)*cos((4*pi*h1(bds).*sinelv1_all(bds))/L1car)).*...
            exp(-4*L1k^2*coefs_0(end)*sinelv1_all(bds).^2);
        snrout_all(bds) = modelSNR1;
    end
    snrout(now) = snrout_all;
end


fsz = 11;      % Fontsize
close all

% now export all the pics to tempmodsnr
for ii=1:numel(ants)
    now = antno_all(:)==ii;
    sinelvtmp=sinelv1_all(now);
    snrtmp = snr1_all(now);
    modelsnrtmp = snrout(now);
    t1tmp=t1_all(now);
    satnotmp=satno_all(now);
    ind=1;
    stind=1;
    cursat=satnotmp(1);
    if sinelvtmp(2)-sinelvtmp(1)<0
        fwd2=0;
    else
        fwd2=1;
    end
    count=0;
    ax = app.SNR_model;
    while ind<numel(sinelvtmp)
        %while count<30
        ind=ind+1;
        if sinelvtmp(ind)-sinelvtmp(ind-1)<0
            fwd1=0;
        else
            fwd1=1;
        end
        curdt=t1tmp(ind)-t1tmp(ind-1);
        if ind-stind>1
            if satnotmp(ind)~=cursat || ind==size(sinelvtmp,1) || abs(curdt)>=3*dtdv...
                    || fwd2~=fwd1 || sinelvtmp(ind)==sinelvtmp(ind-1)
                drawnow
                figure('visible','off')
                plot(ax,sinelvtmp(stind:ind-1),snrtmp(stind:ind-1),'b','linewidth',0.8)
                hold(ax,"on")
                plot(ax,sinelvtmp(stind:ind-1),modelsnrtmp(stind:ind-1),'r','linewidth',0.8)
                legend(ax,'$\delta SNR-Real$','$\delta SNR-Modeling$','interpreter','latex','fontsize',fsz)
                xlabel(ax,'$\sin{\theta}$','interpreter','latex','fontsize',fsz,'FontWeight','bold')
                ylabel(ax,'$\delta SNR$','interpreter','latex','fontsize',fsz,'FontWeight','bold')
                title(ax,'SNR residual sequence Modeling vs. Real','fontsize',16,'FontWeight','bold')
                
                axis(ax,[sind(elv_low) sind(elv_high) -50 50])
                hold(ax,"off")
                count = count+1;
                residout(count,1)=satnotmp(ind-1);
                residout(count,2)=sum(abs(modelsnrtmp(stind:ind-1)-snrtmp(stind:ind-1)));
                cursat=satnotmp(ind);
                stind = ind;
            end
        end
        fwd2=fwd1;
    end
end

end

