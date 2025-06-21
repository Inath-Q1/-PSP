clear
clc
%模型：基于IEEE33节点电网的分布式电源优化调度  其中在 20 7 接了两个光伏 29 16 接两个风电
% 3 24 28 9 12 32 节点依次接了两个 燃气轮机 柴油发电机 储能
%其中 qiantuihuidai1是潮流计算程序  接入位置可以在这里查看  finesss 是适应度函数 成本计算可以在这里查看
% 有问题可以联系我  请不要外传代码 谢谢
format long;
global WT;
global PV;
global WT_price;
global PV_price;
global BT_price;
global Pload;
global DG_price;
global grid_price;
grid_price=load('grid.txt'); %分时电价
load P.mat
Pload=table2array(data)/100000;
load WT.mat
WT=table2array(data);
load PV.mat
PV=table2array(data);

PV=PV/30;
WT=WT/40;
DG_price=0.396; %柴油发电机价格
PV_price=0.336;%光伏价格
BT_price=0.235+0.087;%储能价格
WT_price=0.509;%风电价格
%初始化条件****************************************
%微型燃气轮机最大功率
MTMaxPower=300;
%微型燃气轮机最小功率
MTMinPower=100;
%柴油发电机最大功率
GridMaxImportPower=250;
%柴油发电机最小功率
GridMinImportPower=100;
%储能最大放电功率
StorageMaxDischargingPower=250;
%储能最大充电功率
StorageMaxChargingPower=-200;

Max_Dt=200; 
D=144;
N=150;      
w_max=0.95; 
w_min=0.2;  
v_max=5;    % 增大最大速度限制从3到5
crowding_threshold = 0.05; 
mutation_rate = 0.1;       
s=1;



% 新增参数
crowding_threshold = 0.1; % 拥挤度阈值
mutation_rate = 0.05;     % 变异率

% 初始化种群个体（位置和速度）***********************
for i=1:N
    for j=1:D
        v(i,j)=0.0;
        if j<49
            x(i,j)=MTMinPower+rand()*(MTMaxPower-MTMinPower);
        elseif j>96
            x(i,j)=StorageMaxChargingPower+rand()*(StorageMaxDischargingPower-StorageMaxChargingPower);
        elseif j>48&&j<97
            x(i,j)=GridMinImportPower+rand()*(GridMaxImportPower-GridMinImportPower);
        end
    end    
end

% 初始化适应度值数组
fitness_values = zeros(N,2);

oo=[248.836025668221,202.599416164423,166.494198630985,123.111696636002,202.866506725247,202.861125594650,242.102909733732,235.548660354643,284.485516149875,276.422588148697,233.780505407121,220.178500006218,297.780284028809,100.863575875697,212.996337490365,174.026694615104,179.515995225272,134.127512518142,150.390123306500,207.055493099865,111.311067344063,275.425711475196,254.705788140730,235.567682813465,193.838343843413,172.761093802131,181.633520337349,154.816227644698,185.579891747573,194.426772595660,168.348119922010,269.642523471563,109.171330184822,220.777529215515,189.728293816105,278.446811008100,144.473585748388,209.338530685159,292.728819475653,287.805653234406,255.276530841795,218.470270134246,196.525275207685,143.181026233178,128.895095986248,155.314928183990,202.499127983905,139.216434696685,237.937543999425,218.290271241122,115.103016182943,224.649450741445,217.257376087512,248.141863846984,133.057670451427,241.021007512999,136.292423687319,188.142519919175,221.120041940008,216.657776685665,211.448615165141,239.052570234573,249.865204482559,238.142106563487,213.024727723555,111.358832016195,130.641800374925,141.667145668145,102.255201969535,146.877198806156,196.533672413189,207.064637228093,229.847033650084,209.467160143022,117.916993590261,222.580877439390,103.942154943408,247.952165147164,175.787767715155,231.932043079028,175.952870851028,154.780218497432,226.463076664967,103.743348527819,196.965351614702,164.164253066615,196.281827536177,195.156458272892,200.826770563808,218.027623099870,201.464924375509,134.761384007294,116.624368493318,157.625524012636,219.038490701686,127.237129049592,-18.8104938435840,12.6449972445220,-117.763735909949,14.2067781899308,42.0105185712345,-19.8715764862574,-49.5313225241255,228.356963134336,212.315272336685,36.0389543491393,36.3236150771403,-169.848237459489,-150.966908436866,-42.9060988923272,-73.7879962196773,3.79116398834330,197.696280705504,182.536786513720,117.462970540405,110.982047400986,225.280442389726,209.109196400673,-172.972193167851,44.0640101418510,-171.684873319684,18.2960849157824,31.5607999447231,155.980320234364,-61.8587642223820,-68.0534336444722,34.7513335191343,-46.2292496212675,-18.8229070785433,85.0117190571125,-75.1240316515553,-130.772896568614,15.2199347913970,239.710209731583,185.196565257395,32.4043197365465,-152.406526827120,241.682977766511,70.1483945680432,-36.9830699169090,-123.944897362101,110.377710867087,-136.179184186529,-107.620225605017];
 C_before=economic(oo);  %优化前的成本

