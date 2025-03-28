function [hinit,xinit,sfacspre,sfacsjs,consts_out,roughout] = inverse(dt,snrfile, ...
    hell,hgtlim,ahgt,largetides,tdatenum,tlen,kspac, ...
    gps,glo,gal,bds,is_rough,is_plotmodsnr,roughin,varargin)

glonasswlen = load('glonasswlen.mat');
glonasswlen = glonasswlen.glonasswlen;
if numel(varargin) ~= 0
    app = varargin{1};
end
p = 2; % bspline order, Bezier curve level
stdfac = 3;
% unormal
if dt ~= 0
    modspl = mod(snrfile(:,4),dt);
    delt = modspl(:)>0;
    snrfile(delt,:)=[];
end

% grt rid of nan
tmp = isnan(snrfile(:,7));
snrfile(tmp,:) = [];
% change unit
snrfile(:,7) = sqrt(10.^(snrfile(:,7)./10));
dtdv = dt/86400;

%% INVERSE based on spectral
cursat = snrfile(1,1); % sat number
stind = 1;
s1ind = 0;

sinelv1_all = [];
snr1_all = [];
t1_all = [];
satno_all = [];
antno_all = [];

if snrfile(2,2) - snrfile(1,2) < 0 % Descending order
    fwd2 = 0;
else
    fwd2 = 1;
end

for ind = 2:size(snrfile,1)
    if snrfile(ind,2) - snrfile(ind-1,2) < 0 % Descending order
        fwd1 = 0;
    else
        fwd1 = 1;
    end

    curdt = snrfile(ind,9) - snrfile(ind-1,9);

    if ind - stind > 1
        if snrfile(ind,1) ~= cursat || ind == size(snrfile,1) || abs(curdt) >= 3*dtdv || ...
           fwd2 ~= fwd1 || snrfile(ind,2) == snrfile(ind-1,2) || ind-stind > (3600/dt) % was 3600
            
            if ind-stind < (300/dt) 
                ind = stind;
            else
                sinelvt1 = snrfile(stind:ind-1, 2);
                snr1tmp = snrfile(stind:ind-1, 7);
                t1tmp = snrfile(stind:ind-1, 9);
                satnotmp = snrfile(stind:ind-1, 1);
                antnotmp = snrfile(stind:ind-1, 10);
                del = isnan(snr1tmp(:,1));
                sinelvt1(del,:) = [];

                if numel(sinelvt1) > 2
                    sinelvt1 = sind(sinelvt1);
                    snr1tmp(del,:) = [];
                    t1tmp(del,:) = [];
                    satnotmp(del,:) = [];
                    antnotmp(del,:) = [];

                    p1 = polyfit(sinelvt1, snr1tmp, 2); % detrend
                    y1 = polyval(p1, sinelvt1);
                    sinelv1_all = [sinelv1_all; sinelvt1];
                    snr1tmp = snr1tmp - y1;
                    snr1_all = [snr1_all; snr1tmp];
                    t1_all = [t1_all; t1tmp];
                    satno_all = [satno_all; satnotmp];
                    antno_all = [antno_all; antnotmp];

                    if sinelvt1(2) - sinelvt1(1) < 0 % ensure the sine in ascending sort
                        sinelvt1 = flipud(sinelvt1);
                        snr1tmp = flipud(snr1tmp);
                    end

                    if snrfile(stind,1) < 33
                        L1car = 299792458 / 1575.42e06; % for GPS
                    elseif snrfile(stind,1) > 32 && snrfile(stind,1) < 57
                        L1car = glonasswlen(snrfile(stind,1)-32);
                    elseif snrfile(stind,1) > 56 && snrfile(stind,1) < 56+36+1
                        L1car = 299792458 / 1575.42e06;
                    else
                        L1car = 299792458 / 1575.42e06;
                    end


                    prec1 = 0.001;

                    if all(diff(sinelvt1) > 0) || all(diff(sinelvt1) <= 0)
                        [refl_h, id, psd, pks] = snr2RH_lsp(sinelvt1, snr1tmp, L1car, hell, hgtlim);

                        if refl_h(id) > hell-hgtlim(2) & refl_h(id) < hell-hgtlim(1) & max(psd)>10*mean(pks(1:end-1))
                            s1ind = s1ind + 1;
                            hinit(s1ind) = refl_h(id);
                            xinit(s1ind) = mean(t1tmp); % timing of spectral analysis estimates

                            snr_datatmp = snrfile(stind:ind-1, :);
                            tanthter(s1ind) = tand(mean(snr_datatmp(:,2))) / ...
                                (((pi/180) * (snr_datatmp(end,2) - snr_datatmp(1,2))) / ...
                                ((snr_datatmp(end,9) - snr_datatmp(1,9)) * 86400));
                            siteinit(s1ind) = snr_datatmp(end,10);
                        end
                    end
                end
            end

            stind = ind;
            if ind < size(snrfile,1)
                cursat = snrfile(ind,1);
            end
        end
    end
    fwd2 = fwd1;
end

