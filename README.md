# Hexagonal Cellular Automaton (about-life)

基于 Swift 语言实现的二维六边形网格（Hexagonal Grid）多阶能量细胞自动机。本项目成功将康威生命游戏（Conway's Game of Life）的离散数学模型拓展至六边形轴向坐标系，并引入了带饱和限幅的离散积分动力学系统。

## 核心技术特性

- **六边形轴向坐标数学建模**：采用经典 $q, r$ 轴向坐标系，通过引入隐藏 $s$ 轴（满足 $q + r + s = 0$）的浮点数舍入算法，实现高精度的触控点阵对齐与稀疏矩阵动态定位。
- **跨框架接驳优化**：轻量化 SwiftUI（负责全屏材质控制岛、持久化规则配置）与高性能 SpriteKit（负责 2D 物理 Tick 帧循环与高性能细胞演化渲染）的异步穿透。
- **稀疏矩阵空间演化**：演化区域打破了传统网格的边界限制。算法未遍历全局死格子，而是通过对活跃细胞及其邻居建立动态候选集（Candidates Set），实现 $O(N)$ 复杂度的空间演化，有效对冲极限状态下的计算开销。

## 演化法则 (Dynamic Rules)

系统打破了传统二值（生/死）状态，引入 0~3 级多阶能量跃迁模型。格子的状态由周围 6 个邻居的能量总和 ($\text{Sum}$) 共同决定：
1. **衰变（Decay）**：$\text{Sum} \le \text{limitLower} \implies$ 能量降低 1 级。
2. **生长（Growth）**：$\text{limitLower} < \text{Sum} \le \text{limitUpper} \implies$ 能量提升 1 级。
3. **过载（Overload）**：$\text{Sum} > \text{limitUpper} \implies$ 能量直接归零。
