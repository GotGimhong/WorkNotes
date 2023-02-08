# iOS 平台开发问题排查记录


## 在 iOS 下建立 Http 连接时出现报错

报错信息如下：

```
The resource could not be loaded because the App Transport Security policy requires the use of a secure connection.
```

iOS 默认要求使用安全方式建立 Http 连接，即 Https。在 `项目设置 / 平台 / iOS / Online` 中有一个名为 `Allow web connections to Non-HTTPS websites` 的选项，默认不勾选；如果打算强制使用不安全的连接方式，可以开启该选项，相当于禁用安全连接的检查，除非十分必要，否则不建议这么做。

这个选项的原理是在构建 IPA 时，将 PList 文件中的配置参数 `NSAllowsArbitraryLoads` 设为 `true`。详见引擎源码 UEDeployIOS.cs，函数 `GenerateIOSPList`，以下是关键源码：

```c++
/** UEDeployIOS.cs */

if (bDisableHTTPS)
{
    Text.AppendLine("\t<key>NSAppTransportSecurity</key>");
    Text.AppendLine("\t\t<dict>");
    Text.AppendLine("\t\t\t<key>NSAllowsArbitraryLoads</key><true/>");
    Text.AppendLine("\t\t</dict>");
}
```


## URL 中包含特殊字符时会被解析为空 URL

iOS 等 Apple 系列的平台使用的 Http API 是 `FAppleHttpRequest`，它是使用 Objective-C 实现的，内部使用 `NSURL` 类型处理 URL，详见源码 AppleHttp.h。

`NSURL` 要求传入经过百分号编码的 URL 字符串。若 URL 字符串包含未编码的特殊字符，例如空格和双引号，它就会因为无法识别而被解析为空 URL 。因此，处理 Http 连接时，需要为 iOS 等 Apple 系列平台增加百分号编码和译码的预处理，示例如下：

```c++
// __OBJC__ 宏可用于判断是否处于 Apple 平台（启用 Objective-C 代码的编译）
// 注意使用 #ifdef，而非 #if
#ifdef __OBJC__
    // 百分号编码与译码的预处理
#endif
```
