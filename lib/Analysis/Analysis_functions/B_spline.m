function [t_rh,sea_level_ir, RMSE, Bias] = B_spline(RH_info_all, start_date, end_date, fig_set)

p = 2;
kspac = 0.125;
sfacs_init = [];
knots = [];
start_time = datetime(start_date, 'ConvertFrom', 'datenum');
end_time = datetime(end_date,'ConvertFrom','datenum');
disp('B spline start...')
for t_day = start_time: days(1): end_time
    RH_day = RH_info_all(RH_info_all.Time>= t_day & RH_info_all.Time< t_day+days(1),:);
    t = datenum(RH_day.Time);
    rh= RH_day.RH;
    xinit = t;
    hinit = rh;
    tanthter = RH_day.ROC;

    st = datenum(t_day);
    et = datenum(t_day+days(1));
    tlen = et-st;
    knots_day = [st*ones(1,p) ...
        st:kspac:st+tlen ...
        (st+tlen)*ones(1,p)]; % knot vector, multiplicity = 4
    nsfac = tlen/kspac + p;
    sfacs_0 = fig_set.sta_asl*ones(1,nsfac); % control points
    tempfun_init = @(sfacs) bspline_spectral(sfacs, p, knots_day, tanthter, xinit,1) - hinit.';
    options = optimoptions(@lsqnonlin,'Algorithm','levenberg-marquardt',...
        'Display','off'); 
    sfacs_init_day = lsqnonlin(tempfun_init, sfacs_0, [], [], options);

    if p == 2
        if t_day == start_time
            sfacs_init = [sfacs_init, sfacs_init_day];
            knots = [knots, knots_day(1:end-p)];
        elseif t_day == end_time
            sfacs_init(end) = [];
            sfacs_init = [sfacs_init, sfacs_init_day(2:end)];
            knots = [knots, knots_day(p+2:end)];
        else
            sfacs_init(end) = [];
            sfacs_init = [sfacs_init, sfacs_init_day(2:end)];
            knots = [knots, knots_day(p+2:end-p)];
        end
    end

    if p == 3
        if t_day == start_time
            sfacs_init = [sfacs_init, sfacs_init_day];
            knots = [knots, knots_day(1:end-p)];
        elseif t_day == end_time
            sfacs_init(end-1) = sum(sfacs_init(end-1:end)+sfacs_init_day(1:2))/4;
            sfacs_init(end) = [];
            sfacs_init = [sfacs_init, sfacs_init_day(3:end)];
            knots = [knots, knots_day(p+2:end)];
        else
            sfacs_init(end-1) = sum(sfacs_init(end-1:end)+sfacs_init_day(1:2))/4;
            sfacs_init(end) = [];
            sfacs_init = [sfacs_init, sfacs_init_day(3:end)];
            knots = [knots, knots_day(p+2:end-p)];
        end
    end
end

t_rh = start_date:(6/(24*60)):end_date+1;
rh_b_spline = bspline_deboor(p+1,knots,sfacs_init,t_rh);
sea_level_ir = fig_set.sta_asl - rh_b_spline;
t_rh = datetime(t_rh,'ConvertFrom','datenum');

time_tide      = fig_set.tidal_info{1};
sea_level_tide = fig_set.tidal_info{2};
if fig_set.option
    figure
    set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.7 0.5]);
    if ~isempty(sea_level_tide)
        tiledlayout(7,1,'TileSpacing','compact');
        nexttile([5,1])
    end
    scatter(RH_info_all.Time, fig_set.sta_asl-RH_info_all.RH, ...
        30, [0.7, 0.7, 0.7],"filled", 'DisplayName', 'Raw retrievals')
    hold on
    plot(t_rh, sea_level_ir,'Color','r','LineWidth',1.5,...
        'DisplayName', 'Multi-GNSS combined retrievals')
    ylabel('Sea level (m)','FontWeight','bold')
    legend
    box on
    xlim([min(t_rh),max(t_rh)])
    title('B spline','FontWeight','bold','FontSize',18)
    hold on

    if ~isempty(sea_level_tide)
        sea_level_tide = interp1(time_tide,sea_level_tide, t_rh);
        plot(t_rh,sea_level_tide,'Color','black','LineWidth',1.5,...
            'DisplayName', 'Tide gauge')
        %     xlabel('Time')
        set(gca,'XTickLabel',[])

        nexttile([2,1])
        plot(t_rh,sea_level_ir- sea_level_tide)
        datetick('x', 'dd-mmm-yyyy', 'keepticks', 'keeplimits')
        ylabel('Residual error (m)','FontWeight','bold')
        xlim([min(time_tide),max(time_tide)])
    else
        xlabel('Time','FontWeight','bold')
    end
end

rh_b_spline = sea_level_ir;
if ~isempty(sea_level_tide)
    Bias = nanmean(sea_level_ir - sea_level_tide);
    RMSE = sqrt(nanmean((sea_level_ir - sea_level_tide).^2));
else
    Bias = nan;
    RMSE = nan;
end
end