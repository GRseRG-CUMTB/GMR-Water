function [sfacsjs,sfacspre,hinit,xinit,consts_out,roughout] = inversemodel(app,tdatenum,snrdir,...
    kspac,tlen)

global  Operation_settings

station = Operation_settings.station_name;

gps=0;  glo=0;  gal=0;  bds=0;
if app.GPSCheckBox.Value == 1
    gps = 1;
end
if app.GLONASSCheckBox.Value == 1
    glo = 1;
end
if app.GALILEOCheckBox.Value == 1
    gal = 1;
end
if app.BDSCheckBox.Value == 1
    bds =1;
end

roughin = str2double(app.roughness.Value);
largetides = 1;

ahgt = app.ahgt.Value;
ahgt_bounds = app.ahgt_bounds.Value;
lla       = ecef2lla(Operation_settings.station_xyz);
hell      = lla(3);
hgtlim(1) = hell - ahgt-ahgt_bounds;
hgtlim(2) = hell - ahgt+ahgt_bounds;


dt = str2double(Operation_settings.dt); % in seconds
tdatenum = tdatenum-tlen/3;
curdt    = datetime(tdatenum + tlen/3,'convertfrom','datenum');
disp(char(curdt))

% work out if need two days or just one
mlen = 1;
if tdatenum+tlen - mod(tdatenum+tlen, 1) - (tdatenum-mod(tdatenum,1))>0
    mlen = tdatenum+tlen - mod(tdatenum+tlen,1)-(tdatenum-mod(tdatenum,1))+1;
    if mod(tdatenum+tlen, 1)==0
        mlen = mlen-1;
    end
end

%% GET SNR
snrfilet = [];
for m = 1:mlen
    snrdata = [];
    tdatenumt = tdatenum - mod(tdatenum,1) + m-1;
    curdtt  = datetime(tdatenumt,'convertfrom','datenum');
    strdayt = char(datetime(curdtt,'format','DDD'));
    stryrst = char(datetime(curdtt,'format','yy'));
    if exist([char(snrdir),'/', station, num2str(tdatenumt),'.mat'],'file') == 2
        snr_data = load([char(snrdir),'/', station, num2str(tdatenumt),'.mat']);
        snr_data = snr_data.snr_data;
    elseif exist([char(snrdir),'/',station,strdayt,'0.',stryrst,'snr']) == 2
        snr_data = dlmread([char(snrdir),'/',station,strdayt,'0.',stryrst,'snr']);
    else
        break
    end

    % for each system
    for sys = 1:4
        if sys == 1 && gps == 1
            system = snr_data.GPS;
            gnss_system = "GPS";
            add = 0;
        elseif sys == 2 && glo == 1
            system = snr_data.GLONASS;
            gnss_system = "GLONASS";
            add = 32;
        elseif sys == 3 && gal == 1
            system = snr_data.GALILEO;
            gnss_system = "GALILEO";
            add = 32+24;
        elseif sys == 4 && bds == 1
            system = snr_data.BDS;
            gnss_system = "BDS";
            add = 32+24+36;
        else
            continue
        end
        band_num = size(system.Properties.VariableNames);

        for l = 1: band_num(2)-4
            band = system.Properties.VariableNames(l+4);
            bandchar = char(band);
            if numel(bandchar) == 3
                if bandchar(2) ~= '1' || bandchar(3) == 'W'
                    continue
                end
            else
                if bandchar(2) ~= '1'
                    continue
                end
            end

            [hang,~] = size(system);
            nan_all = nan(hang ,2);
            snrfile_raw = [table2array(system(:,1))+add, table2array(system(:,4)),table2array(system(:,3)),table2array(system(:,2)),...
                nan_all, table2array(system(:,band))];
            [~,lie] = size(snrfile_raw);
            if lie == 7
                snrdata = [snrdata; snrfile_raw];
            end
        end
    end
    snrdata(:,9) = tdatenum - mod(tdatenum,1)+m-1 + snrdata(:,4)./86400;
    snrdata(:,10)= 1;

    % now get rid of data outside window
    tmpout = snrdata(:,9)<tdatenum | snrdata(:,9)>=tdatenum+tlen;
    snrdata(tmpout,:) = [];
    snrfilet = [snrfilet; snrdata];
end

if ~isempty(snrfilet)
    snrfile = sortrows(snrfilet,1);
else
    disp('no data - continue')
    sfacsjs  = NaN;
    sfacspre = NaN;
    hinit    = NaN;
    xinit    = NaN;
    consts_out= NaN;
    roughout  = NaN;
    return
end
clear snrfilet snr_data

is_rough = string(app.rough_sw.Value);
is_plotmodsnr = string(app.plotmodsnr.Value);
[hinit,xinit,sfacspre,sfacsjs,consts_out,roughout] = inverse(dt,snrfile,hell,hgtlim,ahgt, ...
    largetides,tdatenum,tlen,kspac,gps,glo,gal,bds,is_rough,is_plotmodsnr,roughin,app);



end

