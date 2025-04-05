function GMR_Water(varargin)
%% settings Structure Documentation
% git push -u origin develop

% settings
%     .Station_info_file
%       string - Path to the station information file (.mat format).
%       Example: 'E:\GMR-water\examples\data\station_info\scoa_info.mat'
% 
%     .Rinex_path
%       string - Path to RINEX observation data folder.
%       Example: 'E:\GMR-water\examples\data\RINEX\SCOA'
% 
%     .Rinex_version
%       string - Version of the RINEX files. Supported version: Rinex 2.x / Rinex 3.x.
%       Example: '3'
% 
%     .Rinex_dt
%       numeric - Time interval of observation data (unit: seconds).
%       Example: 30 (30-second sampling rate)
% 
%     .Eph_path
%       string - Path to precise ephemeris folder (SP3 files).
%       Example: 'E:\GMR-water\examples\data\sp3\COD'
% 
%     .AC
%       string - Analysis center name for ephemeris data. Supported AC: CODE / GFZ.
%       Example: "CODE"
% 
%     .Time
%       datetime array - Time range for data processing.
%       Format: [start_time, end_time].
%       Example: [datetime(2023, 1, 1, 'Format', 'yyyy-MM-dd'), datetime(2023, 1, 3, 'Format', 'yyyy-MM-dd')]
% 
%     .Out_path
%       string - Output directory for processing results.
%       Example: 'E:\GMR-water\examples\results\Batch_result'
% 
%     .station_name
%       string - Name of the station (used for labeling results).
%       Example: 'SCOA'
% 
%     .methods
%       numeric array - Flags to enable/disable inversion methods.
%       Each position in the array corresponds to a specific method (1 = enabled, 0 = disabled).
%       Example: [1,1,1,1,1] (all methods enabled: Spectral analysis & Inverse modeling & Carrier phase & Pseudo range & Carrier phase and pseudo range)
% 
%     .flow
%       numeric array - Flags to control processing steps (1 = enabled, 0 = disabled).
%       Example: [1 1 1 1] (all steps enabled: RINEX_info_EXTRCATION, Inverse_RH, Tidal_correction & save, Analysis & genReport)
% 
%     .par
%       string - Parallel computing option.
%       Options: 'None' (disable) or '2' '4' '6' '8' (enable, Number of parallel).
% %%%%%%%%%%%%%%%%%%%%%%%  Above is need for retrieval  %%%%%%%%%%%%%%%%%%%
%     % settings
%     .Tide_available
%       numeric - Tide data availability flag (0=disable, 1=enable tide data).
%       Example: 1
% 
%     .tide_file
%       string - Full path to tide data file (.mat format).
%       Example: 'E:\GMR_Water\examples\data\tide_data\scoa_tide_data_2023.mat'
% 
%     .efps
%       cell array of strings - excluded frequency points
%       Supported options: {'S2W','S8Q'} representing different frequency points.
%       Example: {'S2W'}
% 
%     .sigma
%       numeric - Quality control threshold in standard deviations for outlier removal.
%       Example: 1
% 
%     .rrs
%       numeric - robust regression strategy (0=disable, 1=enable).
%       Example: 1
% 
%     .bspline
%       numeric - B-spline strategy (0=disable, 1=enable).
%       Example: 1
% 
%     .cor
%       numeric - Correlation visualization flag (0=hide, 1=show correlation plots).
%       Example: 1
% 
%     .day_num
%       numeric - display daily number (0=disable, 1=enable).
%       Example: 1 
% 
%     .results
%       string - Output directory path for analysis results.
%       Example: 'E:\GMR-water\examples\results\analysis_results'
% %%%%%%%%%%%%%%%%%%%%%%%  Above is need for analysis  %%%%%%%%%%%%%%%%%%%%
%--------------------------------------------------------------------------
addpath(genpath(pwd))
%% Retrieval
if nargin < 1  % example for SCOA
    
    % file settings
    settings.Station_info_file = [pwd,'\examples\data\station_info\scoa_info.mat'];
    settings.Rinex_path        = [pwd,'\examples\data\RINEX\SCOA'];
    settings.Rinex_version     = '3';
    settings.Rinex_dt          = 30;
    settings.Eph_path          = [pwd,'\examples\data\sp3\COD'];
    settings.AC                = "CODE";
    settings.Time              = [datetime(2023, 1, 1, 'Format', 'yyyy-MM-dd'),...
        datetime(2023, 1, 5, 'Format', 'yyyy-MM-dd')];
    settings.Out_path          = [pwd,'\examples\results\Batch_result'];
    settings.station_name      = 'SCOA';

    % Inversion settings
    settings.methods = [1,0,0,0,0];

    % process flow
    settings.flow = [0 0 1 1];
    settings.par  = 'None';

    % download rinex file
    files = dir(settings.Rinex_path);
    files = files(~ismember({files.name}, {'.', '..'}));
    if isempty(files)
        station_name = 'scoa';
        ISO_short = 'FRA';
        st = settings.Time(1);
        et = settings.Time(2);
        get_from_rgp_ign(station_name, ISO_short, st, et, settings.Rinex_path)
    end

    % download eph
    files = dir(settings.Eph_path);
    files = files(~ismember({files.name}, {'.', '..'}));
    if isempty(files)
        f = figure;
        get_sp3(f, settings.Time(1), settings.Time(2), settings.AC, settings.Eph_path)
        close all
    end

elseif nargin == 1
    settings = varargin{1};
end

tic
settings = main_batch(settings);
t_total = toc;
disp(['Retrieval takes ',num2str(t_total), 'seconds.'])

%% Analysis
if settings.flow(4)
    if nargin < 1
        % tide settings
        settings.Tide_available = 1;
        settings.tide_file = [pwd, '\examples\data\tide_data\scoa_tide_data_2023.mat'];

        % qc settings
        settings.efps = {'S2W'};
        settings.sigma = 1;

        % combination settings
        settings.rrs = 1;
        settings.bspline = 1;

        % display settings
        settings.cor = 1;
        % settings.azi = 0;
        settings.day_num = 1;

        % results settings
        settings.results = [pwd,'\examples\results\analysis_results\inverse'];
    end

    tic
    main_analysis(settings)
    t_total = toc;
    disp(['Analysis takes ',num2str(t_total), 'seconds.'])
    genReport(settings, [1,1])
end
close all
disp('GMR_Water has done')