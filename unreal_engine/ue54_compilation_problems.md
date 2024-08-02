# UE5.4 引擎升级编译问题记录

以下是将项目的引擎从 UE5\.1\.1 升级至 UE5\.4\.2 时遇到的编译问题和解决方法。


## 1. 编译时提示项目修改了 bStrictConformanceMode 属性

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


## 2. 编译时提示库文件重复生成，无法合并编译结果

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


## 3. 编译时提示工程没有将 A 插件列为依赖

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

## 4. 编译时提示 A 插件没有将 B 插件列为依赖

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

## 5. 编译时提示找不到来自 Launch 模块的头文件

在包含引擎 Launch 模块的头文件 Version\.h 时，提示找不到该头文件，原因是包含路径错误。正确的写法如下：

```cpp
#include "Runtime/Launch/Resources/Version.h"
```

此外不必在模块的 Build\.cs 文件中添加 Launch 模块的依赖，因为包含 Version\.h 的目的是访问其中定义的宏，不涉及代码的链接。


## 6. 编译时提示找不到 Components/SinglePropertyView.h 头文件

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


## 7. 编译时提示 TCHAR 数组的哈希方法被废弃

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


## 8. 编译时提示 FormatStringSan.h 头文件中出现断言错误

UE5\.4 引入了日志参数的编译时检查，如果使用 `UE_LOG` 宏等方式打印日志，且日志参数存在错误，就会在编译时出现错误，示例如下：

```
D:\UE5.4\Engine\Source\Runtime\Core\Public\String\FormatStringSan.h(99): error C2338: static_assert failed: ''%s' expected 'TCHAR*'; use '%hs' for 'cost char*'.'
```

以上错误表示使用了错误的字符串类型变量作为日志参数，引擎要求使用 `TCHAR*`（宽字符指针或数组）类型作为 `%s` 参数的类型，使用其他类型，例如 `char*`，`const char*`，`void*`，或者空指针都会引起编译错误。

日志参数使用 C 语言标准，详见 https://en.wikipedia.org/wiki/C_data_types 。
