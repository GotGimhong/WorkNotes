# Android 打包

## 1. 打包环境搭建

Android 平台打包环境的关键要素是 **Android SDK**，**Android NDK**，**JDK** 和 **Gradle**。前三者需要在打包前准备好，至于 Gradle，因为引擎通常会在构建 APK 时自动访问 Gradle 服务器来下载相关的依赖文件，所以不必预先准备。

### 1.1. Android SDK 和 NDK

根据 [官方文档](https://dev.epicgames.com/documentation/en-us/unreal-engine/set-up-android-sdk-ndk-and-android-studio-using-turnkey-for-unreal-engine?application_version=5.4) ，Android SDK 和 NDK 应当通过 **Android Studio** 进行下载和管理，因此首先需要下载和安装 Android Studio，然后下载指定版本的 Android SDK 和 NDK。

以 UE5\.4 为例，UE5\.4 最低支持的 Android SDK 版本是 26，推荐的 Android SDK 版本是 34。不过从测试情况来看，UE5\.4 对于 Android 9 以下版本的兼容性不佳，因此建议优先考虑 Android 9 及以上版本的支持；根据 [API 级别对照文档](https://apilevels.com/) ，下载 **28**，**29**，**30**，**31**，**33** 和 **34** 这几个版本的 SDK。至于 NDK，请按照官方要求使用 **r25c** 版本（适用于 UE5\.1 ~ UE5\.5）。

考虑到 Android Studio 比较庞大，如果不希望下载 Android Studio，也可以按照以下的方式单独下载 Android SDK 和 NDK：

#### 下载 Android SDK

首先，前往国内的 [Android 开发工具网站](https://www.androiddevtools.cn/) 下载一个 **SDK 工具（SDK Tools）** ，Windows 系统可以直接 [点击链接](https://dl.google.com/android/android-sdk_r24.4.1-windows.zip) 进行下载。

下载完成后进行解压缩，然后将环境变量 `ANDROID_HOME` 设置为 SDK 工具的解压路径，例如 `D:\android\android-sdk_r24.4.1-windows` 。

SDK 工具包含一个 SDK 管理器，原则上应当通过它来下载指定版本的 SDK，不过因为 SDK 管理器的版本比较旧，不支持下载 30 以上版本的 SDK，所以接下来还需要前往 [Android 开发者官网](https://developer.android.com/studio) 下载一个 **命令行工具（Commandline Tools）** 。

下载完成后将命令行工具解压缩至 SDK 工具的根目录，例如 `D:\android\android-sdk_r24.4.1-windows\cmdline-tools` 。

进入 SDK 工具的根目录，按照 [官方文档](https://developer.android.com/tools/sdkmanager) 的说明，使用 `sdkmanager` 命令行下载指定版本的 SDK。以下是下载 30 版本 SDK 的示例：

```
> .\cmdline-tools\bin\sdkmanager.exe "platform-tools" "platforms;android-30" --sdk_root=d:\android\android-sdk_r24.4.1-windows
```

[参考资料](https://www.cnblogs.com/nebie/p/9145627.html)

#### 下载 Android NDK

[最新版本的 NDK](https://developer.android.com/ndk/downloads)

[旧版本的 NDK](https://github.com/android/ndk/wiki/Unsupported-Downloads)

下载完成后进行解压缩，然后将环境变量 `NDKROOT` 设置为 NDK 的解压路径，例如 `D:\android\android-ndk-r25c-windows` 。

> NDK 版本会不断迭代，请务必选择正确的版本进行下载

### 1.2. JDK

Android Studio 通常内置一个 JDK，不过它的版本不一定符合项目打包所需，因此建议按照 [官方文档](https://dev.epicgames.com/documentation/en-us/unreal-engine/set-up-android-sdk-ndk-and-android-studio-using-turnkey-for-unreal-engine?application_version=5.4) 的说明，下载和安装符合引擎要求的 JDK 版本。以 UE5\.4 为例，因为 UE5\.4 使用 Gradle 7\.5 构建 APK，所以需要下载和安装 [JDK 18](https://www.oracle.com/java/technologies/javase/jdk18-archive-downloads.html)。

> JDK 和 Gradle 版本的对应关系请见 [Compatibility Matrix](https://docs.gradle.org/current/userguide/compatibility.html)


## 2. 常见问题

### 2.1. 在构建 APK 时提示 "Could not resolve com.android.tools.build:gradle:7.4.2."

该问题通常在打包 UE5\.4 项目时出现，原因是使用的 JDK 版本与 Gradle 版本不匹配。因为 UE5\.4 项目使用的 Gradle 版本是 7\.5，所以请确保打包设备正确安装了 **JDK 18（18.0.2.1）**，并且环境变量 `JAVA_HOME` 指向 JDK 18 的安装目录。另外，建议删除打包设备上除 JDK 18 之外其他版本的 JDK，避免产生干扰。

### 2.2. 在构建 APK 时提示 "java.security.InvalidAlgorithmParameterException: the trustAnchors parameter must be non-empty"

该问题通常在打包 UE5\.4 项目时出现，原因是 JDK 18 使用了不受支持的密钥格式。解决方法如下：

1. 进入 JDK 18 的安装目录，使用文本编辑器打开 conf/management/management\.properties 文件，添加一行内容：`javax.net.ssl.trustStorePassword=changeit`

2. 进入 JDK 18 的安装目录，使用文本编辑器打开 conf/security/java\.security 文件，将其中的 `keystore.type=pkcs12` 改为 `keystore.type=jks`

[参考资料](https://stackoverflow.com/questions/6784463/error-trustanchors-parameter-must-be-non-empty)

### 2.3. 在构建 APK 时提示 "Could not resolve com.google.android.gms:play-services-auth:20.7.0."

该问题的原因是访问 Gradle 服务器失败，未能下载依赖文件。建议检查网络连接和安全证书的配置。

### 2.4. 在构建 APK 时日志中出现乱码

乱码通常来源于 Gradle 的日志，解决方法是将环境变量 `GRADLE_OPTS` 的值设置为 `-Dfile.encoding=utf-8` 。