%计算各个粒子的适应度，并初始化Pi和Pg****************
for i=1:N
    p(i)=fitness(x(i,:),s);
    y(i,:)=x(i,:);%每个粒子的个体寻优值
end
Pbest=fitness(x(1,:),s);
pg=x(1,:);%Pg为全局最优
for i=2:N
    if fitness(x(i,:),s)<fitness(pg,s)
       Pbest=fitness(x(i,:),s);
       pg=x(i,:);%全局最优更新
    end
end

%进入主循环*****************************************
for t=1:Max_Dt
    % 串行计算适应度值
    for i=1:N
        try
            fitness_values(i,:) = [fitness(x(i,:),t), diversity_metric(x(i,:))];
        catch
            fitness_values(i,:) = [Inf, 0];
            warning('粒子%d适应度计算失败',i);
        end
    end
    
    % 简化非支配排序计算
    [~, ranks] =non_dominated_sorting(x, fitness_values);  % 使用简化版排序
    
    % 预计算邻居索引
    prev_indices = mod((1:N)-2,N)+1;
    next_indices = mod((1:N),N)+1;
    
    % 串行更新粒子
    for i=1:N
        % 动态参数计算
        w = w_max-(w_max-w_min)*t/Max_Dt;
        c1 = 2.5; % 固定认知系数
        c2 = 2.5; % 固定社会系数
        
        % 速度更新简化
        v(i,:) = w*v(i,:) + c1*rand()*(y(i,:)-x(i,:)) + c2*rand()*(pg-x(i,:));
        
        % 限制速度
        v(i,:) = min(max(v(i,:), -v_max), v_max);
        x(i,:) = x(i,:) + v(i,:);
    end
    
    % 记录最优值
    [Pbest, best_idx] = min(fitness_values(:,1));
    pg = x(best_idx,:);
    uu(t) = Pbest;
end

disp('*************************************************************')

disp('函数的全局最优位置为：')

Solution=pg'
for m=1:24
    pg1(m)=pg(m);
end
for m=25:48
    pg2(m-24)=pg(m);
end
for m=49:72
    pg3(m-48)=pg(m);
end


for m=73:96
    pg4(m-72)=pg(m);
end
for m=97:120
      pg5(m-96)=pg(m);
end
for m=121:144
     pg6(m-120)=pg(m);
end


figure(1)
plot(uu,'Color',[0.19608 0.80392 0.19608],'LineWidth', 2)
title('适应度函数迭代收敛图')
xlabel('迭代次数')
ylabel('适应度函数')



figure(2)
plot( pg1,'->','Color',[0.6 0.19608 0.8],'MarkerEdgeColor', 'k','MarkerFaceColor','b','LineWidth', 2)
hold on 
plot( pg2,'-o','Color',[0.86667 0.62745 0.86667],'MarkerEdgeColor', 'k','MarkerFaceColor','b','LineWidth', 2)
xlim([1 24])
title('燃气轮机运行计划')
legend('MT1','MT2');

figure(4)
plot( pg3,'-s','Color',[1 0.64706 0],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
hold on 
plot( pg4,'-o','Color',[1 0.27059 0],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
xlim([1 24])
title('柴油发电机运行计划')
legend('DG1','DG2');

figure(5)
plot( pg5,'-d','Color',[1 1 0],'MarkerEdgeColor', 'k','MarkerFaceColor','y','LineWidth', 2)
hold on 
plot( pg6,'-s','Color',[1 0.84314 0],'MarkerEdgeColor', 'k','MarkerFaceColor','y','LineWidth', 2)
xlim([1 24])
title('储能运行计划')
legend('BT1','BT2');


figure(3)
subplot(211)
plot( PV,'-d','Color',[1 0.84314 0],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
xlim([1 24])
title('光伏发电出力')
subplot(212)
plot( WT,'-s','Color',[0.25098 0.87843 0.81569],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
xlim([1 24])
title('风力发电出力')


figure(8)
plot( Pload*39000,'-d','Color',[0.69804 0.13333 0.13333],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
xlim([1 24])
title('负荷变化')


Result=economic(pg);

disp('*************************************************************')
  disp('优化前')
   C_before
     disp('优化后')
Result


for i=1:24
    xxx=[pg(i),pg(i+24),pg(i+48),pg(i+72),pg(i+96),pg(i+120)];
    yyy=[PV(i),PV(i),WT(i),WT(i)];
 result1=qiantuihuidai1(xxx,Pload(i),yyy);
 SB(i)=result1;
 
end

figure(9)
plot(SB,'-d','Color',[0.6 0.19608 0.8],'MarkerEdgeColor', 'k','MarkerFaceColor','r','LineWidth', 2)
xlim([1 24])
title('购电功率')

