function genTropParameters(tdatenum,staxyz,sta_asl,tide_range)

curdt = datetime(tdatenum,'convertfrom','datenum');
curjd = juliandate(curdt);
curyr = datetime(curdt,'format','yyyy');
curyr = double(int16(convertTo(curyr,'yyyymmdd') / 10000));
curday = datetime(curdt,'format','DDD');
curday = day(curday,'dayofyear');

% Trop pre settings
lla       = ecef2lla(staxyz);
hell      = lla(3);
gpt3_grid = gpt3_5_fast_readGrid;
curjd2    = doy2jd(curyr,curday)-2400000.5;
hgtlim    = nan(2,1);
hgtlim(1) = hell - sta_asl+tide_range(1);
hgtlim(2) = hell - sta_asl+tide_range(2);
dlat      = lla(1)*pi/180.d0;
dlon      = lla(2)*pi/180.d0;
it        = 0;
plim = nan(2,1);
tlim = nan(2,1);
elim = nan(2,1);
tmlim = nan(2,1);

[pant,~,~,tmant,eant,ah,aw,lambda,~] = gpt3_5_fast (curjd2, dlat,dlon, hell,it, gpt3_grid);
[plim(1),tlim(1),~,tmlim(1),elim(1),~,~,~,~] = gpt3_5_fast (curjd2, dlat,dlon, hgtlim(1),it, gpt3_grid);
[plim(2),tlim(2),~,tmlim(2),elim(2),~,~,~,~] = gpt3_5_fast (curjd2, dlat,dlon, hgtlim(2),it, gpt3_grid);

save([num2str(tdatenum), 'TropParameters.mat'],"curjd","lla","hell", ...
    "hgtlim","plim","tlim","elim","tmlim","pant","tmant","eant","ah","aw","lambda")
end