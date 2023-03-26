# 在 Windows 系统上构建 Metal Library


## 基本说明

对于 Apple 系列的平台，通常需要将 Shader 编译为 Metal Library，而非烘焙为 Shader Bytecode。Metal Library 相较于 Shader Bytecode 有更多的优势，例如编译效率更高。

在4.26版本之前的引擎中，远程打包方式对于构建 Metal Library 的支持度很低。如果需要构建 Metal Library，一般的做法是完全使用 Mac 版本引擎进行打包，或者将 Shader 源文件发送至 Mac 设备上进行远程编译。两种做法在本质上是相同的，都是利用 Mac 系统的 Metal 命令行工具完成 Metal Library 的构建，而且都需要额外维护一个 Mac 版本的引擎。

从4.26版本开始，引擎增加了对于 Metal Developer Tools 的支持。Metal Developer Tools 是 Apple 发布的一个用于在 Windows 系统上构建 Metal Library 的工具，相当于是 Windows 版本的 Metal 命令行工具。利用这个工具，即便使用远程打包，也能完成 Metal Library 的构建，无需再借助 Mac 版本的引擎进行打包。


## 部署方式

首先，请从 Apple 开发者官网上下载最新版本的 Metal Developer Tools，然后传送至 Windows 设备上安装。安装时，请确保同时安装 **iOS Toolchain** 和 **macOS Toolchain** 两个组件，否则引擎会无法识别已安装的 Metal Developer Tools。

![](windows_metal_library/install_wizard.png)

安装完成后，运行项目，在 `项目设置 / iOS / Build` 中找到配置项 `Override location of Metal toolchain `，填入 Metal Developer Tools 的安装路径。

![](windows_metal_library/project_settings.png)

或者直接在 DefaultEngine.ini 中增加以下内容，两种做法是等价的：

```ini
[/Script/IOSRuntimeSettings.IOSRuntimeSettings]
WindowsMetalToolchainOverride={Metal Developer Tools 安装路径}
```

配置完成后，使用 Windows 设备做远程打包时，就能自动完成 Metal Library 的构建，而不是产生 Shader Bytecode 了。


## 注意事项

### 默认的安装路径

引擎提供了一个默认的安装路径 "c:/Program Files/Metal Developer Tools"，当用户没有配置安装路径时就会从这个路径下寻找 Metal Developer Tools。由于这个默认的安装路径通常就是 Metal Developer Tools 首选的安装路径，除非用户有必要将 Metal Developer Tools 安装到其他路径下，否则不需要在引擎中配置安装路径。

引擎源码请见 MetalShaderFormat\.cpp：

```cpp
// MetalShaderFormat.cpp

// 默认的安装路径
FString FMetalCompilerToolchain::DefaultWindowsToolchainPath(TEXT("c:/Program Files/Metal Developer Tools"));

FMetalComilerToolchain::EMetalToolchainStatus FMetalCompilerToolchain::DoWindowsSetup()
{
    int32 Result = 0;

    /**
     * ToolchainBase 是引擎最终读取到的安装路径
     * 如果路径不为空，引擎就会调用 Metal Developer Tools，生成 Metal Library，否则就会生成 Shader Bytecode
     */
    FString ToolchainBase;
    // 先尝试读取用户提供的安装路径
    GConfig->GetString(TEXT("/Script/IOSRuntimeSettings.IOSRuntimeSettings"), TEXT("WindowsMetalToolchainOverride"), ToolchainBase, GEngineIni);

    const bool bUseOverride = (!ToolchainBase.IsEmpty() && FPaths::DirectoryExists(ToolchainBase));
    if (!bUseOverride)
    {
        // 用户没有提供安装路径，因此选择默认的安装路径
        ToolchainBase = DefaultWindowsToolchainPath;
    }

    // ...
}
```

### 版本更新

不同版本的 Metal Developer Tools 所支持的 Metal 版本是不同的，请务必选用**最新版本**的 Metal Developer Tools，否则编译 Metal Library 时就会出现错误。

+ UE4\.26 和 UE4\.27 要求的最低版本是 1\.2

+ UE5\.0 和 UE5\.1 要求的最低版本是 3\.1


## 参考资料

+ [Metal 简介](https://developer.apple.com/metal/)

+ [Windows metal shader compilation in 4.26](https://forums.unrealengine.com/t/windows-metal-shader-compilation-in-4-26/155048)

+ [使用 Metal 命令行编译 Native Shader Library](https://developer.apple.com/documentation/metal/libraries/building_a_library_with_metal_s_command-line_tools)

+ [虚幻引擎4.26的发布说明](https://docs.unrealengine.com/en-US/WhatsNew/Builds/ReleaseNotes/4_26/index.html)

+ [将 Windows Metal Shader 编译器用于 iOS](https://docs.unrealengine.com/en-US/SharingAndReleasing/Mobile/iOS/WindowsMetalShader/index.html)

+ [各版本 Metal 支持的 iOS 版本与 MacOS 版本](https://blog.csdn.net/YoungHong1992/article/details/124812131)
