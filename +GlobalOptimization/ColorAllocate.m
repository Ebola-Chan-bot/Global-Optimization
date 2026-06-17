%[text] 根据人类视觉特点，提供最显眼的作图配色方案
%[text] 作图时经常陷入如何挑选最优配色方案的顾虑。对于不同颜色数目的需求，往往有截然不同的配色方案。本函数解决此问题，输入需要的颜色数量，直接输出对人类视觉来说最为醒目、高对比的最佳配色方案！
%[text] 此函数会在userpath下生成一个全局优化缓存目录，用于保存优化结果，加速以后的函数调用。如果函数工作不正常，可以尝试删除此目录。
%[text] ## 语法
%[text] ```matlabCodeExample
%[text] [Colors,Distance]=GlobalOptimization.ColorAllocate(NumColors);
%[text] %生成指定数目的最佳颜色分配方案
%[text] 
%[text] [___]=GlobalOptimization.ColorAllocate(NumColors,ColorsToAvoid);
%[text] %与上述任意语法组合使用，额外指定要回避的颜色
%[text] 
%[text] [___]=GlobalOptimization.ColorAllocate(___,DistanceFun);
%[text] %与上述任意语法组合使用，额外指定颜色距离函数
%[text] 
%[text] [___]=GlobalOptimization.ColorAllocate(___,Effort);
%[text] %与上述任意语法组合使用，额外指定优化力度
%[text] ```
%[text] ## 示例
%[text] ```matlabCodeExample
%[text] import GlobalOptimization.ColorAllocate
%[text] ColorAllocate(3)%作三色图的最优配色方案
%[text] ColorAllocate(3,[0 0 0])%作三色图的最优配色方案，但回避黑色
%[text] ColorAllocate(4,[1 1 1])%作四色图的最优配色方案，但回避白色
%[text] ColorAllocate(2,[0 0 0;1 1 1])%作二色图的最优配色方案，回避黑色和白色
%[text] ColorAllocate(2,[255,255,255])%作二色图的最优配色方案，回避白色，返回uint8表示的颜色
%[text] ColorAllocate(2,[255,255,255;255,255,255])%白色是背景色，需要加倍回避
%[text] ```
%[text] ## 输入参数
%[text] NumColors(1,1)，要分配的颜色数目
%[text] ColorsToAvoid(:,3)，要避免的颜色。图中已存在某种颜色的元素时，应当回避该颜色。此外，通常还应当加倍回避背景色，此时可以将背景色重复两行以起到加权回避的作用，使得分配的颜色在背景色的环绕下尤为醒目。
%[text] Effort(1,1)=4，优化力度。此值越大越有可能找到最优配色，但耗时也越长。
%[text] ### DistanceFun
%[text] function\_handle，颜色距离计算函数，用于优化不同颜色间的最小距离。此函数应设计为向量化的，可以一次调用计算多组颜色距离。
%[text] #### 语法
%[text] ```matlabCodeExample
%[text] Distance=DistanceFun(Colors)
%[text] ```
%[text] #### 输入参数
%[text] Colors(:,:,3)，要计算距离的颜色。第1维是不同的向量化分组，第2维是要计算距离的不同颜色（回避色总是排在末尾），第3维是RGB。
%[text] #### 返回值
%[text] Distances，距离值。若返回向量或矩阵，优化目标为最大化其中的最小值（max-min）；若返回标量，优化目标为最大化该标量值。
%[text] ## 返回值
%[text] Colors(NumColors,3)，分配的RGB颜色三元向量，每行一种颜色。如果ColorsToAvoid是\[0,1\]范围的浮点数，Colors也将是\[0,1\]范围的浮点数；否则，Colors将用uint8类型表示RGB颜色。
%[text] Distance(1,1)double，优化配色方案的视觉差异。该值越大，配色方案就越对比鲜明。
%[text] ## 算法
%[text] 使用 fmincon 多起点并行搜索 + patternsearch 精细打磨，在连续 RGB 空间中直接最大化所有颜色两两之间
%[text] 的最小 CIEDE2000 色差（max-min 优化）。fmincon 起点数为 Effort×NumColors。
%[text] patternsearch 以 fmincon 结果为起点进一步打磨，消除非光滑瓶颈切换导致的停滞。
%[text] **See also** [fmincon](<matlab:doc fmincon>) [imcolordiff](<matlab:doc imcolordiff>) [userpath](<matlab:doc userpath>)
function [Colors,Distance] = ColorAllocate(NumColors,varargin)
ColorsToAvoid=NaN(0,3);
DistanceFun=function_handle.empty;
Effort=4;
for V=1:numel(varargin)
	Arg=varargin{V};
	if isscalar(Arg)
		if isreal(Arg)
			Effort=Arg;
		else
			DistanceFun=Arg;
		end
	else
		ColorsToAvoid=Arg;
	end
end
persistent CachePath Cache
if ~NumColors
	Colors=zeros(NumColors,3);
	Distance=0;
	return;
end
if isempty(CachePath)
	CachePath=fullfile(userpath,'全局优化缓存');
	if ~isfolder(CachePath)
		mkdir(CachePath);
	end
	CachePath=fullfile(CachePath,'颜色方案.mat');
	if isfile(CachePath)
		Cache=load(CachePath);
		if isfield(Cache,'Cache')
			Cache=Cache.Cache;
		else
			Cache=dictionary;
		end
	else
		Cache=dictionary;
	end
