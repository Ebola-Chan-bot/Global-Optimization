埃博拉酱的全局优化工具包，提供巧妙的全局优化类应用

本项目的发布版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)规范。开发者认为这是一个优秀的规范，并向每一位开发者推荐遵守此规范。
# 目录
本包中所有函数均在命名空间GlobalOptimization下，使用前需import。使用命名空间是一个好习惯，可以有效防止命名冲突，避免编码时不必要的代码提示干扰。
```MATLAB
import GlobalOptimization.*
```
- [ColorAllocate](#ColorAllocate) 根据人类视觉特点，提供最显眼的作图配色方案
# ColorAllocate
根据人类视觉特点，提供最显眼的作图配色方案
```MATLAB
import GlobalOptimization.ColorAllocate
ColorAllocate(3,[0 0 0])%在黑色背景下作三色图的最优配色方案
ColorAllocate(4,[1 1 1])%在白色背景下作四色图的最优配色方案
ColorAllocate(2,[0 0 0;1 1 1])%在黑白交织背景下选择两种最醒目的颜色
```
此函数会在userpath下生成一个+GlobalOptimization缓存目录，用于加速以后的函数调用。如果函数工作不正常，可以尝试删除此目录。
## 输入参数
NoColors(1,1)，必需，要分配的颜色数目

ColorsToAvoid(:,3)double=\[]，可选，要避免的颜色。作图通常需要在具有特定颜色的背景上进行，您应当将背景色输入本函数，否则本函数可能会分配过于接近背景色的颜色方案。每行提供一种要避免颜色的RGB三元向量，数值应在\[0,1]范围内
## 返回值
Colors(:,3)double，分配的RGB颜色三元向量，每行一种颜色

MinDistance(1,1)double，色差最小的两种颜色的视觉差异。该值越大，配色方案就越对比鲜明。