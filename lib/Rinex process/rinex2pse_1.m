function [pse_azi, pse_all, pse_data] = rinex2pse_1(obsstr, sp3str)
% Extract Pse information from RINEX2 files   

global Operation_settings

elv_lims = Operation_settings.elv;
azi_lims = Operation_settings.azi;
azi_mask = Operation_settings.azimask;
plat     = Operation_settings.station_l(2);
plon     = Operation_settings.station_l(1);
staxyz   = Operation_settings.station_xyz;

% all info
elv_all = [0 90];
azi_all = [0 360];
[pse_data] = extract_pse_from_rinex2(obsstr, sp3str, elv_all, azi_all, staxyz, plat, plon);
pse_all = pse_data;

% azi
pse_azi = pse_data;
azimuth_min = azi_lims(1);
azimuth_max = azi_lims(2);
if isfield(pse_data,'GPS')
    GPS_data = pse_azi.GPS;
    GPS_filtered = GPS_data(GPS_data.GPS_azi >= azimuth_min & GPS_data.GPS_azi <= azimuth_max, :);
    if sum(~isnan(azi_mask)) == 0
        GPS_filtered(GPS_filtered.GPS_azi >= azi_mask(1) & GPS_filtered.GPS_azi <= azi_mask(2), :) = [];
    end
    pse_azi.GPS = GPS_filtered;
end
if isfield(pse_data,'GLONASS')
    GLONASS_data = pse_azi.GLONASS;
    GLONASS_filtered = GLONASS_data(GLONASS_data.GLONASS_azi >= azimuth_min & GLONASS_data.GLONASS_azi <= azimuth_max, :);
    if sum(~isnan(azi_mask)) == 0
        GLONASS_filtered(GLONASS_filtered.GLONASS_azi >= azi_mask(1) & GLONASS_filtered.GLONASS_azi <= azi_mask(2), :) = [];
    end
    pse_azi.GLONASS = GLONASS_filtered;
end
if isfield(pse_data, 'GALILEO') && ~isempty(pse_data.GALILEO)
    GALILEO_data = pse_data.GALILEO;
    Galileo_filtered = GALILEO_data(GALILEO_data.GALILEO_azi >= azimuth_min & GALILEO_data.GALILEO_azi <= azimuth_max, :);
    
    if sum(~isnan(azi_mask)) == 0
        Galileo_filtered(Galileo_filtered.GALILEO_azi >= azi_mask(1) & Galileo_filtered.GALILEO_azi <= azi_mask(2), :) = [];
    end
    
    pse_azi.GALILEO = Galileo_filtered;
end



% elv
elvmuth_min = elv_lims(1);
elvmuth_max = elv_lims(2);
pse_data = pse_azi;
if isfield(pse_data,'GPS')
    GPS_data = pse_data.GPS;
    GPS_filtered = GPS_data(GPS_data.GPS_elv >= elvmuth_min & GPS_data.GPS_elv <= elvmuth_max, :);
    pse_data.GPS = GPS_filtered(:,1:end-1);
end
if isfield(pse_data,'GLONASS')
    GLONASS_data = pse_data.GLONASS;
    GLONASS_filtered = GLONASS_data(GLONASS_data.GLONASS_elv >= elvmuth_min & GLONASS_data.GLONASS_elv <= elvmuth_max, :);
    pse_data.GLONASS = GLONASS_filtered(:,1:end-1);
end
if isfield(pse_data, 'GALILEO') && ~isempty(pse_data.GALILEO)
    GALILEO_data = pse_data.GALILEO;
    Galileo_filtered = GALILEO_data(GALILEO_data.GALILEO_elv >= elvmuth_min & GALILEO_data.GALILEO_elv <= elvmuth_max, :);
    pse_data.GALILEO = Galileo_filtered(:, 1:end-1);
end



