function [refl_h, id, psd, pks, dsnr, f] = snr2RH_lsp(sinelv, snr, wave_length, hell, hgtlim)

% detrend
p = polyfit(sinelv, snr, 3);
dsnr = snr - polyval(p, sinelv);

% [imf,~,~] = vmd(snr);
% dsnr = sum(imf(:,1:3),2)';

rh_lim = hell - hgtlim;
f_lim = 2*rh_lim./wave_length;
fi = f_lim(2):1:f_lim(1);

% maxf1 = numel(sinelv) / (2*(max(sinelv)-min(sinelv)))+100;
prec1 = 0.001;
ovs = round(wave_length/(2*prec1*(max(sinelv)-min(sinelv))));
% fi = 1:1:maxf1;
[psd,f,~,~,~,~] = fLSPw(sinelv,dsnr,fi,0.05,ovs);
psd = cell2mat(psd);
f = cell2mat(f);
% [psd, f] = plomb(dsnr, sinelv, [], ovs, "power");
refl_h = f.*0.5*wave_length;
surface_h = hell - refl_h;

% valid_indx = surface_h>hgtlim(1) & surface_h<hgtlim(2);
% refl_h = refl_h(valid_indx);
% psd = psd(valid_indx);
% f = f(valid_indx);
[~,id] = max(psd(:));

try
    pks = findpeaks(psd);
catch
    pks = nan;
    return
end
pks = sort(pks);
end