# Android SDK 各种版本号的总结

## compileSdkVersion

+ 告诉 Gradle 将要使用哪个 Android SDK 版本进行编译项目

+ 用于编译项目的 Java 代码，而非 C++ 代码，因此对 NDK 和项目中的 C++ 代码都没有影响

+ 即使用最新版本的 SDK 来编译项目，也不妨碍打包后的 APK 在低于该 SDK 版本的 Android 系统上运行；例如，使用 API 30 的 SDK 构建出来的 APK，除非项目的 Java 代码中使用了 29 及以上版本的 API，否则它也可以在 API 28 的 Android 系统上运行

+ 建议尽可能使用最新版本，以便及时发现项目代码中的问题；例如可以及时发现是否使用了即将废弃的 API

    在引擎源码 UEDeployAndroid.cs 中，`GetSdkApiLevel` 函数做了一定程度的版本校验，它返回不低于成员变量 `MinimumSDKLevel` 的最新本地 SDK 版本。其中，`MinimumSDKLevel` 自从 4.21 版本开始到 5.0 版本，都是被指定为 28 。

+ 在引擎中有以下两种配置方式：

    1. 项目专用

        在项目设置的 `Platforms - Android - Project SDK Override - SDK API Level (...)` 类别下进行配置。

        这种方式可以为不同的项目配置不同的 SDK 版本，优先级高于方式2。

    2. 全局使用

        在项目设置的 `Platforms - Android SDK - SDK API Level (...)` 类别下进行配置。

        这种方式作用于所有项目，当方式1留空时启用。

+ 配置格式可以是 `android-{具体版本号}`，例如 android\-28；或者是 `matchndk`，表示以 NDK 的版本号为准；或者是 `latest`，表示以本地最高的 SDK 版本号为准

## minSdkVersion

+ 指定了 APK 对 Android 系统的最低版本要求，只有不小于这个版本的 Android 系统才能运行这个 APK

    经测试，若 Android 系统版本不符合 `minSdkVersion` 的要求，在小米手机上会提示 *“解析软件包时出现问题”*；如果使用 `adb install` 命令安装 APK，就会提示 *“Failure [INSTALL_FAILED_USER_RESTRICTED: Invalid apk]”* 。

+ 在 C++ 代码中，可以使用 `__ANDROID_API__` 宏来访问这个值

+ 在使用了高版本 SDK 的情况下，即使 APK 的 Java 代码实际上没有使用到高版本的 API，也不能假设该 APK 能够正常运行；这是因为不同的 SDK 版本，对最终生成的 APK 格式，包含库特性等可能都有影响；因此在指定 `minSdkVersion` 后，就应该严格将这个视为项目的 SDK 版本下限。

+ 设置为游戏项目支持的最低 Android 系统版本；如果游戏代码本身没有特别要求，就设置为虚幻引擎对 Android 系统的最低要求版本

+ 在引擎中的配置方式如下：

    在项目设置的 `Platforms - Android - APK Packaging - Minimum SDK Version (...)` 类别下进行配置。

+ 配置方式是直接填入版本号数字，例如 23 。

## targetSdkVersion

+ 相当于声明项目的 APK 可以在 \[`minSdkVersion`, `targetSdkVersion`\] 之间的任何一个 Android 系统版本下运行

    Android 系统会认为 APK 在这个版本区间内都能良好工作，因此会根据当前的系统版本，优先给 APK 开启更新的特性；例如将它设置为 11 或以上，系统会认为 APK 可以适应新的默认样式（Holo），再例如将它设置为 23 或以上，系统会对 APK 使用从 23 开始引入的新特性“运行时权限”，这要求 APK 提前准备好有关这个特性的处理逻辑。

    在项目开发时，必须确保 APK 可以在 \[`minSdkVersion`, `targetSdkVersion`\] 这个版本区间内的系统下正常运行。

+ 选择项目能够完美适配的最高版本，确保项目在新 Android 系统上有更好的体验

+ 在 C++ 代码中，可以使用 `__ANDROID_API_FUTURE__` 宏（编译时）或 `android_get_application_target_sdk_version` 函数（运行时）来访问这个值

+ 在引擎中的配置方式如下：

    在项目设置的 `Platforms - Android - APK Packaging - Target SDK Version (...)` 类别下进行配置。

+ 配置方式是直接填入版本号数字，例如 23 。
