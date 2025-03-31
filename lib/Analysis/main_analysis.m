function main_analysis(settings)

% set tides data
Tide_available = settings.Tide_available;
if Tide_available
    tide_file = settings.tide_file;
    Tide = load(tide_file);
    tide = [Tide.xaxis, Tide.slvl];
    [~, idx] = unique(tide(:,1), 'stable');
    tide = tide(idx, :);
    xaxis = tide(:,1);
    slvl  = tide(:,2);
end
% clear output dir
fileList = dir(fullfile(settings.results, '*.*'));
for i = 1:length(fileList)
    if ~fileList(i).isdir
        delete(fullfile(settings.results, fileList(i).name));
    elseif string(fileList(i).name) ~= "." & string(fileList(i).name) ~= ".."
        rmdir(fullfile(settings.results, fileList(i).name),'s')
    end
end

% set Final file
Final_path = settings.Final_path;
Final_files= settings.Final_files;
% loop by files
for f = 1 : settings.filenumber
    %% Load file & get information
    % get time from file name
    file_info = strsplit(Final_files{f},'_');
    start_date = datenum(file_info{2});
    end_date   = datenum(file_info{3});

    % get RH_info_all
    if string(file_info{4}) == "SNR-Inverse.mat"
        FF = load(fullfile(Final_path,Final_files{f}));
        RH_info_all = FF.Final_info;
        RH_info_all(isnan(RH_info_all{:,"RH_Inverse"}),:) = [];
    else
        FF = load(fullfile(Final_path,Final_files{f}));
        Final_info = FF.Final_info;
        fieldNames = fieldnames(Final_info);
        RH_info_all = [];
        for i = 1:length(fieldNames)
            currentTable = Final_info.(fieldNames{i});
            RH_info_all = [RH_info_all; currentTable];
        end
    end
    if isempty(RH_info_all)
        continue
    end

    if Tide_available
        % get tide info
        tide_indx = xaxis>=start_date & xaxis<=end_date+1;
        time_tide_raw = datetime(xaxis(tide_indx),'ConvertFrom','datenum');
        % time_tide = datetime(xaxis(tide_indx),'ConvertFrom','datenum');
        sea_level_tide = slvl(tide_indx);

        % interp
        time_tide = datetime(start_date,'ConvertFrom','datenum'):hours(1):datetime(end_date+1,'ConvertFrom','datenum');
        tide = [datenum(time_tide_raw) sea_level_tide];
        [~, idx] = unique(tide(:,1), 'stable');
        tide = tide(idx, :);
        xaxis = tide(:,1);
        slvl  = tide(:,2);
        sea_level_tide = interp1(datetime(xaxis,'ConvertFrom','datenum'), slvl, time_tide);
    end
    %% Figure base settings
    colors = [
        0.3, 0.6, 0.85;
        0.9, 0.5, 0.3;
        0.95, 0.75, 0.4;
        0.65, 0.4, 0.7;
        0.6, 0.8, 0.4;
        0.5, 0.8, 0.9;
        0.8, 0.4, 0.4;
        ];
    set(groot, 'DefaultLineLineWidth', 0.5);
    set(groot, 'DefaultAxesFontName', 'Arial');
    set(groot, 'DefaultAxesFontSize', 14);
    set(groot, 'DefaultTextFontName', 'Arial');

    % creat pic dir
    if ~exist([settings.results,'/pic'], "dir")
        mkdir([settings.results,'/pic'])
    end
    pic_name = [settings.results,'/pic/', settings.station_name, '_',file_info{2},'_',file_info{3},'_',file_info{4}(1:end-4)];

    %% Denoising the raw data
    if ~exist([settings.results,'/RH_info'], "dir")
        mkdir([settings.results,'/RH_info'])
    end

    if string(file_info{4}) ~= "SNR-Inverse.mat"
        % Excluded Bad frequency points
        for exf = 1:numel(settings.efps)
            out_ind = RH_info_all{:,3}==string(settings.efps{exf});
            RH_info_all(out_ind,:) = [];
        end

        % 3-sigma denoising
        if settings.sigma
            start_time = datetime(start_date,'ConvertFrom','datenum');
            end_time = datetime(end_date+1,'ConvertFrom','datenum');

            RH_info_raw = RH_info_all;
            t = 0;
            while 1
                t = t+1;
                RH_info_all_3sigma = [];
                i = 0;
                win_size = days(1/24);

                for win_t = start_time : win_size : end_time
                    i = i+1;
                    win_Data = RH_info_all(RH_info_all{:,1} >= win_t & RH_info_all{:,1} < win_t+win_size,:);
                    std_data = std(win_Data{:,"RH"},'omitnan');
                    mean_data = mean(win_Data{:,"RH"},'omitnan');

                    upper_bound(i) = mean_data + 3 * std_data;
                    lower_bound(i) = mean_data - 3 * std_data;
                    %                 fill([win_t, win_t+win_size, win_t+win_size, win_t], ...
                    %                     [upper_bound(i), upper_bound(i)+win_size, 100, 100], 'r', 'FaceAlpha', 0.1,'EdgeColor','none')
                    %                 fill([win_t, win_t+win_size, win_t+win_size, win_t], ...
                    %                     [lower_bound(i), lower_bound(i)+win_size, -100, -100], 'r', 'FaceAlpha', 0.1,'EdgeColor','none')
                    %                 fill([win_t, win_t+win_size, win_t+win_size, win_t,], ...
                    %                     [lower_bound(i), lower_bound(i)+win_size, upper_bound(i)+win_size, upper_bound(i)], 'b', 'FaceAlpha', 0.1,'EdgeColor','none')
                    %
                    win_Data(win_Data{:,"RH"} > upper_bound(i) | win_Data{:,"RH"} < lower_bound(i),:) = [];
                    RH_info_all_3sigma = [RH_info_all_3sigma; win_Data];
                end

                if numel(RH_info_all_3sigma(:,1)) == numel(RH_info_all(:,1)) | t == 3
                    figure
                    hold on
                    t_bound = start_time+win_size/2 : win_size : end_time+win_size/2;
                    plot(t_bound, upper_bound, 'blue--',DisplayName="upper bound")
                    plot(t_bound, lower_bound, 'blue:',DisplayName='lower bound')
                    legend
                    %             yticks_duration = get(gca, 'YTick');
                    %             yticks_double = days(yticks_duration);
                    %             set(gca, 'YTickLabel', num2str(yticks_double', '%.2f'));
                    %             ylim([days(nanmin(lower_bound)-1),days(nanmax(upper_bound)+1)])
                    ylabel('RH/m')
                    xlim([start_time, end_time])
                    xlabel('Time')
                    scatter(RH_info_raw{:,"Time"}, RH_info_raw{:,"RH"},'red','filled',DisplayName="outliers")
                    scatter(RH_info_all_3sigma{:,"Time"}, RH_info_all_3sigma{:,"RH"},'black','filled',DisplayName="valid")

                    box on
                    title("3 sigma denosing")

                    % save picture
                    set(gcf, 'Units','normalized','OuterPosition',[0.25,0.25,0.5,0.5])
                    name = [pic_name,'_3-sigma'];
                    saveas(gcf, [name,'.fig']);
                    print(gcf, [name,'.png'], '-dpng', '-r300')
                    break
                end
                RH_info_all = RH_info_all_3sigma;
                clear RH_info_all_3sigma
            end
            clear RH_info_raw

            QC_result = [settings.results,'/RH_info/',Final_files{f}(1:end-4),'.txt'];
            writetable(RH_info_all_3sigma, QC_result)
        end

        % spline denoising
        %         if settings.SplinedenoisingCheckBox.Value
        %             start_time = datetime(start_date,'ConvertFrom','datenum');
        %             end_time = datetime(end_date+1,'ConvertFrom','datenum');
        %             time = datenum(RH_info_all{:,1});
        %             data = RH_info_all{:,"RH"};
        %             [unique_time, ~, idx] = unique(time);
        %             avg_data = arrayfun(@(t) mean(data(time(idx) == t)), unique_time);
        %             spline_fit = spline(unique_time, avg_data, datenum(start_time:hours(1):end_time));
        %         end
    end


    %% Display
    % Azimuth
    % if settings.azi
    %     azi = RH_info_all{:,"MEAN_AZI"};
    %     RH = RH_info_all{:,"RH"};
    %     scatter(azi, RH, 'filled')
    % end

    % daily number
    if settings.day_num
        start_time = datetime(start_date,'ConvertFrom','datenum');
        end_time = datetime(end_date,'ConvertFrom','datenum');
        i = 0;
        day_num = nan(numel(start_time : days(1) : end_time),4);
        for t = start_time : days(1) : end_time
            i = i+1;
            RH_info_daily = RH_info_all(RH_info_all{:,1} >= t & RH_info_all{:,1} < t+days(1),:);

            day_num(i, 1) = numel(RH_info_daily(RH_info_daily{:,"System"}=="GPS",:)) / 11;
            day_num(i, 2) = numel(RH_info_daily(RH_info_daily{:,"System"}=="GLONASS",:)) / 11;
            day_num(i, 3) = numel(RH_info_daily(RH_info_daily{:,"System"}=="GALILEO",:)) / 11;
            day_num(i, 4) = numel(RH_info_daily(RH_info_daily{:,"System"}=="BDS",:)) / 11;
        end
        figure
        hold on
        for s = 1:5
            switch s
                case 1
                    scatter(start_time : days(1) : end_time, day_num(:,s),'filled',DisplayName="GPS",LineWidth=1.5)
                case 2
                    scatter(start_time : days(1) : end_time, day_num(:,s),'filled',DisplayName="GLONASS",LineWidth=1.5)
                case 3
                    scatter(start_time : days(1) : end_time, day_num(:,s),'filled',DisplayName="GALILEO",LineWidth=1.5)
                case 4
                    scatter(start_time : days(1) : end_time, day_num(:,s),'filled',DisplayName="BDS",LineWidth=1.5)
                case 5
                    scatter(start_time : days(1) : end_time, sum(day_num,2),'filled',DisplayName="ALL",LineWidth=1.5)

            end
        end
        legend
        box on
        grid on
        axis tight
        set(gcf, 'Units','normalized','OuterPosition',[0.25,0.25,0.5,0.5])
        ylabel('Daily Numbers', 'FontWeight','bold')
        xlabel('Time','FontWeight','bold')
        xlim([start_time-days(0.25), end_time+days(0.25)])

        % save picture
        name = [pic_name,'_Daily Numbers'];
        saveas(gcf, [name,'.fig']);
        print(gcf, [name,'.png'], '-dpng', '-r300')
    end

    %% Analysis of different Methdos
    if ~Tide_available
        time_tide = [];
        sea_level_tide = [];
    end

    % SNR-Spectral method
    if string(file_info{4}) == "SNR-Spectral.mat" || string(file_info{4}) == "OBS-CP.mat"
        % Excluded Bad frequency points
        for exf = 1:numel(settings.efps)
            out_ind = RH_info_all{:,3}==string(settings.efps{exf});
            RH_info_all(out_ind,:) = [];
        end

        Result_display_SNR_Spectral_CMC(settings, RH_info_all,time_tide,sea_level_tide, colors, start_date, end_date)
        % save picture
        saveas(gcf, [pic_name,'.fig']);
        print(gcf, [pic_name,'.png'], '-dpng', '-r300')
        if settings.cor
            if Tide_available
                figure
                set(gcf, 'Units','normalized','OuterPosition',[0.25,0.25,0.35,0.5])
                ir_t = RH_info_all{:,"Time"};
                ir_h = settings.antenna_height - RH_info_all{:,"RH"};
                cor_scatter(ir_h, datenum(ir_t), sea_level_tide, datenum(time_tide))
                ylabel('Tide gauge (m)')
                xlabel('GNSS-IR raw inversion value (m)')
                name = [pic_name,'_scatter'];
                saveas(gcf, [name,'.fig']);
                print(gcf, [name,'.png'], '-dpng', '-r300')
            else
                disp('correlation scatter need Tide Data !!!')
            end
        end

        if settings.rrs % Robust regression strategy
            fig_set.option  = 1;
            fig_set.sta_asl = settings.antenna_height;
            fig_set.tidal_info = {time_tide, sea_level_tide};
            [t_rrs,rh_rrs, RMSE_rrs, Bias_rrs] = rrs(RH_info_all, start_date, end_date, fig_set);
            name = [pic_name,'_rrs'];
            saveas(gcf, [name,'.fig']);
            print(gcf, [name,'.png'], '-dpng', '-r300')
            save([name,'.mat'],"t_rrs","rh_rrs", "RMSE_rrs", "Bias_rrs")
            if settings.cor
                figure
                set(gcf, 'Units','normalized','OuterPosition',[0.25,0.25,0.35,0.5])
                cor_scatter(rh_rrs', datenum(t_rrs'), sea_level_tide, datenum(time_tide))
                ylabel('Tide gauge (m)')
                xlabel('GNSS-IR Robust regression strategy (m)')
                name = [pic_name,'_rrs_scatter'];
                saveas(gcf, [name,'.fig']);
                print(gcf, [name,'.png'], '-dpng', '-r300')
            end
        end

        if settings.bspline % B-spline
            fig_set.option  = 1;
            fig_set.sta_asl = settings.antenna_height;
            fig_set.tidal_info = {time_tide, sea_level_tide};
            [t_b_spline,rh_b_spline, RMSE_b, Bias_b] = B_spline(RH_info_all, start_date, end_date, fig_set);
            name = [pic_name,'_b_spline'];
            saveas(gcf, [name,'.fig']);
            print(gcf, [name,'.png'], '-dpng', '-r300')
            save([name,'.mat'],"t_b_spline","rh_b_spline", "RMSE_b", "Bias_b")
            if settings.cor
                figure
                cor_scatter(rh_b_spline', datenum(t_b_spline'), sea_level_tide, datenum(time_tide))
                ylabel('Tide gauge (m)')
                xlabel('GNSS-IR B-spline (m)')
                name = [pic_name,'_b_spline_scatter'];
                saveas(gcf, [name,'.fig']);
                print(gcf, [name,'.png'], '-dpng', '-r300')
            end
        end

