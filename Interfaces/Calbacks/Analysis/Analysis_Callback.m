function Analysis_Callback(app)
% tide settings
settings.Tide_available = app.TideFileCheckBox.Value;
settings.tide_file = app.TidefileEditField.Value;
% final file settings
settings.filenumber = app.FilenumberEditField.Value;
settings.Final_path = app.FilepathEditField.Value;
settings.Final_files= app.FinalFileListTextArea.Value;
% station settings
settings.station_name = app.StationnameEditField.Value;
settings.antenna_height = app.ASLmEditField.Value;
% qc settings
settings.efps = app.ExcludedfrequencypointsTextArea.Value;
settings.sigma = app.sigmadenoisingCheckBox.Value;
% combination settings
settings.rrs = app.RobustregressionstrategyCheckBox.Value;
settings.bspline = app.BsplineCheckBox.Value;
% display settings
settings.cor = app.CorrelationscatterCheckBox.Value;
% settings.azi = app.AzimuthCheckCheckBox.Value;
settings.day_num = app.DailyNumberCheckBox.Value;
% results settings
settings.results = app.AnalysisResultsEditField.Value;

main_analysis(settings)
end
