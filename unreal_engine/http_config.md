# HTTP 相关的配置参数


## HTTP 相关

### HttpMaxConnectionsPerServer

`HttpMaxConnectionsPerServer` 定义每台主机 HTTP 请求的最大并发量，作用于游戏当中所有的 HTTP 请求。例如 `HttpMaxConnectionsPerServer` 为 10，表示最多可以同时向一台主机发起 10 个 HTTP 请求，当上层向同一台主机发起第 11 个 HTTP 请求的时候，会先进行等待，直至前 10 个 HTTP 请求当中至少有一个完成。

在运行时，引擎会将 `HttpMaxConnectionsPerServer` 传递给 `FHttpModule` 类的成员属性 `HttpMaxConnectionsPerServer`。其中 `HttpMaxConnectionsPerServer` 的默认值是 16；换言之，如果没有配置 `HttpMaxConnectionsPerServer`，**每台主机 HTTP 请求的最大并发量默认是 16**。相关源码请见 HttpModule\.cpp，`FHttpModule` 类的成员函数 `StartupModule`。

如果 `HttpMaxConnectionsPerServer` 不大于 0，引擎就不会调用 `curl_multi_setopt` 接口来设置每台主机 HTTP 请求的最大并发量，相当于不进行限制，或者是使用 Curl 底层的默认限制。相关源码请见 CurlHttpManager\.cpp，`FCurlHttpManager` 类的成员函数 `InitCurl`。

`HttpMaxConnectionsPerServer` 配置在 XXEngine\.ini 文件当中，例如 DefaultEngine\.ini 文件，所属类别为 `HTTP`。以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[HTTP]
; 将每台主机 HTTP 请求的最大并发量设置为 8
HttpMaxConnectionsPerServer=8
```

```ini
[HTTP]
; 无效值，每台主机 HTTP 请求的最大并发量将不会受到限制
HttpMaxConnectionsPerServer=-1
; 无效值，每台主机 HTTP 请求的最大并发量将不会受到限制
HttpMaxConnectionsPerServer=0
```

### MaxTotalConnections

`MaxTotalConnections` 定义全局 HTTP 请求的最大并发量，作用于游戏当中所有的 HTTP 请求。例如 `MaxTotalConnections` 为 10，表示最多可以同时发起 10 个 HTTP 请求，当上层发起第 11 个 HTTP 请求的时候，会先进行等待，直至前 10 个 HTTP 请求当中至少有一个完成。

如果 `MaxTotalConnections` 不大于 0，引擎就不会调用 `curl_multi_setopt` 接口来设置全局 HTTP 请求的最大并发量，相当于不进行限制，或者是使用 Curl 底层的默认限制。因为 `MaxTotalConnections` 没有默认值，所以引擎默认不限制全局 HTTP 请求的最大并发量。相关源码请见 CurlHttpManager\.cpp，`FCurlHttpManager` 类的成员函数 `InitCurl`。

`MaxTotalConnections` 配置在 XXEngine\.ini 文件当中，例如 DefaultEngine\.ini 文件，所属类别为 `HTTP.Curl`。以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[HTTP]
; 将全局 HTTP 请求的最大并发量设置为 8
MaxTotalConnections=8
```

```ini
[HTTP]
; 无效值，全局 HTTP 请求的最大并发量将不会受到限制
MaxTotalConnections=-1
; 无效值，全局 HTTP 请求的最大并发量将不会受到限制
MaxTotalConnections=0
```


## 流文件（Chunk）相关

流文件（Chunk）通常用于游戏补丁的发布和下载。相关的配置参数，配置在 XXEngine\.ini 文件当中，例如 DefaultEngine\.ini 文件，所属类别为 `Portal.BuildPatch`。

### ChunkRetries

`ChunkRetries` 定义流文件下载的重试次数。

当一个流文件下载失败的时候，引擎会将它下载的重试次数与 `ChunkRetries` 进行比较，以判断它是否能够重试下载。

`ChunkRetries` 会影响流文件的并行下载。例如 `ChunkRetries` 是 3，当前有 10 个流文件并行下载，只要其中一个流文件的第 3 次重试下载仍然失败，引擎就会终止这 10 个流文件的并行下载。相关源码请见 CloudChunkSource\.cpp，`FCloudChunkSource` 类的成员函数 `ThreadRun`。