%%%%%%%%%%%%%%%% SNR-Inverse modeling %%%%%%%%%%%%%%%%%%
    elseif string(file_info{4}) == "SNR-Inverse.mat"
        time = RH_info_all.Time;
        RH_inverse_modeling = settings.antenna_height - RH_info_all.RH_Inverse;
        RH_spectral_b = settings.antenna_height - RH_info_all.RH_Spectral_bsp;
        interp_tide = spline(datenum(time_tide),sea_level_tide,datenum(time));
        figure
        tiledlayout(3,12,"TileSpacing","compact")
        nexttile([2,10])
        plot(time, RH_spectral_b, 'r--', LineWidth=1.5, DisplayName='Spectral Retrieval')
        hold on
        plot(time, RH_inverse_modeling, 'blue', LineWidth=1.5,DisplayName='Inverse Modeling')
        plot(time, interp_tide, 'black', LineWidth=1.5, DisplayName='Tide gauge')
        xlabel('Time','FontWeight','bold')
        ylabel('Sea level (m)','FontWeight','bold')
        xlim([min(time),max(time)+1])
        legend

        % cor-scatter
        nexttile(11,[1,2])
        cor_scatter(RH_inverse_modeling, datenum(time), sea_level_tide, datenum(time_tide))
        ylabel('Tide gauge (m)')
        xlabel('Inverse Modeling (m)')
        nexttile(23,[1,2])
        cor_scatter(RH_spectral_b, datenum(time), sea_level_tide, datenum(time_tide))
        ylabel('Tide gauge (m)')
        xlabel('Spectral Retrieval (m)')

        % RMSE
        nexttile(33,[1,4])
        RMSE(1) = sqrt(mean((interp_tide-RH_spectral_b).^2,'omitnan'));
        RMSE(2) = sqrt(mean((interp_tide-RH_inverse_modeling).^2,'omitnan'));
        b = barh(RMSE*100,0.5, 'FaceColor',[0.3010 0.7450 0.9330],'EdgeColor',[0.3010 0.7450 0.9330],'BarWidth',0.9, 'LineWidth', 2);
        set(gca, 'YTickLabel', {'Spectral Retrieval','Inverse Modeling'})
        xlabel('RMSE(cm)','FontWeight','bold')
        xtips1 = b(1).YEndPoints + 0.01;
        ytips1 = b(1).XEndPoints;
        rms_band = string(b(1).YData);
        text(xtips1,ytips1,rms_band,'HorizontalAlignment','right','Color',[1, 0.2, 0.2],'FontWeight','bold')
        xlim([0, max(RMSE)*100+5])

        % res-his
        for m = 1:2
            if m == 1
                data = interp_tide-RH_spectral_b;
                nexttile(25,[1,4])
            else
                data = interp_tide-RH_inverse_modeling;
                nexttile(30,[1,4])
            end
            h = histfit(data, 50, 'normal');
            h(1).FaceColor = [0.4, 0.6, 0.8];
            h(1).EdgeColor = [1,1,1];
            mu = mean(data);
            sigma = std(data);
            hold on;
            xline(mu, '--r', 'LineWidth', 2);
            text(mu, max(ylim)*0.9, sprintf('Mean:%.4f', mu),    'Color', 'r', 'FontSize', 20,'FontWeight','bold', 'HorizontalAlignment', 'right');
            text(mu, max(ylim)*0.65, sprintf('STD :%.4f', sigma), 'Color', 'b', 'FontSize', 20, 'FontWeight','bold','HorizontalAlignment', 'right');
            if m == 1
                ylabel('number')
                xlabel('Spectral Residual')
            else
                xlabel('Inverse Modeling Residual')
            end
        end

        set(gcf, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);
        
        saveas(gcf, [pic_name,'.fig']);
        print(gcf, [name,'.png'], '-dpng', '-r300')


