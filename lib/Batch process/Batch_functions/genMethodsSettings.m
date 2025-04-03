function genMethodsSettings()

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%  for SCOA  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
WinLSP.Enable = 1;
if WinLSP.Enable
    WinLSP.length = 5;
    WinLSP.gap = 2.5;
    PNR = 2.5;
else
    PNR = 7;
end



%% For Carrier phase/pseudo range multi-frequence combination
MFC.type = "triple"; % triple or dual
MFC.gps_ComBand = {'L1C', 'L2W', 'L5Q'};
MFC.gps_parameter = [0.1248 -0.024];

% MFC.glo_ComBand = ['L1C', 'L2C', ];
% MFC.glo_parameter = [0.1248 -0.024];

MFC.gal_ComBand = {'L1C', 'L8Q', 'L7Q'};
MFC.gal_parameter = [0.1257, -0.0548];

MFC.bds_ComBand = {'L1P', 'L6I', 'L5P'};
MFC.bds_parameter = [0.1207, -0.25];

%% For Carrier phase & pseudo range single frequence combination
SFC.gps_parameter = [0.0951 -0.0452; % L1
    0.1221 -0.0672; % L2
    0.1277 -0.0582]; % L5

SFC.glo_parameter = [0.0934 -0.0321; % G1
    0.12 -0.0263; % G2
    0.1242 -0.0646]; % G3

SFC.gal_parameter = [0.0951 -0.0452; % E1
    0.1277 -0.0582; % E5a
    0.1242 -0.0646; % E5b
    0.1261 -0.1038; % E5
    0.1172 -0.0617]; % E6

SFC.bds_parameter = [0.0962 -0.0833; % B1-2
    0.0951 -0.0452 %B1
    0.1277 -0.0582; % B2a
    0.1242 -0.0646; % E5b
    0.1261 -0.1038; % B2
    0.1182 -0.0753]; % B3

save('MethodsSettings.mat',"WinLSP", "PNR", "MFC", "SFC")

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%  for BRST  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WinLSP.Enable = 1;
% if WinLSP.Enable
%     WinLSP.length = 5;
%     WinLSP.gap = 2.5;
% end
% 
% PNR = 10;
% 
% %% For Carrier phase/pseudo range multi-frequence combination
% MFC.type = "triple"; % triple or dual
% MFC.gps_ComBand = {'L1C', 'L2W', 'L5X'};
% MFC.gps_parameter = [0.1248 -0.024];
% 
% % MFC.glo_ComBand = ['L1C', 'L2C', ];
% % MFC.glo_parameter = [0.1248 -0.024];
% 
% MFC.gal_ComBand = {'L1X', 'L8I', 'L7X'};
% MFC.gal_parameter = [0.1257, -0.0548];
% 
% MFC.bds_ComBand = {'L1X', 'L6I', 'L5X'};
% MFC.bds_parameter = [0.1207, -0.25];
% 
% %% For Carrier phase & pseudo range single frequence combination
% SFC.gps_parameter = [0.0951 -0.0452; % L1
%     0.1221 -0.0672; % L2
%     0.1277 -0.0582]; % L5
% 
% SFC.glo_parameter = [0.0934 -0.0321; % G1
%     0.12 -0.0263; % G2
%     0.1242 -0.0646]; % G3
% 
% SFC.gal_parameter = [0.0951 -0.0452; % E1
%     0.1277 -0.0582; % E5a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % E5
%     0.1172 -0.0617]; % E6
% 
% SFC.bds_parameter = [0.0962 -0.0833; % B1-2
%     0.0951 -0.0452 %B1
%     0.1277 -0.0582; % B2a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % B2
%     0.1182 -0.0753]; % B3
% 
% save('MethodsSettings.mat',"WinLSP", "PNR", "MFC", "SFC")

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%  for AT01  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WinLSP.Enable = 1;
% if WinLSP.Enable
%     WinLSP.length = 5;
%     WinLSP.gap = 2.5;
% end
% 
% PNR = 10;
% 
% %% For Carrier phase/pseudo range multi-frequence combination
% MFC.type = "triple"; % triple or dual
% MFC.gps_ComBand = {'L1C', 'L2W', 'L5Q'};
% MFC.gps_parameter = [0.1248 -0.024];
% 
% % MFC.glo_ComBand = ['L1C', 'L2C', ];
% % MFC.glo_parameter = [0.1248 -0.024];
% 
% MFC.gal_ComBand = {'L1C', 'L8Q', 'L7Q'};
% MFC.gal_parameter = [0.1257, -0.0548];
% 
% MFC.bds_ComBand = {'L1P', 'L6I', 'L5P'};
% MFC.bds_parameter = [0.1207, -0.25];
% 
% %% For Carrier phase & pseudo range single frequence combination
% SFC.gps_parameter = [0.0951 -0.0452; % L1
%     0.1221 -0.0672; % L2
%     0.1277 -0.0582]; % L5
% 
% SFC.glo_parameter = [0.0934 -0.0321; % G1
%     0.12 -0.0263; % G2
%     0.1242 -0.0646]; % G3
% 
% SFC.gal_parameter = [0.0951 -0.0452; % E1
%     0.1277 -0.0582; % E5a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % E5
%     0.1172 -0.0617]; % E6
% 
% SFC.bds_parameter = [0.0962 -0.0833; % B1-2
%     0.0951 -0.0452 %B1
%     0.1277 -0.0582; % B2a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % B2
%     0.1182 -0.0753]; % B3
% 
% % [a, b] = genCoefficients('TRM59800.00', 'SCIT', 'gps', 'L1')
% save('MethodsSettings.mat',"WinLSP", "PNR", "MFC", "SFC")

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%  for BUR2  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WinLSP.Enable = 0;
% if WinLSP.Enable
%     WinLSP.length = 5;
%     WinLSP.gap = 2.5;
% end
% 
% PNR = 10;
% 
% %% For Carrier phase/pseudo range multi-frequence combination
% MFC.type = "triple"; % triple or dual
% MFC.gps_ComBand = {'L1C', 'L2W', 'L5Q'};
% MFC.gps_parameter = [0.1248 -0.024];
% 
% % MFC.glo_ComBand = ['L1C', 'L2C', ];
% % MFC.glo_parameter = [0.1248 -0.024];
% 
% MFC.gal_ComBand = {'L1C', 'L8Q', 'L7Q'};
% MFC.gal_parameter = [0.1257, -0.0548];
% 
% MFC.bds_ComBand = {'L1P', 'L6I', 'L5P'};
% MFC.bds_parameter = [0.1207, -0.25];
% 
% %% For Carrier phase & pseudo range single frequence combination
% SFC.gps_parameter = [0.0951 -0.0452; % L1
%     0.1221 -0.0672; % L2
%     0.1277 -0.0582]; % L5
% 
% SFC.glo_parameter = [0.0934 -0.0321; % G1
%     0.12 -0.0263; % G2
%     0.1242 -0.0646]; % G3
% 
% SFC.gal_parameter = [0.0951 -0.0452; % E1
%     0.1277 -0.0582; % E5a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % E5
%     0.1172 -0.0617]; % E6
% 
% SFC.bds_parameter = [0.0962 -0.0833; % B1-2
%     0.0951 -0.0452 %B1
%     0.1277 -0.0582; % B2a
%     0.1242 -0.0646; % E5b
%     0.1261 -0.1038; % B2
%     0.1182 -0.0753]; % B3
% 
% % [a, b] = genCoefficients('TRM59800.00', 'SCIT', 'gps', 'L1')
% save('MethodsSettings.mat',"WinLSP", "PNR", "MFC", "SFC")
end