在运行时，引擎会将 `ChunkRetries` 传递给 `FCloudSourceConfig` 结构体的成员属性 `MaxRetryCount`。其中 `MaxRetryCount` 的默认值是 6；换言之，如果没有配置 `ChunkRetries`，**流文件下载的重试次数默认是 6**。相关源码请见 CloudChunkSource\.h，`FCloudSourceConfig` 结构体的构造函数。

`ChunkRetries` 在传递给 `MaxRetryCount` 的时候，会被修正至区间 \[-1, 1000\]。相关源码请见 BuildPatchInstaller\.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildCloudSourceConfig`。

以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[Portal.BuildPatch]
; 将流文件下载的重试次数设置为 3 次
ChunkRetries=3
```

```ini
[Portal.BuildPatch]
; 流文件下载的重试次数会被修正为 -1 次，相当于下载失败时不会重试
ChunkRetries=-5
```

```ini
[Portal.BuildPatch]
; 流文件下载的重试次数会被修正为 1000 次
ChunkRetries=1005
```

### RetryTimes

`RetryTimes` 定义流文件下载的重试延时。

当一个流文件下载失败的时候，引擎会尝试从 `RetryTimes` 当中读取一个重试延时，据此等待一段时间之后再重试下载。不同的重试次数对应不同的重试延时。

在运行时，引擎会将 `RetryTimes` 传递给 `FCloudSourceConfig` 结构体的成员属性 `RetryDelayTimes`。其中 `RetryDelayTimes` 的默认值是 `{ 0.5f, 1.0f, 1.0f, 3.0f, 3.0f, 10.0f, 10.0f, 20.0f, 20.0f, 30.0f }`；换言之，如果没有配置 `RetryTimes`，**流文件下载的重试策略默认是：在第 1 次下载失败之后等待 0.5 秒进行第 1 次重试，在第 1 次重试下载失败之后等待 1 秒进行第 2 次重试……在第 8 次重试下载失败之后等待 20 秒进行第 9 次重试，在第 9 及以上次重试下载失败之后等待 30 秒进行下一次重试**。相关源码请见 CloudChunkSource\.h，`FCloudSourceConfig` 结构体的构造函数。

在 `RetryTimes` 当中可以配置多个重试延时，每个重试延时都应该大于 0，只要存在一个不大于 0 的重试延时，`RetryTimes` 就会作废，引擎会使用默认的流文件下载重试策略。如果 `RetryTimes` 当中所有的重试延时都大于 0，引擎就会将 `RetryTimes` 传递给 `FCloudSourceConfig` 结构体的成员属性 `RetryDelayTimes`，在此过程中，每个重试延时都会被修正至区间 \[0.5, 300\]。相关源码请见 BuildPatchInstaller\.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildCloudSourceConfig`。

以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[Portal.BuildPatch]
; 无效的重试延时
+RetryTimes=-1.0
; 无效的重试延时
+RetryTimes=0.0
; 有效的重试延时；然而因为存在无效的重试延时，所以引擎会使用默认的流文件下载重试策略
+RetryTimes=3.0
```

```ini
[Portal.BuildPatch]
; 有效的重试延时，会被修正为 0.5；即流文件在第 1 次下载失败之后等待 0.5 秒进行第 1 次重试
+RetryTimes=0.1
; 有效的重试延时；流文件在第 1 次重试下载失败之后等待 1 秒进行第 2 次重试
+RetryTimes=1.0
; 有效的重试延时；流文件在第 2 次重试下载失败之后等待 1.5 秒进行第 3 次重试
+RetryTimes=1.5
; 有效的重试延时，会被修正为 300；即流文件在第 3 次重试下载失败之后等待 300 秒进行第 4 次重试
+RetryTimes=300.5
; 有效的重试延时；流文件在第 4 及以上次重试下载失败之后等待 2 秒进行下一次重试
+RetryTimes=2.0
```

### NumInstallerRetries

`NumInstallerRetries` 定义流文件安装的重试次数。

流文件的安装包含下载流文件，将流文件合并为 PAK 文件，校验 PAK 文件等处理。流文件下载失败，PAK 文件校验失败等都会导致流文件安装失败。当流文件安装失败的时候，引擎会将它安装的重试次数与 `NumInstallerRetries` 进行比较，以判断它是否能够重试安装。

在运行时，`NumInstallerRetries` 会作为命名空间 `ConfigHelpers` 下 `LoadNumInstallerRetries` 函数的返回值，源码请见 BuildPatchInstaller\.cpp。如果没有配置 `NumInstallerRetries`，`LoadNumInstallerRetries` 的返回值是 5，即**流文件安装的重试次数默认是 5**。除此之外，`LoadNumInstallerRetries` 会将 `NumInstallerRetries` 修正至区间 \[1, 50\]。

