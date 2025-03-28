function InverseModelingCallback(app)
try
    app.RunningstateLamp.Color = 'g';
    drawnow

    global Operation_settings

    startdate = datenum(Operation_settings.time(1));
    enddate   = datenum(Operation_settings.time(2));

    snrdir = app.path_SNR_data.Value;
    outdir = app.inverse_analysis_result_path.Value;

    % for window
    kspac = app.kspac_hours.Value/24; % in days
    tlen  = app.tlen_hours.Value/24;  % in days


    tdatenum = startdate - tlen/3;
    while round(tdatenum, 10, 'significant') < round(enddate+1 - tlen/3, 10, 'significant')
        tdatenum = tdatenum + tlen/3;

        [sfacsjs,sfacspre,hinit,xinit,consts_out,roughout] = inversemodel(app, tdatenum,...
            snrdir,kspac,tlen);

        if exist(outdir)==0 % create output dir
            mkdir(outdir);
        end
        % saving results
        save([outdir,'/',num2str(round(tdatenum,10,'significant')),'.mat'],'sfacsjs','sfacspre','hinit','xinit','consts_out','roughout')

    end

    % finish
    app.RunningstateLamp.Color = 'r';
    fig = app.UIFigure;
    uialert(fig,'Modeling Complete!','success','Icon','success')
catch ME
    drawnow
    app.RunningstateLamp.Color = 'r';
    fig = app.UIFigure;
    uialert(fig,[ME.message,newline,'File:',ME.stack(1,:).file,newline,'Name:',...
        ME.stack(1,:).name,newline,'Line:',num2str(ME.stack(1,:).line)],'warning')
    return

end
end