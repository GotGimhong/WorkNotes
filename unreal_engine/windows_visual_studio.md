# Windows 系统 Visual Studio 的安装


## Visual Studio 2019 的安装

以下是必须安装的工作负荷和组件：

+ Visual Studio 核心编辑器

+ 使用 C\+\+ 的游戏开发

    + 【自动包含】C\+\+ 核心功能

    + 【自动包含】Windows 通用 C 运行时

    + 【自动包含】C\+\+ 2019 可再发行程序包更新

    + 【自动包含】MSVC v142 \- VS 2019 C\+\+ x64/x86 生成工具(最新)

    + 【手动包含】Windows 10 SDK (10\.0\.19041\.0)

+ 使用 C\+\+ 的桌面开发

    + 【自动包含】C\+\+ 核心桌面功能

    + 【手动包含】MSVC v142 \- VS 2019 C\+\+ x64/x86 生成工具(最新)

    + 【手动包含】Windows 10 SDK (10\.0\.19041\.0)

    + 【手动包含】MSVC v142 \- VS 2019 C\+\+ ARM64 生成工具(最新)

+ 通用 Windows 平台开发

    + 【自动包含】Blend for Visual Studio

    + 【自动包含】\.NET Native 和 \.NET Standard

    + 【自动包含】NuGet 包管理器

    + 【自动包含】通用 Windows 平台工具

    + 【自动包含】Windows 10 SDK (10\.0\.19041\.0)

+ 单个组件

    + C\# 和 Visual Basic Roslyn 编译器

    + MSBuild

    + \.NET Framework 4\.5 目标包

    + \.NET Framework 4\.6\.2 目标包

    + \.NET Framework 4\.6\.2 SDK

    + MSVC v142 \- VS 2019 C\+\+ ARM64 生成工具(最新)

备注：

+ Windows 10 SDK 的版本并不是固定的，请根据实际情况选择合适的版本

+ 以下工作负荷和组件从 UE5 开始才需要安装，在 UE4 中不需要安装：

    + 使用 C++ 的桌面开发

    + 通用 Windows 平台开发

    + .NET Framework 4.5 目标包

    + MSVC v142 - VS 2019 C++ ARM64 生成工具(最新)


## Visual Studio 2022 的安装

以下是必须安装的工作负荷和组件：

+ Visual Studio 核心编辑器

+ 使用 C++ 的游戏开发

    + 【自动包含】C\+\+ 核心功能

    + 【自动包含】Windows 通用 C 运行时

    + 【自动包含】C\+\+ 2022 可再发行程序包更新

    + 【手动包含】MSVC v143 \- VS 2022 C\+\+ x64/x86 生成工具(最新)

    + 【手动包含】Windows 11 SDK (10\.0\.22000\.0)

+ 使用 C++ 的桌面开发

    + 【自动包含】C\+\+ 核心桌面功能

    + 【手动包含】MSVC v143 \- VS 2022 C\+\+ x64/x86 生成工具(最新)

    + 【手动包含】Windows 11 SDK (10\.0\.22000\.0)

+ 通用 Windows 平台开发

    + 【自动包含】Blend for Visual Studio

    + 【自动包含】\.NET Native 和 \.NET Standard

    + 【自动包含】NuGet 包管理器

    + 【自动包含】通用 Windows 平台工具

    + 【自动包含】Windows 11 SDK (10\.0\.22000\.0)

+ 单个组件

    + \.NET Framework 4\.6\.2 目标包


备注：

+ 经过测试，最适合 UE5\.1 的 VS 版本是 2022。原因是在 UE5\.1 中，UBT（UnrealBuildTool），UHT（UnrealHeaderTool）等核心工具统一使用了 \.NET SDK 6\.0 的 API 来开发，而 VS2019 并不支持 \.NET SDK 6\.0；如果将这些工具的 \.NET 目标（Target）版本改为 5\.0，改用 \.NET SDK 5\.0 编译这些工具（具体做法是在对应的 csproj 文件，例如 UnrealBuildTool\.csproj 文件中，将 `TargetFramework` 字段从 `net6.0` 改成 `net5.0`），就会导致编译错误，提示 \.NET SDK 6\.0 的 API 缺失

+ VS2019 并非完全不可用，但是仅限于引擎使用度有限的情况；如果只是进行相对简单的游戏工程或者是 Demo 的开发，VS2019 是能够满足要求的；如果需要对引擎有更灵活的使用，例如需要定制 UHT，就有必要改用 VS2022

+ 使用 VS2022 编译 UE5\.0 时，可能会遇到 MSB3073 错误，原因是 VS2022 默认安装的 MSVC 编译器版本过高；解决方法是安装一个低版本的 MSVC 编译器，在 BuildConfiguration\.xml 中进行指定，然后重新编译引擎

    可以选用以下版本的 MSVC 编译器：

    + 14\.29\.30133: MSVC v142 \- VS 2019 C\+\+ v14\.29\-16\.11

    + 14\.30\.30705: MSVC v143 \- VS 2022 C\+\+ v14\.30\-17\.0

    + 14\.31\.31103: MSVC v143 \- VS 2022 C\+\+ v14\.31\-17\.1

    BuildConfiguration\.xml 的修改如下：

    ```xml
    <?xml version="1.0" encoding="utf-8" ?>
    <Configuration xmlns="https://www.unrealengine.com/BuildConfiguration">
        <Compiler>VisualStudio2022</Compiler>
        <CompilerVersion>14.30.30705</CompilerVersion>
    </Configuration>
    ```


## 参考资料

+ [UE4.27 - 设置 Visual Studio](https://docs.unrealengine.com/4.27/en-US/ProductionPipelines/DevelopmentSetup/VisualStudioSetup/)

+ [UE5.1 - 设置 Visual Studio](https://docs.unrealengine.com/5.1/en-US/setting-up-visual-studio-development-environment-for-cplusplus-projects-in-unreal-engine/)

+ [当前的 .NET SDK 不支持 .NET 6.0 的解决方法](https://stackoverflow.com/questions/72365082/the-current-net-sdk-does-not-support-targeting-net-6-0-either-target-net-5-0)

+ [UE5编译报错：Error MSB3073](https://zhuanlan.zhihu.com/p/562697309)
