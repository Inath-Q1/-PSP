function result1=qiantuihuidai1(x,pload_flex,P_new)
SB=1;%单位MVA
UB=12.66;%单位kV
%采用33节点算例
%第一列：节点号，第二列：负荷有功（kW），第三列：负荷无功(kvar)
 Bus=[1.0000     0     0             
      2.0000    100   60
      3.0000    90    40
      4.0000    120   80
      5.0000    60    30
      6.0000    60    20
      7.0000    200   100
      8.0000    200   100
      9.0000    60    20
     10.0000    60    20
     11.0000    45    30
     12.0000    60    35
     13.0000    60    35
     14.0000    120   80
     15.0000    60    10
     16.0000    60    20
     17.0000    60    20
     18.0000    90    40
     19.0000    90    40
     20.0000    90    40
     21.0000    90    40
     22.0000    90    40
     23.0000    90    50
     24.0000    420   200
     25.0000    420   200
     26.0000    60    25
     27.0000    60    25
     28.0000    60    20
     29.0000    120   70
     30.0000    200   600
     31.0000    150   70
     32.0000    210   100
     33.0000    60    40];
 
 %第1列存支路号，第2列存支路首节点，第3列存支路尾节点，第4存支路电阻，第5列存支路电抗 （欧姆）
Branch=[1  1  2  0.0922	 0.047
        2  2  3  0.4930	 0.2511
        3  3  4  0.3660	 0.1864
        4  4  5  0.3811	 0.1941
        5  5  6  0.8190	 0.7070
        6  6  7  0.1872	 0.6188
        7  7  8  0.7114	 0.2351
        8  8  9  1.0300	 0.7400
        9  9  10 1.0440     0.7400
        10 10 11  0.1966    0.0650
        11 11 12  0.3744    0.1238
        12 12 13  1.4680	1.1550
        13 13 14  0.5416	 0.7129
        14 14 15  0.5910	 0.5260
        15 15 16  0.7463	 0.5450
        16 16 17   1.2890	 1.7210
        17 17  18  0.3720	 0.5740
        18  2 19  0.1640	 0.1565
        19  19 20 1.5042	 1.3554
        20  20 21 0.4095	 0.4784
        21  21 22 0.7089	 0.9373
        22  3  23 0.4512	 0.3083
        23  23 24 0.8980	 0.7091
        24  24 25 0.8960	 0.7011
        25  6  26 0.2030	 0.1034
        26  26 27 0.2842	 0.1447
        27  27 28 1.0590	 0.9337
        28  28 29 0.8042	 0.7006
        29  29 30 0.5075	 0.2585
        30  30 31 0.9744	 0.9630
        31  31 32 0.3105	 0.3619
        32  32 33 0.3410	 0.5302];
%归算

Bus(:,2)=Bus(:,2)*pload_flex; %负荷波动变化
Bus(:,3)=Bus(:,3)*pload_flex;

WEI_new=[20 7 29 16 ];  %光伏 风电接入的位置  先光伏 后风电

pnew_flex=0.9+0.2*rand();%考虑风光不确定性 功率波动为0.9~1.1
for kk=1:4
 Bus(WEI_new(kk),2)= Bus(WEI_new(kk),2)-P_new(kk)*pnew_flex;
 Bus(WEI_new(kk),3)= Bus(WEI_new(kk),3)-P_new(kk)*pnew_flex*0.484;
end


WEI=[3 24 28 9 12 32 ]; %燃气轮机 柴油发电机 储能
for kk=1:6
 Bus(WEI(kk),2)= Bus(WEI(kk),2)-x(kk);
 Bus(WEI(kk),3)= Bus(WEI(kk),3)-x(kk)*0.484;
end

Bus(:,2)=Bus(:,2)/1000/SB;
Bus(:,3)=Bus(:,3)/1000/SB;

Branch(:,4)=Branch(:,4)*SB/UB^2;
Branch(:,5)=Branch(:,5)*SB/UB^2;



%设置电压初始值
[busnum,dump1]=size(Bus);
Vbus=ones(busnum,1);     
Vbus(1,1)=1;%平衡节点电压
cita=zeros(busnum,1);
[branchnum,dump2]=size(Branch);

k=0;  %迭代次数
Ploss=zeros(branchnum,1);%存支路的有功损耗  
Qloss=zeros(branchnum,1);%支路无功损耗
P=zeros(branchnum,1);%存支路的有功  
Q=zeros(branchnum,1);%支路无功
I=zeros(branchnum,1);
F=0;%迭代收敛标志
%%本段程序将支路重新排序   s1为排好序的支路矩阵
TempBranch=Branch;
n=1;
s2=[];         %这段重新排列支路应该没有问题
while ~isempty(TempBranch)   %判断是否为空
    [s,dump3]=size(TempBranch);%s为支路数  
    m=1;
    while s>0
       i=find(TempBranch(:,2)==TempBranch(s,3));%末端节点是否为其他支路首端节点
        if isempty(i)
            s1(n,:)=TempBranch(s,:);%如果i是空集则该节点为叶节点
            n=n+1;
        else s2(m,:)=TempBranch(s,:);%如果i不是空集则该节点为非叶节点
            m=m+1;
        end
        s=s-1;
   end
    TempBranch=s2;             %将s2赋值给TempBranch.重复上述判断，直到TempBranch为空集为止
    s2=[];
