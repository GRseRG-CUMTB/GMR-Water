clc
clear

station_name = 'BRST';
azi_lim = [165,330];
azi_mask = [nan,nan];
elv_lim = [12,25];
% azi_lim = [130,165];
% azi_mask = [nan,nan];
% elv_lim = [5,20];

staxyz = [4231162.7790  -332746.9230  4745130.6810];
sta_lon = -4.4965976678;
sta_lat = 48.3804906896;
sta_asl = 21;
tide_range = [-2,9];
station_belong = 'FRA';