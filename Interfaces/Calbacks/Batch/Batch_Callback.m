function Batch_Callback(app)
% file settings
settings.Station_info_file = app.StationfileEditField.Value;
settings.Rinex_path        = app.RinexpathEditField.Value;
settings.Rinex_version     = app.RinexversionDropDown.Value;
settings.Rinex_dt          = app.IntervalsEditField.Value;
settings.Eph_path          = app.EphemerispathEditField.Value;
settings.AC                = string(app.ACDropDown.Value);
settings.Time              = [app.StartdateDatePicker.Value, app.EnddateDatePicker.Value];
settings.Out_path          = app.OutputpathEditField.Value;
settings.station_name      = app.StationnameEditField.Value;

% Inversion settings
settings.methods = [app.SpectralanalysisCheckBox.Value app.InversemodelingCheckBox.Value ...
    app.CarrierphaseCheckBox.Value app.pseudorangeCheckBox.Value app.CarrierphasepseudorangeCheckBox.Value];

% process flow
settings.flow = [app.RINEXinfoEXTRCATIONCheckBox.Value app.InverseReflectionheightCheckBox.Value ...
    app.TidalcorrectionOutputFinalfileCheckBox.Value];
settings.par  = app.ParallelnumberDropDown.Value;

main_batch(settings)
end