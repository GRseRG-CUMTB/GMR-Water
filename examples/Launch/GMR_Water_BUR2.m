clc
clear

%% Settings
% file settings
settings.Station_info_file = 'E:\GMR-Water\examples\data\station_info\bur2_info.mat';
settings.Rinex_path        = 'G:\GNSS-IR_data\RINEX\Water_level\BUR2\2023';
settings.Rinex_version     = '3';
settings.Rinex_dt          = 30;
settings.Eph_path          = 'G:\GNSS-IR_data\Orbit\COD\2023';
settings.AC                = "CODE";
settings.Time              = [datetime(2023, 1, 1, 'Format', 'yyyy-MM-dd'),...
    datetime(2023, 1, 3, 'Format', 'yyyy-MM-dd')];
settings.Out_path          = 'G:\GNSS-IR_data\Solutions\water level\BUR2\2023';
settings.station_name      = 'BUR2';

% Inversion settings
settings.methods = [1,0,0,0,0];

% process flow
settings.flow = [0 1 1 1];
settings.par  = 'None';

if settings.flow(4)
    % tide settings
    settings.Tide_available = 1;
    settings.tide_file = 'E:\GMR-Water\examples\data\tide_data\bur2_tide_data_2023.mat';

    % qc settings
    settings.efps = {'S1W'};
    settings.sigma = 1;

    % combination settings
    settings.rrs = 1;
    settings.bspline = 0;

    % display settings
    settings.cor = 0;
    settings.azi = 0;
    settings.day_num = 1;

    % results settings
    settings.results = 'G:\GNSS-IR_data\Solutions\water level\BUR2\2023\Analysis_Results';

end

%% Main
GMR_Water(settings)