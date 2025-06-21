function result=fitness(x,s)

P_BA_sum=0;
P_BA_sum_delt=0;
%储能荷电状态%
BAsocMax=250;
BAsocMin=-200;
global WT;
global PV;
global Pload;
global PV_price;
global BT_price;
global WT_price;
global DG_price;
global grid_price;
C_MT=0;
C_PV=0;
C_WT=0;
C_BA=0;
  C_DG=0;
    green=0;
    for i=1:24
    C_PV=C_PV+2*(PV_price+0.0096)*PV(i);  %风电光伏的运行维护成本
    C_WT= C_WT+2*(WT_price+0.0296)*WT(i);
    end
for i=1:144
    if i<49
      C_MT=C_MT+(0.0006*x(i)^2+(0.3+0.088)*x(i)+40);
    elseif i>48&&i<97
           
            C_DG=C_DG+(DG_price+0.0293)*x(i);
      green=green+(x(i)*649*0.21*0.001+x(i)*0.206*14.842*0.001+x(i)*9.89*62.964*0.001);%柴油发电机污染费用
      
    elseif i>96
     C_BA=C_BA+(BT_price+0.026)*abs(x(i));
      green=green+(abs(x(i))*489*0.21*0.001+abs(x(i))*0.003*14.842*0.001+abs(x(i))*0.01*62.964*0.001);%燃料电池污染费用
    end
end

for i=1:24
    xxx=[x(i),x(i+24),x(i+48),x(i+72),x(i+96),x(i+120)];
    yyy=[PV(i),PV(i),WT(i),WT(i)];
    % 添加异常处理机制
    try
        result1 = qiantuihuidai1(xxx,Pload(i),yyy);
    catch ME
        warning('潮流计算异常: %s', ME.message);
        result1 = 0; % 设置默认值
    end
    
    SB(i) = result1;
 green=green+( SB(i)*489*0.21*0.001+ SB(i)*0.003*14.842*0.001+ SB(i)*0.01*62.964*0.001);%电网污染费用
end
C_grid=0;
for i=1:24
C_grid=C_grid+SB(i)*grid_price(i);
end
C_all=  C_WT+ C_MT+ C_PV+ C_BA+C_grid+C_DG+ green;
for i=97:120 %储能SOC约束
      P_BA_sum=P_BA_sum+x(i);
      if  P_BA_sum>BAsocMax
    P_BA_sum_delt= P_BA_sum_delt+max(0,P_BA_sum-BAsocMax); 
      end
      if   P_BA_sum<BAsocMin
    P_BA_sum_delt= P_BA_sum_delt+abs(P_BA_sum-BAsocMin); 
      end
end 
   P_BA_sum=0;
for i=121:144 %储能SOC约束
      P_BA_sum=P_BA_sum+x(i);
      if  P_BA_sum>BAsocMax
    P_BA_sum_delt= P_BA_sum_delt+max(0,P_BA_sum-BAsocMax); 
      end
      if   P_BA_sum<BAsocMin
    P_BA_sum_delt= P_BA_sum_delt+abs(P_BA_sum-BAsocMin); 
      end
end 






if(P_BA_sum_delt<=0)
    d=0;
elseif(P_BA_sum_delt>0&&P_BA_sum_delt<=10)
   d=1;%%%%%迭代次数
elseif(P_BA_sum_delt>10&&P_BA_sum_delt<50)
    d=2;
elseif(P_BA_sum_delt>50&&P_BA_sum_delt<=100)
    d=5;
else
    d=20;
end


 
result=C_all+d*P_BA_sum_delt;







