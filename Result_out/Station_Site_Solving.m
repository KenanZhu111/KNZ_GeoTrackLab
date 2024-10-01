function [ENU] = Station_Site_Solving()
% 打开坐标文件
file=fopen('111.sp');       
sPRN = [];
satX = [];
satY = [];
satZ = [];
P_t1 = [];
P_t2 = [];
H    = [];
TGD  = [];
Dt   = [];
sat_num = [];

C_V    = 299792458;
f1     =   1575.42;
f2     =   1227.60;
satnum =         0;
eponum =         0;

% 设置测站粗略坐标和精确的经纬高数据
apX = -4052052.8310;
apY =  4212835.9820;
apZ = -2545104.4760;

apB = -0.4131213;%纬度
apL =  2.3367431;%经度
apH =    603.235;

% 逐行读取文件
while ~feof(file)
    line = fgets(file);
    flag_epo = extractBetween(line,1 ,1 );
    %  判断历元标识
    if strcmp(flag_epo, ">") == 1
        eponum = str2double(extractBetween(line,2 ,5 ));
        while eponum <= 2880
            flag_sat = extractBetween(line,1 ,1);
            %  判断卫星标识，读取卫星PRN号和XYZ坐标
            if strcmp(flag_sat, "G") == 1
                satnum = satnum + 1;
                P_t1(eponum, satnum) = str2double(extractBetween(line,11 + 16 + 16 + 16               ,25 + 16 + 16 + 16 ));
                if P_t1(eponum, satnum) ~= 0
                    prnnum = str2double(extractBetween(line,2 ,3 ));
                    sPRN(eponum, prnnum) = str2double(extractBetween(line,2 ,3 ));
                    satX(eponum, satnum) = str2double(extractBetween(line,11                                   ,25 ));
                    satY(eponum, satnum) = str2double(extractBetween(line,11 + 16                              ,25 + 16 ));
                    satZ(eponum, satnum) = str2double(extractBetween(line,11 + 16 + 16                         ,25 + 16 + 16 ));
                    P_t1(eponum, satnum) = str2double(extractBetween(line,11 + 16 + 16 + 16                    ,25 + 16 + 16 + 16 ));
                    P_t2(eponum, satnum) = str2double(extractBetween(line,11 + 16 + 16 + 16 + 16               ,25 + 16 + 16 + 16 + 16));
                    H(eponum, satnum)    = str2double(extractBetween(line,11 + 16 + 16 + 16 + 16 + 16          ,25 + 16 + 16 + 16 + 16 + 16));
                    TGD(eponum, satnum)  = str2double(extractBetween(line,11 + 16 + 16 + 16 + 16 + 16 + 16     ,25 + 16 + 16 + 16 + 16 + 16 + 16));
                    Dt(eponum, satnum)   = str2double(extractBetween(line,11 + 16 + 16 + 16 + 16 + 16 + 16 + 16,25 + 16 + 16 + 16 + 16 + 16 + 16 + 16));
                    line = fgets(file);
                end
                if P_t1(eponum, satnum) == 0
                    satnum = satnum - 1;
                    line = fgets(file);
                end
            end
            %  开头字符不是G，但是是>,判断为一个历元的起点，进行数据读取
            if strcmp(flag_sat, "G") == 0 && strcmp(flag_sat, ">") == 1
                satnum = 0;
                line = fgets(file);
                continue;
            end
            %  开头字符既不是G，也不是>,判断为历元结束标志，跳出循环
            if strcmp(flag_sat, "G") == 0 && strcmp(flag_sat, ">") == 0 && ~feof(file)
                sat_num(eponum) = satnum;
                satnum = 0;
                break;
            end
        end
    end
    if strcmp(flag_epo, ">") == 0
        continue;
    end
end
fclose(file);

% 平差计算测站位置和接收机钟差解算
for i = 1:1:eponum
    if sat_num(i) >= 4 
        X = zeros(4, 1);
        P = zeros(sat_num(i), sat_num(i));
        B = zeros(sat_num(i), 4);
        l = zeros(sat_num(i), 1);
        X_R = zeros(3, 1);
        
        DeltaXYZ = zeros(3, 1);
%       每个历元构成系数矩阵
        for j = 1:1:sat_num(i)
            R = sqrt((satX(i, j)-apX)^2+(satY(i, j)-apY)^2+(satZ(i, j)-apZ)^2);
            B(j, 1) = -((satX(i, j) - apX) / R);
            B(j, 2) = -((satY(i, j) - apY) / R);
            B(j, 3) = -((satZ(i, j) - apZ) / R);
            B(j, 4) = 1;

