# 编译问题汇总

引擎版本：5\.4\.3


## 编译时提示项目修改了 bStrictConformanceMode 属性

编译错误示例如下：

```
MyProjectEditor modifies the values of properties: [ bStrictConformanceMode ]. This is not allowed, as MyProjectEditor has build products in common with UnrealEditor.
Remove the modified setting, change MyProjectEditor to use a unique build environment by setting 'BuildEnvironment = TargetBuildEnvironment.Unique;' in the MyProjectEditorTarget constructor, or set bOverrideBuildEnvironment = true to force this settings on.
```

其中 `MyProjectEditor` 是项目的其中一个目标（Target）。

解决方法有以下三种，**推荐使用第一种**：

1. 显式地将 `DefaultBuildSettings` 属性设置为 `BuildSettingsVersion.V5`，并且将 `IncludeOrderVersion` 属性设置为 `EngineIncludeOrderVersion.Unreal5_4`，示例如下：

    ```cs
    // MyProjectEditor.Target.cs
    using UnrealBuildTool;

    public class MyProjectEditorTarget : TargetRules
    {
        public MyProjectEditorTarget(TargetInfo Target) : base(Target)
        {
            UnrealBuildTool.BuildVersion EngineVersion;
            if (UnrealBuildTool.BuildVersion.TryRead(UnrealBuildTool.BuildVersion.GetDefaultFileName(), out EngineVersion)
                && (EngineVersion.MajorVersion == 5 && EngineVersion.MinorVersion >= 4 || EngineVersion.MajorVersion > 5))
            {
                // 针对 UE5.4 或以上的版本
                DefaultBuildSettings = BuildSettingsVersion.V5;
                IncludeOrderVersion = EngineIncludeOrderVersion.Unreal5_4;
            }
        }
    }
    ```

2. 按照编译错误中的建议，将 `BuildEnvironment` 属性设置为 `TargetBuildEnvironment.Unique`

3. 按照编译错误中的建议，将 `bOverrideBuildEnvironment` 属性设置为 `true`

该编译错误源于 UBT，请见 UEBuildTarget\.cs 的 `ValidateSharedEnvironment` 函数。它源于 **UE5\.4\.0** 引入的一个编译规则——**项目的目标原则上不应该修改预设的编译设置（Build Settings）**，这些编译设置包括但不限于 `bStrictConformanceMode` 属性。

可能大家会疑惑，明明没有对项目的 Target\.cs 文件做过修改，怎么就被引擎判定为修改了编译设置呢？这是因为没有在项目的 Target\.cs 文件中修正 `DefaultBuildSettings` 和 `IncludeOrderVersion` 属性——根据源码 TargetRules\.cs 可知，项目目标的 `DefaultBuildSettings` 和 `IncludeOrderVersion` 属性默认分别是 `BuildSettingsVersion.V1` 和 `EngineIncludeOrderVersion.Oldest`，也就是默认使用最旧的编译设置；再来看 `TargetRules` 类的 `GetBuildSettingsInfo` 函数，只要 `DefaultBuildSettings` 属性低于 `BuildSettingsVersion.V5`，引擎就会将某些编译设置标记为 “修改过” 的状态，这就导致项目编译时，被引擎判定为修改了编译设置。


## 编译时提示库文件重复生成，无法合并编译结果

编译错误示例如下：

```
Re-writing a file that was previously written: "D:\MyProject\Intermediate\Build\Win64\x64\UnrealEditor\Development\ModuleA\UnrealEditor-ModuleA.lib.rsp"
Re-writing a file that was previously written: "D:\MyProject\Intermediate\Build\Win64\x64\UnrealEditor\Development\ModuleA\UnrealEditor-ModuleA.dll.rsp"
Unable to merge actions 'UnrealEditor-ModuleA.lib' and 'UnrealEditor-ModuleA.lib': PrerequisiteItems are different
    First Action: {
        ...
    }
    Second Action: {
        ...
    }
```

该编译错误的原因是项目重复添加某个模块作为编译依赖。例如 MyProject 项目中存在一个模块 ModuleA，如果在其他模块的 Build\.cs 文件中已经添加了 ModuleA 模块作为编译依赖，那么在项目的 **MyProject\.uproject**，**MyProject\.Target\.cs** 和 **MyProjectEditor\.Target\.cs** 文件中，就**不应该**再添加 ModuleA 模块了。

