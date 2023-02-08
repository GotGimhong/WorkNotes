# iOS 打包


## 条款与证书

做 iOS 的打包时，需要先导入条款（Provision）和证书（Certificate），这两个文件的后缀分别为 .mobileprovision 和 .p12。

即使正确导入了条款和证书文件，在打包 iOS 时仍然有可能会提示找不到条款和证书签名，详细错误信息如下：

```
Error: Provision not found. A provision is required for deploying your app to the device.
Error: Signing key not found. The app could not be digitally signed, because the signing key is not configured.
```

据了解，条款文件在不同操作系统的 PC 之间传输时文件可能会被修改，导致它无法被正常识别。例如条款文件正确的名称为 "Distro_acomssjjsyinner.mobileprovision"，传送至 Mac 设备上可能会变为 "Distro_acomssjjsyinner_NEW.mobileprovision"，此时需要将文件名中的多余内容 "_NEW" 删除。


## 打包设置

1. iOS 设置游戏竖屏

	Project Settings → iOS → 勾选 Supports Portrait Orientation

2. iOS 开启 iTunes 文件共享

	Project Settings → iOS → 勾选 Supports ITunes File Sharing

3. iOS 打包产生 dSYM 文件

	Project Settings → iOS → 勾选 Generate dSYM file for code debugging and profiling


## 问题排查记录

## 执行 iOS 打包时出现 Metal 材质的编译报错

报错信息如下：

```
LogShaderCompilers: Error: Errors compiling global shader TSlateElementPSLineSegmentfalsetrueA:
LogShaderCompilers: Error:  /tmp/3135_593812915.metal(0): Xcode's metal shader compiler was not found, verify Xcode has been installed on this Mac and that it has been selected in Xocde > Preferences > Locations > Command-line Tools.
```

该报错属于 Metal 材质编译报错，如果忽略则会导致游戏启动崩溃。原因同 [编译引擎时出现 ShaderCompileWorker 编译失败的问题](mac_engine.md#编译引擎时出现-shadercompileworker-编译失败的问题) 。

### 使用 dis 证书打包 iOS 失败

建议使用命令行来打包，同时额外指定 `-distribution` 参数。需要注意的是编译配置不必一定是 Shipping，还可继续使用 Development。

### iOS 包崩溃问题的排查方法

查看游戏日志，提取包含游戏名称，如 X9 的 .ips 文件并在 Mac 系统上解析。因为崩溃不一定由游戏逻辑导致，例如内存占用过大，所以 .ips 文件也不一定会包含游戏名称，这些 .ips 文件同样需要重视，可根据文件名去网上搜索答案。


## 参考资料

+ [iOS 条款文件有效但仍然提示无法找到的解决方法](https://answers.unrealengine.com/questions/498987/4131-ios-provision-not-found-despite-being-valid.html)

+ [Mac 生成 iOS 证书](https://www.cnblogs.com/xguoz/p/11079496.html)

+ [iOS 设备扫码即可查看 UDID](https://jingyan.baidu.com/article/a3a3f81127f0e18da2eb8a14.html)

+ [iOS 包崩溃解析 | iOS 的崩溃捕获-堆栈符号化-崩溃分析](https://juejin.im/post/5b9bccea6fb9a05d3a4b2472)

+ [iOS 包崩溃解析 | 解析 crash log（一）](https://zhuanlan.zhihu.com/p/59633692)

+ [iOS 包崩溃解析 | iOS 崩溃日志 ips 解析](https://www.cnblogs.com/mukekeheart/p/9449189.html)

+ [删除旧的 iOS 证书](https://dawnarc.com/2018/03/ue4%E5%88%A0%E9%99%A4%E6%97%A7%E7%9A%84mobileprovision%E6%96%87%E4%BB%B6clean-ios-mobileprovision-history/)

+ [IPP ERROR 等问题的解决方法](https://www.cnblogs.com/sevenyuan/p/11810551.html)
