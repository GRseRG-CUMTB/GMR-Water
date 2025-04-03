function varargout = main_batch(settings)

%% Settings
start_time   = settings.Time(1);
end_time     = settings.Time(2);
start_date   = datenum(start_time);
end_date     = datenum(end_time);

%% file preparation
load(settings.Station_info_file)

% extract SNR & carrier pseudorange from rinex
if settings.flow(1)
    tic
    disp('-----------------------------STAR RINEX INFO EXTRCATION-----------------------------')
    RINEX_info_EXTRCATION
    disp('---------------------------RINEX INFO EXTRCATION COMPLETED--------------------------')
    toc
end

% Inverse
if settings.flow(2)
    tic
    disp('------------------------------------STAR INVERSE------------------------------------')
    genMethodsSettings
    Inverse_RH
    delete('MethodsSettings.mat')
    disp('----------------------------------INVERSE COMPLETED---------------------------------')
    toc
end

% Tidal correction & save
if settings.flow(3)
    tic
    disp('------------------------------TIDAL CORRECTION & SAVE-------------------------------')
    clear RH_info
    start_date = datenum(start_time);
    end_date   = datenum(end_time);
    RH_path = [settings.Out_path, '/RH_file/'];
    RH_info_all = cell(1, end_date+1-start_date);
    i = 0;
    for tdatenum = start_date:end_date
        curdt = datetime(tdatenum,'ConvertFrom','datenum');
        RH_file = [RH_path,settings.station_name,num2str(tdatenum),'RH_info.mat'];
        RH_file = load(RH_file);   RH_info = RH_file.RH_info;
        i = i+1;
        RH_info_all{i} = RH_info;
    end
    RH_info_all = vertcat(RH_info_all{:});
    RH_info_all = sortrows(RH_info_all,"Time");
    RH_info_all(isnan(RH_info_all.RH),:) = [];


    
    [~, RH_info_all, ~] = Tidal_correction(RH_info_all, sta_lat, sta_asl, tide_range);
    
    band = RH_info_all.BAND;
    fp_all = unique(RH_info_all.System+band);
    for fp = 1:numel(fp_all)
        cur_sysband = fp_all(fp);
        RH_fp = RH_info_all(RH_info_all.System+band == cur_sysband,:);

        Final_info.(cur_sysband) = RH_fp;
    end


    carrierStruct = struct();
    pseudorangeStruct = struct();
    cpStruct = struct();
    snrStruct = struct();
    fields = fieldnames(Final_info);
    for i = 1:length(fields)
        field = fields{i};
        if endsWith(field, 'Carrier')
            carrierStruct.(field) = Final_info.(field);
        elseif endsWith(field, 'Pseudorange')
            pseudorangeStruct.(field) = Final_info.(field);
        elseif contains(field, 'CP')
            cpStruct.(field) = Final_info.(field);
        else
            snrStruct.(field) = Final_info.(field);
        end
    end

    %% Save the final file
    settings.filenumber = 0;
    settings.Final_files = {};
    for m = 1:5
        if settings.methods(m)
            if m < 3
                Base = 'SNR';
            else
                Base = 'OBS';
            end
            if m == 1
                meth = 'Spectral';
                data = snrStruct;
            elseif m == 3
                meth = 'Carrier';
                data = carrierStruct;
            elseif m == 4
                meth = 'Pseudorange';
                data = pseudorangeStruct;
            elseif m == 5
                meth = 'CP';
                data = cpStruct;
            end

            final_file_name = [settings.Out_path,'/Final_file/',settings.station_name,'_',...
                char(start_time),'_',char(end_time),'_',Base,'-',meth,'.mat'];
            if ~exist([settings.Out_path,'/Final_file'],"dir")
                mkdir([settings.Out_path,'/Final_file'])
            end
            parsave(final_file_name, data,"Final_info")

            if nargout > 0
                settings.filenumber = settings.filenumber + 1;
                settings.Final_files{settings.filenumber} = [settings.station_name,'_',...
                char(start_time),'_',char(end_time),'_',Base,'-',meth,'.mat'];
            end
        end
    end
    if nargout > 0
        settings.Final_path = [settings.Out_path,'/Final_file'];
        settings.station_name = station_name;
        settings.antenna_height = sta_asl;

        varargout = {settings};
    end
end
disp('---------------------------------------SAVED!!!-------------------------------------')
toc
end