在项目的 \.uproject 和 \.Target\.cs 文件中添加某个模块，是因为这个模块没有被依赖，却需要编译并且在适当的时机启动它；而当这个模块被其他模块依赖时，自然就会被编译并且在合适的时机启动，因此不必再在 \.uproject 和 \.Target\.cs 文件中添加了。


## 编译时提示工程没有将 A 插件列为依赖

编译警告示例如下：

```
EXEC : warning : D:\MyProject\MyProject.uproject does not list plugin 'PluginA' as a dependency, but module 'MyProjectModule' depends on 'ModuleA'.
```

其中 MyProjectModule 模块来自 MyProject 工程，ModuleA 模块来自 PluginA 插件。

该编译警告的原因是工程的某个模块依赖了 A 插件中的模块，而在工程的 \.uproject 文件中，并没有显式地将 A 插件列为依赖。编译警告来源请见引擎源码 UEBuildTarget\.cs，`ValidateModule` 函数。解决方法是在工程的 \.uproject 文件中，将 A 插件添加到 `Plugins` 字段内，示例如下：

```json
// MyProject.uproject
{
    ...
    // MyProject 工程包含 MyProjectModule 模块
    "Modules": [
        {
            "Name": "MyProjectModule",
            "Type": "Runtime",
            "LoadingPhase": "Default"
        }
    ],
    // MyProject 工程显式地将 PluginA 插件列为依赖
    "Plugins": [
        {
            "Name": "PluginA",
            "Enabled": true
        }
    ]
}
```


## 编译时提示 A 插件没有将 B 插件列为依赖

编译警告示例如下：

```
EXEC : warning : Plugin 'PluginA' does not list plugin 'PluginB' as a dependency, but module 'ModuleA' depends on module 'ModuleB'.
```

其中 ModuleA 模块来自 PluginA 插件，ModuleB 模块来自 PluginB 插件。

该编译警告的原因是 A 插件中的模块依赖了 B 插件中的模块，而在 A 插件的 \.uplugin 文件中，并没有显式地将 B 插件列为依赖。编译警告来源请见引擎源码 UEBuildTarget\.cs，`ValidatePlugin` 函数。解决方法是在 A 插件的 \.uplugin 文件中，将 B 插件添加到 `Plugins` 字段内，示例如下：

```json
// PluginA.uplugin
{
    ...
    // PluginA 插件包含 ModuleA 模块
    "Modules": [
        {
            "Name": "ModuleA",
            "Type": "Runtime",
            "LoadingPhase": "Default"
        }
    ],
    // PluginA 插件显式地将 PluginB 插件列为依赖
    "Plugins": [
        {
            "Name": "PluginB",
            "Enabled": true
        }
    ]
}
```


## 编译时提示找不到来自 Launch 模块的头文件

在包含引擎 Launch 模块的头文件 Version\.h 时，提示找不到该头文件，原因是包含路径错误。正确的写法如下：

```cpp
#include "Runtime/Launch/Resources/Version.h"
```

此外不必在模块的 Build\.cs 文件中添加 Launch 模块的依赖，因为包含 Version\.h 的目的是访问其中定义的宏，不涉及代码的链接。


## 编译时提示找不到 Components/SinglePropertyView.h 头文件

原因是从 5\.3 版本开始，引擎增加了 ScriptableEditorWidgets 模块，将 SinglePropertyView\.h 头文件从 UMGEditor 模块移至该模块中。存在相同问题的头文件还有 DetailsView\.h 和 PropertyViewBase\.h 。

因此在模块的 Build\.cs 文件中，需要添加 ScriptableEditorWidgets 模块作为编译依赖，示例如下：

```cs
BuildVersion EngineVersion;
if (BuildVersion.TryRead(BuildVersion.GetDefaultFileName(), out EngineVersion))
{
    if (EngineVersion.MajorVersion == 5 && EngineVersion.MinorVersion >= 3 || EngineVersion.MajorVersion > 5)
    {
        PublicDependencyModuleNames.Add("ScriptableEditorWidgets");
    }
}
```


## 编译时提示 TCHAR 数组的哈希方法被废弃

该编译错误源于使用 `TCHAR*` 或者 `const TCHAR*` 类型作为 `TSet` 或者 `TMap` 的键类型，完整提示如下：

```
warning C4996: 'GetTypeHash': Hashing TCHAR arrays is deprecated - use PointerHash() to force a conversion to a pointer or FCrc::Strihash_DEPRECATED to do a string hash, or use TStringPointerSetKeyFuncs_DEPRECATED or TStringPointerMapKeyFuncs_DEPRECATED as keyfuncs for a TSet or TMap respectively
```