if min(t1_all) > tdatenum+tlen/3 || numel(xinit) < 2
    disp('no data - continue')
    sfacsjs  = NaN;
    sfacspre = NaN;
    hinit    = NaN;
    xinit    = NaN;
    consts_out= NaN;
    roughout  = NaN;
    return
end

meanhgts = 0;
tmpinit = [xinit.' hinit.' tanthter.' siteinit.']; % time, reflect h
tmpinit = sortrows(tmpinit,1); % sort by time
xinit = tmpinit(:,1);
hinit = tmpinit(:,2);
tanthter = tmpinit(:,3);
siteinit = tmpinit(:,4);
% get rid of outlines by 3*sigma
hsmooth = smoothdata(hinit,'movmean',5);
diff1 = abs(hsmooth-hinit);
std1 = std(diff1);
delete = diff1(:,1)>stdfac*std1; % 2 for 4 stations
hinit(delete)=[];
xinit(delete)=[];
tanthter(delete)=[];
siteinit(delete)=[];

if largetides == 0
    indt = t1_all(:)>tdatenum+tlen/3 & t1_all(:)<tdatenum+2*tlen/3;
    t1_allt = t1_all(indt);
    maxt1gap = max(diff(sort(t1_allt)));
else
    indt = xinit(:)>tdatenum+tlen/3 & xinit(:)<tdatenum+2*tlen/3;
    indt = find(indt);% find time in window
    if min(indt)~=1
        indt = [min(indt)-1 ;indt];
    end
    if max(indt)~=numel(xinit)
        indt = [indt;max(indt)+1];
    end
    xinitt = xinit(indt);
    maxt1gap = max(diff(sort(xinitt)));
end
disp(['max gap is ',num2str(maxt1gap*24*60),' minutes'])


if  numel(maxt1gap)==0 || maxt1gap>kspac ||...
        max(xinit)<tdatenum+2*tlen/3 || min(xinit)>tdatenum+tlen/3
    disp('gap in data bigger than node spacing')
    disp('continue with risk of instabilities')
end

%% B spline spectral
knots = [tdatenum*ones(1,p) ...
    tdatenum:kspac:tdatenum+tlen ...
    (tdatenum+tlen)*ones(1,p)]; % knot vector, multiplicity = 4
nsfac = tlen/kspac + p;
sfacs_0 = ahgt*ones(1,nsfac); % control points
tempfun_init = @(sfacs) bspline_spectral(sfacs, p, knots, tanthter, xinit,1)-hinit.';
options = optimoptions(@lsqnonlin,'Algorithm','levenberg-marquardt',...
    'Display','off'); % off for now but maybe should check sometimes
sfacs_init = lsqnonlin(tempfun_init,sfacs_0,[],[],options); %lsqnonlin or fsolve??
in = xinit(:)>tdatenum+tlen/3 & xinit(:)<tdatenum+2*tlen/3;
xinit = xinit(in).';
hinit = hinit(in).';
sfacspre = sfacs_init; % spectral analysis adjustment

%% Inverse Modeling
doprev = 0;
if exist('sfacsjs', 'var')==0 || doprev==0
    if largetides == 1
        sfacs_0 = sfacs_init; % estimate b-spline nodes using the initial time series of hs
    else
        sfacs_0 = median(hinit)*ones(size(sfacs_init));
    end
else
    inds = tlen/(3*kspac)+2;
    sfacs_0 = sfacsjs(inds:end);
    sfacs_0 = [sfacs_0(1)*ones(1,p-1) sfacs_0 sfacs_0(end)*ones(1,tlen/(3*kspac)+p-1)];
end
consts = gps+glo+gal+bds;
sfacs_0 = [sfacs_0 zeros(1,consts*2)];

if is_rough == "On"
    sfacs_0 = [sfacs_0 roughin]; % add roughness
    tempfun = @(sfacs) bspline_js(sfacs,t1_all,sinelv1_all,snr1_all,knots,...
        p,satno_all,gps,glo,gal,bds,antno_all,meanhgts);
else
    tempfun = @(sfacs) bspline_jsnorough(sfacs,t1_all, sinelv1_all, snr1_all, knots,...
        p,satno_all,gps,glo,gal,bds,antno_all,meanhgts);
end
options = optimoptions(@lsqnonlin,'Algorithm','levenberg-marquardt', 'Display','off');
tic
sfacs_ls = lsqnonlin(tempfun,sfacs_0,[],[],options);
toc
disp('****least squares done****')

% To plot model vs real snr data
if is_plotmodsnr == "On"
    plotmodsnr = 1;
elseif is_plotmodsnr == "Off"
    plotmodsnr = 0;
end
if plotmodsnr == 1
    residout = bsp_snrout(app,sfacs_ls,t1_all,sinelv1_all,snr1_all,knots,...
        p,satno_all,gps,glo,gal,bds,antno_all,meanhgts,dtdv,elv_low,elv_high);
end

if is_rough == "On"
    sfacsjs    = sfacs_ls(1:end-consts*2-1);
    consts_out = sfacs_ls(end-consts*2:end-1);
    roughout   = sfacs_ls(end);
else
    sfacsjs    = sfacs_ls(1:end-consts*2);
    consts_out = sfacs_ls(end-consts*2:end);
    roughout   = NaN;
end
end