end
ByteMode=isinteger(ColorsToAvoid)||any(ColorsToAvoid>1,'all');
ColorsToAvoid=double(ColorsToAvoid);
if ByteMode
	ColorsToAvoid=ColorsToAvoid/255;
end
Key={{NumColors,ColorsToAvoid,Effort,DistanceFun}};
persistent fminOpts
if isempty(fminOpts)
	fminOpts=optimoptions('fmincon',Display='off');
end
try
	Colors=Cache(Key);
	Colors=Colors{1};
catch
	ColorsToAvoid3D=reshape(ColorsToAvoid,[],1,3);
	% fmincon 多起点并行 + patternsearch 精细打磨
	AllColors=OptimizeSubset(NumColors,ColorsToAvoid3D,DistanceFun,Effort,fminOpts);
	Colors=AllColors;
	Cache(Key)={Colors};
	save(CachePath,'Cache');
end
if nargout>1
	Distance=PairsMinCIEDE2000(Colors,reshape(ColorsToAvoid,[],3));
end
if ByteMode
	Colors=uint8(Colors*255);
end
end
%%
function Colors=OptimizeSubset(NumColors,ColorsToAvoid3D,DistanceFun,Effort,fminOpts,WarmStart)
% fmincon 多起点并行优化 + patternsearch 精细打磨
% WarmStart: 可选的当前颜色 (NumColors×3)，作为起点之一
nVars=NumColors*3;
NStarts=Effort*NumColors;
XTrials=cell(NStarts,1);
FTrials=zeros(NStarts,1);
x0=rand(NStarts,nVars);
if nargin>5 && ~isempty(WarmStart)
	x0(1,:)=WarmStart(:)';
end
persistent psOpts
if isempty(psOpts)
	psOpts=optimoptions('patternsearch',Display='off',MeshTolerance=1e-10,StepTolerance=1e-10);
end
parfor k=1:NStarts
	[Xf,~]=fmincon(@(x)ColorObjective(x,ColorsToAvoid3D,NumColors,DistanceFun),x0(k,:),...
		[],[],[],[],zeros(1,nVars),ones(1,nVars),[],fminOpts);
	% patternsearch 精细打磨：消除非光滑瓶颈切换导致的停滞
	[XTrial,FTrial]=patternsearch(@(x)ColorObjective(x,ColorsToAvoid3D,NumColors,DistanceFun),Xf,...
		[],[],[],[],zeros(1,nVars),ones(1,nVars),[],psOpts);
	XTrials{k}=XTrial;
	FTrials(k)=FTrial;
end
[~,Idx]=min(FTrials);
Colors=reshape(XTrials{Idx},3,[])';
end
%%
function D=ColorObjective(X,AvoidColors3D,NumColorsIn,DistanceFun)
% 向量化目标函数：最大化最小感知距离（max-min），即最小化 -min(d)
% X — (nGroups,nVars)，每行是一组展平的颜色向量
% AvoidColors3D — (nAvoid,1,3)
% 返回 (nGroups,1)，粒子群要求返回列向量
nGroups=size(X,1);
% 拼接回避色（每组都相同，reshape 为 (1,nAvoid,3) 后复制到每组）
AllColors=cat(2,permute(reshape(X',3,NumColorsIn,nGroups),[3 2 1]),repmat(reshape(AvoidColors3D,1,[],3),nGroups,1,1)); % (nGroups,nTotal,3)
% 生成所有不重复颜色对的下标
[I,J]=find(triu(ones(NumColorsIn+height(AvoidColors3D)),1));
nPairs=length(I);
% 向量化提取所有颜色对（跨所有组堆叠）
P1=zeros(nGroups*nPairs,3);
P2=zeros(nGroups*nPairs,3);
for G=1:nGroups
	Idx=(G-1)*nPairs+(1:nPairs);
	P1(Idx,:)=AllColors(G,I,:);
	P2(Idx,:)=AllColors(G,J,:);
end
% 回避色之间的相互距离排除
AvoidMask=(I>NumColorsIn)&(J>NumColorsIn);
if isempty(DistanceFun)
	% 默认 CIEDE2000：一次大矩阵调用
	D=imcolordiff(P1,P2,Standard="CIEDE2000");
	D=reshape(D,nGroups,nPairs);
	D(:,AvoidMask)=Inf;
else
	% 自定义距离函数：传入 (nGroups,nTotal,3) 未配对颜色，返回距离值
	% 注意：回避色总是排在 dim2 末尾（位置 NumColorsIn+1 : nTotal）
	D=DistanceFun(AllColors);
	% 若返回矩阵，排除回避色之间的列
	if size(D,2)==nPairs
		D(:,AvoidMask)=Inf;
	end
end
D=-min(D,[],2);
end
%%
function D=PairsMinCIEDE2000(Colors,AvoidColors)
% 计算一组颜色的最小 CIEDE2000 色差（排除回避色之间）
AllColors=[Colors;AvoidColors];
nMain=size(Colors,1);
nTotal=size(AllColors,1);
[I,J]=find(triu(ones(nTotal),1));
D=imcolordiff(AllColors(I,:),AllColors(J,:),Standard="CIEDE2000");
D((I>nMain)&(J>nMain))=[];
D=min(D);
end

%[appendix]{"version":"1.0"}
%---
