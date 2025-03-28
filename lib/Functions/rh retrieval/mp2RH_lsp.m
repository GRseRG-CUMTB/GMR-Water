function [refl_h, id, psd, pks] = mp2RH_lsp(sinelv, M, hell, hgtlim, a, b)

maxf1 = numel(sinelv) / (2*(max(sinelv)-min(sinelv)));
[psd,f] = plomb(M,sinelv,maxf1,20);

refl_h = f * a + b;
surface_h = hell - refl_h;

% valid_indx = surface_h>hgtlim(1) & surface_h<hgtlim(2);
% refl_h = refl_h(valid_indx);
% psd = psd(valid_indx);
[~,id] = max(psd(:));

try
    pks = findpeaks(psd);
catch
    pks = nan;
    return
end
pks = sort(pks);
end