function cor_scatter(ir_h, ir_t, tide_h, tide_t)

ir_all = [ir_t, ir_h];
ir_all = sortrows(ir_all);
ir_t = ir_all(:,1);
ir_h = ir_all(:,2);
repeat_time = find(diff(ir_t)==0);
ir_t(repeat_time) = [];
ir_h(repeat_time) = [];
tide_h = interp1(tide_t ,tide_h, ir_t,"linear");

[~,TFrm] = rmoutliers(ir_h,"movmedian",20);
ir_h(TFrm) = nan;
CData = density2C(ir_h, tide_h, min(ir_h):0.01:max(ir_h), min(ir_h):0.1:max(ir_h));
scatter(ir_h, tide_h, 50, 'filled','CData',CData);
% scatter(ir_h, tide_h, 50, 'filled');
xlim([min(ir_h),max(ir_h)])
ylim([min(tide_h),max(tide_h)])
box on
hold on
x = min(ir_h):0.01:max(ir_h);
y = x;
l1 = plot(x, y, 'r--','LineWidth',2,'DisplayName','y = x');

nan_indx = isnan(ir_h) | isnan(tide_h);
p = polyfit(ir_h(~nan_indx),tide_h(~nan_indx), 1);
y_fit = p(1)*x + p(2);
l2 = plot(x, y_fit, 'Color',[0.8,0.8,0.8],'LineWidth',1.5,'DisplayName','Linear fitting');



r = corrcoef(ir_h(~nan_indx),tide_h(~nan_indx));
r_value = r(1,2);
equation = sprintf('y = %.3fx + %.3f', p(1), p(2));
text(min(ir_h)+0.05, max(tide_h)-0.05, sprintf('R = %.3f\n%s', r_value, equation), ...
    'FontSize', 12, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left','FontWeight','bold');
hold off

legend([l1,l2],{'y = x','Linear fitting'})
colorbar
set(gcf, 'Units','normalized','OuterPosition',[0.25,0.25,0.35,0.5])
end

function [CData,h,XMesh,YMesh,ZMesh,colorList] = density2C(X,Y,XList,YList,colorList)
[XMesh,YMesh] = meshgrid(XList,YList);
XYi = [XMesh(:) YMesh(:)];
F = ksdensity([X,Y],XYi);
ZMesh = zeros(size(XMesh));
ZMesh(1:length(F)) = F;

h = interp2(XMesh,YMesh,ZMesh,X,Y);
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