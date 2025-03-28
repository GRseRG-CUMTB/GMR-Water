function [tidal_c, RH_info_all, rh] = Tidal_correction(RH_info_all, sta_lat, sta_asl, tide_range)

time = datenum(RH_info_all.Time);
roc  = (RH_info_all.ROC)./3600;
rh   = RH_info_all.RH;

% getting rid of outliers
rhsmooth = smoothdata(rh,'movmean',5);
diff1    = abs(rh - rhsmooth); 
std1     = std(diff1);                  % standard deviation
delete = diff1(:,1) > 3*std1;       % here choose 3*sigma bounds to remove
time(delete,:) = [];
roc(delete,:)  = [];
rh(delete,:)   = [];
RH_info_all(delete,:) = [];
mean_rh = mean(rh);
rh_m = rh-mean(rh);
load('tidefreqs.mat')
ju = [12 20 41 47 56]; % O1, K1, N2, M2, S2

coefs_0 = rand(numel(ju)*2,1) * 2 * sqrt(0.005) - sqrt(0.005);
freqs = freqs(ju);
names = names(ju,:);
tempfun = @(coefs) tidemod_kl(coefs, time, rh_m, ju, roc, freqs, sta_lat);
options = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective','Display','off');
coefs_ls = lsqnonlin(tempfun,coefs_0,[],[],options); % here is the least squares
rh_c = tidemod_kl_plot(coefs_ls,time,rh_m,ju,roc,freqs,sta_lat);
tidal_c = rh_c - rh_m;
rh = rh + tidal_c;

out_range = rh > sta_asl-tide_range(1) | rh < sta_asl-tide_range(2);
tidal_c(out_range) = [];
RH_info_all(out_range,:) = [];
rh(out_range) = [];

RH_info_all.RH        = rh;
RH_info_all.tidal_cor = tidal_c;
end