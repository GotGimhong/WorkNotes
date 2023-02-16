# PAK


## PAK 文件的结构

PAK 文件的结构如下图所示：

![](pak/pak_brief.png)

文件内容区域由多个文件内容块组成，结构如下图所示：

![](pak/pak_entry_content.png)

文件索引区域的末尾，由多个文件索引块组成，结构如下图所示：

![](pak/pak_index.png)

PAK 文件信息区域的结构如下图所示：

![](pak/pak_info.png)

以下是官方的分析：

> Pak 文件的结构中关于 Pak 文件信息是存在末尾的，在文件末尾你可以看到 45 个字节的 FPakInfo 结构，最前面的一个字节表示的是索引区域是否加密，然后是 ​PakFile_Magic(0x5A6F12E1)，然后是 Pak 文件格式版本号（PakFile_Version_Latest 目前主分支是 11），然后是实际文件内容的索引区域的起始地址偏移，再是索引区域长度，最后是20字节的整个索引区域的 SHA1 哈希。然后由这些信息可以找到索引区域。
>
> 从索引区域​开始 4 字节表示 MountPoint 路径字符串长度，然后接着就是这个长度的字符串，然后是 4 字节的索引文件数量。接下来就是前面文件数量个的每个索引（就是去掉了 MountPoint 这类共享路径前缀的文件路径）字符串和对应这个索引文件的 FPakEntry 结构。这个结构存了实际文件内容在 Pak 中的偏移，大小，以及未压缩前大小，压缩格式类型，哈希等数据。根据这些信息就能找到实际的文件内容。


## PAK 文件的增量更新

以下是关于这个问题和官方的沟通记录：

> Wang Mi (Epic Games)：考虑到压缩，签名，IOStore 的容器文件排序和抽取等复杂度，Pak 没有直接往 Pak 容器内直接新增和修改文件的接口。
>
> Q：我们想了解一下原因，是不是因为 Pak 文件在设计上存在限制，而不支持这样的操作呢？可能的话，我们想尝试自己增加这些接口。
> Wang Mi (Epic Games)：我并不清楚，我倾向于理解成，引擎之前在这几这个系统的时候没有类似的需求。是不是能支持我不清楚，单纯看 FPakFile 的结构恐怕并不是很容易处理。
> Wang Mi (Epic Games)：其实本身要改写的内容只有修正所有索引的偏移，以及修正索引中修改文件的偏移和大小，以及修改文件实际偏移位置的数据。​但是如果要替换其中特定文件，那么，大概率原始文件区的大小是要发生变化的，于是，就不得不把后面所有的内容都做修正了。​

