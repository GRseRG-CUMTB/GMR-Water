function SpectralCallBack(app)
global Operation_settings

time = Operation_settings.time;

stations = Operation_settings.station_name;
% trop
if string(app.trop.Value) == "None"
    tropd = 0;
elseif string(app.trop.Value) == "Williams"
    tropd = 1;
elseif string(app.trop.Value) == "Santamaria-Gomez"
    tropd = 2;
end

startdate = datenum(time(1));
enddate = datenum(time(2));
decimate = app.decimates.Value;
tdatenum = startdate-1;
slvlr_all = zeros(0,20);
if string(app.ispic.Value) == "Yes"
    tempsnr = 1;
    templsp = 1;
else
    tempsnr = 0;
    templsp = 0;
end
if string(app.fresnel_kml.Value) == "Yes"
    fresout=[pwd,'\results\fresnel_kml\'];
    if isfolder(fresout)
        files = dir(fullfile(fresout, '*'));
        files = files(~[files.isdir]);

        for i = 1:length(files)
            delete(fullfile(fresout, files(i).name));
        end
    end
end
% axes setting
children = app.LSP_result.Children;
delete(children);
children = app.SNRPanel.Children;
delete(children);
if string(app.ispic.Value) == "Yes"
    axes_dsnr = axes(app.SNRPanel);
    axes_lsp = axes(app.LSP_result);
else
    axes_dsnr = [];
    axes_lsp = [];
end



totalIterations = (enddate-startdate+1) * 4;
currentIteration  = 0;
while tdatenum < enddate
    tdatenum = tdatenum+1;
    % LOAD SNR DATA
    curdt = datetime(tdatenum,'convertfrom','datenum');
    disp(char(curdt))
    load([app.path_SNR_data.Value, '\', stations, num2str(tdatenum),'.mat'])
    snrfile = snr_data;

    for sys = 1:4
        if sys == 1
            if isfield(snr_data,'GPS')
                system = snr_data.GPS;
                gnss_system = "GPS";
            else
                continue
            end
        elseif sys == 2
            if isfield(snr_data,'GLONASS')
                system = snr_data.GLONASS;
                gnss_system = "GLONASS";
            else
                continue
            end

        elseif sys == 3
            if isfield(snr_data,'GALILEO')
                system = snr_data.GALILEO;
                gnss_system = "GALILEO";
            else
                continue
            end

        elseif sys == 4
            if isfield(snr_data,'BDS')
                system = snr_data.BDS;
                gnss_system = "BDS";
            else
                continue
            end

        end
        band_num = size(system.Properties.VariableNames);

        for l = 1:band_num(2)-4
            band = system.Properties.VariableNames(l+4);
            [hang,~] = size(system);
            nan_all = nan(hang ,2);
            snrfile = [table2array(system(:,1)),table2array(system(:,4)),table2array(system(:,3)),table2array(system(:,2)),nan_all,table2array(system(:,band))];

            [slvlr,lspy] = analyzesnr_fun(app,snrfile,tdatenum,tropd,decimate,...
                tempsnr,templsp,axes_dsnr,axes_lsp,gnss_system,cell2mat(band));
            sizes = size(slvlr);
            if sizes(1) ~= 0

                scatter(app.UIAxes,slvlr(:,1),slvlr(:,7),'filled')
                legend(app.UIAxes, cell2mat(band))
                datetick(app.UIAxes,'x','dd-mmm-yyyy')
                xlim(app.UIAxes,[datenum(time(1)) datenum(time(2)+1)])

            end
            slvlr_all = [slvlr_all; slvlr];
        end
        currentIteration = currentIteration+1;
        drawProgressBar(app, currentIteration/totalIterations);
    end
end
% now save the output
save([app.analysis_result_path.Value,'/',num2str(tdatenum),'.mat'],'slvlr','lspy')
slvlr_all = [slvlr_all;slvlr];

drawProgressBar(app, (tdatenum-startdate+1)/(enddate-startdate+1));


Time = datetime(slvlr_all(:,1),'ConvertFrom','datenum');
GNSS = char(slvlr_all(:,14));
Band = char(slvlr_all(:,11:13));
app.analysis_result.Data = horzcat(table(Time,GNSS,Band),array2table(slvlr_all(:,2:10))); % display the result
save([app.analysis_result_path.Value,'/',num2str(tdatenum),'slvlr_all.mat'],'slvlr_all')

disp("end")
end