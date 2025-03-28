clc
clear
%% 
% station_code = 'barn'; % for BUR2 GNSS
% station_code = 'quar'; % for HKQT GNSS
% station_code = 'scoa'; % for SCOA GNSS
station_code = 'bres'; % for BRST GNSS
GNSS_code = 'brst';
% Define the base URL and parameters
base_url = sprintf(['https://www.ioc-sealevelmonitoring.org/bgraph.php?' ...
    'code=%c%c%c%c&output=tab&period=01&endtime='],station_code);
start_date = datetime(2023, 1, 2);
end_date   = datetime(2023, 12, 31);

% Define the output folder for saving data
output_folder = pwd;
if ~exist(output_folder, 'dir')
    mkdir(output_folder);
end

tide_all = [];
% Loop through each day
for date = start_date:end_date
    % Format the date as 'yyyy-mm-dd'
    date_str = datestr(date, 'yyyy-mm-dd');
    
    % Construct the full URL with the current date
    url = strcat(base_url, date_str);
    
    try
        % Read the data from the URL
        data = webread(url);

        % Extract time and values
        pattern = ['<td>(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})<\/td>' ...
            '<td>([\d.]+)<\/td>'];
        matches = regexp(data, pattern, 'tokens');
        results = vertcat(matches{:});

        tide_all = [tide_all; results];
        % Display progress
        fprintf('Downloaded data for %s\n', date_str);
    catch ME
        % Handle errors
        fprintf('Failed to download data for %s: %s\n', date_str, ME.message);
    end
end

%% Save
xaxis = datenum(datetime(cell2mat(tide_all(:,1))));
slvl  = str2double(tide_all(:,2));

% indx = slvl>10;
% slvl = slvl(~indx);
% xaxis = xaxis(~indx);
scatter(xaxis, slvl, 'black','+')
save([GNSS_code,'_tide_data_2023.mat'],"xaxis","slvl");