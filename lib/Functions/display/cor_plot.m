function cor_plot(ir_h, ir_t, tide_h, tide_t)
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

[~,TFrm] = rmoutliers(interp_ir,"movmedian",20);
interp_ir(TFrm) = nan;
CData = density2C(interp_ir,tide_h,min(tide_h):0.01:max(tide_h),min(tide_h):0.1:max(tide_h));
set(gcf,'Color',[1 1 1]);
scatter(interp_ir,tide_h,50,'filled','CData',CData);
xlim([min(tide_h),max(tide_h)])
ylim([min(tide_h),max(tide_h)])
box on
hold on
x = min(tide_h):0.01:max(tide_h);
y = x;
plot(x, y, 'r--','LineWidth',3);

nan_indx = isnan(interp_ir) | isnan(tide_h);
p = polyfit(interp_ir(~nan_indx),tide_h(~nan_indx), 1);
y_fit = p(1)*x + p(2);
plot(x, y_fit, 'r');

r = corrcoef(interp_ir(~nan_indx),tide_h(~nan_indx));
r_value = r(1,2);
text(min(tide_h)+0.1,max(tide_h)-0.1, ['r = ', num2str(r_value)]);
colorbar

xlabel('GNSS-IR Inversion(m)')
ylabel('Tide guage(m)')
title('Correlation diagram')
hold off
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