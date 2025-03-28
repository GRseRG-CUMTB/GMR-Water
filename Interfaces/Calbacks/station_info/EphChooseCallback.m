function EphChooseCallback(app)
[fileNames, filepath] = uigetfile('data/sp3/*.*', 'Select the ephemeris file' ...
    , 'MultiSelect', 'on');

if isequal(fileNames, 0)
    return;
end

fileNames = cellstr(fileNames);
fileCount = 0;
fileCount = fileCount + length(fileNames);
app.sp3filenumber.Text = sprintf('Seleted：%d files', fileCount);
app.sp3.Value = filepath;
if fileCount == 1
    app.sp3filename.Value = fileNames;
    filenames_char = cell2mat(fileNames);
    app.sp3_type.Value = filenames_char(1:3);
else
    app. sp3filename.Value = fileNames';
    filenames_char = cell2mat(fileNames(1));
    app.sp3_type.Value = filenames_char(1:3);
end
end