function [t_rh,rh_adj,rh_nadj,rms_adj,rms_nadj] = spectralanalysis_kl(app,slvlrdir, ...
    tgstring,redconstits,makefig,Final_file_path)
% INPUTS
% slvlrdir: path to directory containing observed or synthetic slvlr
% arrays (i.e., using analyzesnr_fun.m or makesnr_fun.m)
% tgstring: path to tide gauge data in format 'xaxis' 'slvl'
% if no tg, leave empty: ''
% redoncstits: if set to 1 then use full 145 tidal constituents for
% adjustment, otherwise just use 5, can choose which 5 below
% only set to 1 if time series is long (1 year +)

% OUTPUTS
% t_rh: time index of output reflector heights
% rh_adj: adjusted reflector heights
% rh_nadj: unadjusted reflector heights
% rms_adj: RMS of tide gauge and adjusted reflector heights (if tide gauge given)
% rms_nadj: RMS of tide gauge and unadjusted reflector heights (if tide gauge given)


% constellations
gps = 1;
glo = 1;
gal = 1;
bds = 1;

global Operation_settings
plat     = Operation_settings.station_l(2);
plon     = Operation_settings.station_l(1);
elv_low  = Operation_settings.elv(1);
elv_high = Operation_settings.elv(2);
startdate= datenum(Operation_settings.time(1));
enddate  = datenum(Operation_settings.time(2));

% HERE IS WHERE YOU ARE LOADING ALL DATA TO BE ANALYZED
slvlrt = [];
datevect = startdate-1;
while datevect < enddate
    datevect = datevect+1;
    if exist([slvlrdir,'/',num2str(datevect),'slvlr_all.mat'],'file')==2
        load([slvlrdir,'/',num2str(datevect),'slvlr_all.mat'])
        slvlrt = [slvlrt; slvlr_all];
        clear slvlr
    end
end
slvlr = slvlrt;
clear slvlrt

if size(slvlr,1) < 1
    disp('apparently there is no data in this time range')
    return
end


% getting desired satellite constellations
% need to add galileo and beidou
if gps == 0
    delete = slvlr(:,2)<33;
    slvlr(delete,:) = [];
end
if glo == 0
    delete = slvlr(:,2)>32 && slvlr(:,2)<57;
    slvlr(delete,:) = [];
end
if gal == 0
    delete = slvlr(:,2)>56 && slvlr(:,2)<93;
    slvlr(delete,:)=[];
end
if bds == 0
    delete = slvlr(:,2)>92;
    slvlr(delete,:) = [];
end

% GET RID OF NANS
delete = isnan(slvlr(:,7));
slvlr(delete,:) = [];
slvlr = sortrows(slvlr,1);


% NOW START DOING LEAST SQUARES TIDAL FIT
rh_nadj    = slvlr(:,7);                    % sea level measurements
band_names = [char(slvlr(:,14)),char(slvlr(:,11:13))];
tanthter   = slvlr(:,3)./3600;              % to convert to per hour
t          = slvlr(:,1);                    % time

% getting rid of outliers
hsmooth = smoothdata(rh_nadj,'movmean',5);
diff1 = abs(rh_nadj - hsmooth);
std1 = std(diff1);                  % standard deviation
delete = diff1(:,1) > 2*std1;       % here choose 2*sigma bounds to remove

rh_nadj(delete,:)    = [];
t(delete,:)          = [];
tanthter(delete,:)   = [];
band_names(delete,:) = [];
slvlr(delete,:)      = [];


points_per_day      = numel(t)/(enddate+1-startdate);
app.point_day.Value = points_per_day;
load('tidefreqs.mat')

if redconstits == 0
    ju = 1:145;
else
    ju = [12 20 41 47 56]; % O1, K1, N2, M2, S2
end

coefs_0 = rand(numel(ju)*2,1) * 2 * sqrt(0.005) - sqrt(0.005);
freqs = freqs(ju);
names = names(ju,:);
tempfun = @(coefs) tidemod_kl(coefs, t, rh_nadj, ju, tanthter, freqs, plat);
options = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective','Display','off');
coefs_ls= lsqnonlin(tempfun,coefs_0,[],[],options); % here is the least squares

rh_adj = tidemod_kl_plot(coefs_ls,t,rh_nadj,ju,tanthter,freqs,plat);
rh_adj = app.asl.Value - rh_adj;
rh_nadj = app.asl.Value - rh_nadj;

