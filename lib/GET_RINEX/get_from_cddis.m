clc
clear

%%
station_name = 'JNAV';
year = 2017;
doy = 251;

input_arg = 'https://cddis.nasa.gov/archive/gnss/data';

httpsUrl = input_arg;

username ='lk_earth';
password = 'Hao20030801';
options = weboptions('HeaderFields',{'Authorization',...
    ['Basic ' matlab.net.base64encode([username ':' password])]});
url = 'https://cddis.nasa.gov/archive/gnss/data';

year = str2num(input_arg(end-8:end-5));
if (mod(year, 4) == 0 && mod(year, 100) ~= 0) || mod(year, 400) == 0
    days = 366;
else
    days = 365;
end
while str2num(input_arg(end-3:end-1))<days
    data = webread(url,options);

    %% 读取文件名
    pattern = '\w{8}+.\d{2}+zpd.gz';
    result = regexp(data, pattern,'match');

    %% 去除重复的文件名
    Delete_Index = 1:2:numel(result);
    result(:,Delete_Index) = [];
    disp(['找到的文件数量：' num2str(numel(result))]);

    %% 建立保存数据的文件夹
    Folder_Name = 'E:\CDDIS数据';
    Folder_Name(find(Folder_Name=='/'))='\';
    if exist(Folder_Name, 'dir') == 0
        mkdir(Folder_Name);
    end

    %% 下载
    num_files = numel(result);
    parfor i = 1:numel(result)
        Download_httpsUrl = [httpsUrl,result{1,i}];
        Name_Save = [Folder_Name,'\',result{1,i}];
        n = 0;
        while n == 0
            try
                websave(Name_Save, Download_httpsUrl, options);
                %             disp([Name_Save,'下载完成'])
                n = 1;
            catch
                %             disp(['下载文件 ', Name_Save, ' 失败'])
            end
        end

        dirList = dir(Folder_Name); % 读取文件夹列表
        countlist = length(dirList)-2;  % 文件夹中的文件数量（包含两个空文件）
        remaining_files = numel(result) - countlist; % 计算剩余的文件数量

    end

    input_arg(end-3:end-1) = num2str(str2num(input_arg(end-4:end-1))+1);%递增天数
end
input_arg(end-8:end-5) = num2str(str2num(input_arg(end-8:end-5))+1); %递增年份

%下载到同年的情况
while str2num(input_arg(end-8:end-5))==2001  %定年份
    %% 网址
    httpsUrl = input_arg;

    %% 爬取数据
    data = webread(url,options);


    %% 读取文件名
    pattern = '\w{8}+.\d{2}+zpd.gz';
    result = regexp(data, pattern,'match');

    %% 去除重复的文件名
    Delete_Index = 1:2:numel(result);
    result(:,Delete_Index) = [];
    disp(['找到的文件数量：' num2str(numel(result))]);

    %% 建立保存数据的文件夹
    Folder_Name = 'E:\CDDIS数据';
    Folder_Name(find(Folder_Name=='/'))='\';
    if exist(Folder_Name, 'dir') == 0
        mkdir(Folder_Name);
    end

    %% 下载
    num_files = numel(result);
    parfor i = 1:numel(result)
        Download_httpsUrl = [httpsUrl,result{1,i}];
        Name_Save = [Folder_Name,'\',result{1,i}];
        n = 0;
        while n == 0
            try
                websave(Name_Save, Download_httpsUrl, options);
                n = 1;
            catch
            end
        end

        dirList = dir(Folder_Name); % 读取文件夹列表
        countlist = length(dirList)-2;  % 文件夹中的文件数量（包含两个空文件）
        remaining_files = numel(result) - countlist; % 计算剩余的文件数量
    end

    input_arg(end-3:end-1) = num2str(str2num(input_arg(end-4:end-1))+1);
end