function [t_rh,rh_invjs,rh_invpre,rms_js,rms_pre] = invsnr_plot(invdir,startdate, enddate,kspac,tlen,...
    plotl,roughnessplot, varargin)

%%

% this codes takes the output from invsnr.m and plots it and compares with
% a tide gauge (if there is one)

% INPUTS
% startdate: in datenum format
% enddate: in datenum format
% invdir: directory that contains invsnr.m output to plot
% kspac: average node spacing in days (e.g., 2/24 is 2 hours)
% tlen: length of window for analysis in days, split into 3 and the middle
% period is saved (e.g., setting to 3 means that the middle day is saved)
% plotl: the frequency of output time series, in days (e.g., 1/24 is
% hourly)
% tgstring: string of path to tide gauge data (or [] if no tide gauge data)
% makefig: set to 1 if you want to plot / save a figure
% roughnessplot:m add another panel with a daily plot of the roughness
% parameter

% OUPUTS
% t_rh: time vector in datenum format
% rh_invjs: output of b-spline reflector heights from Strandberg et al. analysis
% rh_invpre: output of b-spline reflector heights using spectral analysis
% rms_js: rms between tide gauge and invjs output
% rms_pre: rms between tide gauge and invdp output

if numel(varargin) ~= 0
    app = varargin{1};
    tgstring = varargin{2};
end
meanormedian = 2;
p = 2;

knots = [(startdate-tlen/3)*ones(1,p) ...
    startdate-tlen/3:kspac:enddate+1+tlen/3 ...
    (enddate+1+tlen/3)*ones(1,p)];
t_rh = startdate:plotl:enddate+1; % plotl: the frequency of output time series, in days

sfacspreall=[];
sfacsjsall=[];
x_init=[];
h_init=[];
roughness_all=[];
dispmissed=0;