[A,G,names] = coef2ampphase(coefs_ls,names);
t_rh = t;

if numel(tgstring) > 0
    load(tgstring)
    tide = unique([xaxis, slvl],"rows");
    xaxis = tide(:,1);
    slvl  = tide(:,2);
    tidexp  = xaxis;
    tideyp  = slvl;
    tiderms = interp1(xaxis,slvl,t_rh,'linear');

    tmps    = isnan(rh_adj)==0 & isnan(tiderms)==0;
    rms_adj = rms(tiderms(tmps)-rh_adj(tmps));
    rms_nadj= rms(tiderms(tmps)-rh_nadj(tmps));

    disp(['rms_adj=',num2str(rms_adj*100),' cm'])
    disp(['rms_nadj=',num2str(rms_nadj*100),' cm'])
else
    rms_adj = NaN;
    rms_nadj = NaN;
end

%% Print Final File
Time = datetime(t,'ConvertFrom','datenum');
sys = char(slvlr(:,14));
System = strings(size(sys));
System(sys == 'G') = "GPS";
System(sys == 'R') = "GLONASS";
System(sys == 'E') = "GALILEO";
System(sys == 'C') = "BDS";
if sum(~slvlr(:,13)==0) == 0
    BAND = string(char(slvlr(:,11:12)));
else
    BAND = string(char(slvlr(:,11:13)));
end
PRN = slvlr(:,2);
ROC = slvlr(:,3);
MIN_elv = slvlr(:,4);
MAX_elv = slvlr(:,5);
MEAN_AZI = slvlr(:,6);
RH = -rh_adj;
trop_c = slvlr(:,15);
tidal_cor = rh_adj - rh_nadj;
Final_table = table(Time,System,BAND,PRN,ROC,MIN_elv,MAX_elv,MEAN_AZI,RH,trop_c,tidal_cor);


sys_band = strcat(Final_table.System, Final_table.BAND);
uniqueFields = unique(sys_band);
Final_info = struct();

for i = 1:length(uniqueFields)
    fieldName = uniqueFields{i};
    selectedRows = Final_table(strcmp(sys_band, fieldName), :);
    Final_info.(fieldName) = selectedRows;
end
Final_file_name = [Operation_settings.station_name,'_', char(datetime(startdate,'ConvertFrom','datenum')),'_',...
    char(datetime(enddate,'ConvertFrom','datenum')),'_SNR-Spectral.mat'];
save(fullfile(Final_file_path,Final_file_name),"Final_info")

%%
if makefig == 1
    
    scatter(app.ans_dongtai,t_rh,rh_nadj,'r+','linewidth',1)
    hold(app.ans_dongtai,"on")
    axis(app.ans_dongtai,[startdate enddate+1 -inf inf])
    fs = 15;
    datetick(app.ans_dongtai,'x',1,'keeplimits','keepticks')
    ylabel(app.ans_dongtai,'Sea level (m)','interpreter','latex','fontsize',fs)
    set(app.ans_dongtai,'ticklabelinterpreter','latex','fontsize',fs)
    if numel(tgstring) > 0
        plot(app.ans_dongtai, tidexp,tideyp,'k','linewidth',1.5)
    end
    hold(app.ans_dongtai,"off")
end

if app.BA.Value == 1
    set(figure, 'Visible', 'on')
    figure

    hold on
    scatter(t_rh,rh_nadj,'r+','linewidth',1,'displayname',['After RMS=',num2str(rms_adj*100),' cm'])
    scatter(t_rh,rh_adj, 'b+','linewidth',1,'displayname',['Before RMS=',num2str(rms_nadj*100),' cm'])
    axis([startdate enddate+1 -inf inf])
    fs = 15;
    datetick('x',1,'keeplimits','keepticks')
    ylabel('Sea level (m)','interpreter','latex','fontsize',fs)
    if numel(tgstring) > 0
        plot(tidexp,tideyp,'k','linewidth',1.5,'displayname','Tide level')
    end
    hold off
    box on
    title('Correrction contrast diagram')
    legend

end

