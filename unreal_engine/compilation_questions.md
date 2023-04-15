# 编译问题汇总


## 模块中的蓝图（反射）内容不生效

该问题常见于模块的蓝图（反射）内容只在蓝图中使用，而不在 C\+\+ 代码中使用的情况。在这种情况下，即使模块已经添加到游戏工程模块的 Build\.cs 文件中作为一个编译依赖，在编辑器或者游戏中仍然找不到其中的蓝图内容。例如模块包含一个 `UDeveloperSettings` 的派生类，在项目设置中却找不到对应的配置项；例如模块包含一个标记为 `BlueprintType` 或者 `Blueprintable` 的蓝图类，在蓝图中却无法找到这个类。

经过测试得知，由于模块的蓝图内容没有在 C\+\+ 代码中被引用，对于引擎而言，它就没有真正意义上被依赖，也因此不会被链接到游戏工程当中。解决方法有两种：

+ 首先确保模块已经添加到游戏工程模块的 Build\.cs 文件中作为一个编译依赖，然后将模块添加到 \.uproject 文件当中；示例如下：

    ```csharp
    // GameProject.Build.cs

    // 将 TargetModule 模块作为一个编译依赖；添加至 PublicDependencyModuleNames 和 PrivateDependencyModuleNames 皆可
    PrivateDependencyModuleNames.AddRange(
        new string[]
        {
            // ...
            "TargetModule",
            // ...
        }
    );
    ```

    ```json
    // GameProject.uproject

    // 将运行时模块 TargetModule 添加至 .uproject 文件中
    {
        // ...
        "Modules": [
            // ...
            {
                "Name": "TargetModule",
                "Type": "Runtime",
                "LoadingPhase": "Default"
            },
            // ...
        ]
        // ...
    }
    ```

+ 确保模块的蓝图（反射）内容在 C\+\+ 代码中被引用；示例如下：

    ```cpp
    // 来自 TargetModule 的纯 C++ 类
    class TARGETMODULE_API FCPPClass
    {
        // ...
    public:
        void Func();
        // ...
    };

    // 来自 TargetModule 的蓝图类
    UCLASS()
    class TARGETMODULE_API UBPClass : public UObject
    {
        GENERATED_BODY()
        // ...
    public:
        void Func();
        // ...
    };

    // 来自游戏模块的某个函数
    void FGameModuleInterface::StartupModule()
    {
        // 以下代码块不能让 TargetModule 链接到游戏工程当中，因为 FCPPClass 不属于蓝图（反射）内容
        {
            FCPPClass CPPObject;
            CPPObject.Func();
        }

        // 以下代码块不能让 TargetModule 链接到游戏工程当中，因为声明一个 UBPClass 指针并不涉及蓝图（反射）内容的访问
        {
            UBPClass* BPObject = nullptr;
        }

        // 以下代码块都可以让 TargetModule 链接到游戏工程当中
        {
            UBPClass* BPObject = NewObject<UBPClass>();
        }
        {
            UClass* Class = UBPClass::StaticClass();
        }
    }
    ```


## 编辑器启动时提示重新编译模块

编辑器启动（尚未弹出进度信息）时，弹窗提示 “以下模块丢失或者在其他版本的引擎下编译……是否需要重新编译它们？（The following modules are missing or built with a different engine version: \.\.\. Would you like to rebuild them now?）”

问题的原因是某个模块被添加到 \.uproject 文件当中，却没有在任何游戏模块的 Build\.cs 文件当中，作为编译依赖。引擎会在启动时自动加载添加到 \.uproject 文件中的模块，这个步骤涉及模块 dll 的链接。如果一个模块没有作为编译依赖，引擎在编译工程时就会忽略该模块的编译和链接，导致在启动时无法完成该模块的加载。

对于编辑时（Editor）的模块，可以添加到某个游戏模块的 Build\.cs 文件中，也可以添加到游戏工程编辑时的 Target\.cs 文件（例如 MyGameEditor\.Target\.cs）中；对于运行时（Runtime）的模块，还需要添加到 Build\.cs 文件中，而不能只是添加到游戏工程运行时的 Target\.cs 文件中（例如添加到 MyGameDemo\.Target\.cs 中，该问题仍然存在）。


## 无法找到命令行类

定义一个命令行类（`UCommandlet` 的派生类）后，执行对应的命令时，提示 “XXX looked like a commandlet, but we could not find the class\.” 。

