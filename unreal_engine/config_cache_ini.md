# ConfigCacheIni


## ConfigCacheIni 的用法

`FConfigCacheIni` 类是 ini 系统的核心，管理所有的 ini 配置数据，它有一个全局的单例 `GConfig`。在 UE5\.0 及之前的版本中，`FConfigCacheIni` 类继承自 `TMap` 类，在此基础上封装了 ini 配置数据相关的接口；而从 UE5\.1 开始，`FConfigCacheIni` 类不再是 `TMap` 的派生类，而是维护一个 `TMap` 类型的成员属性。

与 `FConfigCacheIni` 类相关的还有 `FConfigFile`，`FConfigSection` 和 `FConfigValue` 类，它们的关系如下：

+ UE5\.0 及之前的版本：

    ```mermaid
    graph TD

    ConfigCacheIni(FConfigCacheIni)
    ConfigFile(FConfigFile)
    ConfigSection(FConfigSection)
    ConfigValue(FConfigValue)

    ConfigCacheIni -->| 继承 | Map_String_ConfigFile("TMap&lt;FString,FConfigFile&gt")
    ConfigCacheIni -->| 包含 | ConfigFile
    ConfigFile -->| 继承 | Map_String_ConfigSection("TMap&lt;FString,FConfigSetion&gt")
    ConfigFile -->| 包含 | ConfigSection
    ConfigSection -->| 继承 | MultiMap_Name_ConfigValue("TMultiMap&lt;FName,FConfigValue&gt")
    ConfigSection -->| 包含 | ConfigValue

    style ConfigCacheIni    fill: #e2f0d9, stroke: #70ad47
    style ConfigFile        fill: #e2f0d9, stroke: #70ad47
    style ConfigSection     fill: #e2f0d9, stroke: #70ad47
    style ConfigValue       fill: #e2f0d9, stroke: #70ad47
    ```

    在 `FConfigCacheIni` 类中，键是 ini 文件的路径，值是对应的 ini 文件内容，类型是 `FConfigFile`。例如：

    ```c++
    // 返回 Engine.ini 的配置数据
    // 通过 this 指针来调用 TMap 的接口
    FConfigFile* const File = TMap<FString, FConfigFile>::Find(FString(TEXT("../../Saved/Config/Windows/Engine.ini")));
    ```

    `FConfigFile` 类的一个实例包含一份 ini 文件的全部内容，其中，键是配置类别的名称，值是对应配置类别下的配置数据，类型是 `FConfigSection`。例如：

    ```c++
    FConfigFile* const File;
    // 返回重定向相关的配置数据（在 ini 文件中的配置类别是 [CoreRedirects]）
    FConfigSection* const Section = File->Find(FString(TEXT("CoreRedirects")));
    ```

    `FConfigSection` 类的一个实例包含一个配置类别下的配置数据，其中，键是配置项的键，值是配置项的值，类型是 `FConfigValue`。例如：

    ```c++
    FConfigSection* const Section;
    // 返回键是 'A' 的配置项值（在 ini 文件中的配置项是 A=xxxx）
    const FConfigValue* const Value = Section->Find(FName(TEXT("A")));
    // 返回配置项值的实际存储内容
    const FString& SavedValue = Value->GetSavedValue();
    // 返回配置项值的展开内容
    const FString& ExpandedValue = Value->GetValue();
    ```

    对于配置项值是路径的情况，`FConfigValue::GetSavedValue` 返回实际存储内容，`FConfigValue::GetValue` 则返回展开后的内容。例如在 ini 文件中配置项值是 "%GAMEDIR%"，前者返回 "%GAMEDIR%"，后者则返回 "../../{项目根目录名称}"。对于配置项值不是路径的情况，两个接口返回的内容相同。