tide_indx = tidexp<=enddate+1 & tidexp>=startdate;
sea_level_tide = tideyp(tide_indx);
time_tide = tidexp(tide_indx);
if app.band_com.Value == 1
    figure
    gnss = ['G','R','E','C'];
    tiledlayout(4,5,'TileSpacing','compact');
    data_all = [t_rh, rh_adj, double(band_names(:,2:end))];
    for s = 1:4
        sys = gnss(s);
        gnss_indx = band_names(:,1)==sys;
        cur_data = data_all(gnss_indx,:);
        if isempty(cur_data)
            continue
        end
        cur_data = sortrows(cur_data);

        time = cur_data(:,1);
        sea_level_ir = cur_data(:,2);
        band = string(char(cur_data(:,3:end)));
        group = categorical(band);
        nexttile([1,4])
        hold on
        gscatter(time, sea_level_ir,group,[],'+o*xhs',6)

        plot(time_tide,sea_level_tide,'Color','black','LineWidth',1.5,'DisplayName', 'Tide level')
        xlabel('Time')
        datetick('x', 'dd-mmm-yyyy', 'keepticks', 'keeplimits')
        ylabel('Sea level(m)')
        title(sys)
        hold off
        box on

        nexttile
        bands = string(unique(group));
        RMS = nan(numel(bands),1);
        valid_num = nan(numel(bands),1);
        for b = 1:numel(bands)
            cur_band = bands(b);
            cur_indx = band==cur_band;
            time_band = time(cur_indx);
            sea_level_ir_band = sea_level_ir(cur_indx);
            repeat_time = find(diff(time_band)==0);
            time_band(repeat_time) = [];
            sea_level_ir_band(repeat_time) = [];
            try
                interp_ir = interp1(time_band,sea_level_ir_band,time_tide,"linear");
            catch
                RMS(b) = nan;
                valid_num(b) = nan;
                continue
            end

            valid_indx = ~isnan(interp_ir) & ~isnan(sea_level_tide);
            RMS(b) = rms(interp_ir(valid_indx)-sea_level_tide(valid_indx));
            valid_num(b) = numel(sea_level_ir_band);
        end
        b = barh(RMS*100,0.5, 'FaceColor',[0.3010 0.7450 0.9330]);
        set(gca, 'YTickLabel', bands)
        xlabel('RMS(cm)')
        xtips1 = b(1).YEndPoints + 0.01;
        ytips1 = b(1).XEndPoints;
        rms_band = string(b(1).YData);
        text(xtips1,ytips1,rms_band,'HorizontalAlignment','right','Color','r')
        text(xtips1,ytips1,string(valid_num/(enddate-startdate+1)),'HorizontalAlignment','left','Color',[0.4660 0.6740 0.1880])

        xlim([0, max(RMS)*100+5])
    end
end

if app.SPD.Value == 1
    figure
    geoplot(plat,plon,'p',MarkerSize=20,MarkerFaceColor='b')
    hold on
    for arc = 1:numel(slvlr(:,1))
        for e = 1:2
            el = slvlr(arc,4+e-1);
            az = slvlr(arc,6);
            ht = app.antenna_height.Value - slvlr(arc,7);
            sys = char(slvlr(arc,14));
            if sys == 'G'
                gnss_system = "GPS";
            elseif sys == 'R'
                gnss_system = "GLONASS";
            elseif sys == 'E'
                gnss_system = "GALILEO";
            elseif sys == 'C'
                gnss_system = "BDS";
            end
            band = char(slvlr(arc,11:13));
            sat = slvlr(arc,2);
            freq = 299792458/get_wave_length(gnss_system, band, sat);
            data = Spatial_distribution(plat,plon,el,az, ht, freq);
            if e == 1
                color = 'b';
            else
                color = 'r';
            end
            geoplot(data(2,:),data(1,:),color)
        end
    end
    geobasemap("satellite")
    text(plat,plon,'station','Color',[1,1,1],'FontSize',10);
    hold off
end