问题的原因是命令行类所在的模块没有被正确加载。请参照 [编辑器启动时提示重新编译模块](#编辑器启动时提示重新编译模块) 当中的做法，检查命令行类所在的模块是否已经添加到 \.uproject 和 Target\.cs 文件当中（命令行类通常属于编辑时的模块，因此添加到游戏工程编辑时的 Target\.cs 文件即可）。


## 编辑器启动时提示模块初始化失败

编辑器启动（约75%）时，弹窗提示 “游戏模块 ‘xx’ 加载后无法被成功初始化。（The game module 'xx' could not be successfully initialized after it was loaded\.）”

问题的原因是某个模块被添加到 \.uproject 文件当中，却没有定义相应的 `IModuleInterface` 派生类。引擎会在启动时自动加载添加到 \.uproject 文件中的模块。如果一个模块没有正确定义对应的 `IModuleInterface` 派生类，并且重写 `StartupModule` 和 `ShutdownModule` 函数，引擎就无法完成该模块的初始化。


## 编译游戏工程的时候提示 UE4Editor.lib 缺失

如果游戏工程中有模块将 Launch 模块添加到 `PublicDependencyModuleNames` 或者 `PrivateDependencyModuleNames` 当中作为编译依赖，在编译的时候就会因为需要链接 Launch 模块而尝试加载 UE4Editor\.lib。UE4Editor\.lib 是引擎提供的一个库文件，在某些版本的引擎，例如预编译版的引擎当中可能会缺失。

通常，一个游戏模块依赖 Launch 模块的目的是访问其中的一些宏，例如 `ENGINE_MAJOR_VERSION` 和 `ENGINE_MINOR_VERSION`，并不需要链接 Launch 模块。在这种情况下，可以将 Launch 模块添加到 `PublicIncludePathModuleNames` 或者 `PrivateIncludePathModuleNames`，这相当于只是增加头文件的检索目录，并不会去链接 Launch 模块，从而避免加载 UE4Editor\.lib。

然而，如果一个游戏模块需要访问 Launch 模块中某些类的具体实现，就需要链接 Launch 模块，也因此需要设法构建有效的 UE4Editor\.lib。

[参考资料](https://www.cnblogs.com/wellbye/p/5913335.html)


## _WIN32_WINNT_WIN10_XXX 预编译头未定义的编译错误

错误信息如下：

```
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10229): error C4668: '_WIN32_WINNT_WIN10_TH2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10235): error C4668: '_WIN32_WINNT_WIN10_RS1' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10240): error C4668: '_WIN32_WINNT_WIN10_TH2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10244): error C4668: '_WIN32_WINNT_WIN10_TH2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10251): error C4668: '_WIN32_WINNT_WIN10_RS2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10261): error C4668: '_WIN32_WINNT_WIN10_RS2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10265): error C4668: '_WIN32_WINNT_WIN10_TH2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10270): error C4668: '_WIN32_WINNT_WIN10_RS3' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10277): error C4668: '_WIN32_WINNT_WIN10_RS4' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10280): error C4668: '_WIN32_WINNT_WIN10_RS1' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10283): error C4668: '_WIN32_WINNT_WIN10_RS4' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10288): error C4668: '_WIN32_WINNT_WIN10_RS1' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10291): error C4668: '_WIN32_WINNT_WIN10_RS5' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10486): error C4668: '_WIN32_WINNT_WIN10_RS2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(10510): error C4668: '_WIN32_WINNT_WIN10_RS5' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(13950): error C4668: '_WIN32_WINNT_WIN10_RS5' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15111): error C4668: '_WIN32_WINNT_WIN10_RS3' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15128): error C4668: '_WIN32_WINNT_WIN10_RS3' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15147): error C4668: '_WIN32_WINNT_WIN10_RS2' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15266): error C4668: '_WIN32_WINNT_WIN10_RS3' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15416): error C4668: '_WIN32_WINNT_WIN10_RS4' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15429): error C4668: '_WIN32_WINNT_WIN10_RS4' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
>C:\Program Files (x86)\Windows Kits\10\include\10.0.18362.0\um\winioctl.h(15657): error C4668: '_WIN32_WINNT_WIN10_RS1' is not defined as a preprocessor macro, replacing with '0' for '#if/#elif'
```

已知在 Windows 平台下编译 luasocket 的时候，可能会出现这种错误。原因是 luasocket 尝试去包含完整的 Windows SDK 依赖，其中头文件 winioctl\.h 访问了 `_WIN32_WINNT_WIN10_XXX` 系列的预编译头，这些预编译头缺少默认的定义。解决方法有两种：

+ 在 luasocket 所属模块的 Build\.cs 文件，`ModuleRules` 派生类的构造函数当中，添加一行代码 `bEnableUndefinedIdentifierWarnings = false;` ，来屏蔽这种编译错误（警告）

    [参考资料](https://blog.csdn.net/longyanbuhui/article/details/119148909)

+ 在引起编译错误的头文件，例如 luasocket\.h 当中，添加 `WIN32_LEAN_AND_MEAN` 宏的定义，表示以最简的方式去包含 Windows SDK 依赖；示例如下：

    ```cpp
    // luasocket.h
    #ifndef LUASOCKET_H
    #define LUASOCKET_H

    // 定义 WIN32_LEAN_AND_MEAN 宏即可，不需要赋予它具体的值
    #ifndef WIN32_LEAN_AND_MEAN
    #define WIN32_LEAN_AND_MEAN
    #endif

    // ...

    #endif
    ```

    [参考资料1](https://social.msdn.microsoft.com/Forums/en-US/01354cd0-f0bc-40b3-a024-4e96643fc8b8/uwpc14393-warning-c4668-win32winntwin10th2-is-not-defined-as-a-preprocessor-macro?forum=wpdevelop)

    [参考资料2](https://stackoverflow.com/questions/11040133/what-does-defining-win32-lean-and-mean-exclude-exactly)

    [参考资料3](https://www.cnblogs.com/flyinggod/p/8324369.html)


## 编译 UE5 源码时，提示找不到 uintptr_tx 标识符

这个问题通常会在 Visual Studio 下编译到 mimalloc 第三方库时出现。通过了解源码出错处得知，代码 `_Atomic(uintptr_t)x` 被预处理成了 `uintptr_tx`，而代码原意是解析成 `uintptr_t x`。所以 mimalloc 库中原来的写法是有问题的。

解决方法是 **在 UE5 中不要开启 FastBuild** 。据了解，Epic 官方也表示这方面并没做过多维护，目前主要是社区在对 FB for UE 做维护。

另外，新版本的 mimalloc 库已经修复了这个问题。来源请见 https://github.com/microsoft/mimalloc 。


## 使用 Visual Studio 2019 16\.11 版本编译 UE4 时出现报错

报错信息如下：

```
命令“..\..\Build\BatchFiles\Build.bat -Target="UE4Editor Win64 Debug" -Target="ShaderCompileWorker Win64 Development -Quiet" -WaitMutex -FromMsBuild”已退出，代码为 6
```

该报错是指 Unreal Build Tool (UBT) 异常退出。原因是 UBT 此前在旧版本的 Visual Studio 2019，例如 16\.9 版本下进行过编译，但是没有在新版本的 Visual Studio 2019 下重新编译。当用旧版本的 UBT，唤起新版本 Visual Studio 编译器来编译项目代码和引擎时，就会出现错误。

解决方法是更新 Visual Studio 的版本后，需要完全重新构建一次引擎和项目。


## 打包游戏时出现 ld.lld 的编译链接错误

第一种错误信息：

```
ld.lld: error: undefined symbol: GInternalProjectName
ld.lld: error: undefined symbol: GIsGameAgnosticExe
```

第二种错误信息：

```
ld.lld: error: duplicate symbol: GEncryptionKeyRegistration
ld.lld: error: duplicate symbol: GInternalProjectName
ld.lld: error: duplicate symbol: GIsGameAgnosticExe
ld.lld: error: duplicate symbol: GNameBlocksDebug
ld.lld: error: duplicate symbol: GObjectArrayForDebugVisualizers
ld.lld: error: duplicate symbol: GTargetNameRegistration
ld.lld: error: duplicate symbol: operator delete[](void*)
ld.lld: error: duplicate symbol: operator delete[](void*, std::nothrow_t const&)
ld.lld: error: duplicate symbol: operator delete[](void*, unsigned int)
ld.lld: error: duplicate symbol: operator delete[](void*, unsigned int, std::nothrow_t const&)
ld.lld: error: duplicate symbol: operator delete(void*)
ld.lld: error: duplicate symbol: operator delete(void*, std::nothrow_t const&)
ld.lld: error: duplicate symbol: operator delete(void*, unsigned int)
ld.lld: error: duplicate symbol: operator delete(void*, unsigned int, std::nothrow_t const&)
ld.lld: error: duplicate symbol: operator new[](unsigned int)
ld.lld: error: duplicate symbol: operator new[](unsigned int, std::nothrow_t const&)
ld.lld: error: duplicate symbol: operator new(unsigned int)
ld.lld: error: duplicate symbol: operator new(unsigned int, std::nothrow_t const&)
```

第一种错误的原因是未在游戏工程当中使用 `IMPLEMENT_PRIMARY_GAME_MODULE` 宏来指定主模块，请见引擎源码 ModuleManager\.h。根据虚幻引擎的要求，一个游戏工程**有且只有一个**主模块。

在虚幻引擎当中，有一些特殊的全局变量，例如 `GInternalProjectName` 和 `GIsGameAgnostic`，它们在编辑器环境下和在打包游戏环境下有着不同的定义，请见引擎源码 CoreGlobals\.cpp。在编辑器环境下，`IS_MONOLITHIC` 宏通常为0，引擎会为这些全局变量提供默认的定义，而在打包游戏环境下，`IS_MONOLITHIC` 宏通常为1，引擎不再为这些全局变量提供默认的定义，这些全局变量需要在 `IMPLEMENT_PRIMARY_GAME_MODULE` 宏当中重新定义。这就意味者，如果游戏工程没有使用 `IMPLEMENT_PRIMARY_GAME_MODULE` 宏来指定主模块，在打包的时候就会找不到这些全局变量的定义。

根据以上的信息我们也能得知，如果在游戏工程中指定了多个主模块，就会出现全局变量重复定义的问题。这是第二种错误的原因。
