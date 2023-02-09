# Windows 系统 Visual Studio 的安装


## Visual Studio 2019 的安装

以下是必须安装的工作负荷和组件：

+ Visual Studio 核心编辑器

+ 使用 C++ 的游戏开发

    + 【自动包含】C++ 核心功能

    + 【自动包含】Windows 通用 C 运行时

    + 【自动包含】C++ 2019 可再发行程序包更新

    + 【自动包含】MSVC v142 - VS 2019 C++ x64/x86 生成工具(最新)

    + 【手动包含】Windows 10 SDK (10.0.19041.0)

+ 使用 C++ 的桌面开发

    + 【自动包含】C++ 核心桌面功能

    + 【手动包含】MSVC v142 - VS 2019 C++ x64/x86 生成工具(最新)

    + 【手动包含】Windows 10 SDK (10.0.19041.0)

    + 【手动包含】MSVC v142 - VS 2019 C++ ARM64 生成工具(最新)

+ 通用 Windows 平台开发

    + 【自动包含】Blend for Visual Studio

    + 【自动包含】.NET Native 和 .NET Standard

    + 【自动包含】NuGet 包管理器

    + 【自动包含】通用 Windows 平台工具

    + 【自动包含】Windows 10 SDK (10.0.19041.0)

+ 单个组件

    + C# 和 Visual Basic Roslyn 编译器

    + MSBuild

    + .NET Framework 4.5 目标包

    + .NET Framework 4.6.2 目标包

    + .NET Framework 4.6.2 SDK

    + MSVC v142 - VS 2019 C++ ARM64 生成工具(最新)

备注：

+ Windows 10 SDK 的版本并不是固定的，请根据实际情况选择合适的版本

+ 以下工作负荷和组件从 UE5 开始才需要安装，在 UE4 中不需要安装：

    + 使用 C++ 的桌面开发

    + 通用 Windows 平台开发

    + .NET Framework 4.5 目标包

    + MSVC v142 - VS 2019 C++ ARM64 生成工具(最新)


## 参考资料

+ [UE4.27 - 设置 Visual Studio](https://docs.unrealengine.com/4.27/en-US/ProductionPipelines/DevelopmentSetup/VisualStudioSetup/)

+ [UE5.1 - 设置 Visual Studio](https://docs.unrealengine.com/5.1/en-US/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine/)
