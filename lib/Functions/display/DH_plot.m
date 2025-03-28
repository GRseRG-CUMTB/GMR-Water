function DH_plot(ir_h, ir_t, tide_h, tide_t)
figure
global Operation_settings
startdate = datenum(Operation_settings.time(1));
enddate = datenum(Operation_settings.time(2));
time_indx = tide_t>=startdate & tide_t<=enddate+1;
tide_h = tide_h(time_indx);
tide_t = tide_t(time_indx);

ir_all = [ir_t, ir_h];
ir_all = sortrows(ir_all);
ir_t = ir_all(:,1);
ir_h = ir_all(:,2);
repeat_time = find(diff(ir_t)==0);
ir_t(repeat_time) = [];
ir_h(repeat_time) = [];
interp_ir = interp1(ir_t ,ir_h, tide_t,"linear");

[~,TFrm] = rmoutliers(interp_ir,"movmedian",100);
interp_ir(TFrm) = nan;

valid_indx = ~isnan(interp_ir) & ~isnan(tide_h);
DIF = interp_ir(valid_indx)-tide_h(valid_indx);

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
title('Residual histogram')
hold off
end