+ UE5\.1 及之后的版本：

    ```mermaid
    graph TD

    ConfigCacheIni(FConfigCacheIni)
    ConfigFile(FConfigFile)
    ConfigSection(FConfigSection)
    ConfigValue(FConfigValue)

    ConfigCacheIni -->| 引用 | Map_String_ConfigFile("TMap&lt;FString,FConfigFile*&gt") -->| 包含 | ConfigFile
    ConfigFile -->| 继承 | Map_String_ConfigSection("TMap&lt;FString,FConfigSetion&gt")
    ConfigFile -->| 包含 | ConfigSection
    ConfigSection -->| 继承 | MultiMap_Name_ConfigValue("TMultiMap&lt;FName,FConfigValue&gt")
    ConfigSection -->| 包含 | ConfigValue

    style ConfigCacheIni    fill: #e2f0d9, stroke: #70ad47
    style ConfigFile        fill: #e2f0d9, stroke: #70ad47
    style ConfigSection     fill: #e2f0d9, stroke: #70ad47
    style ConfigValue       fill: #e2f0d9, stroke: #70ad47
    ```

    在 `FConfigCacheIni` 中，由 `TMap<FString, FConfigFile*>` 类型的成员属性 `OtherFiles` 存储 ini 配置数据，键是 ini 文件的路径，值是对应的 ini 文件内容。例如：

    ```c++
    // 返回 Engine.ini 的配置数据
    // 通过成员属性 OtherFiles 来调用 TMap 的接口；因为存储的是 FConfigFile 指针，所以建议使用 FindRef 接口来查询
    FConfigFile* const File = OtherFiles.FindRef(FString(TEXT("../../Saved/Config/Windows/Engine.ini")));
    ```

    `FConfigFile`，`FConfigSection` 和 `FConfigValue` 类的用法和 UE5\.0 及之前的版本相同。


## ConfigCacheIni 的扩展

根据对引擎源码的了解，以及和官方的沟通，得知 `GConfig` 除了用于访问 ini 配置数据，还可以作为自定义配置数据的“中转”，即让 `GConfig` 存储自定义的配置数据并提供访问接口。这是因为 `GConfig` 满足以下两个条件：

+ 由引擎提供，并且可以全局访问

    这个条件能够**解耦自定义配置数据的来源和访问**。例如在项目中定义了一个自定义配置数据的读写模块，称为 CustomConfig 模块；作为来源，通常它还需要提供配置数据的访问接口。这样一来其他需要访问配置数据的模块就会与 CustomConfig 模块产生耦合。而借助 `GConfig` 作为中转，由它提供数据的访问接口，就能够有效地消除模块之间的依赖。

+ 生命周期足够长

    如果中转的生命周期不足以覆盖整个游戏运行过程，其他模块在访问配置数据时就需要时刻关注它是否已经初始化或者已经销毁。而 `GConfig` 恰好符合这个条件，它在各个模块执行 `StartupModule` 之前完成初始化，在各个模块执行 `ShutdownModule` 之后再进行销毁，从而确保在各个模块的生命周期中始终有效。

尽管 `GConfig` 原本是为 ini 配置数据服务的，不过自定义配置数据的序列化形式不必拘泥于 ini。在配置数据的读写模块中，可以根据实际需要定义配置数据的序列化形式，完成配置数据的反序列化后，将配置数据写入 `GConfig` 即可。在向 `GConfig` 写入数据时，需要注意避免与 ini 配置数据冲突，因为 ini 配置数据通常使用 ini 文件的路径作为键，所以建议使用特殊的字符串作为自定义配置数据的键，示例如下：

```
GConfig
    - <"../../Config/DefaultEngine.ini",    DefaultEngine.ini 中的配置数据>
    - <"../../Config/DefaultGame.ini",      DefaultGame.ini 中的配置数据>
    - ...
    - <"__custom_config_0__", 自定义配置数据集0>
    - <"__custom_config_1__", 自定义配置数据集1>
    - ...
```

为了方便自定义配置数据的存储和访问，建议在 `FConfigCacheIni` 类中添加一些通用的接口，示例如下：

