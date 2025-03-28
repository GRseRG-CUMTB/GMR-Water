function ObsChooseCallback(app)
[fileNames, filepath] = uigetfile('data/*.*', 'Choose RINEX files:', 'MultiSelect', 'on');

if isequal(fileNames, 0)
    return;
end
fileNames = cellstr(fileNames);
fig = app.UIFigure;

fileCount = 0;
fileCount = fileCount + length(fileNames);
app.obsfilenumber.Text = sprintf('Selected：%d files', fileCount);
app.observation.Value = filepath;
date_is = 1;
if fileCount == 1
    % filenames
    app.obsfilename.Value = fileNames;
    % rinex version
    fileNames_char = cell2mat(fileNames);
    fileID = fopen(strcat(filepath,'\',fileNames_char), 'r');
    data = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    for i = 1:length(data{1})
        line = data{1}{i};
        if endsWith(line, 'RINEX VERSION / TYPE')
            ver = line(1:9);
        elseif endsWith(line, 'INTERVAL            ')
            app.dt.Value = line(1:2);
        end
    end
    if str2double(ver) >= 3
        app.rinex_version.Value = 'rinex 3';
    elseif str2double(ver) >= 2 && str2double(ver) < 3
        app.rinex_version.Value = 'rinex 2';
    else
        uialert(fig,'Cannot automatically read rinex version please manually select version and date!' ...
            ,'Warning','Icon','warning');
        date_is = 0;
    end

    % datetime
    if date_is == 1
        if app.rinex_version.Value == 'rinex 3'
            doy_str = fileNames_char(17:19);
            year_str = fileNames_char(13:16);
            start_date = datetime(str2double(year_str),1,str2double(doy_str));
            end_date = start_date;
        elseif app.rinex_version.Value == 'rinex 2'
            doy_str = fileNames_char(5:7);
            year_str = strcat('20',fileNames_char(10:11));
            start_date = datetime(str2double(year_str),1,str2double(doy_str));
            end_date = start_date;
        end
        app.starttime.Value = start_date;
        app.endtime.Value = end_date;
    end
else % multiple files
    app. obsfilename.Value = fileNames';
    % rinex version
    fileNames_char = cell2mat(fileNames(1));
    fileID = fopen(strcat(filepath,'\',fileNames_char), 'r');
    data = textscan(fileID, '%s', 'Delimiter', '\n');
    fclose(fileID);
    for i = 1:length(data{1})
        line = data{1}{i};
        if endsWith(line, 'RINEX VERSION / TYPE')
            ver = line(1:9);
        elseif endsWith(line, 'INTERVAL            ')
            app.dt.Value = line(1:2);
        end
    end
    if str2double(ver) >= 3
        app.rinex_version.Value = 'rinex 3';
    elseif str2double(ver) >= 2 && str2double(ver) < 3
        app.rinex_version.Value = 'rinex 2';
    else
        uialert(fig,'Cannot automatically read rinex version please manually select version and date!', ...
            'Warning','Icon','warning');
        date_is = 0;
    end
    % datetime
    if date_is == 1
        fileNames_char = cell2mat(fileNames');
        for days = 1:fileCount
            if app.rinex_version.Value == 'rinex 3'
                fileNames_day = fileNames_char(days,:);
                doy_str = fileNames_day(17:19);
                year_str = fileNames_day(13:16);
                date(days) = datetime(str2double(year_str),1,str2double(doy_str));
            elseif app.rinex_version.Value == 'rinex 2'
                fileNames_day = fileNames_char(days,:);
                doy_str = fileNames_day(5:7);
                year_str = strcat('20',fileNames_day(10:11));
                date(days) = datetime(str2double(year_str),1,str2double(doy_str));

            end
        end
        date = sort(date,'ascend');
        start_date = date(1);
        end_date = date(end);
        app.starttime.Value = start_date;
        app.endtime.Value = end_date;
    end
end
end