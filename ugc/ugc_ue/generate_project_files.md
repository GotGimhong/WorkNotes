# 使用定制引擎生成解决方案

在 Source 分支中，需要通过定制引擎来生成解决方案，这一步可以通过一个类似 GenerateProjectFiles\.bat 的批处理脚本来完成，原理是调用定制引擎中 UnrealVersionSelector 的命令行。以 Windows 系统为例，考虑以下目录结构：

```
StudioSource\
    Project\
        Studio.uproject
        生成解决方案.bat
        ...
    Engine\
        ...
```

对应的批处理脚本如下：

```bat
:: 生成解决方案.bat
@echo off
:: "%~dp0" 表示批处理脚本的所在目录；在 Source 分支中，定制引擎的 Engine 目录位于批处理脚本所在目录的上一级目录
"%~dp0..\Engine\Binaries\Win64\UnrealVersionSelector-Win64-Shipping.exe" /projectfiles "%~dp0Studio.uproject"
:: 或者设置一个定时，例如 timeout /t 3
pause
```
