# Source 分支定制引擎的注册

虚幻引擎的注册路径必须是 Engine 目录的所在目录。以 Windows 系统为例，对于以下目录结构，注册路径是批处理脚本所在目录的上一级目录：

```
StudioSource\
    Project\
        Studio.uproject
        注册定制引擎.bat
        ...
    Engine\
        ...
```

对应的批处理脚本如下：

```bat
:: 注册定制引擎.bat
@echo off
:: "UGC_UE" 是定制引擎在注册表中的索引，可以自行定义，但必须与 .uproject 文件中的 EngineAssociation 字段一致
:: "%~dp0" 表示批处理脚本的所在目录，"%~dp0.." 就是上一级目录
reg add "HKEY_CURRENT_USER\Software\Epic Games\Unreal Engine\Builds" /v "UGC_UE" /t REG_SZ /d "%~dp0.." /f
:: 或者设置一个定时，例如 timeout /t 3
pause
```