PAK 文件的增量更新与 PAK 文件的结构直接相关，请见 [PAK 文件的结构](#pak-文件的结构)。

以下是关于 PAK 文件结构的一些细节：

+ 资源文件的数据存储在文件内容区域，并且按照一定的规则进行排序

+ 如果改动文件内容区域当中某个资源文件的数据，就必然要同步调整后续资源文件，资源索引区域和 PAK 文件信息区域的数据

+ 引擎本身没有提供 PAK 文件增量更新的接口，源于 PAK 文件结构的复杂性，即便能够实现可能也会产生一些不稳定因素

经过分析，我们得出以下结论：

+ 实现 PAK 文件的增量更新是完全有可能的，然而性价比会比较低，一是代价比较大，二是很可能会引起其他问题

实现 PAK 文件增量更新的大致思路如下：

1. 将需要更新的资源文件按照文件内容区域的排序规则进行排序

2. 在内存当中准备一个缓冲区，存储新 PAK 文件的数据

3. 逐个读取旧 PAK 文件当中的资源文件数据，按需更新，然后写入缓冲区

4. 依次读取旧 PAK 文件当中的文件索引区域和 PAK 文件信息区域，进行更新，然后写入缓冲区

5. 将缓冲区的数据写出至本地，产生新的 PAK 文件，以替换旧的 PAK 文件

预计存在的问题：

1. 在增量更新的时候，内存当中会存在新 PAK 文件的完整数据，导致内存占用过高

    引擎的 UnrealPak 命令行也存在相同的问题，请见引擎源码 PakFileUtilities\.cpp，`CreatePakFile` 函数的实现。在将资源文件压缩成 PAK 文件的过程当中，虽然资源文件是逐个读入内存当中的，但是 PAK 文件是一次性写出的。因为 UnrealPak 命令行只允许在编辑器环境下使用，所以这种设计尚且在接受范围内，然而如果将它沿用到打包游戏当中，很可能会出现严重的问题。

    解决方法是将缓冲区当中的数据分段写出至本地。

2. PAK 文件的结构比较复杂，增量更新很可能是一个效率比较低的操作

    权宜之计是使用多线程，异步进行增量更新，以优化用户体验。

3. PAK 文件的结构并非一成不变，会随着引擎版本的变化而变化

    这个问题没有比较好的解决方法，只能是对 PAK 文件的格式保持关注，然后兼容不同版本下的增量更新。


## Mount Point

Mount Point 是引擎装载 PAK 文件的起始目录。在打包后的游戏当中，例如移动端游戏，存在一个目录结构和项目目录相似的虚拟目录，以 Android 平台为例，虚拟目录的结构如下：

```
./
    {项目名称}/
        Binaries/
            Android_ETC2/
                {游戏的可执行文件}
        Content/
        ...
    Engine/
        ...
```

在项目当中使用的相对路径，统一以**游戏可执行文件**所在的目录，例如 Android\_ETC2/ 作为起始目录，因此如果需要访问项目资源所在的目录 Content/，就需要使用以 \.\./\.\./\.\./\{项目名称\}/Content/ 或者 \.\./\.\./Content/ 作为开头的相对路径。


## UnrealPak 命令行

在引擎的可执行文件目录（Binaries）下，存在一个 UnrealPak\.exe 文件，用于 PAK 文件的解压缩和压缩。这个可执行文件封装了 UnrealPak 命令行的功能，而 UnrealPak 命令行的入口，则是引擎 PakFileUtilities 模块的全局函数 `ExecuteUnrealPak`。`ExecuteUnrealPak` 是**可导出**的函数，能够在其他模块当中使用，不过因为 PakFileUtilities 模块属于开发者（Developer）类型的模块，所以使用 `ExecuteUnrealPak` 函数的模块只能同属于开发者模块，或者是编辑器（Editor）模块。

`ExecuteUnrealPak` 函数的声明和定义请见引擎源码 PakFileUtilities\.h 和 PakFileUtilities\.cpp，使用示例如下：

```c++
/**
 * 需要在模块的 Build.cs 文件当中，添加 PakFileUtilities 模块的依赖
 * 需要包含头文件 PakFileUtilities.h
 */
#include "PakFileUtilities.h"

/**
 * 解压缩 PAK 文件
 * @param -Extract：执行解压缩
 * @param D:/MyProjectPak.pak: PAK 文件的来源路径；解压缩 D:/MyProject/Pak.pak 路径下的 PAK 文件
 * @param D:/MyProject/Extract: PAK 文件的解压目录；将 PAK 文件解压缩至 D:/MyProject/Extract 目录下
 * @param -ExtractToMountPoint: 基于 Mount Point 解压缩，通常是必选的参数
 * @param -encryptionini: 指定密钥文件的获取途径，通过项目的 ini 配置文件（CryptoKeysSettings）读取
 * @param -projectdir: 项目所在的目录；项目所在的目录是 D:/MyProject，可以通过 FPaths::ProjectDir() 获取
 * @param -enginedir: 引擎所在的目录；引擎所在的目录是 D:/Engine，可以通过 FPaths::EngineDir() 获取
 * @param -platform: 平台；当前的平台是 Android
 */
bool bSuccessful = ExecuteUnrealPak(TEXT("-Extract D:/MyProject/Pak.pak D:/MyProject/Extract -ExtractToMountPoint -encryptionini -projectdir=D:/MyProject -enginedir=D:/Engine -platform=Android"));

/**
 * 压缩 PAK 文件
 * @param -Create: 响应文件，即散列文件清单的路径；读取 D:/MyProject/Response.txt 路径下的响应文件
 * @param D:/MyProject/Pak.pak: PAK 文件的生成路径；在 D:/MyProject/Pak.pak 路径下创建 PAK 文件
 * @param -compress: 执行压缩
 * @param -compressionformats: 压缩格式；压缩格式通常选择 Zlib
 * @param -multiprocess
 * @param -encryptindex
 * @param -encryptionini: 指定密钥文件的获取途径，通过项目的 ini 配置文件（CryptoKeysSettings）读取
 * @param -projectdir: 项目所在的目录；项目所在的目录是 D:/MyProject，可以通过 FPaths::ProjectDir() 获取
 * @param -enginedir: 引擎所在的目录；引擎所在的目录是 D:/Engine，可以通过 FPaths::EngineDir() 获取
 * @param -platform: 平台；当前的平台是 Android
 */
bool bSuccessful = ExecuteUnrealPak(TEXT("-Create=D:/MyProject/Response.txt D:/MyProject/Pak.pak -compress -compressionformats=Zlib -multiprocess -encryptindex -encryptionini -projectdir=D:/MyProject -enginedir=D:/Engine -platform=Android"));
```


## 问题记录

### UnrealPak 命令行中 -encryptionini 参数引起的错误

根据 PakFileUtilities\.cpp 中 `LoadKeyChain` 函数的实现，UnrealPak 命令行有三种读取密钥的方式：

1. 从一个 json 文件当中读取，通过 `-cryptokeys` 参数指定 json 文件的路径

2. 从 `CryptoKeysSettings` 当中读取，通过 `-encryptionini` 参数触发，并且通过 `-projectdir`，`-enginedir` 和 `-platform` 参数来指定项目根目录，引擎根目录和平台

3. 直接从命令行当中读取，通过 `-aes` 参数指定密钥
​
​问题出现在第二种方式。`LoadKeyChain` 函数内部会尝试加载 Engine，Crypto 和 Encryption 三个 ini 文件，在向 `FConfigCacheIni::LoadExternalIniFile` 函数传递 EngineConfigDir 参数的时候，以 "Config\\\\" 来结尾。

```c++
// PakFileUtilities.cpp

void LoadKeyChain(const TCHAR* CmdLine, FKeyChain& OutCryptoSettings)
{
    // ...
    FConfigCacheIni::LoadExternalIniFile(EngineConfig, TEXT("Engine"), *FPaths::Combine(EngineDir, TEXT("Config\\")), *FPaths::Combine(ProjectDir, TEXT("Config/")), true, *Platform);
    // ...
    FConfigCacheIni::LoadExternalIniFile(ConfigFile, TEXT("Crypto"), *FPaths::Combine(EngineDir, TEXT("Config\\")), *FPaths::Combine(ProjectDir, TEXT("Config/")), true, *Platform);
    // ...
    FConfigCacheIni::LoadExternalIniFile(ConfigFile, TEXT("Encryption"), *FPaths::Combine(EngineDir, TEXT("Config\\")), *FPaths::Combine(ProjectDir, TEXT("Config/")), true, *Platform);
    // ...
}
```

在 4\.26 和 4\.27 版本中，`FConfigCacheIni::LoadExternalIniFile` 函数最终会调用到 `FConfigFile::AddStaticLayersToHierarchy` 函数。然而，在 `FConfigFile::AddStaticLayersToHierarchy` 函数当中，会断言 EngineConfigDir 参数以 "Config/" 结尾。

```c++
// ConfigCacheIni.cpp

void FConfigFile::AddStaticLayersToHierarchy(const TCHAR* InBaseIniName, const TCHAR* InPlatformName, const TCHAR* EngineConfigDir, const TCHAR* SourceConfigDir)
{
    SourceEngineConfigDir = EngineConfigDir;
    SourceProjectConfigDir = SourceConfigDir;

    check(SourceEngineConfigDir.EndsWith(TEXT("Config/"))); // 因为 SourceEngineConfigDir 以 "Config\\" 结尾，所以断言失败
    check(SourceProjectConfigDir.EndsWith(TEXT("Config/")));

    // ...
}
```

而在 5\.0 到 5\.2 版本中，`FConfigCacheIni::LoadExternalIniFile` 函数最终会调用到 `FConfigContext::CachePaths` 函数。虽然具体实现有所变化，但是仍然存在相同的断言。

```c++
// ConfigContext.cpp

void FConfigContext::CachePaths()
{
    if (bIsHierarchicalConfig)
    {
        check(EngineConfigDir.EndsWith(TEXT("Config/"))); // 同理
        check(ProjectConfigDir.EndsWith(TEXT("Config/")));

        // ...
    }
}
```

总之，这个问题从 4\.26 版本开始出现，直至 5\.2 版本仍然存在。这个问题已经反馈给官方。


## 参考资料

+ [UE4 Pak 文件格式](https://zhuanlan.zhihu.com/p/54531649)（该参考资料比较旧，不适用于所有版本的引擎）

+ [虚幻引擎中 Pak 的运行时重组方案](https://imzlp.com/posts/12188/)

+ [UDN: Primer: Loading Pak Files and Content at Runtime](https://udn.unrealengine.com/s/article/Primer-Loading-Pak-Files-and-Content-at-Runtime)