以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[Portal.BuildPatch]
; 流文件安装的重试次数会被修正为 1
NumInstallerRetries=0
```

```ini
[Portal.BuildPatch]
; 将流文件安装的重试次数设置为 10
NumInstallerRetries=10
```

```ini
[Portal.BuildPatch]
; 流文件安装的重试次数会被修正为 50
NumInstallerRetries=100
```

<!-- ### NumFileMoveRetries -->

<!-- ### DownloadSpeedAverageTime -->

### ChunkDownloadsDisableConnectionScaling

`ChunkDownloadsDisableConnectionScaling` 作为流文件下载并发量自动调节功能的开关。

引擎提供了流文件下载并发量的自动调节功能。在运行时，流文件下载的实际并发量会根据网络状况和带宽动态变化。相关源码请见 DownloadConnectionCount\.cpp，`FDownloadConnectionCount` 类的成员函数 `GetAdjustedCount`。

在运行时，引擎会将 `ChunkDownloadsDisableConnectionScaling` 传递给 `FDownloadConnectionCountConfig` 结构体的成员属性 `bDisableConnectionScaling`。其中 `bDisableConnectionScaling` 的默认值是 `false`；换言之，除非将 `ChunkDownloadsDisableConnectionScaling` 配置为 `true`，否则引擎**默认会自动调节流文件下载的并发量**。相关源码请见 DownloadConnectionCount\.h，`FDownloadConnectionCountConfig` 结构体的构造函数。

因为 `bDisableConnectionScaling` 的默认值是 `false`，所以启用流文件下载并发量的自动调节功能，并不需要将 `ChunkDownloadsDisableConnectionScaling` 配置为 `false`，当然即使这样做也不会有问题。相关源码请见 BuildPatchInstaller\.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildConnectionCountConfig`。

以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[Portal.BuildPatch]
; 禁用流文件下载并发量的自动调节功能
ChunkDownloadsDisableConnectionScaling=true
```

```ini
[Portal.BuildPatch]
; 启用流文件下载并发量的自动调节功能（该功能默认启用，因此也可以忽略该配置参数）
ChunkDownloadsDisableConnectionScaling=false
```

### ChunkDownloads

`ChunkDownloads` 定义流文件下载的并发量。

如果流文件下载并发量的自动调节功能被禁用，在运行时流文件下载的实际并发量就会始终保持不变，否则 `ChunkDownloads` 就相当于是初始值，实际并发量会在此基础上动态变化。

在运行时，引擎会将 `ChunkDownloads` 传递给 `FDownloadConnectionCountConfig` 结构体的成员属性 `RequestAllowance`。其中 `RequestAllowance` 的默认值是 16；换言之，如果没有配置 `ChunkDownloads`，**流文件下载的并发量默认是 16**。相关源码请见 DownloadConnectionCount\.h，`FDownloadConnectionCountConfig` 结构体的构造函数。

`ChunkDownloads` 在传递给 `RequestAllowance` 的时候，会被修正至区间 \[1, 100\]。相关源码请见 BuildPatchInstaller.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildConnectionCountConfig`。

以下是在 DefaultEngine\.ini 文件当中的配置示例：

```ini
[Portal.BuildPatch]
; 流文件下载的并发量会被修正为 1
ChunkDownloads=0
```

```ini
[Portal.BuildPatch]
; 将流文件下载的并发量设置为 50
ChunkDownloads=50
```

```ini
[Portal.BuildPatch]
; 流文件下载的并发量会被修正为 100
ChunkDownloads=150
```

### ChunkDownloadsLowerLimit

`ChunkDownloadsLowerLimit` 定义流文件下载的最小并发量。

在启用流文件下载并发量自动调节功能的时候，无论流文件下载的并发量如何变化，都不会小于最小的并发量。

在运行时，引擎会将 `ChunkDownloadsLowerLimit` 传递给 `FDownloadConnectionCountConfig` 结构体的成员属性 `MinLimit`。相关源码请见 DownloadConnectionCount\.h，`FDownloadConnectionCountConfig` 结构体的构造函数。

