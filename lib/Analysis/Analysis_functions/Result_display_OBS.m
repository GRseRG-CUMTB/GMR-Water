function Result_display_OBS(RH_info_all, settings, time_tide, sea_level_tide, end_date, start_date, colors)
sys        = unique(RH_info_all.System);
figure
tiledlayout(6,6,"TileSpacing","compact")
set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
for s = 1:numel(sys)
    cur_sys = sys(s);
    cur_info = RH_info_all(RH_info_all.System==cur_sys,:);

    time = cur_info.Time;
    ir_h = settings.antenna_height - cur_info.RH;
    nexttile((s-1)*12+1, [2,5])
    scatter(time, ir_h, 'red','filled', DisplayName=strcat(cur_sys," retrieval"))
    hold on
    plot(time_tide,sea_level_tide,'black','LineWidth',1,'DisplayName', 'Tide gauge')
    if s == numel(sys)
        xlabel('Time','FontWeight','bold')
    else
        set(gca,'XTickLabel',[])
    end
    ylabel('Sea level (m)', 'FontWeight','bold')
    xlim([min(time), max(time)+1])
    box on
    legend
    hold off

    interp_tide = interp1(time_tide,sea_level_tide,time,"linear");
    RMSE(s) = sqrt(nanmean((interp_tide-ir_h).^2));
    valid_num(s) = sum(~isnan(ir_h));
end

% RMSE
nexttile(18,[2,1])
b = barh(RMSE*100,0.5, 'FaceColor',[0.3010 0.7450 0.9330],'EdgeColor',[0.3010 0.7450 0.9330],'BarWidth',0.9, 'LineWidth', 2);
set(gca, 'YTickLabel', sys)
xlabel('RMSE(cm)','FontWeight','bold')
xtips1 = b(1).YEndPoints + 0.01;
ytips1 = b(1).XEndPoints;
rms_band = string(b(1).YData);
text(xtips1,ytips1,rms_band,'HorizontalAlignment','right','Color',[1, 0.2, 0.2],'FontWeight','bold')
xlim([0, max(RMSE)*100+5])

% Average daily inversion points
nexttile(6,[2,1])
data = valid_num/(end_date-start_date+1);
labels = sys;
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
fill(x, y, 'w', 'EdgeColor', 'none');
hold off;
text(0, 0, ['Total: ', num2str(total)], 'HorizontalAlignment', 'center', 'FontSize', 12);
title('Average daily inversion points','FontWeight','bold');

% cor_scatter
nexttile(30,[2,1])
ir_t = RH_info_all{:,"Time"};
ir_h = settings.antenna_height - RH_info_all{:,"RH"};

cor_scatter(ir_h, datenum(ir_t), sea_level_tide, datenum(time_tide))
ylabel('Tide gauge (m)')
xlabel('GNSS-IR raw inversion value (m)')
end