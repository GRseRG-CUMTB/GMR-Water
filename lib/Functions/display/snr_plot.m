function snr_plot(app, sat, band)
% plot SNR in the coordinate system
% input: sat: Three-digit identifier; eg:'G01'
%        band: Three-digit identifier; eg:'S1C'
%----------------------------------------------

global Operation_settings
date = datenum(app.display_date.Value);
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'.mat'])
load([app.path_SNR.Value, '\', Operation_settings.station_name, num2str(date),'azi.mat']);

if sat(1) == 'G'
    system = snr_azi.GPS;
    ax = app.GPS_SNR;
    arc = str2double(app.GPS_arc.Value);
elseif sat(1) == 'R'
    system = snr_azi.GLONASS;
    ax = app.GLONASS_SNR;
    arc = str2double(app.GLONASS_arc.Value);
elseif sat(1) == 'E'
    system = snr_azi.GALILEO;
    ax = app.GALILEO_SNR;
    arc = str2double(app.GALILEO_arc.Value);
elseif sat(1) == 'C'
    system = snr_azi.BDS;
    ax = app.BDS_SNR;
    arc = str2double(app.BDS_arc.Value);
end
[~,lie] = size(system);
for i = 5:lie
    if cell2mat(system.Properties.VariableNames(i)) == band
        band_number = i;
        break;
    end
end
satnum = str2double(sat(2:end));
logicals = table2array(system(:,1)) == satnum;
data = system(logicals,:);

if numel(data) == 0
    return 
end
% find the time division
data_time = data{:,2};
diff_ans = diff(data_time);
div = diff_ans>300;
divs = sum(div)+1; % arc numbers
list = string(1:divs)';

if sat(1) == 'G'
    app.GPS_arc.Items = list;
elseif sat(1) == 'R'
    app.GLONASS_arc.Items = list;
elseif sat(1) == 'E'
    app.GALILEO_arc.Items = list;
elseif sat(1) == 'C'
    app.BDS_arc.Items = list;
end

[hang,~] = size(data_time);
ind = 1;
j = 1;
for i = 1:hang-1
    data_div(j,:,ind) = table2array(data(i,1:end-1));
    j = j+1;
    if div(i) == 1
        ind = ind+1;
        j = 1;
    end
end
% plot
[~,~,arcs] = size(data_div);
if arcs < arc
    return
end
e = data_div(:,4,arc);
e(e<=0) = nan;
xmax = max(sind(e));
snr = data_div(:,band_number,arc);
snr(snr==0) = nan;
if isnan(snr)
    return
elseif  isnan(e)
    return
else
    ymax = max(snr);
    ymin = min(snr);
    if ymax == ymin
        return
    end
    plot(ax,sind(e),snr)
    hold on
    xlim(ax,[0.01,xmax])
    hold on
    ylim(ax,[ymin,ymax])

    elv_min = sind(Operation_settings.elv(1));
    elv_max = sind(Operation_settings.elv(2));
    hold on
    line(ax,[elv_min,elv_min],[ymin,ymax],'linestyle','--','Color','r', 'LineWidth', 0.7);
    hold on
    line(ax,[elv_max,elv_max],[ymin,ymax],'linestyle','--','Color','r', 'LineWidth', 0.7);
    hold off
end

end