`ChunkDownloadsLowerLimit` 在传递给 `MinLimit` 的时候，会基于每台主机 HTTP 请求的最大并发量进行修正。相关源码请见 BuildPatchInstaller\.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildConnectionCountConfig`。具体规则如下：

+ 每台主机 HTTP 请求的最大并发量 < 10：流文件下载的最小并发量会被修正为 每台主机 HTTP 请求的最大并发量 - 2

+ 10 ≤ 每台主机 HTTP 请求的最大并发量 < 34：流文件下载的最小并发量会被修正至区间 \[8, 每台主机 HTTP 请求的最大并发量 - 2\]

+ 34 ≤ 每台主机 HTTP 请求的最大并发量：流文件下载的最小并发量会被修正至区间 \[8, 32\]

### ChunkDownloadsUpperLimit

`ChunkDownloadsUpperLimit` 定义流文件下载的最大并发量

在启用流文件下载并发量自动调节功能的时候，无论流文件下载的并发量如何变化，都不会大于最大的并发量。

在运行时，引擎会将 `ChunkDownloadsUpperLimit` 传递给 `FDownloadConnectionCountConfig` 结构体的成员属性 `MaxLimit`。相关源码请见 DownloadConnectionCount\.h，`FDownloadConnectionCountConfig` 结构体的构造函数。

`ChunkDownloadsUpperLimit` 在传递给 `MaxLimit` 的时候，会被修正至区间 \[流文件下载的最小并发量 + 2, 每台主机 HTTP 请求的最大并发量\]（因为引擎会先修正流文件下载的最小并发量，所以可以确保 流文件下载的最小并发量 + 2 不大于每台主机 HTTP 请求的最大并发量）。相关源码请见 BuildPatchInstaller\.cpp，`FBuildPatchInstaller` 类的成员函数 `BuildConnectionCountConfig`。

以下是 `ChunkDownloadsLowerLimit` 和 `ChunkDownloadsUpperLimit` 在 DefaultEngine\.ini 文件当中的配置示例：

```ini
; 情况1：每台主机 HTTP 请求的最大并发量为 8（小于 10）
[HTTP]
HttpMaxConnectionsPerServer=8

; 示例1：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 6（4 < 8 - 2）
ChunkDownloadsLowerLimit=4
; 流文件下载的最大并发量会被修正为 8（6 < 6 + 2）
ChunkDownloadsUpperLimit=6

; 示例2：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 6（10 > 8 - 2）
ChunkDownloadsLowerLimit=10
; 流文件下载的最大并发量会被修正为 8（20 > 8）
ChunkDownloadsUpperLimit=20
```

```ini
; 情况2：每台主机 HTTP 请求的最大并发量为 16（不小于 10 并且小于 34）
[HTTP]
HttpMaxConnectionsPerServer=16

; 示例1：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 8（4 < 8）
ChunkDownloadsLowerLimit=4
; 流文件下载的最大并发量会被修正为 10（6 < 8 + 2）
ChunkDownloadsUpperLimit=6

; 示例2：
[Portal.BuildPatch]
; 将流文件下载的最小并发量设置为 10，不需要修正（8 ≤ 10 < 16 - 2）
ChunkDownloadsLowerLimit=10
; 将流文件下载的最大并发量设置为 14，不需要修正（10 + 2 ≤ 14 < 16）
ChunkDownloadsUpperLimit=14

; 示例3：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 14（20 > 16 - 2）
ChunkDownloadsLowerLimit=20
; 流文件下载的最大并发量会被修正为 16（40 > 16）
ChunkDownloadsUpperLimit=40
```

```ini
; 情况3：每台主机 HTTP 请求的最大并发量为 40（不小于 34）
[HTTP]
HttpMaxConnectionsPerServer=40

; 示例1：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 8（4 < 8）
ChunkDownloadsLowerLimit=4
; 流文件下载的最大并发量会被修正为 10（6 < 8 + 2）
ChunkDownloadsUpperLimit=6

; 示例2：
[Portal.BuildPatch]
; 将流文件下载的最小并发量设置为 10，不需要修正（8 ≤ 10 ≤ 32）
ChunkDownloadsLowerLimit=10
; 将流文件下载的最大并发量设置为 14，不需要修正（10 + 2 ≤ 14 < 40）
ChunkDownloadsUpperLimit=14

; 示例3：
[Portal.BuildPatch]
; 流文件下载的最小并发量会被修正为 32（36 > 32）
ChunkDownloadsLowerLimit=36
; 流文件下载的最大并发量会被修正为 40（48 > 40）
ChunkDownloadsUpperLimit=48
```
