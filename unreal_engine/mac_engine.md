# 引擎在 Mac 系统上的使用


## 源码版引擎的部署

1. 先赋予 `GenerateProjectFiles.command`，`RunMono.sh`，`XcodeBuild.sh` 和 `ispc` **执行权限**，在引擎根目录下执行以下命令：

```powershell
$ chmod +x GenerateProjectFiles.command
$ chmod +x Engine/Build/BatchFiles/Mac/RunMono.sh
$ chmod +x Engine/Build/BatchFiles/Mac/XcodeBuild.sh
$ chmod +x Engine/Source/ThirdParty/Intel/ISPC/bin/Mac/ispc
```

2. 通过 Xcode 运行 UE4.xcworkspace

3. 将 scheme 切换至 ShaderCompileWorker 进行编译

4. 第3步完成后，将 scheme 切换至 UE4 进行编译


## 源码版引擎的定制

我们对于引擎的定制化内容主要集中在引擎的 Source 和 Shader 目录，对比 Mac 版和 Windows 版引擎发现，这两个目录中的差异主要来自编码：Mac 版引擎 Shader 目录中的 Shader 编码统一为 Unix，Windows 版引擎的 Shader 则统一为 PC（dos）；Mac 版引擎 Source 目录中大多数文件的编码为 Unix，少数文件的编码为 PC（dos），Windows 版引擎则相反（大多数文件的编码为 PC（dos），少数文件的编码为 Unix）。

我们可以使用转码工具解决编码差异的问题。转码工具提供最基本的函数，只针对文本文件进行转码。后续制作的 SVN 钩子脚本用于检查待替换文件的编码，如果 Windows 系统上的代码需要同步至 Mac 系统，那么就要对 Mac 系统上代码的编码进行逐一校验，然后将 Windows 系统上代码的编码转换为目标编码。


## 问题排查记录

### 引擎无法识别 Xcode

Xcode 一般安装到 Applications 目录中，即将 Xcode.app 放到 Applications 目录下，必要时可以通过执行 `xcode-select -s /Applications/Xcode.app/Contents/Developer` 将 Xcode 设置为默认。

### 在执行 GenerateProjectFiles.command 构建引擎 .xcworkspace 的过程中，可能会遇到文件编码错误的问题

Windows 系统和 Mac 系统做文件压缩和解压时，很可能采用不同的编码方式。因此如果需要在 Windows 系统上下载引擎源码再传送至 Mac 系统，建议避免在此之间进行二次压缩的操作。

### 编译引擎时出现 ShaderCompileWorker 编译失败的问题

报错信息如下：

```
command /user/bin/codesign failed with exit code 1
ShaderCompileworker.app: No such file or directory
```

原因为 Xcode 版本与引擎版本不匹配。引擎要求的 Xcode 版本可以从引擎各个版本的发布说明中查看，例如：

| 引擎版本 | 要求的 Xcode 版本 |
|-|-|
| 4.20 | 9.4 |
| 4.22 | 10.1 |
| 4.24 | 11.1 |
| 4.26 | 最低11.3.1，推荐12 |

### 打包含 iOS 平台的安装版引擎时提示远程配置错误

报错信息如下：

```
ERROR: Remote compiling requires a server name. Use the editor (Project Settings > IOS) to set up your compilation settings.
```

需要配置远程 Mac 打包机 IP 与帐号。在 Engine/Config/BaseEngine.ini 中添加以下配置：

```ini
[/Script/IOSRuntimeSettings.IOSRuntimeSettings]
RemoteServerName="172.16.10.144"
RSyncUserName="4399"
```

### 打包含 iOS 平台的安装版引擎时提示条款文件缺失

报错信息如下：

```
ERROR: Unable to find mobile provision for UE4Game.
```

在构建过程中会将引擎打包为 iOS 平台，也就是 UE4Game for iOS，因此同样需要条款（Provision）文件。在 Engine/Config/BaseEngine.ini 中添加以下配置：

```ini
[/Script/IOSRuntimeSettings.IOSRuntimeSettings]
MobileProvision={.mobileprovision 文件的路径}
```

### 打包含 iOS 平台的安装版引擎时提示包 ID 不匹配

报错信息如下：

```
Code Signing Error: Provision profile "xxx" has app ID "xxx", which does not match the bundle ID "com.YourCompany.UE4Game"
```

在 Engine/Config/BaseEngine.ini 中添加以下配置：

```ini
[/Script/IOSRuntimeSettings.IOSRuntimeSettings]
BundleIdentifier=com.ssjjsyinner.[PROJECT_NAME]
```


## 参考资料

+ [执行 .command 文件提示没有运行权限的解决方法](https://zhidao.baidu.com/question/690540202316027684.html)

+ [执行 setup.command 时报错 "/bin/sh^M:bad interpreter: No such file or directory" 的解决方法](https://www.jianshu.com/p/99f36c8765b0)

+ [Mac 下 .sh 文件执行时提示 "Permission denied" 的解决方法](https://blog.csdn.net/weixin_41770169/article/details/86664553)

+ [报错 "-bash: xxx.sh: command not found" 的解决方法](https://www.jianshu.com/p/3ee9bcdc1098)

+ [ISPC 在虚幻引擎4中的应用](https://zhuanlan.zhihu.com/p/138030072)

+ [Python 实现二进制文件的判断](https://blog.csdn.net/homewm/article/details/93192294)

+ [虚幻引擎各版本的发布说明](https://docs.unrealengine.com/en-US/WhatsNew/Builds/index.html)
