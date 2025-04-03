clc
clear

addpath(genpath(pwd));

%% rgp_ign
station_name = 'scoa';
ISO_short = 'FRA';
st = '2023-01-01';
et = '2023-01-05';
target_dir = [pwd,'\examples\data\RINEX\SCOA'];
get_from_rgp_ign(station_name, ISO_short, st, et, target_dir)

%% sonel
station_name = 'sc02';
ISO_short = 'FRA';
st = '2023-01-14';
et = '2023-01-20';
Rinex_version = "RINEX2";
target_dir = ['G:\GNSS-IR_data\RINEX\Water_level\',station_name,'\2023'];
get_from_sonel(station_name, ISO_short, st, et, target_dir, Rinex_version)

%% earthscope
station_name = 'at01';
ISO_short = 'USA';
st = '2023-01-14';
et = '2023-01-20';
Rinex_version = "RINEX3";
target_dir = ['G:\GNSS-IR_data\RINEX\Water_level\',station_name,'\2023'];
api_key = []; % inter yours
get_from_earthsope(station_name, ISO_short, st, et, target_dir, Rinex_version, api_key)