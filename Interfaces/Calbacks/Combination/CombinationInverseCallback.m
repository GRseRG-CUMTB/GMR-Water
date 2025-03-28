function CombinationInverseCallback(app,type)
global Operation_settings
startdate = datenum(Operation_settings.time(1));
enddate = datenum(Operation_settings.time(2));
tdatenum = startdate - 1;

c1 = string(app.p1.Value);
c2 = string(app.p2.Value);
try
    c3 = string(app.p3.Value);
catch
    c3 = nan;
end
carrier_analysis_results = [];
while tdatenum < enddate
    tdatenum = tdatenum + 1;
    file_name = strcat(app.path_cpi.Value,'\',Operation_settings.station_name,num2str(tdatenum));

    if type == "CP"
        file_name = app.path_cpi.Value;
    end
    gnss_system = string(app.s1.Value);
    
    [results] = carrier_analysis(app, file_name, gnss_system, c1, c2, c3, tdatenum);
    carrier_analysis_results = [carrier_analysis_results; results];
end

%% tidal crrection
Time = datetime(carrier_analysis_results(:,1),'ConvertFrom','datenum');
System = repmat(gnss_system, [numel(Time),1]);
BAND = repmat(type, [numel(Time),1]);
PRN = carrier_analysis_results(:,2);
ROC = carrier_analysis_results(:,7);
MIN_elv = carrier_analysis_results(:,3);
MAX_elv = carrier_analysis_results(:,4);
MEAN_azi= carrier_analysis_results(:,5);
RH      = carrier_analysis_results(:,6);
trop_c  = carrier_analysis_results(:,8);
RH_info_all = table(Time, System,BAND,PRN,ROC,MIN_elv,MAX_elv,MEAN_azi,RH,trop_c);
RH_info_all(isnan(RH_info_all.RH),:) = [];

app.car_tab.Data = RH_info_all;

RH_info_all = sortrows(RH_info_all,"Time");
band = RH_info_all.BAND;
fp_all = unique(RH_info_all.System+band);

for fp = 1:numel(fp_all)
    cur_sysband = fp_all(fp);
    RH_fp = RH_info_all(RH_info_all.System+band == cur_sysband,:);
    [~, RH_fp, ~] = Tidal_correction(RH_fp, Operation_settings.station_l(1), app.antenna_height.Value , ...
        [-app.rf_range.Value,app.rf_range.Value]);

    Final_info.(cur_sysband) = RH_fp;
end

final_file_name = [app.path_cpi_m.Value,'/',Operation_settings.station_name,'_',...
    char(datetime(startdate,'ConvertFrom','datenum','Format','uuuu-MM-dd')),'_',char(datetime(enddate,'ConvertFrom','datenum','Format','uuuu-MM-dd'))...
    ,'_OBS','-',char(type),'.mat'];
save(final_file_name, "Final_info")
end