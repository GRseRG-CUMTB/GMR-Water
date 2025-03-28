function get_sp3(fig, start_date, end_date, sp3_option, save_path)
start_date_jd = juliandate(start_date); % start date
[gpsweeks,sows,~] = jd2gps(start_date_jd);
dows = sows/86400;

end_date_jd = juliandate(end_date); % end date
[gpsweeke,sowe,~] = jd2gps(end_date_jd);
dowe = sowe/86400;

numday = daysact(start_date,end_date)+1; % all days number
day_num = 0; % have download files numbers
gpsweekn=gpsweeks-1;
while gpsweekn < gpsweeke
    gpsweekn=gpsweekn+1;
    gpsweek=num2str(gpsweekn);
    disp(['gpsweekn=',gpsweek])

    e = 7; % end day
    bool = 0;
    % Progress bar
    progress = strcat('(',num2str(day_num),'/',num2str(numday),')');
    d = uiprogressdlg(fig,'Title',strcat('Download progress ',progress), ...
        'Message','Start downloading','Cancelable','on');
    drawnow

    for i = 1:7
        dow = i-1;
        if gpsweekn == gpsweeks % in the first week
            while dow >= dows && dow < e
                sow = dow*86400;
                day_num = day_num+1;
                download_sp3(gpsweekn,sow,dow,sp3_option,save_path,d,day_num,numday)
                dow = dow+1;
                if gpsweeks == gpsweeke % end in this week
                    e = dowe;
                else
                    e = 7;
                end
                bool = 1;
            end
        elseif gpsweekn == gpsweeke % in the end week
            while dow <= dowe

                sow = dow*86400;
                day_num = day_num+1;
                download_sp3(gpsweekn,sow,dow,sp3_option,save_path,d,day_num,numday)
                dow = dow+1;
                bool = 1;
            end
        else
            while dow < 7 % in the medium week

                sow = dow*86400;
                day_num = day_num+1;
                download_sp3(gpsweekn,sow,dow,sp3_option,save_path,d,day_num,numday)
                bool = 1;
                dow = dow+1;
            end
        end

        if bool == 1
            break
        end
    end

end
end