end
    %前推进行支路功率计算
    Bus1=Bus;
    while (k<100)&&(F==0)  
    Pij1=zeros(busnum,1); %该支路首端节点及与其相连的其他后续支路的功率情况
    Qij1=zeros(busnum,1);
   
    
      
      for s=1:branchnum        
        ii=s1(s,2);      %取排好序的支路首节点   
        jj=s1(s,3);      %取排好序的支路尾节点  
        Pload=Bus(jj,2);
        Qload=Bus(jj,3); %节点有功和无功负荷
        R=s1(s,4);
        X=s1(s,5);
        VV=Vbus(jj,1);
        Pij0=Pij1(jj); %该支路末端节点的后续功率
        Qij0=Qij1(jj);
        II=((Pload+Pij0)^2+(Qload+Qij0)^2)/(VV^2);    %支路电流的平方
        Ploss(s1(s,1))=II*R;                          %支路有功和无功损耗    这里有待改进。显现Ploss
        Qloss(s1(s,1))=II*X;
        P(s1(s,1))=Pload+Ploss(s1(s,1))+Pij0;       %支路功率，包括后续节点功率和网络损耗
        Q(s1(s,1))=Qload+Qloss(s1(s,1))+Qij0;
        Pij1(ii)=Pij1(ii)+P(s1(s,1));               %支路首端功率单位MW
        Qij1(ii)=Qij1(ii)+Q(s1(s,1));
    end
    %%回推计算节点电压
for s=branchnum:-1:1
    ii=s1(s,3); 
    kk=s1(s,2);
    R=s1(s,4);
    X=s1(s,5);
    Vbus(ii,1)=(Vbus(kk,1)-(P(s1(s,1))*R+Q(s1(s,1))*X)/Vbus(kk,1))^2+((P(s1(s,1))*X-Q(s1(s,1))*R)/Vbus(kk,1))^2;
    cita(ii,1)=cita(kk,1)-atan(((P(s1(s,1))*X-Q(s1(s,1))*R)/Vbus(kk,1))/(Vbus(kk,1)-(P(s1(s,1))*R+Q(s1(s,1))*X)/Vbus(kk,1)));
    Vbus(ii,1)=sqrt(Vbus(ii,1));%计算出节点电压幅值
end
 

   %利用上步电压前推再次计算支路功率
    Pij2=zeros(busnum,1); 
    Qij2=zeros(busnum,1);
    
 for s=1:branchnum        
        ii=s1(s,2);        
        jj=s1(s,3);
        Pload=Bus(jj,2);
        Qload=Bus(jj,3);%节点有功和无功负荷
        R=s1(s,4);
        X=s1(s,5);
        VV=Vbus(jj,1);
        Pij0=Pij2(jj);%该支路末端节点的后续功率
        Qij0=Qij2(jj);
        II=((Pload+Pij0)^2+(Qload+Qij0)^2)/(VV^2);%支路电流的平方
        I(s1(s,1))=sqrt(II)*1000;                         %单位A
        Ploss(s1(s,1))=II*R;                          %支路有功和无功损耗  
        Qloss(s1(s,1))=II*X;
        P(s1(s,1))=Pload+Ploss(s1(s,1))+Pij0;       %支路功率，包括后续节点功率和网络损耗
        Q(s1(s,1))=Qload+Qloss(s1(s,1))+Qij0;
        Pij2(ii)=Pij2(ii)+P(s1(s,1));           %支路首端功率
        Qij2(ii)=Qij2(ii)+Q(s1(s,1));
 end
 
   
     ddp=max(abs(Pij1(:,1)-Pij2(:,1)));
     ddq=max(abs(Qij1(:,1)-Qij2(:,1)));
     pr=1e-3;%精度
     
     L1=(ddp<pr)&&(ddq<pr); 

     F=L1;
     k=k+1;
    end
if k==10
    disp('潮流不收敛！')
    Pij2(1)=3.9;
end
    
    P1=0;Q1=0;
 for s=1:branchnum    %计算总有功损耗 和 总无功损耗
     P1=P1+Ploss(s);
     Q1=Q1+Qloss(s);
 end


result1= Pij2(1)*1000;

 

 
%  disp('节点电压幅值')
%  Vbus
%  disp('节点电压相角（度）')
%  cita*180/pi
% disp('支路号   首节点   末节点   支路功率(kW)   支路损耗(kvar)')
% [Branch(:,1:3) (P+1i*Q)*1000*SB  (Ploss+1i*Qloss)*1000*SB]
%  disp('总损耗')
%  (P1+1i*Q1)*1000*SB
%  disp('迭代次数：')
%  k
 