tdatenum = startdate-tlen/3;
while round(tdatenum,10,'significant') < round(enddate+1-tlen/3,10,'significant')
    tdatenum = tdatenum+tlen/3;
    inds = tlen/(3*kspac)+2;
    inde = (2*tlen)/(3*kspac)+1;
    if tdatenum == startdate
        inds = 1;
    end
    if round(tdatenum,10,'significant') >= round(enddate+1-tlen/3,10,'significant')
        inde = tlen/kspac+p;
    end

    if exist([char(invdir),'/',num2str(round(tdatenum,10,'significant')),'.mat'],'file')==2
        load([char(invdir),'\',num2str(tdatenum),'.mat'])
        if (numel(sfacsjs)>1 || ~isnan(sfacsjs(1))) && numel(hinit)>0
            sfacspreall = [sfacspreall sfacspre(inds:inde)];
            sfacsjsall = [sfacsjsall sfacsjs(inds:inde)];
            x_init = [x_init xinit];
            h_init = [h_init hinit];
            if exist('roughout','var')==1
                roughness_all = [roughness_all roughout];
            else
                roughness_all = [roughness_all NaN];
            end
        else
            if dispmissed == 0
                disp('missingdata')
                dispmissed = 1;
            end
            sfacspreall = [sfacspreall NaN(1,inde-inds+1)];
            sfacsjsall = [sfacsjsall NaN(1,inde-inds+1)];
            roughness_all = [roughness_all NaN];
        end
    else
        if dispmissed==0
            disp('missingdata')
            dispmissed=1;
        end
        sfacspreall=[sfacspreall NaN(1,inde-inds+1)];
        sfacsjsall=[sfacsjsall NaN(1,inde-inds+1)];
        roughness_all=[roughness_all NaN];
    end
end

%% 
indfac = numel(sfacsjsall);
for ii=1:indfac
    jj=0;
    dptmp=[];
    jstmp=[];
    while jj<numel(invdir)
        jj=jj+1;
        dptmp = [dptmp sfacspreall(ii+(jj-1)*indfac)];
        jstmp = [jstmp sfacsjsall(ii+(jj-1)*indfac)];
    end
    if meanormedian==1
        sfacsprep(ii)=nanmean(dptmp);
        sfacsjsp(ii)=nanmean(jstmp);
    else
        sfacsprep(ii)=nanmedian(dptmp);
        sfacsjsp(ii)=nanmedian(jstmp);
    end
end
if numel(roughness_all)>1
    roughlen=enddate-startdate;
    for ii=1:roughlen
        jj=0;
        roughtmp=[];
        while jj<numel(invdir)
            jj=jj+1;
            roughtmp=[roughtmp roughness_all(ii+(jj-1)*roughlen)];
        end
        if meanormedian==1
            roughmean(ii)=nanmean(roughtmp);
        else
            roughmean(ii)=nanmedian(roughtmp);
        end
    end
end

%% 
dell= t_rh(:)<min(x_init) | t_rh(:)>max(x_init);
t_rh(dell)=[];

rh_invjs  = bspline_deboor(p+1,knots, sfacsjsp, t_rh);
rh_invpre = bspline_deboor(p+1,knots, sfacsprep, t_rh);


%% Tide file exist
if exist("tgstring","var")
    load(tgstring)
    tide = [xaxis, slvl];
    [~, idx] = unique(tide(:,1), 'stable');
    tide = tide(idx, :);
    %     tide = tide(1:60:end,:);  % re sample to hourly
    xaxis = tide(:,1);
    slvl  = tide(:,2);

    slvl=interp1(xaxis,slvl,t_rh,'linear');
    tidey=slvl;
    tidex=t_rh;

    in=isnan(tidey)==0 & isnan(rh_invjs)==0;
    rms_js = rms(app.ahgt.Value-rh_invjs(in) - tidey(in));
    in=isnan(tidey)==0 & isnan(rh_invpre)==0;
    rms_pre = rms(app.ahgt.Value-rh_invpre(in)-tidey(in));
    disp(['rms pre is ',num2str(rms_pre*100),' cm'])
    disp(['rms js is ',num2str(rms_js*100),' cm'])
else
    rms_js=NaN;
    rms_pre=NaN;
end
pointsperday = sum(~isnan(h_init))/(enddate+1-startdate);

%% APP mode
if exist("app","var")
    app.point_day.Value = pointsperday;

    %% PLOTTING
    ax = app.inverse_results;
    hold(ax,"off")
    if roughnessplot == 1
        subplot(ax,2,1,1)
    end
    if numel(tgstring)>0
        plot(ax,tidex,tidey,'k')
        hold(ax,"on")
    end
    scatter(ax,x_init,app.ahgt.Value-h_init,'r+')
    hold(ax,"on")
    plot(ax,t_rh, app.ahgt.Value-rh_invjs,'b','linewidth',1.5)
    plot(ax,t_rh, app.ahgt.Value-rh_invpre,'r--','linewidth',1)
    axis(ax,[min(t_rh) max(t_rh) -inf inf])
    ylabel(ax,'Sea level (m)','interpreter','latex')
    datetick(ax,'x',1,'keeplimits','keepticks')
    set(ax,'ticklabelinterpreter','latex')
    h = legend(ax,'Tide gauge','Spectral analysis','Inverse modeling', ...
        'Spectral analysis (B-spline)','fontsize',12);
    set(h,'interpreter','latex')
    hold(ax,"off")

    if roughnessplot == 1
        subplot(2,1,2)
        plot(ax,startdate+0.5:1:enddate-0.5,roughmean,'r')
        %plot(t_rh,movmean(rh_invjs(in)-tiderms(in),10),'r')
        axis([startdate enddate+1 -inf inf])
        datetick('x',1,'keeplimits','keepticks')
        ylabel('Surface roughness_all (m)','interpreter','latex','fontsize',fsz)
        set(gca,'ticklabelinterpreter','latex','fontsize',fsz)
        %set(gca,'xtick',startdate:2:enddate)
    end


    % tide data
    tide_indx = tidex<=enddate & tidex>=startdate;

    for f = 1:2
        if f == 1
            rh = app.ahgt.Value-rh_invjs;
        else
            rh = app.ahgt.Value-rh_invpre;
        end
        sea_level_tide = tidey(tide_indx);
        time_tide = tidex(tide_indx);

        data = [t_rh; rh];
        data = sortrows(data');
        time = data(:,1);
        sea_level_ir = data(:,2);
        repeat_time = find(diff(time)==0);
        time(repeat_time) = [];
        sea_level_ir(repeat_time) = [];
        nan_indx = isnan(sea_level_ir);
        sea_level_ir(nan_indx) = [];
        time(nan_indx) = [];

        interp_ir = interp1(time,sea_level_ir,time_tide,"linear");
        [~,TFrm] = rmoutliers(interp_ir,"movmedian",20);
        interp_ir(TFrm) = nan;

        nan_indx = isnan(interp_ir);
        interp_ir(nan_indx) = [];
        sea_level_tide(nan_indx) = [];
        CData = density2C(interp_ir',sea_level_tide',min(sea_level_tide):0.01:max(sea_level_tide), ...
            min(sea_level_tide):0.01:max(sea_level_tide));
        DH.(strcat('f',num2str(f))) = (interp_ir-sea_level_tide)';
        if app.cor.Value == 1
            if f == 1
                figure
                tiledlayout(1,2,'TileSpacing','compact');
            end
            ax_cor = nexttile;
            set(gcf,'Color',[1 1 1]);
            scatter(ax_cor,interp_ir,sea_level_tide,25,'filled','CData',CData);
            xlim(ax_cor,[min(sea_level_tide),max(sea_level_tide)])
            ylim(ax_cor,[min(sea_level_tide),max(sea_level_tide)])
            box(ax_cor,"on")
            hold(ax_cor,"on")
            x = min(sea_level_tide):0.01:max(sea_level_tide);
            y = x;
            plot(ax_cor,x, y, 'r--','LineWidth',3);

            nan_indx = isnan(interp_ir) | isnan(sea_level_tide);
            p = polyfit(interp_ir(~nan_indx),sea_level_tide(~nan_indx), 1);
            y_fit = p(1)*x + p(2);
            plot(ax_cor,x, y_fit, 'r');

            r = corrcoef(interp_ir(~nan_indx),sea_level_tide(~nan_indx));
            r_value = r(1,2);
            text(ax_cor,min(sea_level_tide)+0.1,max(sea_level_tide)-0.1, ...
                ['r = ', num2str(r_value)]);
            colorbar

            if f == 1
                xlabel('Water Level-Inverse Modeling (m)')
            else
                xlabel('Water Level-Spectral analysis in B-spline (m)')
            end
            ylabel('Tide gauge(m)')
            hold off
        end


    end

    if app.DH.Value == 1
        figure
        tiledlayout(1,2,'TileSpacing','compact');
        for f = 1:2
            nexttile
            DIF = DH.(strcat('f',num2str(f)));
            h = histogram(DIF,'BinWidth',0.005,'FaceColor',[0.5294,0.801,1],'EdgeColor','w');
            pd = fitdist(DIF,'Normal');
            mean_value = pd.mu;
            std_value = pd.sigma;
            text_position = [0.95 0.9];
            text_str = sprintf('μ= %.2f\nσ= %.2f', mean_value, std_value);
            text('Position', text_position, 'String', text_str, 'Units', ...
                'normalized','HorizontalAlignment','right','FontSize',16,'FontWeight','bold');

            hold on
            x = linspace(min(DIF),max(DIF),(max(DIF)-min(DIF))/0.005);
            y = pdf(pd,x);
            y = y * sum(h.Values)/sum(y);
            plot(x, y, 'k','LineWidth',2);
            if f == 1
                title('Inverse Modeling')
            else
                title('Spectral analysis')
            end
            hold off
        end
    end
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
