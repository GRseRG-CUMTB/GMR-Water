function RH_final = lsq(epoc_num, start_date, interval, RH_info_all, ...
    h_initial, h_trop, roc, t, e, h_tidal)

h_change = nan(1,epoc_num);
RH_final = nan(1,epoc_num);
for i = 1:epoc_num
    cur_date = start_date + (i-1)*interval/(24*60);
    cur_indx = (cur_date-30/(24*60)) <= datenum(RH_info_all.Time) & ...
        datenum(RH_info_all.Time) <= (cur_date+30/(24*60));   % win size = 1hour
    cur_h_initial = h_initial(cur_indx);
    cur_h_trop = h_trop(cur_indx);
    cur_roc = roc(cur_indx);
    cur_t = t(cur_indx);

    if numel(unique(roundn(cur_roc,-4))) < 3
        e = e+1;
        h_change(i) = nanmean(cur_roc);
        RH_final(i) = nanmean(cur_h_initial + cur_h_trop + h_tidal(cur_indx));
        continue
    end
    M = cur_roc + (cur_t-cur_date);
    A = [M, ones(size(M, 1), 1)];
    H = cur_h_initial-cur_h_trop;

    X_p_now = pinv(A'*A)*(A')*H;

    while 1
        v = A*X_p_now - H;
        P = nan(numel(v),1);
        P(abs(v) >= 0.5) = 0;
        P(abs(v) < 0.5) = (1-v(abs(v) < 0.5)).^2;
        P_diag = diag(P);
        X_p_last = X_p_now;
        X_p_now = pinv(A'*P_diag*A) * (A'*P_diag) * H;

        if abs(X_p_now(2) - X_p_last(2)) < 0.05
            break
        end

    end
    h_change(i) = X_p_now(1);
    RH_final(i) = X_p_now(2) + mean(cur_h_trop,'omitnan');
end
end