%%%%%%%%%%% OBS-carrier / pseudo range %%%%%%%%%%%%%%%%
    else
        Result_display_OBS(RH_info_all, settings, time_tide, sea_level_tide, end_date, start_date, colors);
        % save picture
        saveas(gcf, [pic_name,'.fig']);
        print(gcf, [pic_name,'.png'], '-dpng', '-r300')
        if settings.cor
            figure
            ir_t = RH_info_all{:,"Time"};
            ir_h = settings.antenna_height - RH_info_all{:,"RH"};
            ir_h = ir_h-mean(ir_h,'omitnan');
            cor_scatter(ir_h, datenum(ir_t), sea_level_tide, datenum(time_tide))
            ylabel('Tide gauge (m)')
            xlabel('GNSS-IR raw inversion value (m)')
            name = [pic_name,'_scatter'];
            saveas(gcf, [name,'.fig']);
            print(gcf, [name,'.png'], '-dpng', '-r300')
        end

        if settings.rrs % Robust regression strategy
            fig_set.option  = 1;
            fig_set.sta_asl = settings.antenna_height;
            fig_set.tidal_info = {time_tide, sea_level_tide};
            [t_rrs, rh_rrs, RMSE_rrs, Bias_rrs] = rrs(RH_info_all, start_date, end_date, fig_set);
            name = [pic_name,'_rrs'];
            saveas(gcf, [name,'.fig']);
            print(gcf, [name,'.png'], '-dpng', '-r300')
            save([name,'.mat'],"t_rrs","rh_rrs", "RMSE_rrs", "Bias_rrs")
            if settings.cor
                figure
                cor_scatter(rh_rrs', datenum(t_rrs'), sea_level_tide, datenum(time_tide))
                ylabel('Tide gauge (m)')
                xlabel('GNSS-IR Robust regression strategy (m)')
                name = [pic_name,'_rrs_scatter'];
                saveas(gcf, [name,'.fig']);
                print(gcf, [name,'.png'], '-dpng', '-r300')
            end
        end

        if settings.bspline % B-spline
            fig_set.option  = 1;
            fig_set.sta_asl = settings.antenna_height;
            fig_set.tidal_info = {time_tide, sea_level_tide};
            [t_b_spline,rh_b_spline, RMSE_b, Bias_b] = B_spline(RH_info_all, start_date, end_date, fig_set);
            name = [pic_name,'_b_spline'];
            saveas(gcf, [name,'.fig']);
            print(gcf, [name,'.png'], '-dpng', '-r300')
            save([name,'.mat'],"t_b_spline","rh_b_spline", "RMSE_b", "Bias_b")
            if settings.cor
                figure
                cor_scatter(rh_b_spline', datenum(t_b_spline'), sea_level_tide, datenum(time_tide))
                ylabel('Tide gauge (m)')
                xlabel('GNSS-IR B-spline (m)')
                name = [pic_name,'_b_spline_scatter'];
                saveas(gcf, [name,'.fig']);
            end
        end
    end


end
