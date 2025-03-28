function Result_display_SNR_Spectral_CMC(settings, RH_info_all,time_tide,sea_level_tide, colors, start_date,end_date)
GNSS = ["GPS","GLONASS","GALILEO","BDS"];
figure
set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
tiledlayout(4,6,'TileSpacing','compact');

for s = 1:4
    sys = GNSS(s);
    cur_RH = RH_info_all(RH_info_all{:,2}==sys , :); % Current system Data
    if isempty(cur_RH)
        continue
    end
    cur_RH = sortrows(cur_RH,"Time");

    time = cur_RH{:,"Time"};
    sea_level_ir = settings.antenna_height - cur_RH{:,"RH"};
    band = cur_RH{:,"BAND"};
    group = categorical(band);
    % Time series
    if ~isempty(time_tide)
        nexttile([1,4])
        plot(time_tide,sea_level_tide,'Color',[0.3, 0.3, 0.3],'LineWidth',0.5,'DisplayName', 'Tide gauge')
    else
        nexttile([1,5])
    end
    hold on
    gscatter(time, sea_level_ir,group,colors,'+o*xhs', 5,5)
    if ~isempty(time_tide)
        legend(["Tide gauge";unique(band)])
    else
        legend(unique(band))
    end
    
    if s == 4
        xlabel('Time')
        datetick('x', 'dd-mmm-yyyy', 'keepticks', 'keeplimits')
    else
        set(gca,'XTickLabel',[],'XLabel',[]);
    end
    ylabel('Sea level(m)','FontWeight','bold')
    title(sys)
    hold off
    box on
    xlim([min(time), max(time)+1])

    % RMSE
    bands = string(unique(group));
    RMSE = nan(numel(bands),1);
    valid_num = nan(numel(bands),1);
    for b = 1:numel(bands)
        cur_band = bands(b);
        cur_indx = band==cur_band;
        time_band = time(cur_indx);
        sea_level_ir_band = sea_level_ir(cur_indx);
        repeat_time = find(diff(time_band)==0);
        time_band(repeat_time) = [];
        sea_level_ir_band(repeat_time) = [];
        valid_num(b) = sum(~isnan(sea_level_ir_band));
        try
            interp_tide = interp1(time_tide,sea_level_tide,time_band,"linear");
            RMSE(b) = sqrt(nanmean((interp_tide-sea_level_ir_band).^2));
        catch
            continue
        end
    end

    if ~isempty(time_tide)
        nexttile([1,1])
        b = barh(RMSE*100,0.5, 'FaceColor',[0.3010 0.7450 0.9330],'EdgeColor',[0.3010 0.7450 0.9330],'BarWidth',0.9, 'LineWidth', 2);
        set(gca, 'YTickLabel', bands)
        if s == 4
            xlabel('RMSE(cm)')
        elseif s == 1
            %         title('RMSE', 'FontWeight','bold')
        end
        xtips1 = b(1).YEndPoints + 0.01;
        ytips1 = b(1).XEndPoints;
        rms_band = string(b(1).YData);
        text(xtips1,ytips1,rms_band,'HorizontalAlignment','right','Color',[1, 0.2, 0.2],'FontWeight','bold')
        xlim([0, max(RMSE)*100+5])
    end


    % Average daily inversion points
    nexttile([1,1])
    data = valid_num/(end_date-start_date+1);
    labels = bands;
    total = sum(data);
    h = pie(data);
    patches = findobj(h, 'Type', 'Patch');
    for i = 1:length(patches)
        set(patches(i), 'FaceColor', colors(i,:), 'EdgeColor', 'none');
    end
    hText = findobj(h, 'Type', 'text');
    for i = 1:length(data)
        hText(i).String = [labels{i}, ' (', num2str(data(i)), ')'];
    end
    hold on;
    theta = linspace(0, 2*pi, 100);
    x = 0.4 * cos(theta);
    y = 0.4 * sin(theta);
    fill(x, y, [0.99,0.99,0.99], 'EdgeColor', 'none');
    hold off;
    text(0, 0, ['Total: ', num2str(total)], 'HorizontalAlignment', 'center', 'FontSize', 12);
    if s == 1
        title('Average daily inversion points','FontWeight','bold');
    end
end
end