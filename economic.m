function cost=economic(x)


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
 result1=qiantuihuidai1(xxx,Pload(i),yyy);
 sb(i)=result1;
 green=green+( sb(i)*489*0.21*0.001+ sb(i)*0.003*14.842*0.001+ sb(i)*0.01*62.964*0.001);%电网污染费用
end

C_grid=0;
for i=1:24
C_grid=C_grid+sb(i)*grid_price(i);
end
C_all=  C_WT+ C_MT+ C_PV+ C_BA+C_grid+C_DG+ green;



cost=C_all;