根据引擎的提示，解决方法有以下几种：

1. 按照引擎的其中一个建议，使用 `PointerHash` 函数计算出 `TCHAR*` 或 `const TCHAR*` 类型指针的哈希值，使用哈希值作为键，示例如下：

    ```cpp
    // PointerHash 函数的定义请见引擎源码 TypeHash.h

    void AddKeyValue(TMap<uint32, int32>& Map, const TCHAR* const Key, const int32 Value)
    {
        Map.Add(PointerHash(Key), Value);
    }

    bool RemoveKeyValue(TMap<uint32, int32>& Map, const TCHAR* const Key)
    {
        return Map.Remove(PointerHash(Key)) > 0;
    }

    bool ContainsKeyValue(const TMap<uint32, int32>& Map, const TCHAR* const Key)
    {
        return Map.Contains(PointerHash(Key));
    }
    ```

2. 按照引擎的其中一个建议，使用 `FCrc::Strihash_DEPRECATED` 函数计算出 `TCHAR*` 或 `const TCHAR*` 类型指针的哈希值，使用哈希值作为键，示例如下：

    ```cpp
    // FCrc::Strihash_DEPRECATED 函数的定义请见引擎源码 Crc.h

    void AddKeyValue(TMap<uint32, int32>& Map, const TCHAR* const Key, const int32 Value)
    {
        Map.Add(FCrc::Strihash_DEPRECATED(Key), Value);
    }

    bool RemoveKeyValue(TMap<uint32, int32>& Map, const TCHAR* const Key)
    {
        return Map.Remove(FCrc::Strihash_DEPRECATED(Key)) > 0;
    }

    bool ContainsKeyValue(const TMap<uint32, int32>& Map, const TCHAR* const Key)
    {
        return Map.Contains(FCrc::Strihash_DEPRECATED(Key));
    }
    ```

3. 使用引擎为 `TCHAR*` 和 `const TCHAR*` 类型保留的键函数，示例如下：

    ```cpp
    TMap<const TCHAR*, int32, FDefaultSetAllocator, TStringPointerMapKeyFuncs_DEPRECATED<const TCHAR*, int32>> Map;
    ```

从接口的命名来看，**方法一是最佳实践**，方法二和三都是临时方案。


## 编译时提示 FormatStringSan.h 头文件中出现断言错误

UE5\.4 引入了日志参数的编译时检查，如果使用 `UE_LOG` 宏等方式打印日志，且日志参数存在错误，就会在编译时出现错误，示例如下：

```
D:\UE5.4\Engine\Source\Runtime\Core\Public\String\FormatStringSan.h(99): error C2338: static_assert failed: ''%s' expected 'TCHAR*'; use '%hs' for 'cost char*'.'
```

以上错误表示使用了错误的字符串类型变量作为日志参数，引擎要求使用 `TCHAR*`（宽字符指针或数组）类型作为 `%s` 参数的类型，使用其他类型，例如 `char*`，`const char*`，`void*`，或者空指针都会引起编译错误。

日志参数使用 C 语言标准，详见 https://en.wikipedia.org/wiki/C_data_types 。


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


## 编辑器启动时提示模块加载失败，存在操作系统层面的错误

问题的表现为，工程能够正常编译，然而编辑器启动至 75% 时，弹出对话框提示某个模块启动失败，示例如下：

```
The game module 'ModuleA' could not be loaded. There may be an operating system error, the module may not be properly set up, or a plugin which has been included into the build has not been turned on.
```

其中 ModuleA 是工程中的一个模块，该错误源于引擎源码 ProjectManager\.cpp，`LoadModulesForProject` 函数。

出现该问题有以下两种可能：

1. 编译该模块与启动该模块的引擎不是同一个；例如同一份工程，在某一台 PC 上进行编译，在另一台 PC 上运行，两台 PC 使用了不同的引擎，就会出现这个问题；

2. 该模块依赖了某个插件，在工程的 \.uproject 文件中却没有显式地添加并启用这个插件；例如 ModuleA 模块依赖 PluginA 插件，就应当在工程 \.uproject 文件的 `Plugins` 字段里添加以下内容，否则就会导致 ModuleA 模块无法正常启动：

    ```json
    // 启用 PluginA 插件
    {
        "Name": "PluginA",
        "Enabled": true
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


## 使用 Visual Studio 2019 16.11 版本编译 UE4 时出现报错

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
