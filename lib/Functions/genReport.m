function genReport(settings, part)
% Define the title name
titleName = ['Station ID: ',settings.station_name];

% Define table data
Name = fieldnames(settings);
tableData = strings(numel(Name),2);
for f = 1:numel(Name)
    tableData(f, 1) = string(Name{f});
    if string(Name{f}) == "Time"
        st_et = char(settings.(Name{f}));
        tableData(f, 2) = string([st_et(1,:), ' To ', st_et(2,:)]);
    elseif string(Name{f}) == "methods" | string(Name{f}) == "flow"
        tableData(f, 2) = string(num2str(settings.(Name{f})));
    elseif string(Name{f}) == "Final_files"
        file = settings.(Name{f});
        all_files = [];
        for n = 1:numel(file)
            all_files = [all_files file{n} ' & '];
        end
        tableData(f, 2) = string(all_files);
    else
        tableData(f, 2) = string(settings.(Name{f}));
    end
end
if part(2)
    visualizationImages = getPNGPaths([settings.results, '\pic']);
end

% Creat a new HTML file for report
copyfile([pwd,'\icon\LOGO.png'], settings.results)
logoImage = '.\LOGO.png';
filename = [settings.results, '\report.html'];
fileID = fopen(filename, 'w');

% Write the HTML content
fprintf(fileID, '<!DOCTYPE html>\n');
fprintf(fileID, '<html lang="en">\n');
fprintf(fileID, '<head>\n');
fprintf(fileID, '    <meta charset="UTF-8">\n');
fprintf(fileID, '    <meta name="viewport" content="width=device-width, initial-scale=1.0">\n');
fprintf(fileID, '    <title>%s</title>\n', titleName); % Insert title here
fprintf(fileID, '    <style>\n');
fprintf(fileID, '        body {\n');
fprintf(fileID, '            font-family: Arial, sans-serif;\n');
fprintf(fileID, '            background-color: #f0f8ff;\n');
fprintf(fileID, '            color: #333;\n');
fprintf(fileID, '            margin: 0;\n');
fprintf(fileID, '            padding: 0;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .container {\n');
fprintf(fileID, '            width: 90%%;\n');
fprintf(fileID, '            max-width: 2000px;\n');
fprintf(fileID, '            margin: 20px auto;\n');
fprintf(fileID, '            padding: 20px;\n');
fprintf(fileID, '            background-color: #ffffff;\n');
fprintf(fileID, '            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);\n');
fprintf(fileID, '            border-radius: 8px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .header {\n');
fprintf(fileID, '            display: flex;\n');
fprintf(fileID, '            justify-content: space-between;\n');
fprintf(fileID, '            align-items: center;\n');
fprintf(fileID, '            margin-bottom: 20px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        h1 {\n');
fprintf(fileID, '            text-align: left;\n');
fprintf(fileID, '            color: #007acc;\n');
fprintf(fileID, '            margin: 0;\n');
fprintf(fileID, '            font-size: 60px;\n');
fprintf(fileID, '            font-weight: bold;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .logo {\n');
fprintf(fileID, '            height: 80px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        table {\n');
fprintf(fileID, '            width: 100%%;\n');
fprintf(fileID, '            border-collapse: collapse;\n');
fprintf(fileID, '            margin-bottom: 20px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        table, th, td {\n');
fprintf(fileID, '            border: 1px solid #ddd;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        th, td {\n');
fprintf(fileID, '            padding: 10px;\n');
fprintf(fileID, '            text-align: left;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        th {\n');
fprintf(fileID, '            background-color: #007acc;\n');
fprintf(fileID, '            color: white;\n');
fprintf(fileID, '            font-weight: bold;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        tr:nth-child(even) {\n');
fprintf(fileID, '            background-color: #f9f9f9;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .visualization {\n');
fprintf(fileID, '            margin-bottom: 40px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .visualization h2 {\n');
fprintf(fileID, '            color: #007acc;\n');
fprintf(fileID, '            margin-bottom: 10px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '        .visualization img {\n');
fprintf(fileID, '            max-width: 100%%;\n');
fprintf(fileID, '            height: auto;\n');
fprintf(fileID, '            display: block;\n');
fprintf(fileID, '            margin: 0 auto;\n');
fprintf(fileID, '            border: 1px solid #ddd;\n');
fprintf(fileID, '            padding: 10px;\n');
fprintf(fileID, '            background-color: #fff;\n');
fprintf(fileID, '            border-radius: 8px;\n');
fprintf(fileID, '        }\n');
fprintf(fileID, '    </style>\n');
fprintf(fileID, '</head>\n');
fprintf(fileID, '<body>\n');
fprintf(fileID, '    <div class="container">\n');
fprintf(fileID, '        <div class="header">\n');
fprintf(fileID, '            <h1>%s</h1>\n', titleName); % Insert title here
fprintf(fileID, '            <img class="logo" src="%s" alt="Logo">\n', logoImage); % Insert logo here
fprintf(fileID, '        </div>\n');

% Write the table
fprintf(fileID, '        <h2>Settings</h2>\n');
fprintf(fileID, '        <table>\n');
fprintf(fileID, '            <thead>\n');
fprintf(fileID, '                <tr>\n');
fprintf(fileID, '                    <th>Field</th>\n');
fprintf(fileID, '                    <th>Value</th>\n');
fprintf(fileID, '                </tr>\n');
fprintf(fileID, '            </thead>\n');
fprintf(fileID, '            <tbody>\n');
for i = 1:size(tableData, 1)
    fprintf(fileID, '                <tr>\n');
    for j = 1:size(tableData, 2)
        fprintf(fileID, '                    <td>%s</td>\n', tableData(i, j));
    end
    fprintf(fileID, '                </tr>\n');
end
fprintf(fileID, '            </tbody>\n');
fprintf(fileID, '        </table>\n');

% Write the visualizations
for i = 1:length(visualizationImages)
    pathParts = split(visualizationImages(i,:), filesep);
    fileName = pathParts{end};
    fprintf(fileID, '        <div class="visualization">\n');
    fprintf(fileID, '            <h2>Results %d: %s</h2>\n', i, fileName);
    fprintf(fileID, '            <img src="%s" alt="Project %s Progress Chart">\n', visualizationImages(i), char('A' + i - 1));
    fprintf(fileID, '        </div>\n');
end

% Close the container and body
fprintf(fileID, '    </div>\n');
fprintf(fileID, '</body>\n');
fprintf(fileID, '</html>\n');

% Close the file
fclose(fileID);

pdfFile = [settings.results,'\report.pdf'];

system([[pwd, '/lib/Functions/wkhtmltopdf.exe'], ' --enable-local-file-access ',filename, ' ',pdfFile]);
disp('report generated successfully.');
open(filename)

function pngFiles = getPNGPaths(folderPath)
    
    folderPath = fullfile(folderPath);
    fileList = dir(fullfile(folderPath, '**', '*.png'));
    
    pngFiles = strings(size(fileList));
    for i = 1:length(fileList)
        [~, relPath] = fileparts(fileList(i).folder);
        relPath = strrep(fullfile(relPath, fileList(i).name), [folderPath filesep], '');
        pngFiles(i) = relPath;
    end
    if isempty(pngFiles)
        pngFiles = "";
    end
end

end