clc
clear

%% Settings
% file settings
settings.Station_info_file = 'E:\GMR-Water\examples\data\station_info\brst_info.mat';
settings.Rinex_path        = 'G:\GNSS-IR_data\RINEX\Water_level\BRST\2023';
settings.Rinex_version     = '3';
settings.Rinex_dt          = 30;
settings.Eph_path          = 'G:\GNSS-IR_data\Orbit\COD\2023';
settings.AC                = "CODE";
settings.Time              = [datetime(2023, 1, 1, 'Format', 'yyyy-MM-dd'),...
    datetime(2023, 1, 6, 'Format', 'yyyy-MM-dd')];
settings.Out_path          = 'G:\GNSS-IR_data\Solutions\water level\BRST\2023';
settings.station_name      = 'BRST';

% Inversion settings
settings.methods = [1,0,1,1,1];

% process flow
settings.flow = [0 0 1 1];
settings.par  = 'None';

if settings.flow(4)
    % tide settings
    settings.Tide_available = 1;
    settings.tide_file = 'E:\GMR-Water\examples\data\tide_data\brst_tide_data_2023.mat';

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
    settings.results = 'G:\GNSS-IR_data\Solutions\water level\BRST\2023\Analysis_Results';

end

%% Main
GMR_Water(settings)