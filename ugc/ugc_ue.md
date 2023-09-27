# 使用虚幻引擎开发 UGC 项目

以下是使用虚幻引擎开发 UGC 项目时的记录和总结。关于 UGC 项目的整体设计，请见 [UGC 项目的设计](ugc/ugc_design.md) 。


## 虚幻引擎的定制

Studio 的主体是虚幻引擎本身，在开发过程中需要对虚幻引擎进行深度定制，为此在 UGC 项目中有必要接入一份虚幻引擎的源码

<!-- 定制引擎的目录结构；哪些需要保留，哪些不需要 -->

<!-- 把部分目录迁移至 Engine 目录下 -->


## Studio: Source 分支的搭建

<!-- 什么是 Source 分支 -->

<!-- 定制引擎的注册，解决方案的生成 -->


## Studio: Lite 分支的搭建

<!-- 什么是 Lite 分支 -->

<!-- 哪些可以外链自 Source 分支，哪些需要自行管理 -->

<!-- 定制引擎的注册 -->

<!-- 自动编译流程，定制引擎编译结果的优化 -->


## Lua 多虚拟机的支持

Studio 部分，编辑器（编辑时）和玩法（运行时）各自维护一个 Lua 虚拟机。后者的启动和关闭时机与游戏项目的做法相同，前者则需要注意。

编辑时的 Lua 虚拟机，应该在 `FCoreDelegates::OnAllModuleLoadingPhasesComplete` 事件广播时启动，在 `FCoreDelegates::OnPreExit` 事件广播时关闭，而不是在模块的 `StartupModule` 和 `ShutdownModule` 函数中启动和关闭。