% %           简化的Hopfield模型
%             dtrop = 2.47/sind(H(i, j))+0.0121;

% % % % % %             
            P0 = 1013.25; e0 = 11.69; T0 = 288.15;
%           求大气压强
            p = P0 * (1.0 - 0.0068 / T0 / apH)^5;
%           求开尔文温度
            T = 288.15 - 0.0068 * apH;
%           水汽压计算
            if apH  > 11000
                e = 0;
            end
            if apH <= 11000
                e = e0 * (1.0 - 0.0068 * apH / T0)^4;
            end
            deltaSd = 0.00001552 * p / T * (40136 + 148.72 * (T - 273.16) - apH);
            deltaSw = 0.0746512 * e / T^2 * (11000 - apH);
%           对流层延迟干分量
            dtropd = deltaSd / sqrt(sind( rad2deg(deg2rad(H(i, j)) ^ 2) + 6.25 ) );
%           对流层延迟湿分量
            dtropw = deltaSw / sqrt(sind( rad2deg(deg2rad(H(i, j)) ^ 2) + 6.25 ) );
            dtrop = 0.1 * dtropw + 0.9 * dtropd;
% % % % % % % % % % % % % % % % % % % % % % % %

% % % % % % % 理想化的Saastamoinen模型/对流层改正
%             P0 = 1013.25; e0 = 11.69; T0 = 288.15;
% %           求大气压强
%             p = P0 * (1.0 - 0.0068 / T0 / apH)^5;
% %           求开尔文温度
%             T = 288.15 - 0.0068 * apH;
% %           水汽压计算
%             if apH  > 11000
%                 e = 0;
%             end
%             if apH <= 11000
%                  e = e0 * (1.0 - 0.0068 * apH / T0)^4;
%             end
% %           静力学延迟
%             dtrop = 0.002277 * p / (1.0 - 0.00266 * cosd(2 * H(i, j)) - 0.00028 * apH * 1e-3) ;
% % % % % % % % % % % % % % % % % % % % % % % % %


            if P_t2(i, j) ~= 0
%           双频组合消除电离层延迟
            P_t = (f1^2) / (f1^2 - f2^2) * P_t1(i, j) - (f2^2) / (f1^2 - f2^2) * P_t2(i, j);
            end
            if P_t2(i, j) == 0
            P_t = P_t1(i, j);
            end
            l(j, 1) = P_t - R + C_V * Dt(i,j) - dtrop;

            P(j, j) = sind(H(i, j))^2;
        end

        apX_R = apX;%迭代坐标传参
        apY_R = apY;
        apZ_R = apZ;
%       平差计算得到改正数并进行迭代计算
        while abs(apX_R - X_R(1,1)) > 0.0001 && abs(apY_R - X_R(2,1)) > 0.0001 && abs(apZ_R - X_R(3,1)) > 0.0001
            apX_R = X(1,1);
            apY_R = X(2,1);
            apZ_R = X(3,1);
            Q=inv(B.'*P*B);
            D_X=Q*B.'*P*l;%坐标改正数
            X(1,1) = apX + D_X(1,1);
            X(2,1) = apY + D_X(2,1);
            X(3,1) = apZ + D_X(3,1);%改正后测站坐标
            X_R(1,1) = X(1,1);
            X_R(2,1) = X(2,1);
            X_R(3,1) = X(3,1);
             
        end
        GDOP(1,i) = sqrt(trace(Q));

        StationCLK(1,i) = D_X(4, 1);
        DeltaXYZ(1,1) = X(1,1) - apX;
        DeltaXYZ(2,1) = X(2,1) - apY;
        DeltaXYZ(3,1) = X(3,1) - apZ;

        S = [
                      -sin(apL),           cos(apL),        0;
             -sin(apB)*cos(apL), -sin(apB)*sin(apL), cos(apB);
              cos(apB)*cos(apL),  cos(apB)*sin(apL), sin(apB) 
            ];
        
        ENU_R = S * DeltaXYZ;
        ENU(1,i) = ENU_R(1,1);
        ENU(2,i) = ENU_R(2,1);
        ENU(3,i) = ENU_R(3,1);
      
    end
end

%绘制结果图
figure("Position",[200, 700,1000,200],"Name", "East component deviation","NumberTitle","off")
plot(ENU(1,:));%E
box off
figure("Position",[200, 400,1000,200],"Name","North component deviation","NumberTitle","off")
plot(ENU(2,:));%N
box off
figure("Position",[200, 100,1000,200],"Name",   "Up component deviation","NumberTitle","off")
plot(ENU(3,:));%U
box off
