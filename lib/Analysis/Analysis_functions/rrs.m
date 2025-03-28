function [time, sea_level_ir, RMSE, Bias] = rrs(RH_info_all, start_date, end_date, fig_set)
%% Robust regression strategy
% Xiaolei Wang, Xiufeng He, Qin Zhang, Evaluation and combination of
% quad-constellation multi-GNSS multipath reflectometry applied to sea 
% level retrieval, Remote Sensing of Environment, https://doi.org/10.1016/j.rse.2019.111229.

rh        = RH_info_all.RH;
h_tidal   = RH_info_all.tidal_cor;
h_trop    = RH_info_all.trop_c;
h_initial = rh-h_trop-h_tidal;
roc = (RH_info_all.ROC)./(24*3600);
t   = datenum(RH_info_all.Time);


time_difference = end_date - start_date+1;
interval = 6;     % min
loop_interval = interval/(24*60);
epoc_num = time_difference / loop_interval + 1;
clear RH_final h_change
e = 0;
RH_final = lsq(epoc_num, start_date, interval, RH_info_all, h_initial, h_trop, roc, t, e, h_tidal);

mu       = nanmean(RH_final);
sigma    = nanstd(RH_final);
RH_final(abs(RH_final - mu) > 3 * sigma) = nan;
sea_level_ir = fig_set.sta_asl - RH_final;
time = datetime(start_date:loop_interval:(end_date+1), 'ConvertFrom','datenum');

time_tide      = fig_set.tidal_info{1};
sea_level_tide = fig_set.tidal_info{2};
if fig_set.option
    figure
    set(gcf, 'Units', 'normalized', 'OuterPosition', [0.1 0.1 0.7 0.5]);
    if ~isempty(sea_level_tide)
        tiledlayout(7,1,'TileSpacing','compact');
        nexttile([5,1])
    end
    scatter(datetime(t,'ConvertFrom','datenum'), fig_set.sta_asl-rh, ...
        30, [0.7, 0.7, 0.7],"filled", 'DisplayName', 'Raw retrievals')
    hold on
    plot(time, sea_level_ir,'Color','r','LineWidth',1.5,...
        'DisplayName', 'Multi-GNSS combined retrievals')
    hold on
    xlim([min(time), max(time)])
    ylabel('Sea level (m)','FontWeight','bold')
    legend
    box on

    title('Robust regression strategy','FontWeight','bold','FontSize',18)

    if ~isempty(sea_level_tide)
        sea_level_tide = interp1(time_tide,sea_level_tide, time);
        plot(time,sea_level_tide,'Color','black','LineWidth',1.5,...
            'DisplayName', 'Tide gauge')
        %     xlabel('Time')
        set(gca,'XTickLabel',[])

        nexttile([2,1])
        plot(time,sea_level_ir- sea_level_tide)
        xlabel('Time','FontWeight','bold')
        datetick('x', 'dd-mmm-yyyy', 'keepticks', 'keeplimits')
        ylabel('Residual error (m)','FontWeight','bold')
        xlim([min(time), max(time)])
    else
        xlabel('Time','FontWeight','bold')
    end
end

RH_final = sea_level_ir;

if ~isempty(sea_level_tide)
    Bias = nanmean(sea_level_ir- sea_level_tide);
    RMSE = sqrt(nanmean((sea_level_ir- sea_level_tide).^2));
else
    Bias = nan;
    RMSE = nan;
end
end