```c++
/** 判断是否包含某个 FConfigFile 实例 */
bool FConfigCacheIni::ContainFile(const FString& Filename) const
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    return Contains(Filename);
#else
    return OtherFiles.Contains(Filename);
#endif
}

/** 查找或添加一个 FConfigFile 实例 */
FConfigFile& FConfigCacheIni::FindOrAddFile(const FString& Filename)
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        ensure(File->NoSave);
        return *File;
    }

    FConfigFile& NewFile = Add(Filename, FConfigFile()); // FConfigCacheIni::Add 已经实现了版本兼容
    NewFile.Name = FName(Filename);
    NewFile.NoSave = true; // 通过该接口添加的数据属于运行时的临时数据，不需要让引擎写出至本地
    return NewFile;
}

/** 移除一个 FConfigFile 实例 */
bool FConfigCacheIni::RemoveFile(const FString& Filename)
{
    return Remove(Filename) > 0; // FConfigCacheIni::Remove 已经实现了版本兼容
}

/** 判断是否包含某个 FConfigSection 实例 */
bool FConfigCacheIni::ContainSection(const FString& Filename, const FString& SectionName) const
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (const FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (const FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        return File->Contains(SectionName);
    }
    return false;
}

/** 查找或添加一个 FConfigSection 实例 */
FConfigSection& FConfigCacheIni::FindOrAddSection(const FString& Filename, const FString& SectionName)
{
    FConfigFile& File = FindOrAddFile(Filename);
    return File.FindOrAdd(SectionName); // 效果与 File.FindOrAddSection 等价，但是效率更优
}

/** 移除一个 FConfigSection 实例 */
bool FConfigCacheIni::RemoveSection(const FString& Filename, const FString& SectionName)
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        return File->Remove(SectionName) > 0;
    }
    return false;
}

/** 判断是否包含某个 FConfigValue 实例 */
bool FConfigCacheIni::ContainCustomValue(const FString& Filename, const FString& SectionName, const FName& Key) const
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (const FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (const FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        if (const FConfigSection* const Section = File->Find(SectionName))
        {
            return Section->Contains(Key);
        }
    }
    return false;
}

/**
 * 返回一个 FConfigValue 实例
 * 可以根据需要封装 FConfigValue::GetSavedValue 和 FConfigValue::GetValue
 */
FString FConfigCacheIni::GetValue(const FString& Filename, const FString& SectionName, const FName& Key) const
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (const FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (const FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        if (const FConfigSection* const Section = File->Find(SectionName))
        {
            if (const FConfigValue* const Value = Section->Find(Key))
            {
                return Value->GetSavedValue();
            }
        }
    }
    return FString();
}

/** 设置一个 FConfigValue 实例 */
void FConfigCacheIni::SetValue(const FString& Filename, const FString& SectionName, const FName& Key, const FString& SavedValue)
{
    FConfigSection& Section = FindOrAddSection(Filename, SectionName);
    if (FConfigValue* const Value = Section.Find(Key))
    {
        *Value = FConfigValue(SavedValue); // FConfigValue 不提供变更 SavedValue 的接口，因此需要重新创建
    }
    else
    {
        Section.Add(Key, FConfigValue(SavedValue));
    }
}

/** 移除一个 FConfigValue 实例 */
bool FConfigCacheIni::RemoveValue(const FString& Filename, const FString& SectionName, const FName& Key)
{
#if ENGINE_MAJOR_VERSION < 5 || ENGINE_MINOR_VERSION < 1
    if (FConfigFile* const File = TMap<FString, FConfigFile>::Find(Filename))
#else
    if (FConfigFile* const File = OtherFiles.FindRef(Filename))
#endif
    {
        if (FConfigSection* const Section = File->Find(SectionName))
        {
            return Section->Remove(Key) > 0;
        }
    }
    return false;
}
```