if app.DH.Value == 1
    figure
    gnss = ['G','R','E','C'];
    data_all = [t_rh, rh_adj, double(band_names(:,2:end))];
    for s = 1:4
        sys = gnss(s);
        gnss_indx = band_names(:,1)==sys;
        cur_data = data_all(gnss_indx,:);
        cur_data = sortrows(cur_data);

        time = cur_data(:,1);
        sea_level_ir = cur_data(:,2);
        band = string(char(cur_data(:,3:end)));
        group = categorical(band);

        bands = string(unique(group));
        for b = 1:numel(bands)
            cur_band = bands(b);
            cur_indx = band==cur_band;
            time_band = time(cur_indx);
            sea_level_ir_band = sea_level_ir(cur_indx);
            repeat_time = find(diff(time_band)==0);
            time_band(repeat_time) = [];
            sea_level_ir_band(repeat_time) = [];
            try
                interp_ir = interp1(time_band,sea_level_ir_band,time_tide,"linear");
            catch
                DIF = nan;
                continue
            end

            valid_indx = ~isnan(interp_ir) & ~isnan(sea_level_tide);
            DIF = interp_ir(valid_indx)-sea_level_tide(valid_indx);
            nexttile
            h = histogram(DIF,'BinWidth',0.02,'FaceColor',[0.5294,0.801,1],'EdgeColor','w');
            pd = fitdist(DIF,'Normal');
            mean_value = pd.mu;
            std_value = pd.sigma;
            text_position = [0.95 0.9];
            text_str = sprintf('μ= %.2f\nσ= %.2f', mean_value, std_value);
            text('Position', text_position, 'String', text_str, 'Units', 'normalized','HorizontalAlignment','right','FontSize',16,'FontWeight','bold'); % 添加文本

            hold on
            x = linspace(min(DIF),max(DIF),(max(DIF)-min(DIF))/0.02);
            y = pdf(pd,x);
            y = y * sum(h.Values)/sum(y);
            plot(x, y, 'k','LineWidth',2);
            title(strcat(sys,cur_band))
            hold off
        end

    end
end

if app.cor.Value == 1
    figure
    % tide data
    tide_indx = tidexp<=enddate & tidexp>=startdate;
    sea_level_tide = tideyp(tide_indx);
    time_tide = tidexp(tide_indx);

    data = [t_rh, rh_adj];
    data = sortrows(data);
    time = data(:,1);
    sea_level_ir = data(:,2);
    repeat_time = find(diff(time)==0);
    time(repeat_time) = [];
    sea_level_ir(repeat_time) = [];
    interp_ir = interp1(time,sea_level_ir,time_tide,"linear");
    [~,TFrm] = rmoutliers(interp_ir,"movmedian",20);
    interp_ir(TFrm) = nan; 
    CData = density2C(interp_ir,sea_level_tide,min(sea_level_tide):0.01:max(sea_level_tide),min(sea_level_tide):0.1:max(sea_level_tide));
    set(gcf,'Color',[1 1 1]);
    scatter(interp_ir,sea_level_tide,50,'filled','CData',CData);
    xlim([min(sea_level_tide),max(sea_level_tide)])
    ylim([min(sea_level_tide),max(sea_level_tide)])
    box on
    hold on
    x = min(sea_level_tide):0.01:max(sea_level_tide);
    y = x;
    plot(x, y, 'r--','LineWidth',3);

    nan_indx = isnan(interp_ir) | isnan(sea_level_tide);
    p = polyfit(interp_ir(~nan_indx),sea_level_tide(~nan_indx), 1);
    y_fit = p(1)*x + p(2);
    plot(x, y_fit, 'r');

    r = corrcoef(interp_ir(~nan_indx),sea_level_tide(~nan_indx));
    r_value = r(1,2);
    text(min(sea_level_tide)+0.1,max(sea_level_tide)-0.1, ['r = ', num2str(r_value)]);
    colorbar

    xlabel('GNSS-IR Water Level(m)')
    ylabel('Tide Gauge (m)')
    title('Correlation scatter plot')
    hold off
end
end

function [CData,h,XMesh,YMesh,ZMesh,colorList]=density2C(X,Y,XList,YList,colorList)
[XMesh,YMesh]=meshgrid(XList,YList);
XYi=[XMesh(:) YMesh(:)];
F=ksdensity([X,Y],XYi);
ZMesh=zeros(size(XMesh));
ZMesh(1:length(F))=F;

h=interp2(XMesh,YMesh,ZMesh,X,Y);
if nargin<5
    colorList=[0.2700         0    0.3300
        0.2700    0.2300    0.5100
        0.1900    0.4100    0.5600
        0.1200    0.5600    0.5500
        0.2100    0.7200    0.4700
        0.5600    0.8400    0.2700
        0.9900    0.9100    0.1300];
end
colorFunc=colorFuncFactory(colorList);
CData=colorFunc((h-min(h))./(max(h)-min(h)));
colorList=colorFunc(linspace(0,1,100)');

    function colorFunc=colorFuncFactory(colorList)
        x=(0:size(colorList,1)-1)./(size(colorList,1)-1);
        y1=colorList(:,1);y2=colorList(:,2);y3=colorList(:,3);
        colorFunc=@(X)[interp1(x,y1,X,'pchip'),interp1(x,y2,X,'pchip'),interp1(x,y3,X,'pchip')];
    end
end
