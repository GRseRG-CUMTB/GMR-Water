function RH_final = Find_final_file(Final_path, station_name, start_date, end_date, mode)
switch mode
    case 1
        m = '_SNR.mat';
    case 2
        m = '_LP.mat';
end
RH_info_all = cell(1, end_date+1-start_date);
i = 0;
for t = start_date:end_date
    mon = sprintf('%02d', month(t));
    Final_file = [Final_path,'/',station_name,'_', mon, m];
    load(Final_file)
    i = i+1;
    switch mode
        case 1
            RH_info_all{i} = Final_info_SNR;
        case 2
            RH_info_all{i} = Final_info_LP;
    end
end
RH_info_all = vertcat(RH_info_all{:});
band_name = fieldnames(RH_info_all);
RH_final = cell(1, numel(band_name));
for band = 1:numel(band_name)
    data = vertcat(RH_info_all.(band_name{band}));
    RH_final{band} = data;
end
RH_final = vertcat(RH_final{:});
RH_final = sortrows(RH_final,"Time");
end