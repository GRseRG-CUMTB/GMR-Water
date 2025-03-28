function data = Spatial_distribution(lat,lon,el,az, ht, freq)

R = 6378.14; %km

F = felipeF(freq, el, ht, az);
a=F(1);
b=F(2);
center=F(3);

azcart=360-az+90;
if azcart>360
    azcart=azcart-360;
end
%convert aznew to radians
azcart=azcart*pi/180;

[x y] = ellipseGE(a,b,azcart,center*cos(azcart),center*sin(azcart));


d=sqrt(x.^2+y.^2); %meters ;
d=d./1000; %km

theta=atan2(x,y);
k=find(theta<0);
theta(k)=theta(k)+2*pi;
theta=theta*180/pi;

%new lat and lon
latnew=asin(sind(lat).*cos(d./R)+cosd(lat).*sin(d./R).*cosd(theta));
lonnew=lon+180./pi.*(atan2(sind(theta).*sin(d./R).*cosd(lat),cos(d./R)-sind(lat).*sin(latnew)));
latnew=latnew.*180./pi;
data = [lonnew;latnew];
end