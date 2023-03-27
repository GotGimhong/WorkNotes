# Windows 系统引擎的注册


## 注册表的位置

1. `HKEY_CURRENT_USER/Software/Epic Games/Unreal Engine`

2. `HKEY_USERS/HKEY_USERS/x-x-x-xxxx-xxxx-xxxx-xx/Software/Epic Games/Unreal Engine`

    该注册表项是1的映射，不需要主动修改

3. `HKEY_CLASSES_ROOT/Unreal.ProjectFile`

4. `HKEY_LOCAL_MACHINE/SOFTWARE/Classes/Unreal.ProjectFile`

    该注册表项是3的映射，不需要主动修改


## 注册表的修改方式

### 修改引擎关联

+ `%1%/Builds`：按需添加引擎的注册条目；“名称”表示在 \.uproject 文件当中通过 `EngineAssociation` 字段关联的引擎，“数据”指向引擎的根目录

### 修改 .uproject 文件的图标

+ `%3%/DefaultIcon`：使用默认的条目；“数据”指向提供图标的 exe 文件路径，通常是 UnrealVersionSelector\.exe 文件的绝对路径

### 修改 .uproject 文件右键菜单的命令

+ `%3%/shell/open/command`：使用默认的条目；“数据”通常是 `{UnrealVersionSelector.exe 的绝对路径} /editor "%1"`

+ `%3%/shell/run`：“Icon”条目；“数据”指向提供“启动游戏”命令图标的 exe 文件路径，通常是 UnrealVersionSelector\.exe 文件的绝对路径

+ `%3%/shell/run/command`：使用默认的条目；“数据”通常是 `{UnrealVersionSelector.exe 的绝对路径} /game "%1"`

+ `%3%/shell/rungenproj`：“Icon”条目；“数据”指向提供“生成项目文件”命令图标的 exe 文件路径，通常是 UnrealVersionSelector\.exe 文件的绝对路径

+ `%3%/shell/rungenproj/command`：使用默认的条目；“数据”通常是 `{UnrealVersionSelector.exe 的绝对路径} /projectfiles "%1"`

+ `%3%/shell/switchversion`：“Icon”条目；“数据”指向提供“切换引擎版本”命令图标的 exe 文件路径，通常是 UnrealVersionSelector\.exe 文件的绝对路径

+ `%3%/shell/switchversion/command`：使用默认的条目；“数据”通常是 `{UnrealVersionSelector.exe 的绝对路径} /switchversion "%1"`


## 添加引擎

参照 [修改引擎关联](#修改引擎关联) ，在注册表当中添加一个新条目即可。


## 切换引擎

通常可以直接使用 引擎根目录/Engine/Binaries/Win64 下的 UnrealVersionSelector\.exe 来切换 `HKEY_CLASSES_ROOT/Unreal.ProjectFile` 处的注册表信息，或者自行编写脚本进行切换，脚本的模板请见 [附件](unreal_engine/windows_engine_registry/registry_template.md) 。
