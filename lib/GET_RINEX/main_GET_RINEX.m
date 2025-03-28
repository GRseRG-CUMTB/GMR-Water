clc
clear

addpath(genpath(pwd));

%% rgp_ign
station_name = 'brst';
ISO_short = 'FRA';
st = '2023-01-01';
et = '2023-12-31';
target_dir = [pwd,'\data\BRST\2023'];
get_from_rgp_ign(station_name, ISO_short, st, et, target_dir, 'p8')

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
api_key = ['eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Im80WDNMM1p0QkN6MmZ5RktMVW9mWiJ9.' ...
        'eyJpc3MiOiJodHRwczovL2xvZ2luLmVhcnRoc2NvcGUub3JnLyIsInN1YiI6ImF1dGgwfDY0YWZjMmFlMzc5' ...
        'NGEyNzQyMmRlOWFlMSIsImF1ZCI6WyJodHRwczovL2FjY291bnQuZWFydGhzY29wZS5vcmciLCJodHRwczov' ...
        'L2VhcnRoc2NvcGUtcHJvZC51cy5hdXRoMC5jb20vdXNlcmluZm8iXSwiaWF0IjoxNzM2OTQ4NzU0LCJleHAi' ...
        'OjE3MzY5Nzc1NTQsInNjb3BlIjoib3BlbmlkIHByb2ZpbGUgZW1haWwgb2ZmbGluZV9hY2Nlc3MiLCJhenAi' ...
        'OiJqTXhRYmJLUEVzeldYMGE5M0FHbEJaWjhybjkxN29jeCIsInBlcm1pc3Npb25zIjpbXX0.fCofwX06TunC' ...
        'OXeDrXZ45hip2xNS52EC1zGFwcUYexm_woaceMHJGhj-PFsR9BNwfug10y-4vq1ybpPiP2k2-65aPzZJ_Lb' ...
        'imfBAX3EnUIlpuioLDoesAut_JJ2uumDBBRoBA4gQnzJRgYXzzralNVPu6qQ6Kytb8x2UNojyMibIxvjqq_' ...
        'ixR0GZHU6UDYc71QsWm9Nnr-vGi0vJ8cE9fZHpfLABcbEgOFJs76u-Ic_ZBOTr9z3zgwkAuNLmHAMvwh9E5' ...
        '0wBcfRoLZSBPtyaSFmBqmeGCLBmUF6DU2-8fEklXTz8oEr5Aj0l45A60Ny3iVGBz82-jAC9ypUkIijdLw'];
get_from_earthsope(station_name, ISO_short, st, et, target_dir, Rinex_version, api_key)